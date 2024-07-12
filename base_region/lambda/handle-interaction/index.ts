import { PublishCommand, SNSClient } from '@aws-sdk/client-sns';
import type {
  APIGatewayProxyEventV2,
  APIGatewayProxyResultV2,
  Handler,
} from 'aws-lambda';
import {
  APIChatInputApplicationCommandInteraction,
  InteractionResponseType,
  InteractionType,
  type APIInteractionResponsePong,
  APIInteractionResponseDeferredChannelMessageWithSource,
} from 'discord-api-types/v10';
import { verify } from 'discord-verify/node';
import { captureAWSv3Client } from 'aws-xray-sdk-core';

// comment for debugging bundle
//!
//!
//! End of vendor code
//!

const DISCORD_APP_PUBLIC_KEY = process.env.DISCORD_APP_PUBLIC_KEY;
const MANAGER_INSTRUCTION_SNS_TOPIC_ARN =
  process.env.MANAGER_INSTRUCTION_SNS_TOPIC_ARN;

if (!DISCORD_APP_PUBLIC_KEY || !MANAGER_INSTRUCTION_SNS_TOPIC_ARN) {
  throw new Error('Missing env vars');
}

const buildResult = (
  statusCode: number,
  body: Record<string, unknown> = {}
) => {
  return {
    headers: { 'content-type': 'application/json' },
    statusCode,
    body: JSON.stringify(body),
  };
};

const sns = captureAWSv3Client(new SNSClient({}));

const validate = async (event: APIGatewayProxyEventV2) => {
  return verify(
    event.body,
    event.headers?.['x-signature-ed25519'],
    event.headers?.['x-signature-timestamp'],
    DISCORD_APP_PUBLIC_KEY,
    crypto.subtle
  );
};

const handleInteraction = async ({
  data,
  id,
  token,
}: APIChatInputApplicationCommandInteraction): Promise<APIGatewayProxyResultV2> => {
  const command = data.name;

  console.log('Publishing command', command, 'from interaction', data.id);

  // Publishing to SNS before returning a response creates a race condition where in
  // rare cases the SNS message may be published, consumed and the instance managed
  // before the interaction is ready for follow-up.
  // However the alternative is response streaming (paid), step functions, etc. (overkill)
  const output = await sns.send(
    new PublishCommand({
      TopicArn: MANAGER_INSTRUCTION_SNS_TOPIC_ARN,
      Message: JSON.stringify({
        interaction_id: id,
        interaction_token: token,
        command,
      }),
    })
  );

  console.log('output', output);

  return buildResult(200, {
    type: InteractionResponseType.DeferredChannelMessageWithSource,
  } satisfies APIInteractionResponseDeferredChannelMessageWithSource);
};

/**
 * Main handler
 */
export const handler: Handler<
  APIGatewayProxyEventV2,
  APIGatewayProxyResultV2
> = async (event) => {
  const isValid = await validate(event);

  if (!isValid) {
    console.log('Invalid signature');
    return buildResult(401, { error: 'Invalid signature' });
  }

  const body = JSON.parse(event.body as string);

  console.log('Event type:', body?.type);

  if (body.type === InteractionType.Ping) {
    console.log('pong!');
    return buildResult(200, {
      type: InteractionResponseType.Pong,
    } satisfies APIInteractionResponsePong);
  }

  if (body.type !== InteractionType.ApplicationCommand) {
    console.log('Unsupported interaction type:', body.type);
    return buildResult(400, { error: 'Unsupported interaction type' });
  }

  return handleInteraction(body as APIChatInputApplicationCommandInteraction);
};

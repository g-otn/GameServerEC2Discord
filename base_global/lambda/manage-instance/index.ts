import {
  DescribeInstancesCommand,
  EC2Client,
  RebootInstancesCommand,
  StartInstancesCommand,
  StopInstancesCommand,
} from '@aws-sdk/client-ec2';
import type { Handler, SNSEvent } from 'aws-lambda';
import { captureAWSv3Client } from 'aws-xray-sdk-core';
import { captureFetchGlobal } from 'aws-xray-sdk-fetch';
import { RESTPatchAPIInteractionOriginalResponseJSONBody } from 'discord-api-types/v10';

// comment for debugging bundle
//!
//!
//! End of vendor code
//!

const DISCORD_APP_ID = process.env.DISCORD_APP_ID;
const DISCORD_BOT_TOKEN = process.env.DISCORD_BOT_TOKEN;

const DISCORD_BASE_URL = 'https://discord.com/api/v10';

if (!DISCORD_APP_ID || !DISCORD_BOT_TOKEN) {
  throw new Error('Missing env vars');
}

captureFetchGlobal();

const sendEC2Command = async (
  serverId: string,
  region: string,
  command: string
) => {
  console.log(
    'Searching instance with server ID',
    serverId,
    'on region',
    region
  );

  const ec2 = captureAWSv3Client(new EC2Client({ region }));

  const result = await ec2.send(
    new DescribeInstancesCommand({
      Filters: [
        { Name: `tag:GameServerEC2Discord:ServerId`, Values: [serverId] },
      ],
    })
  );

  const instance = result.Reservations?.[0]?.Instances?.[0];

  if (!instance?.InstanceId) {
    return `Instance with server ID ${serverId} not found on region ${region}`;
  }

  const instanceId = instance.InstanceId;

  console.log('Executing command', command, 'on instance', serverId);

  switch (command) {
    case 'start':
      return ec2
        .send(new StartInstancesCommand({ InstanceIds: [instanceId] }))
        .then((result) => {
          console.log('result', result);
          return 'Starting...';
        });
    case 'stop':
      return ec2
        .send(new StopInstancesCommand({ InstanceIds: [instanceId] }))
        .then((result) => {
          console.log('result', result);
          return 'Stopping...';
        });
    case 'restart':
      return ec2
        .send(new RebootInstancesCommand({ InstanceIds: [instanceId] }))
        .then((result) => {
          console.log('result', result);
          return 'Rebooting...';
        });
    case 'ip':
    case 'status':
      const { PublicDnsName, PublicIpAddress, State } = instance;

      if (command === 'status') {
        return `State: ${State?.Name}`;
      }

      const mainPort = instance.Tags?.find(
        (t) => t.Key === 'GameServerEC2Discord:MainPort'
      )?.Value;
      const hostname = instance.Tags?.find(
        (t) => t.Key === 'GameServerEC2Discord:Hostname'
      )?.Value;

      return (
        `Addresses:\n` +
        (PublicIpAddress ? `- **\`${PublicIpAddress}:${mainPort}\`**\n` : '') +
        (PublicDnsName ? `- \`${PublicDnsName}:${mainPort}\`\n` : '') +
        `- \`${hostname}:${mainPort}\``
      );
    default:
      return 'Unknown command';
  }
};

const parseMessageFromEvent = (event: SNSEvent) => {
  try {
    return JSON.parse(event.Records[0].Sns.Message);
  } catch (err) {
    console.error('Error parsing message:', err);
    throw err;
  }
};

/**
 * Main handler
 */
export const handler: Handler<SNSEvent> = async (event) => {
  const { command, interactionId, interactionToken, serverId, instanceRegion } =
    parseMessageFromEvent(event);

  const message = await sendEC2Command(serverId, instanceRegion, command).catch(
    (err) => {
      console.error('Error sending EC2 command:', err);
      return `Error executing command:\n\`\`\`\n${err}\n\`\`\``;
    }
  );

  console.log(
    'Updating interaction',
    interactionId,
    'message with content:\n',
    message
  );

  await fetch(
    `${DISCORD_BASE_URL}/webhooks/${DISCORD_APP_ID}/${interactionToken}/messages/@original`,
    {
      method: 'PATCH',
      headers: {
        Authorization: 'Bot ' + DISCORD_BOT_TOKEN,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        content: message,
      } satisfies RESTPatchAPIInteractionOriginalResponseJSONBody),
    }
  )
    .then(async ({ status, json }) => {
      const body = await json();
      console.log(status, JSON.stringify(body, null, '\t'), '\n');
      if (status !== 200) {
        throw { status, body };
      }
    })
    .catch((err) => {
      console.log('Error sending message:', err);
      // For some reason, node-fetch succeds on request but still throws errors afterwards when calling res.json():
      // `Error sending message: TypeError: Illegal invocation [...] webidl.[...]`
      // So let's just avoid throwing the error to avoid SNS retries
      // throw err;
    });
};

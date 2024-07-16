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
const DUCKDNS_DOMAIN = process.env.DUCKDNS_DOMAIN;
const MINECRAFT_PORT = process.env.MINECRAFT_PORT;

const DISCORD_BASE_URL = 'https://discord.com/api/v10';

if (
  !DISCORD_APP_ID ||
  !DISCORD_BOT_TOKEN ||
  !DUCKDNS_DOMAIN ||
  !MINECRAFT_PORT
) {
  throw new Error('Missing env vars');
}

captureFetchGlobal();

const sendEC2Command = async (
  instanceId: string,
  region: string,
  command: string
) => {
  console.log('Executing command', command, 'on instance', instanceId);

  const ec2 = captureAWSv3Client(new EC2Client({ region }));

  switch (command) {
    case 'start':
      return ec2
        .send(new StartInstancesCommand({ InstanceIds: [instanceId] }))
        .then((result) => 'Starting...');
    case 'stop':
      return ec2
        .send(new StopInstancesCommand({ InstanceIds: [instanceId] }))
        .then((result) => 'Stopping...');
    case 'restart':
      return ec2
        .send(new RebootInstancesCommand({ InstanceIds: [instanceId] }))
        .then((result) => 'Restarting...');
    case 'ip':
    case 'status':
      return ec2
        .send(new DescribeInstancesCommand({ InstanceIds: [instanceId] }))
        .then((result) => {
          if (!result?.Reservations?.[0].Instances?.[0]) {
            return 'No data';
          }

          const { PublicDnsName, PublicIpAddress, State } =
            result.Reservations[0].Instances[0];

          if (command === 'status') {
            return `State: ${State?.Name}`;
          }

          return (
            `Addresses:\n` +
            (PublicIpAddress
              ? `- **\`${PublicIpAddress}:${MINECRAFT_PORT}\`**\n`
              : '') +
            (PublicDnsName
              ? `- \`${PublicDnsName}:${MINECRAFT_PORT}\`\n`
              : '') +
            `- \`${DUCKDNS_DOMAIN}.duckdns.org:${MINECRAFT_PORT}\``
          );
        });
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

  const message = await sendEC2Command(instanceRegion, serverId, command).catch(
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
      throw err;
    });
};

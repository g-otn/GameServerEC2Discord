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
const INSTANCE_ID = process.env.INSTANCE_ID;
const MINECRAFT_PORT = process.env.MINECRAFT_PORT;

if (
  !DISCORD_APP_ID ||
  !DISCORD_BOT_TOKEN ||
  !DUCKDNS_DOMAIN ||
  !INSTANCE_ID ||
  !MINECRAFT_PORT
) {
  throw new Error('Missing env vars');
}

captureFetchGlobal();
const ec2 = captureAWSv3Client(new EC2Client({}));

const sendEC2Command = async (instanceId: string, command: string) => {
  console.log('Executing command', command, 'on instance', instanceId);

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
            `- \`${DUCKDNS_DOMAIN}.duckdns.org:${MINECRAFT_PORT}\` (Dynamic)`
          );
        });
    default:
      return 'Unknown command';
  }
};

/**
 * Main handler
 */
export const handler: Handler<SNSEvent> = async (event) => {
  const { command, interaction_id, interaction_token } = JSON.parse(
    event.Records[0].Sns.Message
  );

  const message = await sendEC2Command(INSTANCE_ID, command).catch((err) => {
    console.error('Error sending EC2 command:', err);
    return `Error executing command:\n\`\`\`\n${err}\n\`\`\``;
  });

  console.log(
    'Updating interaction',
    interaction_id,
    'message with content:\n',
    message
  );

  await fetch(
    `https://discord.com/api/v10/webhooks/${DISCORD_APP_ID}/${interaction_token}/messages/@original`,
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
    .then(async (res) =>
      console.log(
        res.status,
        JSON.stringify(await res.json(), null, '\t'),
        '\n'
      )
    )
    .catch((err) => {
      console.log('Error sending message:', err);
    });
};

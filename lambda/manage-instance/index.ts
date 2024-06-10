import type { Handler, SNSEvent } from 'aws-lambda';

// comment for debugging bundle
//!
//!
//! End of vendor code
//!

const DISCORD_BOT_TOKEN = process.env.DISCORD_BOT_TOKEN;

if (!DISCORD_BOT_TOKEN) {
  throw new Error('Missing env vars');
}

/**
 * Main handler
 */
export const handler: Handler<SNSEvent> = async (event) => {
  const { command, interaction_continuation_token } = JSON.parse(
    event.Records[0].Sns.Message
  );

  console.log(command, interaction_continuation_token);
};

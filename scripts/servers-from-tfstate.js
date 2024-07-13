const fs = require('fs');

const TF_STATE_PATH = process.env.TF_STATE_PATH || 'terraform.tfstate';

const serverIdsRegex = /"GameServerEC2Discord:ServerId": "(.+)"/g;

console.log('Reading', TF_STATE_PATH);

const state = fs.readFileSync(TF_STATE_PATH, 'utf8');

const matchesGroup1 = [...state.matchAll(serverIdsRegex)].map((m) => m[1]);

const serverIds = [...new Set(matchesGroup1)];

console.log('serverIds found', serverIds);

fs.writeFileSync(
  'scripts/servers.json',
  JSON.stringify(
    serverIds.map((id) => ({
      gameServerId: id,
      discordGuildId: '<Discord Guild ID here>',
      choiceDisplayName: '<Choice display name here>',
    })),
    null,
    '  '
  )
);

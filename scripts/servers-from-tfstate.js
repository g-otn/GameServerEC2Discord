const fs = require('fs');
const execSync = require('child_process').execSync;

const resourceRegex =
  /^(.+\.module\.ec2_spot_instance\.aws_spot_instance_request\..+)$/gm;

console.log('Listing terraform state');
const output = execSync('terraform state list', { encoding: 'utf-8' });

const serverResources = [...output.matchAll(resourceRegex)].map((m) => m[1]);

console.log('Server spot instance requests found:', serverResources);
const serversIdRegex = /"GameServerEC2Discord:ServerId".+"(.+)"/;
const serversRegionRegex = /"GameServerEC2Discord:Region".+"(.+)"/;

const stateData = serverResources.map((r, i) => {
  console.log('Showing resource', i, r);
  const resourceOutput = execSync('terraform state show ' + r, {
    encoding: 'utf-8',
  });

  const serverId = resourceOutput.match(serversIdRegex)?.[1];
  const region = resourceOutput.match(serversRegionRegex)?.[1];

  console.log('Found for', i, { serverId, region });

  return { serverId, region };
});

console.log('server data found', stateData);

const fileData = JSON.stringify(
  stateData.map(({ region, serverId }) => ({
    region: region || '<AWS Region here>',
    gameServerId: serverId || '<Game Server ID here>',
    discordGuildId: '<Discord Guild ID here>',
    choiceDisplayName: '<Choice display name here>',
  })),
  null,
  '  '
);

fs.writeFileSync('scripts/servers.json', fileData);
console.log('scripts/servers.json created');

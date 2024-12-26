const fs = require('fs');
const execSync = require('child_process').execSync;

console.log('Retrieving terraform state');
const state = execSync('terraform show -json -no-color', { encoding: 'utf-8' });

// See https://developer.hashicorp.com/terraform/internals/json-format
console.log('Parsing state');
const child_modules = JSON.parse(state).values.root_module.child_modules;

console.log('Child modules found:', child_modules.length);
const server_modules = child_modules.filter((m) =>
  m.child_modules?.some((cm) =>
    cm.resources?.some(
      (r) =>
        r.type === 'aws_spot_instance_request' &&
        r.values.tags?.['GameServerEC2Discord:ServerId']
    )
  )
);

console.log('Server modules found:');
console.log(server_modules.map((s) => `- ${s.address}`).join('\n'));

const serverConfig = server_modules.map((sm) => {
  console.log('Getting config for server module', sm.address);
  const spotRequestTags = sm.child_modules.reduce((prev, curr) => {
    console.log(`prev, curr`, prev, curr);
    if (prev) {
      return prev;
    }

    return curr.resources?.find(
      (r) =>
        r.type === 'aws_spot_instance_request' &&
        r.values.tags?.['GameServerEC2Discord:ServerId']
    );
  }, null).values.tags;

  return {
    region: spotRequestTags['GameServerEC2Discord:Region'],
    gameServerId: spotRequestTags['GameServerEC2Discord:ServerId'],
    discordGuildId: '<Discord Guild ID here>',
    choiceDisplayName: spotRequestTags['GameServerEC2Discord:ServerId'],
  };
});

console.log('Generate Discord script server config:', serverConfig);

const fileData = JSON.stringify(serverConfig, null, 2);

fs.writeFileSync('scripts/servers.json', fileData);
console.log('scripts/servers.json created');

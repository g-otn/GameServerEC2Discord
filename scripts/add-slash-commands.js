const fs = require('fs');

const APP_ID = process.env.DISCORD_APP_ID;
const BOT_TOKEN = process.env.DISCORD_APP_BOT_TOKEN;

const BASE_URL = 'https://discord.com/api/v10';

if (!APP_ID || !BOT_TOKEN) {
  throw new Error('Missing env vars');
}

console.log('Reading servers.json');
const servers = JSON.parse(fs.readFileSync('./scripts/servers.json', 'utf8'));

const mapServersToGuildMap = (data) => {
  const guildMap = {};

  data.forEach((item, i) => {
    const { discordGuildId, gameServerId, choiceDisplayName } = item;

    if (!discordGuildId || !gameServerId || !choiceDisplayName) {
      throw new Error(
        `Server ${i + 1}/${
          data.length
        } missing Discord Guild ID (${discordGuildId}), game server ID (${gameServerId}) or/and choice display name (${choiceDisplayName})`
      );
    }

    if (!guildMap[discordGuildId]) {
      guildMap[discordGuildId] = [];
    }

    guildMap[discordGuildId].push({
      gameServerId,
      choiceDisplayName,
    });
  });

  return guildMap;
};

const guildMap = mapServersToGuildMap(servers);

console.log('Guild map', guildMap);

// ---------------------------------------------------------------------------

const listGuildCommands = async () => {
  const res = await fetch(
    `${BASE_URL}/applications/${APP_ID}/guilds/${GUILD_ID}/commands`,
    {
      headers: {
        Authorization: 'Bot ' + BOT_TOKEN,
      },
    }
  );

  console.log('List', res.status, new URL(res.url).pathname);
  console.log(JSON.stringify(await res.json(), null, '  '), '\n');
};

/**
 * @param {string} id
 */
const deleteGuildCommand = async (id) => {
  const res = await fetch(
    `${BASE_URL}/applications/${APP_ID}/guilds/${GUILD_ID}/commands/${id}`,
    {
      method: 'DELETE',
      headers: {
        Authorization: 'Bot ' + BOT_TOKEN,
      },
    }
  );

  console.log('Delete', res.status, new URL(res.url).pathname);
  console.log(JSON.stringify(await res.json(), null, '  '), '\n');
};

/**
 * @param {import('../node_modules/discord-api-types/rest/v10').RESTPostAPIChatInputApplicationCommandsJSONBody} data
 */
const createGuildCommand = async (data) => {
  const res = await fetch(
    `${BASE_URL}/applications/${APP_ID}/guilds/${GUILD_ID}/commands`,
    {
      method: 'POST',
      body: JSON.stringify(data),
      headers: {
        Authorization: 'Bot ' + BOT_TOKEN,
        'Content-Type': 'application/json',
      },
    }
  );

  console.log(`Command ${data.name}:`, res.status, new URL(res.url).pathname);
  console.log(JSON.stringify(await res.json(), null, '  '), '\n');
};

/**
 * @param {import('../node_modules/discord-api-types/rest/v10').RESTPutAPIApplicationGuildCommandsJSONBody} data
 */
const createGuildCommandBulk = async (data, guildId) => {
  const res = await fetch(
    `${BASE_URL}/applications/${APP_ID}/guilds/${guildId}/commands`,
    {
      method: 'PUT',
      body: JSON.stringify(data),
      headers: {
        Authorization: 'Bot ' + BOT_TOKEN,
        'Content-Type': 'application/json',
      },
    }
  );

  console.log(
    `Overwrite guild application commands:`,
    res.status,
    new URL(res.url).pathname
  );
  console.log(JSON.stringify(await res.json(), null, '  '), '\n');
};

// listGuildCommands();
// deleteGuildCommand(123);

// ---------------------------------------------------------------------------

console.log('\nCreating commands');

Object.entries(guildMap).forEach(([guildId, servers]) => {
  const serverIdChoices = servers.map(
    ({ gameServerId, choiceDisplayName }) =>
      /** @type {import('../node_modules/discord-api-types/payloads/v10').APIApplicationCommandOptionChoice} */
      ({
        name: choiceDisplayName,
        value: gameServerId,
      })
  );

  const options = [
    {
      type: 3, // string
      name: 'server',
      name_localizations: {
        'pt-BR': 'servidor',
      },
      description: 'Which server to run the command for',
      description_localizations: {
        'pt-BR': 'Para qual servidor executar o comando',
      },
      required: true,
      choices: serverIdChoices,
    },
  ];

  createGuildCommandBulk(
    [
      {
        type: 1,
        name: 'start',
        name_localizations: {
          'pt-BR': 'iniciar',
        },
        description: 'Starts the Minecraft server',
        description_localizations: {
          'pt-BR': 'Inicia o servidor de Minecraft',
        },
        options,
      },
      {
        type: 1,
        name: 'stop',
        name_localizations: {
          'pt-BR': 'parar',
        },
        description: "Stops the Minecraft server, if it's online",
        description_localizations: {
          'pt-BR': 'Desliga o servidor de Minecraft, se estiver online',
        },
        options,
      },
      {
        type: 1,
        name: 'restart',
        name_localizations: {
          'pt-BR': 'reiniciar',
        },
        description: 'Restarts the Minecraft server, se estiver online',
        description_localizations: {
          'pt-BR': 'Reinicia o servidor de Minecraft, se estiver online',
        },
        options,
      },
      {
        type: 1,
        name: 'ip',
        description: 'Shows the server IP address',
        description_localizations: {
          'pt-BR': 'Exibe o endereço IP do servidor',
        },
        options,
      },
      {
        type: 1,
        name: 'status',
        description: 'Shows server host status',
        description_localizations: {
          'pt-BR': 'Exibe o estado do host do servidor',
        },
        options,
      },
    ],
    guildId
  ).then(() => console.log('Done guild', guildId));
});

const APP_ID = process.env.DISCORD_APP_ID;
const GUILD_ID = process.env.DISCORD_APP_GUILD_ID;
const BOT_TOKEN = process.env.DISCORD_APP_BOT_TOKEN;

if (!APP_ID || !GUILD_ID || !BOT_TOKEN) {
  throw new Error('Missing env vars');
}

const listGuildCommands = async () => {
  const res = await fetch(
    `https://discord.com/api/v10/applications/${APP_ID}/guilds/${GUILD_ID}/commands`,
    {
      headers: {
        Authorization: 'Bot ' + BOT_TOKEN,
      },
    }
  );

  console.log('List', res.status);
  console.log(JSON.stringify(await res.json(), null, '\t'), '\n');
};

/**
 * @param {string} id
 */
const deleteGuildCommand = async (id) => {
  const res = await fetch(
    `https://discord.com/api/v10/applications/${APP_ID}/guilds/${GUILD_ID}/commands/${id}`,
    {
      method: 'DELETE',
      headers: {
        Authorization: 'Bot ' + BOT_TOKEN,
      },
    }
  );

  console.log('Delete', res.status);
  console.log(JSON.stringify(await res.json(), null, '\t'), '\n');
};

/**
 * @param {import('../lambda-manage-ec2/node_modules/discord-api-types/rest/v10').RESTPostAPIChatInputApplicationCommandsJSONBody} data
 */
const createGuildCommand = async (data) => {
  const res = await fetch(
    `https://discord.com/api/v10/applications/${APP_ID}/guilds/${GUILD_ID}/commands`,
    {
      method: 'POST',
      body: JSON.stringify(data),
      headers: {
        Authorization: 'Bot ' + BOT_TOKEN,
        'Content-Type': 'application/json',
      },
    }
  );

  console.log(`Command ${data.name}:`, res.status);
  console.log(JSON.stringify(await res.json(), null, '\t'), '\n');
};

/**
 * @param {import('../lambda-manage-ec2/node_modules/discord-api-types/rest/v10').RESTPutAPIApplicationGuildCommandsJSONBody} data
 */
const createGuildCommandBulk = async (data) => {
  const res = await fetch(
    `https://discord.com/api/v10/applications/${APP_ID}/guilds/${GUILD_ID}/commands`,
    {
      method: 'PUT',
      body: JSON.stringify(data),
      headers: {
        Authorization: 'Bot ' + BOT_TOKEN,
        'Content-Type': 'application/json',
      },
    }
  );

  console.log(`Overwrite guild application commands:`, res.status);
  console.log(JSON.stringify(await res.json(), null, '\t'), '\n');
};

// -----

// listGuildCommands();
// deleteGuildCommand(123);

// ----

createGuildCommandBulk([
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
  },
  {
    type: 1,
    name: 'full_restart',
    name_localizations: {
      'pt-BR': 'reiniciar_tudo',
    },
    description:
      'Restarts the Minecraft server host (more thorough but slower)',
    description_localizations: {
      'pt-BR':
        'Reinicia o host do servidor de Minecraft (mais completo porém lento)',
    },
  },
  {
    type: 1,
    name: 'ip',
    description: 'Shows the server IP',
    description_localizations: {
      'pt-BR': 'Exibe o endereço do servidor',
    },
  },
  {
    type: 1,
    name: 'status',
    description: 'Shows server host status',
    description_localizations: {
      'pt-BR': 'Exibe o status do host do servidor',
    },
  },
]);

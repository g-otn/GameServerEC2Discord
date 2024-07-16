# Game Server EC2 Discord

Terraform files to manage cheap EC2 Spot instances to host game servers controlled by Discord chat.

Made for and tested with personal and small servers with few players.

## Table of Contents

- [Supported games](#supported-games)
- [Strategy](#strategy)
  - [Workflow](#workflow)
  - [Diagram](#diagram)
- [Cost breakdown](#cost-breakdown)
  - [Things to keep in mind](#things-to-keep-in-mind)
  - [Notable expenses](#notable-expenses)
  - [12-month Free Tier](#12-month-free-tier)
  - [Always Free offers](#always-free-offers)
- [Prerequisites](#prerequisites)
- [Setup](#Setup)
  - [Initial setup](#initial-setup)
  - [Terraform variables](#terraform-variables)
    - [Server ports](#server-ports)
    - [Instance type](#instance-type)
    - [Recommended RAM](#recommended-ram)
    - [Recommended Minecraft server plugins](#recommended-Minecraft-server-plugins)
  - [Applying](#applying)
  - [Discord interactions](#discord-interactions)
- [Testing and troubleshooting](#testing-and-troubleshooting)
  - [CloudWatch and X-Ray](#cloudwatch-and-x-ray)
  - [Useful commands](#useful-commands)
- [To-do](#to-do)
- [Notes and acknowledgements](#notes-and-acknowledgements)

## Supported games

**First class support:**

- Minecraft (via [itzg/docker-minecraft-server](https://github.com/itzg/docker-minecraft-server))

**Others:**

You can run any game server using the `custom` game option as long it meets the following criteria:

- It can run on Linux (any cpu architecture)
- It doesn't need to stay online 24/7 (when all players leave the server, there's no need for the server to stay open)
- It can be or it is containerized using Docker (for example, using [steamcmd](https://hub.docker.com/r/steamcmd/steamcmd) image as base)
- The main port, the one players stay connected to, uses TCP (for auto-shutdown to work properly)

Please see [Setup > Terraform variables > Custom game]() for examples.

## Strategy

The idea is reduce costs by mainly:

1. Start the server only when players want to play, instead of having it running 24/7
2. Automatically stop the server when there are no players
3. Avoid paying for a domain/etc by using a DDNS service
4. Using spot instances

This is achieved by:

1. Starting the server via Discord slash commands interactions
   - Slash commands work via webhook which don't require a Discord bot running 24/7, so we can use AWS Lambda + Lambda Function URL _(GCP Cloud Run could work too)_
2. Using the Auto-stop feature from [itzg/docker-minecraft-server](https://github.com/itzg/docker-minecraft-server) _(a plugin like [vincss/mcEmptyServerStopper](https://github.com/vincss/mcEmptyServerStopper) could work too)_ alongside a systemd timer
3. Setting up Duck DNS inside the instance _(No-IP could work too)_

### Workflow

The process of starting and automatically stopping a game server works as follows:

1. The player types `/start` in a Discord server text channel
2. [Discord calls](https://discord.com/developers/docs/interactions/overview#preparing-for-interactions) our Lambda function via its Function URL
3. The Lambda function sends the interaction token alongside the `start` command to another Lambda via SNS and then [ACKs the interaction](https://discord.com/developers/docs/interactions/receiving-and-responding#interaction-response-object-interaction-callback-type) to avoid Discord's 3s interaction response time limit.
4. The other Lambda which can take its time, in this case, starts the EC2 instance. Other commands such as `stop`, `restart`, `ip` and `status` can stop, reboot and describe the instance.
5. The instance starts
6. The DDNS systemd service updates the domain with the new IP (this can take a while to update if the server is restarted often due to DNS caching)
7. The game systemd service runs the Docker Compose file to start the server
8. The game shutdown systemd timer starts checking if the container is running
9. After a minute or so (depending on the game, instance, etc), the server is ready to connect and play
10. After 10 minutes without a connection or after the last player disconnects, the server is shutdown automatically via the [Auto-stop feature](https://docker-minecraft-server.readthedocs.io/en/latest/misc/autopause-autostop/autostop/) (Minecraft) or a script (other games).
11. After a minute or so, the auto-shutdown systemd timer/service notices that the container is stopped and shuts down the whole instance.

### Diagram

Minecraft:
![diagram](https://github.com/g-otn/minecraft-spot-discord/assets/44736064/d7a4a2d6-4eae-4e5b-a44d-88fc9ab10d0a)

<details>
  <summary>Other games</summary>

![todo]()

</details>

## Cost breakdown

### TL;DR

- Minecraft: **Less than 1 USD for 30h of gameplay per month** for 1 vCPU with 2.7GHz and 8GB RAM

**[AWS Princing Calculator estimate](https://calculator.aws/#/estimate?id=f3e231e532d196d04bf96b199fcfe1621cc3bb91)**

- Does not include Public IP cost, see tables below

### Things to keep in mind

- Last updated: July 2024 (please check the AWS Pricing Calculator estimate)
- Region assumed is `us-east-2` (Ohio)
- Prices are in USD
- Assumes usage of [Always Free](https://aws.amazon.com/free/?nc2=h_ql_pr_ft&all-free-tier.sort-by=item.additionalFields.SortRank&all-free-tier.sort-order=asc&awsf.Free%20Tier%20Types=tier%23always-free&awsf.Free%20Tier%20Categories=*all) monthly offers (different from 12 month Free Tier)
  - This is important mostly due to the monthly free 100GB [outbound data transfer](https://aws.amazon.com/ec2/pricing/on-demand/?nc1=h_ls#Data_Transfer) from EC2 to the internet. (See also [blog post](https://aws.amazon.com/pt/blogs/aws/aws-free-tier-data-transfer-expansion-100-gb-from-regions-and-1-tb-from-amazon-cloudfront-per-month/)) Otherwise due to the current price rates and regular gameplay network usage, it would cost more than the instance itself
- For the EC2 prices (in the table below), keep in mind about:
  - Spot prices change:
    - Depending on the chosen instance type
    - With time
    - Per region
    - Per availability zone.
      See Spot Instance pricing history in "AWS Console > EC2 > Instances > [Spot Requests](https://console.aws.amazon.com/ec2/home?region=us-east-2#SpotInstances:) > Pricing History" to see if this variation is significant and to choose the current best availability zone for you.
  - You can always change the instance type, but don't forget to change the other related Terraform variables!
  - Surplus vCPU usage credits charges when using [burstable instances](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/burstable-performance-instances.html) (`t4g`, `t3a`, `t3` and `t2`) in unlimited mode (default). See [Earn CPU credits](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/burstable-credits-baseline-concepts.html#earning-CPU-credits) and [When to use unlimited mode versus fixed CPU](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/burstable-performance-instances-unlimited-mode-concepts.html#when-to-use-unlimited-mode).
    - Basically, don't play at heavy CPU usage continuously for TOO long when using those instances types, or else you'll pay an extra fixed rate.

### Notable expenses

| Service   | Sub-service / description                                                                                                                                                                                     | Price/hour | Price 30h/month |
| --------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------- | --------------- |
| EC2       | [`r8g.medium`](https://instances.vantage.sh/aws/ec2/r8g.medium?min_memory=4&min_vcpus=1&region=us-east-2&cost_duration=daily&selected=r8g.medium&os=linux&reserved_term=Standard.noUpfront) **spot** instance | ~$0.018\*  | $0.54           |
| EBS       | 10GB volume for server data                                                                                                                                                                                   | $0.00109   | $0.032          |
| EBS       | Daily snapshots of 10GB volumes                                                                                                                                                                               | -          | ~$0.03          |
| VPC       | [Public IPv4 address](https://aws.amazon.com/pt/blogs/aws/new-aws-public-ipv4-address-charge-public-ip-insights/)                                                                                             | $0.005     | $0.015          |
| **Total** |                                                                                                                                                                                                               | **$0.029** | **$0.578**      |

\* I'm currently using `r7g.medium` prices (more expensive) since `r8g` family is very new and although it's price is very cheap now (~$0.006/h) it will probably rise.

### 12-month Free Tier

If you have access to the 12-month Free tier, you should automatically benefit from the following offers, and can temporarly ignore some expenses:

- VPC:

  - [750.0 Hrs (of Public IPv4 addresses) for free for 12 months](https://aws.amazon.com/about-aws/whats-new/2024/02/aws-free-tier-750-hours-free-public-ipv4-addresses) (Global-PublicIPv4:InUseAddress)

- EBS
  - "1.0 GB-mo for free for 12 months (Global-EBS:SnapshotUsage)
  - "30.0 GB-Mo for free for 12 months (Global-EBS:VolumeUsage)"

### Always Free offers

Some of the services used are more than covered by the ["always free"](https://aws.amazon.com/free/?all-free-tier.sort-by=item.additionalFields.SortRank&all-free-tier.sort-order=asc&awsf.Free%20Tier%20Types=tier%23always-free&awsf.Free%20Tier%20Categories=*all) monthly offers,
namely:

Lambda; SNS; KMS; CloudWatch / X-Ray; Network data transfer from EC2 to internet.

Again, as of July 2024, the most "would-be relatively expensive" expense is the **Network data transfer from EC2 to the internet**, currently covered by the monthly free 100GB [outbound data transfer](https://aws.amazon.com/ec2/pricing/on-demand/?nc1=h_ls#Data_Transfer) from EC2 to the internet. (See also [blog post](https://aws.amazon.com/pt/blogs/aws/aws-free-tier-data-transfer-expansion-100-gb-from-regions-and-1-tb-from-amazon-cloudfront-per-month/)). **You have to keep this in mind** if you're creating more than a couple of servers, or download something big from a server while it's running for example.

If necessary, it's possible to pay attention to your network stats to see more or less how much data the server is sending to a single player, per second. And then calculate how much will be used per month.

Of course, if you use your AWS account for other things you need to account for them.

## Prerequisites

- An [AWS account](https://portal.aws.amazon.com/billing/signup)
  - AWS credentials allowing Terraform to create resources on your account ([example](https://www.youtube.com/watch?v=eupw9OP14z8))
- An Discord app on the [Developer portal](https://discord.com/developers/applications)
  - A Discord server in which you have enough permissions to manage applications and channels
- DDNS service credentials, such as:
  - [Duck DNS](https://www.duckdns.org/about.jsp) account and domain
- A SSH keypair for SSH-ing into your instance
  - For example, you can generate one by running: `ssh-keygen -t ed25519 -C "GameServerEC2Discord"` or using an online tool ([example](https://showdns.net/ssh-key-generator))

## Setup

Requirements:

- Terraform 1.9+
- Python 3.6+ (due to [terraform-aws-lambda](https://github.com/terraform-aws-modules/terraform-aws-lambda))
- Node.js 18+ (to compile Lambda functions)

### (Optional) Creating an AWS billing alarm

It's recommended to set up a billing alarm on your AWS account to avoid unwanted surprises in case the servers start get way more expensive than estimated, somehow.

In that situation, you can be notified and manually shut down your servers if necessary to troubleshoot what's costing more than it's supposed to and why.

Please check this [tutorial](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/monitor_estimated_charges_with_cloudwatch.html) to set up alarms. In case you will only use your AWS account for this project, set it to 3 USD if you're running one Minecraft server for example.

### Project setup

1. Clone and navigate to the project:

```bash
git clone https://github.com/g-otn/GameServerEC2Discord.git && cd GameServerEC2Discord
```

2. Initialize Terraform:

```
terraform init
```

3.  Install Node.js dependencies to manually build the lambda functions

```
npm i
npm run build --workspaces
```

### Terraform variables

4. Create a file named `terraform.tfvars` and fill the required variables.
   - Check the table below and [`variables.tf`](variables.tf) to see which variables are available and what is their purpose
   - Check [`example.tfvars`](example.tfvars) for a full example

#### Required root module variables

| Name                     | Description                                                                     |
| ------------------------ | ------------------------------------------------------------------------------- |
| `aws_access_key`         | AWS Access Key you created for Terraform to use                                 |
| `aws_secret_key`         | AWS Secret Key you created for Terraform to use                                 |
| `ssh_public_key`         | Public key data in 'Authorized Keys' format to allow SSH-ing into the instances |
| `discord_app_id`         | Discord App ID for Discord API usage                                            |
| `discord_app_public_key` | Discord App public key for webhook validation                                   |
| `discord_bot_token`      | Discord App bot token for Discord API auth                                      |
| `duckdns_token`          | Required if you're using Duck DNS. See [DDNS](#ddns)                            |

After setting up the required variables, you still need to customize the `main.tf` file.

### Customize Terraform `main.tf` file

After filling

#### About available modules

- `base_global`: Common resources used across regions. Only one of these should exist
- `base_region`: Region-specific resources used by game servers located in that region. It uses outputs from `base_global`. One required for each region where a server is going to be placed in
- `server`: Each usage of this module creates and manages the resources of a single game server. References resources from a specific region

#### Required variables for each server module

You'll need to set these for each server you want to create.

| Name       | Description                                                            |
| ---------- | ---------------------------------------------------------------------- |
| `id`       | Unique alphanumeric id for the server                                  |
| `game`     | The game this server is going to host                                  |
| `az`       | Which availability zone from the chosen region to place the server in. |
| `hostname` | Full hostname to be used. (e.g "myserver.duckdns.org")                 |

Some other variables are required depending of the values of specific variables. Please check the [`server/variables.tf`](server/variables.tf) file.

Other variables are also required but are the same between servers or/and regions. Check the [`main.tf`](main.tf) file and the [Examples](#examples).

#### Examples

For a full example, check the [`main.tf`](main.tf) file itself.

<details>

  <summary>Simple minecraft server</summary>

```tf
module "example_server" {
  source = "./server"

  # Change these to desired values
  id       = "ExampleVanilla"
  game     = "minecraft"
  az       = module.region_us_east_2.available_azs[0]
  hostname = "example.duckdns.org"

  # ...
}
```

</details>

<details>

  <summary>Minecraft server with plugins, etc</summary>

```tf
module "example_server" {
  source = "./server"

  # Change these to desired values
  id       = "ExampleVanilla"
  game     = "minecraft"
  az       = module.region_us_east_2.available_azs[0]
  hostname = "example.duckdns.org"

  # ...
}
```

</details>

<details>

  <summary>Minecraft server on another region</summary>

</details>

<details>

  <summary>Multiple servers</summary>

</details>

<details>

  <summary>One server in each region</summary>

</details>

<details>

  <summary>Custom game</summary>

</details>

### Applying

5. Run `terraform plan` and revise the resources to be created

6. Run `terraform apply` after a while the instance and the game server should be running and accessible

> [!NOTE]  
> For extra security, SSH-ing and ICMP pinging the instances are only accepted from IPv4 where the Terraform config was applied (e.g your computer). This means once your IPv4 changes, you must run `terraform apply` again to update the security groups rules, or do it manually. Otherwise you won't be able to ping / SSH.

</details>

### Discord interactions

<details open>

  <summary>Discord interactions</summary>

Now that the server is up and running, you can set up your Discord server to be able to manage them!

#### Registering interaction endpoint

7. Go to the Lambda console on the region you chose, find the `interaction-handler` Lambda and copy it's Function URL.

8. Go to your Application on the [Discord Developer portal](https://discord.com/developers/applications) > General Information and paste the URL into `Interactions Endpoint URL` and click save.

#### Creating the guild commands

9. Invite your app to a Discord server (guild) using the OAuth2 link found at Installation. Make sure `applications.commands` is set in the Default Install Settings.

10. In the project top folder create a `.env` file

```
touch .env
```

11. Fill the environment variables required by [`add-slash-commands.js`](scripts/add-slash-commands.js):

```ini
DISCORD_APP_ID=123456789
DISCORD_APP_BOT_TOKEN=MTABCDE
```

Guild ID is the Discord server ID; App ID and bot token can be found in the [Discord Developer Portal](https://discord.com/developers/applications/).

12. Create the `servers.json` file which will be used to create option choices in the Discord slash commands, by running the `create-servers-file` npm script:

```
npm run create-servers-file
```

> [!NOTE]
> If you're using Terraform workspaces, you can fill the `TF_STATE_PATH` env var in the `.env` file

This will do a quick and dirty match on your Terraform state file to
get the server IDs you created and create a skeleton of the `servers.json` file for you.

If the `create-servers-file` script doesn't work for some reason, you can create the file manually.

The `servers.json` file should contain a list of all the servers you created with Terraform, with each list item containing the following information:

- `gameServerId`: The ID of a specific server you created via the `main.tf` file
- `discordGuildId`: In which Discord server (guild) the option to start/stop/etc the server will appear
- `choiceDisplayName`: How the server is going to show up in the Discord chat command autocomplete.

For example, the [`server.example.json`](scripts/servers.example.json) file would result in something like this:

![server.example.json result](https://github.com/user-attachments/assets/3ac8e0bf-6cbb-4644-901e-1cc106a61a37)

12. After creating the necessary files, run the `setup-discord-app` npm script. The script should call the Discord API and register the slash command interactions which the Lambda is ready to handle to that specific Discord server:

```
npm run setup-discord-app
```

13. You should now be able to use the `/start`, `/stop`, `/restart`, `/ip` or `/status` commands into one of the text channels to manage the instance.
    - You may need do additional permission/role setup depending on your Discord server configuration (i.e if the app can't use the text channel)

</details>

### Automatic backups

Daily snapshots of the data volume are taken via Data Lifecycle Manager. However depending on your region, you **must** enable regional STS endpoint. `us-east-2` (Ohio) for example, requires it. Otherwise the DLM policy will error when it tries to create the snapshot.

14. If applicable, enable the STS regional endpoint for the regions you're using via the [IAM Console](https://us-east-1.console.aws.amazon.com/iam/home?#/account_settings). See [Activating and deactivating AWS STS in an AWS Region](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_enable-regions.html)

## Recommendations and notes

Please read if applicable!

<details>
  <summary>Minecraft (RAM, plugins)</summary>

### Recommended RAM

In the variables you can set the JVM Heap size (`Xms` and `Xmx` options) via the `compose_game_environment` variable - [`INIT/MAX_MEMORY`](https://docker-minecraft-server.readthedocs.io/en/latest/variables/#general-options) option
and the Docker deploy resource memory limit before the OS kills your container via `compose_game_limits` - [`memory`](https://docs.docker.com/compose/compose-file/deploy/#resources). See [`example.tfvars`](example.tfvars)

Firstly, around 200MB is not really available in the instance for usage.

Then I recommended
reserving at least 300MB for idle OS, Docker, etc to try prevent the instance from freezing. The remaining will be your Docker memory limit for the container. You could also not set a Docker limit at all.

Finally, save around 600MiB-1GiB for the JVM / Off-heap memory. Examples:

| Instance memory | Available memory | Docker limit (optional) | Heap size | Recommended players (Vanilla) |
| --------------- | ---------------- | ----------------------- | --------- | ----------------------------- |
| 2GiB            | 1.8GiB           | **1.6GB**               | **1GB**   | 1-2                           |
| 4GiB            | 3.8GiB           | **3.6GB**               | **2.8GB** | 1-4                           |
| 8GiB            | 7.8GiB           | **7.6GB**               | **6.2GB** | 2-8                           |

### Recommended Minecraft server plugins

- [DiscordSRV](https://modrinth.com/plugin/discordsrv) - We're already using Discord, so why not? However it seems this plugin overrides the interactions, so you'll have to create another Discord app on the developer portal just for this. See [Installation](https://docs.discordsrv.com/installation/initial-setup)
- [AFK-Kicker](https://modrinth.com/plugin/afk-kicker) - Or any other plugin which can kick afk players, so the server doesn't stays on if nobody is playing
- [TabTPS](https://modrinth.com/plugin/tabtps) - Or any other plugin for easy in-game information display of server load, etc

> [!TIP]
> For Minecraft servers, once you run the docker compose once, you can
> comment the `PLUGINS` option from the docker compose file inside the instance, to avoid errors
> if the plugin every fails to download or check for updates. (Until of course, you want to add/remove a plugin)

</details>

### Regions

Sometimes you want to change the AWS region you server is located at, due to ping and/or price. By default this project
configures `us-east-2` (Ohio) which is generally cheap.

This project supports multiple AWS regions, so you can have a server in `us-east-2` (Ohio) and another two in `eu-north-1` (Frankfurt), for example.

**Before creating servers in another region**

- Check if the instance type for your server supported
  - Some instance types are not available in every region. (e.g `r8g` family)
  - You should check the default instance type by viewing the `local.game_defaults` in [server/ec2.tf](server/ec2.tf)
  - You should check the `instance_type` server module variable to override the default values.

To configure a new region to place y

### Server ports

Any extra port besides ICMP, SSH and `main_port` you want to open needs to be set both in `sg_ingress_rules` (VPC Security group rules) and `compose_game_ports` (Docker compose service ports) variables in a way in which they match.

<details>

  <summary>Note about Minecraft ports</summary>

By default the Minecraft container exposes port 25565, so if you want to run the server in another port you should either change only the host port (like `12345:25565` where 12345 is the custom port) or change the [`SERVER_PORT` variable](https://docker-minecraft-server.readthedocs.io/en/latest/variables/#server).

</details>

### DDNS

The `ddns_service` server module variable can be used to set which DDNS service to use for that server. Currently only Duck DNS is supported.

You may also disable it, which will make
the server only accessible via its public IPv4 address, which changes each time the instance starts.

You also have to set the `hostname` variable with the hostname which will be used.

<details>
  <summary>Duck DNS variables</summary>

| Name            | Required | Description            |
| --------------- | -------- | ---------------------- |
| `duckdns_token` | Yes      | Duck DNS account token |

</details>

### Server instance type

Choosing the instance type is has significant impact on the performance of the game server and its cost.

Each supported game comes with a default instance type, but it can be changed. Don't forget to update the relevant memory and docker variables to match the chosen instance type.

What to consider mainly, when choosing:

- CPU architecture (e.g `arm64` are generally cheaper but some games don't support it)
- Available vCPU and RAM
- CPU frequency (GHz)
- Spot price
- Spot interruption frequency (if it's too high there's more chance of the server going down while you're playing)

For Minecraft, I'd recommend nothing less than 1 vCPU and 4GB RAM.

To help choose a instance type different from the defaults, check out:

- The [Vantage](https://instances.vantage.sh/?min_memory=4&min_vcpus=1&region=us-east-2&cost_duration=daily&selected=t4g.large) website
  - Tip: Hide Name, `Windows`-related, Network Performance, On-demand and Reserved columns; Show all `Linux Spot`-related, `Clock Speed` and `Physical Processor` columns; Sort by `Linux Spot Average cost`
  - Grouping "Cost" by "Daily" can facilitate visualize how much (the instance alone) would cost for 24h of gameplay.
- [Spot Instance advisor](https://aws.amazon.com/ec2/spot/instance-advisor/)
- [aws-pricing.com Instance Picker](https://aws-pricing.com/picker.html)

If you choose a burstable instance types (`t4g`, `t3a`, `t3` and `t2`), check ["Things to keep in mind"](#things-to-keep-in-mind) in Cost breakdown

## Troubleshooting

#### Useful info and commands

Game data EBS volume is mounted at `/srv/<game id>` (e.g `/srv/minecraft`);

Docker compose container name is `<game id>-<game main service name>-1` (e.g `minecraft-mc-1`)

Commands (using Minecraft server as an example):

- `htop`: Task manager / resource usage viewer
- `docker stats`: Shows current RAM usage vs deploy limit
- [`docker attach minecraft-mc-1`](https://docker-minecraft-server.readthedocs.io/en/latest/commands/#enabling-interactive-console): (Minecraft only) Attach terminal to Minecraft server console
- `docker logs minecraft-mc-1 -f`: Latest logs from the container
- `sudo systemctl stop auto_shutdown.timer`: Stops the systemd timer which prevents the instance from being shut down automatically until next reboot. Don't forget to shutdown/reboot manually or start the timer again!
- `sudo conntrack -L --dst-nat | grep -w <game main port> | grep -w ESTABLISHED`: Lists currently estabilished network connections with the container

#### SSH

Your SSH client may give you a warning when connecting due to the IP changing between server restarts.
You can delete the `~/.ssh/known_hosts` file as a quick workaround.

#### CloudWatch

CloudWatch log groups are created for the Lambda and VPC flow logs.
They can help you troubleshoot problems with connectivity and Discord interactions.

X-Ray tracing is also enabled (mainly for debugging the project), however you need to [manually set up SNS](https://docs.aws.amazon.com/xray/latest/devguide/xray-services-sns.html#xray-services-sns-configuration) permissions so the traces show up correctly in the Trace Map / etc.

## To-do

I may or may not do these in the future:

- Make it generic so other games are supported - similar to [Lemmons/minecraft-spot](https://github.com/Lemmons/minecraft-spot)
  - Create some generic solution for auto-stop, watching active connections etc.
- toggle auto backups

## Notes and acknowledgements

This project was made for studying purposes mainly. The following repos and articles were very helpful in the learning and development process:

- [doctorray117/minecraft-ondemand](https://github.com/doctorray117/minecraft-ondemand) - The main motivation for this project, I wanted to do something similar but less complex and even cheaper (without Route 53, EFS, DataSync, Twilio and Minecraft watchdog)
- [JKolios/minecraft-ondemand-terraform](https://github.com/JKolios/minecraft-ondemand-terraform) - Gave me an general idea of what I had to do
- [mamoit/minecraft-ondemand-terraform](https://github.com/mamoit/minecraft-ondemand-terraform) - I almost went with this solution instead of creating my own, but I wanted to use EC2 directly instead of ECS + Fargate for slightly cheaper costs
- [Lemmons/minecraft-spot](https://github.com/Lemmons/minecraft-spot/) - Some Cloud-init and Terraform reference
- [vincss/mcEmptyServerStopper](https://github.com/vincss/mcEmptyServerStopper) - I was using this before I migrated to Docker and [itzg/docker-minecraft-server](https://github.com/itzg/docker-minecraft-server)
- [Giving kids control of an EC2 instance via discord
  ](https://drpump.github.io/ec2-discord-bot/) - Gave me the push to use Discord to reduce costs and simplify some of the workflow, and almost made me use GCP instead of AWS.

# Minecraft Spot Discord

Spin up a cheap EC2 Spot instance to host a Minecraft server managed by Discord chat.

Made for a personal and small server with few players.

## Table of Contents

- [Strategy](#strategy)
- [Workflow](#workflow)
- [Diagram](#diagram)
- [Cost breakdown](#cost-breakdown)
  - [Notable expenses](#notable-expenses)
  - [12-month Free Tier](#12-month-free-tier)
  - [Always Free offers](#always-free-offers)
- [Prerequisites](#prerequisites)
- [Setup](#Setup)
  - [Initial setup](#initial-setup)
  - [Terraform variables](#terraform-variables)
    - [Ports](#ports)
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

## Strategy

The idea is reduce costs by basically:

1. Start the server only when players want to play
2. Automatically stop the server when there are no players
3. Avoid paying for a domain/etc by using a DDNS service
4. Using spot instances

This is achieved by:

1. Starting the server via Discord slash commands interactions
   - Slash commands work via webhook which don't require a Discord bot running 24/7, so we can use AWS Lambda + Lambda Function URL _(GCP Cloud Run could work too)_
2. Using the Auto-stop feature from [itzg/docker-minecraft-server](https://github.com/itzg/docker-minecraft-server) _(a plugin like [vincss/mcEmptyServerStopper](https://github.com/vincss/mcEmptyServerStopper) could work too)_ alongside a systemd timer
3. Setting up Duck DNS inside the instance _(No-IP could work too)_

## Workflow

The process works as follow:

1. The player types `/start` in a Discord server text channel
2. [Discord calls](https://discord.com/developers/docs/interactions/overview#preparing-for-interactions) our Lambda function via its Function URL
3. The Lambda function sends the interaction token alongside the `start` command to another Lambda via SNS and then [ACKs the interaction](https://discord.com/developers/docs/interactions/receiving-and-responding#interaction-response-object-interaction-callback-type) to avoid Discord's 3s interaction response time limit.
4. The other Lambda which can take its time, and starts the EC2 instance. Other commands such as `stop`, `restart` and `status` can stop, reboot and describe the instance.
5. The instance starts
6. The Duck DNS systemd service [updates the domain](https://www.duckdns.org/install.jsp) with the new IP (this can take a while to use due to DNS caching)
7. The Minecraft systemd service runs the Docker Compose file to start the server
8. The Minecraft shutdown systemd timer starts checking if the container is running
9. After a minute or so, the server is ready to connect and play
10. After 10 minutes without a connection or after the last player disconnects, the server is shutdown automatically via the [Auto-stop feature](https://docker-minecraft-server.readthedocs.io/en/latest/misc/autopause-autostop/autostop/).
11. After a minute or less, the Minecraft shutdown timer/service sees that the server is shutdown and shuts down the instance itself.

## Diagram

![diagram](https://github.com/g-otn/minecraft-spot-discord/assets/44736064/d7a4a2d6-4eae-4e5b-a44d-88fc9ab10d0a)

## Cost breakdown

**TL;DR: Between 0.4 to 1.1 USD for 30h of gameplay** for 2 vCPU with 2.5GHz and 8GB RAM

- **[AWS Princing Calculator estimate](https://calculator.aws/#/estimate?id=f3e231e532d196d04bf96b199fcfe1621cc3bb91)**
  - Does not include Public IP cost, see table below
- Last updated: June 2024
- Region assumed is `us-east-2` (Ohio)
- Prices are in USD
- Assumes usage of [Always Free](https://aws.amazon.com/free/?nc2=h_ql_pr_ft&all-free-tier.sort-by=item.additionalFields.SortRank&all-free-tier.sort-order=asc&awsf.Free%20Tier%20Types=tier%23always-free&awsf.Free%20Tier%20Categories=*all) monthly offers (different from 12 month Free Tier)
  - This is important mostly due to the monthly free 100GB [outbound data transfer](https://aws.amazon.com/ec2/pricing/on-demand/?nc1=h_ls#Data_Transfer) from EC2 to the internet. (See also [blog post](https://aws.amazon.com/pt/blogs/aws/aws-free-tier-data-transfer-expansion-100-gb-from-regions-and-1-tb-from-amazon-cloudfront-per-month/)) Otherwise due to the current price rates and regular gameplay network usage, it would cost more than the instance itself
- For the EC2 prices (in the table below), keep in mind about:
  - Surplus vCPU usage credits charges when using burstable instances in unlimited mode (default). See [Earn CPU credits](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/burstable-credits-baseline-concepts.html#earning-CPU-credits) and [When to use unlimited mode versus fixed CPU](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/burstable-performance-instances-unlimited-mode-concepts.html#when-to-use-unlimited-mode).
    - Basically, don't play at heavy CPU usage continuously for TOO long when using those instances types.
  - Spot prices change:
    - With time
    - Depending on the selected availability zone.
      See Spot Instance pricing history in "AWS Console > EC2 > Instances > Spot Requests > Pricing History" to see if this variation is significant and to choose the current best availability zone for you.
  - You can always change the instance type, don't forget to change the other related Terraform variables!

### Notable expenses

| Service   | Sub-service / description                                                                                                                                                                                  | Price/hour | Price 30h/month |
| --------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------- | --------------- |
| EC2       | [`t4g.large`](https://instances.vantage.sh/aws/ec2/t4g.large?min_memory=4&min_vcpus=1&region=us-east-2&cost_duration=daily&selected=t4g.large&os=linux&reserved_term=Standard.noUpfront) **spot** instance | $0.02379   | $0.531          |
| EBS       | 10GB volume for Minecraft data                                                                                                                                                                             | $0.00109   | $0.032          |
| EBS       | Daily volume snapshots, for backup                                                                                                                                                                         | -          | ~$0.03          |
| VPC       | [Public IPv4 address](https://aws.amazon.com/pt/blogs/aws/new-aws-public-ipv4-address-charge-public-ip-insights/)                                                                                          | $0.005     | $0.015          |
| **Total** |                                                                                                                                                                                                            | **$0.029** | **$0.578**      |

### 12-month Free Tier

If you have access to the 12-month Free tier, you should automatically benefit from the following offers:

- [750h of free Public IPv4 address](https://aws.amazon.com/about-aws/whats-new/2024/02/aws-free-tier-750-hours-free-public-ipv4-addresses)

### Always Free offers

Some of the services used are more than covered by the ["always free"](https://aws.amazon.com/free/?all-free-tier.sort-by=item.additionalFields.SortRank&all-free-tier.sort-order=asc&awsf.Free%20Tier%20Types=tier%23always-free&awsf.Free%20Tier%20Categories=*all) monthly offers,
namely:

Lambda; SNS; KMS; CloudWatch / X-Ray; Network Data Transfer from EC2 to internet.

## Prerequisites

- An AWS account and associated credentials for Terraform to create resources
- An Discord app on the [Developer portal](https://discord.com/developers/applications)
- A [Duck DNS](https://www.duckdns.org/about.jsp) account and domain
- A SSH keypair for SSH-ing into your instance (e.g `ssh-keygen -t ed25519 -C "minecraft-spot-discord"`)

## Setup

Requirements: Terraform 1.9+, Python 3.6+ (due to [terraform-aws-lambda](https://github.com/terraform-aws-modules/terraform-aws-lambda)), Node.js 18+ (to compile Lambda functions)

### Initial setup

1. Clone and navigate to the project:

```bash
git clone https://github.com/g-otn/minecraft-spot-discord.git && cd minecraft-spot-discord
```

2. Initialize Terraform:

```
terraform init
```

3.  Manually build the lambda functions _(`terraform-aws-lambda` was breaking a lot during plan/apply)_

```
npm i
npm run build --workspaces
```

### Terraform variables

4. Create a file named `terraform.tfvars` and fill the required variables.
   - Check [`variables.tf`](variables.tf) to see which variables are required and their descriptions
   - Check [`example.tfvars`](example.tfvars) for a full example

#### Ports

Any extra port you want to open needs to be set both in `extra-ingress-rules` and `minecraft_compose_ports` variables in a way in which they match.

Note that by default the Minecraft container exposes port 25565, so if you want to run the server in another port you should either change only the host port (like `12345:25565` where 12345 is the custom port) or change the [`SERVER_PORT` variable](https://docker-minecraft-server.readthedocs.io/en/latest/variables/#server).

#### Instance type

I'd recommend nothing less than 1 vCPU and 4GB RAM.
This project was mainly tested and monitored with a [`t4g.large`](https://instances.vantage.sh/aws/ec2/t4g.large?min_memory=4&min_vcpus=1&region=us-east-2&cost_duration=daily&selected=t4g.large&os=linux&reserved_term=Standard.noUpfront) instance.

Please check out:

- The [Vantage](https://instances.vantage.sh/?min_memory=4&min_vcpus=1&region=us-east-2&cost_duration=daily&selected=t4g.large) website
  - Tip: Hide Name, `Windows`-related, Network Performance, On-demand and Reserved columns; Show all `Linux Spot`-related and `Clock Speed` columns; Sort by `Linux Spot Average cost`
- [Spot Instance advisor](https://aws.amazon.com/ec2/spot/instance-advisor/)

#### Recommended RAM

In the variables you can set the JVM Heap size (`Xms` and `Xmx` options) via the `minecraft_compose_environment` variable - [`INIT/MAX_MEMORY`](https://docker-minecraft-server.readthedocs.io/en/latest/variables/#general-options) option
and the Docker deploy resource memory limit before the OS kills your container via `minecraft_compose_limits` - [`memory`](https://docs.docker.com/compose/compose-file/deploy/#resources). See [`example.tfvars`](example.tfvars)

Firstly, around 200MB is not really available in the instance for usage.

Then I recommended
reserving at least 300MB for idle OS, Docker, etc to try prevent the instance from freezing. The remaining will be your Docker memory limit for the container. You could also not set a Docker limit at all.

Finally, save around 600MiB-1.5GiB for the JVM / Off-heap memory.

| Instance memory | Available memory | Docker limit | Heap size | Recommended players (Vanilla) |
| --------------- | ---------------- | ------------ | --------- | ----------------------------- |
| 2GiB            | 1.8GiB           | **1.6GB**    | **1GB**   | 1-2                           |
| 4GiB            | 3.8GiB           | **3.6GB**    | **2.8GB** | 1-4                           |
| 8GiB            | 7.8GiB           | **7.6GB**    | **6.1GB** | 2-8                           |

#### Recommended Minecraft server plugins

- [DiscordSRV](https://modrinth.com/plugin/discordsrv) - We're already using Discord, so why not? However it seems this plugin overrides the interactions, so you'll have to create another Discord app on the developer portal just for this. See [Installation](https://docs.discordsrv.com/installation/initial-setup)
- [AFK-Kicker](https://modrinth.com/plugin/afk-kicker) - Or any other plugin which can kick afk players, so the server doesn't stays on if nobody is playing
- [TabTPS](https://modrinth.com/plugin/tabtps) - Or any other plugin for easy in-game information display of server load, etc

tip: comment plugins in docker compose after first download to avoid request error

### Applying

5. Run `terraform plan` and revise the resources to be created

6. Run `terraform apply` after a while the instance and the game server should be running and accessible

### Discord interactions

7. Go to the Lambda console on the region you chose, find the `interaction-handler` Lambda and copy it's Function URL.

8. Go to your Application on the [Discord Developer portal](https://discord.com/developers/applications) > General Information and paste the URL into `Interactions Endpoint URL` and click save.

9. Invite your app to a specific Discord server (guild) using the OAuth2 link found at Installation. Make sure `applications.commands` is set in the Default Install Settings.

10. In the project, navigate to `scripts` and create a `.env` file

```
cd scripts
touch .env
```

11. Fill the environment variables required by [`add-slash-commands.js`](scripts/add-slash-commands.js):

```ini
DISCORD_APP_ID=123456789
DISCORD_APP_GUILD_ID=3123456789
DISCORD_APP_BOT_TOKEN=MTABCDE
```

Guild ID is the Discord server ID, app ID and bot token can be found in the [Discord Developer Portal](https://discord.com/developers/applications/).

12. Run the script while loading the `.env` file. The script should call the Discord API and register the slash command interactions which the Lambda is ready to handle to that specific Discord server:

```
node --env-file=.env add-slash-commands.js
```

13. You should now be able to use the `/start`, `/stop`, `/restart`, `/ip` or `/status` commands into one of the text channels to manage the instance.
    - You may need do additional permission/role setup depending on your Discord server configuration (i.e if the app can't use the text channel)

### Automatic backups

Daily snapshots of the data volume are taken via Data Lifecycle Manager. However depending on your region, you **must** enable regional STS endpoint. `us-east-2` (Ohio) for example, requires it. Otherwise the DLM policy will error when it tries to create the snapshot.

14. If applicable, enable the STS regional endpoint for your region on the [IAM Console](https://us-east-1.console.aws.amazon.com/iam/home?#/account_settings). See [Activating and deactivating AWS STS in an AWS Region](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_enable-regions.html)

## Testing and troubleshooting

#### CloudWatch and X-Ray

CloudWatch log groups are created for the Lambda and VPC flow logs.

X-Ray tracing is also enabled, however you need to [manually set up SNS](https://docs.aws.amazon.com/xray/latest/devguide/xray-services-sns.html#xray-services-sns-configuration) permissions so the traces show up correctly in the Trace Map / etc.

#### Useful commands

Game data EBS volume is mounted at `/srv/minecraft`;
Compose container name is `minecraft-mc-1`.

Inside the instance:

- `htop`
- `docker stats`: Visualize current RAM usage vs the limit
- [`docker attach minecraft-mc-1`](https://docker-minecraft-server.readthedocs.io/en/latest/commands/#enabling-interactive-console): attach terminal to Minecraft server console
- `docker logs minecraft-mc-1 -f`: Latest logs from the container
- `sudo systemctl stop minecraft_shutdown.timer`: Stops the systemd timer which prevents the instance from being shut down automatically until next reboot. Don't forget to shutdown manually or start the timer again!

#### SSH

Your SSH client may give you a warning when connecting due to the IP changing between server restarts.
You can delete the `~/.ssh/known_hosts` file as a quick workaround.

## To-do

I may or may not do these in the future:

- Isolate the reusable resources into a Terraform module so it's easy to spin more than one instance - similar to [mamoit/minecraft-ondemand-terraform](https://github.com/mamoit/minecraft-ondemand-terraform)
- Make it generic so other games are supported - similar to [Lemmons/minecraft-spot](https://github.com/Lemmons/minecraft-spot)
  - Create some generic solution for auto-stop, watching active connections etc.
- Create CloudWatch dashboard via Terraform

## Notes and acknowledgements

This project was made for studying purposes mainly. The following repos and articles were very helpful in the learning and development process:

- [doctorray117/minecraft-ondemand](https://github.com/doctorray117/minecraft-ondemand) - The main motivation for this project, I wanted to do something similar but less complex and even cheaper (without Route 53, EFS, DataSync, Twilio and Minecraft watchdog)
- [JKolios/minecraft-ondemand-terraform](https://github.com/JKolios/minecraft-ondemand-terraform) - Gave me an general idea of what I had to do
- [mamoit/minecraft-ondemand-terraform](https://github.com/mamoit/minecraft-ondemand-terraform) - I almost went with this solution instead of creating my own, but I wanted to use EC2 directly instead of ECS + Fargate for slightly cheaper costs
- [Lemmons/minecraft-spot](https://github.com/Lemmons/minecraft-spot/) - Some Cloud-init and Terraform reference
- [vincss/mcEmptyServerStopper](https://github.com/vincss/mcEmptyServerStopper) - I was using this before I migrated to Docker and [itzg/docker-minecraft-server](https://github.com/itzg/docker-minecraft-server)
- [Giving kids control of an EC2 instance via discord
  ](https://drpump.github.io/ec2-discord-bot/) - Gave me the push to use Discord to reduce costs and simplify some of the workflow, and almost made me use GCP instead of AWS.

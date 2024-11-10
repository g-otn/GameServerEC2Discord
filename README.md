# Game Server EC2 Discord

Terraform files to manage cheap EC2 Spot instances to host game servers controlled by Discord chat.

Made for and tested with personal and small servers with few players.

https://github.com/user-attachments/assets/e2e63d59-3a4e-4aaa-8513-30243aafa6c4

## Table of Contents

- [**Supported games**](#supported-games)
- [Strategy](#strategy)
  - [**Workflow**](#workflow)
  - [**Diagram**](#diagram)
- [Cost breakdown](#cost-breakdown)
  - [**TL;DR**](#tldr)
  - [Notable expenses](#notable-expenses)
  - [Things to keep in mind](#things-to-keep-in-mind)
  - [12-month Free Tier](#12-month-free-tier)
  - [Always Free offers](#always-free-offers)
- [**Prerequisites**](#prerequisites)
- [**Setup**](#setup)
  - [(Recommended) Creating an AWS billing alarm](#recommended-creating-an-aws-billing-alarm)
  - [Project setup](#project-setup)
  - [Terraform variables](#terraform-variables)
    - [Required root module variables](#required-root-module-variables)
  - [Specify AWS regions and servers via Terraform](#specify-aws-regions-and-servers-via-terraform)
    - [Required variables for each server module](#required-variables-for-each-server-module)
    - [Examples](#examples)
  - [Applying](#applying)
  - [(Recommended) Discord interactions](#recommended-discord-interactions)
    - [Registering interaction endpoint](#registering-interaction-endpoint)
    - [Creating the guild commands](#creating-the-guild-commands)
  - [Automatic backups](#automatic-backups)
  - [Game specific post-setup](#game-specific-post-setup)
- [Recommendations and notes](#recommendations-and-notes)
  - [**Game-specific notes**](#game-specific-notes)
  - [Regions](#regions)
    - [Creating server on another region](#creating-server-on-another-region)
  - [Server ports](#server-ports)
  - [DDNS](#ddns)
  - [Server instance type](#server-instance-type)
  - [Backups and deletion](#backups-and-deletion)
    - [Renaming and deleting](#renaming-and-deleting)
    - [Restoring a backup](#restoring-a-backup)
  - [LinuxGSM](#linuxgsm)
  - [Custom game](#custom-game)
- [Troubleshooting](#troubleshooting)
  - [Useful info and commands](#useful-info-and-commands)
  - [SSH](#ssh)
  - [CloudWatch](#cloudwatch)
- [Notes and acknowledgements](#notes-and-acknowledgements)

## Supported games

**Supported**

- Minecraft (via [itzg/docker-minecraft-server](https://github.com/itzg/docker-minecraft-server))
- Terraria (via [ryshe/terraria](https://github.com/ryansheehan/terraria))
- Factorio (via [factoriotools/factorio](https://github.com/factoriotools/factorio-docker))
- Satisfactory (via [wolveix/satisfactory-server](https://github.com/wolveix/satisfactory-server))
- Valheim (via [mbround18/valheim-docker](https://github.com/mbround18/valheim-docker))

**LinuxGSM**

- All above, Palworld, ARK: Survival Evolved and [**many more**](https://linuxgsm.com/servers/) should be supported via [LinuxGSM](https://hub.docker.com/r/gameservermanagers/gameserver)

_Not all games supported by LinuxGSM have been tested with this project._ See also [usage stats](https://linuxgsm.com/data/usage/).

**Others**

- You can run other game servers' Docker containers by using the `custom` server module option and specifying more technical configurations. See [Custom game](#custom-game) and custom game [example](#examples).

## Strategy

The idea is reduce costs by mainly:

1. Start the server only when players want to play, instead of having it running 24/7
2. Automatically stop the server when there are no players
3. Avoid paying for a domain/etc by using a DDNS service
4. Using spot instances

This is achieved by:

1. Starting the server via Discord slash commands interactions
   - Slash commands work via webhook which don't require a Discord bot running 24/7, so we can use AWS Lambda + Lambda Function URL
2. Using the Auto-stop feature from [itzg/docker-minecraft-server](https://github.com/itzg/docker-minecraft-server), or watching for active connections in a specific port, alongside a systemd timer
3. Setting up Duck DNS inside the instance _(No-IP could work too)_

### Workflow

After setup, the process of starting and automatically stopping a game server works as follows:

1. The player types `/start` in a Discord server text channel
2. Discord [calls](https://discord.com/developers/docs/interactions/overview#preparing-for-interactions) our Lambda function via its Function URL
3. The Lambda function sends the interaction token alongside the `start` command to another Lambda via SNS and then [ACKs the interaction](https://discord.com/developers/docs/interactions/receiving-and-responding#interaction-response-object-interaction-callback-type) to try avoiding Discord's 3s interaction response time limit.
4. The other Lambda which can take its time, in this case, starts the EC2 instance. Other commands such as `stop`, `restart`, `ip` and `status` can stop, reboot and describe the instance.
5. The instance starts
6. The DDNS systemd service updates the domain with the new IP
7. The game systemd service runs the Docker Compose file to start the server
8. The instance shutdown systemd timer starts checking if the container is running
9. After a minute or so (depending on the game, instance, etc), the server is ready to connect and play
10. After 10 minutes without a connection or after the last player disconnects, the server is shutdown automatically via the [Auto-stop feature](https://docker-minecraft-server.readthedocs.io/en/latest/misc/autopause-autostop/autostop/) (Minecraft) or a systemd service (other games).
12. After a minute or so, the instance shutdown systemd timer/service notices that the container is stopped and shuts down the whole instance.

### Diagram

Minecraft:
![diagram](https://github.com/g-otn/GameServerEC2Discord/assets/44736064/d7a4a2d6-4eae-4e5b-a44d-88fc9ab10d0a)

<details>
  <summary>Other games</summary>

![diagram others](https://github.com/user-attachments/assets/d3ba7882-f58f-46ec-bfaf-8d7dea6e832b)

</details>

## Cost breakdown

### TL;DR

Assuming one server and AWS free tier/offers:

- Minecraft: **~0.7 USD for 30h of gameplay** using 1x 2.7GHz vCPU and 8GB DDR5 RAM ([estimate](https://calculator.aws/#/estimate?id=dc1445d2100ca6e1e362c332bc2f88ee2b600104))
- Terraria: **~0.5 USD for 30h of gameplay** using 1x 3.7 GHz vCPU and 4GB of DDR5 RAM ([estimate](https://calculator.aws/#/estimate?id=f63634222b52545ef1230d16f4f21500cae14ff0))
- Factorio: **~0.7 USD for 30h of gameplay** using 1x 3.7 GHz vCPU and 4GB of DDR5 RAM ([estimate](https://calculator.aws/#/estimate?id=ff82441ec0eea51961558a2d6a5424d1422599cc))
- Satisfactory: **~0.9 USD for 30h of gameplay** using 1x 3.7 GHz vCPU and 8GB of DDR5 RAM ([estimate]())
- Valheim: **~1 USD for 30h of gameplay** using 2x 3.2 GHz vCPU and 4GB of DDR5 RAM ([estimate]())

AWS Pricing Calculator estimates do not include Public IP cost, see tables below.

### Notable expenses

Again, these are just estimates.

- ☑️ - Covered by **12**-month **F**ree **T**ier (assuming one server)
- ✅ - Covered by monthly **A**lways **F**ree offers (assuming one server)

<details open>
  <summary><b>Minecraft</b></summary>

| 12FT | AF  | Service | Sub-service / description                                                                                                                                                                                     | Price/hour | Price 30h/mo | Price 30h/mo w/ free tier/offers | Price 0h/mo (not in use, no free tier/offers) |
| ---- | --- | ------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------- | ------------ | -------------------------------- | --------------------------------------------- |
|      |     | EC2     | [`r8g.medium`](https://instances.vantage.sh/aws/ec2/r8g.medium?min_memory=4&min_vcpus=1&region=us-east-2&cost_duration=daily&selected=r8g.medium&os=linux&reserved_term=Standard.noUpfront) **spot** instance | $0.022     | $0.66        | $0.66                            |                                               |
| ☑️   |     | EBS     | 4GB root volume + 5GB game data volume                                                                                                                                                                        | -          | ~$0.72       | -                                | ~$0.72                                        |
|      |     | EBS     | (Optional) Snapshots of 5GB game data volume                                                                                                                                                                  | -          | ~$0.25       |                                  | ~$0.25                                        |
| ☑️   |     | VPC     | [Public IPv4 address](https://aws.amazon.com/pt/blogs/aws/new-aws-public-ipv4-address-charge-public-ip-insights/)                                                                                             | $0.005     | $0.15        | -                                |                                               |
|      | ✅  | VPC     | ~10GB of outbound network data (example)                                                                                                                                                                      | $0.003     | $0.9         | -                                |                                               |
|      |     |         | **Total**                                                                                                                                                                                                     | $0.12      | **$2.68**    | **$0.66**                        | **$0.97**                                     |

</details>

<details>
  <summary><b>Terraria</b></summary>

| 12FT | AF  | Service | Sub-service / description                                                                                                                                                                                     | Price/hour | Price 30h/mo | Price 30h/mo w/ free tier/offers | Price 0h/mo (not in use, no free tier/offers) |
| ---- | --- | ------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------- | ------------ | -------------------------------- | --------------------------------------------- |
|      |     | EC2     | [`m8g.medium`](https://instances.vantage.sh/aws/ec2/m8g.medium?min_memory=4&min_vcpus=1&region=us-east-2&cost_duration=daily&selected=m8g.medium&os=linux&reserved_term=Standard.noUpfront) **spot** instance | $0.015     | $0.45        | $0.45                            |                                               |
| ☑️   |     | EBS     | 4GB root volume + 1GB game data volume                                                                                                                                                                        | -          | ~$0.4        | -                                | ~$0.4                                         |
| ☑️   |     | EBS     | (Optional) Snapshots of 1GB game data volume                                                                                                                                                                  | -          | ~$0.05       |                                  | ~$0.05                                        |
| ☑️   |     | VPC     | [Public IPv4 address](https://aws.amazon.com/pt/blogs/aws/new-aws-public-ipv4-address-charge-public-ip-insights/)                                                                                             | $0.005     | $0.15        | -                                |                                               |
|      | ✅  | VPC     | ~10GB of outbound network data (example)                                                                                                                                                                      | $0.003     | $0.9         | -                                |                                               |
|      |     |         | **Total**                                                                                                                                                                                                     | $0.12      | **$1.95**    | **$0.45**                        | **$0.45**                                     |

</details>

<details>
  <summary><b>Factorio</b></summary>

| 12FT | AF  | Service | Sub-service / description                                                                                                                                                                                     | Price/hour | Price 30h/mo | Price 30h/mo w/ free tier/offers | Price 0h/mo (not in use, no free tier/offers) |
| ---- | --- | ------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------- | ------------ | -------------------------------- | --------------------------------------------- |
|      |     | EC2     | [`m7a.medium`](https://instances.vantage.sh/aws/ec2/m7a.medium?min_memory=4&min_vcpus=1&region=us-east-2&cost_duration=daily&selected=m7a.medium&os=linux&reserved_term=Standard.noUpfront) **spot** instance | $0.021     | $0.63        | $0.63                            |                                               |
| ☑️   |     | EBS     | 4GB root volume + 2GB game data volume                                                                                                                                                                        | -          | ~$0.48       | -                                | ~$0.48                                        |
|      |     | EBS     | (Optional) Snapshots of 2GB game data volume                                                                                                                                                                  | -          | ~$0.1        |                                  | ~$0.1                                         |
| ☑️   |     | VPC     | [Public IPv4 address](https://aws.amazon.com/pt/blogs/aws/new-aws-public-ipv4-address-charge-public-ip-insights/)                                                                                             | $0.005     | $0.15        | -                                |                                               |
|      | ✅  | VPC     | ~10GB of outbound network data (example)                                                                                                                                                                      | $0.003     | $0.9         | -                                |                                               |
|      |     |         | **Total**                                                                                                                                                                                                     | $0.12      | **$2.13**    | **$0.63**                        | **$0.58**                                     |

</details>

<details>
  <summary><b>Satisfactory</b></summary>

| 12FT | AF  | Service | Sub-service / description                                                                                                                                                                                     | Price/hour | Price 30h/mo | Price 30h/mo w/ free tier/offers | Price 0h/mo (not in use, no free tier/offers) |
| ---- | --- | ------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------- | ------------ | -------------------------------- | --------------------------------------------- |
|      |     | EC2     | [`r7a.medium`](https://instances.vantage.sh/aws/ec2/r7a.medium?min_memory=8&min_vcpus=1&region=us-east-2&cost_duration=daily&selected=r7a.medium&os=linux&reserved_term=Standard.noUpfront) **spot** instance | $0.028     | $0.84        | $0.84                            |                                               |
| ☑️   |     | EBS     | 4GB root volume + 6GB game data volume                                                                                                                                                                        | -          | ~$0.8        | -                                | ~$0.48                                        |
|      |     | EBS     | (Optional) Snapshots of 6GB game data volume                                                                                                                                                                  | -          | ~$0.3        |                                  | ~$0.3                                         |
| ☑️   |     | VPC     | [Public IPv4 address](https://aws.amazon.com/pt/blogs/aws/new-aws-public-ipv4-address-charge-public-ip-insights/)                                                                                             | $0.005     | $0.15        | -                                |                                               |
|      | ✅  | VPC     | ~10GB of outbound network data (example)                                                                                                                                                                      | $0.003     | $0.9         | -                                |                                               |
|      |     |         | **Total**                                                                                                                                                                                                     | $0.12      | **$2.99**    | **$0.84**                        | **$0.78**                                     |

</details>

<details>
  <summary><b>Valheim</b></summary>

| 12FT | AF  | Service | Sub-service / description                                                                                                                                                                                  | Price/hour | Price 30h/mo | Price 30h/mo w/ free tier/offers | Price 0h/mo (not in use, no free tier/offers) |
| ---- | --- | ------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------- | ------------ | -------------------------------- | --------------------------------------------- |
|      |     | EC2     | [`c7i.large`](https://instances.vantage.sh/aws/ec2/c7i.large?min_memory=2&min_vcpus=2&region=us-east-2&cost_duration=daily&selected=c7i.large&os=linux&reserved_term=Standard.noUpfront) **spot** instance | $0.031     | $0.93        | $0.93                            |                                               |
| ☑️   |     | EBS     | 4GB root volume + 6GB game data volume                                                                                                                                                                     | -          | ~$0.8        | -                                | ~$0.48                                        |
|      |     | EBS     | (Optional) Snapshots of 6GB game data volume                                                                                                                                                               | -          | ~$0.3        |                                  | ~$0.3                                         |
| ☑️   |     | VPC     | [Public IPv4 address](https://aws.amazon.com/pt/blogs/aws/new-aws-public-ipv4-address-charge-public-ip-insights/)                                                                                          | $0.005     | $0.15        | -                                |                                               |
|      | ✅  | VPC     | ~10GB of outbound network data (example)                                                                                                                                                                   | $0.003     | $0.9         | -                                |                                               |
|      |     |         | **Total**                                                                                                                                                                                                  | $0.12      | **$3.08**    | **$0.93**                        | **$0.78**                                     |

</details>

### Things to keep in mind

- Last updated: October 2024 (please check the AWS Pricing Calculator estimates)
- Region assumed is `us-east-2` (Ohio)
- Prices are in USD
- Prices do not include Tax
- Assumes usage of [Always Free](https://aws.amazon.com/free/?nc2=h_ql_pr_ft&all-free-tier.sort-by=item.additionalFields.SortRank&all-free-tier.sort-order=asc&awsf.Free%20Tier%20Types=tier%23always-free&awsf.Free%20Tier%20Categories=*all) monthly offers (different from 12 month Free Tier)
  - This is important mostly due to the monthly free 100GB [outbound data transfer](https://aws.amazon.com/ec2/pricing/on-demand/?nc1=h_ls#Data_Transfer) from EC2 to the internet. See [Always Free offers](#always-free-offers)
- **The most important price factors are play time, instance type and storage size**
- For the EC2 prices, keep in mind about:
  - For each instance type, Spot prices change:
    - With availability
    - With time
    - Per region
    - Per availability zone. See [Availability Zones](#availability-zones).
  - You can always change the instance type, but don't forget to change the other related Terraform variables!
  - Surplus vCPU usage credits charges when using [burstable instances](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/burstable-performance-instances.html) (`t4g`, `t3a`, `t3` and `t2`) in unlimited mode (default). See [Burstable instance types](#burstable-instance-types).
- Of course, if you use your AWS account for other things you need to account for them too, specially for [Always Free offers](#always-free-offers).

### 12-month Free Tier

If you have access to the 12-month Free tier, you should automatically benefit from the following offers, and can temporarly ignore some expenses:

- VPC:

  - [750.0 Hrs (of Public IPv4 addresses) for free for 12 months](https://aws.amazon.com/about-aws/whats-new/2024/02/aws-free-tier-750-hours-free-public-ipv4-addresses) (Global-PublicIPv4:InUseAddress)

- EBS
  - "1.0 GB-mo for free for 12 months (Global-EBS:SnapshotUsage)
  - "30.0 GB-Mo for free for 12 months (Global-EBS:VolumeUsage)"

### Always Free offers

**Outbound data transfer**

The **most** important always free offer is the:

- AWS Data Transfer: "[100.0 GB are always free per month as part of AWS Free Usage Tier](https://aws.amazon.com/pt/blogs/aws/aws-free-tier-data-transfer-expansion-100-gb-from-regions-and-1-tb-from-amazon-cloudfront-per-month/) (Global-DataTransfer-Out-Bytes)"

Otherwise due to the current [price rates](https://aws.amazon.com/ec2/pricing/on-demand/?nc1=h_ls#Data_Transfer) and regular gameplay network usage, it would probably cost more than the instance itself, although it varies per game.

**You have to keep this in mind** if you're creating more than a couple of servers, or download something big from a server while it's running. (e.g downloading large save files to sync multiplayer session)

> [!TIP] If necessary, you could pay attention to individual player network download metrics (e.g 20kb/s), and then calculate how much will be used per 30h of gameplay.

**Misc**

Some of the services used are more than covered by the ["always free"](https://aws.amazon.com/free/?all-free-tier.sort-by=item.additionalFields.SortRank&all-free-tier.sort-order=asc&awsf.Free%20Tier%20Types=tier%23always-free&awsf.Free%20Tier%20Categories=*all) monthly offers,
namely:

Lambda; SNS; KMS; CloudWatch / X-Ray; Data transfer between regions (i.e from Lambda and SNS to game server in another region)

## Prerequisites

- Basic Terraform, Linux and SSH usage knowledge
  - Dedicated server setup knowledge (updating configurations, uploading saves, etc)
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

### (Recommended) Creating an AWS billing alarm

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

### Specify AWS regions and servers via Terraform

After setting up the project and filling in the root Terraform variables,
you must customize your desired AWS regions and servers by modifying the [`servers.tf`](servers.tf) and [`regions.tf`](regions.tf) files.

These files are responsible for creating the game servers, and the resources in a specific AWS region required for the server to run.

By default, us-east-2 is already configured in [`regions.tf`](regions.tf). If you don't want to change your region you can leave that file as is. See also [Creating server on another region](#creating-server-on-another-region).

But you must modify the [`servers.tf`](servers.tf) file to create your server. Go to that file and either modify or comment out the example server. Notice that it references specific values and providers of an AWS region.

#### Required variables for each server module

You'll need to set these for each server you want to create.

| Name       | Description                                                                                                                                                                                             |
| ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `id`       | Unique alphanumeric id for the server                                                                                                                                                                   |
| `game`     | The game this server is going to host. Valid values: `linuxgsm`, `minecraft`, `terraria`, `factorio`, `valheim` `custom`. **Read [LinuxGSM](#linuxgsm) and [Custom game](#custom-game) if applicable.** |
| `az`       | Which availability zone from the chosen region to place the server in. It may be significant price-wise.                                                                                                |
| `hostname` | Full hostname to be used. (e.g "myserver.duckdns.org"). Required unless DDNS is `none`                                                                                                                  |

Some other variables may be required depending of the values of specific variables. Please check the [`server/variables.tf`](server/variables.tf) file.

Other "Common values" are also required but are the same between servers or/and regions. (you can just copy and paste them) See [Examples](#examples).

#### Examples

For a full example, check the [`servers.tf`](servers.tf) and [`regions.tf`](regions.tf) files themselves. See [ryshe/terraria](https://hub.docker.com/r/ryshe/terraria/).

<details>

  <summary>Simple Minecraft server</summary>

```tf
module "example_server" {
  id       = "ExampleVanilla"
  game     = "minecraft"
  az       = "us-east-2a"
  hostname = "example.duckdns.org"

  # ...
  source = "./server"
}
```

</details>

<details>

  <summary>Minecraft server with plugins, etc</summary>

See https://docker-minecraft-server.readthedocs.io/en/latest/variables/

```tf
module "example_plugins" {
  # Change these to desired values
  id       = "ExamplePlugins"
  game     = "minecraft"
  hostname = "exampleplugins.duckdns.org"

  instance_timezone = "America/Bahia"

  main_port          = 34850
  compose_game_ports = ["34850:25565", "24454:24454/udp"]
  sg_ingress_rules = {
    "Simple Voice Chat" : {
      description = "Simple Voice Chat mod server"
      from_port   = 24454
      to_port     = 24454
      ip_protocol = "udp"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
  compose_game_environment = {
    "INIT_MEMORY" = "6100M"
    "MAX_MEMORY"  = "6100M"

    "ICON" = "https://picsum.photos/300/300"
    "MOTD" = "     \u00A7b\u00A7l\u00A7kaaaaaaaa\u00A7r \u00A75\u00A7lGame Server EC2 Discord\u00A7r \u00A7b\u00A7l\u00A7kaaaaaaaa\u00A7r"

    "VERSION"     = "1.20.4"
    "ONLINE_MODE" = false
    # Tip: you may have eventual problems with auto-download/update if you add plugins this way
    # you may comment them out later and/or add them manually via SSH
    "PLUGINS"     = <<EOT
https://cdn.modrinth.com/data/9eGKb6K1/versions/9yRemfrE/voicechat-bukkit-2.5.16.jar

https://cdn.modrinth.com/data/UmLGoGij/versions/mr2CijyC/DiscordSRV-Build-1.27.0.jar

https://cdn.modrinth.com/data/cUhi3iB2/versions/sOk0epGX/tabtps-spigot-1.3.24.jar

https://cdn.modrinth.com/data/MubyTbnA/versions/vbGiEu4k/FreedomChat-Paper-1.6.0.jar
https://github.com/SkinsRestorer/SkinsRestorer/releases/download/15.0.13/SkinsRestorer.jar

https://download.luckperms.net/1544/bukkit/loader/LuckPerms-Bukkit-5.4.131.jar

https://github.com/dmulloy2/ProtocolLib/releases/download/5.2.0/ProtocolLib.jar
https://ci.codemc.io/job/AuthMe/job/AuthMeReloaded/2631/artifact/target/authme-5.7.0-SNAPSHOT.jar
https://ci.codemc.io/job/Games647/job/FastLogin/1319/artifact/bukkit/target/FastLoginBukkit.jar
EOT
  }

  compose_game_limits = {
    memory = "7200mb"
  }

  # DDNS
  duckdns_token = var.duckdns_token

  # Region (change these to desired region)
  base_region = module.region_us-east-2.base_region
  providers   = { aws = aws.us-east-2 }
  az          = "us-east-2a"

  # ------------ Common values (just copy and paste) -------------
  source                     = "./server"
  iam_role_dlm_lifecycle_arn = module.global.iam_role_dlm_lifecycle_arn
  # --------------------------------------------------------------
}
```

</details>

<details>
  <summary>Factorio server via LinuxGSM</summary>

```tf
module "linuxgsm" {
  # Change these to desired values
  id       = "FactorioExample"
  game     = "linuxgsm"
  hostname = "example-fctr.duckdns.org"

  linuxgsm_game_shortname = "fctr"

  instance_type     = "m7a.medium"
  arch              = "x86_64"

  main_port          = 34197
  compose_game_ports = ["34197:34197", "34197:34197/udp"]
  data_volume_size   = 2

  # DDNS
  duckdns_token = var.duckdns_token

  # Region (change these to desired region)
  base_region = module.region_us-east-2.base_region
  providers   = { aws = aws.us-east-2 }
  az          = "us-east-2a"

  # ------------ Common values (just copy and paste) -------------
  source                     = "./server"
  iam_role_dlm_lifecycle_arn = module.global.iam_role_dlm_lifecycle_arn
  # --------------------------------------------------------------
}

```

</details>

<details>

  <summary>Valheim server</summary>

```tf
module "valheim" {
  id       = "GSEDValheimExample"
  game     = "valheim"
  hostname = "valheim-example.duckdns.org"

  compose_game_environment = {
    "NAME" : "My GSED Valheim Server",
    "PASSWORD" : "friendsonly"
    "WEBHOOK_URL" : "https://discord.com/api/webhooks/.../..." # optional
  }

  # DDNS
  duckdns_token = var.duckdns_token

  # Region (change these to desired region)
  base_region = module.region_us-east-2.base_region
  providers   = { aws = aws.us-east-2 }
  az          = "us-east-2a"

  # ------------ Common values (just copy and paste) -------------
  source                     = "./server"
  iam_role_dlm_lifecycle_arn = module.global.iam_role_dlm_lifecycle_arn
  # --------------------------------------------------------------
}
```

</details>

<details>

  <summary>One server in each region</summary>

</details>

<details>

  <summary>Custom game</summary>

Creating a TShock Terraria server using the `custom` game option.
See [ryshe/terraria](https://hub.docker.com/r/ryshe/terraria/).

```tf
module "terraria" {
  # Change these to desired values
  id               = "CustomExample"
  game             = "custom"
  custom_game_name = "Terraria"
  hostname         = "gsed-example.duckdns.org"

  instance_type    = "m7g.medium"
  arch             = "arm64"
  data_volume_size = 1

  main_port = 7777
  compose_services = {
    main : {
      image : "ryshe/terraria"
      ports : ["7777:7777"]
      command : "-world ${local.terraria_workdir_path}/Worlds/CustomExample.wld -autocreate 3"
      volumes : ["/srv/terraria:${local.terraria_workdir_path}"]
    }
  }

  // ...
  source = "./server"
}
```

</details>

### Applying

5. Run `terraform plan` and revise the resources to be created

6. Run `terraform apply` after a while the instance and the game server should be running and accessible

If the server is not acessible try connecting into the instance, disabling auto shutdown and check logs for errors.
See [Useful info and commands](#useful-info-and-commands).

> [!NOTE]  
> For extra security, SSH-ing and ICMP pinging the instances are only accepted from IPv4 where the Terraform config was applied (e.g your computer). This means once your IPv4 changes, you must run `terraform apply` again to update the security groups rules, or do it manually. Otherwise you won't be able to ping / SSH.

</details>

### (Recommended) Discord interactions

<details open>

  <summary>Discord interactions</summary>

Now that the server is up and running, it should already shut itself down automatically after a while with no players.
However you currently still need to start the server via AWS console.

This is techinically optional, but to make starting your server easier, you could set up your Discord server to be able to manage them!

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

12. After creating the necessary files, run the `setup-discord-app` npm script.

```
npm run setup-discord-app
```

The script should load the `servers.json` file, call the Discord API and register the slash command interactions which the Lambda will be ready to handle:

13. You should now be able to use the `/start`, `/stop`, `/restart`, `/ip` or `/status` commands into one of the text channels to manage the instance.
    - You may need do additional permission/role setup depending on your Discord server configuration (i.e if the app can't use the text channel)

</details>

### Automatic backups

Daily snapshots of the data volume may be taken via Data Lifecycle Manager. **This is disabled by default** to save costs. (costs varies a lot depending on game, due to required storage space)

However depending on your region, you **must** enable regional STS endpoint. `us-east-2` (Ohio) for example, requires it. Otherwise the DLM policy will error when it tries to create the snapshot.

13. If you want to enable snapshots:

    - Set the `data_volume_snapshots` module variable to `true`.
    - Run `terraform apply` again, the DLM Lifecycle Policy will be created.

14. If applicable, enable the STS regional endpoint for the regions you're using via the [IAM Console](https://us-east-1.console.aws.amazon.com/iam/home?#/account_settings). See [Activating and deactivating AWS STS in an AWS Region](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_enable-regions.html)

See also [Restoring a backup](#restoring-a-backup)

### Game specific post-setup

Since you're running a public server, technically **anyone on the internet** can join your server and do anything (grief, cheat, crash the server, etc).
This is most likely not desirable and you might want to do game-specific configuration
to limit the server for you and your friends such as setting a password or whitelist.

These are done in most cases by SSH-ing into your instance and then running commands or modifying some game server configuration files. (See also [SSH](#ssh))

You'll also want to do this to load an existing save / world, depending on the game.

15. Please **check the "post-setup" section on each games' [Game-specific notes](#game-specific-notes)** for things you may want to do.

Check also [Useful info and commands](#useful-info-and-commands).

## Recommendations and notes

### Game-specific notes

Please read if applicable!

<details>
  <summary>Minecraft</summary>

### Minecraft post-setup

You should at least set up a whitelist so only your friends can join the server.

You can do that by op-ing yourself by creating an whitelist on the Minecraft server console.

1. Connect to your running server instance using SSH (See [SSH](#ssh))
2. Attach your terminal to the Minecraft server terminal by running `docker attach minecraft-mc-1`
3. Run `whitelist add <player name>` to whitelist someone. You could also give yourself admin using `op <your player name>` to run more commands from within your game chat.

If you're running an offline server, you could also consider setup an auth plugin such as [AuthMeReloaded](https://www.spigotmc.org/resources/authmereloaded.6269/) (Spigot).

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
> For Minecraft servers, once you run the docker compose once, you can comment the `PLUGINS` option from the docker compose file inside the instance, to avoid errors if the plugin every fails to download or check for updates. (Until of course, you want to add/remove a plugin)

</details>

<details>
  <summary>Terraria</summary>

### Terraria post-setup

You should at least set up a server password so only you and your friends can join the server.

1. Connect to your running server instance using SSH (See [SSH](#ssh))
2. Edit the file at `/srv/terraria/data/config.json`
   - You may need to use `sudo` to edit the file. (e.g `sudo nano /srv/terraria/data/config.json`)
3. Set a password in the `Settings.ServerPassword` field
4. Restart the server by running `docker compose restart terraria-terraria-1` or by restarting the whole instance.

See also TShock [Config Settings](https://tshock.readme.io/docs/config-settings) and [Setting Up Your Server](https://tshock.readme.io/docs/setting-up-your-server).

</details>

<details>
  <summary>Factorio</summary>

### Factorio post-setup

You should set at least set up a server password so only you and your friends can join the server.

1. Connect to your running server instance using SSH (See [SSH](#ssh))
2. Edit the file at `/srv/factorio/data/config/server-settings.json`
   - You may need to use `sudo` to edit the file. (e.g `sudo nano /srv/factorio/data/config/server-settings.json`)
3. Set a password in the `game_password` field
4. Restart the server by running `docker compose restart terraria-terraria-1` or by restarting the whole instance.

Consider also setting a name and description by editing the same file.

See also TShock [Config Settings](https://tshock.readme.io/docs/config-settings) and [Setting Up Your Server](https://tshock.readme.io/docs/setting-up-your-server).

</details>

<details>
  <summary>Satisfactory</summary>

### Satisfactory post-setup

The server can be set up in-game via "Server Manager" in the main menu.

In there you should at least set up a server password (different from admin password) so only you and your friends can join the server.

</details>

<details>
  <summary>Valheim</summary>

### Valheim post-setup

By default, the server is created with a password of `valheim` and should be visible in the server list depending on your region. (default server name is the server Terraform module id)

You may change the server password, among [other things](https://github.com/mbround18/valheim-docker?tab=readme-ov-file#environment-variables) such as server name via the `compose_game_environment` server module Terraform variable. See "Valheim server" in [Examples](#examples)

You must run `terraform apply` again to apply the changes.

</details>

<details>
  <summary>LinuxGSM</summary>

### LinuxGSM post-setup

Please check your game specific post-setup documentation if available,
also consider checking out [LinuxGSM own docs](https://docs.linuxgsm.com/game-servers) (left menu) which contains very useful information for some games.

As a general tip, your game data, saves and configurations files might be structured using different folder structure and file names than the ones used in game-specific docker images.

You can change LinuxGSM settings at `/srv/linuxgsm/data/config-lgsm/<short name>server/<short name>server.cfg`
such as `servername` and `serverpassword`.

</details>

### Regions

Sometimes you want to change the AWS region you server is located at, due to latency and/or price. By default this project
configures `us-east-2` (Ohio) which is generally cheap.

This project supports multiple AWS regions, so you can have a server in `us-east-2` (Ohio) and another two in `eu-north-1` (Frankfurt), for example.

#### Before creating servers in another region

- Check if the instance type for your server supported
  - Some instance types are not available in every region. (e.g `r8g` family)
  - You should check the default instance type by viewing the `local.game_defaults` in [server/main.tf](server/main.tf)
  - If needed, override `instance_type` server module variable to override the default values.

#### Creating server on another region

1. In the [`regions.tf`](regions.tf) file, copy and paste the example provider + module blocks below them.

   - If you haven't run `terraform apply` yet, you can also just change the values from the existing one

2. Replace `us-east-2` with the desired region in every occurance in the pasted code.
   This includes `alias` and `region`(s) attributes, `provider.aws` reference and `base_region` module name.
3. Also change the `az` attribute to a valid AZ in the chosen region.

#### Availability zones

A server is constrained to one availability zone (AZ) due to EBS. You cannot change it after
creation without losing data.

You may want to place your server in a specific AZs which has lower price at the moment. Keep in mind the price
still varies with time due to a number of factors.

See Spot Instance pricing history in "AWS Console > EC2 > Instances > [Spot Requests](https://console.aws.amazon.com/ec2/home?region=us-east-2#SpotInstances:) > Pricing History",
then choose the desired instance type or the default instance type in this project for the game you want.

Check if this variation is significant and choose the current cheapest AZ for you.

When choosing an specific AZ, don't forget to update the `azs` variable in the `base_region` module in [`servers.tf`](./servers.tf),
and properly update all server module `az` variables in [`servers.tf`](./servers.tf).

### Server ports

Each game requires different ports to be open.

Any extra port besides ICMP, SSH and `main_port` you want to open needs to be set both in `sg_ingress_rules` (VPC Security group rules) and `compose_game_ports` (Docker compose service ports) variables in a way in which they match.

For example, here's a configuration that opens the port 22222 and 33333:

```hcl
module "myserver" {
  // ...
  main_port = 11111

  // it's not necessary to include main_port configuration in these variables
  compose_game_ports = ["22222:22222", "33333:33333/udp"]
  sg_ingress_rules = {
    "admin panel" : {
      description = "Admin panel using TCP"
      from_port   = 22222
      to_port     = 22222
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
    }
    "video feed" : {
      description = "Some video data using UDP"
      from_port   = 33333
      to_port     = 33333
      ip_protocol = "udp"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
}
```

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

Each supported game comes with a default instance type, but it can be changed. Don't forget to update the relevant Docker Compose variables (environment in case of Minecraft and deploy limits) to match the chosen instance type.

When choosing an EC2 instance type, consider:

- CPU architecture (e.g `arm64` are generally cheaper but some games don't support it)
- Available vCPU and RAM (based on game server requirements)
  - Keep in mind some of the server resources are used for the OS, Docker, etc and are not available to the game server itself. For example a 8GB instance might have ~6.5GB available
- System single-core and multi-core [performance scores](https://browser.geekbench.com/search?utf8=✓&q=amazon+ec2)
- [Instance generation](https://docs.aws.amazon.com/ec2/latest/instancetypes/instance-type-names.html) (newer generations are more performant)
- Spot price and price history
- Spot interruption frequency (if it's too high there's more chance per month of the server going down while you're playing)

To help choose a instance type different from the defaults, check out:

- The [Vantage](https://instances.vantage.sh/?min_memory=4&min_vcpus=1&region=us-east-2&cost_duration=daily&selected=t4g.large) website
  - Tip: Hide Name, `Windows`-related, Network Performance, On-demand and Reserved columns; Show all `Linux Spot`-related, `Clock Speed` and `Physical Processor` columns; Sort by `Linux Spot Average cost`
  - Grouping "Cost" by "Daily" can facilitate visualize how much (the instance alone) would cost for 24h of gameplay.
- [Geekbench Browser](https://browser.geekbench.com/search?utf8=✓&q=amazon+ec2) - Easier to check CPU performance by looking at benchmark scores
- [Spot Instance advisor](https://aws.amazon.com/ec2/spot/instance-advisor/) - Official way to check spot interruption frequency
- [aws-pricing.com Instance Picker](https://aws-pricing.com/picker.html) - Similar to Vantage

Some examples of families you could choose: `r8g`, `m7a`, `m7g`, `c7g` and `c7a`.

#### Burstable instance types

If you choose a burstable instance types (`t4g`, `t3a`, `t3` and `t2`), be aware of _surplus vCPU usage credits charges_ when using [burstable instances](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/burstable-performance-instances.html) (`t4g`, `t3a`, `t3` and `t2`) in unlimited mode (default).
See [Earn CPU credits](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/burstable-credits-baseline-concepts.html#earning-CPU-credits) and [When to use unlimited mode versus fixed CPU](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/burstable-performance-instances-unlimited-mode-concepts.html#when-to-use-unlimited-mode).

Make sure you have a good grasp of concepts such as unlimited vs fixed mode, vCPU credits, baseline performance, breakeven CPU usage and launch credits before choosing an instance of these families. They can be cheaper but if used wrong can incur an extra charges and end of up more expensive than fixed performance instance types.

As a general tip, avoid `micro`, `small` and `medium` instances of these families because the baseline is too low for most games.

#### Renaming and deleting

When you want to delete a server, you can't just comment out the server module usage due to how Terraform providers works.

You can delete by using `terraform destroy --target=module.<server module name>`.

You can also do the same to delete `base_region` module resources. (e.g `terraform destroy --target=module.us-east-2`)

After deleting a server, Terraform will create a "final snapshot" of the server data volume, which you can use to restore the server.

#### Restoring a backup

Backups is done via EBS volume snapshots. You can restore the game server data by
specifying the `snapshot_id` of the desired snapshot in the server module, which will force a replacement of the EBS "data" volume, where the new one will use that snapshot as a base.

### LinuxGSM

You may want to run a game server via [LinuxGSM](https://hub.docker.com/r/gameservermanagers/gameserver), since it supports a [large amount of game servers](https://linuxgsm.com/servers/).

The setup is similar but simpler than a `custom` game server. Most of the values you'll find by searching "(game name) dedicated server requirements".

Here's the _additional_ variables you must to specify in the [`servers.tf`](./servers.tf) module declaration in order to create a `linuxgsm` server:

| Name                    | Description                                                                                                                                                                                       |
| ----------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| game                    | Must be `linuxgsm`                                                                                                                                                                                |
| linuxgsm_game_shortname | The "shortname" of the desired game, found in LinuxGSM's **[server list](https://github.com/GameServerManagers/LinuxGSM/blob/72deed15a68c95765b9a18dad68d15494d644781/lgsm/data/serverlist.csv)** |
| instance_type           | The EC2 instance type. See [Server instance type](#server-instance-type)                                                                                                                          |
| arch                    | The architecture of the chosen EC2 instance type (`arm64` or `x86_64`). Some games do not support `arm64`. See also [server/main.tf](./server/main.tf)                                            |
| main_port               | Main port for server connections. If the game requires more than one port, see [Server ports](#server-ports)                                                                                      |
| data_volume_size        | The required storage in GB by the game data + save files, it varies greatly from game to game. See [server/main.tf](./server/main.tf) for some examples.                                          |

See also [Examples](#examples)

### Custom game

You can manually configure the Compose file, ports, storage and other resources for a desired game server,
by using the `custom` value in the `game` variable.

The game server must meet the following criteria:

- It can run on Linux 64-bits
- It is containerized using Docker (for example, based on [CM2.Network steamcmd](https://cm2.network) or [steamcmd/steamcmd](https://hub.docker.com/r/steamcmd/steamcmd))
  - The container can be run on `x86_64` or `arm64` architectures
- It can handle rare sudden shutdowns
  - This is due to the nature of Spot instances or if someone requests it via Discord slash commands
  - This means it should be able to shut down gracefully and preferrably auto-save periodically
- It makes sense for this project:
  - This project allows part of the friend group to play on the server, without
    requiring the host player who has the save file to be online at all play sessions.
    Examples are Multiplayer "Open World Survival Craft" / Sandbox games.
  - Some games though, can only be played or only make sense to play when the all players are together.

To define a custom game server (see also custom game [example](#examples)):

1. Copy and paste a new server module usage in the [`servers.tf`](servers.tf) file.
2. Set common server-specific values such as `id`, `az`, `hostname` and other DDNS config.
3. Set `game` to `custom` and define an alphanumeric `custom_game_name` (e.g `CustomGame`).
4. Set the game's networking using `main_port` and add `sg_ingress_rules` as needed.
5. Set the game's available storage using `data_volume_size` and backup frequency and retetion using the `data_volume_snapshot_*` variables.
   - If your volume is too big and/or the game data changes too much between snapshots (e.g big save files are compressed each time), consider lowering snapshot retention. Check AWS pricing calculator.
   - If the Docker image you're going to use is too big (more than a couple of GBs), you may need to increase the root volume size.
6. Configure the Docker Compose file which will be used within the instance by setting up at least the `compose_game_elements` variable:
   - Image: Set the game's docker image/tag
   - Networking: Define the container `ports` to match `main_port` and `sg_ingress_rules`
   - Storage: Define a volume matching `data_mount_path`, which is based from lowercase value of `custom_game_name`
     (e.g `/srv/customgame`, See [server/main.tf](server/main.tf)).
   - Environment: Fill in environment variables required by your image.
7. Set the `instance_type` and matching `arch`. See [Server instance type](#server-instance-type).
8. To test the instance for the first time, disable `auto_shutdown`. Don't forget to re-enable it!
9. Run `terraform init` since this is a new module
10. Follow [Applying](#applying) and [Discord interactions](#recommended-discord-interactions) again to create the resources and update your Discord app slash commands.

## Troubleshooting

### SSH

You most likely will want to SSH into your instance at least once to maybe upload an existing save / world or to modify server configuration.

I recommend using some UI application to help navigate and manage files via SSH like [VS Code Remote Explorer](https://marketplace.visualstudio.com/items?itemName=ms-vscode.remote-explorer).

SSH into your instance using the `ec2-user` user. Example:

```bash
ssh -i "~/.ssh/<my private key>.pem" "ec2-user@<myserver>.duckdns.org"
```

- Replace `<my private key>` with the name of your private key, assuming it's saved at `~/.ssh`
- replace `<myserver>.duckdns.org` with the `hostname` you put in the Terraform `servers.tf` config for that server

> [!NOTE]
> Your SSH client may fail when connecting due to the IP changing between server restarts.
> You can delete the `~/.ssh/known_hosts` file as a quick workaround. You may also need to clear your DNS cache.

### Useful info and commands

These notes and commands are for when you are connected to the instance via SSH.

Game data EBS volume is mounted at `/srv/<game id>` (e.g `/srv/minecraft`);

Docker compose container name is `<game id>-<game main service name>-1` (e.g `minecraft-mc-1`)

Commands (using Minecraft server as an example):

- `htop`: Task manager / resource usage viewer
- `docker stats`: Shows current RAM usage vs deploy limit
- [`docker attach minecraft-mc-1`](https://docker-minecraft-server.readthedocs.io/en/latest/commands/#enabling-interactive-console): (Minecraft only) Attach terminal to Minecraft server console
- `docker logs minecraft-mc-1 -f`: Latest logs from the container
- `sudo systemctl stop auto_shutdown.timer`: Stops the systemd timer which prevents the instance from being shut down automatically until next reboot. Don't forget to shutdown/reboot manually or start the timer again!
- `sudo conntrack -L --dst-nat | grep -w <game main port> | grep -w ESTABLISHED`: Lists currently estabilished network connections with the container

### CloudWatch

CloudWatch log groups are created for the Lambda and VPC flow logs.
They can help you troubleshoot problems with connectivity and Discord interactions.

X-Ray tracing is also enabled (mainly for debugging the project), however you need to [manually set up SNS](https://docs.aws.amazon.com/xray/latest/devguide/xray-services-sns.html#xray-services-sns-configuration) permissions so the traces show up correctly in the Trace Map / etc.
_Or else the trace will stop at SNS and a new trace will begin in the Lamba context_

## Notes and acknowledgements

This project was made for studying purposes mainly. The following repos and articles were very helpful in the learning and development process:

- [doctorray117/minecraft-ondemand](https://github.com/doctorray117/minecraft-ondemand) - The main motivation for this project, I wanted to do something similar but less complex and even cheaper (without Route 53, EFS, DataSync, Twilio and Minecraft watchdog)
- [JKolios/minecraft-ondemand-terraform](https://github.com/JKolios/minecraft-ondemand-terraform) - Gave me an general idea of what I had to do
- [mamoit/minecraft-ondemand-terraform](https://github.com/mamoit/minecraft-ondemand-terraform) - I almost went with this solution instead of creating my own, but I wanted to use EC2 directly instead of ECS + Fargate for slightly cheaper costs
- [Lemmons/minecraft-spot](https://github.com/Lemmons/minecraft-spot/) - Some Cloud-init and Terraform reference
- [vincss/mcEmptyServerStopper](https://github.com/vincss/mcEmptyServerStopper) - I was using this before I migrated to Docker and [itzg/docker-minecraft-server](https://github.com/itzg/docker-minecraft-server)
- [Giving kids control of an EC2 instance via discord
  ](https://drpump.github.io/ec2-discord-bot/) - Gave me the push to use Discord to reduce costs and simplify some of the workflow, and almost made me use GCP instead of AWS
- Thanks megamush in the AWS Discord for giving me some help and suggestions

# Minecraft Spot Discord

Spin up a cheap EC2 Spot instance to host a Minecraft server managed by Discord chat.

Made for a personal and small server with few players.

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

1. The player types `/start` on a Discord server
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

**TL;DR: USD 0.5 for 30h of gameplay per month** on a 2x 2.5GHz vCPU, 8GB RAM instance

- **[AWS Princing Calculator estimate]()**
  - Does not include Public IP cost, see table below
- Last updated: June 2024
- Region assumed is `us-east-2` (Ohio)
- Prices are in USD
- Assumes usage of [Always Free](https://aws.amazon.com/free/?nc2=h_ql_pr_ft&all-free-tier.sort-by=item.additionalFields.SortRank&all-free-tier.sort-order=asc&awsf.Free%20Tier%20Types=tier%23always-free&awsf.Free%20Tier%20Categories=*all) monthly offers (different from 12 month Free Tier)
  - This is important mostly due to the monthly free 100GB [outbound data transfer](https://aws.amazon.com/ec2/pricing/on-demand/?nc1=h_ls#Data_Transfer) from EC2 to the internet. Otherwise due to the current price rates and regular gameplay network usage, it would cost more than the instance itself
- EC2 prices (in the table below) do not account for surplus vCPU usage credits charges. See [Earn CPU credits](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/burstable-credits-baseline-concepts.html#earning-CPU-credits) and [When to use unlimited mode versus fixed CPU](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/burstable-performance-instances-unlimited-mode-concepts.html#when-to-use-unlimited-mode). So treat it as a minimum for unlimited-mode burstable instance types
  - You can always change the instance type if you don't need ~6GB of JVM heap size for your server. Don't forget to change the other related Terraform variables!

### Notable expenses

| Service   | Sub-service / description                                                                                         | Price/hour  | Price 30h/month |
| --------- | ----------------------------------------------------------------------------------------------------------------- | ----------- | --------------- |
| EC2       | [`t4g.large`](https://instances.vantage.sh/aws/ec2/t4g.large) **spot** instance                                   | $0.0128     | $0.384          |
| EBS       | 10GB volume for Minecraft data                                                                                    | $0.00109    | $0.032          |
| EBS       | Daily volume snapshots, for backup                                                                                | -           | ~$0.03          |
| VPC       | [Public IPv4 address](https://aws.amazon.com/pt/blogs/aws/new-aws-public-ipv4-address-charge-public-ip-insights/) | $0.005      | $0.015          |
| **Total** |                                                                                                                   | **$0.0189** | **$0.461**      |

### Negligible expenses / Free

Lambda; SNS; KMS; CloudWatch / X-Ray; Network data transfer from EC2 to internet.

Costs that are $0.01 or less per month. See AWS Pricing Calculator estimate.

## Prerequisites

- An Discord app on the [Developer portal](https://discord.com/developers/applications)
- A [Duck DNS](https://www.duckdns.org/about.jsp) account and domain

## Running

Requirements: Terraform, Python 3.6+ (due to [terraform-aws-lambda](https://github.com/terraform-aws-modules/terraform-aws-lambda)), Node 18+ (to compile Lambda functions)

TODO

### Example `terraform.tfvars`

### Notes

## Testing and troubleshooting

https://docs.aws.amazon.com/xray/latest/devguide/xray-services-sns.html#xray-services-sns-configuration

## To-do

I may or may not do these in the future:

- Isolate the reusable resources into a Terraform module so it's easy to spin more than one instance - similar to [mamoit/minecraft-ondemand-terraform](https://github.com/mamoit/minecraft-ondemand-terraform)
- Make it generic so other games are supported - similar to [Lemmons/minecraft-spot](https://github.com/Lemmons/minecraft-spot)
  - Create some generic solution for auto-stop, watching active connections etc.

## Notes and acknowledgements

This project was made for studying purposes mainly. The following repos and articles were very helpful in the learning and development process:

- [doctorray117/minecraft-ondemand](https://github.com/doctorray117/minecraft-ondemand) - The main motivation for this project, I wanted to do something similar but less complex and even cheaper (without Route 53, EFS, DataSync, Twilio and Minecraft watchdog)
- [JKolios/minecraft-ondemand-terraform](https://github.com/JKolios/minecraft-ondemand-terraform) - Gave me an general idea of what I had to do
- [mamoit/minecraft-ondemand-terraform](https://github.com/mamoit/minecraft-ondemand-terraform) - I almost went with this solution instead of creating my own, but I wanted to use EC2 directly instead of ECS + Fargate for slightly cheaper costs
- [vincss/mcEmptyServerStopper](https://github.com/vincss/mcEmptyServerStopper) - I was using this before I migrated to Docker and [itzg/docker-minecraft-server](https://github.com/itzg/docker-minecraft-server)
- [Giving kids control of an EC2 instance via discord
  ](https://drpump.github.io/ec2-discord-bot/) - Gave me the push to use Discord to reduce costs and simplify some of the workflow, and almost made me use GCP instead of AWS.

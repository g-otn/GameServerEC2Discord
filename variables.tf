variable "aws_access_key" {
  description = "AWS Access Key for AWS provider"
  type        = string
  sensitive   = true
}

variable "aws_secret_key" {
  description = "AWS Secret Key for AWS provider"
  type        = string
  sensitive   = true
}

variable "aws_region" {
  description = "Region where to create the resources, choose one with cheap EC2 Spot prices"
  type        = string
  default     = "us-east-2"
}

variable "subnet_az" {
  description = "Specific availability zone where to create the subnet, instance, EBS volumes and other VPC resources"
  type        = string
  default     = "us-east-2a"
}

variable "name" {
  description = "Short name to identify created resources. To be safe, only 15 characters or less, alphanumeric character and spaces"
  type        = string
  default     = "Minecraft Server"
}

variable "discord_app_id" {
  default = "Discord App ID for webhook API usage"
  type    = string
}

variable "discord_app_public_key" {
  description = "Discord App public key for webhook validation"
  type        = string
}

variable "discord_bot_token" {
  description = "Discord App bot token for interaction message updates"
  type        = string
  sensitive   = true
}

variable "duckdns_domain" {
  description = "The name of the subdomain (not the full hostname/URL) registered in Duck DNS"
  type        = string
}

variable "duckdns_token" {
  description = "Duck DNS token"
  type        = string
  sensitive   = true
}

variable "duckdns_interval" {
  description = "Interval for the shell script to update the IP. Shouldn't matter much"
  type        = string
  default     = "5m"
}

variable "extra_ingress_rules" {
  description = "Ingress rules to add to the instance security group, required if a plugin requires a specific port open"
  type = map(object({
    description = string
    from_port   = number
    to_port     = number
    ip_protocol = string
    cidr_ipv4   = string
  }))
  default = {}
}

variable "instance_key_pair_name" {
  description = "Name of the EC2 Key Pair used to SSH into the instance"
  type        = string
  default     = "minecraft-spot-discord"
}

// ssh-keygen -t ed25519 -C "Minecraft Server"
variable "instance_key_pair_public_key" {
  description = "Public key of the EC2 Key Pair used to SSH into the instance"
  type        = string
}

variable "instance_timezone" {
  description = "Custom timezone for the instance OS set via cloud-init. See timedatectl"
  type        = string
  default     = ""
}

variable "instance_type" {
  description = "Instance type for the EC2 Spot Instance. See https://instances.vantage.sh/?min_memory=2&min_vcpus=1&region=us-east-2&cost_duration=daily"
  type        = string
  default     = "t4g.large"
}

variable "minecraft_data_volume_size" {
  description = "The size, in GB of the EBS volume storing the Minecraft server"
  type        = number
  default     = 5
}

variable "minecraft_compose_service_top_level_elements" {
  description = "Override/add other elements to the Minecraft server compose service"
  type        = map(any)
  default     = {}
}

variable "minecraft_port" {
  description = "Main Minecraft port, if you change this, you must change the related variables too"
  type        = number
  default     = 25565
}

variable "minecraft_compose_ports" {
  description = "See https://docker-minecraft-server.readthedocs.io/en/latest/#using-docker-compose"
  type        = set(string)
  default     = ["25565:25565"]
}

variable "minecraft_compose_environment" {
  description = "See https://docker-minecraft-server.readthedocs.io/en/latest/variables"
  type        = map(string)
  default = {
    "INIT_MEMORY" : "6100M"
    "MAX_MEMORY" : "6100M"
  }
}

variable "minecraft_compose_limits" {
  description = "See https://docs.docker.com/compose/compose-file/deploy/#resources"
  type        = map(string)
  default = {
    memory : "7400mb"
  }
}

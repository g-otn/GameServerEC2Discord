variable "aws_access_key" {
  type      = string
  sensitive = true
}

variable "aws_secret_key" {
  type      = string
  sensitive = true
}

variable "aws_region" {
  type    = string
  default = "us-east-2"
}

variable "subnet_az" {
  type    = string
  default = "us-east-2a"
}

variable "name" {
  description = "Short name for use in resources"
  type        = string
  default     = "Minecraft Server"
}

variable "discord_public_key" {
  type = string
}

variable "duckdns_domain" {
  type = string
}

variable "duckdns_token" {
  type      = string
  sensitive = true
}

variable "duckdns_interval" {
  type    = string
  default = "5m"
}

variable "extra_ingress_rules" {
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
  description = "Instance type for the EC2 Spot Instance"
  type        = string
  // Please check out:
  // - https://instances.vantage.sh/?min_memory=2&min_vcpus=1&region=us-east-2&cost_duration=daily
  // - https://aws.amazon.com/ec2/spot/instance-advisor/
  default = "t4g.medium"
}

variable "minecraft_data_volume_size" {
  description = "The size, in GB of the EBS volume storing the Minecraft server"
  type        = number
  default     = 5
}

variable "minecraft_compose_service_top_level_elements" {
  type    = map(any)
  default = {}
}

variable "minecraft_port" {
  type    = number
  default = 25565
}


variable "minecraft_compose_ports" {
  type    = set(string)
  default = ["25565:25565"]
}

variable "minecraft_compose_environment" {
  type    = map(string)
  default = {}
}

variable "minecraft_compose_limits" {
  type = map(string)
  default = {
    memory : "3500mb"
  }
}

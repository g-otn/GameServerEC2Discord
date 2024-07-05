# ----------------------------------------------------------------
# Main variables
# ----------------------------------------------------------------

variable "id" {
  description = "A unique identifier across all servers and all regions for this server."
  type        = string
}

variable "game" {
  description = "The game this server will host"
  type        = string

  validation {
    condition     = contains(["minecraft", "unknown"], var.game)
    error_message = "Valid values are: minecraft, unknown"
  }
}

variable "unknown_game_name" {
  description = "If using unknown as the game, you can use this variable to help name the resources created. Alphanumeric characters only. No spaces, etc"
  type        = string
  default     = "Unknown"
}

variable "ddns_service" {
  description = "DDNS service to use. If 'none' is chosen, DDNS service will be disabled and the instance will only be acessible via dynamic IP/DNS"
  type        = string
  default     = "duckdns"

  validation {
    condition     = contains(["duckdns", "none"], var.ddns_service)
    error_message = "Valid values are: duckdns"
  }
}

variable "main_port" {
  description = "Main TCP port used by players to connect to the server. Also used to check for connections to perform auto shutdown when server is empty"
  type        = number
}

# ----------------------------------------------------------------
# AWS variables
# ----------------------------------------------------------------

variable "az" {
  description = "AWS availability zone from the ones defined in base_region in which to place the server instance in"
  type        = string

  validation {
    condition     = contains(base_region.azs, var.aws_az)
    error_message = "Availability zone must be one of ${base_region.azs}"
  }
}

variable "instance_type" {
  description = "Instance type for the EC2 Spot Instance. See https://instances.vantage.sh/?min_memory=2&min_vcpus=1&region=us-east-2&cost_duration=daily"
  type        = string
  default     = ""
}

variable "data_volume_size" {
  description = "The size, in GB of the EBS volume storing the game server data"
  type        = number
  default     = 10
}

variable "sg_ingress_rules" {
  description = "Extra ingress rules to add to the instance security group, besides the main port"
  type = map(object({
    description = string
    from_port   = number
    to_port     = number
    ip_protocol = string
    cidr_ipv4   = string
  }))
  default = {}
}

# ----------------------------------------------------------------
# Docker compose variables
# ----------------------------------------------------------------
variable "compose_game_ports" {
  description = "The ports to expose and map to the game's Docker Compose service. Use if you want to expose extra ports from the container to outside the instance"
  type        = list(string)
}

variable "compose_game_environment" {
  description = "The environment variables section of the game's Docker compose service. Required if you need another port to be accessible from the internet"
  type        = map(string)
}

variable "compose_game_limits" {
  description = "The deployment resource limits section of the game's Docker compose service. Use to determine hard limits on memory and cpu to help prevent the instance from hanging. See https://docs.docker.com/compose/compose-file/deploy/#resources"
  type        = map(any)
}

variable "compose_services" {
  description = "Extra Docker Compose services to run alongside the game's service. Can also be used to set up unknown games"
  type        = map(any)
  default     = {}
}

variable "compose_top_level_elements" {
  description = "Docker Compose file top level elements, for unknown games"
}

# ----------------------------------------------------------------
# Other instance-related variables
# ----------------------------------------------------------------

variable "instance_timezone" {
  description = "Custom timezone for the instance OS set via cloud-init. See timedatectl / https://gist.github.com/adamgen/3f2c30361296bbb45ada43d83c1ac4e5"
  type        = string
  default     = ""
}

# ----------------------------------------------------------------
# DDNS variables
# ----------------------------------------------------------------

variable "duckdns_domain" {
  description = "The name of the subdomain (not the full hostname/URL) registered in Duck DNS"
  type        = string
}

variable "duckdns_token" {
  description = "Duck DNS token"
  type        = string
  sensitive   = true
}

# ----------------------------------------------------------------
# Discord variables
# ----------------------------------------------------------------

variable "discord_app_id" {
  default = "Discord App ID for Discord API usage"
  type    = string
}

variable "discord_app_public_key" {
  description = "Discord App public key for webhook validation"
  type        = string
}

variable "discord_bot_token" {
  description = "Discord App bot token for Discord API auth"
  type        = string
  sensitive   = true
}

# ----------------------------------------------------------------
# Base variables
# ----------------------------------------------------------------

variable "global" {
  description = "Global/common data required by the server"
  type        = object(any)
}

variable "region" {
  description = "Region-specific data required by the server"
  type        = object(any)
}

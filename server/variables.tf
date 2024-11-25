# ----------------------------------------------------------------
# Main variables
# ----------------------------------------------------------------

variable "id" {
  description = "An alphanumeric identifier for this server, unique across all servers and all regions. Will also be used in discord interactions"
  type        = string
  validation {
    condition     = can(regex("^[[:alnum:]]+$", var.id))
    error_message = "ID must be alphanumeric"
  }
}

variable "game" {
  description = "The game this server will host"
  type        = string

  validation {
    condition     = contains(["minecraft", "terraria", "factorio", "satisfactory", "valheim", "palworld", "linuxgsm", "custom"], var.game)
    error_message = "Valid values are: minecraft, terraria, factorio, satisfactory, valheim, palworld, linuxgsm, custom"
  }
}

variable "custom_game_name" {
  description = "If using 'custom' as the game, you can use this variable to help name the resources created. Alphanumeric values only"
  type        = string
  default     = "Custom"
  validation {
    condition     = can(regex("^[[:alnum:]]+$", var.custom_game_name)) && length(var.custom_game_name) <= 20
    error_message = "ID must be alphanumeric and less or equal to 20 characters"
  }
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
  description = "Main TCP port used by players to connect to the server. Also used to check for connections to perform auto shutdown when server is empty.  Automatically set based on game"
  type        = number
  default     = null
  validation {
    condition     = (var.game != "custom" && var.game != "linuxgsm") || var.main_port != null
    error_message = "Main port must be set for custom games and LinuxGSM"
  }
}

# ----------------------------------------------------------------
# AWS variables
# ----------------------------------------------------------------

variable "az" {
  description = "AWS availability zone in which to place the server instance in. Must be one of the azs defined in the chosen base_region"
  type        = string

  validation {
    condition     = contains(var.base_region.available_azs, var.az)
    error_message = "AZ must be one of the available AZs in the chosen region"
  }
}

variable "instance_type" {
  description = "Instance type for the EC2 Spot Instance. Make sure to update related variables (e.g docker memory limits) if you change this. See https://instances.vantage.sh/?min_memory=2&min_vcpus=1&region=us-east-2&cost_duration=daily. Automatically set based on game"
  type        = string
  default     = null
  validation {
    condition     = (var.game != "custom" && var.game != "linuxgsm") || var.instance_type != null
    error_message = "Instance type must be set for custom games and LinuxGSM"
  }
}

variable "arch" {
  description = "Desired architecture for the instance. Used to select the correct AMI. Must match instance type architecture. Automatically set based on game"
  type        = string
  default     = null
  validation {
    condition     = var.instance_type != null ? (var.arch == "arm64" || var.arch == "x86_64") : var.arch == null
    error_message = "When specifiying instance type, you must specify arch too. Arch must be 'arm64' or 'x86_64' and must match the instance type"
  }
}

variable "root_volume_size" {
  description = "The size, in GB, of the root volume. Make sure it's enough! You'll probably want at least 3GB"
  type        = number
  default     = 4 // 2GB is the minimum for AL2023 minimal, but by default it seems to use ~1.9GB, and we still need storage for docker images / etc
}

variable "data_volume_size" {
  description = "The size, in GB, of the EBS volume storing the game server data. Make sure it's enough! Automatically set based on game"
  type        = number
  default     = null
  validation {
    condition     = (var.game != "custom" && var.game != "linuxgsm") || var.data_volume_size != null
    error_message = "Data volume size must be set for custom and linuxgsm games"
  }
}

variable "data_volume_final_snapshot" {
  description = "Create final snapshot when destroying data volume"
  type        = bool
  default     = true
}

variable "snapshot_id" {
  description = "The snapshot ID to use as the base of the data volume. Can be used to restore backups"
  type        = string
  default     = null
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

variable "data_volume_snapshots" {
  description = "Enable data volume automatic snapshots via DLM"
  type        = bool
  default     = false
}

variable "data_volume_snapshot_retain_count" {
  description = "How many snapshots to retain. Snapshots are taken daily, so the number will correspond to the number of days"
  type        = number
  default     = 5
}

variable "data_volume_snapshot_create_time" {
  description = "The time to take the daily snapshot (UTC)"
  type        = string
  default     = "09:39"
}


# ----------------------------------------------------------------
# Docker compose variables
# ----------------------------------------------------------------

variable "compose_game_ports" {
  description = "The ports to expose and map to the game's Docker Compose service. Use if you want to expose extra ports from the container to outside the instance. Automatically set based on game"
  type        = list(string)
  default     = null
  validation {
    condition     = var.game != "linuxgsm" || var.compose_game_ports != null
    error_message = "Compose game ports must be set when using LinuxGSM. Check the required or default ports for your chosen game"
  }
}

variable "compose_game_environment" {
  description = "The environment variables section of the game's Docker compose service. Required if you need another port to be accessible from the internet"
  type        = map(string)
  default     = {}
}

variable "compose_game_limits" {
  description = "The deployment resource limits section of the game's Docker compose service. Use to determine hard limits on memory and cpu to help prevent the instance from hanging. See https://docs.docker.com/compose/compose-file/deploy/#resources"
  type        = map(any)
  default     = {}
}

variable "compose_game_elements" {
  description = "Attributes for the game's Docker Compose main service. Can be used to override image, environment, ports, volumes, etc"
  type        = map(any)
  default     = {}
}

variable "compose_services" {
  description = "Extra Docker Compose services to run alongside the game's service. Can also be used to set up unknown games"
  type        = map(any)
  default     = {}
}

variable "compose_top_level_elements" {
  description = "Docker Compose file top level elements, for unknown games"
  type        = map(any)
  default     = {}
}

# ----------------------------------------------------------------
# Other instance-related variables
# ----------------------------------------------------------------

variable "instance_timezone" {
  description = "Custom timezone for the instance OS set via cloud-init. See timedatectl / https://gist.github.com/adamgen/3f2c30361296bbb45ada43d83c1ac4e5"
  type        = string
  default     = null
}

variable "auto_shutdown" {
  description = "Create files to manage auto shutdown. If disabled the instance won't shut down automatically! Useful to disable for debugging purposes"
  type        = bool
  default     = true
}

variable "watch_connections" {
  description = "Create files to watch for connections between the compose main service. If disabled the instance won't shut down automatically for some games! Useful to disable for debugging purposes"
  type        = bool
  default     = null
}


# ----------------------------------------------------------------
# DDNS variables
# ----------------------------------------------------------------

variable "hostname" {
  description = "The full hostname created in your DDNS service (e.g myserver.duckdns.org, myserver.ddns.net)"
  type        = string
}

variable "duckdns_token" {
  description = "Duck DNS token"
  type        = string
  sensitive   = true
  default     = null
  validation {
    condition     = var.ddns_service == "duckdns" ? var.duckdns_token != null : true
    error_message = "Duck DNS token must be set if using Duck DNS"
  }
}

variable "noip_ddns_key_username" {
  description = "No-IP Hostname DDNS key username (for use with DUC + all.ddnskey.com)"
  type        = string
  default     = null
}

variable "noip_ddns_key_password" {
  description = "No-IP Hostname DDNS key password (for use with DUC + all.ddnskey.com)"
  type        = string
  sensitive   = true
  default     = null
}

# ----------------------------------------------------------------
# Base variables
# ----------------------------------------------------------------

variable "base_region" {
  description = "Common values"
  type = object({
    vpc_id         = string
    public_subnets = list(string)
    main_sg_id     = string
    key_pair_name  = string
    available_azs  = list(string)
  })
}

variable "iam_role_dlm_lifecycle_arn" {
  description = "Global; ARN of the IAM role that allows DLM to manage the lifecycle of the data volume snapshots"
  type        = string
}

# ----------------------------------------------------------------
# Game-specific variables
# ----------------------------------------------------------------

variable "terraria_world_size" {
  description = "The Terraria server world size"
  type        = number
  default     = 2
  validation {
    condition     = var.terraria_world_size >= 1 && var.terraria_world_size <= 3
    error_message = "Terraria world size autocreate TShock paramter must be between 1 (small) and 3 (big)"
  }
}

variable "linuxgsm_game_shortname" {
  description = "The game 'shortname' used by LinuxGSM to identify the game server. See https://github.com/GameServerManagers/LinuxGSM/blob/master/lgsm/data/serverlist.csv"
  type        = string
  default     = null
  validation {
    condition     = var.linuxgsm_game_shortname != null || var.game != "linuxgsm"
    error_message = "If using 'linuxgsm', the LinuxGSM game shortname must be set"
  }
}

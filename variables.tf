# ----------------------------------------------------------------
# AWS provider variables
# ----------------------------------------------------------------

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

variable "base_global_provider_region" {
  description = "AWS region in which to create the resources from base_global"
  type        = string
  default     = "us-east-1"
}

# ----------------------------------------------------------------
# AWS variables
# ----------------------------------------------------------------

variable "ssh_public_key" {
  description = "Public key data in 'Authorized Keys' format to allow SSH-ing into the instances"
  type        = string
}

# ----------------------------------------------------------------
# DDNS variables
# ----------------------------------------------------------------

variable "duckdns_token" {
  description = "Duck DNS token"
  type        = string
  sensitive   = true
  default     = null
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

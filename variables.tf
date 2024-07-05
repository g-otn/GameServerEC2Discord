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

variable "minecraft_compose_ports" {
  description = "See "
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
  description = "See "
  type        = map(string)
  default = {
    memory : "7400mb"
  }
}

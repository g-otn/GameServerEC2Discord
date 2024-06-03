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

variable "minecraft_port" {
  type = number
  default = 25565
}
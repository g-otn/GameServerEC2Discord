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

variable "extra_ingress_rules" {
  type = map(object({
    description = string
    from_port   = number
    to_port     = number
    ip_protocol    = string
    cidr_ipv4 = string
  }))
  default = {
    "Simple Voice Chat": {
      description = "Simple Voice Chat mod server"
      from_port = 24454
      to_port = 24454
      ip_protocol = "udp"
      cidr_ipv4 = "0.0.0.0/0"
    }
  }
}

variable "instance_key_pair_name" {
  description = "Name of the EC2 Key Pair used to SSH into the instance"
  type = string
  default = "minecraft-spot-discord"
}

// ssh-keygen -t ed25519 -C "Minecraft Server"
variable "instance_key_pair_public_key" {
  default = "Public key of the EC2 Key Pair used to SSH into the instance"
  type = string
}
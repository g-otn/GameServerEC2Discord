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

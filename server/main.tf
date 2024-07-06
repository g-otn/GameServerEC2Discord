locals {
  prefix         = "SpotDiscord"
  prefix_sm      = "SD"
  prefix_id_game = "${local.prefix} ${var.game} ${var.game}"

  server_data_path = "/srv/${var.game == "custom" ? var.custom_game_name : var.game}"

  game_defaults = {
    minecraft = {
      game_name                 = "Minecraft"
      instance_type             = "t4g.large"
      data_volume_size          = coalesce(var.data_volume_size, 10)
      compose                   = local.compose_defaults.minecraft
      compose_main_service_name = "mc"
    }
    custom = {
      game_name                 = var.custom_game_name
      instance_type             = var.instance_type
      data_volume_size          = var.data_volume_size
      compose                   = local.compose_defaults.custom
      compose_main_service_name = "main"
    }
  }
  game = local.game_defaults[var.game]

  compose_defaults = {
    minecraft = merge({
      // https://docker-minecraft-server.readthedocs.io/en/latest/#using-docker-compose
      services : {
        "${local.game_defaults.minecraft.compose_main_service_name}" : {
          image : "itzg/minecraft-server",
          tty : true,
          stdin_open : true,
          ports : try(var.compose_game_ports, ["25565:25565"]),
          environment : merge({
            // https://docker-minecraft-server.readthedocs.io/en/latest/variables
            EULA : true,
            SNOOPER_ENABLED : false,

            TYPE : "PAPER"

            LOG_TIMESTAMP : true
            USE_AIKAR_FLAGS : true

            ENABLE_AUTOSTOP : true
            AUTOSTOP_TIMEOUT_EST : 600
            AUTOSTOP_TIMEOUT_INIT : 600

            VIEW_DISTANCE : 12
            MAX_PLAYERS : 15

            INIT_MEMORY : "6100M"
            MAX_MEMORY : "6100M"
          }, var.compose_game_environment)
          volumes : [
            "${local.game_defaults.minecraft.server_data_path}:/data"
          ]
          deploy : {
            resources : {
              limits : var.compose_game_limits
            }
          }
          restart : "no"
        }
      }
    }, var.compose_top_level_elements)
    custom = merge({
      services : var.compose_services
    }, var.compose_top_level_elements)
  }
}

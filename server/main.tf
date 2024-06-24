locals {
  prefix    = "SpotDiscord"
  prefix_sm = "SD"

  game_defaults = {
    minecraft = {
      data_path = "/srv/minecraft"
    }
    unknown = {
      game_id   = replace(var.unknown_game_name, "/\\W|_|\\s/", "_")
      data_path = "/srv/${local.game_defaults.unknown.game_id}"
    }
  }
  game = local.game_defaults[var.game]

  compose_defaults = {
    minecraft = {
      services : {
        mc : {
          image : "itzg/minecraft-server",
          tty : true,
          stdin_open : true,
          ports : try(var.compose_game_ports),
          environment : merge({
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
          }, var.compose_game_environment)
          volumes : [
            "${local.game_defaults.minecraft.data_path}:/data"
          ]
          deploy : {
            resources : {
              limits : var.compose_game_limits
            }
          }
          restart : "no"
        }
      }
    }
    unknown = {
      services : var.compose_game_services
    }
  }
}

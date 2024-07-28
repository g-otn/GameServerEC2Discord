locals {
  common_tags = {
    "${local.prefix}:Game" : var.game
    "${local.prefix}:ServerId" : var.id
  }

  prefix            = "GameServerEC2Discord"
  prefix_sm         = "GSED"
  prefix_id_game    = "${local.prefix} ${var.id} ${local.game.game_name}"
  prefix_sm_id_game = "${local.prefix_sm} ${var.id} ${local.game.game_name}"

  subnet_id = var.base_region.public_subnets[index(var.base_region.available_azs, var.az)]

  duckdns_domain = var.ddns_service == "duckdns" ? regex("^([^.]+)\\.duckdns\\.org$", var.hostname)[0] : null

  server_data_path = "/srv/${var.game == "custom" ? lower(var.custom_game_name) : var.game}"

  game_defaults_map = {
    minecraft = {
      game_name                 = "Minecraft"
      instance_type             = coalesce(var.instance_type, "r8g.medium")
      arch                      = coalesce(var.arch, "arm64")
      data_volume_size          = coalesce(var.data_volume_size, 10)
      compose_main_service_name = "mc"
      main_port                 = coalesce(var.main_port, 25565)
      watch_connections         = coalesce(var.watch_connections, false)
    }
    terraria = {
      game_name                 = "Terraria"
      instance_type             = coalesce(var.instance_type, "m7a.medium")
      arch                      = coalesce(var.arch, "x86_64")
      data_volume_size          = coalesce(var.data_volume_size, 1)
      compose_main_service_name = "terraria"
      main_port                 = coalesce(var.main_port, 7777)
      watch_connections         = coalesce(var.watch_connections, true)
    }
    custom = {
      game_name                 = var.custom_game_name
      instance_type             = var.instance_type
      arch                      = var.arch
      data_volume_size          = var.data_volume_size
      compose_main_service_name = "main"
      main_port                 = var.main_port
      watch_connections         = coalesce(var.watch_connections, true)
    }
  }
  game                     = local.game_defaults_map[var.game]
  compose_file_content_b64 = base64encode(yamlencode(local.compose_map[var.game]))

  compose_map = {
    minecraft = merge({
      // https://docker-minecraft-server.readthedocs.io/en/latest/#using-docker-compose
      services : {
        "${local.game_defaults_map.minecraft.compose_main_service_name}" : {
          image : "itzg/minecraft-server",
          tty : true,
          stdin_open : true,
          ports : coalesce(var.compose_game_ports, ["25565:25565"]),
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

            INIT_MEMORY : "6200M"
            MAX_MEMORY : "6200M"
          }, var.compose_game_environment)
          volumes : [
            "${local.server_data_path}:/data"
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

    terraria = merge({
      services : {
        "${local.game_defaults_map.terraria.compose_main_service_name}" : {
          image : "ryshe/terraria",
          ports : coalesce(var.compose_game_ports, ["7777:7777"]),
          environment : merge({}, var.compose_game_environment)
          command : "-world /root/.local/share/Terraria/Worlds/${var.id}.wld -autocreate ${var.terraria_world_size}"
          volumes : [
            "${local.server_data_path}:/root/.local/share/Terraria/Worlds"
          ]
        }
      }
    }, var.compose_top_level_elements)

    custom = merge({
      services : var.compose_services
    }, var.compose_top_level_elements)
  }
}

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

  data_mount_path     = "/srv/${var.game == "custom" ? lower(var.custom_game_name) : var.game}"
  data_subfolder_path = "${local.data_mount_path}/data"
  game_defaults_map = {
    minecraft = {
      game_name                 = "Minecraft"
      instance_type             = coalesce(var.instance_type, "r8g.medium")
      arch                      = coalesce(var.arch, "arm64")
      data_volume_size          = coalesce(var.data_volume_size, 5)
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
    factorio = {
      game_name                 = "Factorio"
      instance_type             = coalesce(var.instance_type, "m7a.medium")
      arch                      = coalesce(var.arch, "x86_64")
      data_volume_size          = coalesce(var.data_volume_size, 2)
      compose_main_service_name = "factorio"
      main_port                 = coalesce(var.main_port, 34197)
      watch_connections         = coalesce(var.watch_connections, true)
    }
    linuxgsm = {
      game_name                 = "LinuxGSM"
      instance_type             = var.instance_type
      arch                      = var.arch
      data_volume_size          = var.data_volume_size
      compose_main_service_name = var.linuxgsm_game_shortname
      main_port                 = var.main_port
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
  game = local.game_defaults_map[var.game]

  compose = merge({
    services : merge({
      "${local.game.compose_main_service_name}" : merge(local.main_service_map[var.game], var.compose_game_elements)
    }, var.compose_services)
  }, var.compose_top_level_elements)
  compose_file_content_b64 = base64encode(yamlencode(local.compose))

  main_service_map = {
    // https://docker-minecraft-server.readthedocs.io/en/latest/#using-docker-compose
    minecraft = {
      container_name : "minecraft",
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
        "${local.data_subfolder_path}:/data"
      ]
      deploy : {
        resources : {
          limits : var.compose_game_limits
        }
      }
      restart : "no"
      stop_grace_period : "1m"
    }

    terraria = {
      container_name : "terraria",
      image : "ryshe/terraria",
      ports : coalesce(var.compose_game_ports, ["7777:7777"]),
      environment : merge({}, var.compose_game_environment)
      command : "-world /root/.local/share/Terraria/Worlds/${var.id}.wld -autocreate ${var.terraria_world_size}"
      volumes : [
        "${local.data_subfolder_path}:/root/.local/share/Terraria/Worlds"
      ]
      restart : "no"
      stop_grace_period : "1m"
    }

    factorio = {
      container_name : "factorio",
      image : "factoriotools/factorio:stable",
      ports : coalesce(var.compose_game_ports, ["34197:34197/udp"]),
      environment : merge({}, var.compose_game_environment)
      volumes : [
        "${local.data_subfolder_path}:/factorio",
      ]
      restart : "no"
      stop_grace_period : "1m"
    }

    linuxgsm = {
      container_name : coalesce(var.linuxgsm_game_shortname, "invalid")
      image : "gameservermanagers/gameserver:${coalesce(var.linuxgsm_game_shortname, "invalid")}"
      ports : var.compose_game_ports
      environment : merge({}, var.compose_game_environment)
      volumes : [
        "${local.data_subfolder_path}:/data",
      ]
      restart : "no"
      stop_grace_period : "1m"
    }

    custom = {}
  }
}

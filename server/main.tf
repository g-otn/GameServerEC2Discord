locals {

  prefix            = "GameServerEC2Discord"
  prefix_sm         = "GSED"
  prefix_id_game    = "${local.prefix} ${var.id} ${local.game.game_name}"
  prefix_sm_id_game = "${local.prefix_sm} ${var.id} ${local.game.game_name}"

  common_tags = {
    "${local.prefix}:Game" : var.game
    "${local.prefix}:ServerId" : var.id
  }

  subnet_id = var.base_region.public_subnets[index(var.base_region.available_azs, var.az)]

  sg_ingress_rules = merge(var.sg_ingress_rules, coalesce(local.game.sg_ingress_rules, {}))

  duckdns_domain = var.ddns_service == "duckdns" ? regex("^([^.]+)\\.duckdns\\.org$", var.hostname)[0] : null

  data_mount_path     = "/srv/${var.game == "custom" ? lower(var.custom_game_name) : var.game}"
  data_subfolder_path = "${local.data_mount_path}/data"

  game = local.game_defaults_map[var.game]

  compose = merge({
    services : merge({
      "${local.game.compose_main_service_name}" : merge(local.main_service_map[var.game], var.compose_game_elements)
    }, var.compose_services)
  }, var.compose_top_level_elements)

  compose_file_content_b64 = base64encode(yamlencode(local.compose))


  # ----------------------------------------------------------------
  # Default server values for each game
  # ----------------------------------------------------------------

  game_defaults_map = {
    minecraft = {
      game_name                 = "Minecraft"
      instance_type             = coalesce(var.instance_type, "r8g.medium")
      arch                      = coalesce(var.arch, "arm64")
      data_volume_size          = coalesce(var.data_volume_size, 5)
      compose_main_service_name = "mc"
      main_port                 = coalesce(var.main_port, 25565)
      sg_ingress_rules          = {}
      watch_connections         = coalesce(var.watch_connections, false)
    }
    terraria = {
      game_name                 = "Terraria"
      instance_type             = coalesce(var.instance_type, "m8g.medium")
      arch                      = coalesce(var.arch, "arm64")
      data_volume_size          = coalesce(var.data_volume_size, 1)
      compose_main_service_name = "terraria"
      main_port                 = coalesce(var.main_port, 7777)
      sg_ingress_rules          = {}
      watch_connections         = coalesce(var.watch_connections, true)
    }
    factorio = {
      game_name                 = "Factorio"
      instance_type             = coalesce(var.instance_type, "m7a.medium")
      arch                      = coalesce(var.arch, "x86_64")
      data_volume_size          = coalesce(var.data_volume_size, 2)
      compose_main_service_name = "factorio"
      main_port                 = coalesce(var.main_port, 34197)
      sg_ingress_rules          = {}
      watch_connections         = coalesce(var.watch_connections, true)
    }
    satisfactory = {
      game_name                 = "Satisfactory"
      instance_type             = coalesce(var.instance_type, "r7a.medium")
      arch                      = coalesce(var.arch, "x86_64")
      data_volume_size          = coalesce(var.data_volume_size, 6)
      compose_main_service_name = "satisfactory"
      main_port                 = coalesce(var.main_port, 7777)
      sg_ingress_rules          = {}
      watch_connections         = coalesce(var.watch_connections, true)
    }
    valheim = {
      game_name = "Valheim"
      // For some reason if instance has only one core, server seems to hang on 100% cpu during container startup
      instance_type             = coalesce(var.instance_type, "c7i.large")
      arch                      = coalesce(var.arch, "x86_64")
      data_volume_size          = coalesce(var.data_volume_size, 6)
      compose_main_service_name = "valheim"
      main_port                 = coalesce(var.main_port, 2456)
      sg_ingress_rules = {
        "extra_1" : {
          description = "Valheim extra required ports"
          from_port   = 2457
          to_port     = 2458
          ip_protocol = "udp"
          cidr_ipv4   = "0.0.0.0/0"
        }
      }
      watch_connections = coalesce(var.watch_connections, true)
    }
    palworld = {
      game_name                 = "Palworld"
      instance_type             = coalesce(var.instance_type, "c7i-flex.xlarge")
      arch                      = coalesce(var.arch, "x86_64")
      data_volume_size          = coalesce(var.data_volume_size, 6)
      compose_main_service_name = "palworld"
      main_port                 = coalesce(var.main_port, 8211)
      sg_ingress_rules = {
        "rest_api" : {
          description = "Palworld REST API"
          from_port   = 8212
          to_port     = 8212
          ip_protocol = "udp"
          cidr_ipv4   = "0.0.0.0/0"
        }
        "query" : {
          description = "Palworld Query"
          from_port   = 27015
          to_port     = 27015
          ip_protocol = "udp"
          cidr_ipv4   = "0.0.0.0/0"
        }
      }
      watch_connections = coalesce(var.watch_connections, true)
    }

    linuxgsm = {
      game_name                 = "LinuxGSM"
      instance_type             = var.instance_type
      arch                      = var.arch
      data_volume_size          = var.data_volume_size
      compose_main_service_name = var.linuxgsm_game_shortname
      main_port                 = var.main_port
      sg_ingress_rules          = {}
      watch_connections         = coalesce(var.watch_connections, true)
    }
    custom = {
      game_name                 = var.custom_game_name
      instance_type             = var.instance_type
      arch                      = var.arch
      data_volume_size          = var.data_volume_size
      compose_main_service_name = "main"
      main_port                 = var.main_port
      sg_ingress_rules          = {}
      watch_connections         = coalesce(var.watch_connections, true)
    }
  }

  # ----------------------------------------------------------------
  # Default docker compose service for each game
  # ----------------------------------------------------------------

  main_service_map = {
    // https://docker-minecraft-server.readthedocs.io/en/latest/#using-docker-compose
    minecraft = {
      container_name : "minecraft",
      image : "itzg/minecraft-server",
      tty : true,
      stdin_open : true,
      ports : concat(["25565:25565"], coalesce(var.compose_game_ports, []))
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
      ports : concat(["7777:7777"], coalesce(var.compose_game_ports, []))
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
      ports : concat(["34197:34197/udp"], coalesce(var.compose_game_ports, []))
      environment : merge({}, var.compose_game_environment)
      volumes : [
        "${local.data_subfolder_path}:/factorio",
      ]
      restart : "no"
      stop_grace_period : "1m"
    }

    satisfactory = {
      container_name : "satisfactory",
      image : "wolveix/satisfactory-server",
      ports : concat(["7777:7777/tcp", "7777:7777/udp"], coalesce(var.compose_game_ports, []))
      environment : merge({
        "MAXPLAYERS" : 4
        "PGID" : 1000
        "PUID" : 1000
        "ROOTLESS" : false
        "STEAMBETA" : false
      }, var.compose_game_environment)
      healthcheck : {
        test : ["CMD", "bash", "/healthcheck.sh"]
        interval : "30s"
        timeout : "10s"
        retries : 3
        start_period : "120s"
      }
      volumes : [
        "${local.data_subfolder_path}:/config",
      ]
      restart : "no"
      stop_grace_period : "1m"
    }

    valheim = {
      container_name : "valheim",
      image : "mbround18/valheim:latest",
      ports : concat(["2456-2458:2456-2458/udp"], coalesce(var.compose_game_ports, []))
      environment : merge(
        {
          PORT : 2456
          NAME : "${var.id}"
          WORLD : "${var.id}"
          PASSWORD : "valheim"
          PUBLIC : 1
          AUTO_BACKUP : 1
          AUTO_BACKUP_ON_SHUTDOWN : 1
          AUTO_BACKUP_PAUSE_WITH_NO_PLAYERS : 1
          WEBHOOK_INCLUDE_PUBLIC_IP : 1
        },
        var.instance_timezone != null ? { TZ : var.instance_timezone } : {},
        var.compose_game_environment
      )
      volumes : [
        "${local.data_mount_path}/backups:/home/steam/backups",
        "${local.data_mount_path}/saves:/home/steam/.config/unity3d/IronGate/Valheim",
        "${local.data_mount_path}/server:/home/steam/valheim",
      ]
      cap_add : ["SYS_NICE"]
      restart : "no"
      stop_grace_period : "2m"
    }

    palworld = {
      container_name : "palworld",
      image : "thijsvanloef/palworld-server-docker"
      ports : concat(["8211:8211/udp", "8212:8212/tcp", "27015:27015/udp"], coalesce(var.compose_game_ports, []))
      environment : merge(
        {
          # USE_DEPOT_DOWNLOADER : true // For arm64 instances
          PUID : 1000
          PGID : 1000
          PORT : 8211 # Optional but recommended
          PLAYERS : 6 # Optional but recommended
          SERVER_PASSWORD : "palworld"
          MULTITHREADING : true
          ADMIN_PASSWORD : "worldofpalsadmin"
          COMMUNITY : true # Enable this if you want your server to show up in the community servers tab, USE WITH SERVER_PASSWORD!
          SERVER_NAME : var.id
          SERVER_DESCRIPTION : "${var.id} Palworld Server"
          BACKUP_ENABLED : true
          BACKUP_CRON_EXPRESSION : "0 * * * *"
          DELETE_OLD_BACKUPS : true
        },
        var.instance_timezone != null ? { TZ : var.instance_timezone } : {},
        var.compose_game_environment
      )
      volumes : [
        "${local.data_subfolder_path}:/palworld"
      ]
      restart : "no"
      stop_grace_period : "2m"
    }


    linuxgsm = {
      container_name : coalesce(var.linuxgsm_game_shortname, "invalid")
      image : "gameservermanagers/gameserver:${coalesce(var.linuxgsm_game_shortname, "invalid")}"
      ports : concat([
        "${local.game.main_port}:${local.game.main_port}/tcp",
        "${local.game.main_port}:${local.game.main_port}/udp"
      ], coalesce(var.compose_game_ports, []))
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

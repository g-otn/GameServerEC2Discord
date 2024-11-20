# ================================================================
# Example: Minecraft with plugins, etc
# 
# See https://docker-minecraft-server.readthedocs.io/en/latest/variables/
# ================================================================

module "example_plugins" {
  # Change these to desired values
  id       = "ExamplePlugins"
  game     = "minecraft"
  hostname = "exampleplugins.duckdns.org"

  instance_timezone = "America/Bahia"

  main_port          = 34850
  compose_game_ports = ["34850:25565", "24454:24454/udp"]
  sg_ingress_rules = {
    "Simple Voice Chat" : {
      description = "Simple Voice Chat mod server"
      from_port   = 24454
      to_port     = 24454
      ip_protocol = "udp"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
  compose_game_environment = {
    "INIT_MEMORY" = "6100M"
    "MAX_MEMORY"  = "6100M"

    "ICON" = "https://picsum.photos/300/300"
    "MOTD" = "     \u00A7b\u00A7l\u00A7kaaaaaaaa\u00A7r \u00A75\u00A7lGame Server EC2 Discord\u00A7r \u00A7b\u00A7l\u00A7kaaaaaaaa\u00A7r"

    "VERSION"     = "1.20.4"
    "ONLINE_MODE" = false
    # Tip: you may have eventual problems with auto-download/update if you add plugins this way
    # you may comment them out later and/or add them manually via SSH
    "PLUGINS" = <<EOT
https://cdn.modrinth.com/data/9eGKb6K1/versions/9yRemfrE/voicechat-bukkit-2.5.16.jar

https://cdn.modrinth.com/data/UmLGoGij/versions/mr2CijyC/DiscordSRV-Build-1.27.0.jar

https://cdn.modrinth.com/data/cUhi3iB2/versions/sOk0epGX/tabtps-spigot-1.3.24.jar

https://cdn.modrinth.com/data/MubyTbnA/versions/vbGiEu4k/FreedomChat-Paper-1.6.0.jar
https://github.com/SkinsRestorer/SkinsRestorer/releases/download/15.0.13/SkinsRestorer.jar

https://download.luckperms.net/1544/bukkit/loader/LuckPerms-Bukkit-5.4.131.jar

https://github.com/dmulloy2/ProtocolLib/releases/download/5.2.0/ProtocolLib.jar
https://ci.codemc.io/job/AuthMe/job/AuthMeReloaded/2631/artifact/target/authme-5.7.0-SNAPSHOT.jar
https://ci.codemc.io/job/Games647/job/FastLogin/1319/artifact/bukkit/target/FastLoginBukkit.jar
EOT
  }

  compose_game_limits = {
    memory = "7200mb"
  }

  # DDNS
  duckdns_token = var.duckdns_token

  # Region (change these to desired region)
  base_region = module.region_us-east-2.base_region
  providers   = { aws = aws.us-east-2 }
  az          = "us-east-2a"

  # ------------ Common values (just copy and paste) -------------
  source                     = "./server"
  iam_role_dlm_lifecycle_arn = module.global.iam_role_dlm_lifecycle_arn
  # --------------------------------------------------------------
}

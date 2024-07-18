aws_access_key = "AKIABCDEFGH"
aws_secret_key = "..."

discord_app_id         = "123456"
discord_app_public_key = "abcdef1234567890"
discord_bot_token      = "MTIabcdefg.12345.hijklm"

duckdns_domain = "mydomain"
duckdns_token  = "abcdefg-2057-4bd2-a6f5-4716e6d20516"

extra_ingress_rules = {
  // See https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule#argument-reference
  "Simple Voice Chat" : {
    description = "Simple Voice Chat mod server"
    from_port   = 24454
    to_port     = 24454
    ip_protocol = "udp"
    cidr_ipv4   = "0.0.0.0/0"
  }
}

instance_key_pair_public_key = "ssh-ed25519 AA...a minecraft-spot-discord"
instance_timezone            = "America/Bahia"

minecraft_port          = 23456
minecraft_compose_ports = ["23456:25565", "24454:24454/udp"]

minecraft_compose_environment = {
  "INIT_MEMORY" = "6000M"
  "MAX_MEMORY"  = "6000M"

  "ICON" = "https://picsum.photos/300/300"
  "MOTD" = "     \u00A7b\u00A7l\u00A7kaaaaaaaa\u00A7r \u00A75\u00A7lGame EC2 Spot Discord\u00A7r \u00A7b\u00A7l\u00A7kaaaaaaaa\u00A7r"

  "VERSION"     = "1.20.4"
  "ONLINE_MODE" = false
  "PLUGINS"     = <<EOT
https://cdn.modrinth.com/data/9eGKb6K1/versions/AyVUPPCX/voicechat-bukkit-2.5.15.jar

https://cdn.modrinth.com/data/UmLGoGij/versions/mr2CijyC/DiscordSRV-Build-1.27.0.jar

https://cdn.modrinth.com/data/cUhi3iB2/versions/Ua2p3xKG/tabtps-spigot-1.3.23.jar

https://cdn.modrinth.com/data/MubyTbnA/versions/vbGiEu4k/FreedomChat-Paper-1.6.0.jar
https://github.com/SkinsRestorer/SkinsRestorer/releases/download/15.0.13/SkinsRestorer.jar

https://download.luckperms.net/1544/bukkit/loader/LuckPerms-Bukkit-5.4.131.jar

https://github.com/dmulloy2/ProtocolLib/releases/download/5.2.0/ProtocolLib.jar
https://ci.codemc.io/job/AuthMe/job/AuthMeReloaded/lastSuccessfulBuild/artifact/target/AuthMe-5.6.0-SNAPSHOT.jar
https://ci.codemc.io/job/Games647/job/FastLogin/lastSuccessfulBuild/artifact/bukkit/target/FastLoginBukkit.jar
EOT
}

# ================================================================
# Example: Custom server
# 
# Creating a TShock Terraria server using the `custom` game option.
# See https://hub.docker.com/r/ryshe/terraria/
# ================================================================

module "custom_example" {
  # Change these to desired values
  id               = "CustomExample"
  game             = "custom"
  custom_game_name = "Terraria"
  hostname         = "gsed-example.duckdns.org"

  instance_type    = "m7g.medium"
  arch             = "arm64"
  data_volume_size = 1

  main_port = 7777
  compose_services = {
    main : {
      image : "ryshe/terraria"
      ports : ["7777:7777"]
      command : "-world ${local.terraria_workdir_path}/Worlds/CustomExample.wld -autocreate 3"
      volumes : ["/srv/terraria:${local.terraria_workdir_path}"]
    }
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

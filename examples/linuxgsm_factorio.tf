# ================================================================
# Example: Factorio server via LinuxGSM
# 
# See: https://docs.linuxgsm.com/game-servers/factorio
# ================================================================


module "linuxgsm" {
  # Change these to desired values
  id       = "FactorioExample"
  game     = "linuxgsm"
  hostname = "example-fctr.duckdns.org"

  linuxgsm_game_shortname = "fctr"

  instance_type = "m7a.medium"
  arch          = "x86_64"

  main_port          = 34197
  compose_game_ports = ["34197:34197", "34197:34197/udp"]
  data_volume_size   = 2

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

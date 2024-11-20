# ================================================================
# Example: Minecraft server
# 
# See https://docker-minecraft-server.readthedocs.io/en/latest/variables/
# ================================================================

module "example_server" {
  id       = "ExampleVanilla"
  game     = "minecraft"
  hostname = "example.duckdns.org"

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

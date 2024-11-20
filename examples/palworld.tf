# ================================================================
# Example: Palworld server
# 
# See: https://palworld-server-docker.loef.dev/category/configuration
# ================================================================

module "GSEDPalworldExample" {
  id       = "GSEDPalworldExample"
  game     = "palword"
  hostname = "palword-example.duckdns.org"

  compose_game_environment = {
    "SERVER_NAME" : "My GSED Palworld server"
    "SERVER_DESCRIPTION" : "Welcome to my server"
    "SERVER_PASSWORD" : "palpalpal"
    "ADMIN_PASSWORD" : "worldworld",
    "COMMUNITY" : false                                                # hide server from community list
    "DISCORD_WEBHOOK_URL" : "https://discord.com/api/webhooks/.../..." # optional
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

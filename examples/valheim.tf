# ================================================================
# Example: Valheim server
# 
# See: https://github.com/mbround18/valheim-docker?tab=readme-ov-file#environment-variables
# ================================================================

module "valheim" {
  id       = "GSEDValheimExample"
  game     = "valheim"
  hostname = "valheim-example.duckdns.org"

  compose_game_environment = {
    "NAME" : "My GSED Valheim Server",
    "PASSWORD" : "friendsonly"
    "WEBHOOK_URL" : "https://discord.com/api/webhooks/.../..." # optional
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

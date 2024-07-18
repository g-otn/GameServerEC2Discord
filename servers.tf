# ================================================================
# Servers
# 
# Add new servers here (make sure to edit/remove the example one 
# below)
# ================================================================

module "example" {
  source = "./server"

  # Change these to desired values
  id       = "ExampleVanilla"
  game     = "minecraft"
  hostname = "gsed-example.duckdns.org"

  # DDNS
  duckdns_token = var.duckdns_token

  # Region (change these to desired region)
  base_region = module.region_us-east-2.base_region
  providers   = { aws = aws.us-east-2 }
  az          = "us-east-2a"

  # ------------ Common values (just copy and paste) -------------
  iam_role_dlm_lifecycle_arn = module.global.iam_role_dlm_lifecycle_arn
  # --------------------------------------------------------------
}

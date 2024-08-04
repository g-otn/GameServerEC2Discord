
# ================================================================
# Region
# 
# Configure new AWS regions and their providers here, 
# if you want to place a server on them.
# By default, us-east-2 is configured below.
# 
# For each region module usage, you need one provider
# ================================================================

provider "aws" {
  # Change these two to desired region
  alias  = "us-east-2"
  region = "us-east-2"

  # ---- Common (just copy and paste) ---- 
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  default_tags { tags = local.tags }
  # --------------------------------------
}
module "region_us-east-2" {
  # Change these to desired values
  region = "us-east-2"
  azs    = ["us-east-2a"]

  # Change this to the provider you created for this region
  providers = { aws = aws.us-east-2 }

  # ------------ Common values (just copy and paste) -------------
  source         = "./base_region"
  ssh_public_key = var.ssh_public_key
  # --------------------------------------------------------------
}

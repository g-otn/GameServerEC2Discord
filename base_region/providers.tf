provider "aws" {
  region = var.region

  access_key = var.aws_access_key
  secret_key = var.aws_secret_key

  default_tags {
    tags = {
      Terraform = "true"
      "${local.prefix}:Related" : "true"
      "${local.prefix}:BaseRegionModule" : "true"
    }
  }
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.57"

    }
  }
}

locals {
  prefix = "GameServerEC2Discord"
  tags = {
    Terraform = "true"
    "${local.prefix}:Related" : "true"
  }
}

provider "aws" {
  region = var.base_global_provider_region

  access_key = var.aws_access_key
  secret_key = var.aws_secret_key

  default_tags { tags = local.tags }
}

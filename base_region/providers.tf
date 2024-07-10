terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.57"
    }
  }
}

provider "aws" {
  region = var.region

  access_key = var.aws_access_key
  secret_key = var.aws_secret_key

  default_tags {
    tags = {
      Terraform = "true"
      "${local.prefix}:Related" : "true"
      "${local.prefix}:Module" : local.module_name
    }
  }
}

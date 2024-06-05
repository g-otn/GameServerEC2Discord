terraform {
  required_version = ">= 1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.52.0"
    }

    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
    }

    time = {
      source  = "hashicorp/time"
      version = "~> 0.11.2"
    }
  }
}

provider "aws" {
  region = var.aws_region

  access_key = var.aws_access_key
  secret_key = var.aws_secret_key

  default_tags {
    tags = {
      Terraform = "true"
      "minecraft-spot-discord:related" : "true"
      "minecraft-spot-discord:server-name" : var.name
    }
  }
}

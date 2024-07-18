terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.57"
    }

    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
    }
  }
}

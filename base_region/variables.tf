variable "base" {
  type = object({
    prefix    = string
    prefix_sm = string
  })
}

variable "region" {
  description = "AWS region in which to create the resources required by servers"
  type        = string
}

variable "azs" {
  description = "AWS availability zones in which to create the resources required by servers."
  type        = list(string)
}

variable "ssh_public_key" {
  description = "Public key data in 'Authorized Keys' format for SSH with the instances in this region"
  type        = string
}

variable "data_volume_snapshot_retain_count" {
  description = "How many snapshots to retain. Snapshots are taken daily, so the number will correspond to the number of days"
  type        = number
  default     = 7
}

variable "data_volume_snapshot_create_time" {
  description = "The time to take the daily snapshot"
  type        = number
  default     = "07:12"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.7.0"
    }
  }
}

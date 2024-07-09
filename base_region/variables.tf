# ----------------------------------------------------------------
# AWS provider variables
# ----------------------------------------------------------------

variable "aws_access_key" {
  description = "AWS Access Key for AWS provider"
  type        = string
}

variable "aws_secret_key" {
  description = "AWS Secret Key for AWS provider"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "AWS region in which to create the resources required by servers"
  type        = string
}

# ----------------------------------------------------------------
# AWS variables
# ----------------------------------------------------------------

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
  type        = string
  default     = "07:39"
}


# ----------------------------------------------------------------
# Discord variables
# ----------------------------------------------------------------

variable "discord_app_id" {
  default = "Discord App ID for Discord API usage"
  type    = string
}

variable "discord_app_public_key" {
  description = "Discord App public key for webhook validation"
  type        = string
}

variable "discord_bot_token" {
  description = "Discord App bot token for Discord API auth"
  type        = string
  sensitive   = true
}

# ----------------------------------------------------------------
# Base variables
# ----------------------------------------------------------------

variable "iam_policy_publish_manager_topic_arn" {
  description = "Global; ARN of the IAM policy that allows publishing to the manager SNS topic"
  type        = string
}
variable "iam_policy_manage_instance_arn" {
  description = "Global; ARN of the IAM policy that allows managing instances"
  type        = string
}
variable "iam_role_dlm_lifecycle_arn" {
  description = "Global; ARN of the IAM role that allows DLM to manage the lifecycle of the data volume snapshots"
  type        = string
}

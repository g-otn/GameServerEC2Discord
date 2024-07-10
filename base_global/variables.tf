
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

# ----------------------------------------------------------------
# AWS provider variables
# ----------------------------------------------------------------

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

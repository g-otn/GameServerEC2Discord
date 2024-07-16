locals {
  module_name = basename(abspath(path.module))

  prefix    = "GameServerEC2Discord"
  prefix_sm = "GSED"

  xray_policy_arn = "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess"
}

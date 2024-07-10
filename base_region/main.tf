locals {
  module_name = basename(abspath(path.module))

  prefix    = "SpotDiscord"
  prefix_sm = "SD"

  user_ipv4_cidr = "${chomp(data.http.user_ipv4.response_body)}/32"

  xray_policy_arn = "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess"
}

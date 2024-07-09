locals {
  prefix    = "SpotDiscord"
  prefix_sm = "SD"

  user_ipv4_cidr = "${chomp(data.http.user_ipv4.response_body)}/32"
}

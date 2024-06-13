data "http" "myipv4" {
  url = "https://ipv4.icanhazip.com"
}

data "aws_caller_identity" "current" {}

data "http" "user_ipv4" {
  url = "https://ipv4.icanhazip.com"

  lifecycle {
    postcondition {
      condition     = contains([200], self.status_code)
      error_message = "Status code invalid"
    }
  }
}

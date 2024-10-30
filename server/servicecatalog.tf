resource "aws_servicecatalogappregistry_application" "server_app" {
  name        = "${var.id}-GSED-Server"
  description = "${local.prefix} server for the game ${local.game.game_name}"
}

locals {
  application_tags = aws_servicecatalogappregistry_application.server_app.application_tag
}

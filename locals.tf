locals {
  lowercase_name = lower(var.name)
  title = title(var.name)
  title_PascalCase = replace(local.title, "/\\W|_|\\s/", "")
  lambda_interaction_route = "/api/interactions"
}
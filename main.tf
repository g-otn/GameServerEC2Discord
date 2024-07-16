# ================================================================
# Global
# No need to touch this
# ================================================================

module "global" {
  source = "./base_global"

  # Discord
  discord_app_id         = var.discord_app_id
  discord_app_public_key = var.discord_app_public_key
  discord_bot_token      = var.discord_bot_token
}

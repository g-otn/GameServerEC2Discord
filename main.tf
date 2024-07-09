module "global" {
  source = "./base_global"
}

module "region_us_east_2" {
  source = "./base_region"

  region = "us-east-2"
  azs    = ["us-east-2a"]

  # ----------- Common values between base_region modules -----------
  # AWS
  ssh_public_key = var.ssh_public_key
  # Discord
  discord_app_id         = var.discord_app_id
  discord_app_public_key = var.discord_app_public_key
  discord_bot_token      = var.discord_bot_token
  # Global
  iam_policy_publish_manager_topic_arn = module.global.iam_policy_publish_manager_topic_arn
  iam_policy_manage_instance_arn       = module.global.iam_policy_manage_instance_arn
  iam_role_dlm_lifecycle_arn           = module.global.iam_role_dlm_lifecycle_arn
  # -----------------------------------------------------------------
}

module "myvanilla1" {
  source = "./server"

  id   = "MyVanilla1"
  game = "minecraft"
  az   = module.region_us_east_2.available_azs[0]

  hostname = "myvanilla1.duckdns.org"


  # ------------- Common values between server modules -------------
  # DDNS
  duckdns_token = var.duckdns_token
  # Discord
  discord_app_id         = var.discord_app_id
  discord_app_public_key = var.discord_app_public_key
  discord_bot_token      = var.discord_bot_token
  # Region
  vpc_id        = module.region_us_east_2.vpc_id
  subnet_id     = module.region_us_east_2.public_subnets[0]
  main_sg_id    = module.region_us_east_2.main_sg_id
  key_pair_name = module.region_us_east_2.key_pair_name
  # ----------------------------------------------------------------
}

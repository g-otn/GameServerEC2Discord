module "base_global" {
  source = "./base_global"
}

module "base_us_east_2" {
  source = "./base_region"

  region = "us-east-2"
  azs    = ["us-east-2a"]
}

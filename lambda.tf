// https://github.com/terraform-aws-modules/terraform-aws-lambda

module "lambda_manage_ec2" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "${local.title_PascalCase}-manage-ec2"
  description   = "Handles Discord slash commands interactions to manage the server's instance"
  handler       = "index.handler"
  runtime       = "nodejs20.x"

  publish = true
  create_lambda_function_url = true

  source_path = "lambda-manage-ec2/build/index.js"

  cloudwatch_logs_retention_in_days = 30

  environment_variables = {
    DISCORD_APP_PUBLIC_KEY = var.discord_public_key
  }
}

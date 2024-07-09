module "lambda_handle_interaction" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 7.4"

  function_name = "${local.prefix}-handle-interaction"
  description   = "Handles Discord slash commands interactions to manage the server's instance"
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  architectures = ["arm64"]

  publish                    = true
  create_lambda_function_url = true

  source_path = "lambda/handle-interaction/build/index.js"

  cloudwatch_logs_retention_in_days = 30
  tracing_mode                      = "Active"

  environment_variables = {
    MANAGER_INSTRUCTION_SNS_TOPIC_ARN = module.manager_instruction_sns_topic.topic_arn
    DISCORD_APP_PUBLIC_KEY            = var.discord_app_public_key
  }

  attach_tracing_policy = true
  attach_policies       = true
  number_of_policies    = 2
  policies              = [var.iam_policy_publish_manager_topic_arn, local.xray_policy_arn]
}

module "lambda_manage_instance" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 7.4"

  function_name = "${local.prefix}-manage-instance"
  description   = "Execute commands to manage EC2 instance and updates Discord interaction follow-up message"
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  architectures = ["arm64"]
  timeout       = 5

  publish = true

  source_path = "lambda/manage-instance/build/index.js"

  cloudwatch_logs_retention_in_days = 30
  tracing_mode                      = "Active"

  environment_variables = {
    DISCORD_APP_ID         = var.discord_app_id
    DISCORD_APP_PUBLIC_KEY = var.discord_app_public_key
    DISCORD_BOT_TOKEN      = var.discord_bot_token
  }

  attach_tracing_policy = true
  attach_policies       = true
  number_of_policies    = 2
  policies              = [var.iam_policy_manage_instance_arn, local.xray_policy_arn]
}

resource "aws_lambda_permission" "with_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_manage_instance.lambda_function_name
  principal     = "sns.amazonaws.com"
  source_arn    = module.manager_instruction_sns_topic.topic_arn
}

module "manager_instruction_sns_topic" {
  source  = "terraform-aws-modules/sns/aws"
  version = "~> 6.0"

  name = "${local.prefix}_ManagerInstruction_Topic"

  tracing_config = "Active"

  subscriptions = {
    lambda_manage_instance = {
      protocol = "lambda"
      endpoint = module.lambda_manage_instance.lambda_function_arn
    }
  }
}

module "api_gateway" {
  source = "terraform-aws-modules/apigateway-v2/aws"

  name          = "${local.title} HTTP API"
  description   = "Discord webhooks routes integrated with Lambda"
  protocol_type = "HTTP"

  create_api_domain_name = false

  create_default_stage_api_mapping = true

  # Access logs
  create_default_stage_access_log_group = true
  default_stage_access_log_format          = "$context.identity.sourceIp - - [$context.requestTime] \"$context.httpMethod $context.routeKey $context.protocol\" $context.status $context.responseLength $context.requestId $context.integrationErrorMessage"
  default_stage_access_log_group_name = "/aws/apigateway-v2/minecraft-http"
  default_stage_access_log_group_retention_in_days = 30

  # Routes and integrations
  integrations = {
    "POST ${local.lambda_interaction_route}" = {
      lambda_arn             = module.lambda_manage_ec2.lambda_function_arn
      payload_format_version = "2.0"
      timeout_milliseconds   = 3000
    }
  }
}
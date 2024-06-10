module "manager_instruction_sns_topic" {
  source  = "terraform-aws-modules/sns/aws"
  version = "~> 6.0"

  name = "${local.title_PascalCase}_ManagerInstruction_Topic"

  tracing_config = "Active"
}

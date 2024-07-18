resource "aws_iam_policy" "publish_manager_topic" {
  name        = "${local.prefix}-AllowPublishToManagerInstructionSNSTopic"
  description = "Allows publishing messages to the Manager Instruction SNS Topic"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "sns:Publish"
        ],
        Resource = module.manager_instruction_sns_topic.topic_arn,
        Condition = {
          StringEquals = { "aws:ResourceTag/${local.prefix}:Related" = "true" }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "manage_instance" {
  name        = "${local.prefix}-AllowManageInstance"
  description = "Allow starting, stopping and rebooting the Minecraft server instance"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:RebootInstances",
          "ec2:StartInstances",
          "ec2:StopInstances"
        ],
        "Resource" : "arn:aws:ec2:*:*:instance/*",
        "Condition" : {
          "StringEquals" : { "aws:ResourceTag/${local.prefix}:Related" : "true" }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : "ec2:DescribeInstances",
        "Resource" : "*" // https://stackoverflow.com/a/36768898/11138267
      }
    ]
  })
}

resource "aws_iam_role" "dlm_lifecycle" {
  name = "${local.prefix}-AWSDataLifecycleManagerServiceRole"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "dlm.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSDataLifecycleManagerServiceRole"]
}

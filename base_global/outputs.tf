output "iam_policy_publish_manager_topic_arn" {
  value = aws_iam_policy.publish_manager_topic.arn
}

output "iam_policy_manage_instance_arn" {
  value = aws_iam_policy.manage_instance.arn
}

output "iam_role_dlm_lifecycle_arn" {
  value = aws_iam_role.dlm_lifecycle.arn
}

output "base_global" {
  value = {
    prefix                               = local.prefix
    prefix_sm                            = local.prefix_sm
    user_cidr_ipv4                       = "${chomp(data.http.user_ipv4.response_body)}/32"
    iam_policy_publish_manager_topic_arn = aws_iam_policy.publish_manager_topic.arn
    iam_policy_manage_instance_arn       = aws_iam_policy.manage_instance.arn
    iam_role_dlm_lifecycle_arn           = aws_iam_role.dlm_lifecycle.arn
  }
}

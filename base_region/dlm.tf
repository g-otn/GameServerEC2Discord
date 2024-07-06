resource "aws_dlm_lifecycle_policy" "backup_data" {
  description        = "Takes daily snapshots of server data EBS volumes and retains them for a week"
  execution_role_arn = aws_iam_role.dlm_lifecycle_role.arn
  state              = "ENABLED"

  policy_details {
    resource_types = ["VOLUME"]

    schedule {
      name = "Last ${var.data_volume_snapshot_retain_count} days"

      create_rule {
        interval      = 24
        interval_unit = "HOURS"
        times         = [var.data_volume_snapshot_create_time]
      }

      retain_rule {
        count = var.data_volume_snapshot_retain_count
      }

      tags_to_add = {
        SnapshotCreator = "DLM"
      }

      copy_tags = true
    }

    target_tags = {
      "${local.prefix}:Related" = true
    }
  }

  tags = {
    Name = "${local.prefix} Server data backup Lifecycle Policy"
  }
}
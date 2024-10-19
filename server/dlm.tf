resource "aws_dlm_lifecycle_policy" "backup_data" {
  description        = "Takes daily snapshots of server data EBS volumes and retains them for ${var.data_volume_snapshot_retain_count} days"
  execution_role_arn = var.iam_role_dlm_lifecycle_arn
  state              = "ENABLED"
  count              = var.data_volume_snapshots ? 1 : 0

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
      "${local.prefix}:DataVolume" = var.id
    }
  }

  tags = {
    Name = "${local.prefix_sm_id_game} Data volume backup Lifecycle Policy"
  }
}

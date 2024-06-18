resource "aws_iam_role" "dlm_lifecycle_role" {
  name = "${local.title_PascalCase}-AWSDataLifecycleManagerServiceRole"
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

resource "aws_dlm_lifecycle_policy" "backup_minecraft_data" {
  description        = "Takes daily snapshots of Minecraft data EBS volumes and retains them for a week"
  execution_role_arn = aws_iam_role.dlm_lifecycle_role.arn
  state              = "ENABLED"

  policy_details {
    resource_types = ["VOLUME"]

    schedule {
      name = "Last 7 days"

      create_rule {
        interval      = 24
        interval_unit = "HOURS"
        times         = ["07:12"]
      }

      retain_rule {
        count = 7
      }

      tags_to_add = {
        SnapshotCreator = "DLM"
      }

      copy_tags = true
    }

    target_tags = {
      "minecraft-spot-discord:data-volume" = true
    }
  }

  tags = {
    Name = "${local.title} Backup Lifecycle Policy"
  }
}

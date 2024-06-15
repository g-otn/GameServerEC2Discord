data "aws_iam_policy_document" "assume_role_dlm" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["dlm.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "dlm_lifecycle" {
  statement {
    effect = "Allow"

    actions = [
      "ec2:CreateSnapshot",
      "ec2:CreateSnapshots",
      "ec2:DeleteSnapshot",
      "ec2:DescribeInstances",
      "ec2:DescribeVolumes",
      "ec2:DescribeSnapshots",
    ]

    resources = ["*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["ec2:CreateTags"]
    resources = ["arn:aws:ec2:*::snapshot/*"]
  }
}

// ---

resource "aws_iam_role" "dlm_lifecycle_role" {
  name                = "${local.title_PascalCase}-AWSDataLifecycleManagerServiceRole"
  assume_role_policy  = data.aws_iam_policy_document.assume_role_dlm.json
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSDataLifecycleManagerServiceRole"]
}

resource "aws_iam_role_policy" "dlm_lifecycle" {
  name   = "${local.title_PascalCase}-LifecycleRole"
  role   = aws_iam_role.dlm_lifecycle_role.id
  policy = data.aws_iam_policy_document.dlm_lifecycle.json
}

resource "aws_dlm_lifecycle_policy" "backup_minecraft_data" {
  description        = "Takes daily snapshots of Minecraft data EBS volumes and retains them for two weeks"
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

// https://docs.aws.amazon.com/linux/al2023/ug/ec2.html
// https://docs.aws.amazon.com/linux/al2023/ug/naming-and-versioning.html

// Example:
// arm64:
// - ami-0b9df99d3514cdede
// - al2023-ami-2023.5.20240701.0-kernel-6.1-arm64
// - Amazon Linux 2023 AMI 2023.5.20240701.0 arm64 HVM kernel-6.1
// x86_64:
// - ami-08be1e3e6c338b037
// - al2023-ami-2023.5.20240701.0-kernel-6.1-x86_64
// - Amazon Linux 2023 AMI 2023.5.20240701.0 x86_64 HVM kernel-6.1

data "aws_ami" "latest_al2023_x86_64" {
  most_recent = true

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["al2023-ami-2023*"] // for some reason "2023*" returns results but "2023-*" does not
  }
}

data "aws_ami" "latest_al2023_arm64" {
  most_recent = true

  filter {
    name   = "architecture"
    values = ["arm64"]
  }

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }
  filter {
    name   = "name"
    values = ["al2023-ami-2023*"]
  }
}

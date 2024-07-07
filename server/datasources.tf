// https://docs.aws.amazon.com/linux/al2023/ug/ec2.html
// https://docs.aws.amazon.com/linux/al2023/ug/naming-and-versioning.html

data "aws_ami" "latest_al2023_x86_64" {
  most_recent = true

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["al2023-ami-2023.0.*-x86_64"]
  }
}

data "aws_ami" "latest_al2023_arm64" {
  most_recent = true

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["al2023-ami-2023.0.*-arm64"]
  }
}

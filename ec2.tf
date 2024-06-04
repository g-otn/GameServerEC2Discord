locals {
  cloudinit_userdata = templatefile("./cloud-init/cloud-init.yml", {
    duckdns_domain   = var.duckdns_domain
    duckdns_token    = var.duckdns_token
    duckdns_interval = var.duckdns_interval
  })
}

resource "aws_key_pair" "ec2_spot_instance" {
  key_name   = var.instance_key_pair_name
  public_key = var.instance_key_pair_public_key
}

module "ec2_spot_instance" {
  source = "terraform-aws-modules/ec2-instance/aws"

  name = "${local.title} Spot Instance"

  create_spot_instance      = true
  spot_wait_for_fulfillment = true

  ami           = "ami-08a04a1d153bf02a7" // Amazon Linux 2023 AMI 2023.4.20240528.0 arm64 HVM kernel-6.1
  instance_type = "t4g.medium"

  vpc_security_group_ids      = [aws_security_group.spot_instance.id]
  subnet_id                   = module.vpc.public_subnets[0]
  associate_public_ip_address = true

  monitoring = true
  key_name   = aws_key_pair.ec2_spot_instance.key_name

  spot_instance_interruption_behavior = "stop"

  user_data = local.cloudinit_userdata

  instance_tags = {
    Name = "${local.title} Spot Instance"
  }

  volume_tags = {
    Name = "${local.title} Root Volume"
  }

  tags = {
    Name = "${local.title} Spot Instance Request"
  }
}

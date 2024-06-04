# # Request a Spot fleet
# resource "aws_spot_fleet_request" "cheap_compute" {
#   iam_fleet_role      = "arn:aws:iam::12345678:role/spot-fleet"
#   allocation_strategy = "lowestPrice"
#   target_capacity     = 1

#   launch_specification {
#     instance_type            = "m4.10xlarge"
#     ami                      = "ami-1234"
#     spot_price               = "2.793"
#     placement_tenancy        = "dedicated"
#     iam_instance_profile_arn = aws_iam_instance_profile.example.arn
#   }

#   launch_specification {
#     instance_type            = "m4.4xlarge"
#     ami                      = "ami-5678"
#     key_name                 = "my-key"
#     spot_price               = "1.117"
#     iam_instance_profile_arn = aws_iam_instance_profile.example.arn
#     availability_zone        = "us-west-1a"
#     subnet_id                = "subnet-1234"
#     weighted_capacity        = 35

#     root_block_device {
#       volume_size = "300"
#       volume_type = "gp2"
#     }

#     tags = {
#       Name = "spot-fleet-example"
#     }
#   }
# }

locals {
  cloudinit_userdata = templatefile("./cloud-init/cloud-init.yml", {
    duckdns_domain = var.duckdns_domain
    duckdns_token = var.duckdns_token
    duckdns_interval = var.duckdns_interval
  })
}

resource "aws_key_pair" "ec2_spot_instance" {
  key_name = var.instance_key_pair_name
  public_key = var.instance_key_pair_public_key
}

# module "ec2_spot_instance" {
#   source  = "terraform-aws-modules/ec2-instance/aws"

#   name = "${local.title} Spot Instance"

#   create_spot_instance = true

#   instance_type          = "t4g.small"
#   key_name               = aws_key_pair.ec2_spot_instance.key_name
#   monitoring             = true
#   vpc_security_group_ids = [aws_security_group.spot_instance.id]
#   subnet_id              = module.vpc.public_subnets[0]

#   associate_public_ip_address = true

#   user_data = local.cloudinit_userdata
# }
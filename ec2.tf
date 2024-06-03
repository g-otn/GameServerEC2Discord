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

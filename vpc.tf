module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${local.title} VPC"
  cidr = "10.0.0.0/16"

  azs             = [var.subnet_az]
  public_subnets  = ["10.0.101.0/24"]
  public_subnet_names = ["${local.title} Public Subnet 1 (${var.subnet_az})"]

  enable_flow_log = true
  flow_log_cloudwatch_log_group_retention_in_days = 30
  flow_log_cloudwatch_log_group_name_prefix = "/aws/vpc-flow-log/${local.title_PascalCase}-"

  create_flow_log_cloudwatch_iam_role = true
  create_flow_log_cloudwatch_log_group = true

  public_route_table_tags ={
    Name = "${local.title} Public Route Table"
  }

  igw_tags = {
    Name = "${local.title} Internet Gateway"
  }

  default_route_table_name = "${local.title} Default Route Table"
  default_network_acl_name = "${local.title} Default Network ACL"
  default_security_group_name = "${local.title} Default Security Group" 
}

resource "aws_security_group" "spot_instance" {
  name = "${local.title} Spot Instance Security Group"
  description = "Allow Minecraft and SSH inbound traffic and all outbound traffic"
  vpc_id = module.vpc.vpc_id

  tags = {
    Name = "${local.title} Spot Instance Security Group"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_minecraft" {
  security_group_id = aws_security_group.spot_instance.id
  description = "Allow Minecraft connections"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = var.minecraft_port
  to_port           = var.minecraft_port
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.spot_instance.id
  description = "Allow SSH"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.spot_instance.id
  description = "Allow any outbound IPv4 traffic"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}
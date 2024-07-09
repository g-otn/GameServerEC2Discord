locals {
  base_cidr_block     = "10.0.0.0/16"
  public_subnets      = [for i in range(length(var.azs)) : cidrsubnet(local.base_cidr_block, 8, 101 + i)]
  public_subnet_names = [for i in range(length(var.azs)) : "${local.local.prefix} Public Subnet ${i + 1}"]
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.8"

  name = "${var.base.prefix} VPC"
  cidr = local.base_cidr_block

  azs                 = var.azs
  public_subnets      = local.public_subnets
  public_subnet_names = local.public_subnet_names

  map_public_ip_on_launch = true

  enable_flow_log                                 = true
  flow_log_cloudwatch_log_group_retention_in_days = 30
  flow_log_cloudwatch_log_group_name_prefix       = "/aws/vpc-flow-log/${local.prefix}"
  // https://docs.aws.amazon.com/vpc/latest/userguide/flow-logs.html#flow-log-records
  flow_log_log_format = "$${az-id} $${subnet-id} $${interface-id} $${instance-id} $${pkt-src-aws-service} $${srcaddr} $${srcport} $${flow-direction} $${dstaddr} $${dstport} $${bytes} $${packets} $${protocol} $${start} $${end} $${action} $${log-status}"

  create_flow_log_cloudwatch_iam_role  = true
  create_flow_log_cloudwatch_log_group = true

  public_route_table_tags = {
    Name = "${local.prefix} Public Route Table"
  }

  igw_tags = {
    Name = "${local.prefix} Internet Gateway"
  }

  default_route_table_name    = "${local.prefix} Default Route Table"
  default_network_acl_name    = "${local.prefix} Default Network ACL"
  default_security_group_name = "${local.prefix} Default Security Group"
}

resource "aws_security_group" "instance_main" {
  name        = "${local.prefix} Instance Main Security Group"
  description = "Allow ICMP ping and SSH inbound traffic from admin IPv4, and all outbound traffic"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name = "${local.prefix} Instance Security Group"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ping" {
  security_group_id = aws_security_group.instance_main.id
  description       = "Allow ping for testing internet connectivity"
  from_port         = 8
  to_port           = 0
  ip_protocol       = "icmp"
  // Only you can ping, assumes local Terraform execution environment
  cidr_ipv4 = local.user_ipv4_cidr

  tags = {
    Name = "ICMP ping SGR"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.instance_main.id
  description       = "Allow SSH for managing the instance"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  // Only you can SSH, assumes local Terraform execution environment
  cidr_ipv4 = local.user_ipv4_cidr

  tags = {
    Name = "SSH SGR"
  }
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.instance_main.id
  description       = "Allow any outbound IPv4 traffic"
  ip_protocol       = "-1" # semantically equivalent to all ports
  cidr_ipv4         = "0.0.0.0/0"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.8"

  name = "${local.title} VPC"
  cidr = "10.0.0.0/16"

  azs                 = [var.subnet_az]
  public_subnets      = ["10.0.101.0/24"]
  public_subnet_names = ["${local.title} Public Subnet 1 (${var.subnet_az})"]

  map_public_ip_on_launch = true

  enable_flow_log                                 = true
  flow_log_cloudwatch_log_group_retention_in_days = 30
  flow_log_cloudwatch_log_group_name_prefix       = "/aws/vpc-flow-log/${local.title_PascalCase}-"
  // https://docs.aws.amazon.com/vpc/latest/userguide/flow-logs.html#flow-log-records
  flow_log_log_format = "$${az-id} $${subnet-id} $${interface-id} $${instance-id} $${pkt-src-aws-service} $${srcaddr} $${srcport} $${flow-direction} $${dstaddr} $${dstport} $${bytes} $${packets} $${protocol} $${start} $${end} $${action} $${log-status}"

  create_flow_log_cloudwatch_iam_role  = true
  create_flow_log_cloudwatch_log_group = true

  public_route_table_tags = {
    Name = "${local.title} Public Route Table"
  }

  igw_tags = {
    Name = "${local.title} Internet Gateway"
  }

  default_route_table_name    = "${local.title} Default Route Table"
  default_network_acl_name    = "${local.title} Default Network ACL"
  default_security_group_name = "${local.title} Default Security Group"
}

resource "aws_security_group" "spot_instance" {
  name        = "${local.title} Spot Instance Security Group"
  description = "Allow Minecraft and SSH inbound traffic and all outbound traffic"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name = "${local.title} Spot Instance Security Group"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_minecraft" {
  security_group_id = aws_security_group.spot_instance.id
  description       = "Allow Minecraft connections"
  from_port         = var.minecraft_port
  to_port           = var.minecraft_port
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"

  tags = {
    Name = "SGR for Minecraft (${local.title})"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ping" {
  security_group_id = aws_security_group.spot_instance.id
  description       = "Allow ping for testing internet connection"
  from_port         = 8
  to_port           = 0
  ip_protocol       = "icmp"
  // Only you can ping, assumes local Terraform execution environment
  cidr_ipv4 = local.myipv4

  tags = {
    Name = "SGR for ICMP ping (${local.title})"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.spot_instance.id
  description       = "Allow SSH for managing the instance"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  // Only you can SSH, assumes local Terraform execution environment
  cidr_ipv4 = local.myipv4

  tags = {
    Name = "SGR for SSH (${local.title})"
  }
}

resource "aws_vpc_security_group_ingress_rule" "extra_ingress" {
  for_each = tomap(var.extra_ingress_rules)

  security_group_id = aws_security_group.spot_instance.id

  description = each.value.description
  from_port   = each.value.from_port
  to_port     = each.value.to_port
  ip_protocol = each.value.ip_protocol
  cidr_ipv4   = each.value.cidr_ipv4

  tags = {
    Name = "SGR for ${each.key} (${local.title})"
  }
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.spot_instance.id
  description       = "Allow any outbound IPv4 traffic"
  ip_protocol       = "-1" # semantically equivalent to all ports
  cidr_ipv4         = "0.0.0.0/0"
}

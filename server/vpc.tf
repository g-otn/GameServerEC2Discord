resource "aws_security_group" "instance_extra_ingress" {
  name        = "${local.prefix} ${var.id} Instance Security Group"
  description = "Allow Game main port and custom ingress rules"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name = "${local.prefix} Instance Security Group"
  }
}


resource "aws_vpc_security_group_ingress_rule" "extra_ingress" {
  for_each = tomap(var.)

  security_group_id = aws_security_group.spot_instance.id

  description = each.value.description
  from_port   = each.value.from_port
  to_port     = each.value.to_port
  ip_protocol = each.value.ip_protocol
  cidr_ipv4   = each.value.cidr_ipv4

  tags = {
    Name = "${each.key} SGR (${var.id})"
  }
}

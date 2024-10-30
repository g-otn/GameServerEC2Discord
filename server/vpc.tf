resource "aws_security_group" "instance" {
  name        = "${local.prefix_sm_id_game} Security Group"
  description = "Allow Game main port and custom ingress rules"
  vpc_id      = var.base_region.vpc_id

  tags = merge({
    Name = "${local.prefix_sm_id_game} Instance Security Group"
  }, local.application_tags)
}

resource "aws_vpc_security_group_ingress_rule" "main_port_tcp" {
  security_group_id = aws_security_group.instance.id
  description       = "Allow Game main port TCP"
  from_port         = local.game.main_port
  to_port           = local.game.main_port
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"

  tags = merge({
    Name = "${local.game.game_name} Main Port TCP SG Rule"
  }, local.application_tags)
}

resource "aws_vpc_security_group_ingress_rule" "main_port_udp" {
  security_group_id = aws_security_group.instance.id
  description       = "Allow Game main port UDP"
  from_port         = local.game.main_port
  to_port           = local.game.main_port
  ip_protocol       = "udp"
  cidr_ipv4         = "0.0.0.0/0"

  tags = merge({
    Name = "${local.game.game_name} Main Port UDP SG Rule"
  }, local.application_tags)
}

resource "aws_vpc_security_group_ingress_rule" "extra_ingress" {
  for_each = tomap(var.sg_ingress_rules)

  security_group_id = aws_security_group.instance.id

  description = each.value.description
  from_port   = each.value.from_port
  to_port     = each.value.to_port
  ip_protocol = each.value.ip_protocol
  cidr_ipv4   = each.value.cidr_ipv4

  tags = merge({
    Name = "${each.key} SG Rule (${var.id})"
  }, local.application_tags)
}

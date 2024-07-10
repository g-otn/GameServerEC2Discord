output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnets" {
  value = module.vpc.public_subnets
}

output "main_sg_id" {
  value = aws_security_group.instance_main.id
}

output "key_pair_name" {
  value = aws_key_pair.instance_ssh.key_name
}

output "available_azs" {
  value = module.vpc.azs
}

output "region" {
  value = var.region
}

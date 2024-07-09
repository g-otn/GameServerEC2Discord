output "vpc_id" {
  value = module.vpc.vpc_id
}

output "key_pair_name" {
  value = aws_key_pair.instance_ssh.key_name
}

output "available_azs" {
  value = module.vpc.azs
}

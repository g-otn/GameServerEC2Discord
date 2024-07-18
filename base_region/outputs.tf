output "base_region" {
  value = {
    vpc_id         = module.vpc.vpc_id
    public_subnets = module.vpc.public_subnets
    main_sg_id     = aws_security_group.instance_main.id
    key_pair_name  = aws_key_pair.instance_ssh.key_name
    region         = var.region
    available_azs  = module.vpc.azs
  }
}

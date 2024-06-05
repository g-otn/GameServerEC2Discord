locals {
  duckdns_script_file_content_b64 = base64encode(templatefile("./cloud-init/duckdns/duck.sh", {
    duckdns_domain   = var.duckdns_domain
    duckdns_token    = var.duckdns_token
    duckdns_interval = var.duckdns_interval
  }))
  duckdns_service_file_content_b64 = base64encode(file("./cloud-init/duckdns/duck.service"))

  minecraft_service_file_content_b64 = base64encode(file(("./cloud-init/minecraft/minecraft.service")))

  mc_server_start_sh_file_content_b64 = base64encode(templatefile("./cloud-init/minecraft/server/start.sh", {
    xms      = var.cloudinit_minecraft_jvm_xms
    xmx      = var.cloudinit_minecraft_jvm_xmx
    jar_file = "paper.jar"
  }))

  device_name = "/dev/sdm"
  ec2_user_data = templatefile("./cloud-init/cloud-init.yml", {
    device_name = local.device_name

    duckdns_script_file_content_b64  = local.duckdns_script_file_content_b64
    duckdns_service_file_content_b64 = local.duckdns_service_file_content_b64

    minecraft_service_file_content_b64  = local.minecraft_service_file_content_b64
    mc_server_start_sh_file_content_b64 = local.mc_server_start_sh_file_content_b64
  })
}

resource "aws_key_pair" "ec2_spot_instance" {
  key_name   = var.instance_key_pair_name
  public_key = var.instance_key_pair_public_key
}

# resource "aws_ebs_volume" "minecraft" {
#   availability_zone = var.subnet_az
#   type              = "gp3"
#   size              = var.minecraft_data_volume_size
#   iops              = 3000
#   throughput        = 125

#   tags = {
#     Name = "${local.title} Minecraft Data Volume"
#     "minecraft-spot-discord:created-at" : time_static.ebs_creation_date.rfc3339
#   }

#   # lifecycle {
#   #   prevent_destroy = true
#   # }
# }

# resource "aws_volume_attachment" "attach_minecraft_data_to_instance" {
#   device_name = local.device_name
#   volume_id   = aws_ebs_volume.minecraft.id
#   instance_id = module.ec2_spot_instance.spot_instance_id

#   stop_instance_before_detaching = true
# }

module "ec2_spot_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.6"

  name = "${local.title} Spot Instance"

  create_spot_instance      = true
  spot_wait_for_fulfillment = true

  ami           = "ami-08a04a1d153bf02a7" // Amazon Linux 2023 AMI 2023.4.20240528.0 arm64 HVM kernel-6.1
  instance_type = var.instance_type

  vpc_security_group_ids      = [aws_security_group.spot_instance.id]
  subnet_id                   = module.vpc.public_subnets[0]
  associate_public_ip_address = true

  monitoring = true
  key_name   = aws_key_pair.ec2_spot_instance.key_name

  spot_instance_interruption_behavior = "stop"

  user_data = local.ec2_user_data

  enable_volume_tags = false
  ebs_block_device = [{
    volume_type = "gp3"
    volume_size = var.minecraft_data_volume_size
    iops        = 3000
    throughput  = 125

    device_name           = local.device_name
    delete_on_termination = false

    tags = {
      Name = "${local.title} Minecraft Data Volume"
    }
  }]

  // Due to bug in the provider, spot instances and its root volumes are not being tagged automatically
  # instance_tags = { Name = "${local.title} Spot Instance" }
  # enable_volume_tags = false
  # root_block_device = [{
  #   tags = {
  #     Name = "${local.title} Root Volume"
  #   }
  # }]
  tags = {
    Name = "${local.title} Spot Instance Request"
  }
}

locals {
  duckdns_script_file_content_b64 = base64encode(templatefile("./cloud-init/duckdns/duck.sh", {
    duckdns_domain = var.duckdns_domain
    duckdns_token  = var.duckdns_token
  }))
  duckdns_service_file_content_b64 = base64encode(file("./cloud-init/duckdns/duck.service"))

  device_name = "/dev/sdm"

  minecraft_shutdown_service_file_content_b64 = base64encode(file(("./cloud-init/minecraft/minecraft_shutdown.service")))
  minecraft_shutdown_timer_file_content_b64   = base64encode(file("./cloud-init/minecraft/minecraft_shutdown.timer"))
  minecraft_shutdown_script_file_content_b64 = base64encode(templatefile("./cloud-init/minecraft/minecraft_shutdown.sh", {
    server_data_path               = local.server_data_path
    minecraft_compose_service_name = local.minecraft_compose_service_name
  }))
  minecraft_service_file_content_b64 = base64encode(templatefile(("./cloud-init/minecraft/minecraft.service"), {
    server_data_path = local.server_data_path
  }))

  ec2_user_data = templatefile("./cloud-init/cloud-init.yml", {
    timezone = var.instance_timezone

    server_data_path = local.server_data_path
    device_name      = local.device_name

    duckdns_script_file_content_b64  = local.duckdns_script_file_content_b64
    duckdns_service_file_content_b64 = local.duckdns_service_file_content_b64

    minecraft_shutdown_script_file_content_b64  = local.minecraft_shutdown_script_file_content_b64
    minecraft_shutdown_service_file_content_b64 = local.minecraft_shutdown_service_file_content_b64
    minecraft_shutdown_timer_file_content_b64   = local.minecraft_shutdown_timer_file_content_b64

    compose_start_service_file_content_b64 = local.minecraft_service_file_content_b64
    compose_file_content_b64               = base64encode(local.game.compose)
  })

  instance_tags = {
    Name                              = "${local.prefix_id_game} Spot Instance"
    "${local.prefix_id_game}:Related" = true
  }
  root_volume_tags = {
    Name = "${local.prefix} Root Volume"
  }
}

resource "aws_ebs_volume" "server_data" {
  availability_zone = var.az
  type              = "gp3"
  size              = local.game.data_volume_size
  iops              = 3000
  throughput        = 125

  final_snapshot = true

  tags = {
    Name = "${local.prefix_id_game} Data Volume"
    "${local.prefix}:data-volume" : true
  }
}

resource "aws_volume_attachment" "attach_server_data_to_instance" {
  device_name = local.server_data_path
  volume_id   = aws_ebs_volume.server_data.id
  instance_id = module.ec2_spot_instance.spot_instance_id

  stop_instance_before_detaching = true
}

module "ec2_spot_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.6"

  name = "${local.prefix_id_game} Spot Instance"

  create_spot_instance      = true
  spot_wait_for_fulfillment = true

  ami           = "ami-07a5db12eede6ff87" // Amazon Linux 2023 AMI 2023.4.20240611.0 arm64 HVM kernel-6.1
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.spot_instance.id]
  subnet_id              = module.vpc.public_subnets[0]

  // We enable auto IPv4 via subnet settings (map_public_ip_on_launch)
  // instead of here to avoid force-replacement when applying while
  // the instance is stopped
  # associate_public_ip_address = true

  # monitoring = true
  key_name = var.base_region.key_pair_instance_ssh

  spot_instance_interruption_behavior = "stop"

  user_data = local.ec2_user_data

  enable_volume_tags = false

  // Due to bug in the provider, spot instances and its root volumes are not being tagged automatically
  # enable_volume_tags = false
  # root_block_device = [{
  #   tags = {
  #     Name = "${local.prefix_id_game} Root Volume"
  #   }
  # }]
  tags = {
    Name = "${local.prefix_id_game} Spot Instance Request"
  }
}

resource "aws_ec2_tag" "instance_tags_workaround" {
  for_each    = local.instance_tags
  resource_id = module.ec2_spot_instance.spot_instance_id
  key         = each.key
  value       = each.value
}

resource "aws_ec2_tag" "root_volume_tags_workaround" {
  for_each    = local.root_volume_tags
  resource_id = module.ec2_spot_instance.root_block_device[0].volume_id
  key         = each.key
  value       = each.value
}

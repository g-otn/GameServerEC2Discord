locals {
  device_name = "/dev/sdm"

  compose_start_file_content_b64 = base64encode(templatefile(("./server/systemd/compose_start.service"), {
    server_data_path = local.server_data_path
  }))

  auto_shutdown_service_file_content_b64 = base64encode(file("./server/systemd/auto_shutdown/auto_shutdown.service"))
  auto_shutdown_timer_file_content_b64   = base64encode(file("./server/systemd/auto_shutdown/auto_shutdown.timer"))
  auto_shutdown_script_file_content_b64 = base64encode(templatefile("./server/systemd/auto_shutdown/auto_shutdown.sh", {
    server_data_path          = local.server_data_path
    compose_main_service_name = local.game.compose_main_service_name
  }))

  duckdns_script_file_content_b64 = var.ddns_service == "duckdns" ? templatefile("./ddns/duckdns/duck.sh", {
    duckdns_domain = local.duckdns_domain
    duckdns_token  = var.duckdns_token
  }) : null
  duckdns_service_file_content_b64 = var.ddns_service == "duckdns" ? base64encode(file("./ddns/duckdns/duck.service")) : null

  ec2_user_data = templatefile("./server/cloud-init.yml", {
    timezone = var.instance_timezone

    server_data_path = local.server_data_path
    device_name      = local.device_name

    ddns_service = var.ddns_service

    compose_file_content_b64       = local.compose_file_content_b64
    compose_start_file_content_b64 = local.compose_start_file_content_b64

    auto_shutdown                          = var.auto_shutdown
    auto_shutdown_script_file_content_b64  = local.auto_shutdown_script_file_content_b64
    auto_shutdown_service_file_content_b64 = local.auto_shutdown_service_file_content_b64
    auto_shutdown_timer_file_content_b64   = local.auto_shutdown_timer_file_content_b64

    duckdns_script_file_content_b64  = local.duckdns_script_file_content_b64
    duckdns_service_file_content_b64 = local.duckdns_service_file_content_b64
  })

  instance_tags = {
    Name                       = "${local.prefix_id_game} Spot Instance"
    "${local.prefix}:Related"  = true
    "${local.prefix}:Game"     = var.game
    "${local.prefix}:ServerId" = var.id
  }
  root_volume_tags = {
    Name = "${local.prefix} Root Volume"
  }
}

module "ec2_spot_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.6"

  name = "${local.prefix_id_game} Spot Instance"

  create_spot_instance      = true
  spot_wait_for_fulfillment = true

  ami           = coalesce(var.arch, local.game.arch) == "arm64" ? data.aws_ami.latest_al2023_arm64.id : data.aws_ami.latest_al2023_x86_64.id
  instance_type = coalesce(var.instance_type, local.game.instance_type)

  vpc_security_group_ids = [var.main_sg_id, aws_security_group.instance_extra_ingress.id]
  subnet_id              = var.subnet_id

  // We enable auto IPv4 via subnet settings (map_public_ip_on_launch)
  // instead of here to avoid force-replacement when applying while
  // the instance is stopped
  # associate_public_ip_address = true

  # monitoring = true
  key_name = var.key_pair_name

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

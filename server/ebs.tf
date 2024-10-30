
resource "aws_ebs_volume" "server_data" {
  availability_zone = var.az
  type              = "gp3"
  size              = coalesce(var.data_volume_size, local.game.data_volume_size)
  iops              = 3000
  throughput        = 125

  snapshot_id = var.snapshot_id

  final_snapshot = var.data_volume_final_snapshot

  tags = merge({
    Name = "${local.prefix_id_game} Data Volume"
    "${local.prefix}:DataVolume" : var.id
  }, local.common_tags, local.application_tags)
}

resource "aws_volume_attachment" "attach_server_data_to_instance" {
  device_name = local.device_name
  volume_id   = aws_ebs_volume.server_data.id
  instance_id = module.ec2_spot_instance.spot_instance_id

  stop_instance_before_detaching = true
}

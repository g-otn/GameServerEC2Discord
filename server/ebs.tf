
resource "aws_ebs_volume" "server_data" {
  availability_zone = var.az
  type              = "gp3"
  size              = coalesce(var.data_volume_size, local.game.data_volume_size)
  iops              = 3000
  throughput        = 125

  final_snapshot = true

  tags = {
    Name = "${local.prefix_id_game} Data Volume"
    "${local.prefix}:DataVolume" : true
  }
}

resource "aws_volume_attachment" "attach_server_data_to_instance" {
  device_name = local.server_data_path
  volume_id   = aws_ebs_volume.server_data.id
  instance_id = module.ec2_spot_instance.spot_instance_id

  stop_instance_before_detaching = true
}

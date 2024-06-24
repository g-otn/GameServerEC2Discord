resource "aws_key_pair" "instance_ssh" {
  key_name   = "${local.prefix} instance SSH"
  public_key = var.ssh_public_key
}

locals {
  title            = title(var.name)
  title_PascalCase = replace(local.title, "/\\W|_|\\s/", "")

  myipv4 = "${chomp(data.http.myipv4.response_body)}/32"

  account_id = data.aws_caller_identity.current.account_id

  spot_instance_arn = "arn:aws:ec2:${var.aws_region}:${local.account_id}:instance/${module.ec2_spot_instance.spot_instance_id}"
}

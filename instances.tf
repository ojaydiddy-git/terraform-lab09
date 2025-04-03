provider "aws" {
  region = "us-east-1"
}

locals {
  environment    = upper("prod")
  instance_count = 2
  instance_configs = {
    for i in range(local.instance_count) : "nginx${i + 1}" => {
      subnet_id = i % 2 == 0 ? aws_subnet.public_subnets["subnet1"].id : aws_subnet.public_subnets["subnet2"].id
      name      = replace(lower("nginx-server-${i + 1}-${local.environment}"), "-", "_")
    }
  }
}

resource "aws_instance" "webservers" {
  for_each = local.instance_configs

  ami           = "ami-084568db4383264d4"
  instance_type = coalesce(var.instance_type, "t3.micro")# using the coalesce funtion

  vpc_security_group_ids = [aws_security_group.public_security_group.id]
  subnet_id              = each.value.subnet_id

  user_data = file("./setup-nginx.sh")

  tags = {
    Name           = each.value.name
    Environment    = local.environment
    InstanceNumber = each.key
  }
}

resource "aws_iam_instance_profile" "nginx_profile" {
  name = replace(lower("nginx-profile-${local.environment}"), "-", "_")
  role = "LabRole"
}

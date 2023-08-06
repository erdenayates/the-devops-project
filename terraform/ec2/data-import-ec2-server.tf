provider "aws" {
  region = "us-east-2" # replace with your region
}

data "aws_vpc" "main_vpc" {
  filter {
    name   = "tag:Name"
    values = ["main-vpc"]
  }
}

data "aws_subnet" "app_private_subnet" {
  filter {
    name   = "tag:Name"
    values = ["app-private-subnet-1"]
  }
}

data "aws_security_group" "existing" {
  name = "postgresql-data-import-server-security-group"
}

resource "aws_instance" "postgresql_data_import_server" {
  ami                  = "ami-08fdd91d87f63bb09"
  instance_type        = "t4g.small"
  subnet_id            = data.aws_subnet.app_private_subnet.id
  key_name             = null
  vpc_security_group_ids    = [data.aws_security_group.existing.id]
  iam_instance_profile = "session-manager-instance-profile"
  user_data = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y postgresql-client
    curl -fsSL get.docker.com -o get-docker.sh && sh get-docker.sh
    sudo chmod 666 /var/run/docker.sock
  EOF

  root_block_device {
    volume_type = "gp2"
    volume_size = 8
  }

  tags = {
    Name = "postgresql-data-import-server"
  }
}
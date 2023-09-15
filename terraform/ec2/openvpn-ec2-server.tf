data "aws_subnet" "public_subnet_2" {
  filter {
    name   = "tag:Name"
    values = ["public-subnet-2"]
  }
}

data "aws_security_group" "openvpn" {
  name = "openvpn-server-security-group"
}

data "aws_eip" "openvpn" {
  filter {
    name   = "tag:Name"
    values = ["openvpn-eip"]
  }
}

resource "aws_instance" "openvpn_server" {
  ami                  = "ami-08fdd91d87f63bb09"
  instance_type        = "t4g.small"
  subnet_id            = data.aws_subnet.public_subnet_2.id
  key_name             = null
  vpc_security_group_ids    = [data.aws_security_group.openvpn.id]
  iam_instance_profile = "session-manager-instance-profile"
  user_data = <<-EOF
    #! /bin/bash
    apt-get update
    curl -O https://raw.githubusercontent.com/angristan/openvpn-install/master/openvpn-install.sh
    chmod +x openvpn-install.sh
    AUTO_INSTALL=y ./openvpn-install.sh
    mv /openvpn-install.sh /home/ubuntu
  EOF

  root_block_device {
    volume_type = "gp2"
    volume_size = 8
  }

  tags = {
    Name = "openvpn-server"
  }
}

resource "aws_eip_association" "openvpn_eip_assoc" {
  instance_id   = aws_instance.openvpn_server.id
  public_ip     = data.aws_eip.openvpn.public_ip
}
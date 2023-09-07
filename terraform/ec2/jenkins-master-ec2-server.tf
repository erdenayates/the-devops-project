data "aws_subnet" "app_private_subnet_2" {
  filter {
    name   = "tag:Name"
    values = ["app-private-subnet-2"]
  }
}

data "aws_security_group" "jenkins" {
  name = "jenkins-master-server-security-group"
}

resource "aws_instance" "jenkins_master_server" {
  ami                  = "ami-08fdd91d87f63bb09"
  instance_type        = "t4g.small"
  subnet_id            = data.aws_subnet.app_private_subnet_2.id
  key_name             = null
  vpc_security_group_ids    = [data.aws_security_group.jenkins.id]
  iam_instance_profile = "session-manager-instance-profile"
  user_data = <<-EOF
    #!/bin/bash
    sudo apt update
    sudo apt install -y openjdk-17-jre
    java -version
    curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
      /usr/share/keyrings/jenkins-keyring.asc > /dev/null
    echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
      https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
      /etc/apt/sources.list.d/jenkins.list > /dev/null
    sudo apt-get update
    sudo apt-get install -y jenkins
  EOF

  root_block_device {
    volume_type = "gp2"
    volume_size = 16
  }

  tags = {
    Name = "jenkins-master-server"
  }
}
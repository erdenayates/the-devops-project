provider "aws" {
  region = "us-east-2"
}

data "aws_vpc" "main_vpc" {
  filter {
    name   = "tag:Name"
    values = ["main-vpc"]
  }
}

data "aws_eip" "openvpn_eip" {
  filter {
    name   = "tag:Name"
    values = ["openvpn-eip"]
  }
}

resource "aws_security_group" "postgresql_database_security_group" {
  name        = "postgresql-database-security-group"
  description = "Allows connection between postgresql and applications"
  vpc_id      = data.aws_vpc.main_vpc.id

  ingress {
    description = "main-vpc-postgresql-access"
    from_port   = 5432 # default port for PostgreSQL
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    description = "openvpn-access"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["${data.aws_eip.openvpn_eip.public_ip}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "postgresql-database-security-group"
  }
}

resource "aws_security_group" "postgresql_data_import_server_security_group" {
  name        = "postgresql-data-import-server-security-group"
  description = "Allows user to have connection between postgresql and EC2"
  vpc_id      = data.aws_vpc.main_vpc.id

  ingress {
    description = "main-vpc-postgresql-access"
    from_port   = 5432 # default port for PostgreSQL
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "postgresql-data-import-server-security-group"
  }
}

resource "aws_security_group" "jenkins_master_server_security_group" {
  name        = "jenkins-master-server-security-group"
  description = "Allows user to reach Jenkins UI"
  vpc_id      = data.aws_vpc.main_vpc.id

  ingress {
    description = "main-vpc-jenkins-access"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    description = "openvpn-access"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["${data.aws_eip.openvpn_eip.public_ip}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "jenkins-master-server-security-group"
  }
}

resource "aws_security_group" "openvpn_server_security_group" {
  name        = "openvpn-server-security-group"
  description = "Allows user to reach private applications over VPN "
  vpc_id      = data.aws_vpc.main_vpc.id

  ingress {
    description = "public-openvpn-access"
    from_port   = 1194
    to_port     = 1194
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "openvpn-server-security-group"
  }
}

resource "aws_security_group" "generic_load_balancer_security_group" {
  name        = "generic-load-balancer-security-group"
  description = "Allows user to reach private applications over load balancer "
  vpc_id      = data.aws_vpc.main_vpc.id

  ingress {
    description = "public-jenkins-access"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "generic-load-balancer-security-group"
  }
}

terraform {
  backend "s3" {
    bucket         = "the-lazy-devops-project-tfstate-bucket"
    key            = "terraform/vpc/security-groups/terraform.tfstate"
    region         = "us-east-2"
    encrypt        = true
    dynamodb_table = "the-lazy-devops-project-tfstate-lock"
  }
}

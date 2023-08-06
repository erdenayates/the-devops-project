provider "aws" {
  region = "us-east-2"
}

data "aws_vpc" "main_vpc" {
  filter {
    name   = "tag:Name"
    values = ["main-vpc"]
  }
}

resource "aws_security_group" "postgresql_database_security_group" {
  name        = "postgresql-database-security-group"
  description = "Allows connection between postgesql and applications"
  vpc_id      = data.aws_vpc.main_vpc.id

  ingress {
    description = "main-vpc-postgesql-access"
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
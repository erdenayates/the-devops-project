provider "aws" {
  region = "us-east-2" # replace with your region
}

data "aws_security_group" "existing" {
  name = "postgresql-database-security-group"
}

data "aws_subnet" "db_private_subnets" {
  count = 3
  filter {
    name   = "tag:Name"
    values = ["db-private-subnet-${count.index + 1}"]
  }
}

resource "aws_db_subnet_group" "postgresql_subnet_group" {
  name       = "postgresql-subnet-group"
  subnet_ids = [for subnet in data.aws_subnet.db_private_subnets : subnet.id]

  tags = {
    Name = "postgresql-subnet-group"
  }
}

resource "aws_db_instance" "postgresql_database" {
  identifier                = "postgresql-database"
  engine                    = "postgres"
  engine_version            = "14.8"
  instance_class            = "db.t4g.micro"
  allocated_storage         = 20
  storage_type              = "gp2"
  username                  = "postgres"
  password                  = var.master_password
  vpc_security_group_ids    = [data.aws_security_group.existing.id]
  db_subnet_group_name      = aws_db_subnet_group.postgresql_subnet_group.name
  publicly_accessible       = false
  availability_zone         = "us-east-2a"
  parameter_group_name      = "default.postgres14"
  deletion_protection       = true
  skip_final_snapshot       = true
}

variable "master_password" {
  description = "The password for the master DB user. This password can contain any printable ASCII character except '/', '\"', or '@'."
  type        = string
}

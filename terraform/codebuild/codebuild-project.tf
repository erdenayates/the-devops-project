provider "aws" {
  region = "us-east-2" # Change this to your AWS region
}

data "aws_iam_role" "codebuild_service_role" {
  name = "codebuild-jenkins-service-role"
}

# Attach necessary permissions for CodeBuild
resource "aws_iam_role_policy_attachment" "codebuild_s3_logs_policy" {
  role       = data.aws_iam_role.codebuild_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeBuildAdminAccess" # Modify if needed.
}

resource "aws_iam_role_policy_attachment" "codebuild_ec2_permissions" {
  role       = data.aws_iam_role.codebuild_service_role.name
  policy_arn = "arn:aws:iam::792334107397:policy/CodeBuildEC2Permissions"
}


# Security group for CodeBuild
resource "aws_security_group" "codebuild_sg" {
  name_prefix = "codebuild-sg-"
  vpc_id = data.aws_vpc.main-vpc.id

  ingress {
    from_port   = 0   # Adjust as necessary
    to_port     = 65535 # Adjust as necessary
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "codebuild-security-group"
  }
}

# Data sources for existing resources
data "aws_vpc" "main-vpc" {
  filter {
    name   = "tag:Name"
    values = ["main-vpc"]
  }
}

data "aws_subnet" "app_private_subnet_1" {
  filter {
    name   = "tag:Name"
    values = ["app-private-subnet-1"]
  }
}

data "aws_subnet" "app_private_subnet_2" {
  filter {
    name   = "tag:Name"
    values = ["app-private-subnet-2"]
  }
}

data "aws_subnet" "app_private_subnet_3" {
  filter {
    name   = "tag:Name"
    values = ["app-private-subnet-3"]
  }
}

# AWS CodeBuild project
resource "aws_codebuild_project" "jenkins_job" {
  name         = "jenkins-jobs"
  description  = "Jenkins Job CodeBuild Project"
  service_role = data.aws_iam_role.codebuild_service_role.arn
  build_timeout = 20
  queued_timeout = 60

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_MEDIUM" # 3GB Memory, 2 vCPUs
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = false
  }

  source {
    type            = "NO_SOURCE"
    buildspec       = <<-EOT
                     version: 0.2
                     phases:
                       build:
                         commands:
                           - docker
                           - docker ps
                           - sleep 60
                           - echo Done
                     EOT
  }

  vpc_config {
    vpc_id = data.aws_vpc.main-vpc.id
    subnets = [
      data.aws_subnet.app_private_subnet_1.id,
      data.aws_subnet.app_private_subnet_2.id,
      data.aws_subnet.app_private_subnet_3.id,
    ]
    security_group_ids = [aws_security_group.codebuild_sg.id]
  }

  logs_config {
    cloudwatch_logs {
      status = "ENABLED"
      # You can add a group and stream name if you want more customization
    }
  }

  tags = {
    Name = "jenkins-jobs"
  }
}
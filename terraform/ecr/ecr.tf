provider "aws" {
  region = "us-east-1"
}

resource "aws_ecrpublic_repository" "backend_repository" {
  repository_name = "backend"
  catalog_data {
    operating_systems = ["LINUX"]
  }
}

output "repository_url" {
  description = "Repository URL for the public ECR"
  value       = aws_ecrpublic_repository.backend_repository.repository_uri
}

terraform {
  backend "s3" {
    bucket         = "the-lazy-devops-project-tfstate-bucket"
    key            = "terraform/ecr/terraform.tfstate"
    region         = "us-east-2"
    encrypt        = true
    dynamodb_table = "the-lazy-devops-project-tfstate-lock"
  }
}

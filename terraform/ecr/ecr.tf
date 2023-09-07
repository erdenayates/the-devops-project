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

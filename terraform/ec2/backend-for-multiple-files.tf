terraform {
  backend "s3" {
    bucket         = "the-lazy-devops-project-tfstate-bucket"
    key            = "terraform/ec2/terraform.tfstate"
    region         = "us-east-2"
    encrypt        = true
    dynamodb_table = "the-lazy-devops-project-tfstate-lock"
  }
}


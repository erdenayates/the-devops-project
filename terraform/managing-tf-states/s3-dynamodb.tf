provider "aws" {
  region = "us-east-2" # Change this to your AWS region
}

resource "aws_s3_bucket" "tf_state" {
  bucket = "the-lazy-devops-project-tfstate-bucket"
  versioning {
    enabled = true
  }
}

resource "aws_dynamodb_table" "tf_locks" {
  name           = "the-lazy-devops-project-tfstate-lock"
  hash_key       = "LockID"
  read_capacity  = 20
  write_capacity = 20
  
  attribute {
    name = "LockID"
    type = "S"
  }
}

terraform {
  backend "s3" {
    bucket         = "the-lazy-devops-project-tfstate-bucket"
    key            = "terraform/managing-tf-states/terraform.tfstate"
    region         = "us-east-2"
    encrypt        = true
    dynamodb_table = "the-lazy-devops-project-tfstate-lock"
  }
}

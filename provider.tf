terraform {
  required_providers {
    aws = {
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket         = "your-bucket-name"
    key            = "backend.tfstate"
    region         = "us-east-1"
    dynamodb_table = "your-table-name"
  }
}

provider "aws" {
  region = "us-east-1"
}
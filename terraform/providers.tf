terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Uncomment and configure for remote state in real deployments:
  # backend "s3" {
  #   bucket         = "your-state-bucket"
  #   key            = "cicd-emulator/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "terraform-locks"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "cicd-with-aws-emulator"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

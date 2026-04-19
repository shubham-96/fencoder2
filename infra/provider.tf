terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
  backend "s3" {
    region       = "ap-south-1"
    use_lockfile = true
    profile = "videncdev"
  }
}


provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
  default_tags {
    tags = {
      Name = var.project_name
    }
  }
}

variable "project_name" {
  description = "Project name used for tagging (value for the Name tag)."
  type        = string
}
variable "aws_region" {
  description = "AWS region to deploy resources in"
  type        = string
}
variable "aws_profile" {
  description = "AWS CLI profile to use for authentication"
  type        = string
}
variable "lambda_function_name" {
  description = "Name of the Lambda function"
  type        = string
}
variable "s3_bucket_name" {
  description = "Name of the S3 bucket for fencoder"
  type        = string
}
variable "docker_image_url" {
  description = ""
  type = string
}
variable "allowed_account_id" {
  description = "AWS Account ID allowed to access the S3 bucket"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for AWS Batch Fargate compute environment."
  type        = string
}

variable "batch_subnet_ids" {
  description = "List of subnet IDs for AWS Batch Fargate compute environment. Should span multiple AZs for HA."
  type        = list(string)
}
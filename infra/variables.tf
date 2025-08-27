variable "lambda_function_name" {
  description = "Name of the Lambda function"
  type        = string
}
variable "s3_bucket_name" {
  description = "Name of the S3 bucket for fencoder"
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
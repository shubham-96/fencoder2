resource "aws_s3_bucket" "fencoder_data" {
  bucket = var.s3_bucket_name
}

resource "aws_s3_bucket_public_access_block" "fencoder_data_block" {
  bucket                  = aws_s3_bucket.fencoder_data.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "fencoder_bucket_policy" {
  bucket = aws_s3_bucket.fencoder_data.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "AllowAdamAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.allowed_account_id}:root"
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:ListBucket"
        ]
        Resource = [
          "${aws_s3_bucket.fencoder_data.arn}/*",
          aws_s3_bucket.fencoder_data.arn
        ]
      }
    ]
  }) 
  depends_on = [aws_s3_bucket_public_access_block.fencoder_data_block]
}

resource "aws_s3_bucket_notification" "fencoder_notification" {
  bucket = aws_s3_bucket.fencoder_data.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.fencoder_lambda.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "input/"
  }

  depends_on = [
    aws_lambda_permission.allow_s3_invoke
  ]
}

resource "aws_lambda_permission" "allow_s3_invoke" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.fencoder_lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.fencoder_data.arn
}
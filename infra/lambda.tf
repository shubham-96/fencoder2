resource "aws_lambda_function" "fencoder_lambda" {
  function_name    = var.lambda_function_name
  role             = aws_iam_role.lambda_exec.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  filename         = "${path.module}/../lambda/lambda.zip"
  source_code_hash = filebase64sha256("${path.module}/../lambda/lambda.zip")
  timeout          = 10
  memory_size      = 128
  environment {
    variables = {
      BATCH_JOB_QUEUE        = aws_batch_job_queue.fencoder_queue.name
      BATCH_JOB_DEFINITION   = aws_batch_job_definition.fencoder_job.name
      CRF                    = "23"
    }
  }
  depends_on = [
    aws_iam_role_policy.lambda_policy,
    aws_batch_job_queue.fencoder_queue,
    aws_batch_job_definition.fencoder_job
  ]
}

resource "aws_iam_role" "lambda_exec" {
  name = "fencoder-lambda-exec"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "fencoder-lambda-policy"
  role = aws_iam_role.lambda_exec.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = "arn:aws:s3:::${var.s3_bucket_name}/input/*"
      },
      {
        Effect = "Allow"
        Action = [
          "batch:SubmitJob"
        ]
        Resource = "*"
      }
    ]
  })
}

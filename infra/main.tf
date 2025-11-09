resource "aws_ecr_repository" "fencoder_repo" {
	name = "fencoder-repo"
	image_tag_mutability = "MUTABLE"
	image_scanning_configuration {
		scan_on_push = true
	}
}

resource "aws_batch_compute_environment" "fencoder_compute" {
  name = "fencoder-compute"
  type = "MANAGED"
  service_role = aws_iam_role.batch_service.arn
  compute_resources {
    type                = "FARGATE_SPOT"
    max_vcpus           = 16
    subnets             = var.batch_subnet_ids
    security_group_ids  = [aws_security_group.batch_fargate.id]
  }
}

resource "aws_batch_job_queue" "fencoder_queue" {
  name     = "fencoder-job-queue"
  state    = "ENABLED"
  priority = 1
  compute_environment_order {
    order                  = 1
    compute_environment    = aws_batch_compute_environment.fencoder_compute.arn
  }
}

resource "aws_batch_job_definition" "fencoder_job" {
  name = "fencoder-job-def"
  type = "container"
  platform_capabilities = "FARGATE"
  container_properties = jsonencode({
    image: var.docker_image_url,
    vcpus: 4,
    memory: 8192,
    command: ["/bin/sh", "/bin/encode.sh"],
    environment: [
      { name: "S3_BUCKET", value: "" },
      { name: "S3_KEY", value: "" }
    ],
    jobRoleArn: aws_iam_role.batch_task.arn,
    executionRoleArn: aws_iam_role.ecs_execution.arn
  })
}

resource "aws_security_group" "batch_fargate" {
  name        = "fencoder-batch-fargate-sg"
  description = "Security group for AWS Batch Fargate compute environment"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = []
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

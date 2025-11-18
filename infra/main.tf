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
  depends_on = [aws_batch_compute_environment.fencoder_compute]
}

resource "aws_batch_job_definition" "fencoder_job" {
  name = "fencoder-job-def"
  type = "container"
  platform_capabilities = ["FARGATE"]
  container_properties = jsonencode({
    image: var.docker_image_url,
    runtimePlatform: {
      operatingSystemFamily: "LINUX",
      cpuArchitecture: "ARM64"
    }
    resourceRequirements: [
      {
        type: "VCPU",
        value: "8"
      },
      {
        type: "MEMORY",
        value: "16384"
      }
    ],
    command: ["/bin/sh", "/bin/encode.sh"],
    jobRoleArn: aws_iam_role.batch_task.arn,
    executionRoleArn: aws_iam_role.ecs_execution.arn,
    networkConfiguration: {
      assignPublicIp: "ENABLED"
    }
  })
  depends_on = [
    aws_iam_role_policy.batch_task_s3,
    aws_iam_role_policy_attachment.ecs_execution_policy,
    aws_iam_role_policy_attachment.ecs_execution_ecr_readonly
  ]
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

# fencoder2

Automated video encoding with ffmpeg using AWS Batch & S3 for automated file processing.

## Prerequisites

- AWS Account with appropriate permissions
- AWS CLI configured with credentials
- [Terraform](https://www.terraform.io/downloads.html)

## Setup and Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/shubham-96/fencoder2.git
   cd fencoder2
   ```

2. Install Lambda function dependencies:
   ```bash
   cd lambda
   npm install
   ```

3. Configure AWS credentials:
   ```bash
   aws configure
   ```

4. Initialize Terraform:
   ```bash
   cd ../infra
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your specific values
   terraform init
   ```

## Deployment

1. Build the Lambda package
   ```bash
   cd lambda
   npm run package
   ```
2. Review the Terraform plan:
   ```bash
   cd infra
   terraform plan -out=tfplan
   ```

3. Apply the infrastructure changes:
   ```bash
   terraform apply "tfplan"
   ```

## Workflow

1. Upload a file to the S3 bucket under the `/input` prefix
2. This upload event triggers the Lambda function
3. The Lambda function submits a new job to AWS Batch with the bucket & object details as the parameters
4. The job will, inside a Fargate container, pull the file from S3, encode it & push the output back to S3 under the `/output` prefix
  

# fencoder2

Automated video encoding with ffmpeg using AWS Batch & S3 for automated file processing.

## Overview
I created this project to encode video files to H265 to reduce file sizes while maintaining video quality. It uses AWS Batch to pull files from an S3 bucket, encode it using ffmpeg, & upload the output back to S3. It can also downscale 4k video to 1440p as well as trim the video duration.

Uploading the files to S3 under the input/ prefix triggers a Lambda function which collects the file info & its metadata & submits an AWS batch job which these details as job parameters. 

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
   Or if you're using SSO
   ```bash
   aws sso login
   ```

4. Initialize Terraform:
   ```bash
   cd ../infra
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your specific values
   terraform init
   ```

## Deployment

1. Build & push the docker image
   ```bash
   docker buildx build --platform linux/amd64,linux/arm64 -t yourname/yourrepo:version --push .
   ```

2. Build the Lambda package
   ```bash
   cd lambda
   npm run package
   ```
3. Review the Terraform plan:
   ```bash
   cd infra
   # Update the tfvars if necessary (e.g. changing the image version)
   terraform plan -out=tfplan
   ```

4. Apply the infrastructure changes:
   ```bash
   terraform apply tfplan
   ```

## Workflow

1. Upload a file to the S3 bucket under the `input/` prefix
   * Upload to `input/preserve` to only re-encode
   * Upload to `input/downscale` to downscale 4k video to 1440p while encoding
   * Upload to `input/flip` to vertically flip the video while encoding
   * Upload to `input/downflip` to vertically flip the video & downscale it to 1440p while encoding
   * In order to trim the video, add the following metadata while uploading the file to S3
   
   `
   --metadata startTime=00:01:50.010,endTime=00:23:55.834
   `
2. The AWS batch job for this file should start shortly after upload
3. This project uses Fargate Spot exclusively, so if the file takes too long to encode, it is more likely for the job to be interrupted & the compute used so far to be completely wasted 
4. When the job completes successfully, it will upload the output file in the same S3 bucket under the `output/` prefix

## Future Scope
* For huge files getting their spot tasks interrupted before they are completed 
   * Add a Step Function that takes the file & splits it into multiple chunks of some fixed duration (chunking can be done using ffmpeg at keyframes to maintain seamless concat later). 
   * An array of Batch jobs can then be called for each chunk. The smaller chunks are more likely to complete encoding without being interrupted
   * The encoded chunks can then be concatenated into a single output file.
  

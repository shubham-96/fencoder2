# Video Encoding Setup

## Overview
This document outlines the setup for automating and optimizing video encoding using AWS Batch with Fargate Spot, triggered by a Lambda function on S3 uploads. The setup uses a custom Dockerfile based on Alpine Linux with FFmpeg 7.0, handles resolution-specific encoding via S3 prefixes, and uploads results. The setup prioritizes cost minimization, maintaining video quality, and reducing file size without noticeable degradation.

## Objectives
1. **Minimize Costs**: Use AWS Fargate Spot with aggressive price targeting and Alpine Linux to reduce compute and storage costs. Use Docker Hub’s free tier to avoid container registry storage costs.
2. **Maintain Video Quality**: Ensure encoded videos retain near-original quality using libx265.
3. **Reduce File Size**: Optimize encoding with libx265 to significantly reduce file size without noticeable quality degradation.

## Components

### 1. AWS Batch with Fargate Spot
- **Compute Environment**: Configure AWS Batch to use Fargate Spot for cost efficiency.
  - Use aggressive price targeting to leverage the lowest-cost Fargate Spot instances.
  - Set up a managed compute environment with appropriate vCPU and memory configurations (e.g., 4 vCPUs, 8 GB memory for standard encoding tasks).
- **Job Queue**: Create a job queue linked to the Fargate Spot compute environment with high priority to ensure cost-efficient instance allocation.
- **Job Definition**: Define a job definition referencing the custom Docker image (stored in Docker Hub) and specifying the shell script as the entry point. Pass S3 upload details (e.g., bucket name, file key) as environment variables or parameters.

### 2. Lambda Function
- **Trigger**: Configure an AWS Lambda function to trigger on every object upload to the S3 bucket `s3://bucket-name/input/`.
- **Functionality**:
  - Use TypeScript with Node.js runtime to minimize code size and execution time, reducing Lambda costs.
  - Extract upload details (bucket name, file key) from the S3 event.
  - Submit a job to AWS Batch with the extracted details as parameters.
  - Use the AWS SDK for JavaScript/TypeScript to interact with AWS Batch.
- **Permissions**:
  - Grant the Lambda function IAM permissions to:
    - Read from the S3 bucket (`s3:GetObject`).
    - Submit jobs to AWS Batch (`batch:SubmitJob`).
  - Avoid CloudWatch logging to eliminate associated costs.

### 3. Custom Dockerfile
- **Purpose**: Create a Docker image with FFmpeg 7.0 installed for video encoding, optimized for AWS Batch.
- **Base Image**: Use Alpine Linux for its small size (~5 MB) to minimize container pull times.
- **Dependencies**: Build FFmpeg 7.0 from source with libx265 support for H.265 encoding, as Alpine’s `apk` repository typically offers FFmpeg 6.x.
- **Command**: Set the entry point to a shell script (see below) that handles encoding and uploading.

### 4. Shell Script
- **Purpose**: Encode the video using FFmpeg with libx265, applying resolution-specific commands based on S3 prefix, then upload the result to S3.
- **Inputs**: Read S3 bucket and file key from environment variables (`S3_BUCKET`, `S3_KEY`) passed by the AWS Batch job.
- **Encoding Parameters**:
  - Use H.265 codec (`libx265`) for optimal compression and quality.
  - Set a constant rate factor (CRF) of 23–28 for a balance between quality and file size (lower CRF = better quality, higher file size).
  - For files in `input/preserve/`, maintain original resolution.
  - For files in `input/downscale/`, downscale 4K videos to 1440p (e.g., `-vf scale=2560:1440`).
- **Upload**: Use AWS CLI to upload the encoded video to `s3://bucket-name/output/`.

### 5. S3 Bucket Configuration
- **Input Bucket**: S3 bucket with prefixes:
  - `input/preserve/` for videos to maintain original resolution.
  - `input/downscale/` for 4K videos to downscale to 1440p.
- **Output Prefix**: Use `output/` for storing encoded videos.
- **Event Notification**: Configure S3 event notifications to trigger the Lambda function on `s3:ObjectCreated:*` events in the `input/` prefix (including sub-prefixes).

## Setup Steps
1. **Create S3 Bucket**:
   - No need to set up the `input/preserve/`, `input/downscale/`, and `output/` prefixes. Those can be created when the objects get uploaded to S3.
   - Configure event notifications to trigger the Lambda function for `input/` prefix events.
2. **Build and Push Docker Image**:
   - Build the Dockerfile using Alpine Linux, building FFmpeg 7.0 from source with libx265 support.
   - Push the image to a public Docker Hub repository.
3. **Set Up AWS Batch**:
   - Create a Fargate Spot compute environment with aggressive price targeting.
   - Create a job queue and link it to the compute environment.
   - Register a job definition referencing the Docker Hub image and the shell script.
4. **Deploy Lambda Function**:
   - Create a Lambda function using TypeScript with Node.js runtime.
   - Assign an IAM role with necessary permissions (S3 read, Batch submit).
   - Configure the S3 event trigger.
5. **Test the Pipeline**:
   - Upload sample videos to `input/preserve/` and `input/downscale/` prefixes.
   - Verify that the Lambda function triggers, the Batch job runs with correct FFmpeg commands based on prefix, and encoded videos appear in the `output/` prefix.

## Optimization Notes
- **Cost**: Monitor Fargate Spot costs and Docker Hub pull performance in AWS Cost Explorer. Alpine Linux minimizes container size, but verify build times for FFmpeg 7.0. Adjust vCPU/memory if over-provisioned.
- **Quality**: Test CRF values (e.g., 23 vs. 28) for libx265 to optimize quality vs. file size for VLC playback.
- **File Size**: Leverage H.265’s compression efficiency. For downscaled videos, ensure 1440p output balances quality and size.
- **Error Handling**: Add logic in the shell script to handle invalid video files or encoding failures, ensuring robust operation without CloudWatch logging.

## Future Reference
Attach this document to all future conversations to ensure context for the video encoding setup. Update the document if requirements change (e.g., new codecs, resolution policies, or AWS services).
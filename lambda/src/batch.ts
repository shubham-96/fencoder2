import { BatchClient, SubmitJobCommand } from '@aws-sdk/client-batch';
import { BatchJobConfig } from './config';

export interface EncodingJobInput {
  bucket: string;
  objectKey: string;
  config: BatchJobConfig;
  startTime?: string;
  endTime?: string;
}

export class BatchService {
  private client: BatchClient;

  constructor() {
    this.client = new BatchClient({});
  }

  private generateTimestamp(): string {
    const now = new Date();
    return `${now.getFullYear()}${
      String(now.getMonth() + 1).padStart(2, '0')}${
      String(now.getDate()).padStart(2, '0')}${
      String(now.getHours()).padStart(2, '0')}${
      String(now.getMinutes()).padStart(2, '0')}`;
  }

  async submitEncodingJob({ bucket, objectKey, config, startTime, endTime }: EncodingJobInput) {
    // Sanitize object key and limit length for job name
    const sanitizedKey = objectKey
      .replace(/[^a-zA-Z0-9-]/g, '-')  // Replace special chars with hyphen
      .replace(/-+/g, '-')             // Replace multiple hyphens with single
      .slice(0, 50);                   // Limit length to 50 chars
    const timestamp = this.generateTimestamp();
    const jobName = `fencoder-${sanitizedKey}-${timestamp}`;

    const environment = [
      { name: 'S3_BUCKET', value: bucket },
          { name: 'S3_KEY', value: objectKey },
          { name: 'CRF', value: config.crf.toString() },
          { name: 'S3_STORAGE_CLASS', value: config.s3StorageClass }
    ]
    if (startTime) {
      environment.push({ name: 'START_TIME', value: startTime });
    }
    if (endTime) {
      environment.push({ name: 'END_TIME', value: endTime });
    }
    
    const submitJobCmd = new SubmitJobCommand({
      jobName,
      jobQueue: config.jobQueue,
      jobDefinition: config.jobDefinition,
      containerOverrides: { environment }
    });

    const response = await this.client.send(submitJobCmd);
    return response.jobId;
  }
}
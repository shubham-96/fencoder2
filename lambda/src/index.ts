import { S3Event } from 'aws-lambda';
import { BatchService } from './batch';
import { getBatchConfig } from './config';

export const handler = async (event: S3Event) => {
  const record = event.Records && event.Records[0];
  if (!record) {
    console.error('No S3 record found in event');
    return {
      statusCode: 400,
      body: JSON.stringify({ message: 'No S3 record found in event' })
    };
  }

  const bucket = record.s3.bucket.name;
  const objectKey = record.s3.object.key;
  const batchService = new BatchService();
  const config = getBatchConfig();

  try {
    const jobId = await batchService.submitEncodingJob({
      bucket,
      objectKey,
      config
    });

    console.log('Batch job submitted:', jobId);
    return {
      statusCode: 200,
      body: JSON.stringify({
        message: 'Batch job submitted',
        jobId,
        bucket,
        objectKey
      })
    };
  } catch (error) {
    console.error('Error submitting batch job:', error);
    const errorMsg = error instanceof Error ? error.message : String(error);
    return {
      statusCode: 500,
      body: JSON.stringify({ message: 'Error submitting batch job', error: errorMsg })
    };
  }
};
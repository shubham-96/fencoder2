import { S3Event } from 'aws-lambda';
import { S3Client, HeadObjectCommand } from '@aws-sdk/client-s3';
import { BatchService } from './batch';
import { getBatchConfig } from './config';

const s3Client = new S3Client({});

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
  // First replace '+' with '%20', then decode the URL encoded object key
  const objectKey = decodeURIComponent(record.s3.object.key.replace(/\+/g, '%20'));
  const batchService = new BatchService();
  const config = getBatchConfig();

  try {
    let startTime: string | undefined;
    let endTime: string | undefined;

    try {
      const headObject = await s3Client.send(new HeadObjectCommand({
        Bucket: bucket,
        Key: objectKey
      }));

      if (headObject.Metadata) {
        startTime = headObject.Metadata['starttime']; 
        endTime = headObject.Metadata['endtime'];
        
        if (startTime || endTime) {
          console.log(`Found trimming metadata - Start: ${startTime}, End: ${endTime}`);
        }
      }
    } catch (s3Error) {
      console.warn(`Warning: Could not fetch metadata for ${objectKey}. Proceeding with full encode.`, s3Error);
    }

    const jobId = await batchService.submitEncodingJob({
      bucket,
      objectKey,
      config,
      startTime,
      endTime
    });

    console.log('Batch job submitted:', jobId);
    return {
      statusCode: 200,
      body: JSON.stringify({
        message: 'Batch job submitted',
        jobId,
        bucket,
        objectKey,
        trimming: { startTime, endTime }
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
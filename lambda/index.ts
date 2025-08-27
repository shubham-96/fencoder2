// Lambda entry point for S3 event trigger
// For now, just prints 'Hello World' on invocation
import { S3Event, Context, Callback } from 'aws-lambda';

export const handler = async (event: S3Event, context: Context, callback: Callback) => {
  // Extract object key from the S3 event
  const record = event.Records && event.Records[0];
  if (!record) {
    console.error('No S3 record found in event');
    return {
      statusCode: 400,
      body: JSON.stringify({ message: 'No S3 record found in event' })
    };
  }

  const objectKey = record.s3.object.key;
  // Split the key to get prefixes (folders)
  const keyParts = objectKey.split('/');
  const prefixes = keyParts.length > 1 ? keyParts.slice(0, -1) : [];

  console.log('S3 Object Key:', objectKey);
  console.log('Prefixes:', prefixes);

  return {
    statusCode: 200,
    body: JSON.stringify({
      objectKey,
      prefixes
    })
  };
};

export const CONFIG = {
  BATCH: {
    DEFAULT_JOB_QUEUE: 'fencoder-job-queue',
    DEFAULT_JOB_DEFINITION: 'fencoder-job-def',
    DEFAULT_CRF: 23,
    DEFAULT_S3_STORAGE_CLASS: 'INTELLIGENT_TIERING'
  }
} as const;

export interface BatchJobConfig {
  jobQueue: string;
  jobDefinition: string;
  crf: number;
  s3StorageClass: string;
}

export function getBatchConfig(): BatchJobConfig {
  return {
    jobQueue: process.env.BATCH_JOB_QUEUE || CONFIG.BATCH.DEFAULT_JOB_QUEUE,
    jobDefinition: process.env.BATCH_JOB_DEFINITION || CONFIG.BATCH.DEFAULT_JOB_DEFINITION,
    crf: Number(process.env.CRF) || CONFIG.BATCH.DEFAULT_CRF,
    s3StorageClass: process.env.S3_STORAGE_CLASS || CONFIG.BATCH.DEFAULT_S3_STORAGE_CLASS
  };
}
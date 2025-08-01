export interface JobConfig {
  name: string;
  cronExpression: string;
  url: string;
  method: 'GET' | 'POST' | 'PUT' | 'DELETE' | 'PATCH';
  headers?: Record<string, string>;
  data?: any;
  timeout?: number;
  retries?: number;
  enabled?: boolean;
}

export interface JobResult {
  success: boolean;
  jobName: string;
  timestamp: Date;
  response?: any;
  error?: string;
  statusCode?: number;
  executionTime: number;
}

export interface YamlJobConfig {
  name: string;
  schedule: string; // cron expression
  url: string;
  method: 'GET' | 'POST' | 'PUT' | 'DELETE' | 'PATCH';
  headers?: Record<string, string>;
  data?: any;
  timeout?: number;
  retries?: number;
  enabled?: boolean;
  description?: string;
}

export interface YamlJobFile {
  jobs: YamlJobConfig[];
  global?: {
    defaultTimeout?: number;
    defaultRetries?: number;
    defaultHeaders?: Record<string, string>;
  };
}

export interface SchedulerStatus {
  totalJobs: number;
  runningJobs: number;
  jobNames: string[];
  yamlFile?: string;
  lastYamlUpdate?: Date;
} 
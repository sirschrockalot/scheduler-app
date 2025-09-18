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
  dependsOn?: JobDependencyConfig;
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
  dependsOn?: YamlJobDependencyConfig;
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

export type JobDependencyCondition = 'not_ran' | 'failed' | 'not_ran_or_failed';

export interface JobDependencyConfig {
  job: string;
  windowMinutes?: number; // how far back to look for status
  condition?: JobDependencyCondition; // default: not_ran_or_failed
}

export interface YamlJobDependencyConfig {
  job: string;
  windowMinutes?: number;
  condition?: JobDependencyCondition;
}

export interface JobRuntimeState {
  lastRunAt: Date | null;
  lastSuccessAt: Date | null;
  lastFailureAt: Date | null;
}
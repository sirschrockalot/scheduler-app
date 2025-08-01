import cron from 'node-cron';
import axios, { AxiosRequestConfig, AxiosResponse } from 'axios';
import winston from 'winston';

export interface JobConfig {
  name: string;
  cronExpression: string;
  url: string;
  method: 'GET' | 'POST' | 'PUT' | 'DELETE' | 'PATCH';
  headers?: Record<string, string>;
  data?: any;
  timeout?: number;
  retries?: number;
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

export class JobScheduler {
  private jobs: Map<string, cron.ScheduledTask> = new Map();
  private logger!: winston.Logger;
  private jwtToken: string;

  constructor() {
    this.jwtToken = process.env['JWT_TOKEN'] || '';
    
    if (!this.jwtToken) {
      throw new Error('JWT_TOKEN environment variable is required');
    }

    this.setupLogger();
  }

  private setupLogger(): void {
    this.logger = winston.createLogger({
      level: process.env['LOG_LEVEL'] || 'info',
      format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.errors({ stack: true }),
        winston.format.json()
      ),
      defaultMeta: { service: 'job-scheduler' },
      transports: [
        new winston.transports.Console({
          format: winston.format.combine(
            winston.format.colorize(),
            winston.format.simple()
          )
        }),
        new winston.transports.File({ 
          filename: 'logs/error.log', 
          level: 'error' 
        }),
        new winston.transports.File({ 
          filename: 'logs/combined.log' 
        })
      ]
    });

    // Create logs directory if it doesn't exist
    const fs = require('fs');
    const path = require('path');
    const logsDir = path.join(process.cwd(), 'logs');
    if (!fs.existsSync(logsDir)) {
      fs.mkdirSync(logsDir, { recursive: true });
    }
  }

  /**
   * Register a new job with the scheduler
   */
  public registerJob(config: JobConfig): void {
    if (this.jobs.has(config.name)) {
      throw new Error(`Job with name '${config.name}' already exists`);
    }

    if (!cron.validate(config.cronExpression)) {
      throw new Error(`Invalid cron expression: ${config.cronExpression}`);
    }

    const task = cron.schedule(config.cronExpression, async () => {
      await this.executeJob(config);
    }, {
      scheduled: false
    });

    this.jobs.set(config.name, task);
    this.logger.info(`Job '${config.name}' registered with cron expression: ${config.cronExpression}`);
  }

  /**
   * Execute a job with retry logic and comprehensive logging
   */
  private async executeJob(config: JobConfig): Promise<JobResult> {
    const startTime = Date.now();
    const maxRetries = config.retries || 3;
    let lastError: string | undefined;

    this.logger.info(`🚀 Starting job: ${config.name}`);

    for (let attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        const result = await this.makeRequest(config, attempt);
        const executionTime = Date.now() - startTime;

        const jobResult: JobResult = {
          success: true,
          jobName: config.name,
          timestamp: new Date(),
          response: result.data,
          statusCode: result.status,
          executionTime
        };

        this.logger.info(`✅ Job '${config.name}' completed successfully`, {
          attempt,
          statusCode: result.status,
          executionTime: `${executionTime}ms`
        });

        return jobResult;

      } catch (error) {
        lastError = error instanceof Error ? error.message : String(error);
        
        this.logger.warn(`🔄 Job '${config.name}' attempt ${attempt}/${maxRetries} failed`, {
          error: lastError,
          attempt
        });

        if (attempt === maxRetries) {
          const executionTime = Date.now() - startTime;
          
          this.logger.error(`❌ Job '${config.name}' failed after ${maxRetries} attempts`, {
            error: lastError,
            totalAttempts: maxRetries,
            executionTime: `${executionTime}ms`
          });

          return {
            success: false,
            jobName: config.name,
            timestamp: new Date(),
            error: lastError,
            executionTime
          };
        }

        // Wait before retry (exponential backoff)
        const delay = Math.min(1000 * Math.pow(2, attempt - 1), 30000);
        await new Promise(resolve => setTimeout(resolve, delay));
      }
    }

    // This should never be reached, but TypeScript requires it
    throw new Error('Unexpected execution path');
  }

  /**
   * Make HTTP request with JWT authentication
   */
  private async makeRequest(config: JobConfig, attempt: number): Promise<AxiosResponse> {
    const requestConfig: AxiosRequestConfig = {
      method: config.method,
      url: config.url,
      timeout: config.timeout || 30000,
      headers: {
        'Authorization': `Bearer ${this.jwtToken}`,
        'Content-Type': 'application/json',
        'User-Agent': 'JobScheduler/1.0.0',
        ...config.headers
      }
    };

    if (config.data && ['POST', 'PUT', 'PATCH'].includes(config.method)) {
      requestConfig.data = config.data;
    }

    this.logger.debug(`Making ${config.method} request to ${config.url}`, {
      jobName: config.name,
      attempt,
      headers: requestConfig.headers
    });

    return axios(requestConfig);
  }

  /**
   * Start all registered jobs
   */
  public start(): void {
    this.logger.info('🎯 Starting job scheduler');
    
    for (const [jobName, task] of this.jobs) {
      task.start();
      this.logger.info(`▶️ Started job: ${jobName}`);
    }
  }

  /**
   * Stop all jobs
   */
  public stop(): void {
    this.logger.info('🛑 Stopping job scheduler');
    
    for (const [jobName, task] of this.jobs) {
      task.stop();
      this.logger.info(`⏹️ Stopped job: ${jobName}`);
    }
  }

  /**
   * Get list of registered job names
   */
  public getJobNames(): string[] {
    return Array.from(this.jobs.keys());
  }

  /**
   * Check if a job is running
   */
  public isJobRunning(jobName: string): boolean {
    const task = this.jobs.get(jobName);
    return task ? true : false; // Simplified check - if task exists, it's considered running
  }

  /**
   * Remove a job from the scheduler
   */
  public removeJob(jobName: string): boolean {
    const task = this.jobs.get(jobName);
    if (task) {
      task.stop();
      this.jobs.delete(jobName);
      this.logger.info(`🗑️ Removed job: ${jobName}`);
      return true;
    }
    return false;
  }

  /**
   * Get scheduler status
   */
  public getStatus(): { totalJobs: number; runningJobs: number; jobNames: string[] } {
    const jobNames = this.getJobNames();
    const runningJobs = jobNames.filter(name => this.isJobRunning(name)).length;
    
    return {
      totalJobs: jobNames.length,
      runningJobs,
      jobNames
    };
  }
} 
import * as fs from 'fs';
import * as yaml from 'js-yaml';
import * as chokidar from 'chokidar';
import { YamlJobFile, YamlJobConfig, JobConfig } from './types';

export class YamlManager {
  private yamlFilePath: string;
  private watcher: chokidar.FSWatcher | null = null;
  private onJobsUpdate: ((jobs: JobConfig[]) => void) | null = null;
  private lastUpdate: Date | null = null;

  constructor(yamlFilePath: string = 'jobs.yaml') {
    this.yamlFilePath = yamlFilePath;
  }

  /**
   * Initialize the YAML manager and start watching for file changes
   */
  public initialize(onJobsUpdate: (jobs: JobConfig[]) => void): void {
    this.onJobsUpdate = onJobsUpdate;
    
    // Load initial jobs
    this.loadJobsFromYaml();
    
    // Start watching for file changes
    this.startWatching();
  }

  /**
   * Load jobs from YAML file
   */
  public loadJobsFromYaml(): JobConfig[] {
    try {
      if (!fs.existsSync(this.yamlFilePath)) {
        console.log(`📄 YAML file not found: ${this.yamlFilePath}`);
        return [];
      }

      const fileContent = fs.readFileSync(this.yamlFilePath, 'utf8');
      const yamlData = yaml.load(fileContent) as YamlJobFile;

      if (!yamlData || !yamlData.jobs) {
        console.log('⚠️ No jobs found in YAML file');
        return [];
      }

      const jobs: JobConfig[] = yamlData.jobs
        .filter(job => job.enabled !== false) // Only include enabled jobs
        .map(yamlJob => this.convertYamlJobToJobConfig(yamlJob, yamlData.global));

      console.log(`📄 Loaded ${jobs.length} jobs from YAML file: ${this.yamlFilePath}`);
      this.lastUpdate = new Date();
      
      return jobs;
    } catch (error) {
      console.error(`❌ Error loading YAML file: ${error}`);
      return [];
    }
  }

  /**
   * Convert YAML job config to internal job config
   */
  private convertYamlJobToJobConfig(yamlJob: YamlJobConfig, global?: YamlJobFile['global']): JobConfig {
    return {
      name: yamlJob.name,
      cronExpression: yamlJob.schedule,
      url: yamlJob.url,
      method: yamlJob.method,
      headers: {
        ...global?.defaultHeaders,
        ...yamlJob.headers
      },
      data: yamlJob.data,
      timeout: yamlJob.timeout || global?.defaultTimeout || 10000,
      retries: yamlJob.retries || global?.defaultRetries || 3,
      enabled: yamlJob.enabled !== false
    };
  }

  /**
   * Start watching the YAML file for changes
   */
  private startWatching(): void {
    if (this.watcher) {
      this.watcher.close();
    }

    this.watcher = chokidar.watch(this.yamlFilePath, {
      persistent: true,
      ignoreInitial: true,
      awaitWriteFinish: {
        stabilityThreshold: 1000,
        pollInterval: 100
      }
    });

    this.watcher
      .on('change', (filePath) => {
        console.log(`📄 YAML file changed: ${filePath}`);
        this.handleYamlFileChange();
      })
      .on('add', (filePath) => {
        console.log(`📄 YAML file added: ${filePath}`);
        this.handleYamlFileChange();
      })
      .on('unlink', (filePath) => {
        console.log(`📄 YAML file removed: ${filePath}`);
        this.handleYamlFileChange();
      })
      .on('error', (error) => {
        console.error(`❌ YAML file watcher error: ${error}`);
      });

    console.log(`👀 Watching for changes in: ${this.yamlFilePath}`);
  }

  /**
   * Handle YAML file changes
   */
  private handleYamlFileChange(): void {
    if (!this.onJobsUpdate) return;

    try {
      const jobs = this.loadJobsFromYaml();
      this.onJobsUpdate(jobs);
      this.lastUpdate = new Date();
    } catch (error) {
      console.error(`❌ Error handling YAML file change: ${error}`);
    }
  }

  /**
   * Create a sample YAML file if it doesn't exist
   */
  public createSampleYamlFile(): void {
    if (fs.existsSync(this.yamlFilePath)) {
      console.log(`📄 YAML file already exists: ${this.yamlFilePath}`);
      return;
    }

    const sampleYaml = `# Job Scheduler Configuration
# This file defines jobs that will be executed by the scheduler

global:
  defaultTimeout: 10000  # 10 seconds
  defaultRetries: 3
  defaultHeaders:
    Content-Type: application/json

jobs:
  # Example job that runs every 5 seconds
  - name: test-api-call
    schedule: "*/5 * * * * *"  # Every 5 seconds
    url: "https://httpbin.org/bearer"
    method: GET
    enabled: true
    description: "Test API call to httpbin.org"

  # Example job that runs every minute
  - name: health-check
    schedule: "0 * * * * *"  # Every minute at 0 seconds
    url: "https://httpbin.org/status/200"
    method: GET
    timeout: 5000
    retries: 2
    enabled: true
    description: "Health check endpoint"

  # Example POST job that runs every 2 minutes
  - name: data-sync
    schedule: "0 */2 * * * *"  # Every 2 minutes
    url: "https://httpbin.org/post"
    method: POST
    headers:
      Authorization: "Bearer \${JWT_TOKEN}"
      X-Custom-Header: "data-sync"
    data:
      timestamp: "\${NOW}"
      action: "sync"
    timeout: 15000
    retries: 3
    enabled: false  # Disabled by default
    description: "Data synchronization job"

# Cron Expression Format:
# ┌───────────── second (0-59, optional)
# │ ┌───────────── minute (0-59)
# │ │ ┌───────────── hour (0-23)
# │ │ │ ┌───────────── day of month (1-31)
# │ │ │ │ ┌───────────── month (1-12)
# │ │ │ │ │ ┌───────────── day of week (0-7, 0 and 7 are Sunday)
# │ │ │ │ │ │
# * * * * * *

# Examples:
# "*/5 * * * * *" - Every 5 seconds
# "0 * * * * *" - Every minute
# "0 */5 * * * *" - Every 5 minutes
# "0 0 * * * *" - Every hour
# "0 0 0 * * *" - Every day at midnight
# "0 0 12 * * 1" - Every Monday at noon
`;

    try {
      fs.writeFileSync(this.yamlFilePath, sampleYaml);
      console.log(`✅ Created sample YAML file: ${this.yamlFilePath}`);
    } catch (error) {
      console.error(`❌ Error creating sample YAML file: ${error}`);
    }
  }

  /**
   * Get the last update time
   */
  public getLastUpdate(): Date | null {
    return this.lastUpdate;
  }

  /**
   * Get the YAML file path
   */
  public getYamlFilePath(): string {
    return this.yamlFilePath;
  }

  /**
   * Stop watching the YAML file
   */
  public stopWatching(): void {
    if (this.watcher) {
      this.watcher.close();
      this.watcher = null;
    }
  }
} 
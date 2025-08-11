import dotenv from 'dotenv';
import { JobScheduler } from './scheduler';
import { JobConfig } from './types';
import { YamlManager } from './yaml-manager';

// Load environment variables
dotenv.config();

// Validate required environment variables
if (!process.env['JWT_TOKEN']) {
  console.error('❌ JWT_TOKEN environment variable is required');
  process.exit(1);
}

// Create scheduler instance
const scheduler = new JobScheduler();
const yamlManager = new YamlManager();

// Create sample YAML file if it doesn't exist
yamlManager.createSampleYamlFile();

// Initialize YAML manager and start the scheduler
yamlManager.initialize((jobs: JobConfig[]) => {
  console.log(`📄 Updating scheduler with ${jobs.length} jobs from YAML`);
  scheduler.updateJobsFromYaml(jobs);
  
  // Log status after jobs are loaded and started
  const status = scheduler.getStatus();
  console.log('📊 Scheduler Status:', status);
  console.log('🚀 Job Scheduler started successfully!');
  console.log('📄 YAML-based job configuration enabled');
  console.log('📝 Check logs for job execution details');
  console.log('⏹️ Press Ctrl+C to stop the scheduler');
});

// Handle graceful shutdown
process.on('SIGINT', () => {
  console.log('\n🛑 Received SIGINT, shutting down gracefully...');
  yamlManager.stopWatching();
  scheduler.stop();
  console.log('👋 Scheduler stopped. Goodbye!');
  process.exit(0);
});

process.on('SIGTERM', () => {
  console.log('\n🛑 Received SIGTERM, shutting down gracefully...');
  yamlManager.stopWatching();
  scheduler.stop();
  console.log('👋 Scheduler stopped. Goodbye!');
  process.exit(0);
});

// Handle uncaught exceptions
process.on('uncaughtException', (error) => {
  console.error('💥 Uncaught Exception:', error);
  scheduler.stop();
  process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('💥 Unhandled Rejection at:', promise, 'reason:', reason);
  scheduler.stop();
  process.exit(1);
}); 
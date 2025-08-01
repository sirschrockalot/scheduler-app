import dotenv from 'dotenv';
import { JobScheduler, JobConfig } from './scheduler';

// Load environment variables
dotenv.config();

// Validate required environment variables
if (!process.env['JWT_TOKEN']) {
  console.error('❌ JWT_TOKEN environment variable is required');
  process.exit(1);
}

// Create scheduler instance
const scheduler = new JobScheduler();

// Define test job configuration
const testJob: JobConfig = {
  name: 'test-api-call',
  cronExpression: '*/5 * * * * *', // Every 5 seconds
  url: 'https://httpbin.org/bearer',
  method: 'GET',
  timeout: 10000, // 10 seconds
  retries: 3
};

// Register the test job
try {
  scheduler.registerJob(testJob);
  console.log('✅ Test job registered successfully');
} catch (error) {
  console.error('❌ Failed to register test job:', error);
  process.exit(1);
}

// Start the scheduler
scheduler.start();

// Log initial status
const status = scheduler.getStatus();
console.log('📊 Scheduler Status:', status);

// Handle graceful shutdown
process.on('SIGINT', () => {
  console.log('\n🛑 Received SIGINT, shutting down gracefully...');
  scheduler.stop();
  console.log('👋 Scheduler stopped. Goodbye!');
  process.exit(0);
});

process.on('SIGTERM', () => {
  console.log('\n🛑 Received SIGTERM, shutting down gracefully...');
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

console.log('🚀 Job Scheduler started successfully!');
console.log('📝 Check logs for job execution details');
console.log('⏹️ Press Ctrl+C to stop the scheduler'); 
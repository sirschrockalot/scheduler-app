import dotenv from 'dotenv';
import { JobScheduler } from './scheduler';
import { JobConfig } from './types';
import { YamlManager } from './yaml-manager';
import { createServer } from 'http';

// Load environment variables
dotenv.config();

// Validate required environment variables
// Either JWT_TOKEN or JWT_SECRET must be set
if (!process.env['JWT_TOKEN'] && !process.env['JWT_SECRET']) {
  console.error('❌ Either JWT_TOKEN or JWT_SECRET environment variable is required');
  process.exit(1);
}

// Create scheduler instance
const scheduler = new JobScheduler();
const yamlManager = new YamlManager();

// Create simple HTTP server for health checks
const server = createServer((req, res) => {
  if (req.url === '/health' && req.method === 'GET') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ 
      status: 'healthy', 
      timestamp: new Date().toISOString(),
      service: 'job-scheduler'
    }));
  } else if (req.url === '/status' && req.method === 'GET') {
    const status = scheduler.getStatus();
    const currentTime = new Date();
    const timezone = process.env.TZ || 'America/Chicago';
    
    const detailedStatus = {
      ...status,
      currentTime: currentTime.toISOString(),
      currentTimeLocal: currentTime.toLocaleString('en-US', { timeZone: timezone }),
      timezone: timezone,
      nodeEnv: process.env['NODE_ENV'],
      uptime: process.uptime(),
      memoryUsage: process.memoryUsage(),
      environment: {
        TZ: process.env.TZ,
        NODE_ENV: process.env['NODE_ENV'],
        JWT_TOKEN_SET: !!process.env['JWT_TOKEN']
      }
    };
    
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(detailedStatus, null, 2));
  } else if (req.url === '/jobs' && req.method === 'GET') {
    const jobNames = scheduler.getJobNames();
    const jobDetails = jobNames.map(name => ({
      name: name,
      isRunning: scheduler.isJobRunning(name)
    }));
    
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({
      jobs: jobDetails,
      totalJobs: jobNames.length,
      currentTime: new Date().toISOString()
    }, null, 2));
  } else {
    res.writeHead(404, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: 'Not found' }));
  }
});

// Start HTTP server
const PORT = process.env['PORT'] || 8081;
server.listen(PORT, () => {
  console.log(`🌐 Health check server listening on port ${PORT}`);
});

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
  server.close(() => {
    console.log('👋 HTTP server stopped. Goodbye!');
    process.exit(0);
  });
});

process.on('SIGTERM', () => {
  console.log('\n🛑 Received SIGTERM, shutting down gracefully...');
  yamlManager.stopWatching();
  scheduler.stop();
  server.close(() => {
    console.log('👋 HTTP server stopped. Goodbye!');
    process.exit(0);
  });
});

// Handle uncaught exceptions
process.on('uncaughtException', (error) => {
  console.error('💥 Uncaught Exception:', error);
  scheduler.stop();
  server.close(() => {
    process.exit(1);
  });
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('💥 Unhandled Rejection at:', promise, 'reason:', reason);
  scheduler.stop();
  server.close(() => {
    process.exit(1);
  });
}); 
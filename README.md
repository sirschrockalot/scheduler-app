# Job Scheduler

A secure cron-based job scheduler built with Node.js and TypeScript that can call external APIs using JWT authentication.

## 🚀 Features

- **Cron-based scheduling** using `node-cron`
- **JWT authentication** for secure API calls
- **Comprehensive logging** with Winston
- **Retry logic** with exponential backoff
- **TypeScript** for type safety
- **Docker support** for containerization
- **Graceful shutdown** handling
- **Error handling** and monitoring

## 📋 Prerequisites

- Node.js 18 or higher
- npm or yarn
- Docker (optional, for containerized deployment)

## 🛠️ Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd job-scheduler
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Set up environment variables**
   ```bash
   cp env.example .env
   ```
   
   Edit `.env` and add your JWT token:
   ```env
   JWT_TOKEN=your_actual_jwt_token_here
   LOG_LEVEL=info
   NODE_ENV=development
   ```

## 🏃‍♂️ Usage

### Development Mode
```bash
npm run dev
```

### Production Mode
```bash
npm run build
npm start
```

### Docker
```bash
# Build the image
docker build -t job-scheduler .

# Run the container
docker run -d \
  --name job-scheduler \
  -e JWT_TOKEN=your_jwt_token \
  -v $(pwd)/logs:/app/logs \
  job-scheduler
```

## 📊 Job Configuration

Jobs are configured using the `JobConfig` interface:

```typescript
interface JobConfig {
  name: string;                    // Unique job identifier
  cronExpression: string;          // Cron expression for scheduling
  url: string;                     // API endpoint to call
  method: 'GET' | 'POST' | 'PUT' | 'DELETE' | 'PATCH';
  headers?: Record<string, string>; // Additional headers
  data?: any;                      // Request body for POST/PUT/PATCH
  timeout?: number;                // Request timeout in ms
  retries?: number;                // Number of retry attempts
}
```

### Example Job Registration

```typescript
import { JobScheduler, JobConfig } from './scheduler';

const scheduler = new JobScheduler();

const job: JobConfig = {
  name: 'api-health-check',
  cronExpression: '*/30 * * * * *', // Every 30 seconds
  url: 'https://api.example.com/health',
  method: 'GET',
  timeout: 10000,
  retries: 3
};

scheduler.registerJob(job);
scheduler.start();
```

## 🔐 JWT Authentication

The scheduler automatically includes the JWT token from the `JWT_TOKEN` environment variable in the `Authorization: Bearer <token>` header for all API requests.

## 📝 Logging

The application uses Winston for comprehensive logging:

- **Console output**: Colored, formatted logs
- **File logs**: 
  - `logs/combined.log` - All logs
  - `logs/error.log` - Error logs only

### Log Levels
- `debug` - Detailed debugging information
- `info` - General information (default)
- `warn` - Warning messages
- `error` - Error messages

## 🐳 Docker Support

### Building the Image
```bash
docker build -t job-scheduler .
```

### Running with Docker Compose
Create a `docker-compose.yml`:

```yaml
version: '3.8'
services:
  job-scheduler:
    build: .
    environment:
      - JWT_TOKEN=${JWT_TOKEN}
      - LOG_LEVEL=info
      - NODE_ENV=production
    volumes:
      - ./logs:/app/logs
    restart: unless-stopped
```

### Environment Variables for Docker
- `JWT_TOKEN` - Required JWT token for API authentication
- `LOG_LEVEL` - Logging level (default: info)
- `NODE_ENV` - Node environment (default: development)

## 📁 Project Structure

```
job-scheduler/
├── src/
│   ├── scheduler.ts       # Main scheduler engine
│   └── index.ts           # Application entry point
├── logs/                  # Log files (created at runtime)
├── dist/                  # Compiled JavaScript (created at build)
├── .env                   # Environment variables
├── env.example           # Environment variables template
├── Dockerfile            # Docker configuration
├── .dockerignore         # Docker ignore file
├── package.json          # Dependencies and scripts
├── tsconfig.json         # TypeScript configuration
└── README.md             # This file
```

## 🔧 Available Scripts

- `npm run dev` - Start in development mode with hot reload
- `npm run build` - Compile TypeScript to JavaScript
- `npm start` - Start the compiled application
- `npm test` - Run tests (if configured)
- `npm run lint` - Run ESLint
- `npm run lint:fix` - Fix ESLint issues

## 🧪 Test Job

The application includes a test job that runs every 5 seconds and calls `https://httpbin.org/bearer` to verify JWT authentication is working correctly.

## 🔍 Monitoring

### Scheduler Status
The scheduler provides status information:
```typescript
const status = scheduler.getStatus();
console.log(status);
// Output: { totalJobs: 1, runningJobs: 1, jobNames: ['test-api-call'] }
```

### Job Management
```typescript
// Check if a job is running
const isRunning = scheduler.isJobRunning('job-name');

// Remove a job
const removed = scheduler.removeJob('job-name');

// Get all job names
const jobNames = scheduler.getJobNames();
```

## 🛡️ Security Features

- **Non-root user** in Docker container
- **JWT token validation** on startup
- **Request timeout** protection
- **Retry limits** to prevent infinite loops
- **Graceful shutdown** handling

## 🚨 Error Handling

The application handles various error scenarios:

- **Network timeouts** - Automatic retry with exponential backoff
- **Authentication failures** - Logged and retried
- **Invalid cron expressions** - Validation on job registration
- **Missing JWT token** - Application exits with error message
- **Uncaught exceptions** - Graceful shutdown

## 📈 Performance

- **Lightweight**: Uses Node.js Alpine image
- **Efficient**: Minimal memory footprint
- **Scalable**: Can handle multiple concurrent jobs
- **Reliable**: Comprehensive error handling and retry logic

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License. # 🚀 GitHub Actions deployment test - Tue Aug 19 15:17:42 CDT 2025

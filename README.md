# Job Scheduler

A secure cron-based job scheduler built with Node.js and TypeScript that can call external APIs using JWT authentication. Deployed on Heroku.

## 🚀 Features

- **Cron-based scheduling** using `node-cron`
- **JWT authentication** for secure API calls
- **Comprehensive logging** with Winston
- **Retry logic** with exponential backoff
- **TypeScript** for type safety
- **Heroku deployment** ready
- **YAML-based job configuration**
- **Graceful shutdown** handling
- **Error handling** and monitoring

## 📋 Prerequisites

- Node.js 18 or higher
- npm or yarn
- Heroku CLI (for deployment)

## 🛠️ Local Development

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

4. **Run in development mode**
   ```bash
   npm run dev
   ```

## 🚀 Heroku Deployment

### Prerequisites
- Heroku CLI installed
- Heroku account

### Deploy to Heroku

1. **Create a new Heroku app**
   ```bash
   heroku create your-app-name
   ```

2. **Set environment variables**
   ```bash
   heroku config:set JWT_TOKEN=your_jwt_token --app your-app-name
   heroku config:set LOG_LEVEL=info --app your-app-name
   heroku config:set NODE_ENV=production --app your-app-name
   ```

3. **Deploy**
   ```bash
   git push heroku master
   ```

4. **Check status**
   ```bash
   heroku ps --app your-app-name
   curl https://your-app-name.herokuapp.com/health
   ```

### Environment Variables

Required environment variables for Heroku:
- `JWT_TOKEN` - JWT token for API authentication
- `LOG_LEVEL` - Logging level (default: info)
- `NODE_ENV` - Node environment (default: production)

Optional for automatic JWT rotation:
- `JWT_SECRET` - If set, the scheduler auto-generates JWTs and refreshes them before expiry; overrides `JWT_TOKEN`
- `JWT_TTL_SECONDS` - Lifetime of generated tokens in seconds (default: 60 days)
- `JWT_REFRESH_BUFFER_SECONDS` - Refresh if token expires within this many seconds (default: 3600)

## 📊 Job Configuration

Jobs are configured in `jobs.yaml`:

```yaml
jobs:
  - name: kpi-afternoon-report
    schedule: "0 1 13 * * 1-5"  # Weekdays at 1:01 PM
    url: "https://api.example.com/report/afternoon"
    method: POST
    headers:
      Authorization: "Bearer ${JWT_TOKEN}"
      Content-Type: "application/json"
    timeout: 15000
    retries: 2
    enabled: true
```

### Job Configuration Options

- `name` - Unique job identifier
- `schedule` - Cron expression for scheduling
- `url` - API endpoint to call
- `method` - HTTP method (GET, POST, PUT, DELETE, PATCH)
- `headers` - Additional headers (supports ${JWT_TOKEN} variable)
- `timeout` - Request timeout in milliseconds
- `retries` - Number of retry attempts
- `enabled` - Whether the job is active

## 🔐 JWT Authentication

The scheduler automatically includes the JWT token from the `JWT_TOKEN` environment variable in the `Authorization: Bearer <token>` header for all API requests.

### Generating JWT Tokens

If you need to generate a JWT token:

```bash
npm install jsonwebtoken
node -e "
const jwt = require('jsonwebtoken');
const secret = 'your_jwt_secret';
const payload = { 
  sub: 'scheduler-app', 
  iat: Math.floor(Date.now() / 1000),
  exp: Math.floor(Date.now() / 1000) + (60 * 60 * 24) // 24 hours
};
const token = jwt.sign(payload, secret);
console.log('JWT Token:', token);
"
```

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

## 📁 Project Structure

```
job-scheduler/
├── src/
│   ├── scheduler.ts       # Main scheduler engine
│   ├── yaml-manager.ts    # YAML configuration manager
│   ├── types.ts           # TypeScript type definitions
│   └── index.ts           # Application entry point
├── logs/                  # Log files (created at runtime)
├── dist/                  # Compiled JavaScript (created at build)
├── jobs.yaml             # Job configuration
├── env.example           # Environment variables template
├── env.production        # Production environment template
├── Procfile              # Heroku process configuration
├── package.json          # Dependencies and scripts
├── tsconfig.json         # TypeScript configuration
└── README.md             # This file
```

## 🔧 Available Scripts

- `npm run dev` - Start in development mode with hot reload
- `npm run build` - Compile TypeScript to JavaScript
- `npm start` - Start the compiled application
- `npm test` - Run tests
- `npm run lint` - Run ESLint
- `npm run lint:fix` - Fix ESLint issues

## 🔍 Monitoring

### Health Check Endpoints

- `GET /health` - Application health status
- `GET /status` - Scheduler status and running jobs

### Heroku Logs

```bash
heroku logs --tail --app your-app-name
```

### Job Management

The scheduler provides status information:
```typescript
const status = scheduler.getStatus();
console.log(status);
// Output: { totalJobs: 2, runningJobs: 2, jobNames: ['kpi-afternoon-report', 'kpi-evening-report'] }
```

## 🛡️ Security Features

- **JWT token validation** on startup
- **Request timeout** protection
- **Retry limits** to prevent infinite loops
- **Graceful shutdown** handling
- **Environment variable** protection

## 🚨 Error Handling

The application handles various error scenarios:

- **Network timeouts** - Automatic retry with exponential backoff
- **Authentication failures** - Logged and retried
- **Invalid cron expressions** - Validation on job registration
- **Missing JWT token** - Application exits with error message
- **Uncaught exceptions** - Graceful shutdown

## 📈 Performance

- **Lightweight**: Minimal memory footprint
- **Efficient**: Optimized for Heroku deployment
- **Scalable**: Can handle multiple concurrent jobs
- **Reliable**: Comprehensive error handling and retry logic

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License.
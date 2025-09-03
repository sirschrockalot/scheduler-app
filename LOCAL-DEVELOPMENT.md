# Local Development Guide

This guide will help you set up and run the Job Scheduler application locally for development.

## 🚀 Quick Start

### 1. Prerequisites

- Node.js 18 or higher
- npm or yarn
- Access to the Slack-KPI-Service (running on Heroku or locally)
- Valid API tokens (JWT, Aircall, Slack)

### 2. Setup Environment

```bash
# Copy the environment template
cp env.example .env

# Edit .env with your actual values
nano .env
```

### 3. Install Dependencies

```bash
npm install
```

### 4. Run the Application

```bash
# Development mode with hot reload
npm run dev

# Or build and run
npm run build
npm start
```

## 📁 File Structure

```
scheduler-app/
├── src/
│   ├── scheduler.ts       # Main scheduler engine
│   ├── yaml-manager.ts    # YAML configuration manager
│   ├── types.ts           # TypeScript type definitions
│   └── index.ts           # Application entry point
├── jobs.yaml             # Job configuration
├── jobs-local.yaml       # Local job configuration (optional)
├── .env                  # Environment variables (create this)
├── env.example           # Environment template
├── env.production        # Production environment template
└── LOCAL-DEVELOPMENT.md  # This file
```

## ⚙️ Configuration

### Environment Variables (.env)

Required variables:
```bash
JWT_TOKEN=your_actual_jwt_token
AIRCALL_API_TOKEN=your_actual_aircall_token
SLACK_API_TOKEN=your_actual_slack_token
```

Optional variables:
```bash
LOG_LEVEL=debug
NODE_ENV=development
PORT=8081
```

### Job Configuration (jobs.yaml)

The main configuration includes:

- **KPI Afternoon Report**: Weekdays at 1:01 PM CST
- **KPI Evening Report**: Weekdays at 6:30 PM CST

For local testing, you can create a `jobs-local.yaml` with shorter intervals:

```yaml
jobs:
  - name: kpi-afternoon-report-local
    schedule: "0 */2 * * * *"  # Every 2 minutes
    url: "https://slack-kpi-service-dbf2f7d60f2e.herokuapp.com/report/afternoon"
    method: POST
    headers:
      Authorization: "Bearer ${JWT_TOKEN}"
      Content-Type: "application/json"
    timeout: 15000
    retries: 2
    enabled: true
```

## 🌐 Available Endpoints

When running locally:

- **Health Check**: http://localhost:8081/health
- **Status**: http://localhost:8081/status

## 🔧 Useful Commands

### Development Commands
```bash
# Start with hot reload
npm run dev

# Build TypeScript
npm run build

# Run tests
npm test

# Lint code
npm run lint
```

### Testing Commands
```bash
# Test health endpoint
curl http://localhost:8081/health

# Test status endpoint
curl http://localhost:8081/status

# Test job execution manually
curl -X POST https://slack-kpi-service-dbf2f7d60f2e.herokuapp.com/report/afternoon \
  -H "Authorization: Bearer your_jwt_token" \
  -H "Content-Type: application/json"
```

## 🔍 Monitoring and Debugging

### Check Application Status
```bash
# Check if application is running
curl http://localhost:8081/health

# Check scheduler status
curl http://localhost:8081/status
```

### View Logs
```bash
# Application logs (console output)
# Logs are displayed in the terminal when running npm run dev

# File logs (if running with npm start)
tail -f logs/combined.log
tail -f logs/error.log
```

### Debug Mode

Enable debug logging by setting in `.env`:
```bash
LOG_LEVEL=debug
NODE_ENV=development
```

## 🐛 Troubleshooting

### Common Issues

1. **Port Already in Use**
   ```bash
   # Check what's using the port
   lsof -i :8081
   
   # Kill the process or change PORT in .env
   ```

2. **Environment Variables Not Loaded**
   ```bash
   # Check if .env exists and has correct format
   cat .env
   
   # Ensure no spaces around = in .env
   JWT_TOKEN=your_token_here
   ```

3. **JWT Token Issues**
   ```bash
   # Generate a new JWT token if needed
   npm install jsonwebtoken
   node -e "
   const jwt = require('jsonwebtoken');
   const secret = 'your_jwt_secret';
   const payload = { sub: 'scheduler-app', iat: Math.floor(Date.now() / 1000) };
   const token = jwt.sign(payload, secret);
   console.log('JWT Token:', token);
   "
   ```

4. **Job Not Running**
   ```bash
   # Check job configuration
   cat jobs.yaml
   
   # Check scheduler logs in console
   # Look for job registration messages
   ```

### Debug Mode

Enable debug logging by setting in `.env`:
```bash
LOG_LEVEL=debug
NODE_ENV=development
```

## 🔄 Development Workflow

1. **Make Changes**: Edit source code or configuration
2. **Test Locally**: `npm run dev` (auto-reloads on changes)
3. **Build**: `npm run build`
4. **Test**: Check logs and endpoints
5. **Deploy**: `git push heroku master` (when ready)

## 📝 Notes

- The local setup uses the same codebase as production
- Jobs can be configured with shorter intervals for testing
- All logs are displayed in the console during development
- The application connects to the Heroku-deployed Slack-KPI-Service
- Environment variables are loaded from `.env` file

## 🆘 Getting Help

If you encounter issues:

1. Check the console logs when running `npm run dev`
2. Verify environment variables: `cat .env`
3. Test endpoints: `curl http://localhost:8081/health`
4. Review this documentation
5. Check the main README.md for additional information
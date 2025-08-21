# Local Development Guide

This guide will help you set up and run the Job Scheduler application locally using Docker.

## 🚀 Quick Start

### 1. Prerequisites

- Docker and Docker Compose installed
- Access to the Slack-KPI-Service (running in Docker or accessible via network)
- Valid API tokens (JWT, Aircall, Slack)

### 2. Setup Environment

```bash
# Copy the local environment template
cp env.local.example .env.local

# Edit .env.local with your actual values
nano .env.local
```

### 3. Run the Application

```bash
# Use the automated script (recommended)
./run-local.sh

# Or manually with Docker Compose
docker-compose -f docker-compose.local.yml up -d
```

## 📁 File Structure

```
scheduler-app/
├── jobs-local.yaml          # Local job configuration
├── docker-compose.local.yml # Local Docker Compose setup
├── .env.local              # Local environment variables (create this)
├── env.local.example       # Environment template
├── run-local.sh            # Automated setup script
└── LOCAL-DEVELOPMENT.md    # This file
```

## ⚙️ Configuration

### Environment Variables (.env.local)

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
TZ=America/Chicago
PORT=8081
```

### Job Configuration (jobs-local.yaml)

The local configuration includes:

- **KPI Afternoon Report**: Runs every 2 minutes
- **KPI Evening Report**: Runs every 3 minutes  
- **Health Check**: Runs every minute
- **Test Job**: Runs every 30 seconds

All jobs are configured for local testing with shorter intervals.

## 🌐 Available Endpoints

When running locally:

- **Job Scheduler**: http://localhost:8081
- **Health Check**: http://localhost:8081/health
- **Status**: http://localhost:8081/status
- **Test API**: http://localhost:8080

## 🔧 Useful Commands

### Start Services
```bash
# Automated setup
./run-local.sh

# Manual start
docker-compose -f docker-compose.local.yml up -d
```

### View Logs
```bash
# All services
docker-compose -f docker-compose.local.yml logs -f

# Specific service
docker-compose -f docker-compose.local.yml logs -f job-scheduler-local
```

### Stop Services
```bash
docker-compose -f docker-compose.local.yml down
```

### Restart Services
```bash
docker-compose -f docker-compose.local.yml restart
```

### Rebuild and Start
```bash
docker-compose -f docker-compose.local.yml down
docker-compose -f docker-compose.local.yml build --no-cache
docker-compose -f docker-compose.local.yml up -d
```

## 🔍 Monitoring and Debugging

### Check Service Status
```bash
# Check if containers are running
docker-compose -f docker-compose.local.yml ps

# Check health endpoints
curl http://localhost:8081/health
curl http://localhost:8080/health
```

### View Job Execution
```bash
# Watch job scheduler logs
docker-compose -f docker-compose.local.yml logs -f job-scheduler-local

# Check specific job execution
docker exec job-scheduler-local tail -f /app/logs/scheduler.log
```

### Test Job Execution
```bash
# Manually trigger a job (if supported)
curl -X POST http://localhost:8081/jobs/kpi-afternoon-report-local/trigger
```

## 🐛 Troubleshooting

### Common Issues

1. **Port Already in Use**
   ```bash
   # Check what's using the port
   lsof -i :8081
   lsof -i :8080
   
   # Stop conflicting services
   docker-compose -f docker-compose.local.yml down
   ```

2. **Environment Variables Not Loaded**
   ```bash
   # Check if .env.local exists and has correct format
   cat .env.local
   
   # Ensure no spaces around = in .env.local
   JWT_TOKEN=your_token_here
   ```

3. **Network Connectivity Issues**
   ```bash
   # Check if containers can reach each other
   docker exec job-scheduler-local ping slack-kpi-service-aircall-slack-agent-1
   
   # Check network configuration
   docker network ls
   docker network inspect job-scheduler-local-network
   ```

4. **Job Not Running**
   ```bash
   # Check job configuration
   docker exec job-scheduler-local cat /app/jobs.yaml
   
   # Check scheduler logs
   docker-compose -f docker-compose.local.yml logs job-scheduler-local
   ```

### Debug Mode

Enable debug logging by setting in `.env.local`:
```bash
LOG_LEVEL=debug
ENABLE_DEBUG_LOGGING=true
```

## 🔄 Development Workflow

1. **Make Changes**: Edit source code or configuration
2. **Rebuild**: `docker-compose -f docker-compose.local.yml build`
3. **Restart**: `docker-compose -f docker-compose.local.yml restart`
4. **Test**: Check logs and endpoints
5. **Iterate**: Repeat as needed

## 📝 Notes

- The local setup uses the same Docker image as production
- Jobs run more frequently for testing (30 seconds to 3 minutes)
- All logs are persisted to the `./logs` directory
- The test API server is included for isolated testing
- Network connectivity to Slack-KPI-Service is maintained via external network

## 🆘 Getting Help

If you encounter issues:

1. Check the logs: `docker-compose -f docker-compose.local.yml logs`
2. Verify environment variables: `cat .env.local`
3. Check network connectivity: `docker network ls`
4. Review this documentation
5. Check the main README.md for additional information

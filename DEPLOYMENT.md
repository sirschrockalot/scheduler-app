# 🐳 Docker Deployment and Testing Guide

## Quick Start

### 1. **Prerequisites**
- Docker and Docker Compose installed
- Node.js 18+ (for local development)

### 2. **Setup Environment**
```bash
# Copy environment example
cp env.example .env

# Edit .env with your actual tokens
nano .env
```

### 3. **Deploy and Test**
```bash
# Run the automated deployment and testing script
./test-deployment.sh test
```

## 🚀 Deployment Options

### Option 1: Automated Script (Recommended)
```bash
# Full deployment and testing
./test-deployment.sh test

# Deploy only (no testing)
./test-deployment.sh deploy

# View logs
./test-deployment.sh logs

# Cleanup
./test-deployment.sh cleanup
```

### Option 2: Manual Docker Compose
```bash
# Build and start job scheduler
docker-compose up -d job-scheduler

# Start test API server (for testing)
docker-compose --profile test up -d test-api

# View logs
docker-compose logs -f job-scheduler

# Stop all services
docker-compose down
```

### Option 3: Manual Docker
```bash
# Build the image
docker build -t job-scheduler .

# Run the container
docker run -d \
  --name job-scheduler \
  -p 8081:3000 \
  --env-file .env \
  -v $(pwd)/jobs.yaml:/app/jobs.yaml:ro \
  -v $(pwd)/logs:/app/logs \
  job-scheduler
```

## 🧪 Testing the KPI Job

### 1. **Test Configuration**
The test uses `jobs-test.yaml` which runs the KPI job every 30 seconds:

```yaml
jobs:
  - name: kpi-afternoon-report-test
    schedule: "*/30 * * * * *"  # Every 30 seconds
    url: "http://test-api-server:8080/report/afternoon"
    method: POST
    headers:
      Authorization: "Bearer ${JWT_TOKEN}"
    data:
      test_mode: true
      timestamp: "${NOW}"
```

### 2. **Test API Server**
The test API server provides:
- `GET /health` - Health check
- `GET /status` - Server status
- `POST /report/afternoon` - KPI report endpoint

### 3. **Verification Steps**
1. **Check Job Registration**: Look for "kpi-afternoon-report-test" in logs
2. **Check Job Execution**: Look for "Starting job: kpi-afternoon-report-test"
3. **Check API Calls**: Look for "KPI Report generated successfully" in test API logs
4. **Check Response**: Verify the job receives proper JSON response

### 4. **Manual Testing**
```bash
# Test the API endpoint directly
curl -X POST http://localhost:8080/report/afternoon \
  -H "Authorization: Bearer your_token_here" \
  -H "Content-Type: application/json" \
  -d '{"test_mode": true}'

# Check job scheduler logs
docker-compose logs job-scheduler | grep "kpi-afternoon-report-test"

# Check test API logs
docker-compose logs test-api | grep "KPI Report"
```

## 📊 Monitoring and Logs

### View Logs
```bash
# Job scheduler logs
docker-compose logs -f job-scheduler

# Test API logs
docker-compose logs -f test-api

# All logs
docker-compose logs -f

# Recent logs (last 20 lines)
docker-compose logs --tail=20 job-scheduler
```

### Health Checks
```bash
# Check job scheduler health
curl http://localhost:8081/health

# Check test API health
curl http://localhost:8080/health

# Check container status
docker-compose ps
```

## 🔧 Configuration

### Environment Variables
```bash
# Required
JWT_TOKEN=your_jwt_token_here
AIRCALL_API_TOKEN=your_aircall_token_here

# Optional
LOG_LEVEL=info
NODE_ENV=production
```

### Job Configuration
- **Production**: Use `jobs.yaml` with your actual schedule
- **Testing**: Use `jobs-test.yaml` with frequent execution
- **Custom**: Create your own YAML file

### Docker Configuration
- **Ports**: 8081 (scheduler), 8080 (test API)
- **Volumes**: 
  - `./jobs.yaml:/app/jobs.yaml:ro` (job configuration)
  - `./logs:/app/logs` (log persistence)
  - `./.env:/app/.env:ro` (environment variables)

## 🚨 Troubleshooting

### Common Issues

#### 1. **Container Won't Start**
```bash
# Check Docker logs
docker-compose logs job-scheduler

# Check if ports are available
netstat -tulpn | grep :8081
netstat -tulpn | grep :8080
```

#### 2. **Jobs Not Executing**
```bash
# Check if YAML file is loaded
docker-compose logs job-scheduler | grep "Loaded.*jobs from YAML"

# Check job registration
docker-compose logs job-scheduler | grep "Registered job"

# Verify YAML syntax
docker-compose exec job-scheduler node -e "
const yaml = require('js-yaml');
const fs = require('fs');
try {
  yaml.load(fs.readFileSync('jobs.yaml', 'utf8'));
  console.log('YAML syntax is valid');
} catch(e) {
  console.error('YAML syntax error:', e.message);
}
"
```

#### 3. **API Calls Failing**
```bash
# Check network connectivity
docker-compose exec job-scheduler ping test-api-server

# Check API endpoint
curl -v http://localhost:8080/health

# Check authentication
curl -X POST http://localhost:8080/report/afternoon \
  -H "Authorization: Bearer test_token" \
  -H "Content-Type: application/json"
```

#### 4. **Environment Variables Not Loading**
```bash
# Check if .env file exists
ls -la .env

# Check environment variables in container
docker-compose exec job-scheduler env | grep JWT_TOKEN

# Verify .env file format
cat .env | grep -v "^#" | grep -v "^$"
```

### Debug Mode
```bash
# Run with debug logging
LOG_LEVEL=debug docker-compose up job-scheduler

# Run with interactive shell
docker-compose run --rm job-scheduler sh
```

## 🔄 Production Deployment

### 1. **Update Configuration**
```yaml
# jobs.yaml - Production schedule
jobs:
  - name: kpi-afternoon-report
    schedule: "0 1 13 * * 1-5"  # Weekdays at 1:01 PM
    url: "https://your-production-api.com/report/afternoon"
    method: POST
    headers:
      Authorization: "Bearer ${JWT_TOKEN}"
```

### 2. **Set Production Environment**
```bash
# .env file
NODE_ENV=production
LOG_LEVEL=info
JWT_TOKEN=your_production_jwt_token
AIRCALL_API_TOKEN=your_production_aircall_token
```

### 3. **Deploy**
```bash
# Build and deploy
docker-compose -f docker-compose.prod.yml up -d

# Monitor deployment
docker-compose logs -f job-scheduler
```

## 📈 Performance Monitoring

### Resource Usage
```bash
# Check container resource usage
docker stats job-scheduler

# Check disk usage
docker system df

# Check memory usage
docker-compose exec job-scheduler ps aux
```

### Job Performance
```bash
# Check job execution times
docker-compose logs job-scheduler | grep "execution time"

# Check success/failure rates
docker-compose logs job-scheduler | grep -E "(SUCCESS|FAILED)"

# Check retry attempts
docker-compose logs job-scheduler | grep "retry"
```

## 🔐 Security Considerations

1. **Never commit `.env` files** to version control
2. **Use different tokens** for different environments
3. **Rotate tokens regularly**
4. **Monitor access logs** for suspicious activity
5. **Use HTTPS** for all production API calls
6. **Run containers as non-root** user (already configured)

## 📝 Next Steps

1. **Customize Jobs**: Update `jobs.yaml` with your actual job requirements
2. **Set Up Monitoring**: Configure log aggregation and alerting
3. **Scale**: Consider using Docker Swarm or Kubernetes for production
4. **Backup**: Set up regular backups of job configurations and logs
5. **CI/CD**: Integrate with your deployment pipeline 
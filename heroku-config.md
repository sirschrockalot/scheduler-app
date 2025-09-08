# Heroku Configuration for Reliable Job Scheduler

## Required Environment Variables

Set these in your Heroku app dashboard (Settings → Config Vars):

### Critical Variables:
```bash
# REQUIRED: JWT Token for API authentication
JWT_TOKEN=your_actual_jwt_token_here

# REQUIRED: Timezone for job scheduling
TZ=America/Chicago

# REQUIRED: Production environment
NODE_ENV=production

# Optional: Logging level
LOG_LEVEL=info
```

### Set via Heroku CLI:
```bash
heroku config:set JWT_TOKEN=your_actual_jwt_token_here --app your-app-name
heroku config:set TZ=America/Chicago --app your-app-name
heroku config:set NODE_ENV=production --app your-app-name
heroku config:set LOG_LEVEL=info --app your-app-name
```

## Job Schedule (CST Timezone)

### Afternoon Report:
- **Schedule**: `1 13 * * 1-5` (1:01 PM CST, Monday-Friday)
- **Endpoint**: `/report/afternoon`
- **Description**: KPI afternoon report generation

### Evening Report:
- **Schedule**: `30 18 * * 1-5` (6:30 PM CST, Monday-Friday)
- **Endpoint**: `/report/night`
- **Description**: KPI evening report generation

## Monitoring Endpoints

### Health Check:
```
GET https://your-app.herokuapp.com/health
```

### Detailed Status:
```
GET https://your-app.herokuapp.com/status
```
Returns:
- Job registration status
- Current time (UTC and local)
- Timezone information
- Environment variables status
- Memory usage
- Uptime

### Job List:
```
GET https://your-app.herokuapp.com/jobs
```
Returns:
- List of registered jobs
- Job running status
- Total job count

## Troubleshooting

### Check if jobs are registered:
```bash
curl https://your-app.herokuapp.com/status
```

### Check Heroku logs:
```bash
heroku logs --tail --app your-app-name
```

### Look for these log messages:
```
✅ Job 'kpi-afternoon-report' registered and STARTED with cron expression: 1 13 * * 1-5
✅ Job 'kpi-evening-report' registered and STARTED with cron expression: 30 18 * * 1-5
🎯 Job scheduler started: 2/2 jobs running
```

### Common Issues:

1. **Jobs not running**: Check if `TZ=America/Chicago` is set
2. **Authentication errors**: Verify `JWT_TOKEN` is set correctly
3. **Jobs not registered**: Check logs for cron expression errors
4. **Wrong timezone**: Ensure `TZ` environment variable is set

## Expected Behavior

### On Startup:
1. App loads YAML configuration
2. Jobs are registered with `scheduled: true`
3. Jobs start immediately
4. Logs show successful registration

### During Execution:
1. Jobs run at scheduled times (1:01 PM and 6:30 PM CST)
2. Success/failure is logged
3. Retry logic handles temporary failures
4. Detailed execution logs are available

### Monitoring:
- Use `/status` endpoint to verify job registration
- Use `/jobs` endpoint to check individual job status
- Monitor Heroku logs for execution details

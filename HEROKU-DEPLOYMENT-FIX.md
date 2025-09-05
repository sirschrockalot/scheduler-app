# Heroku Deployment Fix Guide

## Issues Identified and Fixed

### 1. ✅ Fixed: Cron Expression Format
**Problem**: Your jobs were using 6-field cron expressions (with seconds), but `node-cron` expects 5-field expressions.

**Fixed in `jobs.yaml`**:
```yaml
# Before (6 fields - WRONG)
schedule: "0 1 13 * * 1-5"  # Weekdays at 1:01 PM

# After (5 fields - CORRECT)
schedule: "1 13 * * 1-5"  # Weekdays at 1:01 PM
```

### 2. ✅ Fixed: Timezone Configuration
**Problem**: Heroku runs in UTC by default, but your jobs need to run in CST.

**Fixed in `scheduler.ts`**: Added proper timezone handling for production environment.

## Required Heroku Configuration

### Environment Variables
Set these in your Heroku app dashboard (Settings → Config Vars):

```bash
# Required
JWT_TOKEN=your_actual_jwt_token_here
NODE_ENV=production
TZ=America/Chicago

# Optional but recommended
LOG_LEVEL=info
```

### Set Environment Variables via Heroku CLI:
```bash
heroku config:set JWT_TOKEN=your_actual_jwt_token_here --app your-app-name
heroku config:set NODE_ENV=production --app your-app-name
heroku config:set TZ=America/Chicago --app your-app-name
heroku config:set LOG_LEVEL=info --app your-app-name
```

## Deployment Steps

### 1. Commit and Deploy Changes
```bash
git add .
git commit -m "Fix cron expressions and timezone for Heroku deployment"
git push heroku main
```

### 2. Verify Deployment
```bash
# Check app logs
heroku logs --tail --app your-app-name

# Check if jobs are registered
heroku run "curl http://localhost:$PORT/status" --app your-app-name
```

### 3. Test Job Execution
You can temporarily enable the test job to verify everything works:

```yaml
# In jobs.yaml, change this:
- name: test-job-minute
  schedule: "* * * * *"  # Every minute
  enabled: true  # Change from false to true
```

**Remember to disable it after testing!**

## Expected Behavior After Fix

### Job Schedule (CST Timezone):
- **Afternoon Report**: Weekdays at 1:01 PM CST
- **Evening Report**: Weekdays at 6:30 PM CST

### Log Messages to Look For:
```
Job 'kpi-afternoon-report' registered with cron expression: 1 13 * * 1-5
Job 'kpi-evening-report' registered with cron expression: 30 18 * * 1-5
▶️ Started job: kpi-afternoon-report
▶️ Started job: kpi-evening-report
```

### When Jobs Execute:
```
🚀 Starting job: kpi-afternoon-report
✅ Job 'kpi-afternoon-report' completed successfully
```

## Troubleshooting

### If Jobs Still Don't Run:

1. **Check Environment Variables**:
   ```bash
   heroku config --app your-app-name
   ```

2. **Check Logs for Errors**:
   ```bash
   heroku logs --tail --app your-app-name
   ```

3. **Verify JWT Token**:
   - Ensure your JWT token is valid and not expired
   - Test the token manually with your KPI service

4. **Check Timezone**:
   - Verify `TZ=America/Chicago` is set
   - Check logs for timezone information

### Common Issues:

- **"Invalid cron expression"**: Check that all cron expressions use 5 fields
- **"JWT_TOKEN environment variable is required"**: Set the JWT_TOKEN config var
- **"getaddrinfo ENOTFOUND"**: Environment variable substitution not working
- **Jobs not running at expected time**: Timezone configuration issue

## Monitoring

### Health Check Endpoints:
- `https://your-app.herokuapp.com/health` - Basic health check
- `https://your-app.herokuapp.com/status` - Job scheduler status

### Log Monitoring:
```bash
# Real-time logs
heroku logs --tail --app your-app-name

# Recent logs
heroku logs --num 100 --app your-app-name
```

## Next Steps

1. Deploy the fixed code to Heroku
2. Set the required environment variables
3. Monitor the logs for successful job registration
4. Test with the temporary test job if needed
5. Verify jobs run at the correct times (1:01 PM and 6:30 PM CST on weekdays)

The main issues were the cron expression format and timezone configuration. With these fixes, your afternoon and nightly jobs should now run properly in Heroku.

# Nightly Job Troubleshooting Guide

## Issue Analysis

The nightly job has been failing to run consistently. Here's what we've identified and fixed:

### Root Causes Identified:

1. **Timezone Configuration Issues**
   - Heroku runs in UTC by default
   - Jobs scheduled for CST might not trigger correctly
   - Environment variable `TZ=America/Chicago` must be set

2. **Cron Expression Interpretation**
   - 5-field cron expressions: `30 18 * * 1-5` (6:30 PM CST, Mon-Fri)
   - Timezone conversion between UTC and CST

3. **Heroku App Restarts**
   - Heroku may restart apps during scheduled times
   - Jobs might be lost during restarts

4. **Environment Variable Issues**
   - JWT_TOKEN substitution might fail
   - Missing or incorrect environment variables

## Solutions Implemented:

### 1. Backup Job Added
- **Primary**: 6:30 PM CST (`30 18 * * 1-5`)
- **Backup**: 6:35 PM CST (`35 18 * * 1-5`) - 5 minutes later
- This ensures if the primary fails, backup runs

### 2. Enhanced Logging
- Added detailed timezone logging
- Job trigger timestamps in both UTC and local time
- Environment variable validation

### 3. Improved Error Handling
- Better error messages for debugging
- Comprehensive logging for troubleshooting

## Required Heroku Configuration:

### Environment Variables (CRITICAL):
```bash
# REQUIRED: Set timezone
TZ=America/Chicago

# REQUIRED: JWT Token
JWT_TOKEN=your_actual_jwt_token_here

# REQUIRED: Production environment
NODE_ENV=production
```

### Set via Heroku CLI:
```bash
heroku config:set TZ=America/Chicago --app your-app-name
heroku config:set JWT_TOKEN=your_actual_jwt_token --app your-app-name
heroku config:set NODE_ENV=production --app your-app-name
```

## Monitoring Commands:

### Check Job Status:
```bash
curl https://your-app.herokuapp.com/status
```

### Check Individual Jobs:
```bash
curl https://your-app.herokuapp.com/jobs
```

### Monitor Logs:
```bash
heroku logs --tail --app your-app-name
```

## Expected Log Messages:

### On Startup:
```
🕐 Scheduling job 'kpi-evening-report' with timezone: America/Chicago
✅ Job 'kpi-evening-report' registered and STARTED with cron expression: 30 18 * * 1-5
🕐 Scheduling job 'kpi-evening-report-backup' with timezone: America/Chicago
✅ Job 'kpi-evening-report-backup' registered and STARTED with cron expression: 35 18 * * 1-5
```

### When Jobs Execute:
```
⏰ Job 'kpi-evening-report' triggered at: 2025-09-09T23:30:00.000Z (9/9/2025, 6:30:00 PM CDT)
🚀 Starting job: kpi-evening-report
✅ Job 'kpi-evening-report' completed successfully
```

## Troubleshooting Steps:

### 1. Verify Environment Variables:
```bash
heroku config --app your-app-name
```
Look for:
- `TZ=America/Chicago`
- `JWT_TOKEN=...` (should be set)
- `NODE_ENV=production`

### 2. Check Job Registration:
```bash
curl https://your-app.herokuapp.com/status | jq '.jobNames'
```
Should show: `["kpi-afternoon-report", "kpi-evening-report", "kpi-evening-report-backup"]`

### 3. Monitor Execution:
```bash
heroku logs --tail --app your-app-name | grep -E "(evening-report|triggered|completed)"
```

### 4. Test Endpoint Manually:
```bash
curl -X POST \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -H "X-Custom-Header: kpi-app" \
  -H "Content-Type: application/json" \
  https://slack-kpi-service-dbf2f7d60f2e.herokuapp.com/report/night
```

## Common Issues and Fixes:

### Issue: Jobs not registered
**Fix**: Check Heroku logs for cron expression errors

### Issue: Jobs registered but not executing
**Fix**: Verify `TZ=America/Chicago` is set

### Issue: Authentication errors
**Fix**: Verify `JWT_TOKEN` is set correctly

### Issue: Network errors
**Fix**: Check KPI service availability

## Next Steps:

1. Deploy the updated configuration
2. Verify environment variables are set
3. Monitor logs for job registration
4. Test manual execution
5. Monitor scheduled execution at 6:30 PM and 6:35 PM CST

The backup job ensures that even if the primary job fails, the nightly report will still be sent.

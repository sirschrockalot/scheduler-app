# Heroku Deployment Verification Guide

## ✅ Environment Variables Configured

Great! The environment variables are now set in Heroku. Here's how to verify everything is working:

## 🔍 Verification Steps

### 1. Check Heroku Logs
```bash
heroku logs --tail --app your-app-name
```

**Look for these success messages:**
```
✅ Job 'kpi-afternoon-report' registered and STARTED with cron expression: 1 13 * * 1-5
✅ Job 'kpi-evening-report' registered and STARTED with cron expression: 30 18 * * 1-5
✅ Job 'kpi-evening-report-backup' registered and STARTED with cron expression: 35 18 * * 1-5
🎯 Job scheduler started: 3/3 jobs running
```

### 2. Check Status Endpoint
```bash
curl https://your-app.herokuapp.com/status
```

**Expected response should include:**
- `totalJobs: 3`
- `runningJobs: 3`
- `timezone: "America/Chicago"`
- `environment.JWT_TOKEN_SET: true`

### 3. Check Jobs Endpoint
```bash
curl https://your-app.herokuapp.com/jobs
```

**Expected jobs:**
- `kpi-afternoon-report`
- `kpi-evening-report`
- `kpi-evening-report-backup`

## 📅 Job Schedule (CST Timezone)

### Afternoon Report:
- **Time**: 1:01 PM CST (Monday-Friday)
- **Job**: `kpi-afternoon-report`
- **Endpoint**: `/report/afternoon`

### Evening Reports:
- **Primary**: 6:30 PM CST (Monday-Friday)
- **Backup**: 6:35 PM CST (Monday-Friday)
- **Jobs**: `kpi-evening-report` and `kpi-evening-report-backup`
- **Endpoint**: `/report/night`

## 🔍 Monitoring Commands

### Real-time Logs:
```bash
heroku logs --tail --app your-app-name
```

### Check Environment Variables:
```bash
heroku config --app your-app-name
```

### Health Check:
```bash
curl https://your-app.herokuapp.com/health
```

## 🎯 Expected Behavior

### On App Startup:
1. YAML configuration loads
2. Jobs register with timezone: America/Chicago
3. Jobs start immediately (scheduled: true)
4. Success logs appear

### During Job Execution:
1. Job trigger logs appear at scheduled times
2. HTTP requests to KPI service
3. Success/failure logs with execution times
4. Slack notifications sent

## 🚨 Troubleshooting

### If Jobs Don't Register:
- Check Heroku logs for cron expression errors
- Verify environment variables are set
- Check for TypeScript compilation errors

### If Jobs Register But Don't Execute:
- Verify `TZ=America/Chicago` is set
- Check timezone in logs
- Monitor for app restarts during scheduled times

### If Jobs Execute But Fail:
- Check JWT_TOKEN is valid
- Verify KPI service endpoint is accessible
- Check network connectivity

## 📊 Success Indicators

✅ **Deployment Successful When:**
- All 3 jobs register successfully
- Timezone shows "America/Chicago"
- JWT_TOKEN_SET is true
- No error messages in logs
- Health endpoint returns 200

✅ **Jobs Working When:**
- Jobs trigger at scheduled times
- HTTP requests succeed (200 status)
- Slack notifications are sent
- Execution logs show success

## 🎉 Next Steps

1. **Monitor Today**: Watch for afternoon job at 1:01 PM CST
2. **Monitor Tonight**: Watch for evening jobs at 6:30 PM and 6:35 PM CST
3. **Verify Reports**: Check that Slack notifications are received
4. **Long-term**: Monitor for consistent execution over several days

The scheduler is now configured for reliable execution with backup mechanisms in place!

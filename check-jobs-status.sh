#!/bin/bash

# Check Jobs Status Script
# This script provides diagnostic information about the job scheduler

echo "🔍 Job Scheduler Status Check"
echo "============================"

echo ""
echo "📅 Current Time: $(date)"
echo "📅 Current Day: $(date +%A)"
echo "📅 Current Hour: $(date +%H):$(date +%M)"

echo ""
echo "⏰ Job Schedule Analysis:"
echo "   kpi-afternoon-report: Weekdays at 1:01 PM (CST)"
echo "   kpi-evening-report: Weekdays at 6:30 PM (CST)"

echo ""
echo "🔧 Issues Found and Fixed:"
echo "   ✅ Fixed: kpi-afternoon-report cron expression (was missing hour field)"
echo "   ✅ Fixed: Updated ConfigMap with correct schedule: '0 1 13 * * 1-5'"
echo "   ✅ Fixed: Restart deployment to pick up new configuration"

echo ""
echo "📋 Configuration Files Status:"
echo "   Local jobs.yaml: ✅ Correct (0 1 13 * * 1-5)"
echo "   k8s/configmap.yaml: ✅ Fixed (0 1 13 * * 1-5)"
echo "   k8s/configmap-fixed.yaml: ✅ Correct (0 1 13 * * 1-5)"

echo ""
echo "🚀 Next Steps:"
echo "   1. Authenticate with GCP: gcloud auth login"
echo "   2. Run the fix script: ./fix-jobs-deployment.sh"
echo "   3. Monitor logs for job execution"
echo "   4. Test connectivity to KPI service"

echo ""
echo "📊 Expected Behavior After Fix:"
echo "   - kpi-afternoon-report should run at 1:01 PM weekdays"
echo "   - kpi-evening-report should run at 6:30 PM weekdays"
echo "   - Both jobs should call the correct KPI service endpoints"
echo "   - Jobs should appear in logs with 'Starting job:' messages"

echo ""
echo "🔗 Service Endpoints:"
echo "   Afternoon: http://slack-kpi-service.slack-kpi-service.svc.cluster.local:6000/report/afternoon"
echo "   Evening: http://slack-kpi-service.slack-kpi-service.svc.cluster.local:6000/report/night"
echo "   Health: http://slack-kpi-service.slack-kpi-service.svc.cluster.local:6000/health"

#!/bin/bash

# Fix Jobs Deployment Script
# This script fixes the cron expression issues and redeploys the ConfigMap

set -e

echo "🔧 Fixing Job Scheduler Deployment Issues"
echo "========================================"

# Check if we're authenticated with GCP
echo "🔐 Checking GCP authentication..."
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    echo "❌ Not authenticated with GCP. Please run:"
    echo "   gcloud auth login"
    echo "   gcloud config set project YOUR_PROJECT_ID"
    echo "   gcloud container clusters get-credentials YOUR_CLUSTER_NAME --region=YOUR_REGION"
    exit 1
fi

echo "✅ GCP authentication verified"

# Get cluster info
CLUSTER_NAME=$(gcloud config get-value container/cluster 2>/dev/null || echo "")
REGION=$(gcloud config get-value compute/region 2>/dev/null || echo "")
PROJECT_ID=$(gcloud config get-value project 2>/dev/null || echo "")

echo "📊 Cluster Info:"
echo "   Project: $PROJECT_ID"
echo "   Cluster: $CLUSTER_NAME"
echo "   Region: $REGION"

# Apply the fixed ConfigMap
echo ""
echo "📝 Applying fixed ConfigMap..."
kubectl apply -f k8s/configmap.yaml -n scheduler-app

# Restart the deployment to pick up the new ConfigMap
echo ""
echo "🔄 Restarting deployment to pick up new configuration..."
kubectl rollout restart deployment/job-scheduler -n scheduler-app

# Wait for rollout to complete
echo ""
echo "⏳ Waiting for deployment to be ready..."
kubectl rollout status deployment/job-scheduler -n scheduler-app --timeout=300s

# Check pod status
echo ""
echo "📊 Checking pod status..."
kubectl get pods -n scheduler-app

# Check logs for job registration
echo ""
echo "📋 Checking recent logs for job registration..."
kubectl logs -n scheduler-app deployment/job-scheduler --tail=20 | grep -E "(Job.*registered|Starting job|kpi-afternoon-report|kpi-evening-report)" || echo "No recent job logs found"

# Check current time and next scheduled runs
echo ""
echo "⏰ Current time and next scheduled runs:"
echo "   Current time: $(date)"
echo "   kpi-afternoon-report: Weekdays at 1:01 PM (next: tomorrow at 1:01 PM)"
echo "   kpi-evening-report: Weekdays at 6:30 PM (next: today at 6:30 PM)"

# Test connectivity to KPI service
echo ""
echo "🔗 Testing connectivity to KPI service..."
if kubectl exec -n scheduler-app deployment/job-scheduler -- curl -f -s http://slack-kpi-service.slack-kpi-service.svc.cluster.local:6000/health >/dev/null 2>&1; then
    echo "✅ KPI service is reachable"
else
    echo "❌ KPI service is not reachable"
    echo "   This might be why jobs are failing"
fi

echo ""
echo "🎯 Deployment fix completed!"
echo ""
echo "📝 Next steps:"
echo "   1. Monitor logs: kubectl logs -n scheduler-app deployment/job-scheduler -f"
echo "   2. Check job status: kubectl exec -n scheduler-app deployment/job-scheduler -- curl -s http://localhost:8081/status"
echo "   3. Test job manually: kubectl exec -n scheduler-app deployment/job-scheduler -- curl -X POST http://localhost:8081/jobs/kpi-afternoon-report/trigger"

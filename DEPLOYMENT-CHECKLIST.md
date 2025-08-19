# ✅ GKE Deployment Checklist

Use this checklist to ensure a successful deployment of your job scheduler to GKE.

## 🔧 Pre-Deployment Setup

### GCP Configuration
- [ ] Google Cloud SDK (gcloud) installed and configured
- [ ] kubectl CLI tool installed
- [ ] GCP project selected: `gcloud config set project YOUR_PROJECT_ID`
- [ ] GKE cluster exists and is running
- [ ] Docker configured for GCR: `gcloud auth configure-docker`

### Local Environment
- [ ] Docker running locally
- [ ] `.env` file created with actual tokens
- [ ] Required tokens available:
  - [ ] JWT token for authentication
  - [ ] Aircall API token (if needed)
- [ ] All scripts made executable: `chmod +x *.sh`

### Application Code
- [ ] TypeScript code compiles: `npm run build`
- [ ] Docker image builds successfully: `docker build -t job-scheduler .`
- [ ] Health check endpoints working in local container

## 🚀 Deployment Steps

### 1. Build and Push Image
- [ ] Docker image built: `docker build -t gcr.io/PROJECT_ID/job-scheduler:latest .`
- [ ] Image pushed to GCR: `docker push gcr.io/PROJECT_ID/job-scheduler:latest`
- [ ] Image accessible in GCR

### 2. Update Kubernetes Manifests
- [ ] `k8s/deployment.yaml` updated with correct GCR image path
- [ ] `k8s/secret.yaml` updated with base64 encoded tokens
- [ ] `k8s/configmap.yaml` contains correct KPI service URLs
- [ ] All manifests use correct namespace: `scheduler-app`

### 3. Deploy to Kubernetes
- [ ] Namespace created: `kubectl apply -f k8s/namespace.yaml`
- [ ] Secrets created: `kubectl apply -f k8s/secret.yaml`
- [ ] ConfigMap created: `kubectl apply -f k8s/configmap.yaml`
- [ ] Deployment created: `kubectl apply -f k8s/deployment.yaml`
- [ ] Service created: `kubectl apply -f k8s/service.yaml`
- [ ] Network policy applied: `kubectl apply -f k8s/network-policy.yaml`

## 🔍 Post-Deployment Verification

### Pod Status
- [ ] Pod is running: `kubectl get pods -n scheduler-app`
- [ ] Pod is ready: `kubectl get pods -n scheduler-app -o wide`
- [ ] No pod restarts or crashes

### Service Configuration
- [ ] Service created: `kubectl get svc -n scheduler-app`
- [ ] Service endpoints exist: `kubectl get endpoints -n scheduler-app`
- [ ] Service selector matches pod labels

### Application Health
- [ ] Health endpoint responds: `kubectl exec -n scheduler-app deployment/job-scheduler -- curl -s http://localhost:8081/health`
- [ ] Status endpoint works: `kubectl exec -n scheduler-app deployment/job-scheduler -- curl -s http://localhost:8081/status`
- [ ] Application logs show successful startup

### KPI Service Connectivity
- [ ] Can resolve KPI service DNS: `kubectl exec -n scheduler-app deployment/job-scheduler -- nslookup slack-kpi-service.slack-kpi-service.svc.cluster.local`
- [ ] Can connect to KPI service: `kubectl exec -n scheduler-app deployment/job-scheduler -- curl -v http://slack-kpi-service.slack-kpi-service.svc.cluster.local:6000/health`
- [ ] Network policy allows communication

## 📊 Monitoring & Testing

### Job Execution
- [ ] Jobs are registered from YAML configuration
- [ ] Cron jobs are scheduled and running
- [ ] Job execution logs show successful API calls
- [ ] No authentication or connection errors

### Resource Usage
- [ ] Pod resource usage within limits: `kubectl top pods -n scheduler-app`
- [ ] No OOM kills or resource pressure
- [ ] CPU and memory usage reasonable

### Logging
- [ ] Application logs accessible: `kubectl logs -n scheduler-app deployment/job-scheduler`
- [ ] Log level appropriate for production
- [ ] No error logs or warnings

## 🔧 Troubleshooting Checklist

### If Pod Won't Start
- [ ] Check pod events: `kubectl describe pod -n scheduler-app -l app=job-scheduler`
- [ ] Check pod logs: `kubectl logs -n scheduler-app deployment/job-scheduler --previous`
- [ ] Verify image exists in GCR
- [ ] Check resource requests/limits
- [ ] Verify secrets are properly mounted

### If Jobs Not Executing
- [ ] Check if YAML config loaded: `kubectl logs -n scheduler-app deployment/job-scheduler | grep "Loaded.*jobs"`
- [ ] Verify configmap: `kubectl get configmap scheduler-config -n scheduler-app -o yaml`
- [ ] Check job registration logs
- [ ] Verify cron expressions are valid

### If Cannot Connect to KPI Service
- [ ] Check if KPI service is running: `kubectl get pods -n slack-kpi-service`
- [ ] Test DNS resolution: `kubectl exec -n scheduler-app deployment/job-scheduler -- nslookup slack-kpi-service.slack-kpi-service.svc.cluster.local`
- [ ] Test direct connection: `kubectl exec -n scheduler-app deployment/job-scheduler -- curl -v http://slack-kpi-service.slack-kpi-service.svc.cluster.local:6000/health`
- [ ] Verify network policy allows communication
- [ ] Check if services are in same cluster

### If Authentication Fails
- [ ] Verify secrets are mounted: `kubectl exec -n scheduler-app deployment/job-scheduler -- env | grep JWT_TOKEN`
- [ ] Check secret values: `kubectl get secret scheduler-secrets -n scheduler-app -o yaml`
- [ ] Verify tokens are valid and not expired
- [ ] Check if tokens have correct permissions

## 🎯 Success Criteria

### Deployment Success
- [ ] All Kubernetes resources created successfully
- [ ] Pod running and healthy
- [ ] Health endpoints responding
- [ ] Application logs show successful startup

### Functionality Success
- [ ] Jobs loaded from YAML configuration
- [ ] Cron jobs scheduled and running
- [ ] Can connect to Slack-KPI-Service
- [ ] Jobs execute successfully
- [ ] No critical errors in logs

### Production Readiness
- [ ] Resource limits appropriate
- [ ] Health checks configured
- [ ] Logging level appropriate
- [ ] Secrets properly managed
- [ ] Network policies configured

## 🆘 Emergency Procedures

### Rollback
- [ ] Previous deployment image available
- [ ] Rollback command ready: `kubectl rollout undo deployment/job-scheduler -n scheduler-app`
- [ ] Backup of working configuration

### Debug Mode
- [ ] Can access pod shell: `kubectl exec -it -n scheduler-app deployment/job-scheduler -- /bin/sh`
- [ ] Can view real-time logs: `kubectl logs -f -n scheduler-app deployment/job-scheduler`
- [ ] Can check pod status: `kubectl describe pod -n scheduler-app -l app=job-scheduler`

### Cleanup
- [ ] Cleanup command ready: `kubectl delete namespace scheduler-app`
- [ ] Docker images can be removed
- [ ] GCR images can be deleted if needed

## 📝 Post-Deployment Tasks

### Documentation
- [ ] Deployment steps documented
- [ ] Configuration changes recorded
- [ ] Troubleshooting steps documented
- [ ] Rollback procedures documented

### Monitoring Setup
- [ ] Log aggregation configured
- [ ] Metrics collection enabled
- [ ] Alerting configured
- [ ] Dashboard created

### Maintenance Plan
- [ ] Update procedures documented
- [ ] Backup strategy implemented
- [ ] Scaling procedures documented
- [ ] Security updates planned

---

**Remember**: Always test in a non-production environment first, and have a rollback plan ready before deploying to production.

# 🚀 GKE Deployment Guide for Job Scheduler

This guide will help you deploy your job scheduler application to Google Kubernetes Engine (GKE) and configure it to work with the Slack-KPI-Service.

## 📋 Prerequisites

### 1. **GCP Setup**
- Google Cloud Platform account with billing enabled
- GKE cluster running (can be created via GCP Console or gcloud CLI)
- Google Cloud SDK (gcloud CLI) installed and configured
- kubectl CLI tool installed

### 2. **Local Setup**
- Docker installed and running
- Node.js 18+ (for local development)
- Access to your GKE cluster

### 3. **Required Tokens**
- JWT token for authentication
- Aircall API token (if using Aircall integration)

## 🔧 Installation & Setup

### 1. **Install Prerequisites**

```bash
# Install Google Cloud SDK
curl https://sdk.cloud.google.com | bash
exec -l $SHELL

# Install kubectl
gcloud components install kubectl

# Verify installations
gcloud --version
kubectl version --client
```

### 2. **Configure GCP**

```bash
# Login to GCP
gcloud auth login

# Set your project ID
gcloud config set project YOUR_PROJECT_ID

# Configure Docker for GCR
gcloud auth configure-docker

# Get GKE cluster credentials
gcloud container clusters get-credentials CLUSTER_NAME --zone=ZONE --project=YOUR_PROJECT_ID
```

### 3. **Prepare Environment**

```bash
# Copy environment template
cp env.example .env

# Edit .env with your actual tokens
nano .env
```

Example `.env` file:
```bash
JWT_TOKEN=your_actual_jwt_token_here
AIRCALL_API_TOKEN=your_actual_aircall_token_here
NODE_ENV=production
LOG_LEVEL=info
TZ=America/Chicago
```

## 🚀 Deployment

### Option 1: Automated Deployment (Recommended)

```bash
# Make the deployment script executable
chmod +x deploy-to-gke.sh

# Deploy to GKE
./deploy-to-gke.sh deploy
```

### Option 2: Manual Deployment

```bash
# 1. Build and push Docker image
docker build -t gcr.io/YOUR_PROJECT_ID/job-scheduler:latest .
docker push gcr.io/YOUR_PROJECT_ID/job-scheduler:latest

# 2. Update Kubernetes manifests with your project ID
sed -i 's/YOUR_PROJECT_ID/YOUR_ACTUAL_PROJECT_ID/g' k8s/deployment.yaml

# 3. Update secrets with your actual tokens
# First, encode your tokens:
echo -n "your_jwt_token" | base64
echo -n "your_aircall_token" | base64

# Then update k8s/secret.yaml with the base64 encoded values

# 4. Deploy to Kubernetes
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/secret.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
```

## 🔍 Verification & Testing

### 1. **Check Deployment Status**

```bash
# Check pod status
kubectl get pods -n scheduler-app

# Check service
kubectl get svc -n scheduler-app

# Check deployment
kubectl get deployment -n scheduler-app
```

### 2. **Test Health Endpoints**

```bash
# Test health check
kubectl exec -n scheduler-app deployment/job-scheduler -- curl -s http://localhost:8081/health

# Check scheduler status
kubectl exec -n scheduler-app deployment/job-scheduler -- curl -s http://localhost:8081/status
```

### 3. **View Logs**

```bash
# View live logs
kubectl logs -f -n scheduler-app deployment/job-scheduler

# View recent logs
kubectl logs --tail=50 -n scheduler-app deployment/job-scheduler
```

### 4. **Test KPI Service Connectivity**

```bash
# Access pod shell
kubectl exec -it -n scheduler-app deployment/job-scheduler -- /bin/sh

# Test connection to Slack-KPI-Service
curl -v http://slack-kpi-service.slack-kpi-service.svc.cluster.local:6000/health
```

## 🌐 Network Configuration

### 1. **Service Discovery**

The scheduler app is configured to communicate with the Slack-KPI-Service using Kubernetes service discovery:

```yaml
# From k8s/configmap.yaml
url: "http://slack-kpi-service.slack-kpi-service.svc.cluster.local:6000/report/afternoon"
```

### 2. **Network Policies**

If you have network policies enabled, ensure the scheduler app can reach the Slack-KPI-Service:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-scheduler-to-kpi
  namespace: scheduler-app
spec:
  podSelector:
    matchLabels:
      app: job-scheduler
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: slack-kpi-service
    ports:
    - protocol: TCP
      port: 6000
```

## 📊 Monitoring & Logging

### 1. **Application Logs**

```bash
# View logs in real-time
kubectl logs -f -n scheduler-app deployment/job-scheduler

# Filter logs by job name
kubectl logs -n scheduler-app deployment/job-scheduler | grep "kpi-afternoon-report"
```

### 2. **Job Execution Monitoring**

The scheduler provides status endpoints for monitoring:

```bash
# Get overall scheduler status
curl http://job-scheduler-service.scheduler-app.svc.cluster.local:8081/status

# Check specific job logs
kubectl logs -n scheduler-app deployment/job-scheduler | grep "Starting job"
```

### 3. **Resource Monitoring**

```bash
# Check resource usage
kubectl top pods -n scheduler-app

# Check resource limits
kubectl describe pod -n scheduler-app -l app=job-scheduler
```

## 🔧 Troubleshooting

### Common Issues

#### 1. **Pod Not Starting**

```bash
# Check pod events
kubectl describe pod -n scheduler-app -l app=job-scheduler

# Check pod logs
kubectl logs -n scheduler-app deployment/job-scheduler --previous
```

#### 2. **Jobs Not Executing**

```bash
# Check if YAML config is loaded
kubectl logs -n scheduler-app deployment/job-scheduler | grep "Loaded.*jobs from YAML"

# Verify configmap
kubectl get configmap scheduler-config -n scheduler-app -o yaml
```

#### 3. **Cannot Connect to KPI Service**

```bash
# Check if KPI service is running
kubectl get pods -n slack-kpi-service

# Test network connectivity
kubectl exec -n scheduler-app deployment/job-scheduler -- nslookup slack-kpi-service.slack-kpi-service.svc.cluster.local

# Test direct connection
kubectl exec -n scheduler-app deployment/job-scheduler -- curl -v http://slack-kpi-service.slack-kpi-service.svc.cluster.local:6000/health
```

#### 4. **Authentication Errors**

```bash
# Check if secrets are properly mounted
kubectl exec -n scheduler-app deployment/job-scheduler -- env | grep JWT_TOKEN

# Verify secret values
kubectl get secret scheduler-secrets -n scheduler-app -o yaml
```

## 🔄 Updates & Maintenance

### 1. **Update Application**

```bash
# Build new image
docker build -t gcr.io/YOUR_PROJECT_ID/job-scheduler:v2 .

# Push to GCR
docker push gcr.io/YOUR_PROJECT_ID/job-scheduler:v2

# Update deployment
kubectl set image deployment/job-scheduler job-scheduler=gcr.io/YOUR_PROJECT_ID/job-scheduler:v2 -n scheduler-app
```

### 2. **Update Configuration**

```bash
# Update configmap
kubectl apply -f k8s/configmap.yaml

# Restart deployment to pick up new config
kubectl rollout restart deployment/job-scheduler -n scheduler-app
```

### 3. **Scale Application**

```bash
# Scale to multiple replicas
kubectl scale deployment job-scheduler --replicas=3 -n scheduler-app

# Check scaling status
kubectl get pods -n scheduler-app
```

## 🗑️ Cleanup

### 1. **Remove Application**

```bash
# Delete entire namespace (removes all resources)
kubectl delete namespace scheduler-app

# Or delete individual resources
kubectl delete -f k8s/
```

### 2. **Remove Docker Images**

```bash
# Remove local images
docker rmi gcr.io/YOUR_PROJECT_ID/job-scheduler:latest

# Remove from GCR (optional)
gcloud container images delete gcr.io/YOUR_PROJECT_ID/job-scheduler:latest --force-delete-tags
```

## 📚 Additional Resources

### 1. **GKE Documentation**
- [GKE Quickstart](https://cloud.google.com/kubernetes-engine/docs/quickstart)
- [GKE Best Practices](https://cloud.google.com/kubernetes-engine/docs/best-practices)

### 2. **Kubernetes Documentation**
- [Kubernetes Concepts](https://kubernetes.io/docs/concepts/)
- [Kubernetes API Reference](https://kubernetes.io/docs/reference/)

### 3. **Troubleshooting**
- [GKE Troubleshooting](https://cloud.google.com/kubernetes-engine/docs/troubleshooting)
- [Kubernetes Debugging](https://kubernetes.io/docs/tasks/debug-application-cluster/)

## 🆘 Support

If you encounter issues:

1. **Check the logs**: `kubectl logs -n scheduler-app deployment/job-scheduler`
2. **Verify configuration**: Check all Kubernetes manifests and environment variables
3. **Test connectivity**: Ensure network policies allow communication between services
4. **Check GKE status**: Verify cluster health in GCP Console

## 🎯 Next Steps

After successful deployment:

1. **Monitor job execution** to ensure KPI reports are being generated
2. **Set up alerting** for job failures or service unavailability
3. **Configure log aggregation** for better observability
4. **Set up CI/CD pipeline** for automated deployments
5. **Implement backup strategies** for job configurations and logs

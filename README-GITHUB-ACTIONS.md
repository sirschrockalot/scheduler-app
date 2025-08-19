# 🚀 GitHub Actions Quick Start

This repository is now configured with GitHub Actions to automatically deploy your job scheduler to GKE!

## ⚡ Quick Setup

### 1. **Set up GCP Service Account**
```bash
# Run the setup script
./setup-gcp-service-account.sh

# This will:
# - Create a service account with necessary permissions
# - Generate the base64 encoded key
# - Create a template for GitHub secrets
```

### 2. **Add GitHub Secrets**
Go to your repository → **Settings** → **Secrets and variables** → **Actions**

Add these secrets:
- `GCP_PROJECT_ID` - Your GCP project ID
- `GKE_CLUSTER_NAME` - Your GKE cluster name  
- `GKE_ZONE` - Your GKE cluster zone
- `GCP_SA_KEY` - Base64 encoded service account key
- `JWT_TOKEN` - Your JWT authentication token
- `AIRCALL_API_TOKEN` - Your Aircall API token

### 3. **Deploy!**
- **Automatic**: Push to `main` branch → deploys to staging
- **Production**: Create a tag (e.g., `v1.0.0`) → deploys to production
- **Manual**: Go to **Actions** tab → **Manual Deploy** → **Run workflow**

## 🔄 Workflow Triggers

| Action | Environment | Trigger |
|--------|-------------|---------|
| Push to `main` | Staging | Automatic |
| Create tag `v*` | Production | Automatic |
| Pull Request | None | Tests only |
| Manual dispatch | Any | Manual selection |

## 📁 What's Included

### **GitHub Actions Workflows**
- `.github/workflows/deploy.yml` - Main deployment workflow
- `.github/workflows/pr-check.yml` - Pull request validation
- `.github/workflows/manual-deploy.yml` - Manual deployment

### **Kubernetes Manifests**
- `k8s/` - Complete K8s configuration for GKE
- Network policies for Slack-KPI-Service communication
- Health checks and monitoring endpoints

### **Setup Scripts**
- `setup-gcp-service-account.sh` - GCP service account setup
- `deploy-to-gke.sh` - Local deployment script
- `quick-start-gke.sh` - Simplified local deployment

## 🎯 What Happens on Deployment

1. **Build & Test** - Runs tests, builds TypeScript, validates K8s manifests
2. **Docker Build** - Builds and pushes Docker image to GCR
3. **Deploy to GKE** - Applies Kubernetes manifests to your cluster
4. **Verify** - Checks deployment health and connectivity
5. **Test** - Verifies Slack-KPI-Service communication

## 🔍 Monitoring

### **GitHub Actions**
- **Actions** tab: View workflow runs and deployment status
- **Environments**: Monitor staging/production deployments

### **GKE Cluster**
```bash
# Check deployment status
kubectl get pods -n scheduler-app

# View logs
kubectl logs -f -n scheduler-app deployment/job-scheduler

# Test health
kubectl exec -n scheduler-app deployment/job-scheduler -- curl -s http://localhost:8081/health
```

## 🚨 Troubleshooting

### **Common Issues**

#### **Authentication Failed**
- Verify `GCP_SA_KEY` secret is correct
- Check service account has required permissions
- Ensure GKE cluster is accessible

#### **Image Push Failed**
- Verify `GCP_PROJECT_ID` is correct
- Check Container Registry is enabled
- Ensure service account has Storage Admin role

#### **Deployment Failed**
- Check pod events: `kubectl describe pod -n scheduler-app`
- Verify K8s manifests are valid
- Check resource limits and requests

#### **KPI Service Connection Failed**
- Verify Slack-KPI-Service is running in same cluster
- Check network policies allow communication
- Test DNS resolution within the cluster

### **Debug Commands**
```bash
# Enable debug logging in workflows
env:
  ACTIONS_STEP_DEBUG: true

# Check service account permissions
gcloud projects get-iam-policy $PROJECT_ID

# Validate K8s manifests
kubectl apply --dry-run=client -f k8s/
```

## 📚 Documentation

- **`GITHUB-ACTIONS-SETUP.md`** - Complete setup guide
- **`GKE-DEPLOYMENT.md`** - GKE deployment details
- **`DEPLOYMENT-CHECKLIST.md`** - Deployment verification checklist

## 🎉 You're Ready!

Your scheduler app will now automatically deploy to GKE whenever you:
- Push to the main branch (staging)
- Create a version tag (production)
- Manually trigger deployment

The app is configured to communicate with the Slack-KPI-Service and will generate KPI reports on schedule! 🚀

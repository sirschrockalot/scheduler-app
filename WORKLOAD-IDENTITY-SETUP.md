# 🔐 Workload Identity Setup for GitHub Actions

This guide will help you set up Workload Identity to allow GitHub Actions to securely authenticate with Google Cloud Platform without using service account keys.

## 🎯 What is Workload Identity?

Workload Identity is a more secure way to authenticate GitHub Actions with GCP. Instead of storing service account keys as secrets, it uses OIDC tokens and IAM policies to grant temporary access.

## 📋 Prerequisites

- ✅ GCP project with billing enabled
- ✅ `gcloud` CLI installed and authenticated
- ✅ Owner or Editor permissions on the GCP project
- ✅ GitHub repository with Actions enabled

## 🚀 Quick Setup

### 1. Set Environment Variables

```bash
export GCP_PROJECT_ID="your-project-id"
export GITHUB_REPO="your-username/your-repo"
```

**Example:**
```bash
export GCP_PROJECT_ID="presidentialdigs-dev"
export GITHUB_REPO="sirschrockalot/scheduler-app"
```

### 2. Run the Setup Script

```bash
./setup-workload-identity.sh
```

This script will:
- Enable required GCP APIs
- Create a Workload Identity Pool
- Create a Workload Identity Provider
- Create a service account with necessary permissions
- Set up the binding between GitHub Actions and the service account

### 3. Add GitHub Secrets

After running the script, add these secrets to your GitHub repository:

| Secret Name | Value | Description |
|-------------|-------|-------------|
| `GCP_PROJECT_ID` | `your-project-id` | Your GCP project ID |
| `WORKLOAD_IDENTITY_PROVIDER` | `projects/.../...` | Full Workload Identity Provider path |
| `GKE_CLUSTER_NAME` | `your-cluster-name` | Your GKE cluster name |
| `GKE_ZONE` | `your-cluster-zone` | Your GKE cluster zone |

## 🔧 Manual Setup (Alternative)

If you prefer to run the commands manually:

### Enable Required APIs

```bash
gcloud services enable iamcredentials.googleapis.com --project="$GCP_PROJECT_ID"
gcloud services enable cloudresourcemanager.googleapis.com --project="$GCP_PROJECT_ID"
```

### Create Workload Identity Pool

```bash
gcloud iam workload-identity-pools create "github-actions" \
    --project="$GCP_PROJECT_ID" \
    --location="global" \
    --display-name="GitHub Actions Pool"
```

### Create Workload Identity Provider

```bash
gcloud iam workload-identity-pools providers create-oidc "github-actions" \
    --project="$GCP_PROJECT_ID" \
    --location="global" \
    --workload-identity-pool="github-actions" \
    --issuer-uri="https://token.actions.githubusercontent.com" \
    --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository"
```

### Create Service Account

```bash
gcloud iam service-accounts create "github-actions-scheduler" \
    --project="$GCP_PROJECT_ID" \
    --display-name="GitHub Actions Scheduler Service Account" \
    --description="Service account for GitHub Actions to deploy scheduler app"
```

### Grant Permissions

```bash
# Container Developer role for GKE access
gcloud projects add-iam-policy-binding "$GCP_PROJECT_ID" \
    --member="serviceAccount:github-actions-scheduler@$GCP_PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/container.developer"

# Storage Admin role for GCR access
gcloud projects add-iam-policy-binding "$GCP_PROJECT_ID" \
    --member="serviceAccount:github-actions-scheduler@$GCP_PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/storage.admin"

# Service Account User role for impersonation
gcloud projects add-iam-policy-binding "$GCP_PROJECT_ID" \
    --member="serviceAccount:github-actions-scheduler@$GCP_PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/iam.serviceAccountUser"
```

### Create Workload Identity Binding

```bash
gcloud iam service-accounts add-iam-policy-binding "github-actions-scheduler@$GCP_PROJECT_ID.iam.gserviceaccount.com" \
    --project="$GCP_PROJECT_ID" \
    --role="roles/iam.workloadIdentityUser" \
    --member="principalSet://iam.googleapis.com/projects/$GCP_PROJECT_ID/locations/global/workloadIdentityPools/github-actions/attribute.repository/$GITHUB_REPO"
```

## 🔍 Verify Setup

### Check Workload Identity Pool

```bash
gcloud iam workload-identity-pools list --location="global" --project="$GCP_PROJECT_ID"
```

### Check Workload Identity Provider

```bash
gcloud iam workload-identity-pools providers list \
    --workload-identity-pool="github-actions" \
    --location="global" \
    --project="$GCP_PROJECT_ID"
```

### Check Service Account

```bash
gcloud iam service-accounts list --project="$GCP_PROJECT_ID"
```

### Check IAM Bindings

```bash
gcloud projects get-iam-policy "$GCP_PROJECT_ID" \
    --flatten="bindings[].members" \
    --format="table(bindings.role)" \
    --filter="bindings.members:github-actions-scheduler@$GCP_PROJECT_ID.iam.gserviceaccount.com"
```

## 🚀 Using the Workflow

Once setup is complete, the `deploy-with-workload-identity.yml` workflow will:

1. **Test**: Run linting, tests, and TypeScript compilation
2. **Build**: Create Docker image and push to GCR
3. **Deploy**: Deploy to GKE using Workload Identity authentication

## 🔒 Security Benefits

- **No long-lived credentials** stored in GitHub secrets
- **Temporary access** granted only during workflow execution
- **Repository-scoped** access (only your specific repo can use it)
- **Audit trail** of all authentication events

## 🐛 Troubleshooting

### Common Issues

#### "Permission denied" errors
- Ensure the service account has the necessary roles
- Check that the Workload Identity binding is correct
- Verify the repository name matches exactly

#### "Workload Identity not enabled" errors
- Ensure the GKE cluster has Workload Identity enabled
- Check that the required APIs are enabled

#### "Service account not found" errors
- Verify the service account name and project ID
- Check that the service account was created successfully

### Debug Commands

```bash
# Check Workload Identity status on GKE cluster
gcloud container clusters describe "$GKE_CLUSTER" \
    --zone="$GKE_ZONE" \
    --project="$GCP_PROJECT_ID" \
    --format="value(workloadPoolConfig.workloadPool)"

# Test authentication
gcloud auth list

# Check service account permissions
gcloud projects get-iam-policy "$GCP_PROJECT_ID" \
    --flatten="bindings[].members" \
    --filter="bindings.members:github-actions-scheduler@$GCP_PROJECT_ID.iam.gserviceaccount.com"
```

## 📚 Additional Resources

- [Workload Identity Documentation](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity)
- [GitHub Actions GCP Auth](https://github.com/google-github-actions/auth)
- [IAM Best Practices](https://cloud.google.com/iam/docs/best-practices-for-managing-service-account-keys)

## 🎉 Success!

Once setup is complete, your GitHub Actions will be able to:
- ✅ Authenticate with GCP securely
- ✅ Push Docker images to GCR
- ✅ Deploy to GKE
- ✅ All without storing service account keys!

Your scheduler app will be automatically deployed on every push to main/master! 🚀

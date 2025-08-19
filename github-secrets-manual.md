# GitHub Secrets Setup Guide

Since your GCP project has constraints on service account key creation, you'll need to set up authentication manually.

## Option 1: Use Application Default Credentials (Recommended)

### 1. Create a Personal Access Token
1. Go to your GitHub repository
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Add these secrets:

| Secret Name | Value | Description |
|-------------|-------|-------------|
| `GCP_PROJECT_ID` | `presidentialdigs-dev` | Your GCP project ID |
| `GKE_CLUSTER_NAME` | `dev-cluster` | Your GKE cluster name |
| `GKE_ZONE` | `us-central1` | Your GKE cluster zone |
| `JWT_TOKEN` | `[Your JWT token]` | JWT authentication token |
| `AIRCALL_API_TOKEN` | `[Your Aircall token]` | Aircall API token |

### 2. Update GitHub Actions Workflows
The workflows need to be updated to use Application Default Credentials instead of service account keys.

## Option 2: Use Existing Service Account (Alternative)

If you have access to create service account keys in a different project or can temporarily disable the constraint:

1. Create a service account key manually in GCP Console
2. Base64 encode it: `cat key.json | base64`
3. Add as `GCP_SA_KEY` secret

## Option 3: Use Workload Identity (Advanced)

This requires setting up Workload Identity pools and bindings, which is more complex but more secure.

## Current Configuration

- **Project ID**: `presidentialdigs-dev`
- **Cluster Name**: `dev-cluster`
- **Cluster Zone**: `us-central1`
- **Service Account**: `github-actions@presidentialdigs-dev.iam.gserviceaccount.com`

## Next Steps

1. Choose an authentication method above
2. Add the required secrets to GitHub
3. Update the GitHub Actions workflows if needed
4. Test the deployment

## Troubleshooting

If you encounter issues:
- Check that all secrets are properly set
- Verify the service account has the required permissions
- Ensure the GKE cluster is accessible
- Check the GitHub Actions logs for specific error messages

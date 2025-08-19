#!/bin/bash

# Setup Workload Identity for GitHub Actions
# This allows GitHub Actions to authenticate with GCP without service account keys

set -e

echo "🔐 Setting up Workload Identity for GitHub Actions..."

# Check if required environment variables are set
if [ -z "$GCP_PROJECT_ID" ]; then
    echo "❌ Error: GCP_PROJECT_ID environment variable is required"
    echo "Please set it with: export GCP_PROJECT_ID=your-project-id"
    exit 1
fi

if [ -z "$GITHUB_REPO" ]; then
    echo "❌ Error: GITHUB_REPO environment variable is required"
    echo "Please set it with: export GITHUB_REPO=your-username/your-repo"
    echo "Example: export GITHUB_REPO=sirschrockalot/scheduler-app"
    exit 1
fi

echo "📋 Configuration:"
echo "  Project ID: $GCP_PROJECT_ID"
echo "  GitHub Repo: $GITHUB_REPO"
echo ""

# Enable required APIs
echo "🔧 Enabling required GCP APIs..."
gcloud services enable iamcredentials.googleapis.com --project="$GCP_PROJECT_ID"
gcloud services enable cloudresourcemanager.googleapis.com --project="$GCP_PROJECT_ID"

# Create Workload Identity Pool
echo "🏊 Creating Workload Identity Pool..."
gcloud iam workload-identity-pools create "github-actions" \
    --project="$GCP_PROJECT_ID" \
    --location="global" \
    --display-name="GitHub Actions Pool"

# Create Workload Identity Provider
echo "🔑 Creating Workload Identity Provider..."
gcloud iam workload-identity-pools providers create-oidc "github-actions" \
    --project="$GCP_PROJECT_ID" \
    --location="global" \
    --workload-identity-pool="github-actions" \
    --issuer-uri="https://token.actions.githubusercontent.com" \
    --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository"

# Create Service Account
echo "👤 Creating Service Account..."
gcloud iam service-accounts create "github-actions-scheduler" \
    --project="$GCP_PROJECT_ID" \
    --display-name="GitHub Actions Scheduler Service Account" \
    --description="Service account for GitHub Actions to deploy scheduler app"

# Grant necessary roles to the service account
echo "🔐 Granting necessary roles..."
gcloud projects add-iam-policy-binding "$GCP_PROJECT_ID" \
    --member="serviceAccount:github-actions-scheduler@$GCP_PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/container.developer"

gcloud projects add-iam-policy-binding "$GCP_PROJECT_ID" \
    --member="serviceAccount:github-actions-scheduler@$GCP_PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/storage.admin"

gcloud projects add-iam-policy-binding "$GCP_PROJECT_ID" \
    --member="serviceAccount:github-actions-scheduler@$GCP_PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/iam.serviceAccountUser"

# Allow GitHub Actions to impersonate the service account
echo "🔗 Creating Workload Identity binding..."
gcloud iam service-accounts add-iam-policy-binding "github-actions-scheduler@$GCP_PROJECT_ID.iam.gserviceaccount.com" \
    --project="$GCP_PROJECT_ID" \
    --role="roles/iam.workloadIdentityUser" \
    --member="principalSet://iam.googleapis.com/projects/$GCP_PROJECT_ID/locations/global/workloadIdentityPools/github-actions/attribute.repository/$GITHUB_REPO"

# Get the Workload Identity Provider resource name
WORKLOAD_IDENTITY_PROVIDER=$(gcloud iam workload-identity-pools providers describe "github-actions" \
    --project="$GCP_PROJECT_ID" \
    --location="global" \
    --workload-identity-pool="github-actions" \
    --format="value(name)")

echo ""
echo "✅ Workload Identity setup complete!"
echo ""
echo "📋 Add these secrets to your GitHub repository:"
echo "   GCP_PROJECT_ID: $GCP_PROJECT_ID"
echo "   WORKLOAD_IDENTITY_PROVIDER: $WORKLOAD_IDENTITY_PROVIDER"
echo "   GKE_CLUSTER_NAME: [your-cluster-name]"
echo "   GKE_ZONE: [your-cluster-zone]"
echo ""
echo "🔗 The Workload Identity Provider is:"
echo "   $WORKLOAD_IDENTITY_PROVIDER"
echo ""
echo "🚀 Your GitHub Actions can now authenticate with GCP using Workload Identity!"

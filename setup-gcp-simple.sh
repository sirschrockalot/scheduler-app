#!/bin/bash

# 🔧 Simplified GCP Setup for GitHub Actions
# This script provides the information you need to set up GitHub Actions manually

set -e

echo "🔧 Simplified GCP Setup for GitHub Actions"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if gcloud is installed
check_gcloud() {
    if ! command -v gcloud &> /dev/null; then
        print_error "gcloud CLI is not installed. Please install it first."
        echo "Installation guide: https://cloud.google.com/sdk/docs/install"
        exit 1
    fi
    print_success "gcloud CLI is installed"
}

# Check if user is authenticated
check_auth() {
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
        print_error "You are not authenticated with gcloud. Please run:"
        echo "gcloud auth login"
        exit 1
    fi
    
    ACTIVE_ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)")
    print_success "Authenticated as: $ACTIVE_ACCOUNT"
}

# Get project configuration
get_project_config() {
    print_status "Getting project configuration..."
    
    PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
    if [ -z "$PROJECT_ID" ]; then
        print_error "No GCP project configured. Please run:"
        echo "gcloud config set project YOUR_PROJECT_ID"
        exit 1
    fi
    
    print_success "Using GCP project: $PROJECT_ID"
    
    # Get GKE cluster information
    CLUSTER_NAME=$(gcloud container clusters list --format="value(name)" --limit=1 2>/dev/null)
    if [ -z "$CLUSTER_NAME" ]; then
        print_warning "No GKE clusters found in project $PROJECT_ID"
        read -p "Enter your GKE cluster name: " CLUSTER_NAME
    else
        print_success "Found GKE cluster: $CLUSTER_NAME"
    fi
    
    ZONE=$(gcloud container clusters list --format="value(location)" --limit=1 2>/dev/null)
    if [ -z "$ZONE" ]; then
        print_warning "Could not determine GKE cluster zone"
        read -p "Enter your GKE cluster zone (e.g., us-central1-a): " ZONE
    else
        print_success "GKE cluster zone: $ZONE"
    fi
}

# Check service account status
check_service_account() {
    print_status "Checking service account status..."
    
    SA_NAME="github-actions"
    SA_EMAIL="$SA_NAME@$PROJECT_ID.iam.gserviceaccount.com"
    
    if gcloud iam service-accounts describe "$SA_EMAIL" &>/dev/null; then
        print_success "Service account exists: $SA_EMAIL"
        
        # Check IAM roles
        print_status "Checking IAM roles..."
        ROLES=$(gcloud projects get-iam-policy "$PROJECT_ID" \
            --flatten="bindings[].members" \
            --filter="bindings.members:$SA_EMAIL" \
            --format="value(bindings.role)")
        
        echo "Current roles:"
        echo "$ROLES" | while read -r role; do
            echo "  - $role"
        done
        
    else
        print_error "Service account $SA_EMAIL does not exist"
        echo "Please run the full setup script first:"
        echo "./setup-gcp-service-account.sh"
        exit 1
    fi
}

# Generate GitHub secrets template
generate_secrets_template() {
    print_status "Generating GitHub secrets template..."
    
    cat > github-secrets-manual.md << EOF
# GitHub Secrets Setup Guide

Since your GCP project has constraints on service account key creation, you'll need to set up authentication manually.

## Option 1: Use Application Default Credentials (Recommended)

### 1. Create a Personal Access Token
1. Go to your GitHub repository
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Add these secrets:

| Secret Name | Value | Description |
|-------------|-------|-------------|
| \`GCP_PROJECT_ID\` | \`$PROJECT_ID\` | Your GCP project ID |
| \`GKE_CLUSTER_NAME\` | \`$CLUSTER_NAME\` | Your GKE cluster name |
| \`GKE_ZONE\` | \`$ZONE\` | Your GKE cluster zone |
| \`JWT_TOKEN\` | \`[Your JWT token]\` | JWT authentication token |
| \`AIRCALL_API_TOKEN\` | \`[Your Aircall token]\` | Aircall API token |

### 2. Update GitHub Actions Workflows
The workflows need to be updated to use Application Default Credentials instead of service account keys.

## Option 2: Use Existing Service Account (Alternative)

If you have access to create service account keys in a different project or can temporarily disable the constraint:

1. Create a service account key manually in GCP Console
2. Base64 encode it: \`cat key.json | base64\`
3. Add as \`GCP_SA_KEY\` secret

## Option 3: Use Workload Identity (Advanced)

This requires setting up Workload Identity pools and bindings, which is more complex but more secure.

## Current Configuration

- **Project ID**: \`$PROJECT_ID\`
- **Cluster Name**: \`$CLUSTER_NAME\`
- **Cluster Zone**: \`$ZONE\`
- **Service Account**: \`github-actions@$PROJECT_ID.iam.gserviceaccount.com\`

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
EOF

    print_success "GitHub secrets template created: github-secrets-manual.md"
}

# Show current status
show_status() {
    echo ""
    echo "📊 Current Setup Status:"
    echo "========================"
    echo "✅ GCP Project: $PROJECT_ID"
    echo "✅ GKE Cluster: $CLUSTER_NAME"
    echo "✅ GKE Zone: $ZONE"
    echo "✅ Service Account: github-actions@$PROJECT_ID.iam.gserviceaccount.com"
    echo "✅ IAM Roles: Container Developer, Storage Admin, Service Account User"
    echo ""
    echo "⚠️  Constraint: Service account key creation is disabled"
    echo "💡 Solution: Use Application Default Credentials or manual key creation"
}

# Main execution
main() {
    check_gcloud
    check_auth
    get_project_config
    check_service_account
    generate_secrets_template
    show_status
    
    echo ""
    echo "🎯 Next Steps:"
    echo "1. Review github-secrets-manual.md for setup instructions"
    echo "2. Choose an authentication method"
    echo "3. Add the required secrets to GitHub"
    echo "4. Update GitHub Actions workflows if needed"
    echo "5. Test the deployment"
    echo ""
    echo "📚 For more information, see GITHUB-ACTIONS-SETUP.md"
}

# Handle command line arguments
case "${1:-status}" in
    "status")
        main
        ;;
    "info")
        get_project_config
        check_service_account
        show_status
        ;;
    *)
        echo "Usage: $0 {status|info}"
        echo "  status  - Show current setup status (default)"
        echo "  info    - Show configuration information"
        exit 1
        ;;
esac

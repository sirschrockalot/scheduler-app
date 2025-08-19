#!/bin/bash

# 🔧 GCP Service Account Setup for GitHub Actions (Workload Identity)
# This script sets up Workload Identity for GitHub Actions to deploy to GKE
# This approach is more secure and bypasses service account key constraints

set -e

echo "🔧 GCP Service Account Setup for GitHub Actions (Workload Identity)"
echo "=================================================================="

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

# Create service account
create_service_account() {
    print_status "Creating service account..."
    
    SA_NAME="github-actions"
    SA_EMAIL="$SA_NAME@$PROJECT_ID.iam.gserviceaccount.com"
    
    # Check if service account already exists
    if gcloud iam service-accounts describe "$SA_EMAIL" &>/dev/null; then
        print_warning "Service account $SA_EMAIL already exists"
        read -p "Do you want to recreate it? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_status "Deleting existing service account..."
            gcloud iam service-accounts delete "$SA_EMAIL" --quiet
        else
            print_status "Using existing service account"
            return
        fi
    fi
    
    # Create service account
    gcloud iam service-accounts create "$SA_NAME" \
        --display-name="GitHub Actions Service Account" \
        --description="Service account for GitHub Actions to deploy to GKE"
    
    print_success "Service account created: $SA_EMAIL"
}

# Assign IAM roles
assign_roles() {
    print_status "Assigning IAM roles..."
    
    SA_EMAIL="$SA_NAME@$PROJECT_ID.iam.gserviceaccount.com"
    
    # Container Developer role (for GKE access)
    print_status "Assigning Container Developer role..."
    gcloud projects add-iam-policy-binding "$PROJECT_ID" \
        --member="serviceAccount:$SA_EMAIL" \
        --role="roles/container.developer"
    
    # Storage Admin role (for GCR access)
    print_status "Assigning Storage Admin role..."
    gcloud projects add-iam-policy-binding "$PROJECT_ID" \
        --member="serviceAccount:$SA_EMAIL" \
        --role="roles/storage.admin"
    
    # Service Account User role (for impersonation)
    print_status "Assigning Service Account User role..."
    gcloud projects add-iam-policy-binding "$PROJECT_ID" \
        --member="serviceAccount:$SA_EMAIL" \
        --role="roles/iam.serviceAccountUser"
    
    print_success "IAM roles assigned successfully"
}

# Enable Workload Identity
enable_workload_identity() {
    print_status "Enabling Workload Identity on GKE cluster..."
    
    # Check if Workload Identity is already enabled
    if gcloud container clusters describe "$CLUSTER_NAME" --zone="$ZONE" --format="value(workloadPool)" | grep -q "$PROJECT_ID.svc.id.goog"; then
        print_success "Workload Identity is already enabled"
    else
        print_status "Enabling Workload Identity..."
        gcloud container clusters update "$CLUSTER_NAME" \
            --zone="$ZONE" \
            --workload-pool="$PROJECT_ID.svc.id.goog"
        print_success "Workload Identity enabled"
    fi
}

# Create Workload Identity binding
create_workload_identity_binding() {
    print_status "Creating Workload Identity binding..."
    
    # Get your GitHub repository information
    echo ""
    echo "📝 Please provide your GitHub repository information:"
    read -p "GitHub username/organization: " GITHUB_USER
    read -p "GitHub repository name: " GITHUB_REPO
    
    # Create Workload Identity binding
    gcloud iam service-accounts add-iam-policy-binding \
        "$SA_NAME@$PROJECT_ID.iam.gserviceaccount.com" \
        --role="roles/iam.workloadIdentityUser" \
        --member="principalSet://iam.googleapis.com/projects/$PROJECT_ID/locations/global/workloadIdentityPools/github-actions/subject/repo:$GITHUB_USER/$GITHUB_REPO"
    
    print_success "Workload Identity binding created"
}

# Generate GitHub secrets template
generate_secrets_template() {
    print_status "Generating GitHub secrets template..."
    
    cat > github-secrets-workload-identity.md << EOF
# GitHub Secrets Template (Workload Identity)

Add these secrets to your GitHub repository:

## Required Secrets

### GCP Configuration
- \`GCP_PROJECT_ID\`: \`$PROJECT_ID\`
- \`GKE_CLUSTER_NAME\`: \`$CLUSTER_NAME\`
- \`GKE_ZONE\`: \`$ZONE\`
- \`GCP_WORKLOAD_IDENTITY_PROVIDER\`: \`projects/$PROJECT_ID/locations/global/workloadIdentityPools/github-actions/providers/github-actions\`

### Application Secrets
- \`JWT_TOKEN\`: \`[Your JWT token]\`
- \`AIRCALL_API_TOKEN\`: \`[Your Aircall API token]\`

## How to Add Secrets

1. Go to your GitHub repository
2. Click **Settings** tab
3. Click **Secrets and variables** → **Actions**
4. Click **New repository secret**
5. Add each secret with the name and value above

## Service Account Details

- **Service Account**: \`$SA_NAME@$PROJECT_ID.iam.gserviceaccount.com\`
- **Project**: \`$PROJECT_ID\`
- **Cluster**: \`$CLUSTER_NAME\`
- **Zone**: \`$ZONE\`
- **Workload Identity**: Enabled

## Important Notes

⚠️ **No service account keys needed!** This setup uses Workload Identity, which is more secure.
⚠️ **Make sure your GitHub repository is:** \`$GITHUB_USER/$GITHUB_REPO\`
EOF

    print_success "GitHub secrets template created: github-secrets-workload-identity.md"
}

# Update GitHub Actions workflow for Workload Identity
update_workflow_for_workload_identity() {
    print_status "Updating GitHub Actions workflow for Workload Identity..."
    
    # Create a backup of the original workflow
    cp .github/workflows/deploy.yml .github/workflows/deploy.yml.backup
    
    # Update the workflow to use Workload Identity
    sed -i.bak 's/credentials_json: \${{ secrets.GCP_SA_KEY }}/workload_identity_provider: \${{ secrets.GCP_WORKLOAD_IDENTITY_PROVIDER }}\n        service_account: github-actions@${{ env.PROJECT_ID }}.iam.gserviceaccount.com/g' .github/workflows/deploy.yml
    
    # Update the manual deploy workflow as well
    cp .github/workflows/manual-deploy.yml .github/workflows/manual-deploy.yml.backup
    sed -i.bak 's/credentials_json: \${{ secrets.GCP_SA_KEY }}/workload_identity_provider: \${{ secrets.GCP_WORKLOAD_IDENTITY_PROVIDER }}\n        service_account: github-actions@${{ env.PROJECT_ID }}.iam.gserviceaccount.com/g' .github/workflows/manual-deploy.yml
    
    print_success "GitHub Actions workflows updated for Workload Identity"
}

# Main execution
main() {
    check_gcloud
    check_auth
    get_project_config
    create_service_account
    assign_roles
    enable_workload_identity
    create_workload_identity_binding
    generate_secrets_template
    update_workflow_for_workload_identity
    
    echo ""
    echo "🎉 GCP Service Account setup completed with Workload Identity!"
    echo ""
    echo "📋 Next steps:"
    echo "1. Add the required secrets to your GitHub repository (see github-secrets-workload-identity.md)"
    echo "2. The GitHub Actions workflows have been updated to use Workload Identity"
    echo "3. Test the GitHub Actions workflow"
    echo ""
    echo "🔐 Security Benefits:"
    echo "- No service account keys stored in GitHub"
    echo "- Automatic token rotation"
    echo "- Principle of least privilege"
    echo ""
    echo "📚 For more information, see GITHUB-ACTIONS-SETUP.md"
}

# Handle command line arguments
case "${1:-setup}" in
    "setup")
        main
        ;;
    "info")
        get_project_config
        echo ""
        echo "📊 Current Configuration:"
        echo "Project ID: $PROJECT_ID"
        echo "Cluster Name: $CLUSTER_NAME"
        echo "Zone: $ZONE"
        ;;
    *)
        echo "Usage: $0 {setup|info}"
        echo "  setup   - Set up GCP service account with Workload Identity (default)"
        echo "  info    - Show current configuration"
        exit 1
        ;;
esac

#!/bin/bash

# 🔧 GCP Service Account Setup for GitHub Actions
# This script helps you create and configure the service account needed for GitHub Actions

set -e

echo "🔧 GCP Service Account Setup for GitHub Actions"
echo "==============================================="

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

# Create and download service account key
create_key() {
    print_status "Creating service account key..."
    
    SA_EMAIL="$SA_NAME@$PROJECT_ID.iam.gserviceaccount.com"
    KEY_FILE="$HOME/github-actions-key.json"
    
    # Create key
    gcloud iam service-accounts keys create "$KEY_FILE" \
        --iam-account="$SA_EMAIL"
    
    print_success "Service account key created: $KEY_FILE"
    
    # Base64 encode the key
    print_status "Base64 encoding the key for GitHub..."
    KEY_B64=$(cat "$KEY_FILE" | base64)
    
    print_success "Base64 encoded key created"
    echo ""
    echo "🔑 Add this to your GitHub repository secrets as 'GCP_SA_KEY':"
    echo ""
    echo "$KEY_B64"
    echo ""
}

# Generate GitHub secrets template
generate_secrets_template() {
    print_status "Generating GitHub secrets template..."
    
    cat > github-secrets-template.md << EOF
# GitHub Secrets Template

Add these secrets to your GitHub repository:

## Required Secrets

### GCP Configuration
- \`GCP_PROJECT_ID\`: \`$PROJECT_ID\`
- \`GKE_CLUSTER_NAME\`: \`$CLUSTER_NAME\`
- \`GKE_ZONE\`: \`$ZONE\`
- \`GCP_SA_KEY\`: \`[Base64 encoded service account key]\`

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
- **Key File**: \`$HOME/github-actions-key.json\`
- **Project**: \`$PROJECT_ID\`
- **Cluster**: \`$CLUSTER_NAME\`
- **Zone**: \`$ZONE\`
EOF

    print_success "GitHub secrets template created: github-secrets-template.md"
}

# Cleanup function
cleanup() {
    print_status "Cleaning up temporary files..."
    
    # Remove the key file for security
    if [ -f "$HOME/github-actions-key.json" ]; then
        rm "$HOME/github-actions-key.json"
        print_success "Service account key file removed for security"
    fi
    
    print_warning "⚠️  IMPORTANT: The service account key has been removed from your local machine."
    print_warning "Make sure you've copied the base64 encoded key to GitHub secrets before proceeding."
}

# Main execution
main() {
    check_gcloud
    check_auth
    get_project_config
    create_service_account
    assign_roles
    create_key
    generate_secrets_template
    
    echo ""
    echo "🎉 GCP Service Account setup completed!"
    echo ""
    echo "📋 Next steps:"
    echo "1. Copy the base64 encoded key above"
    echo "2. Add it to your GitHub repository secrets as 'GCP_SA_KEY'"
    echo "3. Add other required secrets (see github-secrets-template.md)"
    echo "4. Test the GitHub Actions workflow"
    echo ""
    echo "📚 For more information, see GITHUB-ACTIONS-SETUP.md"
    
    # Ask if user wants to cleanup
    read -p "Do you want to remove the local key file for security? (Y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        cleanup
    fi
}

# Handle command line arguments
case "${1:-setup}" in
    "setup")
        main
        ;;
    "cleanup")
        cleanup
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
        echo "Usage: $0 {setup|cleanup|info}"
        echo "  setup   - Set up GCP service account (default)"
        echo "  cleanup - Remove local key files"
        echo "  info    - Show current configuration"
        exit 1
        ;;
esac

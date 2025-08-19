#!/bin/bash

# 🚀 GKE Deployment Script for Job Scheduler
# This script deploys the job scheduler to GKE and configures it to work with Slack-KPI-Service

set -e  # Exit on any error

echo "🚀 GKE Deployment for Job Scheduler"
echo "==================================="

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

# Configuration variables
PROJECT_ID=""
CLUSTER_NAME=""
ZONE=""
REGION=""
IMAGE_NAME="job-scheduler"
IMAGE_TAG="latest"

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if gcloud is installed
    if ! command -v gcloud &> /dev/null; then
        print_error "gcloud CLI is not installed. Please install it first."
        exit 1
    fi
    
    # Check if kubectl is installed
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed. Please install it first."
        exit 1
    fi
    
    # Check if docker is running
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
    
    print_success "All prerequisites are met"
}

# Function to get GCP configuration
get_gcp_config() {
    print_status "Getting GCP configuration..."
    
    # Get current project
    PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
    if [ -z "$PROJECT_ID" ]; then
        print_error "No GCP project configured. Please run: gcloud config set project YOUR_PROJECT_ID"
        exit 1
    fi
    
    print_success "Using GCP project: $PROJECT_ID"
    
    # Get cluster information
    CLUSTER_NAME=$(gcloud container clusters list --format="value(name)" --limit=1 2>/dev/null)
    if [ -z "$CLUSTER_NAME" ]; then
        print_error "No GKE clusters found in project $PROJECT_ID"
        exit 1
    fi
    
    ZONE=$(gcloud container clusters list --format="value(location)" --limit=1 2>/dev/null)
    if [[ "$ZONE" == *"-"* ]]; then
        REGION="$ZONE"
    else
        REGION=$(echo $ZONE | sed 's/\([a-z0-9-]*\)-[a-z0-9]*/\1/')
    fi
    
    print_success "Using GKE cluster: $CLUSTER_NAME in $ZONE"
}

# Function to configure docker for GCR
configure_docker() {
    print_status "Configuring Docker for GCR..."
    
    gcloud auth configure-docker
    
    print_success "Docker configured for GCR"
}

# Function to build and push Docker image
build_and_push_image() {
    print_status "Building and pushing Docker image..."
    
    # Build the image
    docker build -t gcr.io/$PROJECT_ID/$IMAGE_NAME:$IMAGE_TAG .
    
    # Push to GCR
    docker push gcr.io/$PROJECT_ID/$IMAGE_NAME:$IMAGE_TAG
    
    print_success "Image pushed to GCR: gcr.io/$PROJECT_ID/$IMAGE_NAME:$IMAGE_TAG"
}

# Function to update Kubernetes manifests
update_manifests() {
    print_status "Updating Kubernetes manifests..."
    
    # Update deployment.yaml with correct image
    sed -i.bak "s|gcr.io/YOUR_PROJECT_ID/job-scheduler:latest|gcr.io/$PROJECT_ID/$IMAGE_NAME:$IMAGE_TAG|g" k8s/deployment.yaml
    
    # Update secret.yaml with actual tokens
    if [ -f .env ]; then
        print_status "Updating secrets from .env file..."
        
        # Get JWT token from .env
        JWT_TOKEN=$(grep "^JWT_TOKEN=" .env | cut -d'=' -f2)
        if [ -n "$JWT_TOKEN" ]; then
            JWT_TOKEN_B64=$(echo -n "$JWT_TOKEN" | base64)
            sed -i.bak "s|eW91cl9qd3RfdG9rZW5faGVyZQ==|$JWT_TOKEN_B64|g" k8s/secret.yaml
        fi
        
        # Get Aircall token from .env
        AIRCALL_TOKEN=$(grep "^AIRCALL_API_TOKEN=" .env | cut -d'=' -f2)
        if [ -n "$AIRCALL_TOKEN" ]; then
            AIRCALL_TOKEN_B64=$(echo -n "$AIRCALL_TOKEN" | base64)
            sed -i.bak "s|eW91cl9haXJjYWxsX3Rva2VuX2hlcmU=|$AIRCALL_TOKEN_B64|g" k8s/secret.yaml
        fi
        
        print_success "Secrets updated from .env file"
    else
        print_warning ".env file not found. Please update k8s/secret.yaml manually with your actual tokens."
        print_warning "Run: echo -n 'your_jwt_token' | base64"
        print_warning "Then update the JWT_TOKEN value in k8s/secret.yaml"
    fi
}

# Function to get GKE credentials
get_gke_credentials() {
    print_status "Getting GKE credentials..."
    
    if [[ "$ZONE" == *"-"* ]]; then
        # Regional cluster
        gcloud container clusters get-credentials $CLUSTER_NAME --region=$REGION --project=$PROJECT_ID
    else
        # Zonal cluster
        gcloud container clusters get-credentials $CLUSTER_NAME --zone=$ZONE --project=$PROJECT_ID
    fi
    
    print_success "GKE credentials configured"
}

# Function to deploy to Kubernetes
deploy_to_k8s() {
    print_status "Deploying to Kubernetes..."
    
    # Create namespace
    kubectl apply -f k8s/namespace.yaml
    
    # Create secrets
    kubectl apply -f k8s/secret.yaml
    
    # Create configmap
    kubectl apply -f k8s/configmap.yaml
    
    # Create deployment
    kubectl apply -f k8s/deployment.yaml
    
    # Create service
    kubectl apply -f k8s/service.yaml
    
    # Wait for deployment to be ready
    print_status "Waiting for deployment to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/job-scheduler -n scheduler-app
    
    print_success "Deployment completed successfully"
}

# Function to verify deployment
verify_deployment() {
    print_status "Verifying deployment..."
    
    # Check pod status
    kubectl get pods -n scheduler-app
    
    # Check service
    kubectl get svc -n scheduler-app
    
    # Check logs
    print_status "Recent logs from job scheduler:"
    kubectl logs -n scheduler-app deployment/job-scheduler --tail=20
    
    print_success "Deployment verification completed"
}

# Function to show connection info
show_connection_info() {
    print_status "Connection Information:"
    echo ""
    echo "🌐 Internal Service URL:"
    echo "   http://job-scheduler-service.scheduler-app.svc.cluster.local:8081"
    echo ""
    echo "🔍 Health Check:"
    echo "   kubectl exec -n scheduler-app deployment/job-scheduler -- curl -s http://localhost:8081/health"
    echo ""
    echo "📊 Status Check:"
    echo "   kubectl exec -n scheduler-app deployment/job-scheduler -- curl -s http://localhost:8081/status"
    echo ""
    echo "📝 View Logs:"
    echo "   kubectl logs -f -n scheduler-app deployment/job-scheduler"
    echo ""
    echo "🔧 Access Pod Shell:"
    echo "   kubectl exec -it -n scheduler-app deployment/job-scheduler -- /bin/sh"
    echo ""
    print_success "Job scheduler is now running in GKE and configured to call Slack-KPI-Service!"
}

# Function to cleanup
cleanup() {
    print_status "Cleaning up temporary files..."
    
    # Remove backup files
    rm -f k8s/*.bak
    
    print_success "Cleanup completed"
}

# Main execution
main() {
    check_prerequisites
    get_gcp_config
    configure_docker
    build_and_push_image
    update_manifests
    get_gke_credentials
    deploy_to_k8s
    verify_deployment
    show_connection_info
    cleanup
}

# Handle command line arguments
case "${1:-deploy}" in
    "deploy")
        main
        ;;
    "verify")
        get_gcp_config
        get_gke_credentials
        verify_deployment
        ;;
    "logs")
        get_gcp_config
        get_gke_credentials
        kubectl logs -f -n scheduler-app deployment/job-scheduler
        ;;
    "shell")
        get_gcp_config
        get_gke_credentials
        kubectl exec -it -n scheduler-app deployment/job-scheduler -- /bin/sh
        ;;
    "delete")
        get_gcp_config
        get_gke_credentials
        print_status "Deleting scheduler app from GKE..."
        kubectl delete namespace scheduler-app
        print_success "Scheduler app deleted"
        ;;
    *)
        echo "Usage: $0 {deploy|verify|logs|shell|delete}"
        echo "  deploy  - Deploy the scheduler app to GKE (default)"
        echo "  verify  - Verify the deployment status"
        echo "  logs    - View live logs from the scheduler"
        echo "  shell   - Access the scheduler pod shell"
        echo "  delete  - Delete the scheduler app from GKE"
        exit 1
        ;;
esac

#!/bin/bash

# 🚀 Quick Start GKE Deployment
# This script provides a simplified way to deploy to GKE

echo "🚀 Quick Start GKE Deployment for Job Scheduler"
echo "==============================================="

# Check if .env file exists
if [ ! -f .env ]; then
    echo "❌ .env file not found!"
    echo ""
    echo "Please create a .env file with your tokens:"
    echo "cp env.example .env"
    echo "nano .env"
    echo ""
    echo "Required variables:"
    echo "- JWT_TOKEN=your_jwt_token_here"
    echo "- AIRCALL_API_TOKEN=your_aircall_token_here"
    echo ""
    exit 1
fi

# Check if gcloud is configured
if ! gcloud config get-value project &>/dev/null; then
    echo "❌ GCP project not configured!"
    echo ""
    echo "Please configure your GCP project:"
    echo "gcloud auth login"
    echo "gcloud config set project YOUR_PROJECT_ID"
    echo ""
    exit 1
fi

# Check if kubectl is configured
if ! kubectl cluster-info &>/dev/null; then
    echo "❌ kubectl not configured!"
    echo ""
    echo "Please get GKE credentials:"
    echo "gcloud container clusters get-credentials CLUSTER_NAME --zone=ZONE"
    echo ""
    exit 1
fi

echo "✅ Environment check passed!"
echo ""

# Show current configuration
echo "📋 Current Configuration:"
echo "GCP Project: $(gcloud config get-value project)"
echo "GKE Cluster: $(kubectl config current-context)"
echo ""

# Ask for confirmation
read -p "Do you want to proceed with deployment? (y/N): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Deployment cancelled"
    exit 1
fi

echo ""
echo "🚀 Starting deployment..."
echo ""

# Run the full deployment
./deploy-to-gke.sh deploy

echo ""
echo "🎉 Quick start deployment completed!"
echo ""
echo "Next steps:"
echo "1. Check deployment status: ./deploy-to-gke.sh verify"
echo "2. View logs: ./deploy-to-gke.sh logs"
echo "3. Access shell: ./deploy-to-gke.sh shell"
echo "4. Clean up: ./deploy-to-gke.sh delete"
echo ""
echo "For more information, see GKE-DEPLOYMENT.md"

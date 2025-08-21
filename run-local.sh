#!/bin/bash

# Local Development Script for Job Scheduler
# This script helps you run the scheduler app locally with Docker

set -e

echo "🚀 Starting Job Scheduler Local Development Environment"
echo "=================================================="

# Check if .env.local exists
if [ ! -f ".env.local" ]; then
    echo "❌ .env.local file not found!"
    echo "📝 Please create .env.local based on env.local.example"
    echo "   cp env.local.example .env.local"
    echo "   Then update .env.local with your actual values"
    exit 1
fi

# Check if jobs-local.yaml exists
if [ ! -f "jobs-local.yaml" ]; then
    echo "❌ jobs-local.yaml file not found!"
    echo "📝 Please ensure jobs-local.yaml exists in the current directory"
    exit 1
fi

# Load environment variables
echo "📋 Loading environment variables from .env.local"
source .env.local

# Check required environment variables
if [ -z "$JWT_TOKEN" ] || [ "$JWT_TOKEN" = "your_jwt_token_here" ]; then
    echo "❌ JWT_TOKEN not set in .env.local"
    echo "   Please update .env.local with your actual JWT token"
    exit 1
fi

echo "✅ Environment variables loaded successfully"

# Build the Docker image
echo "🔨 Building Docker image..."
docker build -t job-scheduler-local .

# Stop any existing containers
echo "🛑 Stopping any existing containers..."
docker-compose -f docker-compose.local.yml down 2>/dev/null || true

# Start the local development environment
echo "🚀 Starting local development environment..."
docker-compose -f docker-compose.local.yml up -d

# Wait for services to be ready
echo "⏳ Waiting for services to be ready..."
sleep 10

# Check service health
echo "🔍 Checking service health..."
if curl -f http://localhost:8081/health >/dev/null 2>&1; then
    echo "✅ Job Scheduler is healthy and running on http://localhost:8081"
else
    echo "⚠️  Job Scheduler health check failed, but container is running"
fi

if curl -f http://localhost:8080/health >/dev/null 2>&1; then
    echo "✅ Test API Server is healthy and running on http://localhost:8080"
else
    echo "⚠️  Test API Server health check failed, but container is running"
fi

echo ""
echo "🎉 Local development environment is ready!"
echo ""
echo "📊 Available endpoints:"
echo "   - Job Scheduler: http://localhost:8081"
echo "   - Health Check:  http://localhost:8081/health"
echo "   - Status:        http://localhost:8081/status"
echo "   - Test API:      http://localhost:8080"
echo ""
echo "📝 Useful commands:"
echo "   - View logs:     docker-compose -f docker-compose.local.yml logs -f"
echo "   - Stop services: docker-compose -f docker-compose.local.yml down"
echo "   - Restart:       docker-compose -f docker-compose.local.yml restart"
echo ""
echo "🔍 Monitor job execution in the logs above"
echo "   Jobs will run every 30 seconds to 3 minutes for testing"

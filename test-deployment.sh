#!/bin/bash

# 🧪 Job Scheduler Docker Deployment and Testing Script
# This script helps you deploy and test the job scheduler with Docker

set -e  # Exit on any error

echo "🚀 Job Scheduler Docker Deployment and Testing"
echo "=============================================="

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

# Check if Docker is running
check_docker() {
    print_status "Checking Docker installation..."
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
    print_success "Docker is running"
}

# Check if Docker Compose is available
check_docker_compose() {
    print_status "Checking Docker Compose..."
    if ! docker-compose --version > /dev/null 2>&1; then
        print_error "Docker Compose is not available. Please install Docker Compose."
        exit 1
    fi
    print_success "Docker Compose is available"
}

# Check environment variables
check_env() {
    print_status "Checking environment variables..."
    
    if [ ! -f .env ]; then
        print_warning ".env file not found. Creating from example..."
        cp env.example .env
        print_warning "Please edit .env file with your actual tokens before continuing."
        echo "Press Enter when you've updated the .env file..."
        read
    fi
    
    # Check if JWT_TOKEN is set
    if ! grep -q "JWT_TOKEN=" .env || grep -q "JWT_TOKEN=your_jwt_token_here" .env; then
        print_warning "JWT_TOKEN not set in .env file. Please update it."
    else
        print_success "JWT_TOKEN is configured"
    fi
}

# Build and start services
deploy_services() {
    print_status "Building and starting services..."
    
    # Stop any existing containers
    docker-compose down --remove-orphans
    
    # Build and start the job scheduler
    docker-compose up -d job-scheduler
    
    print_success "Job scheduler deployed successfully"
}

# Start test API server
start_test_api() {
    print_status "Starting test API server..."
    
    # Install dependencies for test API
    if [ ! -d "test-api/node_modules" ]; then
        print_status "Installing test API dependencies..."
        cd test-api
        npm install
        cd ..
    fi
    
    # Start test API server
    docker-compose --profile test up -d test-api
    
    print_success "Test API server started"
}

# Wait for services to be ready
wait_for_services() {
    print_status "Waiting for services to be ready..."
    
    # Wait for test API server
    print_status "Waiting for test API server..."
    for i in {1..30}; do
        if curl -s http://localhost:8080/health > /dev/null 2>&1; then
            print_success "Test API server is ready"
            break
        fi
        if [ $i -eq 30 ]; then
            print_error "Test API server failed to start"
            exit 1
        fi
        sleep 2
    done
    
    # Wait for job scheduler
    print_status "Waiting for job scheduler..."
    for i in {1..30}; do
        if docker-compose logs job-scheduler | grep -q "Job Scheduler started successfully"; then
            print_success "Job scheduler is ready"
            break
        fi
        if [ $i -eq 30 ]; then
            print_error "Job scheduler failed to start"
            exit 1
        fi
        sleep 2
    done
}

# Test the KPI job
test_kpi_job() {
    print_status "Testing KPI job..."
    
    # Copy test configuration
    cp jobs-test.yaml jobs.yaml
    
    # Wait a moment for the file change to be detected
    sleep 5
    
    # Check if the job is registered
    print_status "Checking if KPI job is registered..."
    if docker-compose logs job-scheduler | grep -q "kpi-afternoon-report-test"; then
        print_success "KPI job is registered"
    else
        print_warning "KPI job registration not found in logs"
    fi
    
    # Wait for job execution
    print_status "Waiting for KPI job execution (30 seconds)..."
    sleep 35
    
    # Check job execution logs
    print_status "Checking job execution logs..."
    if docker-compose logs job-scheduler | grep -q "Starting job: kpi-afternoon-report-test"; then
        print_success "KPI job is executing"
    else
        print_warning "KPI job execution not found in logs"
    fi
    
    # Check test API logs
    print_status "Checking test API logs..."
    if docker-compose logs test-api | grep -q "KPI Report generated successfully"; then
        print_success "KPI job successfully called the test API"
    else
        print_warning "KPI job API call not found in test API logs"
    fi
}

# Show logs
show_logs() {
    print_status "Recent job scheduler logs:"
    echo "----------------------------------------"
    docker-compose logs --tail=20 job-scheduler
    
    echo ""
    print_status "Recent test API logs:"
    echo "----------------------------------------"
    docker-compose logs --tail=10 test-api
}

# Cleanup
cleanup() {
    print_status "Cleaning up..."
    docker-compose down --remove-orphans
    print_success "Cleanup completed"
}

# Main execution
main() {
    case "${1:-deploy}" in
        "deploy")
            check_docker
            check_docker_compose
            check_env
            deploy_services
            print_success "Deployment completed successfully!"
            ;;
        "test")
            check_docker
            check_docker_compose
            check_env
            deploy_services
            start_test_api
            wait_for_services
            test_kpi_job
            show_logs
            print_success "Testing completed!"
            ;;
        "logs")
            show_logs
            ;;
        "cleanup")
            cleanup
            ;;
        "help")
            echo "Usage: $0 [deploy|test|logs|cleanup|help]"
            echo ""
            echo "Commands:"
            echo "  deploy  - Deploy the job scheduler only"
            echo "  test    - Deploy and test the KPI job"
            echo "  logs    - Show recent logs"
            echo "  cleanup - Stop and remove all containers"
            echo "  help    - Show this help message"
            ;;
        *)
            print_error "Unknown command: $1"
            echo "Use '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Run main function
main "$@" 
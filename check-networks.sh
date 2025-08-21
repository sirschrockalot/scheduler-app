#!/bin/bash

# Network Check Script for Local Development
# This script helps identify available Docker networks and troubleshoot connectivity

echo "🔍 Docker Network Check for Local Development"
echo "============================================="

echo ""
echo "📋 Available Docker Networks:"
echo "----------------------------"
docker network ls --format "table {{.Name}}\t{{.Driver}}\t{{.Scope}}"

echo ""
echo "🔗 Slack-KPI-Service Networks (if running):"
echo "-------------------------------------------"
docker network ls | grep -i slack || echo "No Slack-KPI-Service networks found"

echo ""
echo "🌐 Network Details for Common Slack-KPI-Service Networks:"
echo "--------------------------------------------------------"

# Check common network names
NETWORKS=(
    "slack-kpi-service_app-network"
    "slack-kpi-service_default"
    "slack-kpi-service-network"
    "slack-kpi-service"
)

for network in "${NETWORKS[@]}"; do
    if docker network ls | grep -q "$network"; then
        echo "✅ Found network: $network"
        echo "   Containers in $network:"
        docker network inspect "$network" --format "{{range .Containers}}{{.Name}} ({{.IPv4Address}}){{end}}" 2>/dev/null || echo "   No containers found or network not accessible"
    else
        echo "❌ Network not found: $network"
    fi
    echo ""
done

echo "🔧 Troubleshooting Commands:"
echo "---------------------------"
echo "1. Check if Slack-KPI-Service is running:"
echo "   docker ps | grep slack"
echo ""
echo "2. Check network connectivity from scheduler:"
echo "   docker exec job-scheduler-local ping slack-kpi-service"
echo ""
echo "3. Check if port 6000 is accessible:"
echo "   docker exec job-scheduler-local curl -f http://slack-kpi-service:6000/health"
echo ""
echo "4. List all containers in the app network:"
echo "   docker network inspect slack-kpi-service_app-network"
echo ""
echo "5. Check scheduler container network:"
echo "   docker exec job-scheduler-local ip route"

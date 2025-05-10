#!/bin/bash
# Bash script to start the release monitoring
# Works on macOS and Linux

# Navigate to the project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

echo "Starting release monitoring from $PROJECT_ROOT..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "Error: Docker is not running. Please start Docker and try again."
    exit 1
fi
echo "Docker is running."

# Check if the app monitoring stack is running
MONITORING_NETWORK=$(docker network ls --filter "name=monitoring-network" --format "{{.Name}}")
if [ -z "$MONITORING_NETWORK" ]; then
    echo "Warning: The monitoring network doesn't exist. Make sure the app monitoring stack is running."
    echo "Starting the app monitoring stack first..."
    
    # Try to start the app monitoring stack
    APP_MONITORING_PATH="$(dirname "$PROJECT_ROOT")/fastAPI-project-app"
    if [ -d "$APP_MONITORING_PATH" ]; then
        cd "$APP_MONITORING_PATH"
        docker-compose -f docker-compose.monitoring-only.yml up -d
        cd "$PROJECT_ROOT"
    else
        echo "Error: Could not find the app repository. Please start the app monitoring stack manually."
        exit 1
    fi
fi

# Start the release monitoring
echo "Starting release monitoring services..."
docker-compose -f docker-compose.monitoring.yml up -d

# Check if services are running
echo "Checking if services are running..."
status=$(docker ps --filter "name=release-monitoring" --format "{{.Status}}")
if [ -n "$status" ]; then
    echo -e "\033[0;32mRelease monitoring is running: $status\033[0m"
else
    echo -e "\033[0;33mRelease monitoring is not running\033[0m"
fi

echo "Release monitoring setup complete."
echo "You can access the monitoring dashboards at:"
echo "- Grafana: http://localhost:3001"

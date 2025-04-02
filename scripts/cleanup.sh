#!/bin/bash

# Function to cleanup environment
cleanup_environment() {
    local env=$1
    echo "Cleaning up resources in fastapi-$env namespace..."
    kubectl delete namespace fastapi-$env --ignore-not-found
    echo "Cleanup of $env environment complete!"
}

# Check if environment argument is provided
if [ -z "$1" ]; then
    echo "Usage: ./cleanup.sh [dev|prod|all]"
    exit 1
fi

# Perform cleanup based on argument
case "$1" in
    "dev")
        cleanup_environment "dev"
        ;;
    "prod")
        cleanup_environment "prod"
        ;;
    "all")
        cleanup_environment "dev"
        cleanup_environment "prod"
        ;;
    *)
        echo "Invalid environment. Use 'dev', 'prod', or 'all'"
        exit 1
        ;;
esac
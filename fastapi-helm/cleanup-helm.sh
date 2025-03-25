#!/bin/bash

# Display confirmation message
echo "This will uninstall the FastAPI Helm release and clean up all associated resources."
echo "Are you sure you want to proceed? (y/n)"
read -r confirmation

if [[ "$confirmation" != "y" && "$confirmation" != "Y" ]]; then
    echo "Operation cancelled."
    exit 0
fi

# Uninstall the Helm release
echo "Uninstalling Helm release..."
helm uninstall fastapi-release -n fastapi-helm

# Delete PVCs to ensure complete cleanup
echo "Deleting persistent volume claims..."
kubectl delete pvc -n fastapi-helm --all

# Optionally delete the namespace (uncomment if needed)
echo "Do you want to delete the fastapi-helm namespace as well? (y/n)"
read -r delete_namespace

if [[ "$delete_namespace" == "y" || "$delete_namespace" == "Y" ]]; then
    echo "Deleting namespace..."
    kubectl delete namespace fastapi-helm
    echo "Namespace deleted."
else
    echo "Namespace preserved."
fi

echo "Cleanup completed successfully."

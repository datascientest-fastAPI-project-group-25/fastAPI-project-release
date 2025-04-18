#!/bin/bash

# Test script to verify the sed commands for updating Helm values
# This script simulates the behavior of the update-helm.yaml workflow

set -e

# Create temporary files for testing
mkdir -p test_tmp
cp config/helm/values-stg.yaml test_tmp/values-stg-test.yaml
cp config/helm/values-prod.yaml test_tmp/values-prod-test.yaml

# Function to extract tag value using grep and sed
extract_tag() {
  local file=$1
  local component=$2
  grep -A 1 "^$component:" "$file" | grep "tag:" | sed 's/.*tag: \(.*\)$/\1/'
}

# Test staging environment
echo "Testing staging environment..."
CURRENT_BACKEND_TAG=$(extract_tag test_tmp/values-stg-test.yaml "backend")
CURRENT_FRONTEND_TAG=$(extract_tag test_tmp/values-stg-test.yaml "frontend")
DEPLOY_TAG="stg-abcdef1"

echo "Current backend tag: $CURRENT_BACKEND_TAG"
echo "Current frontend tag: $CURRENT_FRONTEND_TAG"
echo "New deploy tag: $DEPLOY_TAG"

# Update tags using sed
echo "Updating backend tag: $CURRENT_BACKEND_TAG -> $DEPLOY_TAG"
sed -i "s/tag: $CURRENT_BACKEND_TAG/tag: $DEPLOY_TAG/" test_tmp/values-stg-test.yaml

echo "Updating frontend tag: $CURRENT_FRONTEND_TAG -> $DEPLOY_TAG"
sed -i "s/tag: $CURRENT_FRONTEND_TAG/tag: $DEPLOY_TAG/" test_tmp/values-stg-test.yaml

# Verify the changes
NEW_BACKEND_TAG=$(extract_tag test_tmp/values-stg-test.yaml "backend")
NEW_FRONTEND_TAG=$(extract_tag test_tmp/values-stg-test.yaml "frontend")

echo "New backend tag: $NEW_BACKEND_TAG"
echo "New frontend tag: $NEW_FRONTEND_TAG"

if [[ "$NEW_BACKEND_TAG" == "$DEPLOY_TAG" && "$NEW_FRONTEND_TAG" == "$DEPLOY_TAG" ]]; then
  echo "✅ Staging test passed!"
else
  echo "❌ Staging test failed!"
  exit 1
fi

# Test production environment
echo -e "\nTesting production environment..."
CURRENT_BACKEND_TAG=$(extract_tag test_tmp/values-prod-test.yaml "backend")
CURRENT_FRONTEND_TAG=$(extract_tag test_tmp/values-prod-test.yaml "frontend")
DEPLOY_TAG="1.2.3"

echo "Current backend tag: $CURRENT_BACKEND_TAG"
echo "Current frontend tag: $CURRENT_FRONTEND_TAG"
echo "New deploy tag: $DEPLOY_TAG"

# Update tags using sed
echo "Updating backend tag: $CURRENT_BACKEND_TAG -> $DEPLOY_TAG"
sed -i "s/tag: $CURRENT_BACKEND_TAG/tag: $DEPLOY_TAG/" test_tmp/values-prod-test.yaml

echo "Updating frontend tag: $CURRENT_FRONTEND_TAG -> $DEPLOY_TAG"
sed -i "s/tag: $CURRENT_FRONTEND_TAG/tag: $DEPLOY_TAG/" test_tmp/values-prod-test.yaml

# Verify the changes
NEW_BACKEND_TAG=$(extract_tag test_tmp/values-prod-test.yaml "backend")
NEW_FRONTEND_TAG=$(extract_tag test_tmp/values-prod-test.yaml "frontend")

echo "New backend tag: $NEW_BACKEND_TAG"
echo "New frontend tag: $NEW_FRONTEND_TAG"

if [[ "$NEW_BACKEND_TAG" == "$DEPLOY_TAG" && "$NEW_FRONTEND_TAG" == "$DEPLOY_TAG" ]]; then
  echo "✅ Production test passed!"
else
  echo "❌ Production test failed!"
  exit 1
fi

# Clean up
rm -rf test_tmp

echo -e "\n✅ All tests passed! The sed commands are working correctly."

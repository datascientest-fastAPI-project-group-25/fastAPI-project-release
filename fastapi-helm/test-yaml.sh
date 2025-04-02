#!/bin/bash

# Test YAML syntax for all templates
echo "Testing YAML syntax for all templates..."

# Use helm template to render the templates and check for syntax errors
helm template ./fastapi-helm -f ./fastapi-helm/values-dev.yaml > /dev/null

if [ $? -eq 0 ]; then
  echo "✅ YAML syntax is valid for development environment"
else
  echo "❌ YAML syntax errors found in development environment"
  exit 1
fi

helm template ./fastapi-helm -f ./fastapi-helm/values-release.yaml > /dev/null

if [ $? -eq 0 ]; then
  echo "✅ YAML syntax is valid for release environment"
else
  echo "❌ YAML syntax errors found in release environment"
  exit 1
fi

helm template ./fastapi-helm -f ./fastapi-helm/values-prod.yaml > /dev/null

if [ $? -eq 0 ]; then
  echo "✅ YAML syntax is valid for production environment"
else
  echo "❌ YAML syntax errors found in production environment"
  exit 1
fi

echo "All YAML syntax tests passed!"

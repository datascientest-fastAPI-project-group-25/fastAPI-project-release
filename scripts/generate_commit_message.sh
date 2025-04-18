#!/bin/bash

# generate_commit_message.sh
# Generates a commit message based on environment variables.

set -e # Exit on error

# Input validation (optional but recommended)
if [[ -z "$ENV" || -z "$DEPLOY_TAG" || -z "$RAW_VERSION" || -z "$OLD_BACKEND_TAG" || -z "$OLD_FRONTEND_TAG" ]]; then
  echo "::error::Missing required environment variables for commit message generation." >&2
  exit 1
fi

# Generate commit message title
echo "chore(helm): update image tags for ${ENV} to ${DEPLOY_TAG}"
echo "" # Blank line

# Generate commit message body
echo "Updates image tags in Helm values for the **${ENV}** environment based on release **${RAW_VERSION}**."
echo ""
echo "**Changes:**"
echo "- **Environment:** ${ENV}"
echo "- **Target Tag:** ${DEPLOY_TAG}"
echo "- **Previous Backend Tag:** ${OLD_BACKEND_TAG}"
echo "- **Previous Frontend Tag:** ${OLD_FRONTEND_TAG}"

# Add Chart.yaml version info for prod commits
if [[ "$ENV" == "prod" ]]; then
  # Ensure semantic version is clean for the commit message
  if [[ "$SEMANTIC_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "- **Chart Version:** ${SEMANTIC_VERSION}"
  fi
fi
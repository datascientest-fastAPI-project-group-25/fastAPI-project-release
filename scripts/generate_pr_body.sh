#!/bin/bash

# generate_pr_body.sh
# Generates the PR body content and writes it to pr_body.md

set -e # Exit on error

# Input validation (optional but recommended)
if [[ -z "$ENV" || -z "$RAW_VERSION" || -z "$DEPLOY_TAG" || -z "$OLD_BACKEND_TAG" || -z "$OLD_FRONTEND_TAG" || -z "$GITHUB_REPOSITORY" || -z "$GITHUB_RUN_ID" ]]; then
  echo "::error::Missing required environment variables for PR body generation." >&2
  exit 1
fi

# Start writing to pr_body.md
cat > pr_body.md << EOF
Automated update of Helm values for the **${ENV}** environment triggered by release **${RAW_VERSION}**.

**Changes:**
- **Target Tag:** \`${DEPLOY_TAG}\`
- **Previous Backend Tag:** \`${OLD_BACKEND_TAG}\`
- **Previous Frontend Tag:** \`${OLD_FRONTEND_TAG}\`
EOF

# Add Chart.yaml version info for prod PRs
if [[ "$ENV" == "prod" ]]; then
  # Ensure semantic version is clean for the PR body
  if [[ "$SEMANTIC_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "" >> pr_body.md # Add newline
    echo "- **Chart Version:** \`${SEMANTIC_VERSION}\`" >> pr_body.md
  fi
fi

# Add workflow run link
echo "" >> pr_body.md # Add newline
echo "**Workflow Run:** [View Run](https://github.com/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID})" >> pr_body.md
echo "" >> pr_body.md # Add newline
echo "This PR will be automatically merged upon successful checks." >> pr_body.md

echo "✅ PR body content written to pr_body.md"
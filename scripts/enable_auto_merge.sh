#!/usr/bin/env bash
set -euo pipefail

# Enable auto-merge for a pull request
# Requires PR_NUMBER and GH_TOKEN env vars

echo "::group::Enable Auto-Merge"
echo "Enabling auto-merge for PR #${PR_NUMBER}"

# Install GitHub CLI if not installed
if ! command -v gh &> /dev/null; then
  echo "Installing GitHub CLI..."
  type -p curl >/dev/null || (sudo apt update && sudo apt install -y curl)
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
    https://cli.github.com/packages stable main" \
    | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null \
    && sudo apt update \
    && sudo apt install -y gh
else
  echo "GitHub CLI already installed."
fi

# Authenticate GitHub CLI using GH_TOKEN for non-interactive login
echo "${GH_TOKEN}" | gh auth login --with-token

# Merge PR automatically
if gh pr merge "${PR_NUMBER}" --auto --merge --delete-branch; then
  echo "Auto-merge enabled for PR #${PR_NUMBER}"
else
  echo "::warning::Auto-merge failed for PR #${PR_NUMBER}, continuing."
fi

echo "::endgroup::"

#!/usr/bin/env bash
set -euo pipefail

# Enable auto-merge for a pull request
# Requires PR_NUMBER and GH_TOKEN env vars

# Error handling function
error_handler() {
    local line_number=$1
    local error_code=$2
    local timestamp
    timestamp=$(date -u +"%Y-%m-%d %H:%M:%S UTC")
    
    echo "::error::Error occurred at ${timestamp}"
    echo "::error::Script failed at line ${line_number} with error code ${error_code}"
    
    # Log detailed error information
    echo "::group::Error Details"
    echo "Timestamp: ${timestamp}"
    echo "Line Number: ${line_number}"
    echo "Error Code: ${error_code}"
    echo "PR Number: ${PR_NUMBER:-N/A}"
    echo "Current User: ${GITHUB_ACTOR:-N/A}"
    
    # Get PR status for debugging
    if [ -n "${PR_NUMBER:-}" ]; then
        echo "PR Status:"
        gh pr view "${PR_NUMBER}" --json mergeStateStatus,mergeable,state,statusCheckRollup 2>/dev/null || echo "Could not fetch PR status"
    fi
    echo "::endgroup::"
    
    # Attempt recovery if possible
    if [ "${error_code}" -eq 1 ] && [ -n "${PR_NUMBER:-}" ]; then
        echo "::notice::Attempting error recovery..."
        attempt_recovery
    fi
}

# Function to attempt recovery after failure
attempt_recovery() {
    local recovery_attempts=2
    local recovery_wait=10
    
    echo "::group::Recovery Attempt"
    for ((i=1; i<=recovery_attempts; i++)); do
        echo "Recovery attempt ${i}/${recovery_attempts}..."
        
        # Check if PR exists and is still open
        if ! gh pr view "${PR_NUMBER}" --json state --jq .state | grep -q "OPEN"; then
            echo "::error::PR is no longer open, recovery aborted"
            break
        fi
        
        # Try to re-enable auto-merge with increased timeouts
        if enable_auto_merge; then
            echo "::notice::Recovery successful!"
            echo "::endgroup::"
            return 0
        fi
        
        echo "::warning::Recovery attempt ${i} failed, waiting ${recovery_wait}s before next attempt..."
        sleep $recovery_wait
        recovery_wait=$((recovery_wait * 2))
    done
    
    echo "::error::Recovery attempts exhausted"
    echo "::endgroup::"
    return 1
}

trap 'error_handler ${LINENO} $?' ERR

# Function to check GitHub permissions
check_permissions() {
    echo "Checking required permissions..."
    # Test authentication and repository access
    if ! gh auth status &>/dev/null; then
        echo "::error::GitHub authentication failed. Please check GH_TOKEN."
        exit 1
    fi

    # Verify write access to the repository
    if ! gh api repos/:owner/:repo/collaborators/${GITHUB_ACTOR}/permission | grep -q '"write"\|"admin"'; then
        echo "::error::Insufficient permissions. Write access is required."
        exit 1
    }
}

# Function to check branch protection rules
check_branch_protection() {
    local target_branch
    target_branch=$(gh pr view "${PR_NUMBER}" --json baseRefName --jq .baseRefName)
    echo "Checking branch protection rules for ${target_branch}..."
    
    if gh api "repos/:owner/:repo/branches/${target_branch}/protection" &>/dev/null; then
        echo "Branch protection rules are enabled for ${target_branch}"
        return 0
    else
        echo "::warning::No branch protection rules found for ${target_branch}"
        return 1
    fi
}

# Function to check required status checks
check_status_checks() {
    local timeout=1800  # 30 minutes timeout
    local interval=30   # Check every 30 seconds
    local elapsed=0
    
    while [ $elapsed -lt $timeout ]; do
        local status_output
        status_output=$(gh pr view "${PR_NUMBER}" --json statusCheckRollup --jq '.statusCheckRollup[] | select(.state != "SUCCESS")')
        
        if [ -z "$status_output" ]; then
            echo "All required status checks have passed"
            return 0
        else
            echo "::notice::Waiting for status checks to complete (${elapsed}s elapsed)..."
            if [ $elapsed -eq 0 ]; then
                echo "Pending checks:"
                echo "$status_output" | jq -r '.context + ": " + .state'
            fi
            sleep $interval
            elapsed=$((elapsed + interval))
        fi
    done
    
    echo "::error::Timeout waiting for status checks to complete"
    return 1
}

# Function to enable auto-merge
enable_auto_merge() {
    local max_retries=5
    local retry_count=0
    local wait_time=5
    
    echo "Attempting to enable auto-merge..."
    while [ $retry_count -lt $max_retries ]; do
        if gh pr merge "${PR_NUMBER}" --auto --merge --delete-branch; then
            echo "Auto-merge enabled successfully"
            return 0
        fi
        
        retry_count=$((retry_count + 1))
        if [ $retry_count -lt $max_retries ]; then
            wait_time=$((wait_time * 2))  # Exponential backoff
            echo "::warning::Failed to enable auto-merge (attempt ${retry_count}/${max_retries}), retrying in ${wait_time}s..."
            sleep $wait_time
        fi
    done
    
    echo "::error::Failed to enable auto-merge after ${max_retries} attempts"
    return 1
}

# Function to verify auto-merge status
verify_auto_merge() {
    local max_attempts=3
    local attempt=0
    local wait_time=5
    
    while [ $attempt -lt $max_attempts ]; do
        local merge_status
        merge_status=$(gh pr view "${PR_NUMBER}" --json autoMergeRequest --jq '.autoMergeRequest.enabledAt')
        
        if [ -n "$merge_status" ]; then
            echo "Auto-merge verification successful"
            return 0
        fi
        
        attempt=$((attempt + 1))
        if [ $attempt -lt $max_attempts ]; then
            echo "::warning::Auto-merge not yet confirmed, retrying verification..."
            sleep $wait_time
            wait_time=$((wait_time * 2))
        fi
    done
    
    echo "::error::Could not verify auto-merge status"
    return 1
}

main() {
    echo "::group::Enable Auto-Merge"
    echo "Enabling auto-merge for PR #${PR_NUMBER}"

    # Validate required environment variables
    if [ -z "${PR_NUMBER:-}" ] || [ -z "${GH_TOKEN:-}" ]; then
        echo "::error::Required environment variables PR_NUMBER and/or GH_TOKEN are not set"
        exit 1
    fi

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

    # Check permissions before proceeding
    check_permissions

    # Check branch protection and adapt strategy
    check_branch_protection
    
    # Check status checks before enabling auto-merge
    if ! check_status_checks; then
        echo "::error::Required status checks are not passing"
        exit 1
    fi
    
    # Enable auto-merge
    if ! enable_auto_merge; then
        echo "::error::Failed to enable auto-merge"
        exit 1
    fi
    
    # Verify auto-merge was enabled
    if ! verify_auto_merge; then
        echo "::error::Failed to verify auto-merge status"
        exit 1
    fi

    echo "::endgroup::"
}

# Execute main function
main

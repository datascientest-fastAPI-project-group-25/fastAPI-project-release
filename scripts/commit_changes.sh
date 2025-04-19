#!/usr/bin/env bash
set -euo pipefail

# Git configuration

echo "::group::Git Configuration"
git config --global user.name "${GIT_AUTHOR_NAME}"
git config --global user.email "${GIT_AUTHOR_EMAIL}"
echo "::endgroup::"

# Default branch
default_branch="main"
echo "Default branch: $default_branch"

echo "::group::Git Status and Staging"
git status
# Stage Helm value changes
git add config/helm/values-*.yaml charts/fastapi/Chart.yaml || echo "No files to add, continuing..."
git status
echo "::endgroup::"

# Only proceed if there are staged changes
if ! git diff --staged --quiet; then
    echo "Staged changes detected, proceeding with branch creation and commit."

    echo "::group::Generating Commit Message"
    COMMIT_MESSAGE=$(./scripts/generate_commit_message.sh)
    echo "Generated commit message: $COMMIT_MESSAGE"
    echo "::endgroup::"

    # Generate branch name
timestamp=$(date +%Y%m%d%H%M%S)
if [[ "$ENV" == "prod" ]]; then
    semver_branch=$(echo "$SEMANTIC_VERSION" | sed 's/\./-/g')
    new_branch="helm-update-prod-${semver_branch}-${timestamp}"
else
    tag_branch=$(echo "$DEPLOY_TAG" | sed 's/[^a-zA-Z0-9-]/-/g')
    new_branch="helm-update-stg-${tag_branch}-${timestamp}"
fi
    echo "New branch name: $new_branch"
    echo "branch_name=$new_branch" >> $GITHUB_OUTPUT

    echo "::group::Branch Creation"
    if git show-ref --verify --quiet "refs/heads/$new_branch"; then
        git checkout "$new_branch"
    else
        git checkout -b "$new_branch"
    fi
    echo "::endgroup::"

    echo "::group::Committing Changes"
    git commit -m "$COMMIT_MESSAGE"
    echo "::endgroup::"

    echo "::group::Pushing Branch"
    if git push --set-upstream origin "$new_branch"; then
        echo "committed=true" >> $GITHUB_OUTPUT
        echo "::endgroup::"

        echo "::group::Creating Pull Request using gh cli"
        PR_BODY=$(./scripts/generate_pr_body.sh)
        if PR_URL=$(gh pr create --base "$default_branch" --head "$new_branch" --title "$COMMIT_MESSAGE" --body "$PR_BODY" 2>&1); then
            PR_NUMBER=$(echo "$PR_URL" | grep -oE '[0-9]+$')
            echo "pr_number=$PR_NUMBER" >> $GITHUB_OUTPUT
        else
            if echo "$PR_URL" | grep -q 'A pull request for .* already exists'; then
                existing_pr=$(gh pr list --head "$new_branch" --json number -q '.[0].number')
                echo "pr_number=$existing_pr" >> $GITHUB_OUTPUT
            else
                echo "error: $PR_URL"
                exit 1
            fi
        fi
        echo "::endgroup::"
    else
        exit 1
    fi
else
    echo "committed=false" >> $GITHUB_OUTPUT
fi

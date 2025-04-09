# Release Integration Guide

This document explains how the integration between the application repository and the release repository works, and how to set it up.

## Overview

The integration allows for automatic deployment of new application versions when a release is created in the application repository. The workflow is as follows:

1. A new version is built and released in the application repository
2. The application repository triggers a workflow in the release repository
3. The release repository updates the Helm values with the new image tags
4. ArgoCD detects the changes and deploys the new version

## Setup Instructions

### 1. Create a Personal Access Token (PAT)

You need to create a GitHub Personal Access Token with the necessary permissions to trigger workflows in the release repository:

1. Go to your GitHub account settings
2. Navigate to "Developer settings" > "Personal access tokens" > "Tokens (classic)"
3. Click "Generate new token"
4. Give it a descriptive name like "App to Release Integration"
5. Select the following scopes:
   - `repo` (Full control of private repositories)
   - `workflow` (Update GitHub Action workflows)
6. Click "Generate token" and copy the token

### 2. Add the Token as a Secret in the App Repository

1. Go to the application repository settings
2. Navigate to "Secrets and variables" > "Actions"
3. Click "New repository secret"
4. Name: `RELEASE_REPO_ACCESS_TOKEN`
5. Value: Paste the token you generated
6. Click "Add secret"

### 3. Configure ArgoCD Credentials

For the ArgoCD integration to work, you need to add the following secrets to the release repository:

1. Go to the release repository settings
2. Navigate to "Secrets and variables" > "Actions"
3. Add the following secrets:
   - `ARGOCD_SERVER`: The URL of your ArgoCD server
   - `ARGOCD_USERNAME`: Your ArgoCD username
   - `ARGOCD_PASSWORD`: Your ArgoCD password

## How It Works

### App Repository Workflow

The `create-release.yml` workflow in the app repository:
1. Creates a GitHub release with the new version
2. Triggers the release repository workflow using the repository dispatch event

### Release Repository Workflow

The `app-release-trigger.yml` workflow in the release repository:
1. Updates the Helm values files with the new image tags
2. Commits and pushes the changes
3. Triggers ArgoCD to sync the application
4. Creates a GitHub release in the release repository

## Manual Triggering

You can also manually trigger the release workflow:

1. Go to the release repository on GitHub
2. Navigate to "Actions" > "Update from App Release"
3. Click "Run workflow"
4. Enter the version and select the environment
5. Click "Run workflow"

## Troubleshooting

If the integration is not working as expected, check the following:

1. Verify that the PAT has the necessary permissions
2. Check that the PAT is correctly added as a secret in the app repository
3. Ensure that the ArgoCD credentials are correctly configured
4. Check the workflow logs for any errors
5. Verify that the repository names in the workflow files match your actual repository names

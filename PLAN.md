# Deployment Improvement Plan

## Past Actions

1. **Version Merge Driver Implementation**
   - Added a custom git merge driver for VERSION file to prevent conflicts
   - Created scripts to handle version conflicts by keeping the higher version
   - Updated CI/CD workflows to use the merge driver
   - Successfully tested the solution with a full end-to-end workflow

2. **CI/CD Pipeline Improvements**
   - Split workflows into separate stages to avoid timing issues
   - Improved PR creation and merging processes
   - Added automatic version bumping on PR creation
   - Implemented proper branch protection and workflow

3. **Repository Cleanup**
   - Removed unnecessary branches from both app and release repositories
   - Maintained only essential branches (main, stg)

## Current Issues

1. **Helm Chart Secret Values Issue**
   - ArgoCD application is failing because the Helm chart is trying to use `.Values.secrets.databaseUrl` and `.Values.secrets.secretKey`
   - These values are not defined in all environment values files
   - The backend deployment has conditional logic to use either ConfigMap or Secret

2. **Container Image Pull Issues**
   - Pods are in ImagePullBackOff state because container images don't exist in GitHub Container Registry
   - Need to ensure proper image pull secrets and repository paths

## Plan to Fix Issues

### 1. Fix Helm Chart Secret Values

1. Update the values files to properly define the secrets or use existing secrets
2. Leverage the existing conditional logic in the templates
3. Ensure consistency across all environment configurations

### 2. Fix Image Pull Issues

1. Verify the image repository path is correct
2. Ensure proper image pull secrets are configured

## Implementation Steps

1. Create a branch `fix/improve-secrets`
2. Update values files to use existing secrets
3. Test the changes locally
4. Create a PR and merge to main
5. Verify ArgoCD deployment succeeds

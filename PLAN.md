# PLAN.md — CI/CD Bug Investigation & Remediation Checklist

## Objective
Improve the automated version bumping, relabeling, and branch management between `fastAPI-project-app` and `fastAPI-project-release`:
- Ensure SemVer version is correctly passed to the release repository
- Remove hardcoded fallback version numbers
- Provide clear error messages when version validation fails
- Improve the overall robustness of the workflow

---

## Current Work (2023-04-16)

### 1. Remove Hardcoded Fallback SemVer Solutions
- [x] Identify all instances of hardcoded fallback versions (e.g., "0.1.0")
- [x] Replace with proper error handling and clear error messages
- [x] Collect and display diagnostic information to help troubleshoot version issues

### 2. Repository Cleanup
- [x] Check for open PRs and merge if appropriate
- [x] Switch to main branch in both repositories
- [x] Remove unused branches if necessary
- [x] Create new fix branches for testing improvements

### 3. Improve Version Validation
- [x] Enhance version validation in trigger-helm-release.yml
- [x] Improve error messages to clearly indicate what went wrong
- [x] Add more detailed logging to help diagnose issues

### 4. Test Workflow Improvements
- [ ] Test the full flow (app build → release trigger → update-helm → PR to main)
- [ ] Verify that version handling works correctly for both staging and production
- [ ] Ensure proper error handling when invalid versions are detected

---

## ❗️Important branching rules

1. NEVER merge feature branches directly to main ON APP REPO (stg is required)
   - app repo: requires staging branch and stg→main flow
   - release repo: direct PR to main is okay (no staging flow required)
2. Always on app repo follow the flow:
   - feat/* -> stg (via PR)
   - stg -> main (via PR)

This ensures all changes go through proper staging and testing before reaching production.

## 🔒 Version Handling Strategy

1. Staging Environment:
   - Images: Tagged with stg-hash (e.g., stg-abc1234)
   - Helm Charts: Use semantic_version with -stg suffix (e.g., 1.2.3-stg)
   - No fallback to default versions - fail with clear error message

2. Production Environment:
   - Images: Tagged with semantic version (e.g., 1.2.3)
   - Helm Charts: Use semantic version (e.g., 1.2.3)
   - No fallback to default versions - fail with clear error message

---

## Progress Log

### 2023-04-16
- Analyzed current state of both repositories
- Identified existing branches and open PRs
- Created updated PLAN.md to track progress
- Decided to remove fix-update-helm.md as it's now outdated
- Created new fix branches in both repositories
- Removed all hardcoded fallback versions (0.1.0)
- Added proper error handling with detailed diagnostic information
- Improved logging with emojis and better formatting
- Enhanced version validation to fail early with clear error messages

## Notes
- Focus only on `fastAPI-project-app` and `fastAPI-project-release`
- Use PLAN.md as a living checklist; update as you progress


# Image Tagging Strategy

## Overview
This document outlines the tagging strategy used for container images across different environments.

## Production Environment
- Uses semantic versioning tags (e.g., `v1.2.3`)
- Tags are immutable
- No 'latest' tag is used to ensure deployment stability
- Example: `ghcr.io/org/app:v1.2.3`

## Staging Environment
- Uses dual tagging approach:
  1. Semantic version tag (e.g., `v1.2.3-rc1`)
  2. Rolling `stg-latest` tag
- Rationale:
  - The semantic version tag provides traceability and rollback capability
  - The `stg-latest` tag enables continuous deployment workflows
  - Using both ensures we can track exact versions while maintaining deployment automation

### Staging Tag Examples
```
ghcr.io/org/app:v1.2.3-rc1  # Immutable tag for traceability
ghcr.io/org/app:stg-latest  # Rolling tag for CD workflows
```

## Best Practices
1. **Production Deployments**
   - Always use specific version tags
   - Never use floating tags like 'latest'
   - Tag format: `vX.Y.Z`

2. **Staging Deployments**
   - Use both version tags and `stg-latest`
   - Version tag format: `vX.Y.Z-rcN`
   - Automated workflows update `stg-latest` on successful builds

3. **Version Control**
   - Tags are created from release branches
   - Each release gets a unique semantic version
   - Release candidates are suffixed with `-rcN`

## Implementation
The tagging strategy is implemented in the following files:
- `.github/workflows/update-helm.yaml`: Handles deployment updates
- `charts/fastapi/values.yaml`: Defines image configuration
- `scripts/get_release_vars.sh`: Manages tag generation
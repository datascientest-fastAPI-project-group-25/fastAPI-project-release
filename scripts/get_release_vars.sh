#!/usr/bin/env bash
set -euo pipefail

RAW_TAG="${1}"
PRERELEASE="${2}"

echo "Processing published release event for tag $RAW_TAG"

# Determine environment based on tag format and prerelease flag
# Production: tag starts with 'v', is NOT a prerelease, and not 'vstg-' or 'stg-'
# Staging: tag starts with 'vstg-' OR 'stg-' OR is a prerelease
if [[ "$RAW_TAG" == v* && "$PRERELEASE" == "false" && "$RAW_TAG" != vstg-* && "$RAW_TAG" != stg-* ]]; then
  ENV="prod"
  SEMANTIC_VERSION="${RAW_TAG#v}"
  DEPLOY_TAG="$SEMANTIC_VERSION"
  if ! [[ "$DEPLOY_TAG" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "::error::Invalid production tag format '$RAW_TAG'. Expected 'vX.Y.Z'."
    exit 1
  fi
  GIT_HASH=""
elif [[ "$RAW_TAG" == vstg-* || "$RAW_TAG" == stg-* || "$PRERELEASE" == "true" ]]; then
  ENV="stg"
  if [[ "$RAW_TAG" == vstg-* ]]; then
    if [[ "$RAW_TAG" =~ vstg-([0-9]+\.[0-9]+\.[0-9]+)-([a-f0-9]+) ]]; then
      BASE_SEMVER="${BASH_REMATCH[1]}"
      GIT_HASH="${BASH_REMATCH[2]}"
      SEMANTIC_VERSION="${BASE_SEMVER}-stg"
      DEPLOY_TAG="stg-${GIT_HASH}"
    else
      echo "::error::Invalid vstg tag format '$RAW_TAG'. Expected 'vstg-X.Y.Z-<hash>'."
      exit 1
    fi
  elif [[ "$RAW_TAG" == stg-* ]]; then
    BASE_SEMVER="${RAW_TAG#stg-}"
    SEMANTIC_VERSION="${BASE_SEMVER}-stg"
    DEPLOY_TAG="$RAW_TAG"
    GIT_HASH=""
  else
    if [[ "$RAW_TAG" =~ -([a-f0-9]+)$ ]]; then
      GIT_HASH="${BASH_REMATCH[1]}"
      SEMVER_BASE="${RAW_TAG%-*}"
      SEMANTIC_VERSION="${SEMVER_BASE}-stg"
      DEPLOY_TAG="stg-${GIT_HASH}"
    else
      echo "::error::Invalid prerelease tag format '$RAW_TAG'."
      exit 1
    fi
  fi
else
  echo "::error::Could not determine environment from tag '$RAW_TAG' and prerelease status ($PRERELEASE)."
  exit 1
fi

echo "Determined environment: $ENV"
echo "Determined semantic version: $SEMANTIC_VERSION"
echo "Determined deploy tag: $DEPLOY_TAG"
echo "Determined git hash: $GIT_HASH"

# Set outputs for GitHub Actions
: > "$GITHUB_OUTPUT"
echo "env=$ENV" >> "$GITHUB_OUTPUT"
echo "raw_version=$RAW_TAG" >> "$GITHUB_OUTPUT"
echo "semantic_version=$SEMANTIC_VERSION" >> "$GITHUB_OUTPUT"
echo "deploy_tag=$DEPLOY_TAG" >> "$GITHUB_OUTPUT"
echo "git_hash=$GIT_HASH" >> "$GITHUB_OUTPUT"

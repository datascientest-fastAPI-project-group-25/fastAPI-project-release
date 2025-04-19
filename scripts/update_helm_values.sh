#!/usr/bin/env bash
set -euo pipefail

# Ensure required environment variables are set
: "${ENV:?ENV not set}"
: "${DEPLOY_TAG:?DEPLOY_TAG not set}"
: "${SEMANTIC_VERSION:?SEMANTIC_VERSION not set}"

echo "::group::Environment and Target Tag Information"
echo "Environment: $ENV"
echo "Target Deploy Tag: $DEPLOY_TAG"
echo "Target Semantic Version (for Chart.yaml if prod): $SEMANTIC_VERSION"
echo "::endgroup::"

# Determine values file path
if [[ "$ENV" == "prod" ]]; then
  VALUES_FILE="config/helm/values-prod.yaml"
  CHART_FILE="charts/fastapi/Chart.yaml"
elif [[ "$ENV" == "stg" ]]; then
  VALUES_FILE="config/helm/values-stg.yaml"
  CHART_FILE=""
else
  echo "::error::Invalid environment '$ENV' determined." >&2
  exit 1
fi

# Check if values file exists
if [ ! -f "$VALUES_FILE" ]; then
  echo "::error::Values file $VALUES_FILE does not exist" >&2
  ls -la config/helm/
  exit 1
fi

echo "✅ Values file exists: $VALUES_FILE"

# --- Idempotency Check ---
echo "::group::Checking Current Tag Values"
CURRENT_BACKEND_TAG=$(yq e '.backend.tag' "$VALUES_FILE" || echo "ERROR")
CURRENT_FRONTEND_TAG=$(yq e '.frontend.tag' "$VALUES_FILE" || echo "ERROR")

if [[ "$CURRENT_BACKEND_TAG" == "ERROR" || "$CURRENT_FRONTEND_TAG" == "ERROR" ]]; then
  echo "::error::Failed to read current tag values from $VALUES_FILE" >&2
  exit 1
fi

echo "Current backend tag: $CURRENT_BACKEND_TAG"
echo "Current frontend tag: $CURRENT_FRONTEND_TAG"

# Check Chart.yaml version for prod
CURRENT_CHART_VERSION=""
CURRENT_APP_VERSION=""
if [[ "$ENV" == "prod" && -n "$CHART_FILE" && -f "$CHART_FILE" ]]; then
  CURRENT_CHART_VERSION=$(yq e '.version' "$CHART_FILE" || echo "ERROR")
  CURRENT_APP_VERSION=$(yq e '.appVersion' "$CHART_FILE" || echo "ERROR")
  echo "Current Chart.yaml version: $CURRENT_CHART_VERSION"
  echo "Current Chart.yaml appVersion: $CURRENT_APP_VERSION"
  if [[ "$CURRENT_CHART_VERSION" == "ERROR" || "$CURRENT_APP_VERSION" == "ERROR" ]]; then
    echo "::error::Failed to read current Chart.yaml versions" >&2
    exit 1
  fi
elif [[ "$ENV" == "prod" ]]; then
  echo "::warning::Chart.yaml file not found or not specified for prod. Skipping version check."
fi
echo "::endgroup::"

# Compare current tags/versions with the target deploy tag/semantic version
NEEDS_UPDATE="false"
if [[ "$CURRENT_BACKEND_TAG" != "$DEPLOY_TAG" || "$CURRENT_FRONTEND_TAG" != "$DEPLOY_TAG" ]]; then
  NEEDS_UPDATE="true"
  echo "Values file needs update: Tags mismatch."
fi

# Also check Chart.yaml for prod
if [[ "$ENV" == "prod" && -n "$CHART_FILE" && -f "$CHART_FILE" ]]; then
  if [[ "$SEMANTIC_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    if [[ "$CURRENT_CHART_VERSION" != "$SEMANTIC_VERSION" || "$CURRENT_APP_VERSION" != "$SEMANTIC_VERSION" ]]; then
      NEEDS_UPDATE="true"
      echo "Chart.yaml needs update: Versions mismatch."
    fi
  else
    echo "::warning::Cannot compare Chart.yaml version as target semantic version '$SEMANTIC_VERSION' is not in X.Y.Z format."  
  fi
fi

if [[ "$NEEDS_UPDATE" == "false" ]]; then
  echo "✅ Helm values are already up-to-date with target tag '$DEPLOY_TAG'. No changes needed."
  echo "updated=false" >> "$GITHUB_OUTPUT"
  exit 0
fi

# Perform updates
 echo "::group::Updating Image Tags and Chart Version"
 echo "Updating values file: $VALUES_FILE"
 echo "Updating backend tag: $CURRENT_BACKEND_TAG -> $DEPLOY_TAG"
 sed -i "s|tag: $CURRENT_BACKEND_TAG\(.*\)|tag: $DEPLOY_TAG\1|" "$VALUES_FILE"

 echo "Updating frontend tag: $CURRENT_FRONTEND_TAG -> $DEPLOY_TAG"
 sed -i "s|tag: $CURRENT_FRONTEND_TAG\(.*\)|tag: $DEPLOY_TAG\1|" "$VALUES_FILE"

 if [[ "$ENV" == "prod" && -n "$CHART_FILE" && -f "$CHART_FILE" ]]; then
   if [[ "$SEMANTIC_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
     echo "Updating Chart.yaml: $CHART_FILE"
     echo "Updating version: $CURRENT_CHART_VERSION -> $SEMANTIC_VERSION"
     sed -i "s/version: .*/version: $SEMANTIC_VERSION/" "$CHART_FILE"
     echo "Updating appVersion: $CURRENT_APP_VERSION -> $SEMANTIC_VERSION"
     sed -i "s/appVersion: .*/appVersion: $SEMANTIC_VERSION/" "$CHART_FILE"
   else
     echo "::warning::Not updating Chart.yaml version as semantic version '$SEMANTIC_VERSION' is not in X.Y.Z format"
   fi
 fi
 echo "::endgroup::"

# Verification
 echo "::group::Verification after Update"
 NEW_BACKEND_TAG=$(yq e '.backend.tag' "$VALUES_FILE" || echo "ERROR")
 NEW_FRONTEND_TAG=$(yq e '.frontend.tag' "$VALUES_FILE" || echo "ERROR")

 if [[ "$NEW_BACKEND_TAG" == "ERROR" || "$NEW_FRONTEND_TAG" == "ERROR" ]]; then
    echo "::error::Failed to read tags after update!" >&2
    exit 1
 fi
 if [[ "$NEW_BACKEND_TAG" != "$DEPLOY_TAG" || "$NEW_FRONTEND_TAG" != "$DEPLOY_TAG" ]]; then
   echo "::error::Tag verification failed after update!"
   echo "Expected: $DEPLOY_TAG"
   echo "Got: backend=$NEW_BACKEND_TAG, frontend=$NEW_FRONTEND_TAG"
   exit 1
 fi
 echo "✅ Tags successfully updated and verified in $VALUES_FILE"

 if [[ "$ENV" == "prod" && -n "$CHART_FILE" && -f "$CHART_FILE" ]]; then
   if [[ "$SEMANTIC_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
     NEW_CHART_VERSION=$(yq e '.version' "$CHART_FILE" || echo "ERROR")
     NEW_APP_VERSION=$(yq e '.appVersion' "$CHART_FILE" || echo "ERROR")
     if [[ "$NEW_CHART_VERSION" == "ERROR" || "$NEW_APP_VERSION" == "ERROR" ]]; then
       echo "::error::Failed to read Chart.yaml versions after update!" >&2
       exit 1
     fi
     if [[ "$NEW_CHART_VERSION" != "$SEMANTIC_VERSION" || "$NEW_APP_VERSION" != "$SEMANTIC_VERSION" ]]; then
       echo "::error::Chart.yaml version verification failed after update!"
       echo "Expected: $SEMANTIC_VERSION"
       echo "Got: version=$NEW_CHART_VERSION, appVersion=$NEW_APP_VERSION"
       exit 1
     fi
     echo "✅ Chart.yaml versions successfully updated and verified"
   fi
 fi
 echo "::endgroup::"

# Set outputs for use in later steps
 echo "updated=true" >> "$GITHUB_OUTPUT"
 echo "old_backend_tag=$CURRENT_BACKEND_TAG" >> "$GITHUB_OUTPUT"
 echo "old_frontend_tag=$CURRENT_FRONTEND_TAG" >> "$GITHUB_OUTPUT"
 echo "deploy_tag=$DEPLOY_TAG" >> "$GITHUB_OUTPUT"

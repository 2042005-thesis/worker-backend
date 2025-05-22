#!/bin/bash
set -euo pipefail  # Exit on error, undefined variable, or pipe failure

# Function to log messages
log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

# Initialize VERSION_TAG to avoid "unbound variable" errors
VERSION_TAG=""

# Extract version tag if it's a tag reference
if [[ "${GITHUB_REF}" == refs/tags/v* ]]; then
  VERSION_TAG="${GITHUB_REF#refs/tags/}"
fi

# Determine the environment based on the Git reference
if [[ "${GITHUB_REF}" == "refs/heads/dev" ]]; then
  COMPOSE_FILE="apps/dev/docker-compose.yml"
  BRANCH="dev"
  ALLOW_UPDATE=true
  log "Environment: Dev"

elif [[ "$VERSION_TAG" =~ ^v[0-9]+\.[0-9]+\.[0-9]+-pre$ ]]; then
  COMPOSE_FILE="apps/staging/docker-compose.yml"
  BRANCH="staging"
  ALLOW_UPDATE=true
  log "Environment: Staging (pre-release)"

elif [[ "$VERSION_TAG" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  COMPOSE_FILE="apps/production/docker-compose.yml"
  BRANCH="main"
  ALLOW_UPDATE=true
  log "Environment: Production (stable release)"

else
  log "Skipping update: Unrecognized or unsupported Git reference '$GITHUB_REF'"
  exit 0
fi

# Clone the deployment repository
if [[ -n "${DEPLOYMENT_REPO:-}" ]]; then
  log "Cloning deployment repo..."
  git clone "https://$DEPLOYMENT_TOKEN@$DEPLOYMENT_REPO" deployment
  cd deployment
  git fetch origin dev
  git checkout dev || git checkout -b dev "origin/dev"
  git reset --hard "origin/dev"
else
  log "Error: DEPLOYMENT_REPO is not defined."
  exit 1
fi

# Proceed only if updates are allowed
if [[ "$ALLOW_UPDATE" == true ]]; then
  log "Updating $COMPOSE_FILE with image tag: $DOCKER_METADATA_OUTPUT_TAGS"

  # Replace image tag
  sed -E -i "s|(image:\s*$IMAGE_NAME):[a-zA-Z0-9._-]+|\1:$DOCKER_METADATA_OUTPUT_VERSION|" "$COMPOSE_FILE"

  git config user.name "github-actions[bot]"
  git config user.email "github-actions[bot]@users.noreply.github.com"

  git add "$COMPOSE_FILE"

  if git diff --cached --quiet; then
    log "No changes to commit."
    exit 0
  fi

  git commit -m "Update image tag to $DOCKER_METADATA_OUTPUT_TAGS"
  git push origin dev
  log "Changes pushed to dev."
else
  log "Skipping update: ALLOW_UPDATE is not set to true."
  exit 0
fi

#!/bin/bash
set -e  # Exit on error

# Determine the correct docker-compose file to update
if [[ "${GITHUB_REF}" == "refs/heads/staging" ]]; then
  COMPOSE_FILE="env/staging/docker-compose.yml"
  BRANCH="staging"
  ALLOW_UPDATE=true  # Always allow updates for staging (Git SHA)

elif [[ "${GITHUB_REF}" == refs/tags/v* ]]; then
  # Extract the version from the tag (e.g., v1.2.3)
  VERSION_TAG="${GITHUB_REF#refs/tags/}"

  # Allow update only if it's a stable semantic version (vX.Y.Z)
  if [[ "$VERSION_TAG" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    COMPOSE_FILE="env/production/docker-compose.yml"
    BRANCH="main"
    ALLOW_UPDATE=true
  else
    echo "Skipping update: Tag '$VERSION_TAG' is not a stable semantic version."
    exit 0
  fi

  # Ensure we are on the main branch
  git fetch origin main  # Fetch latest main branch
  git checkout main || git checkout -b main origin/main  # Switch to main branch
  git reset --hard origin/main  # Ensure branch is up to date

else
  echo "Branch not recognized, skipping update."
  exit 0
fi

# Proceed only if updates are allowed
if [[ "$ALLOW_UPDATE" == "true" ]]; then
  # Configure Git credentials
  git config user.name "github-actions[bot]"
  git config user.email "github-actions[bot]@users.noreply.github.com"

  # Update docker image tag in docker-compose.yml
  echo "Updating $COMPOSE_FILE with image: $DOCKER_METADATA_OUTPUT_VERSION"
  sed -E -i "s|(image:\s*)[^ ]+|\1$DOCKER_METADATA_OUTPUT_TAGS|" "$COMPOSE_FILE"

  # Stage changes
  git add "$COMPOSE_FILE"

  # Check if there are changes before committing
  if git diff --cached --quiet; then
    echo "No changes to commit, skipping push."
    exit 0  # Exit gracefully instead of failing
  fi

  # Commit and push changes
  git commit -m "Update image tag $DOCKER_METADATA_OUTPUT_VERSION"
  git push origin "$BRANCH"
else
  echo "Skipping update: No valid SHA or stable semantic version detected."
fi

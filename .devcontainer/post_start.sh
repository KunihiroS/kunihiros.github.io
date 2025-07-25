#!/bin/bash
# post_start.sh
# This script runs after the container is created and attached.
# It tags the container's base image with the current timestamp.

set -e

# The base name for the image, defined in devcontainer.json.
# This should be consistent with the image being built.
IMAGE_NAME_BASE="ghcr.io/kunihiros/kunihiros.github.io"

# --- Script Body ---
echo "[post-start] Starting image tagging process..."

# Explicitly define the Podman host socket path as it is not available in the postAttachCommand environment.
export PODMAN_HOST="unix:///run/user/1000/podman/podman.sock"

# Get the container's own ID from its hostname.
CONTAINER_ID=$(hostname)
if [ -z "$CONTAINER_ID" ]; then
    echo "[post-start] Error: Could not determine container ID from hostname." >&2
    exit 1
fi

# Get the full image ID (SHA) from the container ID using the host's Podman daemon.
IMAGE_ID=$(sudo podman --url "$PODMAN_HOST" inspect --format '{{.Image}}' "$CONTAINER_ID")
if [ -z "$IMAGE_ID" ]; then
    echo "[post-start] Error: Could not determine image ID from container '${CONTAINER_ID}'." >&2
    exit 1
fi

# Generate a timestamp tag for today's date (e.g., YYYYMMDD).
TODAY_TAG_DATE=$(date +%Y%m%d)
NEW_IMAGE_NAME="${IMAGE_NAME_BASE}:${TODAY_TAG_DATE}"

# Check if an image with today's tag already exists to ensure idempotency.
EXISTING_TAG=$(sudo podman --url "$PODMAN_HOST" image list --format "{{.Repository}}:{{.Tag}}" | grep "^${NEW_IMAGE_NAME}$" || true)
if [ -n "$EXISTING_TAG" ]; then
    echo "[post-start] Image for today (${TODAY_TAG_DATE}) already has a timestamp tag. Skipping."
    exit 0
fi

# Apply the new timestamp tag to the image.
sudo podman --url "$PODMAN_HOST" tag "$IMAGE_ID" "$NEW_IMAGE_NAME"

echo "[post-start] Successfully tagged image as ${NEW_IMAGE_NAME}"

# --- End of Script ---

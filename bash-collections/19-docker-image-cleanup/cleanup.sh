#!/bin/bash
# Docker Image Cleanup: Remove dangling and old unused images
#
# Usage:
#   ./cleanup.sh [--force]

FORCE=$1

echo "Cleaning up dangling Docker images..."
docker image prune -f

echo -e "\nCleaning up unused volumes..."
docker volume prune -f

if [ "$FORCE" == "--all" ]; then
    echo -e "\nRemoving ALL unused images (not just dangling)..."
    docker image prune -a -f
fi

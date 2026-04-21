#!/bin/bash
# Automatically generated script: docker-clean-all
# Purpose: Purge dead Docker images, containers and volumes fully.

docker system prune -af --volumes

#!/bin/bash
# Automatically generated script: docker-ip
# Purpose: Isolate and read a Docker Container's exact IP address.

docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$1"

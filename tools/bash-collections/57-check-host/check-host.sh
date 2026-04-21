#!/bin/bash
# Automatically generated script: check-host
# Purpose: Check if a host is up or down.

ping -c 1 "$1" &> /dev/null && echo "up" || echo "down"

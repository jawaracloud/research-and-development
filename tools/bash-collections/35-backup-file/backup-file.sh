#!/bin/bash
# Automatically generated script: backup-file
# Purpose: Make a timestamped backup of a file.

cp -a "$1" "$1.bak-$(date +%Y%m%d%H%M%S)"

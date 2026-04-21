#!/bin/bash
# Automatically generated script: restore-file
# Purpose: Restore the most recent timestamped backup.

latest=$(ls -t "${1}".bak-* 2>/dev/null | head -1); [ -n "$latest" ] && cp -a "$latest" "$1"

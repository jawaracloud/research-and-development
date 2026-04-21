#!/bin/bash
# Automatically generated script: serve-here
# Purpose: Serve the current directory over HTTP.

python3 -m http.server "${1:-8080}"

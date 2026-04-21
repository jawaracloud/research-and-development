#!/bin/bash
# Automatically generated script: run-until-fail
# Purpose: Continually trigger a local script indefinitely until finding an eventual failure context.

count=0; while "$@"; do count=$((count+1)); echo "Run \$count succeeded."; done; echo "Failed on run \$((count+1))"

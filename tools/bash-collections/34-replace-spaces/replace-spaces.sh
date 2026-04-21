#!/bin/bash
# Automatically generated script: replace-spaces
# Purpose: Replace all spaces in filenames with underscores.

for f in *\ *; do [ -e "$f" ] && mv "$f" "${f// /_}"; done

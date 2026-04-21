#!/bin/bash
# Automatically generated script: lowercase-names
# Purpose: Rename all files in a folder to lowercase.

for f in *; do [ -e "$f" ] && mv -v "$f" "$(echo "$f" | tr '[:upper:]' '[:lower:]')"; done

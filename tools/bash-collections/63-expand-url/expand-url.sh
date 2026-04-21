#!/bin/bash
# Automatically generated script: expand-url
# Purpose: Expand a shortened URL.

curl -sI "$1" | grep -i Location | awk '{print $2}' | tr -d '\r'

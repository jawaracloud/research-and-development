#!/bin/bash
# Automatically generated script: url-decode
# Purpose: URL-decode a string using pure bash.

echo -e "${1//%/\\x}"

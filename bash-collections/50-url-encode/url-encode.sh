#!/bin/bash
# Automatically generated script: url-encode
# Purpose: URL-encode a string using jq.

echo "$1" | jq -sRr @uri

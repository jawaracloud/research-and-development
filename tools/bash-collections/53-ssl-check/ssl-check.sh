#!/bin/bash
# Automatically generated script: ssl-check
# Purpose: Verify the expiration dates of an SSL certificate.

echo | openssl s_client -servername "$1" -connect "${1}:443" 2>/dev/null | openssl x509 -noout -dates

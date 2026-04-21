#!/bin/bash
# Automatically generated script: ip-info
# Purpose: Retrieve geolocation data for an IP.

curl -s "ipinfo.io/${1:-}"

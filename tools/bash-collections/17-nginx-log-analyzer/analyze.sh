#!/bin/bash
# Nginx Log Analyzer: Analyze Nginx access logs for insights
#
# Usage:
#   ./analyze.sh /var/log/nginx/access.log

LOG_FILE=$1

if [ -z "$LOG_FILE" ] || [ ! -f "$LOG_FILE" ]; then
    echo "Usage: $0 <nginx-access-log>"
    exit 1
fi

echo "--- Top 10 IP Addresses ---"
awk '{print $1}' "$LOG_FILE" | sort | uniq -c | sort -nr | head -n 10

echo -e "\n--- Top 10 Requested URLs ---"
awk '{print $7}' "$LOG_FILE" | sort | uniq -c | sort -nr | head -n 10

echo -e "\n--- HTTP Status Code Distribution ---"
awk '{print $9}' "$LOG_FILE" | sort | uniq -c | sort -nr

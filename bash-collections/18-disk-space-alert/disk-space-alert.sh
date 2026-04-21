#!/bin/bash
# Disk Space Alert Script: Monitor disk usage and send alerts
#
# Requirements:
#   - curl (for Telegram/Slack alerts)
#   - mailutils (optional, for email alerts)
#
# Usage:
#   ./disk-space-alert.sh [threshold-percent]
#   ./disk-space-alert.sh 90  # Alert at 90% usage

set -eo pipefail

# Configuration
THRESHOLD=${1:-85}  # Default 85% threshold
ALERT_VIA_TELEGRAM="true"
ALERT_VIA_EMAIL="false"
ALERT_VIA_SLACK="false"

# Telegram configuration (required if ALERT_VIA_TELEGRAM=true)
TELEGRAM_BOT_TOKEN="${TELEGRAM_BOT_TOKEN:-}"
TELEGRAM_CHAT_ID="${TELEGRAM_CHAT_ID:-}"

# Slack configuration (required if ALERT_VIA_SLACK=true)
SLACK_WEBHOOK_URL="${SLACK_WEBHOOK_URL:-}"

# Email configuration (required if ALERT_VIA_EMAIL=true)
EMAIL_TO="${EMAIL_TO:-admin@example.com}"
EMAIL_FROM="disk-alert@example.com"

# Filesystems to exclude
EXCLUDE_FS="^/proc|^/sys|^/dev|^/run|/var/lib/docker/overlay|/tmp|/var/lib/kubelet/pods"

# Function to send Telegram alert
send_telegram_alert() {
    local message="$1"
    if [ -n "$TELEGRAM_BOT_TOKEN" ] && [ -n "$TELEGRAM_CHAT_ID" ]; then
        curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
            -d chat_id="${TELEGRAM_CHAT_ID}" \
            -d parse_mode="Markdown" \
            -d text="${message}" > /dev/null
        log "Telegram alert sent"
    fi
}

# Function to send Slack alert
send_slack_alert() {
    local message="$1"
    if [ -n "$SLACK_WEBHOOK_URL" ]; then
        curl -s -X POST "$SLACK_WEBHOOK_URL" \
            -H "Content-type: application/json" \
            -d '{"text": "'"${message}"'"' > /dev/null
        log "Slack alert sent"
    fi
}

# Function to send email alert
send_email_alert() {
    local message="$1"
    local subject="$2"
    if [ -n "$EMAIL_TO" ]; then
        echo "$message" | mail -s "$subject" -r "$EMAIL_FROM" "$EMAIL_TO"
        log "Email alert sent to $EMAIL_TO"
    fi
}

# Function to log messages
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Check required tools
if [ "$ALERT_VIA_TELEGRAM" = "true" ] && ! command -v curl &> /dev/null; then
    log "Warning: curl not installed for Telegram alerts"
    ALERT_VIA_TELEGRAM="false"
fi

# Get filesystems with usage > threshold
log "Checking disk usage with threshold: ${THRESHOLD}%"

# Get disk usage info
DF_OUTPUT=$(df -Px\
    -t ext4 -t xfs -t btrfs -t zfs\
    | grep -vE "$EXCLUDE_FS")

# Check each filesystem
ALERT_MESSAGE="⚠️ *Disk Space Alert* ⚠️\n\n"
ALERT_COUNT=0

while read -r line; do
    # Skip header line
    if [[ "$line" =~ ^Filesystem ]]; then
        continue
    fi

    # Parse df output
    FS=$(echo "$line" | awk '{print $1}')
    SIZE=$(echo "$line" | awk '{print $2}')
    USED=$(echo "$line" | awk '{print $3}')
    AVAIL=$(echo "$line" | awk '{print $4}')
    USE_PERCENT=$(echo "$line" | awk '{print $5}' | sed 's/%//')
    MOUNT_POINT=$(echo "$line" | awk '{print $6}')

    # Check if usage exceeds threshold
    if [ "$USE_PERCENT" -ge "$THRESHOLD" ]; then
        ALERT_COUNT=$((ALERT_COUNT + 1))
        ALERT_MESSAGE+="📁 *Mount Point:* $MOUNT_POINT\n"
        ALERT_MESSAGE+="💾 *Usage:* $(numfmt --to=iec $USED) / $(numfmt --to=iec $SIZE)\n"
        ALERT_MESSAGE+="⚠️ *Percent Used:* ${USE_PERCENT}%\n"
        ALERT_MESSAGE+="📉 *Available:* $(numfmt --to=iec $AVAIL)\n"
        ALERT_MESSAGE+="🔗 *Partition:* $FS\n\n"
    fi
done <<< "$DF_OUTPUT"

# Send alerts if needed
if [ "$ALERT_COUNT" -gt 0 ]; then
    ALERT_MESSAGE="🚨 *DISK SPACE CRITICAL ALERT* 🚨\n\n${ALERT_MESSAGE}Threshold: ${THRESHOLD}% used"
    
    log "Disk space alert triggered for $ALERT_COUNT filesystems"
    
    if [ "$ALERT_VIA_TELEGRAM" = "true" ]; then
        send_telegram_alert "$ALERT_MESSAGE"
    fi
    
    if [ "$ALERT_VIA_SLACK" = "true" ]; then
        send_slack_alert "$ALERT_MESSAGE"
    fi
    
    if [ "$ALERT_VIA_EMAIL" = "true" ]; then
        send_email_alert "$ALERT_MESSAGE" "Disk Space Alert: Critical Usage Detected"
    fi
    
    # Print to stdout
    echo ""
    echo "=========================================="
    echo "DISK SPACE ALERT TRIGGERED"
    echo "=========================================="
    echo "$ALERT_MESSAGE"
    exit 1
else
    log "All disk usage within threshold (max ${THRESHOLD}%)"
    echo "✅ All filesystems are OK (max usage: $(df -P | grep -vE "$EXCLUDE_FS" | grep -v ^Filesystem | awk '{print $5}' | sed 's/%//' | sort -nr | head -1)%)"
    exit 0
fi
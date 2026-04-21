#!/bin/bash
# Logs Shipper: Simple script to zip and ship logs to a remote server
#
# Usage:
#   ./ship.sh <log-dir> <remote-dest>
#   ./ship.sh /var/log/nginx user@backup-server:/backups/logs/

LOG_DIR=$1
REMOTE_DEST=$2

if [ -z "$LOG_DIR" ] || [ -z "$REMOTE_DEST" ]; then
    echo "Usage: $0 <source-log-dir> <remote-ssh-dest>"
    exit 1
fi

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
ARCHIVE_NAME="logs_backup_${TIMESTAMP}.tar.gz"

echo "Archiving logs from $LOG_DIR..."
tar -czf "/tmp/$ARCHIVE_NAME" "$LOG_DIR"

echo "Shipping to $REMOTE_DEST..."
scp "/tmp/$ARCHIVE_NAME" "$REMOTE_DEST"

echo "Cleanup..."
rm "/tmp/$ARCHIVE_NAME"

echo "Done!"

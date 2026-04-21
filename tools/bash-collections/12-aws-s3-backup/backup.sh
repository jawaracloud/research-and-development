#!/bin/bash
# AWS S3 Backup Script: Backup directories or files to AWS S3 with compression and encryption
#
# Requirements:
#   - awscli must be installed and configured
#   - Proper AWS IAM permissions: s3:PutObject, s3:ListBucket
#
# Usage:
#   ./backup.sh /path/to/source s3://bucket-name/backup-path/
#   ./backup.sh /var/www/html s3://my-backups-bucket/www/

set -eo pipefail

# Configuration
BACKUP_SOURCE="$1"
BACKUP_DEST="$2"
BACKUP_NAME="backup_$(date +%Y%m%d_%H%M%S).tar.gz"
ENCRYPTION_PASSWORD="${ENCRYPTION_PASSWORD:-}"
COMPRESSION_LEVEL="6"

# Check for required arguments
if [ $# -ne 2 ]; then
    echo "Usage: $0 <source-directory> <s3-destination>"
    echo "Example: $0 /var/www/html s3://my-backups-bucket/www/"
    exit 1
fi

# Validate source exists
if [ ! -e "$BACKUP_SOURCE" ]; then
    echo "Error: Source path $BACKUP_SOURCE does not exist"
    exit 1
fi

# Validate S3 destination format
if [[ ! "$BACKUP_DEST" =~ ^s3:// ]]; then
    echo "Error: Destination must be in s3://bucket-name/path/ format"
    exit 1
fi

# Function to log messages
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Start backup process
log "Starting backup of $BACKUP_SOURCE to $BACKUP_DEST$BACKUP_NAME"

# Create temporary backup directory
TMP_DIR=$(mktemp -d)
TMP_BACKUP="$TMP_DIR/$BACKUP_NAME"

# Create compressed backup
if [ -n "$ENCRYPTION_PASSWORD" ]; then
    log "Creating encrypted backup with AES-256 encryption"
    tar -cf - -C "$(dirname "$BACKUP_SOURCE")" "$(basename "$BACKUP_SOURCE")" | \
        pigz -$COMPRESSION_LEVEL | \
        openssl enc -aes-256-cbc -salt -k "$ENCRYPTION_PASSWORD" -out "$TMP_BACKUP"
else
    log "Creating compressed backup (no encryption)"
    tar -cf - -C "$(dirname "$BACKUP_SOURCE")" "$(basename "$BACKUP_SOURCE")" | \
        pigz -$COMPRESSION_LEVEL > "$TMP_BACKUP"
fi

# Calculate backup size
BACKUP_SIZE=$(du -h "$TMP_BACKUP" | awk '{print $1}')
log "Backup created: $TMP_BACKUP ($BACKUP_SIZE)"

# Upload to S3
log "Uploading backup to S3: $BACKUP_DEST$BACKUP_NAME"
if aws s3 cp "$TMP_BACKUP" "$BACKUP_DEST$BACKUP_NAME"; then
    log "Successfully uploaded backup to S3"
    
    # Upload a latest symlink for easy reference
    aws s3 cp "$TMP_BACKUP" "$BACKUP_DEST/latest_backup.tar.gz" --quiet
    log "Updated latest_backup symlink"
else
    log "Error: Failed to upload backup to S3"
    rm -rf "$TMP_DIR"
    exit 1
fi

# Cleanup
rm -rf "$TMP_DIR"
log "Backup process completed successfully!"

# Print summary
echo "=========================================="
echo "Backup Summary:"
echo "Source: $BACKUP_SOURCE"
echo "Destination: $BACKUP_DEST$BACKUP_NAME"
echo "Size: $BACKUP_SIZE"
echo "Time: $(date +'%Y-%m-%d %H:%M:%S')"
echo "=========================================="

#!/bin/bash
# PostgreSQL Backup Script: Create compressed backups of PostgreSQL databases
#
# Requirements:
#   - psql client must be installed
#   - pg_dump must be available
#   - Proper database credentials
#
# Usage:
#   ./postgres-backup.sh <db-name> <backup-directory>
#   ./postgres-backup.sh my_db /backups/postgres/

set -eo pipefail

# Configuration
DB_USER="${DB_USER:-postgres}"
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
BACKUP_RETENTION_DAYS="7"
COMPRESS_WITH_GZIP="true"

# Function to show usage
usage() {
    echo "PostgreSQL Backup Script"
    echo ""
    echo "Usage: $0 <database-name> <backup-directory>"
    echo ""
    echo "Environment Variables:"
    echo "  DB_USER       - Database username (default: postgres)"
    echo "  DB_HOST       - Database host (default: localhost)"
    echo "  DB_PORT       - Database port (default: 5432)"
    echo "  BACKUP_RETENTION_DAYS - Days to keep backups (default: 7)"
    echo ""
    echo "Example:"
    echo "  DB_USER=admin DB_HOST=db.example.com $0 my_prod_db /backups/"
    exit 1
}

# Check arguments
if [ $# -ne 2 ]; then
    usage
fi

DB_NAME="$1"
BACKUP_DIR="$2"

# Validate backup directory
if [ ! -d "$BACKUP_DIR" ]; then
    echo "Creating backup directory: $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
fi

# Function to log messages
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Check required commands
if ! command -v pg_dump &> /dev/null; then
    echo "Error: pg_dump not found. Please install PostgreSQL client tools."
    exit 1
fi

if ! command -v psql &> /dev/null; then
    echo "Error: psql not found. Please install PostgreSQL client tools."
    exit 1
fi

# Test database connection
log "Testing connection to PostgreSQL: $DB_HOST:$DB_PORT"
if ! PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "\q" > /dev/null 2>&1; then
    echo "Error: Could not connect to database $DB_NAME"
    exit 1
fi

# Create backup filename
BACKUP_FILENAME="${DB_NAME}_backup_$(date +%Y%m%d_%H%M%S).sql"
if [ "$COMPRESS_WITH_GZIP" = "true" ]; then
    BACKUP_FILENAME="${BACKUP_FILENAME}.gz"
fi
FULL_BACKUP_PATH="${BACKUP_DIR}/${BACKUP_FILENAME}"

# Create backup
log "Starting backup of database: $DB_NAME"

set +o pipefail
if [ "$COMPRESS_WITH_GZIP" = "true" ]; then
    PGPASSWORD="$DB_PASSWORD" pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "$DB_NAME" | gzip -9 > "$FULL_BACKUP_PATH"
else
    PGPASSWORD="$DB_PASSWORD" pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "$DB_NAME" > "$FULL_BACKUP_PATH"
fi
set -o pipefail

if [ $? -eq 0 ]; then
    BACKUP_SIZE=$(du -h "$FULL_BACKUP_PATH" | awk '{print $1}')
    log "Successfully created backup: $FULL_BACKUP_PATH ($BACKUP_SIZE)"
else
    log "Error: Backup failed"
    rm -f "$FULL_BACKUP_PATH"
    exit 1
fi

# Clean up old backups
log "Cleaning up backups older than $BACKUP_RETENTION_DAYS days"
find "$BACKUP_DIR" -name "${DB_NAME}_backup_*.sql*" -type f -mtime +$BACKUP_RETENTION_DAYS -delete

# Print summary
BACKUP_SIZE=$(du -h "$FULL_BACKUP_PATH" | awk '{print $1}')
echo "=========================================="
echo "PostgreSQL Backup Complete!"
echo "Database: $DB_NAME"
echo "Backup File: $BACKUP_FILENAME"
echo "Size: $BACKUP_SIZE"
echo "Location: $FULL_BACKUP_PATH"
echo "Retention: $BACKUP_RETENTION_DAYS days"
echo "Time: $(date +'%Y-%m-%d %H:%M:%S')"
echo "=========================================="

# Optional: Upload to S3 (uncomment and configure)
# aws s3 cp "$FULL_BACKUP_PATH" "s3://your-backup-bucket/postgres/"

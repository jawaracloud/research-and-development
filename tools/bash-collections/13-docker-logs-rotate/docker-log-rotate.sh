#!/bin/bash
# Docker Logs Rotation Script: Clean up and rotate Docker container logs
#
# Requirements:
#   - Docker must be installed and running
#   - Script must be run as root or with docker permissions
#
# Usage:
#   ./docker-log-rotate.sh [max-size-mb] [max-files]

set -eo pipefail

# Configuration
MAX_SIZE_MB="${1:-100}"  # Default: 100MB per log file
MAX_FILES="${2:-5}"      # Default: Keep last 5 logs
LOG_DIR="/var/lib/docker/containers"

# Function to log messages
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Validate numeric inputs
if ! [[ "$MAX_SIZE_MB" =~ ^[0-9]+$ ]]; then
    echo "Error: max-size must be a number"
    exit 1
fi

if ! [[ "$MAX_FILES" =~ ^[0-9]+$ ]]; then
    echo "Error: max-files must be a number"
    exit 1
fi

log "Starting Docker log rotation policy: $MAX_SIZE_MB MB per file, keeping last $MAX_FILES logs"

# Check if Docker is running
if ! systemctl is-active --quiet docker; then
    log "Docker service is not running"
    exit 1
fi

# Find all container log files
log_count=0
files_removed=0

while IFS= read -r -d $'\0' log_file; do
    # Skip if file doesn't exist
    [ -f "$log_file" ] || continue
    
    # Get current size in MB
    current_size=$(du -m "$log_file" | cut -f1)
    
    if [ "$current_size" -ge "$MAX_SIZE_MB" ]; then
        log "Rotating logs for: $log_file ($current_size MB)"
        
        # Create backup of current log
        backup_file="${log_file}.$(date +%Y%m%d_%H%M%S)"
        cp "$log_file" "$backup_file"
        
        # Truncate the original log
        > "$log_file"
        
        # Compress old backup
        gzip "$backup_file"
        
        # Cleanup old log files
        log_files=$(ls -1 "${log_file}".* 2>/dev/null | gzip -l | head -n -$MAX_FILES | tail -n +2 || true)
        if [ -n "$log_files" ]; then
            log "Removing old log files: $log_files"
            rm -f ${log_files}
            files_removed=$((files_removed + $(echo "$log_files" | wc -l)))
        fi
        log_count=$((log_count + 1))
    fi
done < <(find "$LOG_DIR" -type f -name "*-json.log" -print0)

# Also clean up old compressed logs
log "Cleaning up old compressed logs older than 30 days"
find "$LOG_DIR" -type f -name "*-json.log.*.gz" -mtime +30 -delete

log "Log rotation complete! Rotated $log_count containers, removed $files_removed old log files"

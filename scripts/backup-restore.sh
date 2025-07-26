#!/bin/bash
set -e

echo "Restoring from latest backup..."

# Get the latest backup name
LATEST_BACKUP=$(wal-g backup-list | tail -n 1 | awk '{print $1}')

if [ -z "$LATEST_BACKUP" ]; then
    echo "No backups found. Please create a backup first."
    exit 1
fi

echo "Restoring from backup: $LATEST_BACKUP"

# Restore from the latest backup
wal-g backup-fetch /backups/restored_data $LATEST_BACKUP

echo "Restore completed successfully."
echo "Restored data is available in /backups/restored_data" 
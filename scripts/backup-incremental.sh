#!/bin/bash
set -e

echo "Creating incremental backup with WAL-G..."

# Create incremental backup
wal-g backup-push /var/lib/postgresql/data --delta-from-name $(wal-g backup-list | tail -n 1 | awk '{print $1}')

echo "Incremental backup completed successfully."
echo "Backup timestamp: $(date)" 
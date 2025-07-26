#!/bin/bash
set -e

echo "Creating full backup with WAL-G..."

# Create full backup
wal-g backup-push /var/lib/postgresql/data

echo "Full backup completed successfully."
echo "Backup timestamp: $(date)" 
#!/bin/bash
set -e

echo "Testing WAL-G restore functionality..."

# Get the latest backup name
LATEST_BACKUP=$(docker-compose exec -e PGUSER=postgres -e PGPASSWORD=postgres -e PGDATABASE=testdb postgres wal-g backup-list | tail -n 1 | awk '{print $1}')

if [ -z "$LATEST_BACKUP" ]; then
    echo "No backups found. Please create a backup first."
    exit 1
fi

echo "Restoring from backup: $LATEST_BACKUP"

# Create a temporary directory for restore
RESTORE_DIR="/tmp/walg_restore_test_$(date +%s)"
docker-compose exec postgres mkdir -p $RESTORE_DIR

# Restore the backup
docker-compose exec -e PGUSER=postgres -e PGPASSWORD=postgres -e PGDATABASE=testdb postgres wal-g backup-fetch $RESTORE_DIR $LATEST_BACKUP

echo "Backup restored to: $RESTORE_DIR"
echo "Restore test completed successfully."
echo ""
echo "To verify the restore manually, you can:"
echo "1. Stop the current PostgreSQL container"
echo "2. Replace the data directory with the restored data"
echo "3. Start PostgreSQL and check the data"
echo ""
echo "Restored data location: $RESTORE_DIR" 
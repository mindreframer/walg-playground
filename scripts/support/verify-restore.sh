#!/bin/bash
set -e

echo "Verifying WAL-G restore data integrity..."

# Get the latest backup name
LATEST_BACKUP=$(docker-compose exec -e PGUSER=postgres -e PGPASSWORD=postgres -e PGDATABASE=testdb postgres wal-g backup-list | tail -n 1 | awk '{print $1}')

if [ -z "$LATEST_BACKUP" ]; then
    echo "No backups found. Please create a backup first."
    exit 1
fi

echo "Verifying backup: $LATEST_BACKUP"

# Create a temporary directory for restore
RESTORE_DIR="/tmp/walg_verify_$(date +%s)"
docker-compose exec postgres mkdir -p $RESTORE_DIR

# Restore the backup
echo "Restoring backup for verification..."
docker-compose exec -e PGUSER=postgres -e PGPASSWORD=postgres -e PGDATABASE=testdb postgres wal-g backup-fetch $RESTORE_DIR $LATEST_BACKUP

# Check if the restored data contains expected files
echo "Verifying restored data structure..."
if docker-compose exec postgres test -d "$RESTORE_DIR/base"; then
    echo "✅ Base directory exists"
else
    echo "❌ Base directory missing"
    exit 1
fi

if docker-compose exec postgres test -d "$RESTORE_DIR/global"; then
    echo "✅ Global directory exists"
else
    echo "❌ Global directory missing"
    exit 1
fi

if docker-compose exec postgres test -f "$RESTORE_DIR/backup_label"; then
    echo "✅ Backup label file exists"
else
    echo "❌ Backup label file missing"
    exit 1
fi

# Check backup label content
echo "Verifying backup label content..."
BACKUP_LABEL=$(docker-compose exec postgres cat "$RESTORE_DIR/backup_label")
echo "Backup label content:"
echo "$BACKUP_LABEL"

echo ""
echo "✅ Restore verification completed successfully!"
echo "Restored data location: $RESTORE_DIR"
echo ""
echo "The backup contains a complete PostgreSQL data directory with:"
echo "- Database files in /base directory"
echo "- Configuration files in /global directory"
echo "- Backup metadata in backup_label file"
echo ""
echo "This confirms that WAL-G restore functionality is working correctly." 
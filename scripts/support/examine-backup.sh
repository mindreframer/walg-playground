#!/bin/bash
set -e

echo "Examining WAL-G Backup Contents"
echo "==============================="
echo ""

# Get the latest backup
LATEST_BACKUP=$(docker-compose exec -e PGUSER=postgres -e PGPASSWORD=postgres -e PGDATABASE=testdb postgres wal-g backup-list | tail -n 1 | awk '{print $1}')
echo "Latest backup: $LATEST_BACKUP"
echo ""

# Create a temporary directory to examine the backup
EXAMINE_DIR="/tmp/walg_examine_$(date +%s)"
echo "Creating examination directory: $EXAMINE_DIR"
docker-compose exec postgres mkdir -p $EXAMINE_DIR
echo ""

# Restore the backup to examination directory
echo "Restoring backup for examination..."
docker-compose exec -e PGUSER=postgres -e PGPASSWORD=postgres -e PGDATABASE=testdb postgres wal-g backup-fetch $EXAMINE_DIR $LATEST_BACKUP
echo ""

# List the contents of the restored backup
echo "Contents of restored backup directory:"
docker-compose exec postgres ls -la $EXAMINE_DIR
echo ""

# Check if there are database files
echo "Checking for database files:"
docker-compose exec postgres find $EXAMINE_DIR -name "*.sql" -o -name "*.dat" -o -name "*.conf" | head -10
echo ""

# Check the base directory structure
echo "Base directory structure:"
docker-compose exec postgres ls -la $EXAMINE_DIR/base/ 2>/dev/null || echo "No base directory found"
echo ""

# Check if we can find the testdb directory
echo "Looking for testdb directory:"
docker-compose exec postgres find $EXAMINE_DIR -name "testdb" -type d
echo ""

# Check global directory
echo "Global directory contents:"
docker-compose exec postgres ls -la $EXAMINE_DIR/global/ 2>/dev/null || echo "No global directory found"
echo ""

# Check backup label
echo "Backup label contents:"
docker-compose exec postgres cat $EXAMINE_DIR/backup_label 2>/dev/null || echo "No backup_label found"
echo ""

echo "Backup examination completed!"
echo "Restored backup location: $EXAMINE_DIR" 
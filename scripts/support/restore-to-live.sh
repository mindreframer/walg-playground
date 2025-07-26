#!/bin/bash
set -e

echo "Restoring WAL-G backup to live PostgreSQL instance..."

# Get the latest backup name
LATEST_BACKUP=$(docker-compose exec -e PGUSER=postgres -e PGPASSWORD=postgres -e PGDATABASE=testdb postgres wal-g backup-list | tail -n 1 | awk '{print $1}')

if [ -z "$LATEST_BACKUP" ]; then
    echo "No backups found. Please create a backup first."
    exit 1
fi

echo "Restoring from backup: $LATEST_BACKUP"

# Create a temporary directory for restore
RESTORE_DIR="/tmp/walg_live_restore_$(date +%s)"
docker-compose exec postgres mkdir -p $RESTORE_DIR

# Restore the backup
echo "Restoring backup..."
docker-compose exec -e PGUSER=postgres -e PGPASSWORD=postgres -e PGDATABASE=testdb postgres wal-g backup-fetch $RESTORE_DIR $LATEST_BACKUP

echo "Backup restored to: $RESTORE_DIR"

# Stop the current PostgreSQL container
echo "Stopping current PostgreSQL container..."
docker-compose stop postgres

# Backup the current data directory
echo "Backing up current data directory..."
docker-compose exec postgres mv /var/lib/postgresql/data /var/lib/postgresql/data_backup_$(date +%s) 2>/dev/null || true

# Copy the restored data to the PostgreSQL data directory
echo "Copying restored data to PostgreSQL data directory..."
docker-compose exec postgres cp -r $RESTORE_DIR /var/lib/postgresql/data

# Fix permissions
echo "Fixing permissions..."
docker-compose exec postgres chown -R postgres:postgres /var/lib/postgresql/data

# Start PostgreSQL with the restored data
echo "Starting PostgreSQL with restored data..."
docker-compose start postgres

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL to be ready..."
sleep 10

# Test the connection
echo "Testing connection to restored database..."
docker-compose exec postgres pg_isready -U postgres

echo ""
echo "✅ PostgreSQL is now running with the restored backup data!"
echo ""
echo "You can now connect to the database to verify the restored data:"
echo "  make db-connect"
echo ""
echo "Or run specific queries to check the data:"
echo "  docker-compose exec postgres psql -U postgres -d testdb -c \"SELECT COUNT(*) FROM test_data;\""
echo "  docker-compose exec postgres psql -U postgres -d testdb -c \"SELECT * FROM test_data ORDER BY id DESC LIMIT 5;\""
echo ""
echo "To restore the original data, run:"
echo "  docker-compose stop postgres"
echo "  docker-compose exec postgres rm -rf /var/lib/postgresql/data"
echo "  docker-compose exec postgres mv /var/lib/postgresql/data_backup_* /var/lib/postgresql/data"
echo "  docker-compose start postgres" 
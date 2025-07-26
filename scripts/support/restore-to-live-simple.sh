#!/bin/bash
set -e

echo "Restoring WAL-G backup to live PostgreSQL instance (Simple Method)..."

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

# Create a new PostgreSQL container with the restored data
echo "Creating new PostgreSQL container with restored data..."
RESTORE_PATH=$(docker-compose exec postgres realpath $RESTORE_DIR)
echo "Restore path: $RESTORE_PATH"
docker run --rm -d \
  --name walg-restored-postgres \
  --network walg-playground_default \
  -e POSTGRES_DB=testdb \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -v "$RESTORE_PATH:/var/lib/postgresql/data" \
  -p 5433:5432 \
  walg-playground-postgres

echo "Waiting for restored PostgreSQL to be ready..."
sleep 15

# Test the connection
echo "Testing connection to restored database..."
docker exec walg-restored-postgres pg_isready -U postgres

echo ""
echo "✅ PostgreSQL is now running with the restored backup data!"
echo ""
echo "Connection details:"
echo "  Host: localhost"
echo "  Port: 5433"
echo "  Database: testdb"
echo "  User: postgres"
echo "  Password: postgres"
echo ""
echo "You can now connect to verify the restored data:"
echo "  docker exec -it walg-restored-postgres psql -U postgres -d testdb"
echo ""
echo "Or run specific queries:"
echo "  docker exec walg-restored-postgres psql -U postgres -d testdb -c \"SELECT COUNT(*) FROM test_data;\""
echo "  docker exec walg-restored-postgres psql -U postgres -d testdb -c \"SELECT * FROM test_data ORDER BY id DESC LIMIT 5;\""
echo ""
echo "To stop the restored instance:"
echo "  docker stop walg-restored-postgres"
echo ""
echo "To restart the original PostgreSQL:"
echo "  docker-compose start postgres" 
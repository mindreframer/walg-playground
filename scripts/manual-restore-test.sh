#!/bin/bash
set -e

echo "Manual WAL-G Restore Test Instructions"
echo "======================================"
echo ""

# Get the latest backup name
LATEST_BACKUP=$(docker-compose exec -e PGUSER=postgres -e PGPASSWORD=postgres -e PGDATABASE=testdb postgres wal-g backup-list | tail -n 1 | awk '{print $1}')

if [ -z "$LATEST_BACKUP" ]; then
    echo "No backups found. Please create a backup first."
    exit 1
fi

echo "Latest backup: $LATEST_BACKUP"
echo ""

echo "Step 1: Restore the backup to a temporary directory"
echo "---------------------------------------------------"
RESTORE_DIR="/tmp/walg_manual_restore_$(date +%s)"
echo "Restore directory: $RESTORE_DIR"
echo ""

echo "Running: docker-compose exec -e PGUSER=postgres -e PGPASSWORD=postgres -e PGDATABASE=testdb postgres wal-g backup-fetch $RESTORE_DIR $LATEST_BACKUP"
docker-compose exec -e PGUSER=postgres -e PGPASSWORD=postgres -e PGDATABASE=testdb postgres wal-g backup-fetch $RESTORE_DIR $LATEST_BACKUP

echo ""
echo "Step 2: Stop the current PostgreSQL container"
echo "---------------------------------------------"
echo "Running: docker-compose stop postgres"
docker-compose stop postgres

echo ""
echo "Step 3: Create a new PostgreSQL container with restored data"
echo "-----------------------------------------------------------"
echo "Running: docker run --rm -d --name walg-restored-postgres --network walg-playground_default -e POSTGRES_DB=testdb -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres -v $RESTORE_DIR:/var/lib/postgresql/data -p 5434:5432 walg-playground-postgres"

docker run --rm -d \
  --name walg-restored-postgres \
  --network walg-playground_default \
  -e POSTGRES_DB=testdb \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -v "$RESTORE_DIR:/var/lib/postgresql/data" \
  -p 5434:5432 \
  walg-playground-postgres

echo ""
echo "Step 4: Wait for PostgreSQL to be ready"
echo "---------------------------------------"
echo "Waiting 15 seconds for PostgreSQL to start..."
sleep 15

echo ""
echo "Step 5: Test the connection"
echo "---------------------------"
echo "Running: docker exec walg-restored-postgres pg_isready -U postgres"
docker exec walg-restored-postgres pg_isready -U postgres

echo ""
echo "✅ PostgreSQL is now running with the restored backup data!"
echo ""
echo "Connection details:"
echo "  Host: localhost"
echo "  Port: 5434"
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
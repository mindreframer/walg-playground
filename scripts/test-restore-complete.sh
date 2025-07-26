#!/bin/bash
set -e

echo "Complete WAL-G Restore Test"
echo "=========================="
echo ""

# Step 1: Check current database state
echo "Step 1: Checking current database state..."
echo "Running: docker-compose exec postgres psql -U postgres -d testdb -c '\d'"
docker-compose exec postgres psql -U postgres -d testdb -c "\d"
echo ""

# Step 2: Create a new backup
echo "Step 2: Creating a new backup..."
echo "Running: make backup-full"
make backup-full
echo ""

# Step 3: List available backups
echo "Step 3: Listing available backups..."
echo "Running: docker-compose exec -e PGUSER=postgres -e PGPASSWORD=postgres -e PGDATABASE=testdb postgres wal-g backup-list"
docker-compose exec -e PGUSER=postgres -e PGPASSWORD=postgres -e PGDATABASE=testdb postgres wal-g backup-list
echo ""

# Step 4: Get the latest backup name
echo "Step 4: Getting latest backup name..."
LATEST_BACKUP=$(docker-compose exec -e PGUSER=postgres -e PGPASSWORD=postgres -e PGDATABASE=testdb postgres wal-g backup-list | tail -n 1 | awk '{print $1}')
echo "Latest backup: $LATEST_BACKUP"
echo ""

# Step 5: Restore the backup
echo "Step 5: Restoring backup to temporary directory..."
RESTORE_DIR="/tmp/walg_test_restore_$(date +%s)"
echo "Restore directory: $RESTORE_DIR"
docker-compose exec -e PGUSER=postgres -e PGPASSWORD=postgres -e PGDATABASE=testdb postgres wal-g backup-fetch $RESTORE_DIR $LATEST_BACKUP
echo ""

# Step 6: Stop current PostgreSQL
echo "Step 6: Stopping current PostgreSQL..."
docker-compose stop postgres
echo ""

# Step 7: Create new container with restored data
echo "Step 7: Creating new PostgreSQL container with restored data..."
docker run --rm -d \
  --name walg-test-restored \
  --network walg-playground_default \
  -e POSTGRES_DB=testdb \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -v "$RESTORE_DIR:/var/lib/postgresql/data" \
  -p 5435:5432 \
  walg-playground-postgres
echo ""

# Step 8: Wait for PostgreSQL to be ready
echo "Step 8: Waiting for PostgreSQL to be ready..."
sleep 15
echo ""

# Step 9: Test connection
echo "Step 9: Testing connection..."
docker exec walg-test-restored pg_isready -U postgres
echo ""

# Step 10: Check restored database structure
echo "Step 10: Checking restored database structure..."
echo "Running: docker exec walg-test-restored psql -U postgres -d testdb -c '\d'"
docker exec walg-test-restored psql -U postgres -d testdb -c "\d"
echo ""

# Step 11: Check data in tables
echo "Step 11: Checking data in tables..."
echo "Running: docker exec walg-test-restored psql -U postgres -d testdb -c 'SELECT COUNT(*) FROM test_data;'"
docker exec walg-test-restored psql -U postgres -d testdb -c "SELECT COUNT(*) FROM test_data;"
echo ""

echo "✅ Restore test completed!"
echo ""
echo "Connection details for restored database:"
echo "  Host: localhost"
echo "  Port: 5435"
echo "  Database: testdb"
echo "  User: postgres"
echo "  Password: postgres"
echo ""
echo "To connect to the restored database:"
echo "  docker exec -it walg-test-restored psql -U postgres -d testdb"
echo ""
echo "To stop the test container:"
echo "  docker stop walg-test-restored"
echo ""
echo "To restart the original PostgreSQL:"
echo "  docker-compose start postgres" 
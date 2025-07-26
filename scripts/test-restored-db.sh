#!/bin/bash
set -e

echo "Testing Restored Database"
echo "========================"
echo ""

# Get the latest backup
LATEST_BACKUP=$(docker-compose exec -e PGUSER=postgres -e PGPASSWORD=postgres -e PGDATABASE=testdb postgres wal-g backup-list | tail -n 1 | awk '{print $1}')
echo "Latest backup: $LATEST_BACKUP"
echo ""

# Create a temporary directory for restore
RESTORE_DIR="/tmp/walg_test_restored_db_$(date +%s)"
echo "Restore directory: $RESTORE_DIR"
docker-compose exec postgres mkdir -p $RESTORE_DIR
echo ""

# Restore the backup
echo "Restoring backup..."
docker-compose exec -e PGUSER=postgres -e PGPASSWORD=postgres -e PGDATABASE=testdb postgres wal-g backup-fetch $RESTORE_DIR $LATEST_BACKUP
echo ""

# Stop current PostgreSQL
echo "Stopping current PostgreSQL..."
docker-compose stop postgres
echo ""

# Create new container with restored data
echo "Creating new PostgreSQL container with restored data..."
docker run --rm -d \
  --name walg-test-restored-db \
  --network walg-playground_default \
  -e POSTGRES_DB=testdb \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -v "$RESTORE_DIR:/var/lib/postgresql/data" \
  -p 5436:5432 \
  walg-playground-postgres
echo ""

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL to be ready..."
sleep 15
echo ""

# Test connection
echo "Testing connection..."
docker exec walg-test-restored-db pg_isready -U postgres
echo ""

# Check all databases
echo "All databases in restored instance:"
docker exec walg-test-restored-db psql -U postgres -c "\l"
echo ""

# Check tables in testdb
echo "Tables in testdb:"
docker exec walg-test-restored-db psql -U postgres -d testdb -c "\d"
echo ""

# Check if backup_test table exists
echo "Checking if backup_test table exists:"
docker exec walg-test-restored-db psql -U postgres -d testdb -c "\d backup_test" 2>/dev/null || echo "backup_test table does not exist"
echo ""

# Check test_data table
echo "Checking test_data table:"
docker exec walg-test-restored-db psql -U postgres -d testdb -c "\d test_data"
echo ""

# Check data in tables
echo "Data in test_data table:"
docker exec walg-test-restored-db psql -U postgres -d testdb -c "SELECT COUNT(*) FROM test_data;"
echo ""

# Try to query backup_test if it exists
echo "Trying to query backup_test table:"
docker exec walg-test-restored-db psql -U postgres -d testdb -c "SELECT COUNT(*) FROM backup_test;" 2>/dev/null || echo "Cannot query backup_test table"
echo ""

echo "✅ Restored database test completed!"
echo ""
echo "Connection details:"
echo "  Host: localhost"
echo "  Port: 5436"
echo "  Database: testdb"
echo "  User: postgres"
echo "  Password: postgres"
echo ""
echo "To connect to the restored database:"
echo "  docker exec -it walg-test-restored-db psql -U postgres -d testdb"
echo ""
echo "To stop the test container:"
echo "  docker stop walg-test-restored-db"
echo ""
echo "To restart the original PostgreSQL:"
echo "  docker-compose start postgres" 
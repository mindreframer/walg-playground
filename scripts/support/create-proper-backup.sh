#!/bin/bash
set -e

echo "Creating Proper WAL-G Backup"
echo "============================"
echo ""

# Ensure PostgreSQL is running
echo "1. Ensuring PostgreSQL is running..."
docker-compose start postgres
sleep 10
echo ""

# Check current database state
echo "2. Current database state:"
docker-compose exec postgres psql -U postgres -d testdb -c "\d"
echo ""

# Create backup_test table with explicit transaction
echo "3. Creating backup_test table with explicit transaction..."
docker-compose exec postgres psql -U postgres -d testdb -c "
BEGIN;
DROP TABLE IF EXISTS backup_test CASCADE;
CREATE TABLE backup_test (
    id SERIAL PRIMARY KEY,
    description VARCHAR(200),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO backup_test (description) VALUES 
('Proper backup test record 1'),
('Proper backup test record 2'),
('Proper backup test record 3');
COMMIT;
"
echo ""

# Verify the table was created
echo "4. Verifying table creation:"
docker-compose exec postgres psql -U postgres -d testdb -c "\d"
echo ""

# Check the data
echo "5. Checking backup_test data:"
docker-compose exec postgres psql -U postgres -d testdb -c "SELECT COUNT(*) FROM backup_test;"
echo ""

# Force a checkpoint to ensure all data is written
echo "6. Forcing checkpoint..."
docker-compose exec postgres psql -U postgres -c "CHECKPOINT;"
echo ""

# Wait a moment for the checkpoint to complete
echo "7. Waiting for checkpoint to complete..."
sleep 5
echo ""

# Create backup
echo "8. Creating backup with all tables..."
make backup-full
echo ""

# List backups
echo "9. Listing backups:"
docker-compose exec -e PGUSER=postgres -e PGPASSWORD=postgres -e PGDATABASE=testdb postgres wal-g backup-list
echo ""

echo "✅ Proper backup creation completed!" 
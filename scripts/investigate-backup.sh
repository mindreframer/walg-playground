#!/bin/bash
set -e

echo "Investigating WAL-G Backup Contents"
echo "=================================="
echo ""

# Check current database state
echo "1. Current database state:"
docker-compose exec postgres psql -U postgres -d testdb -c "\d"
echo ""

# Check if we're in the right database
echo "2. Current database name:"
docker-compose exec postgres psql -U postgres -d testdb -c "SELECT current_database();"
echo ""

# Check all databases
echo "3. All databases:"
docker-compose exec postgres psql -U postgres -c "\l"
echo ""

# Check if backup_test table exists in the current database
echo "4. Checking backup_test table structure:"
docker-compose exec postgres psql -U postgres -d testdb -c "\d backup_test"
echo ""

# Check table data
echo "5. Checking backup_test table data:"
docker-compose exec postgres psql -U postgres -d testdb -c "SELECT COUNT(*) FROM backup_test;"
echo ""

# Create a fresh backup_test table to ensure it's in the right place
echo "6. Dropping and recreating backup_test table:"
docker-compose exec postgres psql -U postgres -d testdb -c "DROP TABLE IF EXISTS backup_test CASCADE;"
docker-compose exec postgres psql -U postgres -d testdb -c "
CREATE TABLE backup_test (
    id SERIAL PRIMARY KEY,
    description VARCHAR(200),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);"
docker-compose exec postgres psql -U postgres -d testdb -c "
INSERT INTO backup_test (description) VALUES 
('Fresh backup test record 1'),
('Fresh backup test record 2'),
('Fresh backup test record 3');"
echo ""

# Verify the table was created
echo "7. Verifying table creation:"
docker-compose exec postgres psql -U postgres -d testdb -c "\d"
echo ""

# Create backup
echo "8. Creating backup with fresh table:"
make backup-full
echo ""

# List backups
echo "9. Listing backups:"
docker-compose exec -e PGUSER=postgres -e PGPASSWORD=postgres -e PGDATABASE=testdb postgres wal-g backup-list
echo ""

echo "Investigation completed!" 
#!/bin/bash
set -e

echo "Preparing database for backup..."

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL to be ready..."
sleep 10

# Create backup_test table with proper structure
echo "Creating backup_test table..."
docker-compose exec postgres psql -U postgres -d testdb -c "
CREATE TABLE IF NOT EXISTS backup_test (
    id SERIAL PRIMARY KEY,
    description VARCHAR(200),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);"

# Insert test data into backup_test
echo "Inserting test data into backup_test..."
docker-compose exec postgres psql -U postgres -d testdb -c "
INSERT INTO backup_test (description) VALUES 
('Backup test record 1'),
('Backup test record 2'),
('Backup test record 3')
ON CONFLICT DO NOTHING;"

# Show all tables
echo "Current database tables:"
docker-compose exec postgres psql -U postgres -d testdb -c "\d"

# Create backup
echo "Creating backup with all tables..."
make backup-full

echo "Backup preparation completed!" 
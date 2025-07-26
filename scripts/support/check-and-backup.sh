#!/bin/bash
set -e

echo "Checking current database structure and creating backup..."

# Check if backup_test table exists and its structure
echo "Checking backup_test table structure..."
docker-compose exec postgres psql -U postgres -d testdb -c "\d backup_test" 2>/dev/null || echo "backup_test table does not exist or cannot be accessed"

# Create backup_test table if it doesn't exist
echo "Creating backup_test table if it doesn't exist..."
docker-compose exec postgres psql -U postgres -d testdb -c "CREATE TABLE IF NOT EXISTS backup_test (id SERIAL PRIMARY KEY, description VARCHAR(200), created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);"

# Insert test data
echo "Inserting test data into backup_test..."
docker-compose exec postgres psql -U postgres -d testdb -c "INSERT INTO backup_test (description) VALUES ('Backup test record 1'), ('Backup test record 2'), ('Backup test record 3');"

# Show current tables
echo "Current tables in database:"
docker-compose exec postgres psql -U postgres -d testdb -c "\d"

# Create a new backup
echo "Creating new backup with all tables..."
make backup-full

echo "Backup completed successfully!" 
#!/bin/bash
set -e

echo "Creating fresh database with backup_test table..."

# Stop PostgreSQL
echo "Stopping PostgreSQL..."
docker-compose stop postgres

# Remove the data directory to start fresh
echo "Removing existing data directory..."
docker-compose exec postgres rm -rf /var/lib/postgresql/data/* 2>/dev/null || true

# Start PostgreSQL fresh
echo "Starting PostgreSQL fresh..."
docker-compose start postgres

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL to be ready..."
sleep 15

# Create the test database (drop if exists)
echo "Creating test database..."
docker-compose exec postgres psql -U postgres -c "DROP DATABASE IF EXISTS testdb;"
docker-compose exec postgres psql -U postgres -c "CREATE DATABASE testdb;"

# Create backup_test table
echo "Creating backup_test table..."
docker-compose exec postgres psql -U postgres -d testdb -c "
CREATE TABLE backup_test (
    id SERIAL PRIMARY KEY,
    description VARCHAR(200),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);"

# Insert test data
echo "Inserting test data..."
docker-compose exec postgres psql -U postgres -d testdb -c "
INSERT INTO backup_test (description) VALUES 
('Fresh backup test record 1'),
('Fresh backup test record 2'),
('Fresh backup test record 3');"

# Create test_data table and insert data
echo "Creating test_data table..."
docker-compose exec postgres psql -U postgres -d testdb -c "
CREATE TABLE test_data (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);"

docker-compose exec postgres psql -U postgres -d testdb -c "
INSERT INTO test_data (name) VALUES 
('Fresh test record 1'),
('Fresh test record 2'),
('Fresh test record 3');"

# Show all tables
echo "Current database tables:"
docker-compose exec postgres psql -U postgres -d testdb -c "\d"

# Create backup
echo "Creating backup with all tables..."
make backup-full

echo "Fresh backup completed!" 
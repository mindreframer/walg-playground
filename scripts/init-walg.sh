#!/bin/bash
set -e

echo "Initializing PostgreSQL with WAL-G configuration..."

# Create a test table
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE TABLE IF NOT EXISTS test_data (
        id SERIAL PRIMARY KEY,
        name VARCHAR(100),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    
    INSERT INTO test_data (name) VALUES 
        ('Initial test record 1'),
        ('Initial test record 2'),
        ('Initial test record 3');
EOSQL

echo "PostgreSQL initialization completed." 
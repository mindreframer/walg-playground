#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test configuration
TEST_TABLE="backup_validation_test"
BACKUP_NAME=""
RESTORE_PATH="/backups/validation_restore"

echo -e "${YELLOW}Starting WAL-G Backup Validation Test${NC}"
echo "======================================"

# Function to execute SQL in PostgreSQL
execute_sql() {
    docker-compose exec -T postgres psql -U postgres -d testdb -c "$1"
}

# Function to execute SQL and get result
execute_sql_result() {
    docker-compose exec -T postgres psql -U postgres -d testdb -t -c "$1" | xargs
}

# Step 1: Create test table and insert initial data
echo -e "${YELLOW}Step 1: Creating test table and inserting initial data...${NC}"
execute_sql "DROP TABLE IF EXISTS $TEST_TABLE;"
execute_sql "CREATE TABLE $TEST_TABLE (id SERIAL PRIMARY KEY, name VARCHAR(50), created_at TIMESTAMP DEFAULT NOW());"
execute_sql "INSERT INTO $TEST_TABLE (name) VALUES ('user1'), ('user2'), ('user3');"

# Verify initial data
INITIAL_COUNT=$(execute_sql_result "SELECT COUNT(*) FROM $TEST_TABLE;")
echo "Initial record count: $INITIAL_COUNT"

if [ "$INITIAL_COUNT" != "3" ]; then
    echo -e "${RED}FAILED: Expected 3 initial records, got $INITIAL_COUNT${NC}"
    exit 1
fi

# Step 2: Create backup
echo -e "${YELLOW}Step 2: Creating full backup...${NC}"
docker-compose exec -T postgres wal-g backup-push /var/lib/postgresql/data

# Get the backup name (latest backup)
BACKUP_NAME=$(docker-compose exec -T postgres wal-g backup-list | tail -n 1 | awk '{print $1}')
echo "Created backup: $BACKUP_NAME"

if [ -z "$BACKUP_NAME" ]; then
    echo -e "${RED}FAILED: No backup was created${NC}"
    exit 1
fi

# Step 3: Add more data (this should NOT be in the backup)
echo -e "${YELLOW}Step 3: Adding additional data (post-backup)...${NC}"
execute_sql "INSERT INTO $TEST_TABLE (name) VALUES ('user4'), ('user5'), ('user6'), ('user7');"

# Verify we now have more records
CURRENT_COUNT=$(execute_sql_result "SELECT COUNT(*) FROM $TEST_TABLE;")
echo "Current record count: $CURRENT_COUNT"

if [ "$CURRENT_COUNT" != "7" ]; then
    echo -e "${RED}FAILED: Expected 7 records after adding data, got $CURRENT_COUNT${NC}"
    exit 1
fi

# Step 4: Simulate data loss
echo -e "${YELLOW}Step 4: Simulating data loss (dropping table)...${NC}"
execute_sql "DROP TABLE $TEST_TABLE;"

# Verify table is gone
TABLE_EXISTS=$(execute_sql_result "SELECT COUNT(*) FROM information_schema.tables WHERE table_name='$TEST_TABLE';" 2>/dev/null || echo "0")
if [ "$TABLE_EXISTS" != "0" ]; then
    echo -e "${RED}FAILED: Table still exists after drop${NC}"
    exit 1
fi
echo "Table dropped successfully"

# Step 5: Stop PostgreSQL for restore
echo -e "${YELLOW}Step 5: Stopping PostgreSQL for restore...${NC}"
docker-compose stop postgres

# Clean up any existing restore directory
docker-compose exec -T walg rm -rf $RESTORE_PATH 2>/dev/null || true

# Step 6: Restore from backup
echo -e "${YELLOW}Step 6: Restoring from backup...${NC}"
docker-compose --profile backup run --rm walg wal-g backup-fetch $RESTORE_PATH $BACKUP_NAME

# Step 7: Start a temporary PostgreSQL instance with restored data
echo -e "${YELLOW}Step 7: Starting temporary PostgreSQL with restored data...${NC}"

# Create a temporary docker-compose override for validation
cat > docker-compose.validation.yml << EOF
version: '3.8'
services:
  postgres-validation:
    build:
      context: .
      dockerfile: Dockerfile.postgres
      platforms:
        - linux/arm64
    container_name: walg-postgres-validation
    environment:
      POSTGRES_DB: testdb
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      PGUSER: postgres
      PGPASSWORD: postgres
      PGDATABASE: testdb
    volumes:
      - ./backups/validation_restore:/var/lib/postgresql/data
      - ./scripts:/scripts
    ports:
      - "5433:5432"
    command: postgres
    healthcheck:
      test: [ "CMD-SHELL", "pg_isready -U postgres" ]
      interval: 10s
      timeout: 5s
      retries: 5
EOF

# Start validation PostgreSQL instance
docker-compose -f docker-compose.validation.yml up -d postgres-validation

# Wait for PostgreSQL to be ready
echo "Waiting for validation PostgreSQL to be ready..."
for i in {1..30}; do
    if docker-compose -f docker-compose.validation.yml exec -T postgres-validation pg_isready -U postgres >/dev/null 2>&1; then
        break
    fi
    if [ $i -eq 30 ]; then
        echo -e "${RED}FAILED: Validation PostgreSQL did not start in time${NC}"
        docker-compose -f docker-compose.validation.yml down
        docker-compose start postgres
        exit 1
    fi
    sleep 2
done

# Step 8: Validate restored data
echo -e "${YELLOW}Step 8: Validating restored data...${NC}"

# Check if table exists
TABLE_EXISTS=$(docker-compose -f docker-compose.validation.yml exec -T postgres-validation psql -U postgres -d testdb -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_name='$TEST_TABLE';" | xargs)

if [ "$TABLE_EXISTS" != "1" ]; then
    echo -e "${RED}FAILED: Test table does not exist in restored database${NC}"
    docker-compose -f docker-compose.validation.yml down
    docker-compose start postgres
    exit 1
fi

# Check record count (should be 3, not 7)
RESTORED_COUNT=$(docker-compose -f docker-compose.validation.yml exec -T postgres-validation psql -U postgres -d testdb -t -c "SELECT COUNT(*) FROM $TEST_TABLE;" | xargs)
echo "Restored record count: $RESTORED_COUNT"

if [ "$RESTORED_COUNT" != "3" ]; then
    echo -e "${RED}FAILED: Expected 3 records in restored data, got $RESTORED_COUNT${NC}"
    docker-compose -f docker-compose.validation.yml down
    docker-compose start postgres
    exit 1
fi

# Check specific data (should only have user1, user2, user3)
RESTORED_USERS=$(docker-compose -f docker-compose.validation.yml exec -T postgres-validation psql -U postgres -d testdb -t -c "SELECT string_agg(name, ',') FROM $TEST_TABLE ORDER BY id;" | xargs)
EXPECTED_USERS="user1,user2,user3"

if [ "$RESTORED_USERS" != "$EXPECTED_USERS" ]; then
    echo -e "${RED}FAILED: Restored data mismatch. Expected: $EXPECTED_USERS, Got: $RESTORED_USERS${NC}"
    docker-compose -f docker-compose.validation.yml down
    docker-compose start postgres
    exit 1
fi

# Step 9: Cleanup
echo -e "${YELLOW}Step 9: Cleaning up...${NC}"
docker-compose -f docker-compose.validation.yml down
rm -f docker-compose.validation.yml
docker-compose start postgres

# Wait for original PostgreSQL to be ready
echo "Waiting for original PostgreSQL to restart..."
for i in {1..30}; do
    if docker-compose exec -T postgres pg_isready -U postgres >/dev/null 2>&1; then
        break
    fi
    if [ $i -eq 30 ]; then
        echo -e "${YELLOW}WARNING: Original PostgreSQL took longer than expected to restart${NC}"
        break
    fi
    sleep 2
done

# Clean up restore directory
docker-compose --profile backup run --rm walg rm -rf $RESTORE_PATH 2>/dev/null || true

echo ""
echo -e "${GREEN}✅ BACKUP VALIDATION SUCCESSFUL!${NC}"
echo -e "${GREEN}✅ Backup correctly preserved the initial 3 records${NC}"
echo -e "${GREEN}✅ Post-backup data (4 additional records) were correctly NOT restored${NC}"
echo -e "${GREEN}✅ Data integrity confirmed: user1, user2, user3${NC}"
echo ""
echo "Backup validation completed successfully!"
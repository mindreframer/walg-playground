#!/bin/bash
set -e

echo "Examining Database Contents in Backup"
echo "===================================="
echo ""

# Get the latest backup
LATEST_BACKUP=$(docker-compose exec -e PGUSER=postgres -e PGPASSWORD=postgres -e PGDATABASE=testdb postgres wal-g backup-list | tail -n 1 | awk '{print $1}')
echo "Latest backup: $LATEST_BACKUP"
echo ""

# Create a temporary directory to examine the backup
EXAMINE_DIR="/tmp/walg_examine_db_$(date +%s)"
echo "Creating examination directory: $EXAMINE_DIR"
docker-compose exec postgres mkdir -p $EXAMINE_DIR
echo ""

# Restore the backup to examination directory
echo "Restoring backup for examination..."
docker-compose exec -e PGUSER=postgres -e PGPASSWORD=postgres -e PGDATABASE=testdb postgres wal-g backup-fetch $EXAMINE_DIR $LATEST_BACKUP
echo ""

# Check what's in each database directory
echo "Examining database directories:"
for db_dir in $(docker-compose exec postgres ls $EXAMINE_DIR/base/); do
    echo "Database directory: $db_dir"
    echo "Contents:"
    docker-compose exec postgres ls -la $EXAMINE_DIR/base/$db_dir/ | head -10
    echo ""
done

# Check if we can find the testdb OID
echo "Finding testdb OID:"
docker-compose exec postgres psql -U postgres -c "SELECT oid, datname FROM pg_database WHERE datname = 'testdb';"
echo ""

# Check what's in the testdb directory (if we can find it)
echo "Checking for testdb data:"
TESTDB_OID=$(docker-compose exec postgres psql -U postgres -c "SELECT oid FROM pg_database WHERE datname = 'testdb';" -t | xargs)
echo "testdb OID: $TESTDB_OID"

if [ ! -z "$TESTDB_OID" ]; then
    echo "Contents of testdb directory ($TESTDB_OID):"
    docker-compose exec postgres ls -la $EXAMINE_DIR/base/$TESTDB_OID/ 2>/dev/null || echo "Directory not found"
    echo ""
    
    # Look for table files
    echo "Looking for table files in testdb:"
    docker-compose exec postgres find $EXAMINE_DIR/base/$TESTDB_OID/ -name "*.dat" | head -10
    echo ""
else
    echo "Could not find testdb OID"
fi

echo "Backup examination completed!"
echo "Restored backup location: $EXAMINE_DIR" 
#!/bin/bash
set -e

echo "Creating full backup with WAL-G..."

# Create full backup by connecting to PostgreSQL container
docker-compose exec postgres wal-g backup-push /var/lib/postgresql/data

echo "Full backup completed successfully."
echo "Backup timestamp: $(date)" 
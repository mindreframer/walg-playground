#!/bin/bash
set -e

echo "Listing available backups..."

# List all backups by connecting to PostgreSQL container
docker-compose exec postgres wal-g backup-list

echo "Backup listing completed." 
.PHONY: help build up down start stop restart logs backup-full backup-incremental backup-list backup-restore clean test-data

# Default target
help:
	@echo "WAL-G PostgreSQL Backup Playground"
	@echo ""
	@echo "Available commands:"
	@echo "  build          - Build all Docker images"
	@echo "  up             - Start all services"
	@echo "  down           - Stop and remove all services"
	@echo "  start          - Start services (if already built)"
	@echo "  stop           - Stop services"
	@echo "  restart        - Restart services"
	@echo "  logs           - Show logs from all services"
	@echo "  init-minio     - Initialize MinIO bucket"
	@echo "  backup-full    - Create a full backup"
	@echo "  backup-incremental - Create an incremental backup"
	@echo "  backup-list    - List available backups"
	@echo "  backup-restore - Restore from latest backup"
	@echo "  test-restore   - Test restore functionality"
	@echo "  verify-restore - Verify restore data integrity"
	@echo "  restore-to-live - Restore backup to live PostgreSQL"
	@echo "  restore-test-live - Manual restore test with live PostgreSQL"
	@echo "  restore-test-complete - Complete restore test with detailed output"
	@echo "  clean          - Remove all containers, volumes, and images"
	@echo "  test-data      - Insert test data into database"

# Build all images
build:
	docker-compose build

# Start all services
up:
	docker-compose up -d

# Stop and remove all services
down:
	docker-compose down

# Start services (if already built)
start:
	docker-compose start

# Stop services
stop:
	docker-compose stop

# Restart services
restart:
	docker-compose restart

# Show logs
logs:
	docker-compose logs -f

# Create full backup
backup-full:
	docker-compose exec -e PGUSER=postgres -e PGPASSWORD=postgres -e PGDATABASE=testdb postgres wal-g backup-push /var/lib/postgresql/data

# Create incremental backup
backup-incremental:
	docker-compose exec -e PGUSER=postgres -e PGPASSWORD=postgres -e PGDATABASE=testdb postgres wal-g backup-push /var/lib/postgresql/data --delta-from-name $$(docker-compose exec -e PGUSER=postgres -e PGPASSWORD=postgres -e PGDATABASE=testdb postgres wal-g backup-list | tail -n 1 | awk '{print $$1}')

# List available backups
backup-list:
	docker-compose exec -e PGUSER=postgres -e PGPASSWORD=postgres -e PGDATABASE=testdb postgres wal-g backup-list

# Restore from latest backup
backup-restore:
	docker-compose exec -e PGUSER=postgres -e PGPASSWORD=postgres -e PGDATABASE=testdb postgres wal-g backup-fetch /backups/restored_data $$(docker-compose exec -e PGUSER=postgres -e PGPASSWORD=postgres -e PGDATABASE=testdb postgres wal-g backup-list | tail -n 1 | awk '{print $$1}')

# Test restore functionality
test-restore:
	./scripts/test-restore.sh

# Verify restore data integrity
verify-restore:
	./scripts/verify-restore.sh

# Restore backup to live PostgreSQL instance
restore-to-live:
	./scripts/restore-to-live.sh

# Manual restore test with live PostgreSQL
restore-test-live:
	./scripts/manual-restore-test.sh

# Complete restore test with detailed output
restore-test-complete:
	./scripts/test-restore-complete.sh

# Clean everything
clean:
	docker-compose down -v --rmi all
	docker system prune -f

# Insert test data
test-data:
	docker-compose exec postgres psql -U postgres -d testdb -f /scripts/insert-test-data.sql

# Show database status
db-status:
	docker-compose exec postgres psql -U postgres -d testdb -c "SELECT version();"
	docker-compose exec postgres psql -U postgres -d testdb -c "SHOW archive_mode;"
	docker-compose exec postgres psql -U postgres -d testdb -c "SHOW wal_level;"

# Connect to database
db-connect:
	docker-compose exec postgres psql -U postgres -d testdb

# Initialize MinIO bucket
init-minio:
	docker-compose --profile backup run --rm walg /scripts/init-minio.sh

# Show WAL-G version
walg-version:
	docker-compose --profile backup run --rm walg wal-g --version

# Show MinIO status
minio-status:
	docker-compose exec minio mc alias set myminio http://localhost:9000 minioadmin minioadmin
	docker-compose exec minio mc ls myminio 
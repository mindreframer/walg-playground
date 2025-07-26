# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a WAL-G PostgreSQL backup playground - a Docker-based testing environment for WAL-G streaming backups of PostgreSQL with MinIO as S3-compatible storage. The project provides a complete containerized environment for testing backup and restore operations.

## Commands

### Primary Development Commands
- `make help` - Display all available commands
- `make build` - Build all Docker images
- `make up` - Start all services in daemon mode
- `make down` - Stop and remove all services
- `make logs` - Show logs from all services

### Environment Setup (Required sequence)
1. `make build` - Build containers
2. `make up` - Start services  
3. `make init-minio` - Initialize MinIO bucket (required before backups)

### Backup Operations
- `make backup-full` - Create a full WAL-G backup
- `make backup-incremental` - Create an incremental backup
- `make backup-list` - List available backups
- `make backup-restore` - Restore from latest backup
- `make validate-backup` - Test backup and restore functionality end-to-end

### Database Operations
- `make test-data` - Insert test data into PostgreSQL
- `make db-status` - Show database status and configuration
- `make db-connect` - Connect to PostgreSQL database

### Utilities
- `make clean` - Remove all containers, volumes, and images
- `make walg-version` - Show WAL-G version
- `make minio-status` - Show MinIO status

## Architecture

The project consists of three main services orchestrated via Docker Compose:

1. **PostgreSQL** (port 5432): PostgreSQL 15 with WAL-G installed, configured for streaming backups with WAL level replica and archive mode enabled
2. **MinIO** (ports 9000/9001): S3-compatible storage backend for backup storage
3. **WAL-G Client**: Standalone container for backup operations using the `backup` profile

### Key Configuration
- PostgreSQL configured with `wal_level=replica`, `archive_mode=on`, and `archive_command='wal-g wal-push %p'`
- WAL-G uses MinIO as S3 backend with bucket `walg-backups`
- ARM64 platform support configured for Apple Silicon

## Development Workflow

1. **Initial Setup**: `make build && make up && make init-minio`
2. **Add Test Data**: `make test-data`
3. **Create Backup**: `make backup-full`
4. **Test Operations**: `make backup-list`, `make backup-restore`

## File Structure

- `Dockerfile.postgres` - PostgreSQL container with WAL-G
- `Dockerfile.walg` - WAL-G client container  
- `docker-compose.yml` - Service orchestration
- `scripts/` - Backup and initialization scripts
- `backups/` - Local backup storage mount point

## Environment Access

- PostgreSQL: `localhost:5432` (user: postgres, password: postgres, database: testdb)
- MinIO Console: `http://localhost:9001` (login: minioadmin/minioadmin)
- MinIO API: `localhost:9000`

## Testing and Verification

Use `make db-status` to verify PostgreSQL configuration and `make backup-list` to confirm backup operations. The environment includes health checks for both PostgreSQL and MinIO services.

### Backup Validation

Run `make validate-backup` to perform a comprehensive test that:
1. Creates test data in PostgreSQL
2. Performs a full backup
3. Adds additional data (post-backup)
4. Simulates data loss by dropping tables
5. Restores from backup to verify data integrity
6. Confirms only pre-backup data is recovered

This validation ensures the backup and restore process works correctly and data can be recovered after loss scenarios.
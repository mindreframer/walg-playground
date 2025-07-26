# WAL-G PostgreSQL Backup Playground

A Docker-based playground for testing WAL-G streaming backups of PostgreSQL with MinIO as S3-compatible storage.

## Overview

This playground provides a complete environment for testing WAL-G backup and restore operations with PostgreSQL. It includes:

- **PostgreSQL 15** with WAL-G installed and configured for streaming backups
- **MinIO** as S3-compatible storage backend
- **WAL-G client** container for backup operations
- Automated scripts for backup, restore, and testing

## Architecture

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   MinIO     │    │ PostgreSQL  │    │  WAL-G      │
│  S3 Storage │◄───┤   Database  │◄───┤   Client    │
│             │    │             │    │             │
└─────────────┘    └─────────────┘    └─────────────┘
```

## Prerequisites

- Docker and Docker Compose
- Make (optional, for convenience commands)

## Quick Start

1. **Build and start all services:**
   ```bash
   make build
   make up
   ```

2. **Initialize MinIO bucket:**
   ```bash
   make init-minio
   ```

3. **Insert test data:**
   ```bash
   make test-data
   ```

4. **Create a full backup:**
   ```bash
   make backup-full
   ```

5. **List available backups:**
   ```bash
   make backup-list
   ```

## Services

### PostgreSQL
- **Port:** 5432
- **Database:** testdb
- **User:** postgres
- **Password:** postgres
- **WAL Level:** replica
- **Archive Mode:** enabled

### MinIO
- **API Port:** 9000
- **Console Port:** 9001
- **Access Key:** minioadmin
- **Secret Key:** minioadmin
- **Bucket:** walg-backups

### WAL-G Client
- Available for backup operations
- Configured to use MinIO as S3 backend

## Available Commands

### Service Management
- `make build` - Build all Docker images
- `make up` - Start all services
- `make down` - Stop and remove all services
- `make start` - Start services (if already built)
- `make stop` - Stop services
- `make restart` - Restart services
- `make logs` - Show logs from all services

### Backup Operations
- `make init-minio` - Initialize MinIO bucket
- `make backup-full` - Create a full backup
- `make backup-incremental` - Create an incremental backup
- `make backup-list` - List available backups
- `make backup-restore` - Restore from latest backup

### Database Operations
- `make test-data` - Insert test data into database
- `make db-status` - Show database status
- `make db-connect` - Connect to database

### Utility Commands
- `make clean` - Remove all containers, volumes, and images
- `make walg-version` - Show WAL-G version
- `make minio-status` - Show MinIO status

## Testing Workflow

1. **Start the environment:**
   ```bash
   make build
   make up
   make init-minio
   ```

2. **Insert initial data:**
   ```bash
   make test-data
   ```

3. **Create a full backup:**
   ```bash
   make backup-full
   ```

4. **Add more data and create incremental backup:**
   ```bash
   make test-data
   make backup-incremental
   ```

5. **List backups:**
   ```bash
   make backup-list
   ```

6. **Test restore (optional):**
   ```bash
   make backup-restore
   ```

## Configuration

### Environment Variables

The playground uses the following environment variables:

- `WALG_S3_PREFIX`: S3 bucket prefix for backups
- `AWS_ACCESS_KEY_ID`: MinIO access key
- `AWS_SECRET_ACCESS_KEY`: MinIO secret key
- `AWS_ENDPOINT`: MinIO endpoint URL
- `AWS_S3_FORCE_PATH_STYLE`: Force path-style S3 URLs

### PostgreSQL Configuration

PostgreSQL is configured with:
- WAL level: replica
- Archive mode: enabled
- Archive command: wal-g wal-push
- Max WAL senders: 10
- Max replication slots: 10

## File Structure

```
walg-playground/
├── docker-compose.yml      # Main orchestration file
├── Dockerfile.postgres     # PostgreSQL with WAL-G
├── Dockerfile.walg        # WAL-G client container
├── Makefile               # Convenience commands
├── scripts/               # Utility scripts
│   ├── init-walg.sh      # PostgreSQL initialization
│   ├── init-minio.sh     # MinIO bucket setup
│   ├── backup-full.sh    # Full backup script
│   ├── backup-incremental.sh # Incremental backup script
│   ├── backup-list.sh    # List backups script
│   ├── backup-restore.sh # Restore script
│   └── insert-test-data.sql # Test data insertion
├── backups/               # Local backup storage
└── Readme.md             # This file
```

## Troubleshooting

### MinIO Connection Issues
- Ensure MinIO is healthy: `docker-compose ps`
- Check MinIO logs: `docker-compose logs minio`
- Verify bucket exists: `make minio-status`

### PostgreSQL Connection Issues
- Check PostgreSQL health: `docker-compose ps`
- View PostgreSQL logs: `docker-compose logs postgres`
- Test connection: `make db-status`

### Backup Issues
- Verify WAL-G version: `make walg-version`
- Check WAL-G logs: `docker-compose logs walg`
- Ensure MinIO bucket is initialized: `make init-minio`

## Access Points

- **PostgreSQL:** `localhost:5432`
- **MinIO API:** `localhost:9000`
- **MinIO Console:** `http://localhost:9001` (login: minioadmin/minioadmin)

## Cleanup

To completely remove all data and containers:
```bash
make clean
```

This will remove all containers, volumes, and images created by this playground.

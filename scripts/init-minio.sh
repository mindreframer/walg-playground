#!/bin/bash
set -e

echo "Initializing MinIO bucket for WAL-G backups..."

# Wait for MinIO to be ready
until curl -f http://minio:9000/minio/health/live; do
    echo "Waiting for MinIO to be ready..."
    sleep 2
done

# Create the bucket using MinIO client (mc)
mc alias set myminio http://minio:9000 minioadmin minioadmin
mc mb myminio/walg-backups --ignore-existing

echo "MinIO bucket 'walg-backups' created successfully."
echo "MinIO Console available at: http://localhost:9001"
echo "Login with: minioadmin / minioadmin" 
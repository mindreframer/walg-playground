#!/bin/bash
set -e

echo "Listing available backups..."

# List all backups
wal-g backup-list

echo "Backup listing completed." 
#!/bin/bash
set -euo pipefail

CONTAINER_NAME="hotel_bookings_db"
DB_NAME="hotel_bookings"
DB_USER="dbadmin"
BACKUP_DIR="$(cd "$(dirname "$0")/.." && pwd)/backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="${BACKUP_DIR}/backup_${TIMESTAMP}.sql"

mkdir -p "$BACKUP_DIR"

echo "Starting database backup..."
echo "Database: $DB_NAME"
echo "Container: $CONTAINER_NAME"
echo "Backup file: $BACKUP_FILE"

docker exec "$CONTAINER_NAME" pg_dump -U "$DB_USER" -d "$DB_NAME" --no-owner --no-acl > "$BACKUP_FILE"

if [ -s "$BACKUP_FILE" ]; then
    FILE_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    echo "Backup completed successfully."
    echo "File: $BACKUP_FILE"
    echo "Size: $FILE_SIZE"
else
    echo "ERROR: Backup file is empty. Something went wrong."
    rm -f "$BACKUP_FILE"
    exit 1
fi

#!/bin/bash
set -euo pipefail

CONTAINER_NAME="hotel_bookings_db"
DB_NAME="hotel_bookings"
DB_USER="dbadmin"
BACKUP_DIR="$(cd "$(dirname "$0")/.." && pwd)/backups"

# Use the backup file passed as argument, or find the latest one
if [ -n "${1:-}" ]; then
    BACKUP_FILE="$1"
else
    BACKUP_FILE=$(ls -t "$BACKUP_DIR"/backup_*.sql 2>/dev/null | head -1)
fi

if [ -z "$BACKUP_FILE" ] || [ ! -f "$BACKUP_FILE" ]; then
    echo "ERROR: No backup file found."
    echo "Usage: $0 [path/to/backup.sql]"
    echo "Or place backup files in the backups/ directory."
    exit 1
fi

echo "Starting database restore..."
echo "Backup file: $BACKUP_FILE"
echo "Database: $DB_NAME"
echo "Container: $CONTAINER_NAME"
echo ""
echo "WARNING: This will drop and recreate the database."
echo "Press Ctrl+C within 5 seconds to cancel..."
sleep 5

echo "Dropping existing database..."
docker exec "$CONTAINER_NAME" psql -U "$DB_USER" -d postgres -c "
    SELECT pg_terminate_backend(pg_stat_activity.pid)
    FROM pg_stat_activity
    WHERE pg_stat_activity.datname = '$DB_NAME' AND pid <> pg_backend_pid();
" > /dev/null 2>&1 || true

docker exec "$CONTAINER_NAME" psql -U "$DB_USER" -d postgres -c "DROP DATABASE IF EXISTS $DB_NAME;" > /dev/null 2>&1
docker exec "$CONTAINER_NAME" psql -U "$DB_USER" -d postgres -c "CREATE DATABASE $DB_NAME;" > /dev/null 2>&1

echo "Restoring from backup..."
docker exec -i "$CONTAINER_NAME" psql -U "$DB_USER" -d "$DB_NAME" < "$BACKUP_FILE"

echo ""
echo "Restore completed. Verifying..."
echo ""

echo "=== Row counts ==="
docker exec "$CONTAINER_NAME" psql -U "$DB_USER" -d "$DB_NAME" -c "
    SELECT 'hotel_bookings' AS table_name, COUNT(*) AS row_count FROM hotel_bookings
    UNION ALL
    SELECT 'booking_events', COUNT(*) FROM booking_events;
"

echo "Restore verified successfully."


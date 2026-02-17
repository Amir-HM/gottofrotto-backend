#!/bin/bash
set -euo pipefail

# =============================================================================
# Gottofrotto — PostgreSQL Backup Script
# =============================================================================
# Runs as the postgres user via cron (installed by setup.sh).
# Keeps 7 days of compressed backups.
# =============================================================================

DB_NAME="gottofrotto"
BACKUP_DIR="/var/backups/gottofrotto"
RETENTION_DAYS=7
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/${DB_NAME}_${TIMESTAMP}.sql.gz"

mkdir -p "$BACKUP_DIR"

# Dump and compress
pg_dump "$DB_NAME" | gzip > "$BACKUP_FILE"

# Verify the backup is not empty
if [ ! -s "$BACKUP_FILE" ]; then
  echo "ERROR: Backup file is empty: $BACKUP_FILE" >&2
  rm -f "$BACKUP_FILE"
  exit 1
fi

SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
echo "Backup complete: ${BACKUP_FILE} (${SIZE})"

# Remove backups older than retention period
find "$BACKUP_DIR" -name "${DB_NAME}_*.sql.gz" -mtime +${RETENTION_DAYS} -delete

REMAINING=$(find "$BACKUP_DIR" -name "${DB_NAME}_*.sql.gz" | wc -l)
echo "Backups retained: ${REMAINING}"

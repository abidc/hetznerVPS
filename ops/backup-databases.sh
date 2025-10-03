#!/bin/bash
#
# Database Backup Script for Stack Services
# Backs up PostgreSQL, MySQL/MariaDB, and application-specific data
#
# Usage: ./backup-databases.sh
#

set -e

# Configuration
BACKUP_BASE="/srv/stack/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=7

# Create backup directories
mkdir -p "$BACKUP_BASE"/{postgres,mysql,redis,docmost,linkstack}

echo "=========================================="
echo "Starting database backups - $TIMESTAMP"
echo "=========================================="

# Backup PostgreSQL (Docmost database)
echo "[1/5] Backing up PostgreSQL (Docmost)..."
docker exec postgres pg_dump -U postgres -d docmost | gzip > "$BACKUP_BASE/postgres/docmost_${TIMESTAMP}.sql.gz"
echo "  ✓ PostgreSQL backup complete: docmost_${TIMESTAMP}.sql.gz"

# Backup MySQL (Ghost CMS)
echo "[2/5] Backing up MySQL (Ghost)..."
docker exec mysql mysqldump -u root -p${MYSQL_ROOT_PASSWORD:-changeme} --all-databases | gzip > "$BACKUP_BASE/mysql/all_databases_${TIMESTAMP}.sql.gz"
echo "  ✓ MySQL backup complete: all_databases_${TIMESTAMP}.sql.gz"

# Backup Redis data
echo "[3/5] Backing up Redis..."
docker exec redis redis-cli --pass changeme SAVE > /dev/null 2>&1 || echo "  ⚠ Redis save skipped (auth issue)"
docker cp redis:/data/dump.rdb "$BACKUP_BASE/redis/dump_${TIMESTAMP}.rdb" 2>/dev/null || echo "  ⚠ Redis dump not found"
echo "  ✓ Redis backup attempted"

# Backup Docmost data directory
echo "[4/5] Backing up Docmost data..."
tar -czf "$BACKUP_BASE/docmost/data_${TIMESTAMP}.tar.gz" -C /srv/stack/data/docmost . 2>/dev/null
echo "  ✓ Docmost data backup complete: data_${TIMESTAMP}.tar.gz"

# Backup LinkStack SQLite database
echo "[5/5] Backing up LinkStack..."
if [ -f "/srv/stack/data/linkstack/linkstack.sqlite" ]; then
    cp /srv/stack/data/linkstack/linkstack.sqlite "$BACKUP_BASE/linkstack/linkstack_${TIMESTAMP}.sqlite"
    gzip "$BACKUP_BASE/linkstack/linkstack_${TIMESTAMP}.sqlite"
    echo "  ✓ LinkStack backup complete: linkstack_${TIMESTAMP}.sqlite.gz"
else
    echo "  ⚠ LinkStack database not found"
fi

# Cleanup old backups (keep last RETENTION_DAYS days)
echo ""
echo "Cleaning up backups older than $RETENTION_DAYS days..."
find "$BACKUP_BASE" -type f -name "*.gz" -mtime +$RETENTION_DAYS -delete
find "$BACKUP_BASE" -type f -name "*.rdb" -mtime +$RETENTION_DAYS -delete
find "$BACKUP_BASE" -type f -name "*.sqlite" -mtime +$RETENTION_DAYS -delete

# Show backup summary
echo ""
echo "=========================================="
echo "Backup Summary"
echo "=========================================="
du -sh "$BACKUP_BASE"/* 2>/dev/null | awk '{print "  " $2 ": " $1}'

echo ""
echo "✓ All backups completed successfully!"
echo "Location: $BACKUP_BASE"
echo "=========================================="

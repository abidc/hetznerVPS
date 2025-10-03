# Database Backup & Restoration Guide

## Overview
Automated daily backups run at 2:00 AM via cron job.
Backups are stored in `/srv/stack/backups/` and retained for 7 days.

## Backup Locations
- **PostgreSQL (Docmost)**: `/srv/stack/backups/postgres/`
- **MySQL (Ghost)**: `/srv/stack/backups/mysql/`
- **Redis**: `/srv/stack/backups/redis/`
- **Docmost Data**: `/srv/stack/backups/docmost/`
- **LinkStack**: `/srv/stack/backups/linkstack/`

## Manual Backup
Run the backup script manually anytime:
```bash
/srv/stack/ops/backup-databases.sh
```

## Restoration Procedures

### 1. Restore PostgreSQL (Docmost)
```bash
# List available backups
ls -lh /srv/stack/backups/postgres/

# Restore from backup
gunzip -c /srv/stack/backups/postgres/docmost_YYYYMMDD_HHMMSS.sql.gz | \
  docker exec -i postgres psql -U postgres -d docmost

# Verify restoration
docker exec postgres psql -U postgres -d docmost -c "SELECT COUNT(*) FROM users;"
```

### 2. Restore MySQL (Ghost)
```bash
# List available backups
ls -lh /srv/stack/backups/mysql/

# Restore from backup
gunzip -c /srv/stack/backups/mysql/all_databases_YYYYMMDD_HHMMSS.sql.gz | \
  docker exec -i mysql mysql -u root -pchangeme

# Verify restoration
docker exec mysql mysql -u root -pchangeme -e "SHOW DATABASES;"
```

### 3. Restore Redis
```bash
# Stop Redis container
docker stop redis

# Replace dump.rdb file
docker cp /srv/stack/backups/redis/dump_YYYYMMDD_HHMMSS.rdb redis:/data/dump.rdb

# Start Redis container
docker start redis
```

### 4. Restore Docmost Data
```bash
# Stop Docmost container
docker stop stack-docmost-1

# Clear existing data
rm -rf /srv/stack/data/docmost/*

# Restore from backup
tar -xzf /srv/stack/backups/docmost/data_YYYYMMDD_HHMMSS.tar.gz -C /srv/stack/data/docmost/

# Start Docmost container
docker start stack-docmost-1
```

### 5. Restore LinkStack
```bash
# Stop LinkStack container
docker stop stack-linkstack-1

# Restore SQLite database
gunzip -c /srv/stack/backups/linkstack/linkstack_YYYYMMDD_HHMMSS.sqlite.gz > \
  /srv/stack/data/linkstack/linkstack.sqlite

# Start LinkStack container
docker start stack-linkstack-1
```

## Complete Disaster Recovery

If you need to restore everything from scratch:

```bash
# 1. Restore PostgreSQL databases
cd /srv/stack/backups/postgres
LATEST_PG=$(ls -t docmost_*.sql.gz | head -1)
gunzip -c $LATEST_PG | docker exec -i postgres psql -U postgres -d docmost

# 2. Restore MySQL databases
cd /srv/stack/backups/mysql
LATEST_MYSQL=$(ls -t all_databases_*.sql.gz | head -1)
gunzip -c $LATEST_MYSQL | docker exec -i mysql mysql -u root -pchangeme

# 3. Restore LinkStack
cd /srv/stack/backups/linkstack
LATEST_LS=$(ls -t linkstack_*.sqlite.gz | head -1)
gunzip -c $LATEST_LS > /srv/stack/data/linkstack/linkstack.sqlite

# 4. Restore Docmost data
cd /srv/stack/backups/docmost
LATEST_DM=$(ls -t data_*.tar.gz | head -1)
tar -xzf $LATEST_DM -C /srv/stack/data/docmost/

# 5. Restart all services
docker compose restart docmost linkstack
```

## Backup Monitoring

Check backup logs:
```bash
tail -f /srv/stack/backups/backup.log
```

Check backup sizes:
```bash
du -sh /srv/stack/backups/*
```

List recent backups:
```bash
find /srv/stack/backups -type f -name "*.gz" -mtime -7 -ls
```

## Cron Job Management

View current cron jobs:
```bash
crontab -l
```

Edit cron schedule:
```bash
crontab -e
```

Current schedule: Daily at 2:00 AM
```
0 2 * * * /srv/stack/ops/backup-databases.sh >> /srv/stack/backups/backup.log 2>&1
```

## Backup Best Practices

1. **Off-site Backups**: Copy `/srv/stack/backups/` to external storage regularly
2. **Test Restorations**: Perform test restorations quarterly to verify backup integrity
3. **Monitor Disk Space**: Ensure `/srv/stack/backups/` has sufficient space
4. **Adjust Retention**: Modify `RETENTION_DAYS` in backup script if needed
5. **Pre-maintenance Backups**: Run manual backup before major changes

## Troubleshooting

### Backup script fails
```bash
# Check script permissions
ls -la /srv/stack/ops/backup-databases.sh

# Check Docker containers are running
docker ps

# Check disk space
df -h /srv/stack
```

### Database restoration fails
```bash
# Verify backup file integrity
gunzip -t /srv/stack/backups/postgres/docmost_*.sql.gz

# Check container logs
docker logs postgres
docker logs mysql

# Verify database credentials
docker exec postgres psql -U postgres -c "\l"
```

## Emergency Contacts
- Backup Location: `/srv/stack/backups/`
- Script Location: `/srv/stack/ops/backup-databases.sh`
- Log File: `/srv/stack/backups/backup.log`

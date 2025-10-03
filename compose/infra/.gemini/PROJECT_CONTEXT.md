# Phoenix Server - Infrastructure Services Context

## Current Directory
`/srv/stack/compose/infra` - Infrastructure Docker Compose services

## This Compose Stack
Contains core infrastructure services:
- PostgreSQL (postgres:15) - Main database server
- MySQL (mysql:8.0) - Database for Ghost CMS
- Redis (redis:7) - Cache and queue service
- Qdrant (v1.12.3) - Vector database
- Dashy - Dashboard
- Watchtower - Auto-updater

## Docker Compose Configuration
File: `docker-compose.yml`
Network: `net_core` (external, shared with other services)

## Environment Variables
Loaded from `/srv/stack/.env`:
- POSTGRES_USER=postgres
- POSTGRES_PASSWORD=changeme
- POSTGRES_DB=docmost
- MYSQL_ROOT_PASSWORD=changeme
- REDIS_PASSWORD=changeme

## Database Connections

### PostgreSQL
- Host: postgres (container name)
- Port: 5432
- User: postgres
- Password: changeme
- Databases: docmost
- Used by: Docmost, Paperless-ngx (separate instance)

### MySQL
- Host: mysql (container name)
- Port: 3306
- Root password: changeme
- Used by: Ghost CMS

### Redis
- Host: redis (container name)
- Port: 6379
- Password: changeme
- Used by: Docmost, Paperless-ngx

### Qdrant
- Host: qdrant (container name)
- Ports: 6333 (REST), 6334 (gRPC)
- No authentication
- Vector database for AI applications

## Related Services
Other application services are in `/srv/stack/docker-compose.yml`:
- Docmost - Documentation (uses postgres + redis)
- Ghost - Blog CMS (uses mysql)
- LinkStack - Link manager (uses SQLite)
- n8n - Workflow automation
- Flowise - AI flows
- Open WebUI - AI chat
- Paperless-ngx - Document management
- Portainer - Docker UI
- Dockge - Compose UI
- Homarr, Dashy - Dashboards
- Homebox - Home inventory
- Excalidraw - Diagramming

## Backup Configuration
Daily backups at 2:00 AM via cron:
- Script: `/srv/stack/ops/backup-databases.sh`
- Location: `/srv/stack/backups/`
- Retention: 7 days
- Includes: PostgreSQL, MySQL, Redis, application data

## Network Access
All services exposed via Cloudflare tunnel (*.abidc.dev)
- Config: `/srv/stack/ops/cloudflared/config.yml`
- No direct port exposure to internet

## Common Operations

### Restart infrastructure services:
```bash
cd /srv/stack/compose/infra
docker-compose restart
```

### Check service logs:
```bash
docker logs postgres
docker logs mysql
docker logs redis
docker logs qdrant
```

### Access PostgreSQL:
```bash
docker exec -it postgres psql -U postgres -d docmost
```

### Access MySQL:
```bash
docker exec -it mysql mysql -u root -pchangeme
```

### Access Redis:
```bash
docker exec -it redis redis-cli -a changeme
```

## Volumes
Persistent data stored in Docker named volumes:
- `postgres_data` - PostgreSQL data
- `mysql_data` - MySQL data
- `redis_data` - Redis data
- `qdrant_data` - Qdrant data
- `dashy_data` - Dashy config

## Key Files
- `docker-compose.yml` - Service definitions
- `/srv/stack/.env` - Environment variables
- `/srv/stack/ops/backup-databases.sh` - Backup script
- `/srv/stack/backups/` - Backup directory

## MCP Servers Available
All configured in `.gemini/settings.json`:
1. github - GitHub integration
2. puppeteer - Browser automation
3. playwright - Browser testing
4. knowledge-graph - Knowledge management
5. desktop-commander - System operations
6. octocode - Code search
7. mcp-compass - MCP discovery
8. crush - Documentation
9. n8n - Workflow automation

## Server Resources
- CPU: 4 cores
- Memory: 7.6 GB (typically 73% used)
- Storage: 150 GB total, 117 GB available
- No swap configured

## Important Notes
- All passwords are "changeme" - consider changing in production
- Monitor memory usage closely (no swap)
- Services auto-restart unless stopped manually
- Watchtower keeps containers updated
- PostgreSQL uses md5 authentication (not scram-sha-256)

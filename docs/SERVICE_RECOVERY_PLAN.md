# Service Recovery Action Plan

_Last updated: 2025-10-13 (UTC)_

This plan reflects the current container inventory and the procedures exercised
during the latest system health check. Work through the phases sequentially when
recovering from outages so core access is restored before application tiers.

## Environment reference

* Shared Docker network: `net_core` (created by `make bootstrap`).
* Persistent data root: `/srv/stack/data` (see service-specific subdirectories).
* Core compose files:
  * `compose/infra/docker-compose.yml` – databases, caches, internal dashboards, and
    Watchtower.
  * `docker-compose.yml` – application layer (Flowise, Paperless-ngx, Linkstack, etc.).
* Health commands:
  * `uptime` for load averages.
  * `top -bn1 | head -n 15` for real-time CPU consumers.
  * `free -h` for RAM and swap usage.

## Phase 1 – Access & Control Plane

1. **Cloudflared tunnel**
   * Ensure credentials exist in `ops/cloudflared/`.
   * Restart: `docker compose up -d cloudflared`.
   * Verify ingress: `docker logs cloudflared | tail`.
2. **Portainer & Dockge**
   * Restart: `docker compose up -d portainer dockge`.
   * Validate via HTTPS on ports 9443 and 5001 respectively.
3. **Watchtower**
   * Runs from the infra stack; confirm it is not pulling unexpected images during
     an incident. Pause with `docker stop watchtower` if necessary.

## Phase 2 – Data Services

1. **Postgres / MySQL / Redis / Qdrant**
   * Compose file: `compose/infra/docker-compose.yml`.
   * Restart order: `docker compose -f compose/infra/docker-compose.yml up -d postgres mysql redis qdrant`.
   * Validate:
     * Postgres: `docker exec postgres pg_isready`.
     * MySQL: `docker exec mysql mysqladmin ping -p`.
     * Redis: `docker exec redis redis-cli -a "$REDIS_PASSWORD" PING`.
     * Qdrant: `curl -fsSL http://localhost:6333/collections`.
2. **Backup expectations**
   * Database volumes are Docker named volumes; snapshot `/var/lib/docker/volumes/*`
     or use logical dumps as part of routine backups.

## Phase 3 – Application Layer

Address services in the order users depend on them. Each command targets the
root `docker-compose.yml` file unless otherwise noted.

1. **Authentication-sensitive apps**
   * Flowise: `docker compose up -d flowise` and follow the credential rotation runbook
     in `PHASE2_IMPLEMENTATION.md`.
   * Paperless-ngx stack: `docker compose up -d redis postgres paperless`.
   * Linkstack: ensure `LINKSTACK_APP_KEY` is set before restart.
2. **Dashboards and portals**
   * Dashy and Homarr expose navigation UIs; restart with
     `docker compose up -d dashy homarr`.
3. **Content services**
   * Ghost and Docmost share database dependencies. Confirm Postgres/MySQL are healthy
     before `docker compose up -d ghost docmost`.
4. **AI/automation services**
   * n8n, mem0, and OpenWebUI rely on external APIs. Inspect their environment
     variables before restarting (`docker compose config <service>` to double-check).
5. **Collaboration tools**
   * Excalidraw and Homebox run independently. Restart when other priorities are stable.

## Phase 4 – Verification & Monitoring

1. `make ps` to confirm every container reports `Up` status.
2. Inspect logs for the services touched using `docker logs <service> --tail 100`.
3. Browse to each externally exposed hostname to confirm TLS and application behaviour.
4. Record the incident, including resource utilisation snapshots from the health
   commands above, in your operations journal.

Keeping this document updated alongside the codebase ensures the operational picture
stays accurate after every change.

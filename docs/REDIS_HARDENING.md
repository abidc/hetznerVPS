# Redis Hardening Validation

Follow these steps after updating the `redis` service port bindings to ensure Docmost and Paperless reconnect cleanly.

1. Restart the Redis container:
   ```bash
   ops/scripts/restart-redis.sh
   ```
   This script runs `docker compose up -d redis` from the repository root so the container picks up the new binding.

2. Confirm the containers are running:
   ```bash
   docker compose ps redis docmost paperless
   ```
   All three services should report a `running` state.

3. Inspect recent application logs for reconnection noise:
   ```bash
   docker compose logs --tail=20 docmost paperless
   ```
   Docmost should log a successful Redis connection, and Paperless should report that both the task queue and broker are available.

If any container fails to reconnect, re-run `docker compose up -d <service>` for the affected service and inspect its logs with `docker compose logs -f <service>`.

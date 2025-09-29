#!/usr/bin/env bash
set -euo pipefail
docker compose -f compose/mcp/docker-compose.yml pull
docker compose -f compose/apps-extra/docker-compose.yml pull
docker compose -f compose/apps-core/docker-compose.yml pull
docker compose -f compose/infra/docker-compose.yml pull

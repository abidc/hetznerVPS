#!/usr/bin/env bash
set -euo pipefail
export $(grep -v '^#' env/.env.global | xargs) || true
docker compose -f compose/infra/docker-compose.yml up -d
# Only start apps-core if docker-compose.yml exists
if [ -f compose/apps-core/docker-compose.yml ]; then
    docker compose -f compose/apps-core/docker-compose.yml up -d
fi
# Only start apps-extra if docker-compose.yml exists
if [ -f compose/apps-extra/docker-compose.yml ]; then
    docker compose -f compose/apps-extra/docker-compose.yml up -d
fi
# Only start mcp if docker-compose.yml exists
if [ -f compose/mcp/docker-compose.yml ]; then
    docker compose -f compose/mcp/docker-compose.yml up -d
fi

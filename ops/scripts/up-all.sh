#!/usr/bin/env bash
set -euo pipefail
export $(grep -v '^#' env/.env.global | xargs) || true
docker compose -f compose/infra/docker-compose.yml up -d
docker compose -f compose/apps-core/docker-compose.yml up -d
docker compose -f compose/apps-extra/docker-compose.yml up -d
docker compose -f compose/mcp/docker-compose.yml up -d

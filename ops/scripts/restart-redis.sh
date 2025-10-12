#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

echo "Restarting redis service..."
docker compose up -d redis

echo
echo "Checking status of redis, docmost, and paperless services..."
docker compose ps redis docmost paperless

echo
echo "Tail the last 20 log lines for docmost and paperless to confirm healthy reconnections."
docker compose logs --tail=20 docmost paperless

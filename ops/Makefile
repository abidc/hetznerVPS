SHELL := /bin/bash
.PHONY: bootstrap up pull stop down ps logs

bootstrap:
	@chmod +x ops/scripts/*.sh || true
	@docker network create net_core || true
	@echo "Bootstrap done."

up:
	@ops/scripts/up-all.sh

pull:
	@ops/scripts/pull-all.sh

stop:
	docker compose -f compose/infra/docker-compose.yml stop || true
	docker compose -f compose/apps-core/docker-compose.yml stop || true
	docker compose -f compose/apps-extra/docker-compose.yml stop || true
	docker compose -f compose/mcp/docker-compose.yml stop || true

down:
	docker compose -f compose/mcp/docker-compose.yml down || true
	docker compose -f compose/apps-extra/docker-compose.yml down || true
	docker compose -f compose/apps-core/docker-compose.yml down || true
	docker compose -f compose/infra/docker-compose.yml down || true

ps:
	docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

logs:
	docker compose -f compose/infra/docker-compose.yml logs -f

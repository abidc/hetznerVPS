# Platform Onboarding Checklist

_Last updated: 2025-10-13 (UTC)_

This document describes how to bring a fresh Hetzner VPS host under management with this
repository. Follow the steps in order so the helper scripts can find every file and
network they expect.

## 1. Prerequisites

* Ubuntu 22.04 LTS or later with sudo access.
* Docker Engine 24.x and Docker Compose Plugin 2.27 or later installed.
* Git installed and able to reach this repository.
* DNS entries and a Cloudflare account ready for the tunnel credentials that live in
  `ops/cloudflared/`.

To verify Docker is ready:

```bash
sudo docker version
sudo docker compose version
```

## 2. Clone and layout

```bash
sudo mkdir -p /srv/stack
sudo chown $USER:$USER /srv/stack
cd /srv/stack
git clone https://github.com/<your-org>/hetznerVPS.git stack
cd stack
```

The repository expects the following directories to exist at runtime:

* `/srv/stack/data/*` – persistent volumes for application containers.
* `/srv/stack/ops/cloudflared` – Cloudflare tunnel config and credentials.
* `/srv/stack/env` – environment files loaded by helper scripts.

Create any missing directories before continuing.

## 3. Environment configuration

Populate `env/.env.global` with the secrets required by the infrastructure stack. The
file is sourced by `ops/scripts/up-all.sh` before Docker Compose is executed.

```env
# env/.env.global
POSTGRES_USER=postgres
POSTGRES_PASSWORD=change-me
POSTGRES_DB=stack
MYSQL_ROOT_PASSWORD=change-me-too
REDIS_PASSWORD=change-me-three
``` 

Add any additional environment values referenced by
`docker-compose.yml` or files under `compose/`. All variables support standard
`KEY=value` syntax. Keep the file readable by the account that runs `make up`.

## 4. Bootstrap networking

The helper make target prepares execute permissions and ensures the shared Docker
network exists.

```bash
make bootstrap
```

The command is idempotent: running it again will not recreate resources that already
exist. Verify the network after bootstrapping:

```bash
docker network inspect net_core
```

## 5. Start the stacks

`make up` runs `ops/scripts/up-all.sh`, which:

1. Loads `env/.env.global` if present.
2. Brings up `compose/infra/docker-compose.yml` (databases, cache, internal dashboards).
3. Conditionally starts the optional stacks (`compose/apps-core`, `compose/apps-extra`,
   `compose/mcp`) when their compose files are present.

Use `docker compose` directly whenever you need to work with a single stack. For the
monolithic application compose file at the repository root, run:

```bash
docker compose up -d
```

## 6. Post-start validation

1. Check container health: `make ps`.
2. Tail infrastructure logs: `make logs`.
3. Confirm system resources are healthy: `uptime`, `top -bn1 | head -n 15`, and
   `free -h`.
4. If a service is fronted by Cloudflare, confirm the tunnel container is running and
   the ingress rule exists in `ops/cloudflared/config.yml`.

## 7. Updating services

* Pull the latest images: `make pull`.
* Re-run `make up` to apply new images or configuration changes.
* Watchtower (defined in `compose/infra/docker-compose.yml`) performs automated hourly
  image refreshes; disable it if you prefer manual control.

Document any deviations from this process in Git so future operators inherit the same
baseline.

# Phase 2 – Authentication & Configuration Hardening

_Last updated: 2025-10-13 (UTC)_

The second recovery phase is complete. This document now serves as the
runbook for keeping authentication-dependent services healthy and for rotating
credentials without downtime.

## Flowise

* **Current state** – `docker-compose.yml` defines explicit admin credentials via
  `FLOWISE_USERNAME` and `FLOWISE_PASSWORD`. The container persists data to
  `/srv/stack/data/flowise`.
* **Rotate credentials**
  1. Pick strong replacements and update `FLOWISE_USERNAME` and
     `FLOWISE_PASSWORD` in `docker-compose.yml`.
  2. Apply the change: `docker compose up -d flowise`.
  3. Confirm login succeeds with the new credentials. Browsers that cached the
     old session may need their application storage cleared (`Application → Storage →
     Clear site data`).
* **Troubleshooting tips**
  * Check logs: `docker logs flowise`.
  * Verify the data directory retains write permissions for UID 0 inside the container.

## Paperless-ngx

* **Current state** – CSRF protection is correctly configured through
  `PAPERLESS_URL`, `PAPERLESS_CSRF_TRUSTED_ORIGINS`, and
  `PAPERLESS_ALLOWED_HOSTS`. Redis and Postgres run locally inside the same
  compose project.
* **Configuration validation checklist**
  1. Ensure the public URL in DNS matches `PAPERLESS_URL`.
  2. Regenerate passwords if Postgres credentials are rotated; the variables live in
     `docker-compose.yml` under the `postgres` service.
  3. Restart the trio in order if connectivity breaks:
     `docker compose up -d redis postgres paperless`.
* **Testing**
  * CLI: `curl -I https://paperless.abidc.dev` should return HTTP 200.
  * UI: submitting the login form should no longer produce 403 errors.

## Linkstack

* **Current state** – `APP_KEY` in `docker-compose.yml` still uses the placeholder
  `base64:please-set-me`. Generate a secure key before exposing the service.
* **Key rotation**
  1. Generate a value: `openssl rand -base64 32` and prefix it with `base64:`.
  2. Update `LINKSTACK_APP_KEY` (or `APP_KEY`) in `docker-compose.yml`.
  3. Restart the service: `docker compose up -d linkstack`.
  4. Verify logs are clean: `docker logs -f linkstack`.
* **Database care**
  * The SQLite database lives in `/srv/stack/data/linkstack`. Back it up before
    destructive changes.
  * If corruption is suspected, run `sqlite3 linkstack.sqlite "PRAGMA integrity_check;"`.

## Operational checklist

1. Document every credential rotation in your password manager.
2. Keep TLS endpoints behind Cloudflare updated when hostnames change.
3. Review `make logs` weekly to catch auth failures early.
4. Pair the procedures above with the system health commands noted in
   `ONBOARDING.md` (`uptime`, `top -bn1`, `free -h`).

With these safeguards in place Phase 3 can focus on data cleanliness and UI polish
without risking renewed authentication outages.

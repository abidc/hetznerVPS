# Phase 2 Implementation: Authentication/Configuration Fixes

## Overview
This phase addresses authentication and configuration issues preventing service usage.

---

## Step 2.1: Fix Flowise Login Issue

### Problem
Stuck on login screen with cached credentials (abid.chaudhry@gmail.com)

### Root Cause Analysis
Browser has cached invalid/old credentials that don't work with current Flowise instance

### Implementation Options

#### Option A: Client-Side Fix (Recommended - Try First)
**Action:** Clear browser cache/cookies for flowise.abidc.dev
**Steps:**
1. Open flowise.abidc.dev in browser
2. Open DevTools (F12)
3. Go to Application > Storage
4. Clear all site data for flowise.abidc.dev
5. Refresh page
6. Try logging in with correct credentials

#### Option B: Reset Flowise Credentials (If Option A fails)
**Action:** Update credentials via environment variables

**Implementation:**
```yaml
# Add to flowise service in docker-compose.yml
flowise:
  environment:
    FLOWISE_USERNAME: admin
    FLOWISE_PASSWORD: <new-secure-password>
```

**Commands:**
```bash
# 1. Update docker-compose.yml with new credentials
# 2. Recreate Flowise container
docker compose -f /srv/stack/docker-compose.yml up -d flowise

# 3. Wait for service to start
sleep 5

# 4. Verify
curl -s -o /dev/null -w "%{http_code}\n" https://flowise.abidc.dev
```

#### Option C: Reset Flowise Data (Nuclear Option)
**Action:** Clear Flowise data and reinitialize
**Risk:** Will lose all Flowise configurations and flows

```bash
# Backup first
sudo cp -r /srv/stack/data/flowise /srv/stack/data/flowise.backup

# Stop container
docker stop flowise

# Clear data
sudo rm -rf /srv/stack/data/flowise/*

# Restart container
docker start flowise
```

---

## Step 2.2: Fix Paperless CSRF Issue

### Problem
"Forbidden (403) CSRF verification failed" when creating account

### Root Cause
Missing PAPERLESS_URL causes CSRF origin mismatch when accessed via proxy

### Implementation

**Required Changes to docker-compose.yml:**
```yaml
paperless:
  environment:
    # Existing vars...
    PAPERLESS_REDIS: redis://paperless-redis:6379/0
    PAPERLESS_DBHOST: paperless-postgres
    PAPERLESS_DBPORT: 5432
    PAPERLESS_DBNAME: paperless
    PAPERLESS_DBUSER: paperless
    PAPERLESS_DBPASS: paperless
    PAPERLESS_DBENGINE: postgresql
    # Add these new vars:
    PAPERLESS_URL: https://paperless.abidc.dev
    PAPERLESS_CSRF_TRUSTED_ORIGINS: https://paperless.abidc.dev
    PAPERLESS_ALLOWED_HOSTS: paperless.abidc.dev,paperless
```

**Commands to Apply:**
```bash
# 1. Update docker-compose.yml (see changes above)

# 2. Recreate Paperless container
docker compose -f /srv/stack/docker-compose.yml up -d paperless

# 3. Wait for service to fully start
sleep 10

# 4. Verify CSRF is working
curl -s https://paperless.abidc.dev | grep -i csrf
```

**Testing:**
1. Navigate to https://paperless.abidc.dev
2. Click "Create Account" or login form
3. Fill in details and submit
4. Should NOT see CSRF error

---

## Step 2.3: Fix Linkstack Boot Loop

### Problem
Service stuck in boot loop after admin account creation

### Root Cause Options
1. Missing or invalid APP_KEY
2. Database corruption
3. Permission issues
4. Configuration mismatch

### Diagnostic Steps

**Step 1: Check Container Logs**
```bash
# View logs to identify error
docker logs linkstack --tail 100

# Common errors to look for:
# - "No application encryption key"
# - Database connection errors
# - Permission denied errors
# - Session errors
```

**Step 2: Verify APP_KEY**
```bash
# Check if APP_KEY is properly set
docker exec linkstack printenv | grep APP_KEY
```

### Implementation Options

#### Option A: Generate New APP_KEY (Most Common Fix)
**When:** Logs show "No application encryption key" or APP_KEY issues

```bash
# 1. Stop container
docker stop linkstack

# 2. Generate new APP_KEY
# Format: base64:random_string_of_32_chars
NEW_KEY="base64:$(openssl rand -base64 32)"
echo "New APP_KEY: $NEW_KEY"

# 3. Update docker-compose.yml
# Replace LINKSTACK_APP_KEY with the new key

# 4. Start container
docker start linkstack

# 5. Monitor logs
docker logs -f linkstack
```

#### Option B: Fix Database Issues
**When:** Logs show SQLite errors or corruption

```bash
# 1. Stop container
docker stop linkstack

# 2. Backup database
sudo cp /srv/stack/data/linkstack/linkstack.sqlite /srv/stack/data/linkstack/linkstack.sqlite.backup

# 3. Check database integrity
docker run --rm -v /srv/stack/data/linkstack:/data \
  alpine:latest \
  sh -c "cd /data && echo 'PRAGMA integrity_check;' | sqlite3 linkstack.sqlite"

# 4. If corrupted, start fresh
sudo rm /srv/stack/data/linkstack/linkstack.sqlite
docker start linkstack
```

#### Option C: Permission Fix
**When:** Logs show permission denied errors

```bash
# Fix ownership
sudo chown -R 1000:1000 /srv/stack/data/linkstack

# Fix permissions
sudo chmod -R 755 /srv/stack/data/linkstack

# Restart
docker restart linkstack
```

#### Option D: Complete Reset (Nuclear Option)
**When:** All else fails
**Risk:** Will lose all LinkStack data and configuration

```bash
# 1. Backup
sudo cp -r /srv/stack/data/linkstack /srv/stack/data/linkstack.backup

# 2. Stop and remove
docker stop linkstack
docker rm linkstack

# 3. Clear data
sudo rm -rf /srv/stack/data/linkstack/*

# 4. Generate fresh APP_KEY
NEW_KEY="base64:$(openssl rand -base64 32)"

# 5. Update APP_KEY in docker-compose.yml

# 6. Recreate container
docker compose -f /srv/stack/docker-compose.yml up -d linkstack

# 7. Monitor startup
docker logs -f linkstack
```

---

## Execution Order for Phase 2

1. **Flowise** (Option A first - quickest, no changes needed)
2. **Paperless** (Requires docker-compose changes)
3. **Linkstack** (Start with diagnostics, then apply appropriate fix)

## Success Criteria

- ✅ Flowise: Can login with correct credentials
- ✅ Paperless: Can create account without CSRF error
- ✅ Linkstack: Service running stable, admin can login

## Rollback Strategy

All changes can be reverted:
- Flowise: Restore from .backup directory if data was cleared
- Paperless: Remove new environment variables
- Linkstack: Restore .sqlite.backup file

## Next Steps

After Phase 2 completion, proceed to Phase 3 (Data/Rendering fixes).
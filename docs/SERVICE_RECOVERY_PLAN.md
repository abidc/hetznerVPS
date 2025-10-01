# Service Recovery Action Plan

## Issue Summary
After restoring the Cloudflare tunnel, several services are experiencing various issues ranging from authentication problems to missing configurations.

## Categorized Issues

### 🔴 Critical Infrastructure (Priority 1)
1. **Portainer** - Security timeout + 1033 error
2. **Dockge** - Cannot see docker containers

### 🟡 Authentication/Configuration (Priority 2)
3. **Flowise** - Stuck on login with cached credentials
4. **Paperless** - CSRF 403 error on account creation
5. **Linkstack** - Boot loop after admin creation

### 🟢 Data/Rendering (Priority 3)
6. **Homebox** - Static placeholder HTML
7. **Dashy** - Blank page

### 🔵 Missing Services (Priority 4)
8. **Excalidraw** - Not in tunnel config (whiteboard.abidc.dev)

---

## Systematic Resolution Plan

### Phase 1: Fix Critical Infrastructure

#### 1.1 Portainer Recovery
**Problem:** Security timeout message + needs restart
**Root Cause:** Portainer has a 5-minute initialization timeout for security
**Solution:**
```bash
docker restart portainer
```
**Verification:** Access portainer.abidc.dev and complete first-run setup

#### 1.2 Dockge Docker Socket Access
**Problem:** Cannot see docker containers
**Root Cause:** Missing docker socket mount and stacks directory
**Solution:**
- Add docker.sock volume mount
- Add stacks directory volume mount
```yaml
dockge:
  volumes:
    - /var/run/docker.sock:/var/run/docker.sock
    - /srv/stack/data/dockge:/app/data
```
**Verification:** Check if containers are visible in Dockge UI

### Phase 2: Fix Authentication/Configuration Issues

#### 2.1 Flowise Login Fix
**Problem:** Stuck on login screen with old cached credentials
**Root Cause:** Browser cached invalid credentials
**Solutions:**
A. Clear browser cache/cookies for flowise.abidc.dev
B. Reset Flowise credentials via environment variables
C. Check if authentication is properly configured
**Verification:** Can login with correct credentials

#### 2.2 Paperless CSRF Fix
**Problem:** 403 CSRF verification failed
**Root Cause:** Missing PAPERLESS_URL configuration causing CSRF origin mismatch
**Solution:**
```yaml
paperless:
  environment:
    PAPERLESS_URL: https://paperless.abidc.dev
    PAPERLESS_CSRF_TRUSTED_ORIGINS: https://paperless.abidc.dev
```
**Verification:** Can create account without CSRF error

#### 2.3 Linkstack Boot Loop
**Problem:** Service in boot loop after admin creation
**Root Cause:** Likely missing APP_KEY or database corruption
**Solutions:**
A. Check logs: `docker logs linkstack`
B. Generate proper APP_KEY if missing
C. Clear/reset database if corrupted
**Verification:** Service starts and admin can login

### Phase 3: Fix Data/Rendering Issues

#### 3.1 Homebox Placeholder
**Problem:** Shows static "homebox placeholder" HTML
**Root Cause:** Data directory not properly initialized or wrong image
**Solutions:**
A. Check if using correct image version
B. Verify data directory permissions
C. Clear and reinitialize data directory
**Verification:** Homebox loads proper UI

#### 3.2 Dashy Blank Page
**Problem:** Loads blank page
**Root Cause:** Missing or corrupt configuration file
**Solutions:**
A. Check if conf.yml exists in /srv/stack/data/dashy/
B. Create default configuration if missing
C. Check browser console for JS errors
**Verification:** Dashy loads with configuration

### Phase 4: Add Missing Services

#### 4.1 Add Excalidraw
**Problem:** whiteboard.abidc.dev returns 1033 error
**Root Cause:** Service not in docker-compose or cloudflared config
**Solution:**
A. Add excalidraw to docker-compose.yml
B. Add to cloudflared config.yml ingress rules
C. Create DNS CNAME if missing
```yaml
excalidraw:
  image: excalidraw/excalidraw:latest
  restart: unless-stopped
  ports:
    - "3001:80"
  networks:
    - net_core
```
**Verification:** whiteboard.abidc.dev loads Excalidraw

---

## Execution Order

1. **Start with infrastructure** (Portainer, Dockge) - these are needed to manage other services
2. **Fix auth/config issues** - these prevent service usage
3. **Fix data/rendering** - these affect user experience
4. **Add missing services** - this expands functionality

## Rollback Plan

If any changes cause issues:
1. Keep backup of docker-compose.yml before changes
2. Can revert specific service configs
3. Can restart individual services without affecting others
4. All data is in /srv/stack/data/ - persistent across restarts

## Success Criteria

All services should:
- ✅ Return HTTP 200
- ✅ Load proper UI (no placeholders/blank pages)
- ✅ Allow authentication where required
- ✅ Function without errors
- ✅ Be accessible via their .abidc.dev domains
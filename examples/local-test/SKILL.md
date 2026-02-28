---
name: local-test
description: >-
  Test projects locally in the Docker/OrbStack environment that mirrors
  a production VPS. Manages docker compose, nginx configs, containers,
  and verification.
  Use when testing changes, verifying a build works, checking if
  something works end-to-end, testing locally before deploying,
  spinning up the local server, debugging why something works locally
  but not on the server, or adding a new site to the Docker environment.
---

<!-- EXAMPLE SKILL: This is a redacted version of a real infrastructure skill.
     It shows how to encode a local Docker testing environment that mirrors
     production. Replace placeholders with your own values. -->

# Local Testing Environment

Docker Compose setup at `<PROJECT_PATH>` that mirrors the production VPS exactly: Nginx 1.24, Node.js 20, Python 3.12, same security headers, gzip, SSL, and routing.

**Runtime:** OrbStack (install: `brew install orbstack`, then open the app once)

## Quick Reference

```bash
# From <PROJECT_PATH>
docker compose up --build        # Start everything
docker compose up --build app nginx  # Rebuild specific services
docker compose down              # Stop all
docker compose logs nginx        # View nginx logs
docker compose logs -f app       # Follow app logs
docker compose exec nginx nginx -t   # Test nginx config
docker compose restart nginx     # Reload after config change
```

## Current Architecture

| Container | Image | Role | Port |
|-----------|-------|------|------|
| `nginx` | nginx:1.24 | Reverse proxy + static serving | 80, 443 (host) |
| `app` | node:20-slim | Node.js/Express app (long-running) | 3001 (internal) |
| `docs` | python:3.12-slim | MkDocs builder (one-shot) | none |
| `spa` | node:20-slim | Vite/React builder (one-shot) | none |

Builder containers (`docs`, `spa`) run once at startup, output to shared Docker volumes, then exit. Nginx reads from those volumes.

## Accessing Sites Locally

**Without /etc/hosts** (default):
- `https://localhost` — static content
- `https://localhost/app/` — Node.js app

**With /etc/hosts** (add: `127.0.0.1 <YOUR_DOMAIN> <ADDITIONAL_DOMAINS>`):
- `https://<YOUR_DOMAIN>` — static + app reverse proxy
- `https://<DOCS_DOMAIN>` — mkdocs documentation
- `https://<SPA_DOMAIN>` — React SPA

Self-signed SSL certs — use `curl -k` or accept browser warning.

## File Layout

```
<PROJECT_PATH>
├── docker-compose.yml                     # Orchestration
├── docker/
│   ├── nginx/
│   │   ├── nginx.conf                     # Global nginx config
│   │   ├── .htpasswd                      # Basic auth credentials
│   │   ├── sites/                         # Per-domain server blocks
│   │   │   ├── <YOUR_DOMAIN>.conf
│   │   │   └── <DOCS_DOMAIN>.conf
│   │   └── ssl/self-signed/               # Generated certs (gitignored)
│   ├── app/Dockerfile
│   ├── docs/Dockerfile
│   ├── spa/Dockerfile
│   └── scripts/generate-certs.sh
├── staging/                               # Site content (gitignored)
│   ├── <YOUR_DOMAIN>/                     # Static HTML
│   └── app/                               # Node.js app (pre-built)
```

## Adding a New Site

Follow this workflow when adding a new domain/project to the local environment.

### 1. Determine site type

- **Static site** — mount directory into nginx, no extra container
- **Node.js app** — new container + nginx reverse proxy
- **Built site (React/mkdocs/etc)** — builder container + shared volume

### 2. Create SSL cert

Add the domain to `docker/scripts/generate-certs.sh` in the `DOMAINS` array, then re-run:

```bash
bash docker/scripts/generate-certs.sh
```

### 3. Create nginx server block

Add `docker/nginx/sites/<domain>.conf`. Copy the pattern closest to your site type:

- **Static:** Use a simple static file server block as template
- **SPA (React/Vue):** Add `try_files $uri $uri/ /index.html` for client-side routing
- **Reverse proxy:** Use a `proxy_pass http://<service>:<port>` location block
- **With basic auth:** Add `auth_basic` and `auth_basic_user_file` directives

### 4. For apps needing a container

Create `docker/<app-name>/Dockerfile`, then add to `docker-compose.yml`:

**Long-running app (Node.js, Python server, etc):**
```yaml
  my-app:
    build:
      context: /absolute/path/to/source
      dockerfile: /absolute/path/to/docker/my-app/Dockerfile
    environment:
      - NODE_ENV=production
      - PORT=<port>
    expose:
      - "<port>"
    restart: unless-stopped
```

**One-shot builder (static output served by nginx):**
```yaml
  my-builder:
    build:
      context: /absolute/path/to/source
      dockerfile: /absolute/path/to/docker/my-builder/Dockerfile
    volumes:
      - my-builder-html:/output
```
Add volume to the `volumes:` section and mount in `nginx` service:
```yaml
    - my-builder-html:/var/www/<domain>:ro
```
Add dependency in nginx:
```yaml
    depends_on:
      my-builder:
        condition: service_completed_successfully
```

### 5. Mount in nginx container

For static sites, add to the nginx service `volumes:` in `docker-compose.yml`:
```yaml
    - ./staging/<domain>:/var/www/<domain>:ro
```

### 6. Rebuild and test

```bash
docker compose up --build
curl -k https://localhost/  # or use the domain with /etc/hosts
```

## Verification Checklist

After changes, verify:

- [ ] `docker compose up --build` — all containers start without errors
- [ ] `docker compose exec nginx nginx -t` — nginx config syntax OK
- [ ] `curl -k https://localhost/` — static site responds (HTML)
- [ ] `curl -k https://localhost/app/api/health` — app responds
- [ ] Any new site responds at its expected URL
- [ ] Check `docker compose logs nginx` for routing errors

## Troubleshooting

See [references/troubleshooting.md](references/troubleshooting.md) for common issues and fixes.

## VPS Parity Notes

The local environment matches the VPS in these critical areas:
- **Nginx version:** 1.24 (same binary, same module set)
- **Security headers:** HSTS, X-Frame-Options, X-Content-Type-Options, X-XSS-Protection, Referrer-Policy
- **Gzip:** level 6, same MIME types
- **SSL:** TLSv1.2/1.3, same cipher suite (self-signed certs instead of Cloudflare Origin)
- **Proxy headers:** X-Real-IP, X-Forwarded-For, X-Forwarded-Proto, websocket upgrade
- **Node.js:** v20 (same major version)
- **SPA routing:** `try_files $uri $uri/ /index.html` for React apps

**Not replicated locally:** UFW firewall, Fail2Ban, PM2 process management (Docker handles restarts), Cloudflare CDN/WAF layer.

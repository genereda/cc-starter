# Troubleshooting

## Container won't start

**Symptom:** `docker compose up` fails with build errors.

**Private repo can't clone inside Docker:**
Docker builds can't access GitHub credentials. Clone the repo locally first, then use the local path as `build.context` in `docker-compose.yml`. Use absolute paths (Docker Compose does not expand `~`).

**Port already in use (80 or 443):**
```bash
lsof -i :80   # Find what's using port 80
lsof -i :443
# Stop the conflicting process, or change ports in docker-compose.yml:
# ports: ["8080:80", "8443:443"]
```

**OrbStack not running:**
If `docker` commands fail with connection errors, open OrbStack.app. It must be running for Docker to work.

## Nginx errors

**Config syntax error:**
```bash
docker compose exec nginx nginx -t
```
This shows the exact line number and error. Common causes:
- Missing semicolon at end of directive
- Typo in `server_name` or `proxy_pass`
- SSL cert file not found (run `generate-certs.sh`)

**502 Bad Gateway on reverse proxy:**
The upstream container isn't running or isn't on the expected port.
```bash
docker compose ps          # Is the app container running?
docker compose logs app    # Check app logs for crashes
```
Verify `proxy_pass` hostname matches the service name in `docker-compose.yml` (e.g., `proxy_pass http://app:3001`).

**403 Forbidden:**
- Check the volume mount is `:ro` and the path exists
- Check file permissions in the mounted directory
- For basic auth sites, verify credentials in `.htpasswd`

**404 Not Found:**
- Verify `root` directive points to the correct `/var/www/<domain>` path
- For builder containers, check the volume is populated: `docker compose run --rm docs ls /output`
- For SPA apps, ensure `try_files $uri $uri/ /index.html` is present

## SSL certificate issues

**Browser shows "connection not secure":**
Expected with self-signed certs. Accept the warning or use `curl -k`.

**Cert file not found during nginx start:**
```bash
bash docker/scripts/generate-certs.sh
```
Then `docker compose restart nginx`.

**Regenerate all certs:**
```bash
rm docker/nginx/ssl/self-signed/*
bash docker/scripts/generate-certs.sh
docker compose restart nginx
```

## Builder container issues

**Builder fails during build:**
These are one-shot containers that build and exit. If they fail, nginx won't start (it depends on them).

```bash
docker compose logs docs   # or spa
docker compose build docs  # Rebuild just that container
```

**Volume appears empty (nginx shows 403 for built site):**
The builder container may have failed silently. Force rebuild:
```bash
docker compose down -v        # Remove volumes
docker compose up --build     # Rebuild everything fresh
```

**Source repo changes not reflected:**
Builder containers copy source at build time. After pulling new changes in the local repo:
```bash
docker compose build --no-cache spa   # Force fresh build
docker compose up
```

## App issues

**App crashes on startup:**
```bash
docker compose logs app
```
Common causes:
- Missing `.env` file
- Missing `dist/` directory (app needs to be pre-built)
- Missing npm dependencies (Dockerfile runs `npm ci --omit=dev`)

**API returns wrong responses locally vs VPS:**
Check env differences between local `.env` and production `.env`.

## Performance

**Build is slow:**
Use targeted rebuilds instead of rebuilding everything:
```bash
docker compose up --build app nginx  # Only rebuild what changed
```

**Containers use too much memory:**
Check with `docker stats`. OrbStack is lighter than Docker Desktop but Node.js containers can still consume significant RAM during builds.

## Cleanup

```bash
docker compose down           # Stop containers
docker compose down -v        # Stop + remove volumes (forces fresh builds)
docker system prune           # Remove unused images/containers
docker volume prune           # Remove unused volumes
```

# Snipe-IT Docker Swarm Deployment

Step-by-step guide for deploying the Snipe-IT stack in Docker Swarm. Access via reverse proxy at `intranet.afapitau.uy/snipeit`.

**IMPORTANT:** This stack uses Docker Secrets to manage sensitive credentials. `.env` files are not used and not required.

## Prerequisites

- Docker Swarm initialized
- Docker overlay networks:
  - `proxy-net`: Network shared with reverse proxy
  - `backend-net`: Network for backend service communication
- `reverse-proxy` stack deployed
- Proxy configuration: `/srv/iac/infra-deployments/reverse-proxy/conf.d/locations/500-snipeit.conf`

## Production Deployment Steps

### 0. Complete Cleanup (testing only)

To validate the procedure from scratch:

```bash
# Remove stack
docker stack rm snipe-it

# Wait until no services remain
docker service ls | grep snipe-it

# Remove secrets (if they exist)
docker secret rm snipeit_app_key snipeit_db_password snipeit_mysql_root_password
docker secret rm snipeit_mail_username snipeit_mail_password 2>/dev/null || true
```

**Note:** This does not delete persistent data in `/srv/data/snipe-it/`. If you delete secrets and keep `/srv/data/snipe-it/db`, the `snipeit` user will retain the previous password and connection will fail. For testing from scratch, delete the contents of `/srv/data/snipe-it/db` or keep the original secrets.

### 1. Verify Docker Networks

```bash
docker network ls | grep -E "proxy-net|backend-net"
```

If they don't exist, create them:

```bash
docker network create --driver overlay proxy-net
docker network create --driver overlay backend-net
```

### 2. Create Docker Secrets

Secrets are required for the stack to function. Create the following secrets:

#### a) APP_KEY (Laravel Application Key)

Generate a new APP_KEY:

```bash
APP_KEY=$(docker run --rm snipe/snipe-it:latest php artisan key:generate --show | grep -oP 'base64:[^\s]+' || echo "base64:$(openssl rand -base64 32)")
echo -n "$APP_KEY" | docker secret create snipeit_app_key -
```

**OR** if you already have an APP_KEY:

```bash
echo -n "base64:YOUR_BASE64_KEY_HERE" | docker secret create snipeit_app_key -
```

#### b) DB_PASSWORD (Database User Password)

```bash
echo -n "your_secure_password_here" | docker secret create snipeit_db_password -
```

#### c) MYSQL_ROOT_PASSWORD (MariaDB Root Password)

```bash
echo -n "your_root_password_here" | docker secret create snipeit_mysql_root_password -
```

#### d) Optional Email Secrets

For SMTP email configuration, see [Email Configuration](email-configuration.md).

**Note:** If you don't create these email secrets, the stack will function but email will not be configured.

### 3. Verify Created Secrets

```bash
docker secret ls | grep snipeit
```

You should see at least:
- `snipeit_app_key`
- `snipeit_db_password`
- `snipeit_mysql_root_password`

### 4. Verify Data Directories

Persistent data is stored in:

```bash
# Verify they exist
ls -la /srv/data/snipe-it/storage
ls -la /srv/data/snipe-it/db

# If they don't exist, create them
mkdir -p /srv/data/snipe-it/storage
mkdir -p /srv/data/snipe-it/db

# Ensure correct permissions
chown -R 1000:1000 /srv/data/snipe-it/storage
chmod -R 755 /srv/data/snipe-it/storage
```

### 5. Deploy the Stack

```bash
cd /home/ralex/apps/snipe-it
docker stack deploy -c docker-compose.yml snipe-it
```

### 6. Verify Deployment

```bash
# View stack services
docker service ls | grep snipe-it

# View detailed service status
docker service ps snipe-it_snipe-it-app --no-trunc
docker service ps snipe-it_snipe-it-db --no-trunc

# View application logs
docker service logs snipe-it_snipe-it-app --tail 50

# View database logs
docker service logs snipe-it_snipe-it-db --tail 50
```

### 7. Redeploy Reverse Proxy

For the proxy to load the Snipe-IT configuration:

```bash
cd /srv/iac/infra-deployments
docker stack deploy -c reverse-proxy/reverse_proxy-stack.yml reverse-proxy
```

**Note:** The reverse proxy is in `infra-deployments` because it's shared infrastructure. The Snipe-IT stack is in this repository.

### 8. Verify Access

Access `https://intranet.afapitau.uy/snipeit` (or `http://` if SSL is not configured).

## Required Secrets

| Secret | Description | Required |
|--------|-------------|----------|
| `snipeit_app_key` | Laravel application key (generate with `php artisan key:generate`) | Yes |
| `snipeit_db_password` | Database user password | Yes |
| `snipeit_mysql_root_password` | MariaDB root password | Yes |
| `snipeit_email_credentials` | Email credentials in JSON format | No |

## Secret Structure

Secrets are mounted at `/run/secrets/{secret_name}` inside the container. The `entrypoint-wrapper.sh` script reads these secrets and exports them as environment variables before starting Snipe-IT.

## Stack Updates

To update the stack after changes:

```bash
cd /home/ralex/apps/snipe-it
docker stack deploy -c docker-compose.yml snipe-it
```

Swarm will update only modified services with a rolling update.

## Secret Management

### View Existing Secrets

```bash
docker secret ls | grep snipeit
```

### View Secret Content (manager node only)

```bash
docker secret inspect snipeit_app_key --format '{{.Spec.Data}}' | base64 -d && echo
```

### Update a Secret

**IMPORTANT:** Secrets in Docker Swarm are immutable. To "update", you must:

1. Create a new secret with a different name or remove the previous one
2. Update the service to use the new secret
3. Remove the old secret

Example password rotation:

```bash
# 1. Create new password
echo -n "new_secure_password" | docker secret create snipeit_db_password_v2 -

# 2. Update the service (this requires updating docker-compose.yml first)
# Edit docker-compose.yml and change snipeit_db_password to snipeit_db_password_v2
cd /home/ralex/apps/snipe-it
docker stack deploy -c docker-compose.yml snipe-it

# 3. Once verified working, remove the old secret
docker secret rm snipeit_db_password
```

### Remove Secrets

```bash
# First remove the stack that uses the secret
docker stack rm snipe-it

# Then remove the secret
docker secret rm snipeit_app_key
```

## Troubleshooting

### Service Not Starting

```bash
# View detailed logs
docker service logs snipe-it_snipe-it-app --tail 100 --follow

# View task status
docker service ps snipe-it_snipe-it-app --no-trunc
```

If you see errors about missing secrets:

```bash
# Verify secrets exist
docker secret ls | grep snipeit

# Verify wrapper logs
docker service logs snipe-it_snipe-it-app | grep -i "WRAPPER\|ERROR\|secret"
```

### Database Connection Error

1. Verify the DB service is healthy:

```bash
docker service ps snipe-it_snipe-it-db
```

2. Verify DB logs:

```bash
docker service logs snipe-it_snipe-it-db --tail 100
```

3. Verify both services are on `backend-net`:

```bash
docker service inspect snipe-it_snipe-it-app | grep -A 10 Networks
docker service inspect snipe-it_snipe-it-db | grep -A 10 Networks
```

### Proxy 502 Error

1. Verify the application service is running:

```bash
docker service ls | grep snipe-it
```

2. Verify the service is on the `proxy-net` network:

```bash
docker service inspect snipe-it_snipe-it-app | grep proxy-net
```

3. Verify service DNS resolution:

```bash
# From inside a proxy container
docker exec -it $(docker ps -q -f name=reverse-proxy_nginx) nslookup snipe-it_snipe-it-app
```

4. Verify proxy logs:

```bash
docker service logs reverse-proxy_nginx --tail 100 | grep snipeit
```

### Volume Permission Issues

```bash
# Verify permissions
ls -la /srv/data/snipe-it/

# Adjust permissions if necessary
chown -R 1000:1000 /srv/data/snipe-it/storage
chmod -R 755 /srv/data/snipe-it/storage
```

### Verify Wrapper is Reading Secrets

```bash
docker service logs snipe-it_snipe-it-app | grep -i "WRAPPER"
```

You should see messages like:
```
[SNIPE-IT WRAPPER] Iniciando entrypoint-wrapper.sh
[SNIPE-IT WRAPPER] APP_KEY configurado desde secret
[SNIPE-IT WRAPPER] DB_PASSWORD configurado desde secret
```

## Stack Removal

To remove the complete stack:

```bash
docker stack rm snipe-it
```

**Warning:** This removes services but **NOT** volumes or secrets. Data in `/srv/data/snipe-it/` is preserved.

To also remove data:

```bash
# First remove the stack
docker stack rm snipe-it

# Wait for services to stop
docker service ls | grep snipe-it

# Remove data (CAUTION! This deletes all information)
rm -rf /srv/data/snipe-it/
```

## Important Notes

- The stack name **must be** `snipe-it` for the proxy to resolve `snipe-it_snipe-it-app:80`
- The application service must be named `snipe-it-app` to maintain consistency with proxy configuration
- Volumes use absolute paths (`/srv/data/snipe-it/`) for Swarm compatibility
- Services are restricted to `manager` nodes for consistency
- The application service healthcheck has a `start_period` of 120s to allow Laravel to complete initial migrations
- **`.env` files are NOT used** - everything is managed through Docker Secrets

## References

- [Official Snipe-IT Documentation](https://snipe-it.readme.io/docs)
- [Docker Swarm Documentation](https://docs.docker.com/engine/swarm/)
- [Docker Secrets Documentation](https://docs.docker.com/engine/swarm/secrets/)

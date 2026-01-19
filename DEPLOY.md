# Snipe-IT - Despliegue en Producción

## Prerequisitos

- Docker Swarm inicializado (`docker swarm init`)
- Redes creadas:
  ```bash
  docker network create --driver overlay proxy-net
  docker network create --driver overlay backend-net
  ```

## 1. Clonar repositorio

```bash
cd /home/$USER/apps
git clone https://github.com/ralexrivero/snipe-it.git
cd snipe-it
```

## 2. Crear directorios de datos

```bash
sudo mkdir -p /srv/data/snipe-it/{storage,db}
sudo chown -R $USER:$USER /srv/data/snipe-it
```

## 3. Crear secrets

```bash
# Generar APP_KEY (debe empezar con "base64:")
echo "base64:$(openssl rand -base64 32)" | docker secret create snipeit_app_key -

# Contraseñas de base de datos
openssl rand -base64 32 | docker secret create snipeit_db_password -
openssl rand -base64 32 | docker secret create snipeit_mysql_root_password -
```

## 4. Desplegar stack

```bash
docker stack deploy -c docker-compose.yml snipe-it
```

## 5. Configurar reverse proxy (nginx)

Copiar configuración de location a nginx:
```bash
# El archivo 500-snipeit.conf debe estar en:
# /srv/iac/infra-deployments/reverse-proxy/conf.d/locations/500-snipeit.conf
```

Reiniciar nginx:
```bash
docker service update --force reverse-proxy_nginx
```

## 6. Acceder al setup

```
https://intranet.afapitau.uy/snipeit/setup
```

## Verificar estado

```bash
docker service ls | grep snipe-it
docker service logs snipe-it_snipe-it-app --tail 20
```

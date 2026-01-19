# Despliegue de Snipe-IT en Docker Swarm

## Descripción

Stack de Snipe-IT desplegado en Docker Swarm, accesible a través del proxy reverso en `intranet.afapitau.uy/snipeit`.

**IMPORTANTE:** Este stack utiliza Docker Secrets para gestionar credenciales sensibles. No se utilizan archivos `.env`.

## Requisitos Previos

- Docker Swarm inicializado
- Redes Docker overlay existentes:
  - `proxy-net`: Red compartida con el proxy reverso
  - `backend-net`: Red para comunicación entre servicios backend
- Stack `reverse-proxy` desplegado
- Configuración del proxy: `/srv/iac/infra-deployments/reverse-proxy/conf.d/locations/500-snipeit.conf`

## Pasos para Desplegar en Producción

### 1. Verificar redes Docker

```bash
docker network ls | grep -E "proxy-net|backend-net"
```

Si no existen, crearlas:

```bash
docker network create --driver overlay proxy-net
docker network create --driver overlay backend-net
```

### 2. Crear Docker Secrets

Los secrets son obligatorios para que el stack funcione. Crear los siguientes secrets:

#### a) APP_KEY (Laravel Application Key)

Generar una nueva APP_KEY:

```bash
APP_KEY=$(docker run --rm snipe/snipe-it:latest php artisan key:generate --show | grep -oP 'base64:[^\s]+' || echo "base64:$(openssl rand -base64 32)")
echo -n "$APP_KEY" | docker secret create snipeit_app_key -
```

**O** si ya tienes una APP_KEY:

```bash
echo -n "base64:TU_CLAVE_BASE64_AQUI" | docker secret create snipeit_app_key -
```

#### b) DB_PASSWORD (Password de usuario de base de datos)

```bash
echo -n "tu_password_seguro_aqui" | docker secret create snipeit_db_password -
```

#### c) MYSQL_ROOT_PASSWORD (Password root de MariaDB)

```bash
echo -n "tu_root_password_seguro_aqui" | docker secret create snipeit_mysql_root_password -
```

#### d) Secrets opcionales de Email

Si necesitas configuración de email SMTP:

```bash
# Usuario SMTP (opcional)
echo -n "usuario@smtp.example.com" | docker secret create snipeit_mail_username -

# Password SMTP (opcional)
echo -n "password_smtp_aqui" | docker secret create snipeit_mail_password -
```

**Nota:** Si no creas estos secrets de email, el stack seguirá funcionando pero el email no estará configurado.

### 3. Verificar secrets creados

```bash
docker secret ls | grep snipeit
```

Deberías ver al menos:
- `snipeit_app_key`
- `snipeit_db_password`
- `snipeit_mysql_root_password`

### 4. Verificar directorios de datos

Los datos persistentes se almacenan en:

```bash
# Verificar que existen
ls -la /srv/data/snipe-it/storage
ls -la /srv/data/snipe-it/db

# Si no existen, crearlos
mkdir -p /srv/data/snipe-it/storage
mkdir -p /srv/data/snipe-it/db

# Asegurar permisos correctos
chown -R 1000:1000 /srv/data/snipe-it/storage
chmod -R 755 /srv/data/snipe-it/storage
```

### 5. Desplegar el stack

```bash
cd /home/ralex/apps/snipe-it
docker stack deploy -c docker-compose.yml snipe-it
```

### 6. Verificar despliegue

```bash
# Ver servicios del stack
docker service ls | grep snipe-it

# Ver estado detallado de servicios
docker service ps snipe-it_snipe-it-app --no-trunc
docker service ps snipe-it_snipe-it-db --no-trunc

# Ver logs de la aplicación
docker service logs snipe-it_snipe-it-app --tail 50

# Ver logs de la base de datos
docker service logs snipe-it_snipe-it-db --tail 50
```

### 7. Redesplegar proxy reverso

Para que el proxy cargue la configuración de Snipe-IT:

```bash
cd /srv/iac/infra-deployments
docker stack deploy -c reverse-proxy/reverse_proxy-stack.yml reverse-proxy
```

**Nota:** El proxy reverso está en `infra-deployments` porque es infraestructura compartida. El stack de Snipe-IT está en este repositorio.

### 8. Verificar acceso

Acceder a `https://intranet.afapitau.uy/snipeit` (o `http://` si no hay SSL configurado).

## Secretos Requeridos

| Secreto | Descripción | Obligatorio |
|---------|-------------|-------------|
| `snipeit_app_key` | Clave de aplicación Laravel (generar con `php artisan key:generate`) | Sí |
| `snipeit_db_password` | Password del usuario de base de datos | Sí |
| `snipeit_mysql_root_password` | Password root de MariaDB | Sí |
| `snipeit_mail_username` | Usuario SMTP para emails | No |
| `snipeit_mail_password` | Password SMTP para emails | No |

## Estructura de Secretos

Los secrets se montan en `/run/secrets/{secret_name}` dentro del contenedor. El script `entrypoint-wrapper.sh` lee estos secrets y los exporta como variables de entorno antes de iniciar Snipe-IT.

## Actualización del Stack

Para actualizar el stack después de cambios:

```bash
cd /home/ralex/apps/snipe-it
docker stack deploy -c docker-compose.yml snipe-it
```

Swarm actualizará solo los servicios modificados con un rolling update.

## Gestión de Secretos

### Ver secretos existentes

```bash
docker secret ls | grep snipeit
```

### Ver contenido de un secreto (solo en el nodo manager)

```bash
docker secret inspect snipeit_app_key --format '{{.Spec.Data}}' | base64 -d && echo
```

### Actualizar un secreto

**IMPORTANTE:** Los secrets en Docker Swarm son inmutables. Para "actualizar", debes:

1. Crear un nuevo secreto con nombre diferente o eliminar el anterior
2. Actualizar el servicio para usar el nuevo secreto
3. Eliminar el secreto antiguo

Ejemplo de rotación de password:

```bash
# 1. Crear nuevo password
echo -n "nuevo_password_seguro" | docker secret create snipeit_db_password_v2 -

# 2. Actualizar el servicio (esto requiere actualizar docker-compose.yml primero)
# Editar docker-compose.yml y cambiar snipeit_db_password por snipeit_db_password_v2
cd /home/ralex/apps/snipe-it
docker stack deploy -c docker-compose.yml snipe-it

# 3. Una vez verificado que funciona, eliminar el secreto antiguo
docker secret rm snipeit_db_password
```

### Eliminar secretos

```bash
# Primero eliminar el stack que usa el secreto
docker stack rm snipe-it

# Luego eliminar el secreto
docker secret rm snipeit_app_key
```

## Troubleshooting

### Servicio no inicia

```bash
# Ver logs detallados
docker service logs snipe-it_snipe-it-app --tail 100 --follow

# Ver estado de las tareas
docker service ps snipe-it_snipe-it-app --no-trunc
```

Si ves errores sobre secrets faltantes:

```bash
# Verificar que los secrets existan
docker secret ls | grep snipeit

# Verificar logs del wrapper
docker service logs snipe-it_snipe-it-app | grep -i "WRAPPER\|ERROR\|secret"
```

### Error de conexión a base de datos

1. Verificar que el servicio de DB esté saludable:

```bash
docker service ps snipe-it_snipe-it-db
```

2. Verificar logs de la DB:

```bash
docker service logs snipe-it_snipe-it-db --tail 100
```

3. Verificar que ambos servicios estén en `backend-net`:

```bash
docker service inspect snipe-it_snipe-it-app | grep -A 10 Networks
docker service inspect snipe-it_snipe-it-db | grep -A 10 Networks
```

### Error 502 del proxy

1. Verificar que el servicio de aplicación esté corriendo:

```bash
docker service ls | grep snipe-it
```

2. Verificar que el servicio esté en la red `proxy-net`:

```bash
docker service inspect snipe-it_snipe-it-app | grep proxy-net
```

3. Verificar resolución DNS del servicio:

```bash
# Desde dentro de un contenedor del proxy
docker exec -it $(docker ps -q -f name=reverse-proxy_nginx) nslookup snipe-it_snipe-it-app
```

4. Verificar logs del proxy:

```bash
docker service logs reverse-proxy_nginx --tail 100 | grep snipeit
```

### Problemas de permisos en volúmenes

```bash
# Verificar permisos
ls -la /srv/data/snipe-it/

# Ajustar permisos si es necesario
chown -R 1000:1000 /srv/data/snipe-it/storage
chmod -R 755 /srv/data/snipe-it/storage
```

### Verificar que el wrapper está leyendo los secrets

```bash
docker service logs snipe-it_snipe-it-app | grep -i "WRAPPER"
```

Deberías ver mensajes como:
```
[SNIPE-IT WRAPPER] Iniciando entrypoint-wrapper.sh
[SNIPE-IT WRAPPER] APP_KEY configurado desde secret
[SNIPE-IT WRAPPER] DB_PASSWORD configurado desde secret
```

## Eliminación del Stack

Para eliminar el stack completo:

```bash
docker stack rm snipe-it
```

**Advertencia:** Esto elimina los servicios pero **NO** los volúmenes ni los secrets. Los datos en `/srv/data/snipe-it/` se mantienen.

Para eliminar también los datos:

```bash
# Primero eliminar el stack
docker stack rm snipe-it

# Esperar a que los servicios se detengan
docker service ls | grep snipe-it

# Eliminar datos (¡CUIDADO! Esto borra toda la información)
rm -rf /srv/data/snipe-it/
```

## Notas Importantes

- El nombre del stack **debe ser** `snipe-it` para que el proxy pueda resolver `snipe-it_snipe-it-app:80`
- El servicio de aplicación debe llamarse `snipe-it-app` para mantener consistencia con la configuración del proxy
- Los volúmenes usan rutas absolutas (`/srv/data/snipe-it/`) para compatibilidad con Swarm
- Los servicios están restringidos a nodos `manager` para mantener consistencia
- El healthcheck del servicio de aplicación tiene un `start_period` de 120s para permitir que Laravel complete las migraciones iniciales
- **NO se utilizan archivos `.env`** - todo se gestiona a través de Docker Secrets

## Referencias

- [Documentación oficial de Snipe-IT](https://snipe-it.readme.io/docs)
- [Docker Swarm documentation](https://docs.docker.com/engine/swarm/)
- [Docker Secrets documentation](https://docs.docker.com/engine/swarm/secrets/)

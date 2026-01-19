#!/bin/sh
set -e

echo "[SNIPE-IT WRAPPER] Iniciando entrypoint-wrapper.sh"

# Leer secretos de Docker Swarm y exportarlos como variables de entorno
# Docker Swarm monta los secrets en /run/secrets/{secret_name}

if [ -f "/run/secrets/snipeit_app_key" ]; then
    export APP_KEY=$(cat /run/secrets/snipeit_app_key)
    echo "[SNIPE-IT WRAPPER] APP_KEY configurado desde secret"
else
    echo "[SNIPE-IT WRAPPER] ERROR: No se encontró /run/secrets/snipeit_app_key"
    exit 1
fi

if [ -f "/run/secrets/snipeit_db_password" ]; then
    export DB_PASSWORD=$(cat /run/secrets/snipeit_db_password)
    echo "[SNIPE-IT WRAPPER] DB_PASSWORD configurado desde secret"
else
    echo "[SNIPE-IT WRAPPER] ERROR: No se encontró /run/secrets/snipeit_db_password"
    exit 1
fi

if [ -f "/run/secrets/snipeit_mysql_root_password" ]; then
    export MYSQL_ROOT_PASSWORD=$(cat /run/secrets/snipeit_mysql_root_password)
    echo "[SNIPE-IT WRAPPER] MYSQL_ROOT_PASSWORD configurado desde secret"
else
    echo "[SNIPE-IT WRAPPER] ERROR: No se encontró /run/secrets/snipeit_mysql_root_password"
    exit 1
fi

# Variables opcionales (mail)
if [ -f "/run/secrets/snipeit_mail_password" ]; then
    export MAIL_PASSWORD=$(cat /run/secrets/snipeit_mail_password)
    echo "[SNIPE-IT WRAPPER] MAIL_PASSWORD configurado desde secret"
fi

if [ -f "/run/secrets/snipeit_mail_username" ]; then
    export MAIL_USERNAME=$(cat /run/secrets/snipeit_mail_username)
    echo "[SNIPE-IT WRAPPER] MAIL_USERNAME configurado desde secret"
fi

echo "[SNIPE-IT WRAPPER] Todos los secrets leídos correctamente"

# NO configurar RewriteBase - Laravel debe pensar que está en la raíz
# El proxy reverso maneja el prefijo /snipeit
echo "[SNIPE-IT WRAPPER] Laravel configurado para raíz, proxy maneja /snipeit"

echo "[SNIPE-IT WRAPPER] Cediendo ejecución al entrypoint original de Snipe-IT"

# Ejecutar el entrypoint original de Snipe-IT
# La imagen oficial usa /startup.sh como script de inicio
if [ -f "/startup.sh" ]; then
    exec /startup.sh "$@"
elif [ -f "/start.sh" ]; then
    exec /start.sh "$@"
elif [ -f "/entrypoint" ]; then
    exec /entrypoint "$@"
else
    # Si no encontramos el entrypoint, ejecutar directamente php-fpm o apache
    exec "$@"
fi

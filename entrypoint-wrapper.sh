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

# Variables de email desde secreto JSON
if [ -f "/run/secrets/snipeit_email_credentials" ]; then
    # Leer el JSON y extraer los valores usando jq o python
    if command -v jq >/dev/null 2>&1; then
        export MAIL_HOST=$(cat /run/secrets/snipeit_email_credentials | jq -r '.smtp_host')
        export MAIL_PORT=$(cat /run/secrets/snipeit_email_credentials | jq -r '.smtp_port // 587')
        export MAIL_ENCRYPTION=$(cat /run/secrets/snipeit_email_credentials | jq -r '.smtp_encryption // "tls"')
        export MAIL_USERNAME=$(cat /run/secrets/snipeit_email_credentials | jq -r '.smtp_username')
        export MAIL_PASSWORD=$(cat /run/secrets/snipeit_email_credentials | jq -r '.smtp_password')
        export MAIL_FROM_ADDR=$(cat /run/secrets/snipeit_email_credentials | jq -r '.email')
        echo "[SNIPE-IT WRAPPER] Credenciales de email configuradas desde secreto JSON (usando jq)"
    elif command -v python3 >/dev/null 2>&1; then
        export MAIL_HOST=$(python3 -c "import json, sys; d=json.load(sys.stdin); print(d.get('smtp_host', ''))" < /run/secrets/snipeit_email_credentials)
        export MAIL_PORT=$(python3 -c "import json, sys; d=json.load(sys.stdin); print(d.get('smtp_port', 587))" < /run/secrets/snipeit_email_credentials)
        export MAIL_ENCRYPTION=$(python3 -c "import json, sys; d=json.load(sys.stdin); print(d.get('smtp_encryption', 'tls'))" < /run/secrets/snipeit_email_credentials)
        export MAIL_USERNAME=$(python3 -c "import json, sys; d=json.load(sys.stdin); print(d.get('smtp_username', ''))" < /run/secrets/snipeit_email_credentials)
        export MAIL_PASSWORD=$(python3 -c "import json, sys; d=json.load(sys.stdin); print(d.get('smtp_password', ''))" < /run/secrets/snipeit_email_credentials)
        export MAIL_FROM_ADDR=$(python3 -c "import json, sys; d=json.load(sys.stdin); print(d.get('email', ''))" < /run/secrets/snipeit_email_credentials)
        echo "[SNIPE-IT WRAPPER] Credenciales de email configuradas desde secreto JSON (usando python3)"
    else
        # Fallback: usar grep y sed (menos robusto pero funciona)
        export MAIL_HOST=$(grep -o '"smtp_host":\s*"[^"]*"' /run/secrets/snipeit_email_credentials | sed 's/.*"smtp_host":\s*"\([^"]*\)".*/\1/')
        export MAIL_PORT=$(grep -o '"smtp_port":\s*[0-9]*' /run/secrets/snipeit_email_credentials | grep -o '[0-9]*' || echo "587")
        export MAIL_ENCRYPTION=$(grep -o '"smtp_encryption":\s*"[^"]*"' /run/secrets/snipeit_email_credentials | sed 's/.*"smtp_encryption":\s*"\([^"]*\)".*/\1/' || echo "tls")
        export MAIL_USERNAME=$(grep -o '"smtp_username":\s*"[^"]*"' /run/secrets/snipeit_email_credentials | sed 's/.*"smtp_username":\s*"\([^"]*\)".*/\1/')
        export MAIL_PASSWORD=$(grep -o '"smtp_password":\s*"[^"]*"' /run/secrets/snipeit_email_credentials | sed 's/.*"smtp_password":\s*"\([^"]*\)".*/\1/')
        export MAIL_FROM_ADDR=$(grep -o '"email":\s*"[^"]*"' /run/secrets/snipeit_email_credentials | sed 's/.*"email":\s*"\([^"]*\)".*/\1/')
        echo "[SNIPE-IT WRAPPER] Credenciales de email configuradas desde secreto JSON (usando grep/sed)"
    fi
    
    # Configurar valores por defecto si no están en el JSON
    export MAIL_PORT=${MAIL_PORT:-587}
    export MAIL_ENCRYPTION=${MAIL_ENCRYPTION:-tls}
    export MAIL_REPLYTO_ADDR=${MAIL_FROM_ADDR}
    echo "[SNIPE-IT WRAPPER] MAIL_HOST=${MAIL_HOST}"
    echo "[SNIPE-IT WRAPPER] MAIL_PORT=${MAIL_PORT}"
    echo "[SNIPE-IT WRAPPER] MAIL_ENCRYPTION=${MAIL_ENCRYPTION}"
    echo "[SNIPE-IT WRAPPER] MAIL_USERNAME=${MAIL_USERNAME}"
    echo "[SNIPE-IT WRAPPER] MAIL_FROM_ADDR=${MAIL_FROM_ADDR}"
else
    echo "[SNIPE-IT WRAPPER] WARNING: No se encontró /run/secrets/snipeit_email_credentials, usando valores por defecto"
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

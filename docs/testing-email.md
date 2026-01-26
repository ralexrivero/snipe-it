# Pruebas de Configuración de Email

Esta guía describe cómo verificar que la configuración de email está correctamente implementada y funcionando.

## Verificación Paso a Paso

### 1. Verificar que el Secreto Existe

Comprobar que el secreto de Docker Swarm está creado:

```bash
docker secret ls | grep snipeit_email_credentials
```

Deberías ver una salida similar a:
```
snipeit_email_credentials   X minutes ago
```

### 2. Verificar que el Servicio Usa el Secreto

Verificar que el servicio tiene el secreto montado:

```bash
docker service inspect snipe-it_snipe-it-app --format '{{json .Spec.TaskTemplate.ContainerSpec.Secrets}}' | python3 -m json.tool
```

Deberías ver `snipeit_email_credentials` en la lista de secrets.

### 3. Verificar que el Secreto Está Montado en el Contenedor

Verificar que el archivo del secreto existe dentro del contenedor:

```bash
docker exec $(docker ps -qf "name=snipe-it.*app" | head -1) ls -la /run/secrets/snipeit_email_credentials
```

Deberías ver el archivo con permisos de solo lectura.

### 4. Verificar Contenido del Secreto (Estructura JSON)

Verificar que el secreto contiene un JSON válido:

```bash
docker exec $(docker ps -qf "name=snipe-it.*app" | head -1) cat /run/secrets/snipeit_email_credentials
```

Deberías ver un JSON con las claves: `smtp_host`, `smtp_username`, `smtp_password`, `email`.

### 5. Verificar que el Wrapper Lee el Secreto

Verificar en los logs que el entrypoint-wrapper.sh está leyendo el secreto:

```bash
docker service logs snipe-it_snipe-it-app | grep -i "WRAPPER\|email\|MAIL"
```

Deberías ver mensajes como:
```
[SNIPE-IT WRAPPER] Credenciales de email configuradas desde secreto JSON (usando python3)
[SNIPE-IT WRAPPER] MAIL_HOST=167.254.0.177
[SNIPE-IT WRAPPER] MAIL_USERNAME=unioncapital3\snipeit
[SNIPE-IT WRAPPER] MAIL_FROM_ADDR=snipeit@afapitau.com.uy
```

### 6. Verificar Variables de Entorno en el Contenedor

Verificar que las variables de entorno están configuradas:

```bash
docker exec $(docker ps -qf "name=snipe-it.*app" | head -1) env | grep -E "MAIL_"
```

Deberías ver:
- `MAIL_HOST=167.254.0.177`
- `MAIL_USERNAME=unioncapital3\snipeit`
- `MAIL_PASSWORD=...` (el password)
- `MAIL_FROM_ADDR=snipeit@afapitau.com.uy`
- `MAIL_PORT=25`
- `MAIL_ENCRYPTION=` (vacío)
- `MAIL_MAILER=smtp`

### 7. Verificar Configuración en Laravel

Verificar que Laravel puede leer la configuración de email:

```bash
docker exec $(docker ps -qf "name=snipe-it.*app" | head -1) php artisan tinker --execute="echo 'SMTP Host: ' . config('mail.mailers.smtp.host') . PHP_EOL; echo 'SMTP Port: ' . config('mail.mailers.smtp.port') . PHP_EOL; echo 'From Address: ' . config('mail.from.address') . PHP_EOL; echo 'From Name: ' . config('mail.from.name') . PHP_EOL;"
```

Deberías ver:
```
SMTP Host: 167.254.0.177
SMTP Port: 25
From Address: snipeit@afapitau.com.uy
From Name: Snipe-IT
```

### 8. Probar Conexión SMTP

Probar que el servidor SMTP es accesible desde el contenedor:

```bash
docker exec $(docker ps -qf "name=snipe-it.*app" | head -1) nc -zv 167.254.0.177 25
```

O usando telnet:

```bash
docker exec $(docker ps -qf "name=snipe-it.*app" | head -1) sh -c "echo 'QUIT' | telnet 167.254.0.177 25"
```

Deberías ver una conexión exitosa al puerto 25.

### 9. Probar Envío de Email desde la Interfaz Web

1. Acceder a https://intranet.afapitau.uy/snipeit/setup
2. Navegar a la sección "Email"
3. Hacer clic en "Send Test"
4. Verificar que aparece un mensaje de éxito

### 10. Verificar Logs de Laravel para Errores de Email

Si el envío falla, revisar los logs de Laravel:

```bash
docker exec $(docker ps -qf "name=snipe-it.*app" | head -1) tail -100 /var/www/html/storage/logs/laravel.log | grep -i "mail\|smtp\|email"
```

### 11. Probar Envío de Email desde Tinker (Opcional)

Probar el envío directamente desde Laravel Tinker:

```bash
docker exec -it $(docker ps -qf "name=snipe-it.*app" | head -1) php artisan tinker
```

Dentro de tinker, ejecutar:

```php
Mail::raw('Test email from Snipe-IT', function ($message) {
    $message->to('tu-email@ejemplo.com')
            ->subject('Test Email');
});
```

## Script de Verificación Automática

Puedes usar este script para verificar todos los puntos anteriores:

```bash
#!/bin/bash
# Script de verificación de configuración de email

CONTAINER=$(docker ps -qf "name=snipe-it.*app" | head -1)

if [ -z "$CONTAINER" ]; then
    echo "ERROR: No se encontró el contenedor de Snipe-IT"
    exit 1
fi

echo "=== Verificación de Configuración de Email ==="
echo ""

echo "1. Verificando secreto en Swarm..."
docker secret ls | grep snipeit_email_credentials && echo "✓ Secreto existe" || echo "✗ Secreto no encontrado"

echo ""
echo "2. Verificando secreto montado en contenedor..."
docker exec $CONTAINER test -f /run/secrets/snipeit_email_credentials && echo "✓ Secreto montado" || echo "✗ Secreto no montado"

echo ""
echo "3. Verificando variables de entorno..."
docker exec $CONTAINER env | grep -E "MAIL_HOST|MAIL_USERNAME|MAIL_FROM_ADDR" && echo "✓ Variables configuradas" || echo "✗ Variables no encontradas"

echo ""
echo "4. Verificando configuración en Laravel..."
docker exec $CONTAINER php artisan tinker --execute="echo config('mail.mailers.smtp.host');" | grep -q "167.254.0.177" && echo "✓ Configuración correcta" || echo "✗ Configuración incorrecta"

echo ""
echo "5. Verificando conectividad SMTP..."
docker exec $CONTAINER nc -zv 167.254.0.177 25 2>&1 | grep -q "succeeded" && echo "✓ SMTP accesible" || echo "✗ SMTP no accesible"

echo ""
echo "=== Verificación completada ==="
```

## Problemas Comunes

### El secreto no está montado

**Síntoma:** No se encuentra `/run/secrets/snipeit_email_credentials` en el contenedor.

**Solución:**
1. Verificar que el secreto existe: `docker secret ls | grep snipeit_email_credentials`
2. Verificar que el servicio tiene el secreto: `docker service inspect snipe-it_snipe-it-app | grep snipeit_email_credentials`
3. Redesplegar el servicio: `docker service update --force snipe-it_snipe-it-app`

### Las variables de entorno no están configuradas

**Síntoma:** `env | grep MAIL_` no muestra las variables.

**Solución:**
1. Verificar logs del wrapper: `docker service logs snipe-it_snipe-it-app | grep WRAPPER`
2. Verificar que Python3 está disponible: `docker exec $CONTAINER which python3`
3. Verificar que el JSON es válido: `docker exec $CONTAINER python3 -m json.tool /run/secrets/snipeit_email_credentials`

### Laravel no puede leer la configuración

**Síntoma:** `config('mail.mailers.smtp.host')` retorna null o valor incorrecto.

**Solución:**
1. Limpiar caché de configuración: `docker exec $CONTAINER php artisan config:clear`
2. Verificar que las variables de entorno están disponibles
3. Verificar logs de Laravel para errores

### Error de conexión SMTP

**Síntoma:** El envío de email falla con error de conexión.

**Solución:**
1. Verificar conectividad de red: `docker exec $CONTAINER nc -zv 167.254.0.177 25`
2. Verificar que el firewall permite conexiones al puerto 25
3. Verificar credenciales SMTP (usuario y contraseña)
4. Verificar que el servidor SMTP acepta conexiones desde el contenedor

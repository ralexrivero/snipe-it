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
MAIL_VARS=$(docker exec $CONTAINER env | grep -E "MAIL_HOST|MAIL_USERNAME|MAIL_FROM_ADDR|MAIL_PASSWORD" | wc -l)
if [ "$MAIL_VARS" -gt 0 ]; then
    echo "✓ Variables configuradas ($MAIL_VARS encontradas)"
    docker exec $CONTAINER env | grep -E "MAIL_HOST|MAIL_USERNAME|MAIL_FROM_ADDR" | sed 's/\(MAIL_PASSWORD=\).*/\1***/'
else
    echo "⚠ Variables no visibles en proceso principal (puede ser normal si Laravel las lee directamente)"
fi

echo ""
echo "4. Verificando configuración en Laravel..."
docker exec $CONTAINER php artisan tinker --execute="echo config('mail.mailers.smtp.host');" 2>/dev/null | grep -q "167.254.0.177" && echo "✓ Configuración correcta" || echo "✗ Configuración incorrecta"

echo ""
echo "5. Verificando conectividad SMTP..."
if docker exec $CONTAINER which nc >/dev/null 2>&1; then
    docker exec $CONTAINER nc -zv 167.254.0.177 25 2>&1 | grep -q "succeeded" && echo "✓ SMTP accesible" || echo "⚠ No se pudo verificar conectividad (nc disponible pero conexión falló o puerto bloqueado)"
else
    echo "⚠ nc no disponible en contenedor, probando con telnet..."
    if docker exec $CONTAINER which telnet >/dev/null 2>&1; then
        timeout 3 docker exec $CONTAINER sh -c "echo 'QUIT' | telnet 167.254.0.177 25" 2>&1 | grep -q "Connected" && echo "✓ SMTP accesible" || echo "⚠ No se pudo verificar conectividad"
    else
        echo "⚠ Herramientas de red no disponibles, verificar manualmente desde la interfaz web"
    fi
fi

echo ""
echo "6. Resumen de configuración en Laravel:"
docker exec $CONTAINER php artisan tinker --execute="echo '  Host: ' . config('mail.mailers.smtp.host') . PHP_EOL; echo '  Port: ' . config('mail.mailers.smtp.port') . PHP_EOL; echo '  From: ' . config('mail.from.address') . PHP_EOL; echo '  Username: ' . config('mail.mailers.smtp.username') . PHP_EOL;" 2>/dev/null

echo ""
echo "=== Verificación completada ==="
echo ""
echo "Para probar el envío de email:"
echo "1. Accede a https://intranet.afapitau.uy/snipeit/setup"
echo "2. Ve a la sección 'Email'"
echo "3. Haz clic en 'Send Test'"

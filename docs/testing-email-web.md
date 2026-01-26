# Probar Email desde la Interfaz Web

Esta guía describe cómo probar la configuración de email directamente desde la interfaz web de Snipe-IT.

## Método Rápido: Ruta Directa

La forma más rápida de probar el email es acceder directamente a la ruta de prueba:

```
https://intranet.afapitau.uy/snipeit/setup/mailtest
```

Esta ruta ejecuta automáticamente una prueba de email y envía un mensaje a la dirección configurada en `mail.from.address` (snipeit@afapitau.com.uy).

**Resultado esperado:**
- Si funciona: Verás un mensaje JSON con `"status": "success"` y el mensaje "Mail sent"
- Si falla: Verás un mensaje JSON con el error específico

## Método Completo: Desde la Interfaz de Configuración

### 1. Acceder a la Página de Setup

1. Abre tu navegador web
2. Accede a: `https://intranet.afapitau.uy/snipeit/setup`
3. Navega por las secciones de configuración hasta encontrar la sección de **"Email"** o **"Mail"**

### 2. Verificar la Configuración Mostrada

La configuración debería mostrar:
- **SMTP Server:** 167.254.0.177
- **SMTP Port:** 25
- **SMTP Username:** unioncapital3\snipeit
- **From Address:** snipeit@afapitau.com.uy
- **From Name:** Snipe-IT

### 3. Enviar Email de Prueba

1. Busca el botón **"Send Test Email"** o **"Test Email"** en la sección de Email
2. Haz clic en el botón
3. El sistema enviará un email de prueba a la dirección configurada en `mail.from.address`

### 4. Verificar el Resultado

**Si el email se envía correctamente:**
- Verás un mensaje de éxito: "Mail sent" o similar
- Recibirás un email en `snipeit@afapitau.com.uy` (la dirección configurada como remitente)
- El email tendrá como remitente: snipeit@afapitau.com.uy

**Si hay un error:**
- Verás un mensaje de error con detalles
- Revisa los logs del contenedor para más información:
  ```bash
  docker service logs snipe-it_snipe-it-app --tail 50 | grep -i "mail\|smtp\|email"
  ```

## Verificar Resultado desde la Terminal

Después de ejecutar la prueba, puedes verificar los logs:

```bash
# Ver logs del servicio
docker service logs snipe-it_snipe-it-app --tail 100 | grep -i "mail\|smtp\|email"
 
# Ver logs de Laravel (dentro del contenedor)
docker exec $(docker ps -qf "name=snipe-it.*app" | head -1) tail -50 /var/www/html/storage/logs/laravel.log | grep -i "mail\|smtp"
```

Busca mensajes como:
- `"Attempting to send mail to snipeit@afapitau.com.uy"` - Email enviado correctamente
- `"Mail sent from snipeit@afapitau.com.uy with errors"` - Error en el envío

## Probar con curl (Alternativa)

También puedes probar desde la línea de comandos:

```bash
curl -k https://intranet.afapitau.uy/snipeit/setup/mailtest
```

**Respuesta exitosa:**
```json
{"status":"success","messages":null,"payload":"Mail sent"}
```

**Respuesta con error:**
```json
{"status":"error","messages":"Error message here","payload":null}
```

## Problemas Comunes

### Error: "Could not connect to SMTP server"

**Causa:** El servidor SMTP no es accesible desde el contenedor.

**Solución:**
1. Verificar conectividad de red:
   ```bash
   docker exec $(docker ps -qf "name=snipe-it.*app" | head -1) ping -c 3 167.254.0.177
   ```
2. Verificar que el firewall permite conexiones al puerto 25
3. Verificar que el servidor SMTP está corriendo

### Error: "Authentication failed"

**Causa:** Credenciales incorrectas.

**Solución:**
1. Verificar que el secreto tiene las credenciales correctas:
   ```bash
   docker exec $(docker ps -qf "name=snipe-it.*app" | head -1) cat /run/secrets/snipeit_email_credentials
   ```
2. Verificar el formato del username (debe tener `\\` en JSON)
3. Actualizar el secreto si es necesario

### Error: "Connection timeout"

**Causa:** El servidor SMTP no responde o el puerto está bloqueado.

**Solución:**
1. Verificar que el servidor SMTP está accesible
2. Verificar reglas de firewall
3. Probar desde otro contenedor o máquina

### No se recibe el email

**Posibles causas:**
1. El email se envió pero está en spam
2. El servidor SMTP no está configurado para enviar emails externos
3. El email se envió pero hay un delay en la entrega

**Verificación:**
- Revisar los logs del servidor SMTP
- Verificar la bandeja de spam
- Verificar que el servidor SMTP permite envío desde el contenedor

## Notas

- El email de prueba se envía automáticamente a `snipeit@afapitau.com.uy` (la dirección configurada como remitente)
- El servidor SMTP está en `SERVER111.unioncapital3.net:587` con encriptación TLS
- Si el puerto 587 falla, se puede cambiar a puerto 25 sin encriptación editando el secreto JSON
- Los cambios en la configuración requieren actualizar el secreto y reiniciar el servicio

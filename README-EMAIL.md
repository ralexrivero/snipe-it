# Configuración de Email para Snipe-IT

## ✅ Implementación Completada

El sistema de email está configurado para usar secretos de Docker Swarm.

## 📋 Credenciales Configuradas

Las credenciales están almacenadas en el secreto `snipeit_email_credentials`:

- **SMTP Host:** 167.254.0.177
- **SMTP Username:** unioncapital3\snipeit
- **SMTP Password:** (almacenado en secreto)
- **Email From:** snipeit@afapitau.com.uy
- **SMTP Port:** 25 (sin encriptación)

## 🔧 Cómo Funciona

1. El secreto `snipeit_email_credentials` contiene un archivo JSON con las credenciales
2. El `entrypoint-wrapper.sh` lee el secreto al iniciar el contenedor
3. Extrae los valores del JSON usando Python3 (disponible en el contenedor)
4. Exporta las variables de entorno: `MAIL_HOST`, `MAIL_USERNAME`, `MAIL_PASSWORD`, `MAIL_FROM_ADDR`

## 🧪 Probar la Configuración de Email

1. Accede a https://intranet.afapitau.uy/snipeit/setup
2. En la sección "Email", haz clic en "Send Test"
3. Verifica que el email se envíe correctamente

## 🔄 Actualizar Credenciales

Si necesitas cambiar las credenciales:

1. Edita `snipeit_email_credentials.json`
2. Elimina el secreto antiguo: `docker secret rm snipeit_email_credentials`
3. Crea el nuevo secreto: `docker secret create snipeit_email_credentials snipeit_email_credentials.json`
4. Actualiza el servicio: `docker service update --force snipe-it_snipe-it-app`

## 📝 Archivos Relacionados

- `snipeit_email_credentials.json`: Credenciales en formato JSON
- `entrypoint-wrapper.sh`: Script que lee y configura las credenciales
- `docker-compose.yml`: Configuración del stack con el secreto montado
- `CREAR_SECRETOS.md`: Instrucciones para crear secretos

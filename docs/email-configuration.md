# Configuración de Email

Este documento describe la configuración de email para Snipe-IT usando secrets de Docker Swarm.

## Resumen

El sistema de email está configurado para usar secrets de Docker Swarm para la gestión de credenciales. Las credenciales se almacenan en el secreto `snipeit_email_credentials`.

## Configuración Actual

Las credenciales están almacenadas en el secreto `snipeit_email_credentials`:

- SMTP Host: SERVER111.unioncapital3.net
- SMTP Port: 587
- SMTP Encryption: TLS
- SMTP Username: unioncapital3\snipeit
- SMTP Password: (almacenado en secreto)
- Email From: snipeit@afapitau.com.uy

## Cómo Funciona

1. El secreto `snipeit_email_credentials` contiene un archivo JSON con las credenciales
2. El `entrypoint-wrapper.sh` lee el secreto cuando el contenedor inicia
3. Extrae los valores del JSON usando Python3 (disponible en el contenedor)
4. Exporta las variables de entorno: `MAIL_HOST`, `MAIL_PORT`, `MAIL_ENCRYPTION`, `MAIL_USERNAME`, `MAIL_PASSWORD`, `MAIL_FROM_ADDR`

## Probar la Configuración de Email

1. Acceder a https://intranet.afapitau.uy/snipeit/setup
2. En la sección "Email", hacer clic en "Send Test"
3. Verificar que el email se envíe correctamente

## Actualizar Credenciales

Para cambiar las credenciales:

1. Editar `snipeit_email_credentials.json`
2. Eliminar el secreto antiguo: `docker secret rm snipeit_email_credentials`
3. Crear el nuevo secreto: `docker secret create snipeit_email_credentials snipeit_email_credentials.json`
4. Actualizar el servicio: `docker service update --force snipe-it_snipe-it-app`

## Archivos Relacionados

- `snipeit_email_credentials.json`: Credenciales en formato JSON
- `entrypoint-wrapper.sh`: Script que lee y configura las credenciales
- `docker-compose.yml`: Configuración del stack con el secreto montado
- `docs/secrets.md`: Instrucciones para crear secrets

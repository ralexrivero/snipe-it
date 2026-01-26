# Secrets de Docker Swarm

Este documento describe cómo crear y gestionar secrets de Docker Swarm para el despliegue de Snipe-IT.

## Secreto de Credenciales de Email

### Prerrequisitos

El archivo `snipeit_email_credentials.json` con credenciales reales no debe estar en el repositorio. Usar `snipeit_email_credentials.json.example` como plantilla.

### Crear el Archivo de Credenciales

Si el archivo `snipeit_email_credentials.json` no existe, crearlo desde el ejemplo:

```bash
cd /home/ralex/apps/snipe-it
cp snipeit_email_credentials.json.example snipeit_email_credentials.json
# Editar el archivo con tus credenciales reales
nano snipeit_email_credentials.json
```

### Crear el Secreto

Crear el secreto de Docker Swarm desde el archivo JSON:

```bash
cd /home/ralex/apps/snipe-it
docker secret create snipeit_email_credentials snipeit_email_credentials.json
```

El secreto se crea desde un archivo JSON. Docker Swarm almacena el contenido del archivo como secreto.

**Nota de Seguridad:** Una vez creado el secreto en Swarm, el archivo local `snipeit_email_credentials.json` ya no es necesario para el funcionamiento (el secreto está en Swarm), pero es útil mantenerlo localmente para futuras actualizaciones. El archivo está protegido por `.gitignore` y no se incluirá en el repositorio.

### Verificar el Secreto

Verificar que el secreto fue creado:

```bash
docker secret ls | grep snipeit_email_credentials
```

Salida esperada:
```
snipeit_email_credentials   2 minutes ago
```

### Inspeccionar Metadatos del Secreto

Ver información del secreto (no el contenido):

```bash
docker secret inspect snipeit_email_credentials --pretty
```

**Importante:** No puedes ver el contenido del secreto por razones de seguridad. Solo se pueden ver metadatos.

## Formato del Archivo JSON

El archivo `snipeit_email_credentials.json` debe seguir esta estructura:

```json
{
  "smtp_host": "smtp.tu-servidor.com",
  "smtp_port": 587,
  "smtp_encryption": "tls",
  "smtp_username": "usuario\\dominio",
  "smtp_password": "tu_contraseña_segura",
  "email": "snipeit@tu-dominio.com"
}
```

### Campos del JSON

- `smtp_host`: Dirección del servidor SMTP (requerido)
- `smtp_port`: Puerto SMTP (opcional, por defecto 587)
- `smtp_encryption`: Tipo de encriptación: `"tls"`, `"ssl"` o `""` (opcional, por defecto `"tls"`)
- `smtp_username`: Usuario SMTP (requerido)
- `smtp_password`: Contraseña SMTP (requerido)
- `email`: Dirección de email remitente (requerido)

### Formato del Username

El backslash en el username debe ser escapado como `\\` en JSON:

- Ejemplo: Si el username real es `unioncapital3\snipeit` (un solo backslash), en JSON debe escribirse como `"unioncapital3\\snipeit"` (doble backslash)
- Al parsear el JSON, se convertirá correctamente a `unioncapital3\snipeit` (un solo backslash)
- El formato es correcto: `"unioncapital3\\snipeit"` en JSON → `unioncapital3\snipeit` al parsear

### Configuración de Puerto y Encriptación

- **Puerto 587 con TLS** (recomendado para autenticación): `"smtp_port": 587, "smtp_encryption": "tls"`
- **Puerto 25 sin encriptación** (SMTP interno): `"smtp_port": 25, "smtp_encryption": ""`
- **Puerto 465 con SSL** (legacy): `"smtp_port": 465, "smtp_encryption": "ssl"`

Si no se especifican `smtp_port` o `smtp_encryption`, se usarán los valores por defecto: puerto 587 y encriptación TLS.

### Requisitos

- El archivo debe estar en formato JSON válido
- Nunca hacer commit de `snipeit_email_credentials.json` al repositorio (ya está en `.gitignore`)

## Actualizar un Secreto Existente

Para actualizar el secreto:

```bash
# 1. Eliminar el secreto existente (solo si no está en uso)
docker secret rm snipeit_email_credentials

# 2. Crear el nuevo secreto
docker secret create snipeit_email_credentials snipeit_email_credentials.json

# 3. Actualizar el servicio para que use el nuevo secreto
docker service update --secret-rm snipeit_email_credentials --secret-add snipeit_email_credentials snipe-it_snipe-it-app
```

## Verificar Uso del Secreto en el Servicio

Verificar que el servicio usa el secreto:

```bash
docker service inspect snipe-it_snipe-it-app --format '{{json .Spec.TaskTemplate.ContainerSpec.Secrets}}' | python3 -m json.tool
```

## Eliminar un Secreto

Eliminar un secreto:

```bash
docker secret rm snipeit_email_credentials
```

**Nota:** Solo puedes eliminar secrets que no estén siendo usados por ningún servicio.

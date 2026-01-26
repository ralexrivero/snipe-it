# Crear Secretos de Docker Swarm para Snipe-IT

## 📋 Crear Secreto de Credenciales de Email

### Paso 1: Crear el archivo de credenciales (si no existe)

Si no tienes el archivo `snipeit_email_credentials.json`, créalo desde el ejemplo:

```bash
cd /home/ralex/apps/snipe-it
cp snipeit_email_credentials.json.example snipeit_email_credentials.json
# Edita el archivo con tus credenciales reales
nano snipeit_email_credentials.json
```

### Paso 2: Crear el secreto desde el archivo JSON

```bash
cd /home/ralex/apps/snipe-it
docker secret create snipeit_email_credentials snipeit_email_credentials.json
```

**Nota:** El secreto se crea desde un archivo JSON. Docker Swarm guardará el contenido del archivo como secreto. 

**Seguridad:** Una vez creado el secreto en Swarm, el archivo local `snipeit_email_credentials.json` ya no es necesario para el funcionamiento (el secreto está en Swarm), pero es útil mantenerlo localmente para futuras actualizaciones. El archivo está protegido por `.gitignore` y no se incluirá en el repositorio.

### Paso 3: Verificar que el secreto se creó

```bash
docker secret ls | grep snipeit_email_credentials
```

Deberías ver algo como:
```
snipeit_email_credentials   2 minutes ago
```

### Paso 4: Ver información del secreto (no el contenido)

```bash
docker secret inspect snipeit_email_credentials --pretty
```

**Importante:** No puedes ver el contenido del secreto por seguridad. Solo puedes ver metadatos.

---

## 📝 Formato del Archivo JSON

**IMPORTANTE:** El archivo `snipeit_email_credentials.json` con credenciales reales NO debe estar en el repositorio. Usa `snipeit_email_credentials.json.example` como plantilla.

### Crear el archivo de credenciales

1. Copia el archivo de ejemplo:
```bash
cp snipeit_email_credentials.json.example snipeit_email_credentials.json
```

2. Edita `snipeit_email_credentials.json` con tus credenciales reales:

```json
{
  "smtp_host": "smtp.tu-servidor.com",
  "smtp_username": "usuario\\dominio",
  "smtp_password": "tu_password_seguro",
  "email": "snipeit@tu-dominio.com"
}
```

**Nota importante:** 
- El backslash en el username debe ser escapado como `\\` en JSON
  - Ejemplo: Si el username real es `unioncapital3\snipeit` (un solo backslash), en JSON debe escribirse como `"unioncapital3\\snipeit"` (doble backslash)
  - Al parsear el JSON, se convertirá correctamente a `unioncapital3\snipeit` (un solo backslash)
  - ✅ **Tu formato actual es correcto**: `"unioncapital3\\snipeit"` en JSON → `unioncapital3\snipeit` al parsear
- El archivo debe estar en formato JSON válido
- **NUNCA** hagas commit de `snipeit_email_credentials.json` al repositorio (ya está en `.gitignore`)

---

## 🔄 Actualizar un Secreto Existente

Si necesitas actualizar el secreto:

```bash
# 1. Eliminar el secreto existente (solo si no está en uso)
docker secret rm snipeit_email_credentials

# 2. Crear el nuevo secreto
docker secret create snipeit_email_credentials snipeit_email_credentials.json

# 3. Actualizar el servicio para que use el nuevo secreto
docker service update --secret-rm snipeit_email_credentials --secret-add snipeit_email_credentials snipe-it_snipe-it-app
```

---

## ✅ Verificar que el Servicio Usa el Secreto

```bash
docker service inspect snipe-it_snipe-it-app --format '{{json .Spec.TaskTemplate.ContainerSpec.Secrets}}' | python3 -m json.tool
```

---

## 🗑️ Eliminar un Secreto

```bash
docker secret rm snipeit_email_credentials
```

**Nota:** Solo puedes eliminar secretos que no estén siendo usados por ningún servicio.

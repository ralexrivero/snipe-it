# Docker Swarm Secrets

This document describes how to create and manage Docker Swarm secrets for Snipe-IT deployment.

## Email Credentials Secret

### Prerequisites

The `snipeit_email_credentials.json` file with real credentials must not be in the repository. Use `snipeit_email_credentials.json.example` as a template.

### Creating the Credentials File

If the `snipeit_email_credentials.json` file does not exist, create it from the example:

```bash
cd /home/ralex/apps/snipe-it
cp snipeit_email_credentials.json.example snipeit_email_credentials.json
# Edit the file with your real credentials
nano snipeit_email_credentials.json
```

### Creating the Secret

Create the Docker Swarm secret from the JSON file:

```bash
cd /home/ralex/apps/snipe-it
docker secret create snipeit_email_credentials snipeit_email_credentials.json
```

The secret is created from a JSON file. Docker Swarm stores the file content as a secret.

**Security Note:** Once the secret is created in Swarm, the local `snipeit_email_credentials.json` file is no longer required for operation (the secret is in Swarm), but it's useful to keep it locally for future updates. The file is protected by `.gitignore` and will not be included in the repository.

### Verifying the Secret

Verify that the secret was created:

```bash
docker secret ls | grep snipeit_email_credentials
```

Expected output:
```
snipeit_email_credentials   2 minutes ago
```

### Inspecting Secret Metadata

View secret information (not the content):

```bash
docker secret inspect snipeit_email_credentials --pretty
```

**Important:** You cannot view the secret content for security reasons. Only metadata is visible.

## JSON File Format

The `snipeit_email_credentials.json` file must follow this structure:

```json
{
  "smtp_host": "smtp.your-server.com",
  "smtp_username": "user\\domain",
  "smtp_password": "your_secure_password",
  "email": "snipeit@your-domain.com"
}
```

### Username Format

The backslash in the username must be escaped as `\\` in JSON:

- Example: If the actual username is `unioncapital3\snipeit` (single backslash), in JSON it must be written as `"unioncapital3\\snipeit"` (double backslash)
- When parsing the JSON, it will be correctly converted to `unioncapital3\snipeit` (single backslash)
- Format is correct: `"unioncapital3\\snipeit"` in JSON → `unioncapital3\snipeit` when parsed

### Requirements

- The file must be valid JSON format
- Never commit `snipeit_email_credentials.json` to the repository (already in `.gitignore`)

## Updating an Existing Secret

To update the secret:

```bash
# 1. Remove the existing secret (only if not in use)
docker secret rm snipeit_email_credentials

# 2. Create the new secret
docker secret create snipeit_email_credentials snipeit_email_credentials.json

# 3. Update the service to use the new secret
docker service update --secret-rm snipeit_email_credentials --secret-add snipeit_email_credentials snipe-it_snipe-it-app
```

## Verifying Service Secret Usage

Verify that the service uses the secret:

```bash
docker service inspect snipe-it_snipe-it-app --format '{{json .Spec.TaskTemplate.ContainerSpec.Secrets}}' | python3 -m json.tool
```

## Removing a Secret

Remove a secret:

```bash
docker secret rm snipeit_email_credentials
```

**Note:** You can only remove secrets that are not being used by any service.

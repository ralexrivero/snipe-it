# Email Configuration

This document describes the email configuration for Snipe-IT using Docker Swarm secrets.

## Overview

The email system is configured to use Docker Swarm secrets for credential management. Credentials are stored in the `snipeit_email_credentials` secret.

## Current Configuration

Credentials are stored in the `snipeit_email_credentials` secret:

- SMTP Host: 167.254.0.177
- SMTP Username: unioncapital3\snipeit
- SMTP Password: (stored in secret)
- Email From: snipeit@afapitau.com.uy
- SMTP Port: 25 (no encryption)

## How It Works

1. The `snipeit_email_credentials` secret contains a JSON file with credentials
2. The `entrypoint-wrapper.sh` reads the secret when the container starts
3. Extracts values from JSON using Python3 (available in the container)
4. Exports environment variables: `MAIL_HOST`, `MAIL_USERNAME`, `MAIL_PASSWORD`, `MAIL_FROM_ADDR`

## Testing Email Configuration

1. Access https://intranet.afapitau.uy/snipeit/setup
2. In the "Email" section, click "Send Test"
3. Verify that the email is sent correctly

## Updating Credentials

To change credentials:

1. Edit `snipeit_email_credentials.json`
2. Remove the old secret: `docker secret rm snipeit_email_credentials`
3. Create the new secret: `docker secret create snipeit_email_credentials snipeit_email_credentials.json`
4. Update the service: `docker service update --force snipe-it_snipe-it-app`

## Related Files

- `snipeit_email_credentials.json`: Credentials in JSON format
- `entrypoint-wrapper.sh`: Script that reads and configures credentials
- `docker-compose.yml`: Stack configuration with mounted secret
- `docs/secrets.md`: Instructions for creating secrets

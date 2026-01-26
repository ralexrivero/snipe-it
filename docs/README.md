# Documentación de Despliegue de Snipe-IT

Este directorio contiene la documentación de despliegue y configuración para Snipe-IT en Docker Swarm.

## Índice de Documentación

- [Guía de Despliegue](deployment.md) - Guía completa paso a paso para desplegar Snipe-IT en Docker Swarm
- [Gestión de Secrets](secrets.md) - Instrucciones para crear y gestionar secrets de Docker Swarm
- [Configuración de Email](email-configuration.md) - Configuración de email usando secrets de Docker Swarm
- [Pruebas de Email](testing-email.md) - Guía para verificar que la configuración de email funciona correctamente

## Inicio Rápido

1. Revisar la [Guía de Despliegue](deployment.md) para requisitos previos y configuración
2. Crear los secrets requeridos siguiendo [Gestión de Secrets](secrets.md)
3. Desplegar el stack usando `docker stack deploy`
4. Configurar email si es necesario usando [Configuración de Email](email-configuration.md)

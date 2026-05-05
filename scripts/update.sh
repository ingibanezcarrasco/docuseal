#!/bin/bash
# ------------------------------------------------------------------------------
# Script de actualización rápida de DocuSeal
# Uso: ./update.sh
# ------------------------------------------------------------------------------
set -e

echo "⬇️  Descargando última imagen de docuseal/docuseal..."
docker compose pull

echo "🔄  Reiniciando contenedores con la nueva versión..."
docker compose up -d --force-recreate

echo "🧹  Limpiando imágenes antiguas..."
docker image prune -f

echo "✅  Actualización completada. Estado de los servicios:"
docker compose ps

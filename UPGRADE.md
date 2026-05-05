# Guía de actualización de DocuSeal

## Método recomendado

Ejecuta el script incluido:

```bash
./scripts/update.sh
```

Esto descarga la última imagen, recrea los contenedores y limpia imágenes viejas.

## Método manual

1. Descarga la imagen más reciente:
   ```bash
   docker compose pull
   ```

2. Reinicia los contenedores con la nueva versión:
   ```bash
   docker compose up -d --force-recreate
   ```

3. (Opcional) Elimina imágenes antiguas para liberar espacio:
   ```bash
   docker image prune -f
   ```

## Verificación post-actualización

```bash
docker compose ps
docker compose logs --tail=50 docuseal
```

Asegúrate de que el estado sea `healthy` y no aparezcan errores de migración.

## Notas importantes

- **Datos persistentes:** SQLite y archivos subidos viven en `./data/`, montado como volumen; no se pierden al recrear el contenedor.
- **Base de datos externa:** si usas PostgreSQL/MySQL, asegúrate de que la base esté disponible antes de levantar DocuSeal.
- **Migraciones:** DocuSeal ejecuta migraciones automáticamente al iniciar. Si hay un error, revisa los logs antes de reportar.
- **Version pinning:** si prefieres controlar la versión exacta, cambia `image: docuseal/docuseal:latest` por una etiqueta específica (p. ej. `docuseal/docuseal:2.5.0`) en `docker-compose.yml`.

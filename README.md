# DocuSeal Deployment

Repositorio de despliegue de [DocuSeal](https://www.docuseal.co/) para gestión de firmas digitales.

## Estructura del proyecto

```
docuseal-deployment/
├── Caddyfile              # Configuración de proxy inverso (producción HTTPS)
├── docker-compose.yml     # Orquestación de servicios (DocuSeal + PostgreSQL)
├── .env.example           # Plantilla de variables de entorno
├── .gitignore             # Exclusiones de Git
├── scripts/
│   └── update.sh          # Script de actualización rápida
└── data/                  # Volumen persistente (no se versiona)
```

## Requisitos previos

- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/)
- **Nota importante:** La imagen Docker oficial de DocuSeal requiere PostgreSQL. El stack incluye PostgreSQL automáticamente.
- (Opcional) Dominio apuntando a tu servidor para HTTPS

## Instalación rápida

### 1. Configurar variables de entorno

```bash
cp .env.example .env
```

Edita `.env` con tus valores reales (SMTP, dominio, etc.).

### 2. Levantar el servicio

**Modo desarrollo / local:**
```bash
docker compose up -d
```

Accede a http://localhost:3000.

**Modo producción (con HTTPS y dominio propio):**

1. Asegúrate de que tu dominio apunte a la IP del servidor.
2. Descomenta el bloque `caddy` en `docker-compose.yml`.
3. Activa el volumen `caddy_data` al final del archivo.
4. Ejecuta:
```bash
sudo HOST=tu-dominio.com docker compose up -d
```

**Modo exposición rápida con Tailscale Funnel (sin dominio ni router):**

Ideal para compartir links de firma con clientes sin abrir puertos ni configurar DNS.

1. Asegúrate de tener [Tailscale](https://tailscale.com/) instalado y logueado.
2. En `.env`, cambia `HOST_URL` a tu URL pública de Tailscale:
   ```bash
   HOST_URL=https://tu-nombre.tailnet-name.ts.net
   ```
3. Reinicia DocuSeal para que tome la nueva URL:
   ```bash
   docker compose up -d
   ```
4. En otra terminal, activa Funnel:
   ```bash
   sudo tailscale funnel 3000
   ```

Los enlaces de firma que generes ahora serán accesibles públicamente con HTTPS automático.

### 3. Primer acceso

- Abre la URL en tu navegador.
- Crea la primera cuenta de administrador.
- Configura el SMTP desde el panel (Settings → Email) para que los firmantes reciban notificaciones.

## Uso: enviar documentos a firmar

### Desde la interfaz web

1. Ve a **Templates** → **Create**.
2. Sube tu PDF.
3. Arrastra los campos necesarios sobre el documento (firma, fecha, texto, etc.).
4. Guarda la plantilla.
5. Haz clic en **Send** e ingresa los emails de los firmantes.
6. DocuSeal enviará automáticamente un email con un enlace único a cada firmante.

### Desde la API

DocuSeal expone una API REST completa. Documentación disponible en:
https://www.docuseal.com/docs/api

Ejemplo rápido con curl:
```bash
curl -X POST https://tu-dominio.com/api/templates \
  -H "Authorization: Bearer TU_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"template":{"name":"Contrato","folder_name":"Legal"}}'
```

## Actualización

Para actualizar a la última versión de DocuSeal:

```bash
./scripts/update.sh
```

O manualmente:
```bash
docker compose pull
docker compose up -d --force-recreate
```

Más detalles en [UPGRADE.md](UPGRADE.md).

## Variables de entorno importantes

| Variable | Descripción | Requerida |
|----------|-------------|-----------|
| `HOST_URL` | URL pública de la aplicación | Sí |
| `SMTP_ADDRESS` | Servidor SMTP para notificaciones | Recomendada |
| `SMTP_USERNAME` | Usuario SMTP | Recomendada |
| `SMTP_PASSWORD` | Contraseña o app-password SMTP | Recomendada |
| `SECRET_KEY_BASE` | Clave secreta para firmar cookies | En producción |
| `DATABASE_URL` | PostgreSQL (ya configurado en docker-compose.yml) | Sí (incluido por defecto) |
| `AWS_*` / `GOOGLE_*` / `AZURE_*` | Credenciales de almacenamiento en la nube | No |

## Backups

Por defecto todos los datos se guardan en `./data/`. Para respaldar:

```bash
tar -czvf backup_$(date +%F).tar.gz ./data/
```

El backup incluye tanto la base de datos PostgreSQL como los archivos subidos.

## Licencia

DocuSeal se distribuye bajo [AGPLv3](https://github.com/docusealco/docuseal/blob/master/LICENSE).
Este repositorio de despliegue es una configuración de ejemplo.

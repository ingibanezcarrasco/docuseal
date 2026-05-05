# Backup y Restauración de DocuSeal

Guía para respaldar y migrar tu instancia de DocuSeal entre equipos (Linux, macOS, Windows).

---

## ¿Qué respaldar

Tu instancia de DocuSeal almacena datos en **tres lugares**:

| Ubicación | Contenido | Carpeta local |
|-----------|-----------|---------------|
| PostgreSQL | Usuarios, plantillas, envíos, registros de firma, metadatos | `./data/postgres` |
| DocuSeal files | PDFs subidos, documentos firmados, archivos adjuntos | `./data/docuseal` |
| `.env` | Claves secretas, credenciales SMTP, configuración de host | Archivo en raíz del repo |

> **Advertencia:** Sin `SECRET_KEY_BASE` original, no podrás descifrar datos sensibles (2FA, SMTP passwords) aunque restaures la base de datos.

---

## Backup completo

### Linux / macOS

```bash
cd docuseal-deployment

# 1. Crear carpeta de backup con fecha
BACKUP_DIR="backup_$(date +%F)"
mkdir -p "$BACKUP_DIR"

# 2. Respaldar .env
cp .env "$BACKUP_DIR/"

# 3. Detener los contenedores (para consistencia)
docker compose down

# 4. Copiar archivos de DocuSeal (PDFs, documentos firmados)
cp -r data/docuseal "$BACKUP_DIR/"

# 5. Respaldar PostgreSQL como dump SQL
docker compose up -d postgres
docker compose exec postgres pg_dump -U docuseal docuseal > "$BACKUP_DIR/docuseal.sql"
docker compose down

# 6. Empaquetar todo
tar -czvf "${BACKUP_DIR}.tar.gz" "$BACKUP_DIR"
echo "Backup creado: ${BACKUP_DIR}.tar.gz"
```

### Windows (PowerShell)

```powershell
# 1. Navegar al directorio
cd docuseal-deployment

# 2. Crear carpeta de backup
$backupDir = "backup_$(Get-Date -Format 'yyyy-MM-dd')"
New-Item -ItemType Directory -Name $backupDir

# 3. Respaldar .env
copy .env $backupDir\env.backup

# 4. Detener contenedores
docker compose down

# 5. Copiar archivos de DocuSeal
Copy-Item -Recurse data\docuseal $backupDir\

# 6. Respaldar PostgreSQL
docker compose up -d postgres
docker compose exec postgres pg_dump -U docuseal docuseal > "$backupDir\docuseal.sql"
docker compose down

# 7. Empaquetar con Compress-Archive
Compress-Archive -Path $backupDir -DestinationPath "$backupDir.zip"
Write-Host "Backup creado: $backupDir.zip"
```

---

## Restauración en nuevo equipo

### Linux / macOS

```bash
# 1. Extraer backup
tar -xzvf backup_2026-05-05.tar.gz
cd docuseal-deployment

# 2. Restaurar .env
cp backup_2026-05-05/.env .

# 3. Crear directorio de datos
docker compose down
rm -rf data/*
mkdir -p data/docuseal data/postgres

# 4. Copiar archivos de DocuSeal
cp -r backup_2026-05-05/docuseal/* data/docuseal/

# 5. Levantar solo PostgreSQL primero (para importar dump)
docker compose up -d postgres
sleep 10

# 6. Restaurar dump SQL
docker compose exec -T postgres psql -U docuseal docuseal < backup_2026-05-05/docuseal.sql

# 7. Levantar DocuSeal completo
docker compose up -d

# 8. Verificar
open http://localhost:3000  # macOS
# xdg-open http://localhost:3000  # Linux
```

### Windows (PowerShell)

```powershell
# 1. Extraer backup
Expand-Archive -Path backup_2026-05-05.zip -DestinationPath .

cd docuseal-deployment

# 2. Restaurar .env
copy backup_2026-05-05\env.backup .env

# 3. Limpiar datos viejos
docker compose down
Remove-Item -Recurse -Force data\*
New-Item -ItemType Directory -Path data\docuseal
New-Item -ItemType Directory -Path data\postgres

# 4. Copiar archivos de DocuSeal
Copy-Item -Recurse backup_2026-05-05\docuseal\* data\docuseal\

# 5. Levantar PostgreSQL
docker compose up -d postgres
Start-Sleep -Seconds 10

# 6. Restaurar dump SQL
Get-Content backup_2026-05-05\docuseal.sql | docker compose exec -T postgres psql -U docuseal docuseal

# 7. Levantar todo
docker compose up -d
```

---

## Migración entre plataformas (Linux ↔ macOS ↔ Windows)

El proceso es **el mismo en todas las plataformas** porque DocuSeal corre dentro de Docker:

1. **En el equipo origen:** ejecutá el script de backup de tu plataforma.
2. **Transferí** el archivo `.tar.gz` o `.zip` al equipo destino (USB, cloud, etc.).
3. **En el equipo destino:** cloná el repo de GitHub y ejecutá el script de restauración de tu plataforma.

> **Nota sobre Docker Desktop (Windows):** asegurate de tener Docker Desktop instalado con el backend WSL2 activado. Las rutas de volúmenes locales funcionan igual que en macOS/Linux.

---

## Backup automático (opcional)

### macOS / Linux — Cron diario

```bash
# Editar crontab
crontab -e

# Agregar línea para backup diario a las 2:00 AM
0 2 * * * cd /ruta/a/docuseal-deployment && bash scripts/backup.sh >> backup.log 2>&1
```

Creá `scripts/backup.sh`:

```bash
#!/bin/bash
set -e
cd "$(dirname "$0")/.."
BACKUP_DIR="backup_$(date +%F)"
mkdir -p "$BACKUP_DIR"
cp .env "$BACKUP_DIR/"
docker compose down
cp -r data/docuseal "$BACKUP_DIR/"
docker compose up -d postgres
sleep 5
docker compose exec postgres pg_dump -U docuseal docuseal > "$BACKUP_DIR/docuseal.sql"
docker compose down
tar -czvf "backups/${BACKUP_DIR}.tar.gz" "$BACKUP_DIR"
rm -rf "$BACKUP_DIR"
docker compose up -d
echo "[$(date)] Backup completado: backups/${BACKUP_DIR}.tar.gz"
```

---

## Verificación post-restauración

Después de restaurar, verificá estos puntos:

1. **Acceso al panel:** http://localhost:3000 debería cargar.
2. **Login:** podés iniciar sesión con el mismo usuario admin.
3. **Plantillas:** las plantillas guardadas deberían estar visibles.
4. **Documentos firmados:** los PDFs en Templates → Completed deberían descargarse.
5. **SMTP:** si configuraste email, verificá que las credenciales siguen funcionando.

Si algo falla, revisá los logs:

```bash
docker compose logs docuseal | tail -50
docker compose logs postgres | tail -20
```

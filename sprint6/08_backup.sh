#!/usr/bin/env bash
set -Eeuo pipefail
umask 077

# Configuração por variáveis de ambiente. Use ~/.pgpass para a senha.
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-ecommerce_db}"
DB_USER="${DB_USER:-postgres}"
BACKUP_DIR="${BACKUP_DIR:-/var/backups/ecommerce}"
RETENTION_DAYS="${RETENTION_DAYS:-30}"
TIMESTAMP="$(date '+%Y%m%d_%H%M%S')"
BACKUP_FILE="${BACKUP_DIR}/${DB_NAME}_${TIMESTAMP}.dump"
LOG_FILE="${BACKUP_DIR}/backup.log"

log() {
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" | tee -a "$LOG_FILE"
}

on_error() {
  local exit_code=$?
  printf '[%s] ERRO: backup interrompido (código %s).\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$exit_code" >&2
  if [[ -n "${BACKUP_FILE:-}" && -f "$BACKUP_FILE" ]]; then
    rm -f -- "$BACKUP_FILE"
  fi
  exit "$exit_code"
}
trap on_error ERR

command -v pg_dump >/dev/null 2>&1 || { echo "pg_dump não encontrado." >&2; exit 127; }
command -v pg_restore >/dev/null 2>&1 || { echo "pg_restore não encontrado." >&2; exit 127; }

mkdir -p -- "$BACKUP_DIR"
touch "$LOG_FILE"
chmod 600 "$LOG_FILE"

log "Início do backup de $DB_NAME."
pg_dump \
  --host="$DB_HOST" \
  --port="$DB_PORT" \
  --username="$DB_USER" \
  --dbname="$DB_NAME" \
  -Fc \
  --compress=9 \
  --no-owner \
  --no-privileges \
  --file="$BACKUP_FILE"

# Validação mínima: o catálogo do arquivo deve ser legível pelo pg_restore.
pg_restore --list "$BACKUP_FILE" >/dev/null
chmod 600 "$BACKUP_FILE"
log "Backup validado: $BACKUP_FILE"

# Retenção: remove apenas dumps deste banco com mais de 30 dias (configurável).
find "$BACKUP_DIR" -type f -name "${DB_NAME}_*.dump" -mtime +"$RETENTION_DAYS" -print -delete |
while IFS= read -r old_backup; do
  log "Backup antigo removido: $old_backup"
done

log "Backup concluído com sucesso."

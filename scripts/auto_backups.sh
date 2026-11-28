#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Uso: $0 <directorio_origen> <directorio_destino_backup> [archivo_reporte]" >&2
  exit 1
fi

ORIGEN="$1"
DESTINO="$2"
REPORTE="${3:-}"

if [[ ! -d "$ORIGEN" ]]; then
  echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') El directorio origen no existe: $ORIGEN" >&2
  exit 1
fi

if [[ ! -r "$ORIGEN" ]]; then
  echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') Sin permisos de lectura en origen: $ORIGEN" >&2
  exit 1
fi

mkdir -p "$DESTINO"

FECHA_TAG=$(date "+%Y%m%d_%H%M%S")
ARCHIVO_BACKUP="${DESTINO}/backup_${FECHA_TAG}.tar.gz"

if [[ -z "$REPORTE" ]]; then
  REPORTE="${DESTINO}/reporte_backup_${FECHA_TAG}.txt"
else
  mkdir -p "$(dirname "$REPORTE")"
fi

# Comprime el directorio origen evitando rutas absolutas problemáticas
tar -czf "$ARCHIVO_BACKUP" -C "$(dirname "$ORIGEN")" "$(basename "$ORIGEN")"

# Verifica la integridad del archivo comprimido
tar -tzf "$ARCHIVO_BACKUP" >/dev/null

TAMANO=$(du -sh "$ARCHIVO_BACKUP" | awk '{print $1}')

{
  echo "REPORTE DE RESPALDO - $(date '+%Y-%m-%d %H:%M:%S')"
  echo "Host     : $(hostname)"
  echo "Origen   : $ORIGEN"
  echo "Destino  : $ARCHIVO_BACKUP"
  echo "Tamaño   : $TAMANO"
  echo "Estado   : OK (integridad verificada con tar -tzf)"
} > "$REPORTE"

echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') Respaldo creado y verificado: $ARCHIVO_BACKUP"
echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') Reporte guardado en: $REPORTE"

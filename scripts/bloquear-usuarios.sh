#!/usr/bin/env bash

set -Eeuo pipefail

archivo="$1"
UBICACION_SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UBICACION_TRABAJO="$(dirname "$UBICACION_SCRIPT")"
FECHA="$(date +'%Y-%m-%d-%H:%M:%S')"

declare logs_interno="$UBICACION_TRABAJO/logs"
declare ruta_funciones="$UBICACION_TRABAJO"
declare logs_archivo="$logs_interno/gestion_usuarios.log"

# Ruta para agregar las funciones
source "$ruta_funciones/config/validador_json.sh"
source "$ruta_funciones/config/validador_logsinterno.sh"
source "$ruta_funciones/config/validador_usuario.sh"

# La ejecucion para validaciones
validar_logint "$logs_interno"
validar_archivo_json "$archivo" "$logs_interno" || exit 1
validar_json_esquema_bloquear  "$archivo" "$logs_interno" || exit 1
# EJecucion del bloqueado y lectura de usuarios
errores=0
while IFS= read -r username; do
    # Valida si existe o no pero sigue cada usuario del json
    if ! usuario_existe "$username"; then
        printf "%s - ERROR - El usuario (%s) no existe\n" "$FECHA" "$username" 2>&1 | tee -a "$logs_archivo"
        ((errores++)) || true
        continue
    fi

    # bloquear usuario
    if sudo usermod --lock "$username"; then
        printf "%s - INFO - El usuario (%s) BLOQUEADO\n" "$FECHA" "$username" 2>&1 | tee -a "$logs_archivo"
        continue
    else
        printf "%s - FATAL - Error a bloquear el usuario (%s)\n" "$FECHA" "$username" 2>&1 | tee -a "$logs_archivo"
        ((errores++)) || true
        continue
    fi
done < <(leer_json_bloquear "$archivo")
if [[ "$errores" -gt 0 ]]; then
    printf "Hubo: %s - de errores al bloquear usuarios en el JSON.\nFinalizacion dudodas consulte los logs (%s)\n" "$errores" "$logs_archivo"
    printf "%s - WARNING - Hubo algunos errores al bloquear usuarios\n" "$FECHA"  2>&1 | tee -a "$logs_archivo"
    exit 1
else
    printf "Se han bloqueado exitosamente todos los usuarios sin ERRORES\n"
    printf "%s - OK - Se han bloqueado exitosamente todos los usuarios del JSON (%s)\n" "$FECHA" "$archivo"  2>&1 | tee -a "$logs_archivo"
    exit 0
fi

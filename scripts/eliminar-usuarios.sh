#!/usr/bin/env bash

set -Eeuo pipefail

archivo="$1"
UBICACION_SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]})")" && pwd)"
UBICACION_TRABAJO="$(dirname "$UBICACION_SCRIPT")"
FECHA="$(date +'%Y-%m-%d-%H:%M:%S')"

declare logs_interno="$UBICACION_TRABAJO/logs"
declare ruta_funciones="$UBICACION_TRABAJO"
declare logs_archivo="$logs_interno/gestion_usuarios.log"

# Ruta para agregar las funciones
source "$ruta_funciones/config/validador_json.sh"
source "$ruta_funciones/config/validador_logsinterno.sh"

# Funcion solo para validar si existe el usuario previo
usuario_existe(){
    getent passwd "$1" >/dev/null 2>&1
}

leyendo_archivo(){
    local archivo="$1"
    jq -r '.users[] | [.username, (.delete_home // false)] | @tsv' "$archivo"
}


# La ejecucion para validaciones JSON
validar_logint "$logs_interno"
validar_archivo_json "$archivo" "$logs_interno" || exit 1
validar_json_esquema_eliminar "$archivo" "$logs_interno" || exit 1

while IFS=$'\t' read -r username delete_home; do


    if ! usuario_existe "$username"; then
        printf "%s - ERROR - El usuario (%s) no existe\n" "$FECHA" "$username" 2>&1 | tee -a "$logs_archivo"
        continue
    fi

    args=()
    # Solo agrega el argumento a userdel -r
    # Eliminar el home
    if [[ "$delete_home" == true ]]; then
        args+=(-r)
    fi

    # Bloquear el usuario para poder eliminar luego
    sudo usermod --lock "$username"
    # borrar los procesos del usuario
    # En si para evitar un borrado limpuo y evitar
    # Procesos huerfanos con UID sin nombre aprox
    printf "Atención eliminado procesos del usuario (%s)\n" "$username"
    # Seria como un cierre suave
    sudo pkill -TERM -u "$username" 2>/dev/null || true
    sleep 2
    # Este forzado pero en caso existe algun proceso
    sudo pkill -KILL -u "$username" 2>/dev/null || true

    # Proceso de eliminado
    # En si aplica esto
    # userdel (-r) usuario
    if sudo userdel "${args[@]}" "$username";then
        printf "Se elimino el usuario\n"
        printf "%s - INFO - Usuario (%s) eliminado exitosamente\n" "$FECHA" "$username" 2>&1 | tee -a "$logs_archivo"
        continue
    else
        printf "%s - ERROR - AL eliminar el Usuario (%s)\n" "$FECHA" "$username" 2>&1 | tee -a "$logs_archivo"
    fi
done < <(leyendo_archivo "$archivo")

#!/usr/bin/env bash

set -Eeuo pipefail

# Variables
archivo="$1"
# Variables para obtener el usuario y si usa privilegios
usuario_efectivo="$(id -un)"
USUARIO_SESION="${SUDO_USER:-$USER}"
# Variables mas que todo para obtener ubicaciones
NOMBRE_SCRIPT="$(basename "${BASH_SOURCE[0]}")"
UBICACION_SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]})")" && pwd)"
UBICACION_TRABAJO="$(dirname "$UBICACION_SCRIPT")"

declare logs_interno="$UBICACION_TRABAJO/logs"
declare ruta_funciones="$UBICACION_TRABAJO"
declare logs_archivo="$logs_interno/gestion_usuarios.log"

# Ruta para agregar las funciones
source "$ruta_funciones/config/funcion-log.sh"
source "$ruta_funciones/config/validador_json.sh"
source "$ruta_funciones/config/validador_logsinterno.sh"
source "$ruta_funciones/config/validador_usuario.sh"

# La ejecucion para validaciones JSON
validar_logint "$logs_interno" "$logs_archivo" "$NOMBRE_SCRIPT" "$USUARIO_SESION" "$usuario_efectivo"
validar_archivo_json "$archivo" "$logs_archivo" "$NOMBRE_SCRIPT" "$USUARIO_SESION" "$usuario_efectivo" || exit 1
validar_json_esquema_eliminar "$archivo" "$logs_archivo" "$NOMBRE_SCRIPT" "$USUARIO_SESION" "$usuario_efectivo" || exit 1

while IFS=$'\t' read -r username delete_home; do


    if ! usuario_existe "$username"; then
        log_mensaje "ERROR" "$logs_archivo" "$NOMBRE_SCRIPT" "$USUARIO_SESION" "$usuario_efectivo" "El usuario ($username) no existe"
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
    log_mensaje "INFO" "$logs_archivo" "$NOMBRE_SCRIPT" "$USUARIO_SESION" "$usuario_efectivo" "Deteniendo procesos del usuario($username)"
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
        log_mensaje "INFO" "$logs_archivo" "$NOMBRE_SCRIPT" "$USUARIO_SESION" "$usuario_efectivo" "El usuario($username) fue eliminado exitosamente"
        continue
    else
        log_mensaje "ERROR" "$logs_archivo" "$NOMBRE_SCRIPT" "$USUARIO_SESION" "$usuario_efectivo" "Error al eliminar el usuario($username) verifque usuarios JSON"
    fi
done < <(leer_json_eliminar "$archivo")

#!/usr/bin/env bash

set -Eeuo pipefail

# Variables
archivo="$1"
# Variables para obtener el usuario y si usa privilegios
usuario_efectivo="$(id -un)"
USUARIO_SESION="${SUDO_USER:-$USER}"
# Variables mas que todo para obtener ubicaciones
NOMBRE_SCRIPT="$(basename "${BASH_SOURCE[0]}")"
UBICACION_SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UBICACION_TRABAJO="$(dirname "$UBICACION_SCRIPT")"

declare logs_interno="$UBICACION_TRABAJO/logs"
declare ruta_funciones="$UBICACION_TRABAJO"
declare logs_archivo="$logs_interno/gestion_usuarios.log"

# Ruta para agregar las funciones
source "$ruta_funciones/config/funcion-log.sh"
source "$ruta_funciones/config/validador_json.sh"
source "$ruta_funciones/config/validador_logsinterno.sh"
source "$ruta_funciones/config/validador_usuario.sh"

# La ejecucion para validaciones
validar_logint "$logs_interno" "$logs_archivo" "$NOMBRE_SCRIPT" "$USUARIO_SESION" "$usuario_efectivo"
validar_archivo_json "$archivo" "$logs_archivo" "$NOMBRE_SCRIPT" "$USUARIO_SESION" "$usuario_efectivo" || exit 1
validar_json_esquema_eliminar "$archivo" "$logs_archivo" "$NOMBRE_SCRIPT" "$USUARIO_SESION" "$usuario_efectivo" || exit 1
# EJecucion del bloqueado y lectura de usuarios
errores=0
while IFS= read -r username; do
    # Valida si existe o no pero sigue cada usuario del json
    if ! usuario_existe "$username"; then
        log_mensaje "ERROR" "$logs_archivo" "$NOMBRE_SCRIPT" "$USUARIO_SESION" "$usuario_efectivo" "El usuario ($username) no existe"
        ((errores++)) || true
        continue
    fi

    # bloquear usuario
    if sudo usermod --lock "$username"; then
        log_mensaje "INFO" "$logs_archivo" "$NOMBRE_SCRIPT" "$USUARIO_SESION" "$usuario_efectivo" "El usuario ($username) fue bloqueado exitosamente"
        continue
    else
        log_mensaje "ERROR" "$logs_archivo" "$NOMBRE_SCRIPT" "$USUARIO_SESION" "$usuario_efectivo" " Error al bloquear el usuario ($username)"
        ((errores++)) || true
        continue
    fi
done < <(leer_json_bloquear "$archivo")
if [[ "$errores" -gt 0 ]]; then
    printf "Hubo: %s - de errores al bloquear usuarios en el JSON.\nFinalizacion dudodas consulte los logs (%s)\n" "$errores" "$logs_archivo"
    log_mensaje "WARNING" "$logs_archivo" "$NOMBRE_SCRIPT" "$USUARIO_SESION" "$usuario_efectivo" "Hubo algunos errores en bloquear usuarios del JSON ($archivo)"
else
    printf "Se han bloqueado exitosamente todos los usuarios sin ERRORES\n"
    log_mensaje "INFO" "$logs_archivo" "$NOMBRE_SCRIPT" "$USUARIO_SESION" "$usuario_efectivo" "Se han bloqueado exitosamente todos los usuarios del JSON ($archivo)"
    exit 0
fi

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

# Esta funcion crea la contrasena temporal
# Con un numero maximo de 16 bytes o char
generar_password_temporal(){
    local random contra

    while :; do
            random="$(LC_ALL=C tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 16 || true)"
            contra="${random:0:12}"
            if (( ${#contra} >= 12 )); then
                printf '%s\n' "$contra"
                return 0
            fi
        done
}

# La ejecucion para validaciones
# Si alguno da un return diferente da exit 1 o error digamoslo
validar_logint "$logs_interno" "$logs_archivo" "$NOMBRE_SCRIPT" "$USUARIO_SESION" "$usuario_efectivo"
validar_archivo_json "$archivo" "$logs_archivo" "$NOMBRE_SCRIPT" "$USUARIO_SESION" "$usuario_efectivo" || exit 1
validar_json_esquema_eliminar "$archivo" "$logs_archivo" "$NOMBRE_SCRIPT" "$USUARIO_SESION" "$usuario_efectivo" || exit 1

# La lectura
# Y ejecucion - creacion de usuario con sus parametros dados
while IFS=$'\t' read -r username groups create_home; do
    contrasena="$(generar_password_temporal)"
    if usuario_existe "$username";then
        log_mensaje "WARNING" "$logs_archivo" "$NOMBRE_SCRIPT" "$USUARIO_SESION" "$usuario_efectivo" "El usuario ($username) ya existe"
        continue
    fi

    args=(-s /bin/bash)

    # Si es true aplica el useradd -m con su home
    # Si es false aplica el -M osea sin su home
    if [[ "$create_home" == true ]]; then
        args+=(-m)
    else
        args+=(-M)
    fi

    # Añade los grupos a crear para el useradd
    if [[ -n "$groups" ]]; then
        args+=(-G "$groups")
    fi

    # printf "prueba para %s\n" "$username"
    # printf "${args[@]}"
    # En si aplica esto
    # useradd (-m ó -M) -G (grupos) usuario
    sudo useradd "${args[@]}" "$username"

    printf "Atencion - Contraseña Temporal Generada : Usuario (%s) - Contrasena: %s\n" "$username" "$contrasena"
    printf "%s:%s\n" "$username" "$contrasena" | sudo chpasswd
    log_mensaje "INFO" "$logs_archivo" "$NOMBRE_SCRIPT" "$USUARIO_SESION" "$usuario_efectivo" "El usuario ($username) fue creado exitosamente con sus parametros"
    # Para cambiarlo en el primer login
    sudo chage -d 0 "$username"
    unset "contrasena"
done < <(leer_json_crear "$archivo")
printf "OJO - No se olvide de cambiar la contrasena en el primer login\n"
printf "NOTA: La contrasena solo aparace en la shell generada (stdout) no olvide la contrasena generada en caso use un administrador para cambiarla\n"
exit 0

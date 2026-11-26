#!/usr/bin/bash

set -Eeuo pipefail

archivo="$1"
UBICACION_SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]})")" && pwd)"
UBICACION_TRABAJO="$(dirname "$UBICACION_SCRIPT")"
FECHA="$(date +'%Y-%m-%d-%H:%M:%S')"
declare logs_interno="$UBICACION_TRABAJO/logs"
declare logs_archivo="$logs_interno/gestion_usuarios.log"

validar_logint(){
    if [[ -d "$logs_interno" ]] && [[ -r "$logs_interno" ]] && [[ -w "$logs_interno" ]]; then
        printf "%s - INFO - Validando carpeta logs existente\n" "$FECHA" 2>&1 | tee -a "$logs_archivo"
        return 0
    else
        mkdir -p "$logs_interno"
        printf "%s - WARNING - Carpeta '/logs' no creada\n" "$FECHA" 2>&1 | tee -a "$logs_archivo"
        printf "%s - INFO - Se ha creado carpeta ubicacion: ('%s')\n" "$FECHA"  "$logs_interno" 2>&1 | tee -a "$logs_archivo"
        return 0
    fi
}
validar_logint

validar_archivo_json() {
    local archivo="$1"

    if [[ -z "$archivo" ]]; then
        printf "%s - FATAL - No se coloco ningun archivo\n" "$FECHA" 2>&1 | tee -a "$logs_archivo"
        return 1
    fi

    if ! [[  -f "$archivo" && -r "$archivo" ]]; then
        printf "%s - ERROR - No se puede leer el archivo (%s)\n" "$FECHA" "$archivo" 2>&1 | tee -a "$logs_archivo"
        return 1
    fi

    if ! jq empty "$archivo" >/dev/null 2>&1; then
        printf "%s - FATAL - JSON invalido\n" "$FECHA" 2>&1 | tee -a "$logs_archivo"
        return 1
    fi
    printf "%s - INFO - Archivo valido\n" "$FECHA" 2>&1 | tee -a "$logs_archivo"
}

# Esta funcion solo valida el esquema JSON
# que sea array
# Y que tenga valores
# ademas el regex para usuario
# Si da error mandara al stderr
validar_json_esquema() {
    local archivo="$1"

    if jq -e '(.users | type == "array") and (.users | length > 0) and all(.users[]; (.username | type == "string") and (.groups | type == "string") and (.username | test("^[a-z_][a-z0-9_-]{0,31}$")))' "$archivo" >/dev/null 2>&1; then
        printf "%s - INFO - Esquema del JSON validado\n" "$FECHA" 2>&1 | tee -a "$logs_archivo"
        return 0
    else
        printf "%s - FATAL - Esquema del JSON INVALIDO\n" "$FECHA" 2>&1 | tee -a "$logs_archivo"
        return 1
    fi
}

leyendo_archivo(){
    local archivo="$1"
    jq -r '.users[] | [.username, (.groups // ""), (.create_home // false)]| @tsv' "$archivo"
}

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

# Solo es una funcion
# Para ver si existe
usuario_existe() {
    getent passwd "$1" >/dev/null 2>&1
}


# La ejecucion para validaciones
# Si alguno da un return diferente da exit 1 o error digamoslo

validar_archivo_json "$archivo" || exit 1
validar_json_esquema "$archivo" || exit 1

# La lectura
# Y ejecucion - creacion de usuario con sus parametros dados
while IFS=$'\t' read -r username groups create_home; do
    contrasena="$(generar_password_temporal)"
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
    useradd "${args[@]}" "$username"
    # Para cambiarlo en el primer login
    chage -d 0 "$username"
    printf "Atencion - Contraseña Temporal Generada: %s:%s" "$username" "$contrasena"
    printf "%s:%s\n" "$username" "$contrasena" | sudo chpasswd
    printf "%s - OK - Usuario(%s) creado exitosamente\n" "$FECHA" "$username" 2>&1 | tee -a "$logs_archivo"
done < <(leyendo_archivo "$archivo")
printf "OJO - No se olvide de cambiar la contrasena en el primer login\n"
return 0

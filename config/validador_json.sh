#!/usr/bin/env bash

# Funciones de validar JSON
validar_archivo_json() {
    local archivo="$1"
    local logs_archivo="$2"
    local nombre_script="$3"
    local usuario_ejecutor="$4"
    local usuario_efectivo="$5"

    if [[ -z "$archivo" ]]; then
        log_mensaje "CRITICAL" "$logs_archivo" "$nombre_script" "$usuario_ejecutor" "$usuario_efectivo" "No se coloco ningun archivo"
        return 1
    fi

    if ! [[  -f "$archivo" && -r "$archivo" ]]; then
        log_mensaje "CRITICAL" "$logs_archivo" "$nombre_script" "$usuario_ejecutor" "$usuario_efectivo" "No se puede leer el archivo y no es un archivo"
        return 1
    fi

    if ! jq empty "$archivo" >/dev/null 2>&1; then
        log_mensaje "CRITICAL" "$logs_archivo" "$nombre_script" "$usuario_ejecutor" "$usuario_efectivo" "JSON invalido"
        return 1
    fi
    log_mensaje "INFO" "$logs_archivo" "$nombre_script" "$usuario_ejecutor" "$usuario_efectivo" "Archivo cumple permisos"
}

# Esta funcion solo valida el esquema JSON
# que sea array
# Y que tenga valores
# ademas el regex para usuario
# Si da error mandara al stderr
validar_json_esquema() {
    local archivo="$1"
    local logs_archivo="$2"
    local nombre_script="$3"
    local usuario_ejecutor="$4"
    local usuario_efectivo="$5"

    if jq -e '(.users | type == "array") and (.users | length > 0) and all(.users[]; (.username | type == "string") and (.groups | type == "string") and (.username | test("^[a-z_][a-z0-9_-]{0,31}$")))' "$archivo" >/dev/null 2>&1; then
        log_mensaje "INFO" "$logs_archivo" "$nombre_script" "$usuario_ejecutor" "$usuario_efectivo" "Esquema del JSON validado exitosamente"
        return 0
    else
        log_mensaje "CRITICAL" "$logs_archivo" "$nombre_script" "$usuario_ejecutor" "$usuario_efectivo" "Esquema del JSON INVALIDO"
        return 1
    fi
}

validar_json_esquema_bloquear(){
    local archivo="$1"
    local logs_archivo="$2"
    local nombre_script="$3"
    local usuario_ejecutor="$4"
    local usuario_efectivo="$5"

    if jq -e '(.users | type == "array") and (.users | length > 0) and all(.users[]; (.username | type == "string") and (.username | test("^[a-z_][a-z0-9_-]{0,31}$")))' "$archivo" >/dev/null 2>&1; then
        log_mensaje "INFO" "$logs_archivo" "$nombre_script" "$usuario_ejecutor" "$usuario_efectivo" "Esquema del JSON validado exitosamente"
        return 0
    else
        log_mensaje "CRITICAL" "$logs_archivo" "$nombre_script" "$usuario_ejecutor" "$usuario_efectivo" "Esquema del JSON INVALIDO"
        return 1
    fi
}

validar_json_esquema_eliminar(){
    local archivo="$1"
    local logs_archivo="$2"
    local nombre_script="$3"
    local usuario_ejecutor="$4"
    local usuario_efectivo="$5"

    if jq -e '(.users | type == "array") and (.users | length > 0) and all(.users[]; (.username | type == "string") and (.username | test("^[a-z_][a-z0-9_-]{0,31}$")) and (.delete_home | type == "boolean"))' "$archivo" >/dev/null 2>&1; then
        log_mensaje "INFO" "$logs_archivo" "$nombre_script" "$usuario_ejecutor" "$usuario_efectivo" "Esquema del JSON validado exitosamente"
        return 0
    else
        log_mensaje "CRITICAL" "$logs_archivo" "$nombre_script" "$usuario_ejecutor" "$usuario_efectivo" "Esquema del JSON INVALIDO"
        return 1
    fi
}

# Funciones para leer
# Esta en si es para leer en crear
leer_json_crear() {
    local archivo="$1"
    jq -r '.users[] | [.username, (.groups // ""), (.create_home // false)] | @tsv' "$archivo"
}

# Esta leer la de bloquear
leer_json_bloquear() {
    local archivo="$1"
    jq -r '.users[] | [.username] | @tsv' "$archivo"
}

# Esta lee la de eliminar
leer_json_eliminar() {
    local archivo="$1"
    jq -r '.users[] | [.username, (.delete_home // false)] | @tsv' "$archivo"
}

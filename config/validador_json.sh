#!/usr/bin/bash

# Funciones de validar JSON
validar_archivo_json() {
    local archivo="$1"
    local logs_interno="$2"
    local logs_archivo="$logs_interno/gestion_usuarios.log"
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
    local logs_interno="$2"
    local logs_archivo="$logs_interno/gestion_usuarios.log"
    if jq -e '(.users | type == "array") and (.users | length > 0) and all(.users[]; (.username | type == "string") and (.groups | type == "string") and (.username | test("^[a-z_][a-z0-9_-]{0,31}$")))' "$archivo" >/dev/null 2>&1; then
        printf "%s - INFO - Esquema del JSON validado\n" "$FECHA" 2>&1 | tee -a "$logs_archivo"
        return 0
    else
        printf "%s - FATAL - Esquema del JSON INVALIDO\n" "$FECHA" 2>&1 | tee -a "$logs_archivo"
        return 1
    fi
}

validar_json_esquema_bloquear(){
    local archivo="$1"
    local logs_interno="$2"
    local logs_archivo="$logs_interno/gestion_usuarios.log"
    if jq -e '(.users | type == "array") and (.users | length > 0) and all(.users[]; (.username | type == "string") and (.username | test("^[a-z_][a-z0-9_-]{0,31}$")))' "$archivo" >/dev/null 2>&1; then
        printf "%s - INFO - Esquema del JSON validado\n" "$FECHA" 2>&1 | tee -a "$logs_archivo"
        return 0
    else
        printf "%s - FATAL - Esquema del JSON INVALIDO\n" "$FECHA" 2>&1 | tee -a "$logs_archivo"
        return 1
    fi
}

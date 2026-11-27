#!/usr/bin/env bash
# Funcion para validar la carpeta logs interna
# Para los scripts
validar_logint(){
    local logs_interno="$1"
    local logs_archivo="$2"
    local nombre_script="$3"
    local usuario_ejecutor="$4"
    local usuario_efectivo="$5"
    if [[ -d "$logs_interno" ]] && [[ -r "$logs_interno" ]] && [[ -w "$logs_interno" ]]; then
        log_mensaje "DEBUG" "$logs_archivo" "$nombre_script" "$usuario_ejecutor" "$usuario_efectivo" "Validando carpeta logs existente ruta y permisos existosamente"
        return 0
    else
        mkdir -p "$logs_interno"
        log_mensaje "WARNING" "$logs_archivo" "$nombre_script" "$usuario_ejecutor" "$usuario_efectivo" "Carpeta '/logs' no creada"
        log_mensaje "INFO" "$logs_archivo" "$nombre_script" "$usuario_ejecutor" "$usuario_efectivo" "Se ha creado carpeta ubicacion"
        return 0
    fi
}

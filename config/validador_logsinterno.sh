#!/usr/bin/env bash
# Funcion para validar la carpeta logs interna
# Para los scripts
validar_logint(){
    local logs_interno="$1"
    local logs_archivo="$logs_interno/gestion_usuarios.log"
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

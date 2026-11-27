#!/usr/bin/env bash

# Una funcion para generar logs hacia la ubicacion
# Usando "tee -a"
# En si seria
# log_mensaje "NIVEL" "UBICACION" "MENSAJE"
log_mensaje(){
    # Para capturar y luego todo lo mensaje o arg siguiente leerlos aprox
    local nivel="$1"
    local ubicacion="$2"
    shift
    local mensaje="$*"
    local fecha_actual
    fecha_actual="$(date +'%Y-%m-%d-%H:%M:%S')"

    printf "%s - %s - %s\n" "$fecha_actual" "$nivel" "$mensaje" | tee -a "$ubicacion"
}

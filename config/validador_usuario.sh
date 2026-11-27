#!/usr/bin/env bash

# Funcion solo para validar si existe el usuario previo
usuario_existe(){
    getent passwd "$1" >/dev/null 2>&1
}

# Scripts de gestión
Estos scripts permiten el desarrollo de tareas con la finalidad
de resolver problemas o facilitar procesos. 
*Digamos - agrupados como una toolkit basica*

### **Decision de diseño**
- **Filosofia Unix** : *Cada script tiene una responsabilidad buscando facilitar actividades , lectura y mantenimiento sin dependencias pesadas en su mayoria.*
- **Sin flags complejas** : *Busca la ejecución directa , predecible y auditable*

## Configuracion rápida
1. Clonar repositorio:
```
git clone https://github.com/Vl4xpo/SF-Toolkit.git
cd SF-Toolkit
```

2. Dar permisos de ejecución a los scripts:
```
chmod +x scripts/*.sh
```

## Uso de scripts:



## Estructura del proyecto
```
SF-Toolkit
├── config/
│   ├── settings.env      # variables generales o parametros entre scripts
│   
├── scripts/
│   ├── auto_backups.sh       # Respaldo comprimido          
│   ├── sistema_monitoreo.sh  # Alerta y lectura - visualización
│   └── gestion_usuarios.sh   # Creacion y asignacion de roles
└── logs/                 # Salida histórica de cada ejecución

```

## Requisitos
- `bash` (4.0+) o `bash` (>5.2.20)
- Dependencias : `jq` - Para lectura y creacion de usuarios

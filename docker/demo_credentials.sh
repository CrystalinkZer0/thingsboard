#!/bin/bash
#
# Copyright © 2016-2026 The Thingsboard Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#

###############################################################################
# Demo Rápido - ThingsBoard Credenciales
# Este script demuestra cómo funcionan las credenciales en ThingsBoard
###############################################################################

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

clear

cat << "EOF"
╔══════════════════════════════════════════════════════════════════════════╗
║                                                                          ║
║     ████████╗██╗  ██╗██╗███╗   ██╗ ██████╗ ███████╗██████╗  ██████╗     ║
║     ╚══██╔══╝██║  ██║██║████╗  ██║██╔════╝ ██╔════╝██╔══██╗██╔═══██╗    ║
║        ██║   ███████║██║██╔██╗ ██║██║  ███╗███████╗██████╔╝██║   ██║    ║
║        ██║   ██╔══██║██║██║╚██╗██║██║   ██║╚════██║██╔══██╗██║   ██║    ║
║        ██║   ██║  ██║██║██║ ╚████║╚██████╔╝███████║██████╔╝╚██████╔╝    ║
║        ╚═╝   ╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚══════╝╚═════╝  ╚═════╝     ║
║                                                                          ║
║                   DEMOSTRACIÓN DE CREDENCIALES                          ║
║                                                                          ║
╚══════════════════════════════════════════════════════════════════════════╝
EOF

echo ""
echo -e "${CYAN}Presiona Enter para comenzar el demo...${NC}"
read

clear

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  PARTE 1: Tipos de Credenciales en ThingsBoard${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "ThingsBoard maneja DOS tipos principales de credenciales:"
echo ""

cat << "EOF"
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│  1️⃣  USUARIO / CONTRASEÑA                                       │
│     Para: Humanos (interfaz web, APIs REST)                    │
│     Ejemplo: tenant@thingsboard.org / tenant                   │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  👤 Usuario → http://localhost → 🖥️  Interfaz Web       │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│  2️⃣  ACCESS TOKEN                                               │
│     Para: Dispositivos IoT (sensores, actuadores)              │
│     Ejemplo: A1_WEATHER_SENSOR_TOKEN                           │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  📡 Sensor → MQTT/HTTP → 🏢 ThingsBoard                  │  │
│  │       (usa Access Token para autenticarse)               │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
EOF

echo ""
echo -e "${CYAN}Presiona Enter para continuar...${NC}"
read

clear

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  PARTE 2: ¿Necesitas crear cuenta para usar ThingsBoard local?${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

cat << "EOF"
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│  ❌ NO NECESITAS CREAR CUENTA EXTERNA                           │
│                                                                 │
│  Cuando instalas ThingsBoard con Docker:                       │
│                                                                 │
│  ✅ Se crean usuarios AUTOMÁTICAMENTE                           │
│  ✅ Todo es 100% LOCAL en tu máquina                            │
│  ✅ NO necesitas internet (excepto para descargar Docker)       │
│  ✅ NO necesitas registrarte en ningún sitio web                │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  Instalación básica:                                            │
│                                                                 │
│    $ cd docker                                                  │
│    $ ./docker-install-tb.sh                                     │
│    $ ./docker-start-services.sh                                 │
│                                                                 │
│  ➜ Se crea automáticamente:                                     │
│                                                                 │
│    Usuario: sysadmin@thingsboard.org                           │
│    Password: sysadmin                                          │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  Instalación con datos demo (RECOMENDADO para empezar):        │
│                                                                 │
│    $ cd docker                                                  │
│    $ ./docker-install-tb.sh --loadDemo                          │
│    $ ./docker-start-services.sh                                 │
│                                                                 │
│  ➜ Se crean automáticamente:                                    │
│                                                                 │
│    👤 System Admin:    sysadmin@thingsboard.org / sysadmin     │
│    👤 Tenant Admin:    tenant@thingsboard.org / tenant         │
│    👤 Customer User:   customer@thingsboard.org / customer     │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
EOF

echo ""
echo -e "${CYAN}Presiona Enter para continuar...${NC}"
read

clear

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  PARTE 3: Jerarquía de Usuarios${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

cat << "EOF"
                 ┌─────────────────────────────────┐
                 │   SYSTEM ADMINISTRATOR          │
                 │   (Superusuario)                │
                 │                                 │
                 │   👤 sysadmin@thingsboard.org   │
                 │   🔑 sysadmin                   │
                 │                                 │
                 │   Puede:                        │
                 │   ✅ Gestionar TODO el sistema   │
                 │   ✅ Crear/eliminar Tenants      │
                 │   ✅ Configuración global        │
                 └────────────┬────────────────────┘
                              │
                   ┌──────────┴──────────┐
                   │                     │
        ┌──────────▼──────────┐  ┌──────▼──────────────┐
        │  TENANT ADMIN       │  │  TENANT ADMIN       │
        │  (Inquilino A)      │  │  (Inquilino B)      │
        │                     │  │                     │
        │  👤 tenant@...      │  │  👤 otrotenant@...  │
        │  🔑 tenant          │  │  🔑 password        │
        │                     │  │                     │
        │  Puede:             │  │  Puede:             │
        │  ✅ Crear devices    │  │  ✅ Crear devices    │
        │  ✅ Crear dashboards │  │  ✅ Crear dashboards │
        │  ✅ Gestionar rules  │  │  ✅ Gestionar rules  │
        │  ✅ Crear customers  │  │  ✅ Crear customers  │
        └──────────┬──────────┘  └──────┬──────────────┘
                   │                    │
        ┌──────────▼──────────┐  ┌──────▼──────────────┐
        │  CUSTOMER USER      │  │  CUSTOMER USER      │
        │  (Usuario final)    │  │  (Usuario final)    │
        │                     │  │                     │
        │  👤 customer@...    │  │  👤 usuario@...     │
        │  🔑 customer        │  │  🔑 password        │
        │                     │  │                     │
        │  Puede:             │  │  Puede:             │
        │  ✅ Ver dashboards   │  │  ✅ Ver dashboards   │
        │  ❌ Solo lectura     │  │  ❌ Solo lectura     │
        └─────────────────────┘  └─────────────────────┘
EOF

echo ""
echo -e "${CYAN}Presiona Enter para continuar...${NC}"
read

clear

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  PARTE 4: Flujo de trabajo - Crear dispositivo y obtener token${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

cat << "EOF"
  PASO 1: Login en la interfaz web
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  🌐 http://localhost
  
  👤 Email:     tenant@thingsboard.org
  🔑 Password:  tenant
  
  
  PASO 2: Crear un dispositivo
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  Menú izquierdo → Devices → + (Add Device)
  
  📝 Name:          Mi Sensor de Temperatura
  📝 Device Type:   default
  
  → Click en "Add"
  
  
  PASO 3: Obtener Access Token
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  Click en "Mi Sensor de Temperatura"
  → Pestaña "Credentials"
  
  Verás algo como:
  
    Credential Type:  Access Token
    Access Token:     A1_WEATHER_SENSOR_TOKEN  ← ¡COPIA ESTE TOKEN!
  
  
  PASO 4: Usar el token para enviar datos
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  Opción A - HTTP:
  
    curl -X POST http://localhost:8080/api/v1/A1_WEATHER_SENSOR_TOKEN/telemetry \
      -H "Content-Type: application/json" \
      -d '{"temperature": 25.5, "humidity": 60}'
  
  Opción B - MQTT:
  
    mosquitto_pub -h localhost -t v1/devices/me/telemetry \
      -u "A1_WEATHER_SENSOR_TOKEN" \
      -m '{"temperature": 25.5, "humidity": 60}'
  
  
  PASO 5: Ver los datos en la interfaz
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  Devices → Mi Sensor de Temperatura → Latest telemetry
  
  ✅ Deberías ver:
     temperature: 25.5
     humidity: 60
EOF

echo ""
echo -e "${CYAN}Presiona Enter para continuar...${NC}"
read

clear

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  PARTE 5: Diferencia entre Usuario/Password y Access Token${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

cat << "EOF"
┌─────────────────────────────────────────────────────────────────────┐
│                                                                     │
│  USUARIO / PASSWORD                                                 │
│  ═══════════════════                                                │
│                                                                     │
│  Para qué sirve:                                                    │
│    • Login en interfaz web (http://localhost)                      │
│    • Obtener JWT token para usar APIs REST                         │
│    • Gestionar dispositivos, dashboards, usuarios                  │
│                                                                     │
│  Ejemplo:                                                           │
│    Email:     tenant@thingsboard.org                               │
│    Password:  tenant                                               │
│                                                                     │
│  Usado por:                                                         │
│    👤 Humanos (administradores, usuarios)                           │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  Login → Obtiene JWT token → Expira en 24 horas (configurable)│
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                                                                     │
│  ACCESS TOKEN                                                       │
│  ═════════════                                                      │
│                                                                     │
│  Para qué sirve:                                                    │
│    • Autenticar DISPOSITIVOS IoT                                   │
│    • Enviar telemetría (temperatura, humedad, etc.)                │
│    • Recibir comandos RPC                                          │
│                                                                     │
│  Ejemplo:                                                           │
│    A1_WEATHER_SENSOR_TOKEN                                         │
│                                                                     │
│  Usado por:                                                         │
│    📡 Dispositivos IoT (sensores, actuadores)                       │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  Token permanente → No expira → Se puede cambiar manualmente │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                                                                     │
│  COMPARACIÓN RÁPIDA                                                 │
│  ══════════════════                                                 │
│                                                                     │
│  ┌───────────────────┬────────────────────┬─────────────────────┐  │
│  │ Característica    │ Usuario/Password   │ Access Token        │  │
│  ├───────────────────┼────────────────────┼─────────────────────┤  │
│  │ Usado por         │ 👤 Humanos         │ 📡 Dispositivos IoT │  │
│  │ Dónde se usa      │ Web, API REST      │ MQTT, HTTP, CoAP    │  │
│  │ Expira            │ ✅ Sí (24h)        │ ❌ No               │  │
│  │ Puede crear otros │ ✅ Sí              │ ❌ No               │  │
│  │ Formato           │ email/password     │ String único        │  │
│  └───────────────────┴────────────────────┴─────────────────────┘  │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
EOF

echo ""
echo -e "${CYAN}Presiona Enter para continuar...${NC}"
read

clear

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  RESUMEN FINAL${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

cat << "EOF"
  ✅ PUNTOS CLAVE
  ═══════════════════════════════════════════════════════════════════
  
  1. NO necesitas crear cuenta externa para usar ThingsBoard local
  
  2. Al instalar con Docker, se crean usuarios automáticamente:
     • sysadmin@thingsboard.org / sysadmin
     • tenant@thingsboard.org / tenant (con --loadDemo)
  
  3. Hay DOS tipos de credenciales:
     • Usuario/Password: Para humanos (interfaz web)
     • Access Token: Para dispositivos IoT
  
  4. El Access Token NO es lo mismo que un tenant
  
  5. NO necesitas crear un tenant si usas --loadDemo
  
  
  📚 DOCUMENTACIÓN DISPONIBLE
  ═══════════════════════════════════════════════════════════════════
  
  • MANUAL_CONFIGURACION.md    - Manual completo de configuración
  • GUIA_CREDENCIALES.md       - Guía detallada de credenciales
  • CREDENCIALES_RESUMEN.md    - Respuestas rápidas
  • docker/manage_credentials.sh - Script interactivo de gestión
  
  
  🚀 INICIO RÁPIDO
  ═══════════════════════════════════════════════════════════════════
  
  1. Instalar:
     $ cd docker
     $ ./docker-install-tb.sh --loadDemo
     $ ./docker-start-services.sh
  
  2. Acceder:
     http://localhost
     tenant@thingsboard.org / tenant
  
  3. Crear dispositivo y obtener Access Token
  
  4. Enviar datos con el token
  
  
  🛠️  HERRAMIENTAS
  ═══════════════════════════════════════════════════════════════════
  
  Script de gestión de credenciales:
  $ cd docker
  $ ./manage_credentials.sh
  
EOF

echo ""
echo -e "${GREEN}¡Demo completado!${NC}"
echo ""
echo -e "${YELLOW}¿Quieres ejecutar el script interactivo de gestión? (s/n)${NC}"
read -n 1 response
echo ""

if [ "$response" == "s" ] || [ "$response" == "S" ]; then
    cd "$(dirname "$0")"
    if [ -f "manage_credentials.sh" ]; then
        ./manage_credentials.sh
    else
        echo -e "${RED}Script no encontrado en el directorio actual${NC}"
    fi
fi

echo ""
echo -e "${CYAN}¡Gracias por usar ThingsBoard!${NC}"
echo ""

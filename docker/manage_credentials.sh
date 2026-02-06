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
# Script de Gestión de Credenciales de ThingsBoard
# Autor: Equipo Innvoid
# Fecha: Enero 2026
###############################################################################

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuración
THINGSBOARD_URL="${THINGSBOARD_URL:-http://localhost:8080}"

###############################################################################
# Funciones de utilidad
###############################################################################

print_header() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║     ThingsBoard - Gestión de Credenciales            ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

check_dependencies() {
    local missing_deps=()
    
    if ! command -v curl &> /dev/null; then
        missing_deps+=("curl")
    fi
    
    if ! command -v jq &> /dev/null; then
        missing_deps+=("jq")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_error "Faltan dependencias: ${missing_deps[*]}"
        echo ""
        echo "Instala con:"
        echo "  macOS: brew install ${missing_deps[*]}"
        echo "  Linux: sudo apt-get install ${missing_deps[*]}"
        exit 1
    fi
}

check_thingsboard() {
    print_info "Verificando conexión con ThingsBoard en $THINGSBOARD_URL..."
    
    if ! curl -s -f "$THINGSBOARD_URL/api/noauth/health" > /dev/null 2>&1; then
        print_error "No se puede conectar a ThingsBoard"
        print_info "Asegúrate de que ThingsBoard está corriendo:"
        echo "  cd docker && ./docker-start-services.sh"
        exit 1
    fi
    
    print_success "ThingsBoard está corriendo"
}

###############################################################################
# Funciones de autenticación
###############################################################################

login() {
    local email="$1"
    local password="$2"
    
    local response=$(curl -s -X POST "$THINGSBOARD_URL/api/auth/login" \
        -H "Content-Type: application/json" \
        -d "{\"username\":\"$email\",\"password\":\"$password\"}")
    
    local token=$(echo "$response" | jq -r '.token // empty')
    
    if [ -z "$token" ] || [ "$token" == "null" ]; then
        print_error "Login fallido"
        echo "$response" | jq -r '.message // "Error desconocido"'
        return 1
    fi
    
    echo "$token"
}

get_user_info() {
    local token="$1"
    
    curl -s -X GET "$THINGSBOARD_URL/api/auth/user" \
        -H "Authorization: Bearer $token"
}

###############################################################################
# Menú: Verificar credenciales de usuario
###############################################################################

verify_user_credentials() {
    echo ""
    echo -e "${BLUE}══════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  Verificar Credenciales de Usuario${NC}"
    echo -e "${BLUE}══════════════════════════════════════════════════════${NC}"
    echo ""
    
    echo "Credenciales por defecto:"
    echo "  - System Admin: sysadmin@thingsboard.org / sysadmin"
    echo "  - Tenant Admin: tenant@thingsboard.org / tenant"
    echo "  - Customer: customer@thingsboard.org / customer"
    echo ""
    
    read -p "Email: " email
    read -s -p "Password: " password
    echo ""
    echo ""
    
    print_info "Intentando login..."
    
    TOKEN=$(login "$email" "$password")
    if [ $? -eq 0 ]; then
        print_success "Login exitoso!"
        echo ""
        
        USER_INFO=$(get_user_info "$TOKEN")
        
        echo "Información del usuario:"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "$USER_INFO" | jq -r '
            "  Email:     \(.email)",
            "  Nombre:    \(.firstName) \(.lastName)",
            "  Rol:       \(.authority)",
            "  ID:        \(.id.id)"
        '
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "Token JWT (primeros 50 caracteres):"
        echo "  ${TOKEN:0:50}..."
    fi
}

###############################################################################
# Menú: Listar dispositivos y sus tokens
###############################################################################

list_devices_and_tokens() {
    echo ""
    echo -e "${BLUE}══════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  Listar Dispositivos y Access Tokens${NC}"
    echo -e "${BLUE}══════════════════════════════════════════════════════${NC}"
    echo ""
    
    read -p "Email (Tenant Admin): " email
    read -s -p "Password: " password
    echo ""
    echo ""
    
    print_info "Obteniendo lista de dispositivos..."
    
    TOKEN=$(login "$email" "$password")
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    # Obtener dispositivos
    DEVICES=$(curl -s -X GET "$THINGSBOARD_URL/api/tenant/devices?pageSize=100&page=0" \
        -H "Authorization: Bearer $TOKEN")
    
    local device_count=$(echo "$DEVICES" | jq -r '.data | length')
    
    if [ "$device_count" -eq 0 ]; then
        print_warning "No hay dispositivos registrados"
        return 0
    fi
    
    print_success "Se encontraron $device_count dispositivos"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    printf "%-30s %-40s %-20s\n" "NOMBRE" "ACCESS TOKEN" "TIPO"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    echo "$DEVICES" | jq -r '.data[] | [.id.id, .name, .type] | @tsv' | while IFS=$'\t' read -r device_id device_name device_type; do
        # Obtener credenciales del dispositivo
        CREDENTIALS=$(curl -s -X GET "$THINGSBOARD_URL/api/device/$device_id/credentials" \
            -H "Authorization: Bearer $TOKEN")
        
        ACCESS_TOKEN=$(echo "$CREDENTIALS" | jq -r '.credentialsId // "N/A"')
        
        printf "%-30s %-40s %-20s\n" "$device_name" "$ACCESS_TOKEN" "$device_type"
    done
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

###############################################################################
# Menú: Crear nuevo dispositivo
###############################################################################

create_device() {
    echo ""
    echo -e "${BLUE}══════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  Crear Nuevo Dispositivo${NC}"
    echo -e "${BLUE}══════════════════════════════════════════════════════${NC}"
    echo ""
    
    read -p "Email (Tenant Admin): " email
    read -s -p "Password: " password
    echo ""
    echo ""
    
    TOKEN=$(login "$email" "$password")
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    read -p "Nombre del dispositivo: " device_name
    read -p "Tipo de dispositivo (default): " device_type
    device_type=${device_type:-default}
    
    print_info "Creando dispositivo '$device_name'..."
    
    DEVICE_RESPONSE=$(curl -s -X POST "$THINGSBOARD_URL/api/device" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $TOKEN" \
        -d "{
            \"name\": \"$device_name\",
            \"type\": \"$device_type\"
        }")
    
    DEVICE_ID=$(echo "$DEVICE_RESPONSE" | jq -r '.id.id // empty')
    
    if [ -z "$DEVICE_ID" ]; then
        print_error "Error al crear dispositivo"
        echo "$DEVICE_RESPONSE" | jq .
        return 1
    fi
    
    print_success "Dispositivo creado con ID: $DEVICE_ID"
    
    # Obtener credenciales
    print_info "Obteniendo Access Token..."
    
    CREDENTIALS=$(curl -s -X GET "$THINGSBOARD_URL/api/device/$DEVICE_ID/credentials" \
        -H "Authorization: Bearer $TOKEN")
    
    ACCESS_TOKEN=$(echo "$CREDENTIALS" | jq -r '.credentialsId')
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${GREEN}  Dispositivo creado exitosamente${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Nombre:        $device_name"
    echo "  Tipo:          $device_type"
    echo "  ID:            $DEVICE_ID"
    echo "  Access Token:  $ACCESS_TOKEN"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Guarda el Access Token. Úsalo para enviar datos:"
    echo ""
    echo "  # HTTP"
    echo "  curl -X POST $THINGSBOARD_URL/api/v1/$ACCESS_TOKEN/telemetry \\"
    echo "    -H 'Content-Type: application/json' \\"
    echo "    -d '{\"temperature\": 25.5}'"
    echo ""
    echo "  # MQTT"
    echo "  mosquitto_pub -h localhost -t v1/devices/me/telemetry \\"
    echo "    -u '$ACCESS_TOKEN' \\"
    echo "    -m '{\"temperature\": 25.5}'"
}

###############################################################################
# Menú: Probar envío de datos
###############################################################################

test_send_data() {
    echo ""
    echo -e "${BLUE}══════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  Probar Envío de Datos de Telemetría${NC}"
    echo -e "${BLUE}══════════════════════════════════════════════════════${NC}"
    echo ""
    
    read -p "Access Token del dispositivo: " access_token
    
    if [ -z "$access_token" ]; then
        print_error "Access Token no puede estar vacío"
        return 1
    fi
    
    # Generar datos aleatorios
    TEMP=$(echo "scale=1; 20 + ($RANDOM % 100) / 10" | bc)
    HUM=$(echo "50 + ($RANDOM % 40)" | bc)
    TIMESTAMP=$(date +%s000)
    
    print_info "Enviando datos de prueba..."
    echo "  Temperatura: ${TEMP}°C"
    echo "  Humedad:     ${HUM}%"
    echo ""
    
    RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
        "$THINGSBOARD_URL/api/v1/$access_token/telemetry" \
        -H "Content-Type: application/json" \
        -d "{
            \"temperature\": $TEMP,
            \"humidity\": $HUM,
            \"timestamp\": $TIMESTAMP
        }")
    
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | head -n-1)
    
    if [ "$HTTP_CODE" -eq 200 ]; then
        print_success "Datos enviados correctamente!"
        print_info "Revisa en la interfaz: Devices → Tu dispositivo → Latest telemetry"
    else
        print_error "Error al enviar datos (HTTP $HTTP_CODE)"
        echo "$BODY"
    fi
}

###############################################################################
# Menú: Ver credenciales por defecto
###############################################################################

show_default_credentials() {
    echo ""
    echo -e "${BLUE}══════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  Credenciales por Defecto de ThingsBoard${NC}"
    echo -e "${BLUE}══════════════════════════════════════════════════════${NC}"
    echo ""
    
    echo "Después de instalar con: ./docker-install-tb.sh --loadDemo"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${GREEN}System Administrator${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Email:     sysadmin@thingsboard.org"
    echo "  Password:  sysadmin"
    echo "  Rol:       ADMIN del sistema"
    echo "  Permisos:  Gestión total, crear tenants"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${GREEN}Tenant Administrator${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Email:     tenant@thingsboard.org"
    echo "  Password:  tenant"
    echo "  Rol:       TENANT_ADMIN"
    echo "  Permisos:  Gestionar dispositivos, dashboards, rules"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${GREEN}Customer User${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Email:     customer@thingsboard.org"
    echo "  Password:  customer"
    echo "  Rol:       CUSTOMER_USER"
    echo "  Permisos:  Solo ver dashboards asignados"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Acceso: $THINGSBOARD_URL"
}

###############################################################################
# Menú principal
###############################################################################

show_menu() {
    echo ""
    echo -e "${BLUE}┌──────────────────────────────────────────────────┐${NC}"
    echo -e "${BLUE}│  MENÚ PRINCIPAL                                  │${NC}"
    echo -e "${BLUE}└──────────────────────────────────────────────────┘${NC}"
    echo ""
    echo "  1) Ver credenciales por defecto"
    echo "  2) Verificar credenciales de usuario"
    echo "  3) Listar dispositivos y Access Tokens"
    echo "  4) Crear nuevo dispositivo"
    echo "  5) Probar envío de datos"
    echo "  0) Salir"
    echo ""
    read -p "Selecciona una opción: " option
    
    case $option in
        1) show_default_credentials ;;
        2) verify_user_credentials ;;
        3) list_devices_and_tokens ;;
        4) create_device ;;
        5) test_send_data ;;
        0) 
            print_info "¡Hasta luego!"
            exit 0
            ;;
        *)
            print_error "Opción inválida"
            ;;
    esac
}

###############################################################################
# Main
###############################################################################

main() {
    print_header
    
    # Verificar dependencias
    check_dependencies
    
    # Verificar que ThingsBoard esté corriendo
    check_thingsboard
    
    # Menú infinito
    while true; do
        show_menu
        echo ""
        read -p "Presiona Enter para continuar..."
    done
}

main "$@"

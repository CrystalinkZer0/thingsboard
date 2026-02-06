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

# Guía Interactiva para Registrar ESP32 en ThingsBoard
# Este script te ayuda a registrar y configurar tu ESP32 en ThingsBoard
#

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Funciones
print_header() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  $1"
    echo -e "${CYAN}╚════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_step() {
    echo -e "${BLUE}▶${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_info() {
    echo -e "${YELLOW}ℹ${NC} $1"
}

print_code() {
    echo -e "${CYAN}$1${NC}"
}

# Solicitar credenciales de ThingsBoard
read_credentials() {
    echo ""
    print_step "Ingresa las credenciales de tu ThingsBoard"
    
    read -p "  URL de ThingsBoard (ej: http://192.168.4.177:8080): " TB_URL
    read -p "  Usuario (ej: sysadmin@thingsboard.org): " TB_USER
    read -sp "  Contraseña: " TB_PASSWORD
    echo ""
    
    # Validar conectividad
    print_info "Verificando conectividad con ThingsBoard..."
    
    if ! curl -s "${TB_URL}/api/auth/login" \
        -H "Content-Type: application/json" \
        -d "{\"username\":\"${TB_USER}\",\"password\":\"${TB_PASSWORD}\"}" \
        | grep -q "token"; then
        echo -e "${RED}✗ Error: No se puede conectar a ThingsBoard${NC}"
        exit 1
    fi
    
    print_success "Conectado a ThingsBoard"
}

# Obtener token de login
get_login_token() {
    TOKEN=$(curl -s "${TB_URL}/api/auth/login" \
        -H "Content-Type: application/json" \
        -d "{\"username\":\"${TB_USER}\",\"password\":\"${TB_PASSWORD}\"}" \
        | grep -oP '"token":"\K[^"]+')
    
    if [ -z "$TOKEN" ]; then
        echo -e "${RED}✗ Error al obtener token${NC}"
        exit 1
    fi
}

# Paso 1: Crear Tenant (si es necesario)
create_tenant() {
    print_header "PASO 1: Crear o Seleccionar Tenant"
    
    print_step "Obteniendo lista de tenants..."
    
    TENANTS=$(curl -s "${TB_URL}/api/tenants?pageSize=100" \
        -H "X-Authorization: Bearer ${TOKEN}" \
        -H "Content-Type: application/json")
    
    echo ""
    print_info "Tenants disponibles:"
    echo "$TENANTS" | grep -oP '"name":"\K[^"]+' | nl
    
    read -p "  Ingresa el número del tenant a usar (o 0 para crear uno nuevo): " TENANT_CHOICE
    
    if [ "$TENANT_CHOICE" = "0" ]; then
        read -p "  Nombre del nuevo tenant: " TENANT_NAME
        
        TENANT_ID=$(curl -s "${TB_URL}/api/tenant" \
            -X POST \
            -H "X-Authorization: Bearer ${TOKEN}" \
            -H "Content-Type: application/json" \
            -d "{\"title\":\"${TENANT_NAME}\"}" \
            | grep -oP '"id":{"id":"\K[^"]+')
        
        print_success "Tenant creado: ${TENANT_ID}"
    else
        # Obtener ID del tenant seleccionado
        TENANT_ID=$(echo "$TENANTS" | grep -oP '"id":{"id":"\K[^"]+' | sed -n "${TENANT_CHOICE}p")
    fi
}

# Paso 2: Crear Dispositivo ESP32
create_device() {
    print_header "PASO 2: Crear Dispositivo ESP32"
    
    DEVICE_NAME="ESP32_IoT_Sensors"
    DEVICE_TYPE="default"
    
    print_step "Creando dispositivo: ${DEVICE_NAME}"
    
    DEVICE_JSON=$(curl -s "${TB_URL}/api/device?accessToken=${TOKEN}" \
        -X POST \
        -H "X-Authorization: Bearer ${TOKEN}" \
        -H "Content-Type: application/json" \
        -d "{
            \"name\":\"${DEVICE_NAME}\",
            \"type\":\"${DEVICE_TYPE}\",
            \"label\":\"ESP32 con Sensores IoT\",
            \"description\":\"Placa ESP32 con DHT11 y Sensor de Sonido W104\",
            \"additionalInfo\":{
                \"description\":\"ESP32 con sensores ambientales\"
            }
        }")
    
    DEVICE_ID=$(echo "$DEVICE_JSON" | grep -oP '"id":{"id":"\K[^"]+')
    
    if [ -z "$DEVICE_ID" ]; then
        echo -e "${RED}✗ Error al crear dispositivo${NC}"
        echo "Respuesta: $DEVICE_JSON"
        exit 1
    fi
    
    print_success "Dispositivo creado con ID: ${DEVICE_ID}"
}

# Paso 3: Obtener Access Token del Dispositivo
get_device_token() {
    print_header "PASO 3: Obtener Access Token del Dispositivo"
    
    print_step "Obteniendo credenciales del dispositivo..."
    
    CREDENTIALS=$(curl -s "${TB_URL}/api/device/${DEVICE_ID}/credentials" \
        -H "X-Authorization: Bearer ${TOKEN}" \
        -H "Content-Type: application/json")
    
    DEVICE_TOKEN=$(echo "$CREDENTIALS" | grep -oP '"credentialsId":"\K[^"]+' | head -1)
    
    if [ -z "$DEVICE_TOKEN" ]; then
        # Si no existe, crear una nueva credencial
        CRED_JSON=$(curl -s "${TB_URL}/api/device/${DEVICE_ID}/credentials" \
            -X POST \
            -H "X-Authorization: Bearer ${TOKEN}" \
            -H "Content-Type: application/json" \
            -d "{
                \"deviceId\":{\"id\":\"${DEVICE_ID}\"},
                \"type\":\"ACCESS_TOKEN\",
                \"credentialsType\":\"ACCESS_TOKEN\",
                \"credentialsId\":\"esp32_iot_token_$(date +%s)\"
            }")
        
        DEVICE_TOKEN=$(echo "$CRED_JSON" | grep -oP '"credentialsId":"\K[^"]+')
    fi
    
    if [ -z "$DEVICE_TOKEN" ]; then
        echo -e "${RED}✗ Error al obtener token del dispositivo${NC}"
        exit 1
    fi
    
    print_success "Access Token obtenido"
}

# Paso 4: Crear Atributos del Dispositivo
create_device_attributes() {
    print_header "PASO 4: Crear Atributos del Dispositivo"
    
    print_step "Configurando atributos del dispositivo..."
    
    # Atributos compartidos
    curl -s "${TB_URL}/api/plugins/telemetry/DEVICE/${DEVICE_ID}/attributes/SHARED_SCOPE" \
        -X POST \
        -H "X-Authorization: Bearer ${TOKEN}" \
        -H "Content-Type: application/json" \
        -d '{
            "model": "ESP32-WROOM-32",
            "manufacturer": "Espressif Systems",
            "serialNumber": "ESP32-001",
            "firmwareVersion": "1.0.0"
        }' > /dev/null
    
    # Atributos de cliente
    curl -s "${TB_URL}/api/plugins/telemetry/DEVICE/${DEVICE_ID}/attributes/CLIENT_SCOPE" \
        -X POST \
        -H "X-Authorization: Bearer ${TOKEN}" \
        -H "Content-Type: application/json" \
        -d '{
            "location": "Lab",
            "status": "active"
        }' > /dev/null
    
    print_success "Atributos creados"
}

# Paso 5: Crear Regla de Procesamiento (opcional)
create_rule() {
    print_header "PASO 5: Crear Regla de Procesamiento (Opcional)"
    
    read -p "  ¿Deseas crear una regla de alerta? (s/n): " CREATE_RULE
    
    if [ "$CREATE_RULE" = "s" ] || [ "$CREATE_RULE" = "S" ]; then
        print_step "Creando regla de temperaturas altas..."
        
        # Aquí va la creación de la regla
        print_info "Las reglas se crean desde la interfaz web"
        print_info "En el Panel de ThingsBoard → Reglas → Crear Nueva Regla"
    fi
}

# Paso 6: Mostrar Configuración Final
show_final_config() {
    print_header "PASO 6: Configuración del ESP32"
    
    echo -e "${GREEN}Guarda esta configuración en tu ESP32:${NC}"
    echo ""
    
    cat << EOF
╔════════════════════════════════════════════════════════════════╗
║                   CONFIGURACIÓN DEL ESP32                      ║
╠════════════════════════════════════════════════════════════════╣
║
║ Nombre del Dispositivo:    ${DEVICE_NAME}
║ Device ID:                 ${DEVICE_ID}
║ Access Token:              ${DEVICE_TOKEN}
║
║ CONEXIÓN MQTT:
║ ─────────────
║ Broker:                    192.168.4.177
║ Puerto:                    1883
║ Usuario (opcional):        (dejar vacío)
║ Contraseña (opcional):     (dejar vacío)
║ Client ID:                 ESP32_${DEVICE_ID:0:8}
║ Topic de Publicación:      v1/devices/me/telemetry
║ Access Token MQTT:         ${DEVICE_TOKEN}
║
║ SENSORES:
║ ─────────
║ DHT11 Temperatura:         GPIO 4
║ DHT11 Humedad:             GPIO 4
║ Sensor de Sonido W104:     GPIO 34 (ADC)
║ LED Estado:                GPIO 2
║
║ DATOS A ENVIAR:
║ ───────────────
║ Telemetría (v1/devices/me/telemetry):
║   {
║     "temperature":      25.5,
║     "humidity":         65.3,
║     "soundLevel":       2048,
║     "timestamp":        1609459200000
║   }
║
╚════════════════════════════════════════════════════════════════╝
EOF
    
    echo ""
    echo -e "${GREEN}Ejemplo de código Arduino para conectar:${NC}"
    echo ""
    
    cat << 'ARDUINO_CODE'
#include <WiFi.h>
#include <PubSubClient.h>
#include "DHT.h"

// Configuración WiFi
const char* ssid = "HOP85";
const char* password = "TU_PASSWORD_WIFI";

// Configuración ThingsBoard
const char* mqtt_server = "192.168.4.177";
const int mqtt_port = 1883;
const char* mqtt_token = "ARDUINO_CODE
echo -e "${CYAN}${DEVICE_TOKEN}${NC}"
cat << 'ARDUINO_CODE2'
";

// Pines GPIO
#define DHT_PIN 4
#define SOUND_PIN 34
#define LED_PIN 2

#define DHT_TYPE DHT11
DHT dht(DHT_PIN, DHT_TYPE);

WiFiClient espClient;
PubSubClient client(espClient);

void setup() {
    Serial.begin(115200);
    pinMode(LED_PIN, OUTPUT);
    
    // Conectar WiFi
    WiFi.begin(ssid, password);
    while (WiFi.status() != WL_CONNECTED) {
        delay(500);
        Serial.print(".");
    }
    Serial.println("WiFi conectado!");
    
    // Conectar MQTT
    client.setServer(mqtt_server, mqtt_port);
    client.setCallback(callback);
    
    // Inicializar DHT
    dht.begin();
}

void loop() {
    if (!client.connected()) {
        reconnect();
    }
    client.loop();
    
    // Leer sensores
    delay(2000); // DHT necesita al menos 2 segundos entre lecturas
    
    float temperature = dht.readTemperature();
    float humidity = dht.readHumidity();
    int soundLevel = analogRead(SOUND_PIN);
    
    if (!isnan(temperature) && !isnan(humidity)) {
        // Publicar a ThingsBoard
        String payload = "{\"temperature\":" + String(temperature) +
                        ",\"humidity\":" + String(humidity) +
                        ",\"soundLevel\":" + String(soundLevel) + "}";
        
        client.publish("v1/devices/me/telemetry", payload.c_str());
        
        Serial.print("Enviado: ");
        Serial.println(payload);
    }
    
    delay(5000); // Enviar cada 5 segundos
}

void reconnect() {
    while (!client.connected()) {
        Serial.print("Intentando conectar MQTT...");
        
        if (client.connect("ESP32Client", mqtt_token, "")) {
            Serial.println("conectado");
        } else {
            Serial.print("error: ");
            Serial.println(client.state());
            delay(5000);
        }
    }
}

void callback(char* topic, byte* message, unsigned int length) {
    Serial.print("Mensaje recibido [");
    Serial.print(topic);
    Serial.print("]: ");
    
    String messageTemp;
    for (int i = 0; i < length; i++) {
        messageTemp += (char)message[i];
    }
    Serial.println(messageTemp);
    
    // Controlar LED desde ThingsBoard
    if (String(topic) == "v1/devices/me/rpc/request/+") {
        if (messageTemp.indexOf("ledOn") > 0) {
            digitalWrite(LED_PIN, HIGH);
        } else if (messageTemp.indexOf("ledOff") > 0) {
            digitalWrite(LED_PIN, LOW);
        }
    }
}
ARDUINO_CODE2

    echo ""
    echo -e "${GREEN}Próximos pasos:${NC}"
    echo "  1. Copia el Access Token: ${DEVICE_TOKEN}"
    echo "  2. Actualiza tu código del ESP32 con el token"
    echo "  3. Carga el programa en tu ESP32"
    echo "  4. Verifica en ThingsBoard que los datos lleguen en tiempo real"
}

# Paso 7: Verificación Final
verify_connection() {
    print_header "PASO 7: Verificar Conexión"
    
    echo -e "${YELLOW}Esperando datos del ESP32...${NC}"
    echo "  (Esta verificación tardará ~30 segundos)"
    echo ""
    
    # Esperar a que el ESP32 envíe datos
    for i in {1..30}; do
        TELEMETRY=$(curl -s \
            "${TB_URL}/api/plugins/telemetry/DEVICE/${DEVICE_ID}/values/timeseries?keys=temperature,humidity,soundLevel&limit=1" \
            -H "X-Authorization: Bearer ${TOKEN}" \
            -H "Content-Type: application/json")
        
        if echo "$TELEMETRY" | grep -q "temperature"; then
            print_success "Datos recibidos del ESP32:"
            echo "$TELEMETRY" | grep -oP '"(temperature|humidity|soundLevel)":\K[^,}]*'
            return 0
        fi
        
        echo -n "."
        sleep 1
    done
    
    print_info "Aún no se reciben datos. Verifica:"
    echo "  - El ESP32 está conectado por WiFi"
    echo "  - ThingsBoard está accesible desde la red"
    echo "  - El Token está configurado correctamente"
}

# MAIN
main() {
    print_header "🔌 REGISTRADOR INTERACTIVO DE ESP32 EN THINGSBOARD"
    
    echo -e "${YELLOW}Este script te ayudará a registrar tu ESP32 en ThingsBoard${NC}"
    echo ""
    
    # Leer credenciales
    read_credentials
    
    # Obtener token de login
    get_login_token
    print_success "Login exitoso"
    
    # Ejecutar pasos
    create_tenant
    create_device
    get_device_token
    create_device_attributes
    create_rule
    show_final_config
    verify_connection
    
    print_header "✅ REGISTRO COMPLETADO"
    echo ""
    echo -e "${GREEN}Tu ESP32 está registrado en ThingsBoard${NC}"
    echo -e "${GREEN}Accede a: ${CYAN}${TB_URL}${GREEN} para ver los datos en tiempo real${NC}"
    echo ""
}

main "$@"

# 🚀 Guía Completa: Desplegar ThingsBoard en Raspberry y Conectar ESP32 + getmarket-iot

**📅 Fecha**: Febrero 2026  
**🎯 Objetivo**: Tener ThingsBoard corriendo en la Raspberry con ESP32 registrado y getmarket-iot conectado

---

## 📋 Índice

1. [Desplegar ThingsBoard en Raspberry](#desplegar-thingsboard-en-raspberry)
2. [Registrar ESP32 en ThingsBoard](#registrar-esp32-en-thingsboard)
3. [Configurar getmarket-iot](#configurar-getmarket-iot)
4. [Verificar Conectividad](#verificar-conectividad)
5. [Troubleshooting](#troubleshooting)

---

## 🐳 Desplegar ThingsBoard en Raspberry

### Requisitos Previos

```bash
✅ SSH accesible a Raspberry: innvoid@192.168.4.177
✅ Docker corriendo en Raspberry
✅ Docker Compose V2+
✅ Espacio libre: ~20GB
```

### Paso 1: Compilar Imagen de ThingsBoard (en tu Mac)

```bash
cd /Users/pedrovalenzuela/Documents/Innvoid/Desarrollo/thingsboard

# Compilar (esto toma ~10-15 minutos)
export MAVEN_OPTS="-Xmx1024m"
mvn clean install -DskipTests -T2

# Verificar que el build fue exitoso
ls -la application/target/thingsboard*.jar
```

### Paso 2: Ejecutar Script de Despliegue

```bash
cd docker

# Hacer ejecutable el script
chmod +x deploy-thingsboard-raspberry.sh

# Ejecutar despliegue
./deploy-thingsboard-raspberry.sh
```

El script hará:
- ✅ Verificar conectividad con Raspberry
- ✅ Crear estructura de directorios
- ✅ Copiar archivos de configuración
- ✅ Hacer backup de versión anterior
- ✅ Levantar contenedores con docker-compose
- ✅ Verificar estado de servicios
- ✅ Mostrar información de acceso

### Paso 3: Verificar que ThingsBoard Está Corriendo

```bash
# Ver estado de contenedores en Raspberry
ssh innvoid@192.168.4.177 "cd ~/docker-projects/thingsboard/docker && docker compose ps"

# Ver logs de ThingsBoard
ssh innvoid@192.168.4.177 "cd ~/docker-projects/thingsboard/docker && docker compose logs -f tb-core1"

# Test de conectividad desde tu Mac
curl http://192.168.4.177:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"sysadmin@thingsboard.org","password":"sysadmin"}'
```

**Salida esperada**:
```json
{"token":"eyJhbGc...","refreshToken":"eyJhbGc..."}
```

### Paso 4: Acceder a ThingsBoard Web

Abre en tu navegador:
```
http://192.168.4.177:8080
```

**Credenciales por defecto**:
- 👤 Usuario: `sysadmin@thingsboard.org`
- 🔐 Contraseña: `sysadmin`

---

## 📱 Registrar ESP32 en ThingsBoard

### Opción A: Usar Script Interactivo (RECOMENDADO)

```bash
cd /Users/pedrovalenzuela/Documents/Innvoid/Desarrollo/thingsboard/docker

# Hacer ejecutable
chmod +x register-esp32.sh

# Ejecutar script
./register-esp32.sh
```

El script te pedirá:
1. URL de ThingsBoard (ej: `http://192.168.4.177:8080`)
2. Usuario de login (ej: `sysadmin@thingsboard.org`)
3. Contraseña

Luego creará automáticamente:
- ✅ Dispositivo "ESP32_IoT_Sensors"
- ✅ Access Token para MQTT
- ✅ Atributos del dispositivo
- ✅ Código Arduino ejemplo

### Opción B: Manual (Interfaz Web)

#### 1. Crear Dispositivo

```
1. Login en ThingsBoard (http://192.168.4.177:8080)
2. Menú izquierdo → Devices
3. Botón "+ Create new device"
4. Llenar:
   - Name: ESP32_IoT_Sensors
   - Type: default
   - Label: ESP32 con Sensores
5. Click "Create"
```

#### 2. Obtener Access Token

```
1. Abrir el dispositivo "ESP32_IoT_Sensors"
2. Pestaña "Credentials"
3. Copiar el "Access Token"
   Ejemplo: dGVzdF9kZXZpY2U=
```

#### 3. Añadir Atributos (Opcional)

```
1. Pestaña "Attributes"
2. Crear atributos compartidos:
   - model: ESP32-WROOM-32
   - manufacturer: Espressif Systems
   - serialNumber: ESP32-001
```

### Paso 3: Configurar Código ESP32

```cpp
#include <WiFi.h>
#include <PubSubClient.h>
#include "DHT.h"

// ========== CONFIGURACIÓN WIFI ==========
const char* ssid = "HOP85";
const char* password = "TU_PASSWORD_WIFI";

// ========== CONFIGURACIÓN THINGSBOARD ==========
const char* mqtt_broker = "192.168.4.177";
const int mqtt_port = 1883;
const char* mqtt_token = "XXXXXX_ACCESO_TOKEN_AQUI_XXXXXX";  // Copiar del paso anterior

// ========== PINES GPIO ==========
#define DHT_PIN 4           // Temperatura/Humedad
#define SOUND_PIN 34        // Sensor de sonido (ADC)
#define LED_PIN 2           // LED de estado

#define DHT_TYPE DHT11
DHT dht(DHT_PIN, DHT_TYPE);

WiFiClient espClient;
PubSubClient client(espClient);

void setup() {
    Serial.begin(115200);
    delay(100);
    
    pinMode(LED_PIN, OUTPUT);
    dht.begin();
    
    // Conectar WiFi
    Serial.print("Conectando a WiFi: ");
    Serial.println(ssid);
    
    WiFi.begin(ssid, password);
    int attempts = 0;
    while (WiFi.status() != WL_CONNECTED && attempts < 20) {
        delay(500);
        Serial.print(".");
        attempts++;
    }
    
    Serial.println();
    Serial.print("WiFi conectado: ");
    Serial.println(WiFi.localIP());
    
    // Configurar MQTT
    client.setServer(mqtt_broker, mqtt_port);
    client.setCallback(mqtt_callback);
    
    // Conectar MQTT
    reconnect_mqtt();
}

void loop() {
    if (!client.connected()) {
        reconnect_mqtt();
    }
    client.loop();
    
    // Leer sensores cada 5 segundos
    if (millis() % 5000 == 0) {
        read_and_publish_sensors();
    }
}

void reconnect_mqtt() {
    int attempts = 0;
    while (!client.connected() && attempts < 3) {
        Serial.print("Conectando a MQTT...");
        
        String client_id = "ESP32-" + String(ESP.getChipId());
        
        if (client.connect(client_id.c_str(), mqtt_token, "")) {
            Serial.println(" conectado!");
            
            // Suscribirse a comandos RPC
            client.subscribe("v1/devices/me/rpc/request/+");
            
        } else {
            Serial.print(" error: ");
            Serial.println(client.state());
            delay(2000);
            attempts++;
        }
    }
}

void read_and_publish_sensors() {
    // Leer DHT
    float temperature = dht.readTemperature();
    float humidity = dht.readHumidity();
    
    // Leer sensor de sonido
    int soundLevel = analogRead(SOUND_PIN);
    
    // Ignorar lecturas error
    if (isnan(temperature) || isnan(humidity)) {
        Serial.println("Error leyendo DHT");
        return;
    }
    
    // Crear JSON
    String payload = "{";
    payload += "\"temperature\":" + String(temperature) + ",";
    payload += "\"humidity\":" + String(humidity) + ",";
    payload += "\"soundLevel\":" + String(soundLevel) + ",";
    payload += "\"timestamp\":" + String(millis());
    payload += "}";
    
    // Publicar a ThingsBoard
    bool success = client.publish("v1/devices/me/telemetry", payload.c_str());
    
    Serial.print("Telemetría enviada: ");
    Serial.println(success ? "✓" : "✗");
    Serial.print("Temp: ");
    Serial.print(temperature);
    Serial.print("C, Hum: ");
    Serial.print(humidity);
    Serial.print("%, Sonido: ");
    Serial.println(soundLevel);
}

void mqtt_callback(char* topic, byte* payload, unsigned int length) {
    // Procesar comandos RPC desde ThingsBoard
    String message = "";
    for (int i = 0; i < length; i++) {
        message += (char)payload[i];
    }
    
    Serial.print("RPC recibido: ");
    Serial.println(message);
    
    // Ejemplo: Controlar LED
    if (message.indexOf("\"method\":\"setLED\"") >= 0) {
        if (message.indexOf("\"value\":true") >= 0) {
            digitalWrite(LED_PIN, HIGH);
            Serial.println("LED ON");
        } else {
            digitalWrite(LED_PIN, LOW);
            Serial.println("LED OFF");
        }
    }
}
```

### Paso 4: Cargar en ESP32

```bash
# Usar Arduino IDE o platformio
# Configuración:
# - Board: ESP32 Dev Module
# - Port: /dev/cu.usbserial-XXXXX
# - Upload speed: 921600
# - CPU Frequency: 240 MHz
```

### Paso 5: Verificar Datos en ThingsBoard

```
1. Abre ThingsBoard: http://192.168.4.177:8080
2. Menú Devices → ESP32_IoT_Sensors
3. Pestaña "Latest Telemetry"
4. Deberías ver:
   ✓ temperature
   ✓ humidity
   ✓ soundLevel
   ✓ timestamp
```

---

## ⚙️ Configurar getmarket-iot

### Arquitectura de Conexión

```
┌─────────────────────────────────────────────────────┐
│                    Tu Mac / Raspberry                │
│                                                      │
│  ┌──────────────────┐         ┌─────────────────┐  │
│  │  getmarket-iot   │────────>│  ThingsBoard    │  │
│  │  (Node.js k3s)   │   REST  │  (Docker)       │  │
│  └──────────────────┘  API    └─────────────────┘  │
│                        Port:8080                    │
│                                                      │
│  ┌──────────────────┐         ┌─────────────────┐  │
│  │     ESP32        │────────>│  ThingsBoard    │  │
│  │ (WiFi ↔ MQTT)    │  MQTT   │  (Docker)       │  │
│  └──────────────────┘  Port:1883                   │
│                        Token:xxxxx                 │
└─────────────────────────────────────────────────────┘
```

### Paso 1: Obtener Credenciales ThingsBoard Tenant

```bash
# Ejecutar login en ThingsBoard como tenant
curl -X POST "http://192.168.4.177:8080/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "tenant@thingsboard.org",
    "password": "tenant"
  }'

# Guardar el token de respuesta: {"token": "eyJhbGc..."}
```

### Paso 2: Actualizar Configuración en getmarket-iot

#### Opción A: Usando ConfigMap en k3s

```bash
# Desde tu Mac, dentro del namespace de k3s

kubectl edit configmap getmarket-iot-config

# Agregar o actualizar:
apiVersion: v1
kind: ConfigMap
metadata:
  name: getmarket-iot-config
  namespace: thingsboard
data:
  # ThingsBoard connection
  THINGSBOARD_HOST: "192.168.4.177"
  THINGSBOARD_PORT: "8080"
  THINGSBOARD_USERNAME: "tenant@thingsboard.org"
  THINGSBOARD_PASSWORD: "tenant"
  THINGSBOARD_PROTOCOL: "http"
  
  # Opcional: Token persistente
  THINGSBOARD_TOKEN: "eyJhbGc..."
  
  # Endpoints de la API
  THINGSBOARD_DEVICES_ENDPOINT: "/api/tenant/devices"
  THINGSBOARD_TELEMETRY_ENDPOINT: "/api/plugins/telemetry"
  
  # Intervalo de sincronización
  SYNC_INTERVAL_SECONDS: "300"  # Cada 5 minutos
  
  # Variables de aplicación
  NODE_ENV: "production"
  PORT: "3000"
```

#### Opción B: Usando archivos .env (Desarrollo Local)

```bash
# En getmarket-iot/.env

# ThingsBoard Configuration
THINGSBOARD_HOST=192.168.4.177
THINGSBOARD_PORT=8080
THINGSBOARD_PROTOCOL=http
THINGSBOARD_USERNAME=tenant@thingsboard.org
THINGSBOARD_PASSWORD=tenant
THINGSBOARD_TOKEN=

# Application
NODE_ENV=development
PORT=3000

# Sync
SYNC_INTERVAL_SECONDS=300
LOG_LEVEL=debug
```

### Paso 3: Implementar ThingsBoardService en getmarket-iot

Usa el ejemplo de código en el documento adjunto: `THINGSBOARD_INTEGRATION.md`

```bash
# Crear archivo src/services/ThingsBoardService.ts
# Ver documento adjunto para el código completo
```

### Paso 4: Crear Endpoints para Exponer Datos

```typescript
// src/routes/devices.ts

import express from 'express';
import { ThingsBoardService } from '../services/ThingsBoardService';

const router = express.Router();

const tbService = new ThingsBoardService({
    host: process.env.THINGSBOARD_HOST!,
    port: process.env.THINGSBOARD_PORT!,
    username: process.env.THINGSBOARD_USERNAME!,
    password: process.env.THINGSBOARD_PASSWORD!,
});

// Obtener lista de dispositivos
router.get('/devices', async (req, res) => {
    try {
        const devices = await tbService.getDevices();
        res.json(devices);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Obtener datos de un dispositivo
router.get('/devices/:id/telemetry', async (req, res) => {
    try {
        const { id } = req.params;
        const { keys = 'temperature,humidity,soundLevel' } = req.query;
        
        const telemetry = await tbService.getDeviceTelemetry(
            id,
            String(keys).split(',')
        );
        
        res.json(telemetry);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Health check
router.get('/health', async (req, res) => {
    try {
        await tbService.authenticate();
        res.json({ status: 'connected', thingsboard: 'online' });
    } catch (error) {
        res.status(503).json({ 
            status: 'disconnected', 
            thingsboard: 'offline',
            error: error.message 
        });
    }
});

export default router;
```

### Paso 5: Desplegar en k3s

```bash
cd getmarket-iot

# Construir imagen
docker build -t getmarket-iot:latest .

# Copiar a Raspberry (si lo deseas)
docker save getmarket-iot:latest | gzip > getmarket-iot.tar.gz
scp getmarket-iot.tar.gz innvoid@192.168.4.177:~

# En Raspberry, cargar imagen
ssh innvoid@192.168.4.177 "gunzip -c getmarket-iot.tar.gz | sudo k3s ctr images import -"

# Desplegar con kubectl
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/secret.yaml
kubectl apply -f k8s/deployment.yaml
```

---

## ✅ Verificar Conectividad

### Test 1: ThingsBoard Accesible

```bash
curl -v http://192.168.4.177:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"sysadmin@thingsboard.org","password":"sysadmin"}'
```

**Resultado esperado**: `HTTP/1.1 200 OK` con token JWT

### Test 2: MQTT Accesible

```bash
# Instalar cliente MQTT
brew install mosquitto

# Test de connectivity
mosquitto_sub -h 192.168.4.177 -p 1883 -t "v1/devices/me/telemetry" -u "dGVzdF9kZXZpY2U=" &

# Publicar mensaje de prueba
mosquitto_pub -h 192.168.4.177 -p 1883 -t "v1/devices/me/telemetry" \
  -u "dGVzdF9kZXZpY2U=" \
  -m '{"test":1}'
```

### Test 3: getmarket-iot Health Check

```bash
# Si está en k3s
kubectl port-forward deployment/getmarket-iot 3000:3000

# En otra terminal
curl http://localhost:3000/health/thingsboard
```

**Resultado esperado**:
```json
{
  "status": "healthy",
  "thingsboard": "connected"
}
```

### Test 4: Datos Llegando al ESP32

```bash
# Ver dashboard de ThingsBoard
# http://192.168.4.177:8080 → Devices → ESP32_IoT_Sensors → Latest Telemetry
```

---

## 🔧 Troubleshooting

### Problema: ThingsBoard no inicia

```bash
# Ver logs
ssh innvoid@192.168.4.177 "cd ~/docker-projects/thingsboard/docker && docker compose logs tb-core1 --tail 50"

# Ver si está por espacio en disco
ssh innvoid@192.168.4.177 "df -h"

# Reiniciar servicios
ssh innvoid@192.168.4.177 "cd ~/docker-projects/thingsboard/docker && docker compose restart"
```

### Problema: ESP32 no envía datos

```bash
# Ver monitor serial del ESP32 en Arduino IDE
# Verificar:
- ✓ SSID y password WiFi correctos
- ✓ Access Token correcto
- ✓ IP de ThingsBoard accesible (ping 192.168.4.177)
- ✓ Puerto MQTT 1883 abierto
```

### Problema: getmarket-iot no conecta con ThingsBoard

```bash
# Test desde pod de k3s
kubectl exec -it deployment/getmarket-iot -- sh

# Dentro del pod
curl http://192.168.4.177:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"tenant@thingsboard.org","password":"tenant"}'

# Verificar resolución DNS
nslookup 192.168.4.177
```

### Problema: Credenciales incorrectas

```bash
# El usuario tenant@ no existe por defecto
# Crear nuevo tenant:
1. Login como sysadmin
2. Ir a Tenants → Create new tenant
3. Crear admin user para el tenant
4. Usar esas credenciales en configmap
```

---

## 📊 Monitor la Integración

### Dashboard en ThingsBoard

```
1. Ir a http://192.168.4.177:8080
2. Crear Dashboard "IoT System"
3. Agregar widgets:
   - Latest Telemetry: temperatura, humedad
   - Timeseries Card: valores históricos
   - LED Control: usar RPC para controlar LED del ESP32
```

### Logs de getmarket-iot

```bash
# Ver logs en tiempo real
kubectl logs -f deployment/getmarket-iot

# O en Docker
ssh innvoid@192.168.4.177 "docker logs -f thingsboard-ce-getmarket-iot-1"
```

---

## 🎉 ¡Listo!

Tu sistema está completo con:
- ✅ **ThingsBoard** corriendo en Raspberry
- ✅ **ESP32** enviando datos por MQTT
- ✅ **getmarket-iot** accediendo a los datos via API REST

¡Puedes monitorear en tiempo real y crear reglas personalizadas!

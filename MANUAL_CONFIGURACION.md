# Manual de Configuración de ThingsBoard

**Versión:** 4.4.0  
**Última actualización:** Enero 2026

---

## Índice

1. [Introducción](#introducción)
2. [Arquitectura de ThingsBoard](#arquitectura-de-thingsboard)
3. [Configuración Inicial](#configuración-inicial)
4. [Conectar Microservicios](#conectar-microservicios)
5. [Configurar Sensores](#configurar-sensores)
6. [Interfaz de Navegador](#interfaz-de-navegador)
7. [Docker Compose - Configuración y Deployment](#docker-compose---configuración-y-deployment)
8. [Troubleshooting](#troubleshooting)
9. [Recursos Adicionales](#recursos-adicionales)

---

## Introducción

ThingsBoard es una plataforma IoT de código abierto que permite:

- **Provisión y gestión** de dispositivos
- **Recolección de datos** en tiempo real
- **Visualización** mediante dashboards
- **Procesamiento** con Rule Engine
- **Notificaciones y alertas**

### Características principales

- 🔗 Múltiples protocolos de transporte (MQTT, HTTP, CoAP, LWM2M, SNMP)
- 📊 Dashboards en tiempo real
- 🔧 Rule Engine para procesamiento de datos
- 🏢 Arquitectura de microservicios
- 🐳 Deployment con Docker Compose
- 💾 Soporte para PostgreSQL, Cassandra
- 🗄️ Caché con Valkey/Redis

---

## Arquitectura de ThingsBoard

### Componentes principales

```
┌─────────────────────────────────────────────────────────────┐
│                     Web UI (UI-NGX)                          │
│              (Interfaz web en navegador)                     │
└────────────────────────┬────────────────────────────────────┘
                         │
┌─────────────────────────┴────────────────────────────────────┐
│                    Load Balancer (HAProxy)                   │
└──────┬─────────────────────────────────────────────┬─────────┘
       │                                             │
   ┌───┴─────────────────────┬───────┬─────────┐   │
   │                         │       │         │   │
   ▼                         ▼       ▼         ▼   │
┌────────────┐  ┌────────┐ ┌──────┐ ┌──────┐  │   │
│ TB-Core    │  │TB-Rule │ │JS    │ │VC    │  │   │
│ (Business  │  │Engine  │ │Execut│ │Execut│  │   │
│ Logic)     │  │        │ │or    │ │or    │  │   │
└────────────┘  └────────┘ └──────┘ └──────┘  │   │
                                              │   │
   ┌──────────┬──────────┬──────────┐         │   │
   │          │          │          │         │   │
   ▼          ▼          ▼          ▼         │   │
┌──────────┐┌──────────┐┌──────────┐┌──────┐  │   │
│ MQTT     ││ HTTP     ││ CoAP     ││ LWM2M│◄─┘   │
│Transport ││Transport ││Transport ││Transp│◄─────┘
└──────────┘└──────────┘└──────────┘└──────┘
   │          │          │          │
   └──────────┴──────────┴──────────┘
              │
┌─────────────┴────────────────────────────┐
│                                          │
│  ┌──────────┐  ┌───────────┐  ┌──────┐  │
│  │PostgreSQL│  │  Cassandra│  │Valkey│  │
│  │(Entities)│  │(Timeseries)  │(Cache)│  │
│  └──────────┘  └───────────┘  └──────┘  │
│                                          │
│  Database Layer & Message Queue (Kafka) │
└──────────────────────────────────────────┘
```

### Microservicios disponibles

| Servicio | Propósito |
|----------|-----------|
| **tb-core** | Lógica de negocio, API REST, gestión de dispositivos |
| **tb-rule-engine** | Procesamiento de datos mediante rule chains |
| **tb-mqtt-transport** | Transporte MQTT para dispositivos |
| **tb-http-transport** | Transporte HTTP para dispositivos |
| **tb-coap-transport** | Transporte CoAP (Constrained Application Protocol) |
| **tb-lwm2m-transport** | Transporte LWM2M (Lightweight M2M) |
| **tb-js-executor** | Ejecución de scripts JavaScript |
| **tb-vc-executor** | Version Control de configuraciones |
| **tb-web-ui** | Interfaz web de usuario |
| **haproxy** | Load Balancer |

---

## Configuración Inicial

### Requisitos previos

- **Docker**: v20.10+
- **Docker Compose**: v2.0+
- **Sistema Operativo**: Linux, macOS o Windows (con WSL2)
- **Espacio en disco**: Mínimo 20GB
- **RAM disponible**: Mínimo 8GB

### Paso 1: Clonar o acceder al repositorio

```bash
# Si aún no tienes el repositorio
git clone https://github.com/thingsboard/thingsboard.git
cd thingsboard

# Si ya lo tienes
cd /Users/pedrovalenzuela/Documents/Innvoid/Desarrollo/thingsboard
```

### Paso 2: Configurar variables de entorno

Navega a la carpeta de Docker y revisa el archivo `.env`:

```bash
cd docker
cat .env
```

**Archivo: `docker/.env`**

```dotenv
# Tipo de cola de mensajes
TB_QUEUE_TYPE=kafka

# Tipo de caché (valkey, valkey-cluster o valkey-sentinel)
CACHE=valkey

# Tipo de base de datos (postgres o hybrid)
DATABASE=postgres

# Versión de ThingsBoard
TB_VERSION=latest

# Load Balancer
LOAD_BALANCER_NAME=haproxy-certbot

# Monitoreo (prometheus + grafana)
MONITORING_ENABLED=false

# Opciones de memoria para Java (descomenta si necesitas ajustar)
# JAVA_OPTS=-Xmx2048M -Xms2048M -Xss384k -XX:+AlwaysPreTouch
```

### Paso 3: Crear carpetas de logs (con permisos)

```bash
cd docker
./docker-create-log-folders.sh
```

Este script:
- Crea directorios para logs de cada servicio
- Establece permisos correctos
- Puede requerir contraseña de `sudo`

---

## Conectar Microservicios

### 1. Configuración de comunicación entre servicios

ThingsBoard usa **Kafka** como sistema de colas de mensajes para la comunicación entre microservicios.

**Archivo: `docker/.env`**

```dotenv
# Tipo de cola (kafka o rabbitMQ)
TB_QUEUE_TYPE=kafka
```

**Archivo: `docker/kafka.env`**

```dotenv
KAFKA_BROKER_HOST=kafka
KAFKA_BROKER_PORT=9092
```

### 2. Servicios base de datos y caché

#### PostgreSQL (Base de datos)

**Archivo: `docker/docker-compose.postgres.yml`**

```yaml
services:
  postgres:
    image: postgres:15-alpine
    env_file: tb-node.postgres.env
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
```

#### Valkey/Redis (Caché)

**Archivo: `docker/docker-compose.valkey.yml`**

```yaml
services:
  valkey:
    image: valkey/valkey:latest
    ports:
      - "6379:6379"
    volumes:
      - valkey_data:/data
```

### 3. Comunicación con servicios externos

Para integrar con un microservicio externo:

#### A. Mediante Rule Engine (Recomendado)

1. **Crear una Rule Chain** en ThingsBoard
2. **Usar nodo "External Service Call"** o **"REST API Call"**
3. Configurar URL del servicio: `http://your-service:port/endpoint`

Ejemplo de configuración en Rule Engine:

```json
{
  "type": "org.thingsboard.rule.engine.action.TbHttpActionNode",
  "configuration": {
    "requestMethod": "POST",
    "url": "http://external-service:8080/api/data",
    "headers": {
      "Content-Type": "application/json"
    },
    "useSimpleClientHttpFactory": false,
    "readTimeoutMs": 10000,
    "maxParallelRequestsCount": 10
  }
}
```

#### B. Mediante REST API

Usar la **API REST de ThingsBoard** para enviar/recibir datos:

```bash
# Obtener token de acceso
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"sysadmin@thingsboard.org","password":"sysadmin"}'

# Enviar datos de telemetría (Ejemplo: sensor de temperatura)
curl -X POST http://localhost:8080/api/v1/devices/{deviceId}/telemetry \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "temperature": 25.5,
    "humidity": 60,
    "timestamp": 1234567890000
  }'
```

#### C. Mediante MQTT

Protocolo ligero ideal para dispositivos IoT:

```bash
# Instalar cliente MQTT
brew install mosquitto

# Publicar datos de temperatura
mosquitto_pub -h localhost -t v1/devices/{deviceId}/telemetry -m '{
  "temperature": 25.5,
  "humidity": 60
}'

# Suscribirse a comandos del dispositivo
mosquitto_sub -h localhost -t v1/devices/{deviceId}/rpc/request/+
```

### 4. Variables de configuración de microservicios

**Archivo: `docker/tb-node.env`**

```dotenv
# Puerto de ThingsBoard
TB_PORT=8080
TB_BIND_ADDRESS=0.0.0.0

# Base de datos
SPRING_DATASOURCE_URL=jdbc:postgresql://postgres:5432/thingsboard
SPRING_DATASOURCE_USERNAME=postgres
SPRING_DATASOURCE_PASSWORD=postgres
SPRING_DATASOURCE_HIKARI_MAXIMUM_POOL_SIZE=16

# Cache (Valkey/Redis)
CACHE_TYPE=redis
REDIS_ADDRESSES=valkey:6379

# Queue (Kafka)
TB_QUEUE_TYPE=kafka
TB_QUEUE_KAFKA_SERVERS=kafka:9092

# Rule Engine
TB_RULE_ENGINE_CORE_POOL_SIZE=1
TB_RULE_ENGINE_THREAD_POOL_SIZE=4

# Clusters
TB_SERVICE_ID=tb-core1
TB_SERVICE_TYPE=tb-core
```

---

## Configurar Sensores

### 1. Acceder a la consola de administración

1. **Inicia los servicios**:
   ```bash
   cd docker
   ./docker-start-services.sh
   ```

2. **Abre el navegador** en `http://localhost`

3. **Inicia sesión** con:
   - Usuario: `sysadmin@thingsboard.org`
   - Contraseña: `sysadmin`

### 2. Crear un dispositivo

#### Opción A: Desde la interfaz web

1. **Menú izquierdo** → **Devices**
2. Haz clic en **+ Create device**
3. Rellena los datos:
   - **Name**: `Mi Sensor de Temperatura`
   - **Device Profile**: `default` (o crea uno personalizado)
   - **Type**: `default`
4. **Create** → Se genera automáticamente un **Device ID** y **Access Token**

#### Opción B: Usando API REST

```bash
# Obtener token
TOKEN=$(curl -s -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"sysadmin@thingsboard.org","password":"sysadmin"}' \
  | jq -r '.token')

# Crear dispositivo
curl -X POST http://localhost:8080/api/device \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "name": "Mi Sensor de Temperatura",
    "type": "default"
  }'
```

### 3. Obtener credenciales del dispositivo

Después de crear el dispositivo:

1. **Haz clic en el dispositivo** en la lista
2. **Pestaña "Credentials"**
3. Copia el **Access Token** (ej: `dGVzdF9kZXZpY2VfdG9rZW4=`)

### 4. Enviar datos desde sensores

#### A. Mediante MQTT (Recomendado para sensores)

```bash
# Terminal 1: Suscribirse a datos
mosquitto_sub -h localhost -p 1883 \
  -t "v1/devices/me/telemetry" \
  -u "sysadmin@thingsboard.org" \
  -P "sysadmin"

# Terminal 2: Publicar datos (reemplaza TOKEN con tu Access Token)
mosquitto_pub -h localhost -p 1883 \
  -t "v1/devices/me/telemetry" \
  -u "DEVICE_ACCESS_TOKEN" \
  -d '{
    "temperature": 22.5,
    "humidity": 65,
    "pressure": 1013,
    "timestamp": '$(date +%s000)'
  }'
```

#### B. Mediante HTTP

```bash
# Script Python para enviar datos periódicamente
cat > send_sensor_data.py << 'EOF'
import requests
import json
import time

# Configuración
THINGSBOARD_URL = "http://localhost:8080"
DEVICE_ACCESS_TOKEN = "your_device_access_token"

while True:
    # Simular lectura de sensor
    data = {
        "temperature": 22.5 + (import random; random.uniform(-2, 2)),
        "humidity": 65,
        "timestamp": int(time.time() * 1000)
    }
    
    # Enviar a ThingsBoard
    response = requests.post(
        f"{THINGSBOARD_URL}/api/v1/{DEVICE_ACCESS_TOKEN}/telemetry",
        json=data,
        headers={"Content-Type": "application/json"}
    )
    
    print(f"Datos enviados: {data}")
    print(f"Status: {response.status_code}\n")
    
    time.sleep(5)  # Esperar 5 segundos
EOF

python3 send_sensor_data.py
```

#### C. Mediante HTTP (cURL)

```bash
#!/bin/bash
# Script para enviar datos

DEVICE_TOKEN="your_access_token"
THINGSBOARD_URL="http://localhost:8080"

while true; do
  TEMP=$(echo "20 + $RANDOM % 10" | bc -l)
  HUMIDITY=$(echo "50 + $RANDOM % 30" | bc -l)
  TIMESTAMP=$(date +%s000)
  
  curl -X POST "$THINGSBOARD_URL/api/v1/$DEVICE_TOKEN/telemetry" \
    -H "Content-Type: application/json" \
    -d "{
      \"temperature\": $TEMP,
      \"humidity\": $HUMIDITY,
      \"timestamp\": $TIMESTAMP
    }"
  
  sleep 5
done
```

### 5. Configurar perfil de dispositivo (Device Profile)

Para definir qué datos envía tu sensor:

1. **Menú** → **Device Profiles**
2. **+ Create device profile**
3. **Rellena**:
   - **Name**: `Sensor de Temperatura y Humedad`
   - **Device Type**: `default`
4. **Telemetry Configuration**:
   - Añade campos: `temperature`, `humidity`, `pressure`
   - Define tipos: `Double`, `Integer`, etc.

```json
{
  "name": "Sensor de Temperatura y Humedad",
  "type": "DEFAULT",
  "transportType": "DEFAULT",
  "telemetryConfiguration": {
    "telemetryKeys": [
      {
        "key": "temperature",
        "type": "DOUBLE"
      },
      {
        "key": "humidity",
        "type": "INTEGER"
      },
      {
        "key": "pressure",
        "type": "DOUBLE"
      }
    ]
  }
}
```

---

## Interfaz de Navegador

### 1. Acceso a ThingsBoard

**URL**: `http://localhost` (si está detrás de HAProxy)  
o  
**URL**: `http://localhost:8080` (acceso directo a TB-Core)

### 2. Estructura de la interfaz

```
┌─────────────────────────────────────────────────────────┐
│                   THINGSBOARD UI                        │
├─────────────┬───────────────────────────────────────────┤
│   MENU      │          CONTENIDO PRINCIPAL              │
│             │                                           │
│ Dashboard   │  Visualización de datos en tiempo real    │
│ Devices     │  Lista de dispositivos                    │
│ Assets      │  Gestión de activos                       │
│ Rules       │  Configuración de reglas (Rule Engine)    │
│ Alarms      │  Alertas y alarmas                        │
│ Admin       │  Configuración del sistema                │
│             │                                           │
└─────────────┴───────────────────────────────────────────┘
```

### 3. Crear un Dashboard

#### Paso 1: Crear nuevo dashboard

1. **Menú izquierdo** → **Dashboards**
2. **+ Create dashboard**
3. Dale un nombre: `Mi Panel de Control`

#### Paso 2: Añadir widgets

1. **Edit** (arriba a la derecha)
2. **+ Add widget**
3. Selecciona tipo de widget:
   - **Gauge**: Indicador de valor único
   - **Chart**: Gráfico de líneas/barras
   - **Digital**: Valor numérico
   - **Maps**: Ubicación en mapa
   - **Table**: Tabla de datos
   - **Thermometer**: Termómetro
   - **Alarm Table**: Tabla de alarmas

#### Paso 3: Configurar widget

Ejemplo: **Gauge para temperatura**

```
1. Selecciona el widget "Gauge"
2. Datos:
   - Device: "Mi Sensor de Temperatura"
   - Data key: "temperature"
   - Min: 0
   - Max: 50
   - Rango verde: 15-25°C
   - Rango amarillo: 25-35°C
   - Rango rojo: 35-50°C
3. Guardar
```

### 4. Configurar Rule Engine para reaccionar a datos

#### Crear una alarma cuando la temperatura exceda 30°C

1. **Menú** → **Rules** (en la sección Administration)
2. **+ Create new rule**
3. **Nombre**: `Alarma Temperatura Alta`
4. **Configurar cadena de reglas**:

```json
{
  "nodes": [
    {
      "type": "TbMsgTypeSwitchNode",
      "name": "Verificar tipo de mensaje"
    },
    {
      "type": "TbFilterScriptNode",
      "name": "Filtrar temperatura > 30",
      "configuration": {
        "script": "return msg.temperature > 30;"
      }
    },
    {
      "type": "TbCreateAlarmNode",
      "name": "Crear alarma",
      "configuration": {
        "alarmType": "HighTemperature",
        "severity": "CRITICAL",
        "details": "La temperatura ha excedido 30°C"
      }
    }
  ]
}
```

### 5. Visualizar datos en tiempo real

En cualquier widget:

1. **Haz clic en el widget**
2. **View in full screen** para una vista ampliada
3. Los datos se actualizan automáticamente cuando tu sensor envía información

---

## Docker Compose - Configuración y Deployment

### 1. Estructura de Docker Compose

**Archivo: `docker/docker-compose.yml`**

```yaml
version: '3.8'

services:
  postgres:        # Base de datos de entidades
  kafka:           # Cola de mensajes
  valkey:          # Caché distribuida
  tb-core:         # Núcleo de ThingsBoard (lógica de negocio)
  tb-rule-engine:  # Motor de reglas
  tb-mqtt-transport: # Transporte MQTT
  tb-web-ui:       # Interfaz web
  haproxy:         # Load balancer

volumes:
  postgres_data:
  valkey_data:
  kafka_data:
```

### 2. Instalación y arranque

#### Paso 1: Crear estructura de directorios

```bash
cd docker
./docker-create-log-folders.sh
```

#### Paso 2: Instalar con datos de demostración

```bash
./docker-install-tb.sh --loadDemo
```

**Opciones**:
- `--loadDemo`: Carga datos de ejemplo (dispositivos, dashboards, usuarios)
- Sin flag: Instalación limpia

**Credenciales después de instalar con `--loadDemo`**:
```
Administrador del sistema:
  Email: sysadmin@thingsboard.org
  Contraseña: sysadmin

Administrador de inquilino:
  Email: tenant@thingsboard.org
  Contraseña: tenant

Usuario cliente:
  Email: customer@thingsboard.org
  Contraseña: customer
```

#### Paso 3: Iniciar servicios

```bash
./docker-start-services.sh
```

**¿Qué ocurre?**
1. Docker descarga imágenes (primera vez)
2. Crea y inicia contenedores
3. Inicializa base de datos
4. Los servicios se conectan entre sí

**Esperar a que todo esté listo** (2-3 minutos):

```bash
# Ver estado de contenedores
docker-compose ps

# Ver logs de un servicio
docker-compose logs -f tb-core1

# Ver logs de todos los servicios
docker-compose logs -f
```

#### Paso 4: Acceder a ThingsBoard

```
http://localhost (a través de HAProxy)
o
http://localhost:8080 (TB-Core directo)
```

### 3. Comandos útiles de Docker

```bash
# Ver estado de todos los contenedores
docker-compose ps

# Ver logs de un servicio específico
docker-compose logs -f tb-core1
docker-compose logs -f tb-mqtt-transport1

# Ver logs de los últimos 100 líneas
docker-compose logs --tail=100 tb-core1

# Buscar un error específico en los logs
docker-compose logs tb-core1 | grep -i "error"

# Entrar en un contenedor
docker-compose exec tb-core1 bash

# Detener servicios (sin eliminar volúmenes)
./docker-stop-services.sh

# Detener y eliminar TODO
./docker-remove-services.sh

# Actualizar una imagen específica
./docker-update-service.sh tb-core1

# Actualizar todas las imágenes
./docker-update-service.sh
```

### 4. Escalado de servicios

Para aumentar la capacidad, edita `docker-compose.yml`:

```yaml
services:
  tb-core1:
    # ... configuración existente
    
  tb-core2:
    # Replica del tb-core1
    image: thingsboard/tb-core:latest
    environment:
      TB_SERVICE_ID: tb-core2
    depends_on:
      - postgres
      - kafka
      - valkey

  tb-mqtt-transport1:
    # ... existente

  tb-mqtt-transport2:
    # Nueva instancia de MQTT transport
    image: thingsboard/tb-mqtt-transport:latest
    ports:
      - "1884:1883"  # Puerto diferente
```

### 5. Monitoreo con Prometheus y Grafana

Habilitar monitoreo en `.env`:

```dotenv
MONITORING_ENABLED=true
```

Luego acceder a:
- **Prometheus**: `http://localhost:9090`
- **Grafana**: `http://localhost:3000` (usuario: `admin` / contraseña: `admin`)

### 6. Configuración de base de datos

#### PostgreSQL (Por defecto)

```yaml
services:
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: thingsboard
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
```

Para conectarte desde tu máquina:

```bash
psql -h localhost -U postgres -d thingsboard
```

Consultas útiles:

```sql
-- Ver dispositivos registrados
SELECT * FROM device;

-- Ver datos de telemetría (últimas 100 lecturas)
SELECT * FROM ts_kv_latest ORDER BY ts DESC LIMIT 100;

-- Ver alarmas
SELECT * FROM alarm;

-- Contar dispositivos por tipo
SELECT type, COUNT(*) as count FROM device GROUP BY type;
```

#### Hybrid (PostgreSQL + Cassandra)

Editar `.env`:

```dotenv
DATABASE=hybrid
```

Esto despliega tanto PostgreSQL como Cassandra.

### 7. Configuración de caché

#### Valkey Standalone (Por defecto)

```dotenv
CACHE=valkey
```

#### Valkey Cluster (Alta disponibilidad)

```dotenv
CACHE=valkey-cluster
```

Proporciona 6 nodos (3 primarios, 3 réplicas).

#### Valkey Sentinel

```dotenv
CACHE=valkey-sentinel
```

Proporciona failover automático.

### 8. Variables de entorno personalizadas

Editar `docker/tb-node.env`:

```dotenv
# Puertos
TB_PORT=8080
TB_BIND_ADDRESS=0.0.0.0

# Base de datos
SPRING_DATASOURCE_URL=jdbc:postgresql://postgres:5432/thingsboard
SPRING_DATASOURCE_USERNAME=postgres
SPRING_DATASOURCE_PASSWORD=postgres

# Cache
CACHE_TYPE=redis
REDIS_ADDRESSES=valkey:6379

# Queue
TB_QUEUE_TYPE=kafka
TB_QUEUE_KAFKA_SERVERS=kafka:9092

# Rule Engine
TB_RULE_ENGINE_CORE_POOL_SIZE=1
TB_RULE_ENGINE_THREAD_POOL_SIZE=4
TB_RULE_ENGINE_QUEUES_COUNT=10

# JWT
JWT_TOKEN_EXPIRATION_TIME=86400

# Límites
TB_DEVICE_DEFAULT_BATCH_SIZE=1000
```

---

## Troubleshooting

### Problema: "Connection refused" en puerto 8080

```bash
# Verificar si el contenedor está corriendo
docker-compose ps

# Ver logs del contenedor
docker-compose logs tb-core1

# Solución: Esperar más tiempo a que inicie
# Los microservicios pueden tardar 2-3 minutos
```

### Problema: Base de datos no inicia

```bash
# Ver logs de PostgreSQL
docker-compose logs postgres

# Comprobar que el volumen existe
docker volume ls | grep postgres

# Limpiar volúmenes y reiniciar (¡esto borra datos!)
docker-compose down -v
./docker-create-log-folders.sh
./docker-install-tb.sh
```

### Problema: Falta memoria

**Error**: `java.lang.OutOfMemoryError`

**Solución**: Aumentar memoria en `.env`:

```dotenv
JAVA_OPTS=-Xmx4096M -Xms4096M -Xss384k -XX:+AlwaysPreTouch
```

### Problema: Los datos no llegan desde MQTT

```bash
# Probar conexión MQTT
mosquitto_sub -h localhost -v -t '#'

# Ver logs del transport MQTT
docker-compose logs -f tb-mqtt-transport1

# Verificar que el dispositivo tenga access token válido
# (En interfaz web: Devices > Tu dispositivo > Credentials)
```

### Problema: Rule Engine no procesa datos

1. Verificar que la Rule Chain está **activada**
2. Ver logs:
   ```bash
   docker-compose logs -f tb-rule-engine1
   ```
3. Comprobar que los nodos estén correctamente conectados
4. Verificar configuración de filtros (scripts JavaScript)

### Problema: Pérdida de datos después de `docker-compose down`

**Por defecto**: Los volúmenes persisten  
**Para limpiar TODO**: 
```bash
docker-compose down -v
```

### Logs útiles para debugging

```bash
# Seguir logs en tiempo real
docker-compose logs -f

# Últimas 50 líneas de tb-core
docker-compose logs --tail=50 tb-core1

# Búsqueda de errores
docker-compose logs | grep -i exception

# Exportar logs a archivo
docker-compose logs > thingsboard_logs.txt
```

---

## Recursos Adicionales

### Documentación oficial

- 📖 [Documentación de ThingsBoard](https://thingsboard.io/docs/)
- 🚀 [Getting Started Guide](https://thingsboard.io/docs/getting-started-guides/helloworld/)
- 🔌 [Device Connectivity](https://thingsboard.io/docs/user-guide/device-connectivity/)
- 📡 [MQTT Integration](https://thingsboard.io/docs/reference/mqtt-api/)
- ⚙️ [Rule Engine Guide](https://thingsboard.io/docs/user-guide/rule-engine-2-0/re-getting-started/)

### Protocolos soportados

| Protocolo | Puerto | Caso de uso |
|-----------|--------|------------|
| MQTT | 1883/8883 | Dispositivos IoT ligeros |
| HTTP | 8080 | APIs REST, webhooks |
| CoAP | 5683 | Dispositivos muy limitados |
| LWM2M | 5685 | Gestión de dispositivos |
| SNMP | 161 | Monitoreo de redes |

### APIs de ThingsBoard

```bash
# Obtener token
POST /api/auth/login
{
  "username": "user@example.com",
  "password": "password"
}

# Crear dispositivo
POST /api/device
Authorization: Bearer {token}

# Enviar telemetría
POST /api/v1/{device_access_token}/telemetry

# Obtener atributos
GET /api/plugins/telemetry/DEVICE/{deviceId}/values/attributes

# Ejecutar comando RPC
POST /api/plugins/rpc/oneway/{deviceId}
```

### Ejemplos de code

**Python - Enviar datos:**
```python
import requests
import json

TOKEN = "your_device_token"
URL = "http://localhost:8080/api/v1/" + TOKEN + "/telemetry"

data = {
    "temperature": 25.5,
    "humidity": 60
}

response = requests.post(URL, json=data)
print(response.status_code)
```

**JavaScript - Node.js:**
```javascript
const mqtt = require('mqtt');

const client = mqtt.connect('mqtt://localhost:1883');

client.on('connect', () => {
  const topic = 'v1/devices/me/telemetry';
  const message = JSON.stringify({
    temperature: 25.5,
    humidity: 60
  });
  
  client.publish(topic, message);
});
```

---

## Guía rápida

### Instalación rápida (5 minutos)

```bash
cd docker
./docker-create-log-folders.sh
./docker-install-tb.sh --loadDemo
./docker-start-services.sh

# Abre en navegador: http://localhost
# Usuario: sysadmin@thingsboard.org
# Contraseña: sysadmin
```

### Enviar datos rápidamente

```bash
# Terminal 1: Instalar MQTT
brew install mosquitto

# Terminal 2: Publicar datos (reemplaza TOKEN)
mosquitto_pub -h localhost -t v1/devices/me/telemetry \
  -u "YOUR_ACCESS_TOKEN" \
  -d '{"temperature": 25.5, "humidity": 60}'

# En navegador: Devices > Tu dispositivo > Latest telemetry
# ¡Deberías ver los datos!
```

---

**Última actualización**: Enero 2026  
**Versión de ThingsBoard**: 4.4.0  
**Mantenedor**: Tu nombre/equipo

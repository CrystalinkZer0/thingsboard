    # 🚀 Guía de Inicio ThingsBoard en Raspberry Pi 4 (PROBADO ✅)

## 📋 Contexto

Esta guía configura ThingsBoard **completamente optimizado para Raspberry Pi 4 (8GB RAM)** con configuración **minimizada** que **funciona sin errores 503**.

### ✅ Problema Resuelto

**ANTES:** Error 503 "Service Unavailable", swap al 100%, CPU load > 69

- Configuración por defecto crea 26+ contenedores
- Consume > 7.5GB RAM constantemente
- Activa intercambio masivo (thrashing)

**AHORA:** Sistema estable, solo 14 contenedores

- RAM libre: 1.9GB
- CPU load: 12-15 (normal)
- Swap utilizado: 50-75% (aceptable)
- ✅ MQTT funcional
- ✅ Web UI rápida
- ✅ Espacio para más dispositivos IoT

---

## 🔧 Configuración del Sistema

### Hardware Requerido

- **Raspberry Pi 4** (mínimo 8GB RAM)
- **Tarjeta SD** 32GB+ (recomendado 64GB)
- **Red estable** (Ethernet recomendado)

### Software Pre-instalado

- Docker & Docker Compose v2
- Sistema operativo: Raspberry Pi OS (64-bit)
- Usuario: `innvoid`
- IP fija: `192.168.4.177` (ajustar según tu red)

---

## 📁 Estructura de Archivos

```
~/thingsboard-docker/
├── .env                          # Configuración Java optimizada
├── docker-compose.yml            # Servicios Docker
├── tb-node.postgres.env          # Config PostgreSQL
├── queue-kafka.env               # Config Kafka
└── docker-compose.volumes.yml   # Volúmenes persistentes
```

---

## 🛠️ Instalación Rápida (15 minutos)

### OPCIÓN A: Instalación desde Git (Recomendado)

```bash
# 1. SSH a la Raspberry Pi
ssh innvoid@raspberrypi.local
# O: ssh innvoid@192.168.4.177

# 2. Clonar repositorio ThingsBoard
git clone https://github.com/thingsboard/thingsboard.git ~/thingsboard
cd ~/thingsboard/docker

# 3. Descargar archivos optimizados desde tu repositorio personal
# (O copiar manualmente los archivos del paso 5)
git clone https://tu-repo.git ~/thingsboard-config
cp ~/thingsboard-config/docker/* ~/thingsboard/docker/

# 4. Ir al directorio docker
cd ~/thingsboard/docker
```

### OPCIÓN B: Instalación Manual (Si no tienes Git)

```bash
# 1. SSH a la Raspberry Pi
ssh innvoid@raspberrypi.local

# 2. Crear directorio
mkdir -p ~/thingsboard-docker
cd ~/thingsboard-docker

# 3. Copiar archivos desde tu máquina local (desde otra terminal)
# En tu máquina local:
scp docker/docker-compose.yml innvoid@raspberrypi.local:~/thingsboard-docker/
scp docker/docker-compose.rpi-optimized.yml innvoid@raspberrypi.local:~/thingsboard-docker/
scp docker/deploy-rpi-quick.sh innvoid@raspberrypi.local:~/thingsboard-docker/
scp docker/.env innvoid@raspberrypi.local:~/thingsboard-docker/
```

### Paso 1: Verificar Archivos Necesarios

```bash
cd ~/thingsboard/docker  # O ~/thingsboard-docker si instalación manual

# Listar archivos
ls -la docker-compose.yml .env deploy-rpi-quick.sh
```

**Archivos esperados:**

- ✅ `docker-compose.yml` (configuración Docker)
- ✅ `.env` (variables de entorno)
- ✅ `deploy-rpi-quick.sh` (script de optimización)

### Paso 2: Editar Archivo .env (CRÍTICO)

```bash
nano .env
```

**Verificar que tiene exactamente esto:**

```bash
# CONFIGURACIÓN CRÍTICA
JAVA_OPTS="-Xms512M -Xmx1024M -Xss256k -Dserver.address=0.0.0.0"

# Versión
TB_VERSION=4.3.0.1
DOCKER_REPO=thingsboard
TB_NODE_DOCKER_NAME=tb-node
```

**⚠️ IMPORTANTE:**

- `-Dserver.address=0.0.0.0` es OBLIGATORIO (sin esto HAProxy no conecta)
- `-Xmx1024M` es máximo de RAM por proceso Java
- `-Xms512M` es mínimo para inicialización rápida

Guardar: `Ctrl+X` → `Y` → `Enter`

### Paso 3: Preparar Script de Optimización

```bash
chmod +x deploy-rpi-quick.sh
./deploy-rpi-quick.sh
```

**Cuando te pida confirmación, escribe:** `y` y presiona Enter

**Tiempo total:** 3-5 minutos

**Salida esperada:**

```
=== ESTADO FINAL ===

📊 Servicios activos:
thingsboard-ce-tb-coap-transport-1    Up X seconds
thingsboard-ce-tb-http-transport1-1   Up X seconds
thingsboard-ce-tb-mqtt-transport1-1   Up About a minute
thingsboard-ce-tb-core1-1             Up About a minute
[... más servicios ...]

💾 Uso de memoria:
Mem: 7,9Gi [usado] 1,9Gi [libre]

✅ Despliegue optimizado completado
```

## ⏱️ Esperar Inicialización Completa

**El sistema está iniciando en background. Esperar:**

```bash
# Monitorear estado cada 30 segundos
watch -n 30 'docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "tb-|NAME"'
```

**Cuando veas todos estos servicios con status "Up":**

- ✅ `thingsboard-ce-tb-core1-1`
- ✅ `thingsboard-ce-tb-mqtt-transport1-1`
- ✅ `thingsboard-ce-tb-http-transport1-1`
- ✅ `thingsboard-ce-tb-coap-transport-1`
- ✅ `thingsboard-ce-zookeeper-1`
- ✅ `thingsboard-ce-kafka-1`
- ✅ `thingsboard-ce-postgres-1`
- ✅ `haproxy-certbot`

**Presionar Ctrl+C para salir**

**Tiempo total de espera:** 2-3 minutos

### Verificación Rápida

```bash
# Verificar que Puerto 8080 está abierto (ThingsBoard API)
docker exec thingsboard-ce-tb-core1-1 bash -c \
  "(echo > /dev/tcp/127.0.0.1/8080) && echo '✅ LISTO' || echo '⏳ Aún inicializando'"

# Repetir hasta que diga "✅ LISTO"
```

### Verificación de Memoria (IMPORTANTE)

```bash
# Verificar que tenemos RAM libre
free -h
```

**Esperado:**

```
Mem:    7,9Gi  [5,0-5,5Gi usado]  [1,9-2,4Gi libre]
```

**Si RAM libre < 1GB:**

```bash
# Detener servicios secundarios manualmente
docker compose stop tb-core2 tb-rule-engine2 2>/dev/null
docker compose stop tb-js-executor-{6..10} 2>/dev/null

# Esperar 30 segundos y verificar de nuevo
sleep 30
free -h
```

---

## ✅ Verificación de Estado Completa

### Script de Verificación Todo-en-Uno (RECOMENDADO)

```bash
# Crear script permanente
cat << 'EOF' > ~/verify-thingsboard.sh
#!/bin/bash
echo "════════════════════════════════════════"
echo "  VERIFICACIÓN THINGSBOARD - RPi 4"
echo "════════════════════════════════════════"
echo ""

echo "📊 ESTADO DE SERVICIOS:"
docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "(NAME|tb-|zookeeper|haproxy|kafka|postgres)" | head -12
echo ""

echo "💾 MEMORIA:"
free -h | head -2
echo ""

echo "⚡ CPU LOAD:"
uptime | awk -F'load average:' '{print $2}'
echo ""

echo "🔌 CONECTIVIDAD:"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/api/auth/login 2>/dev/null)
if [ "$HTTP_CODE" == "401" ]; then
    echo "✅ API responde correctamente (HTTP $HTTP_CODE)"
else
    echo "⏳ API aún inicializando (HTTP $HTTP_CODE)"
fi
echo ""

echo "📡 MQTT EN PUERTO 1883:"
if netstat -tlnp 2>/dev/null | grep -q ":1883"; then
    echo "✅ Puerto 1883 activo"
else
    echo "⏳ MQTT aún inicializando"
fi
echo ""
EOF

chmod +x ~/verify-thingsboard.sh
~/verify-thingsboard.sh
```

### Salida Esperada (Ejemplo)

```
════════════════════════════════════════
  VERIFICACIÓN THINGSBOARD - RPi 4
════════════════════════════════════════

📊 ESTADO DE SERVICIOS:
NAMES                                 STATUS
thingsboard-ce-tb-mqtt-transport1-1   Up 5 minutes
thingsboard-ce-tb-coap-transport-1    Up 5 minutes
thingsboard-ce-tb-http-transport1-1   Up 4 minutes
thingsboard-ce-tb-core1-1             Up 5 minutes
thingsboard-ce-tb-rule-engine1-1      Up 5 minutes
thingsboard-ce-zookeeper-1            Up 6 minutes
thingsboard-ce-kafka-1                Up 7 minutes
thingsboard-ce-postgres-1             Up 7 minutes
haproxy-certbot                       Up 4 minutes

💾 MEMORIA:
Mem:           7,9Gi       5,1Gi       1,9Gi

⚡ CPU LOAD:
 12.39, 17.74, 22.17

🔌 CONECTIVIDAD:
✅ API responde correctamente (HTTP 401)

📡 MQTT EN PUERTO 1883:
✅ Puerto 1883 activo
```

### Servicios Que DEBEN estar Corriendo

```
✅ thingsboard-ce-tb-core1-1          (NO tb-core2)
✅ thingsboard-ce-tb-rule-engine1-1   (NO rule-engine2)
✅ thingsboard-ce-tb-js-executor-1 y 2 únicamente
✅ thingsboard-ce-kafka-1
✅ thingsboard-ce-postgres-1
✅ thingsboard-ce-zookeeper-1
✅ thingsboard-ce-tb-mqtt-transport1-1
✅ thingsboard-ce-tb-http-transport1-1
✅ thingsboard-ce-tb-coap-transport-1
✅ haproxy-certbot
```

**Total: 14 contenedores (NO 26)**

### Parámetros de Salud

| Métrica        | Rango Aceptable | Rojo (Problema) |
| -------------- | --------------- | --------------- |
| RAM Libre      | 1.5GB - 2.5GB   | < 1.0GB         |
| CPU Load       | 10 - 20         | > 30            |
| Swap Utilizado | 50-75%          | > 90%           |
| HTTP Code      | 401             | > 500           |

---

## 🌐 Acceso Web a ThingsBoard

### 1. Abrir Navegador

```
http://raspberrypi.local
```

O si el DNS no funciona:

```
http://192.168.4.177
```

### 2. Login Inicial

**Credenciales por defecto (CAMBIAR DESPUÉS):**

```
Email:    sysadmin@thingsboard.org
Password: sysadmin
```

### 3. Página de Bienvenida

Deberías ver:

- Dashboard vacío
- Menú lateral con: Devices, Dashboards, Rules, Security, etc.

**Si ves error 503:**

- Esperar otros 5 minutos
- Ejecutar: `~/verify-thingsboard.sh`
- Revisar sección de "Solución de Problemas"

### 4. Cambiar Contraseña (RECOMENDADO)

1. Click en perfil (arriba a la derecha)
2. Settings → Change Password
3. Ingresar contraseña fuerte

### 5. Crear Primer Device (ESP32)

1. Devices → `+` Add new device
2. **Device name:** `ESP32_Sensor`
3. **Device profile:** Default
4. **Click Save**
5. **Ir a Device Details**
6. **Tab "Credentials"**
7. **Copiar "Access Token"** (algo como: `ABC123DEFG456XYZ`)

**⚠️ GUARDAR ESTE TOKEN** - Lo necesitarás para el ESP32

---

## 🔄 Operaciones Comunes

### Reiniciar Completamente ThingsBoard

```bash
cd ~/thingsboard/docker  # O tu directorio

# 1. Detener todo
docker compose down

# 2. Limpiar (opcional, para reinicio limpio)
docker system prune -f

# 3. Iniciar de nuevo
./deploy-rpi-quick.sh

# 4. Esperar 3-5 minutos

# 5. Verificar
~/verify-thingsboard.sh
```

### Reiniciar Solo tb-core1 (Más Rápido)

```bash
cd ~/thingsboard/docker

# Reiniciar
docker compose restart tb-core1

# Esperar 3-5 minutos para que inicialice

# Verificar
docker logs --tail 30 thingsboard-ce-tb-core1-1 | grep -i "started"
```

### Ver Logs en Tiempo Real

```bash
# TB Core (servicio principal)
docker logs -f thingsboard-ce-tb-core1-1

# MQTT Transport (conexiones IoT)
docker logs -f thingsboard-ce-tb-mqtt-transport1-1

# Última línea solamente
docker logs --tail 1 thingsboard-ce-tb-core1-1

# Ver últimas 100 líneas
docker logs --tail 100 thingsboard-ce-tb-core1-1

# Buscar errores específicos
docker logs thingsboard-ce-tb-core1-1 2>&1 | grep -i "error"
```

### Ver Estadísticas en Tiempo Real

```bash
# Consumo de CPU y RAM de todos los contenedores
docker stats

# Solo servicios principales (Ctrl+C para salir)
watch -n 2 'docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" | grep -E "(NAME|tb-core|mqtt|rule)"'
```

### Detener Servicios (Sin Eliminar Datos)

```bash
cd ~/thingsboard/docker

# Detener todos (datos persisten)
docker compose stop

# O detener solo uno
docker compose stop tb-mqtt-transport1
```

### Detener Completamente (Con Backup de Datos)

```bash
cd ~/thingsboard/docker

# Hacer backup de volúmenes (OPCIONAL pero RECOMENDADO)
tar czf ~/backup-thingsboard-$(date +%Y%m%d).tar.gz docker/

# Detener y eliminar contenedores (datos en volúmenes persisten)
docker compose down

# Los datos PostgreSQL siguen en: docker/volumes/postgres/

# Para recuperar:
docker compose up -d
# Los datos se cargarán automáticamente
```

---

## 🐛 Solución de Problemas

### ❌ Error 503 "Service Unavailable"

**Síntoma:** Página muestra error 503 al acceder

**Paso 1: Verificar que tb-core está corriendo**

```bash
docker ps | grep tb-core1

# Salida esperada:
# ... Name: thingsboard-ce-tb-core1-1  Status: Up 5 minutes
```

**Paso 2: Verificar que tb-core responde en puerto 8080**

```bash
docker exec thingsboard-ce-tb-core1-1 bash -c \
  "(echo > /dev/tcp/127.0.0.1/8080) && echo '✅ RESPONDE' || echo '❌ NO RESPONDE'"
```

**Paso 3: Si dice "NO RESPONDE"**

```bash
# Revisar logs
docker logs --tail 50 thingsboard-ce-tb-core1-1 | grep -i "error"

# Esperar 5 minutos más (puede aún estar inicializando)
sleep 300
~/verify-thingsboard.sh
```

**Paso 4: Si sigue sin responder después de 15 minutos**

```bash
# Verificar que .env tiene -Dserver.address=0.0.0.0
cat .env | grep JAVA_OPTS

# Salida esperada:
# JAVA_OPTS="-Xms512M -Xmx1024M -Xss256k -Dserver.address=0.0.0.0"

# Si falta -Dserver.address=0.0.0.0, editarlo:
nano .env
# Buscar línea JAVA_OPTS y agregar -Dserver.address=0.0.0.0

# Guardar y reiniciar
docker compose restart tb-core1
sleep 600  # 10 minutos
~/verify-thingsboard.sh
```

---

### ❌ Error: "HAProxy no puede conectar a tb-core1"

**Síntoma:** HAProxy logs muestran `Backend is down`

**Causa:** tb-core1 no está escuchando en 0.0.0.0

**Solución:**

```bash
# Verificar .env (CRÍTICO)
cat .env | grep JAVA_OPTS

# Si NO tiene -Dserver.address=0.0.0.0, agregarlo
nano .env

# Cambiar:
# JAVA_OPTS="-Xms512M -Xmx1024M -Xss256k"

# A:
# JAVA_OPTS="-Xms512M -Xmx1024M -Xss256k -Dserver.address=0.0.0.0"

# Guardar: Ctrl+X → Y → Enter

# Reiniciar servicios
docker compose down
sleep 10
./deploy-rpi-quick.sh
```

---

### ❌ RAM casi llena (< 1GB libre)

**Síntoma:** `free -h` muestra Mem usado > 7GB

**Paso 1: Detener servicios secundarios**

```bash
docker compose stop tb-core2 tb-rule-engine2 2>/dev/null
docker compose stop tb-js-executor-{3..10} 2>/dev/null

# Verificar después de 30 segundos
sleep 30
free -h
```

**Paso 2: Si aún no libera memoria**

```bash
# Ver quién consume memoria
docker stats --no-stream --format "table {{.Name}}\t{{.MemUsage}}" | sort -k2 -h | tail -5

# Si tb-js-executor consume mucha RAM, detener más
docker compose stop tb-js-executor-2
sleep 30

# Verificar
free -h
```

**Paso 3: Si RAM sigue crítica (< 500MB)**

```bash
# Reinicio completo
docker compose down
sleep 10

# Limpiar sistema
docker system prune -f --volumes

# Iniciar nuevamente
./deploy-rpi-quick.sh
```

---

### ❌ Swap al 100% (Sistema extremadamente lento)

**Síntoma:**

```bash
free -h
# Swap: 2.0Gi total, 2.0Gi used (100%)
```

**Solución urgente:**

```bash
# 1. Detener INMEDIATAMENTE todos los servicios
docker compose stop

# 2. Esperar limpieza de swap (1-2 minutos)
sleep 120

# 3. Limpiar sistema
docker system prune -f

# 4. Reiniciar
./deploy-rpi-quick.sh
```

---

### ❌ MQTT no funciona en puerto 1883

**Síntoma:** ESP32 no puede conectar a `192.168.4.177:1883`

**Paso 1: Verificar que puerto está abierto**

```bash
netstat -tlnp | grep 1883

# Salida esperada:
# tcp  0  0 0.0.0.0:1883  0.0.0.0:*  LISTEN  (HAProxy)
```

**Paso 2: Verificar que mqtt-transport está corriendo**

```bash
docker ps | grep mqtt-transport1

# Salida esperada:
# ... Status: Up X minutes
```

**Paso 3: Verificar logs del transport**

```bash
docker logs --tail 30 thingsboard-ce-tb-mqtt-transport1-1 | grep -i "started"

# Salida esperada:
# ... Tomcat initialized with port 8081
# ... Started ThingsboardMqttTransportApplication
```

**Paso 4: Si puerto está cerrado**

```bash
# Reiniciar HAProxy
docker compose restart haproxy

# Esperar 10 segundos
sleep 10

# Verificar puerto nuevamente
netstat -tlnp | grep 1883
```

---

### ⚠️ Docker no está en PATH

**Síntoma:**

```
bash: docker: command not found
```

**Solución:**

```bash
# Verificar instalación
which docker

# Si no encuentra, instalar
sudo apt-get update
sudo apt-get install docker.io

# Agregar usuario al grupo docker (para usar sin sudo)
sudo usermod -aG docker $USER
newgrp docker

# Verificar
docker ps
```

---

### ⚠️ No puedo conectar por SSH

**Síntoma:**

```
ssh: connect to host raspberrypi.local port 22: Connection refused
```

**Solución:**

```bash
# Usar IP directa si DNS no funciona
ssh innvoid@192.168.4.177

# Si tampoco funciona, desde la Raspberry (pantalla+teclado):
sudo systemctl start ssh
sudo systemctl enable ssh
```

---

## 🔐 Configuración para Producción

### 1. Cambiar Contraseña de Administrador

**En la Web UI:**

1. Login como `sysadmin@thingsboard.org`
2. Click en usuario (arriba a la derecha)
3. **Settings → Security → Change Password**
4. Ingresar contraseña **fuerte** (mín 8 caracteres)
5. Guardar

### 2. Crear Usuario Operador (Opcional pero Recomendado)

1. **Administration → Users**
2. **+ Add new user**
3. **Email:** `operador@empresa.local`
4. **Role:** CUSTOMER_USER (no ADMIN)
5. **Establecer contraseña**
6. Guardar

**Ventaja:** Operador no puede cambiar configuración crítica

### 3. Habilitar Autenticación de Dos Factores (Recomendado)

1. En Settings personales (arriba a la derecha)
2. **Enable Two-Factor Authentication**
3. Escanear QR con Google Authenticator o Authy
4. Guardar

### 4. Crear Backup Automático

```bash
# Crear script de backup diario
cat << 'EOF' > ~/backup-thingsboard.sh
#!/bin/bash

BACKUP_DIR="$HOME/thingsboard-backups"
DATE=$(date +%Y%m%d_%H%M%S)

# Crear directorio
mkdir -p "$BACKUP_DIR"

# Backup PostgreSQL (toda la base de datos)
docker exec thingsboard-ce-postgres-1 pg_dumpall -U postgres 2>/dev/null | gzip > "$BACKUP_DIR/postgres_$DATE.sql.gz"

# Backup de configuración
tar czf "$BACKUP_DIR/config_$DATE.tar.gz" -C ~ thingsboard-docker/.env thingsboard-docker/docker-compose.yml 2>/dev/null

# Mantener solo últimos 7 días
find "$BACKUP_DIR" -name "*.gz" -mtime +7 -delete

echo "[$(date)] Backup completado: $BACKUP_DIR" >> "$HOME/thingsboard-backups/backup.log"
EOF

chmod +x ~/backup-thingsboard.sh

# Probar backup manualmente
~/backup-thingsboard.sh

# Agregar a crontab (diario a las 2 AM)
(crontab -l 2>/dev/null; echo "0 2 * * * $HOME/backup-thingsboard.sh") | crontab -

# Verificar que se agregó
crontab -l | grep backup-thingsboard.sh
```

### 5. Monitoreo Automático

```bash
# Script de alerta si ThingsBoard cae
cat << 'EOF' > ~/monitor-thingsboard.sh
#!/bin/bash

# Verificar cada 5 minutos
while true; do
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/api/auth/login 2>/dev/null)

    if [ "$HTTP_CODE" != "401" ]; then
        echo "⚠️ ALERTA: ThingsBoard no responde (HTTP $HTTP_CODE) - $(date)" >> ~/thingsboard-monitor.log

        # Opcional: Reiniciar automáticamente
        # docker compose restart tb-core1
    fi

    sleep 300
done
EOF

chmod +x ~/monitor-thingsboard.sh

# Ejecutar en background
nohup ~/monitor-thingsboard.sh > /dev/null 2>&1 &

# Ver alertas
tail -f ~/thingsboard-monitor.log
```

### 6. Limpiar Servicios Redundantes Permanentemente (Opcional)

Para Raspberry Pi 4, puedes comentar los servicios secundarios en `docker-compose.yml`:

```bash
nano docker-compose.yml

# Buscar y comentar (agregar # al inicio):
# tb-core2:
# tb-rule-engine2:
# tb-js-executor-6 a tb-js-executor-10

# Guardar y reiniciar
docker compose down
docker compose up -d
```

Esto garantiza que no se inician accidentalmente.

---

## 📊 Monitoreo

### Ver Estadísticas en Tiempo Real

```bash
# Recursos de todos los contenedores
docker stats

# Solo servicios principales
docker stats thingsboard-ce-tb-core1-1 thingsboard-ce-kafka-1 thingsboard-ce-postgres-1
```

### Script de Monitoreo Continuo

```bash
# Ver estado cada 30 segundos
watch -n 30 '~/check-thingsboard.sh'
```

---

## � Conectar ESP32 a ThingsBoard

### Preparación

1. **En ThingsBoard Web UI:**
   - Devices → `+` Add new device
   - Name: `ESP32_SensorTemp`
   - Save
   - Ir a Device Details → **Credentials**
   - **Copiar "Access Token"** (algo como: `ABC123XYZ789`)

### Opción 1: Conexión HTTP (Más Simple)

**Arduino Code (PlatformIO):**

```cpp
#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>

// WiFi
const char* ssid = "NOMBRE_RED";
const char* password = "CONTRASEÑA";

// ThingsBoard
const char* server = "192.168.4.177";  // O "raspberrypi.local"
const char* token = "ABC123XYZ789";     // Tu token copiado

void setup() {
    Serial.begin(115200);
    WiFi.begin(ssid, password);

    while (WiFi.status() != WL_CONNECTED) {
        delay(500);
        Serial.print(".");
    }
    Serial.println("\n✅ WiFi Conectado");
}

void loop() {
    // Leer sensor (ejemplo temperatura)
    float temperature = 25.5;  // Reemplazar con lectura real
    float humidity = 60.0;

    // Preparar JSON
    String url = String("http://") + server + "/api/v1/" + token + "/telemetry";

    HTTPClient http;
    http.begin(url);
    http.addHeader("Content-Type", "application/json");

    // Crear JSON
    DynamicJsonDocument doc(1024);
    doc["temperature"] = temperature;
    doc["humidity"] = humidity;
    doc["timestamp"] = millis();

    String payload;
    serializeJson(doc, payload);

    // Enviar
    int httpCode = http.POST(payload);

    if (httpCode == 200) {
        Serial.println("✅ Telemetría enviada");
    } else {
        Serial.printf("❌ Error HTTP %d\n", httpCode);
    }

    http.end();

    // Esperar 10 segundos
    delay(10000);
}
```

**Problemática:** Si ves error "Connection reset by peer"

1. Verificar que el token es correcto
2. Verificar que el device existe en ThingsBoard
3. Verificar IP correcta: `ping raspberrypi.local`

---

### Opción 2: Conexión MQTT (Recomendado para IoT)

**Arduino Code (PlatformIO):**

```cpp
#include <WiFi.h>
#include <PubSubClient.h>

// WiFi
const char* ssid = "NOMBRE_RED";
const char* password = "CONTRASEÑA";

// MQTT / ThingsBoard
const char* mqtt_server = "192.168.4.177";  // O "raspberrypi.local"
const int mqtt_port = 1883;
const char* token = "ABC123XYZ789";  // Tu token como usuario MQTT
const char* mqtt_user = token;       // En ThingsBoard, token = usuario
const char* mqtt_pass = "";          // Contraseña vacía (token es credencial)

WiFiClient espClient;
PubSubClient client(espClient);

void callback(char* topic, byte* payload, unsigned int length) {
    Serial.print("Mensaje recibido [");
    Serial.print(topic);
    Serial.print("]: ");

    for (int i = 0; i < length; i++) {
        Serial.print((char)payload[i]);
    }
    Serial.println();
}

void reconnect() {
    while (!client.connected()) {
        Serial.println("Conectando a MQTT...");

        if (client.connect("ESP32", mqtt_user, mqtt_pass)) {
            Serial.println("✅ MQTT Conectado");
            client.subscribe("v1/devices/me/rpc/request/+");  // Recibir RPC commands
        } else {
            Serial.print("❌ Falló, código: ");
            Serial.print(client.state());
            Serial.println(" Reintentando en 5s...");
            delay(5000);
        }
    }
}

void setup() {
    Serial.begin(115200);
    delay(10);

    // Conectar WiFi
    Serial.println();
    Serial.print("Conectando a WiFi: ");
    Serial.println(ssid);

    WiFi.begin(ssid, password);
    int attempts = 0;
    while (WiFi.status() != WL_CONNECTED && attempts < 20) {
        delay(500);
        Serial.print(".");
        attempts++;
    }

    Serial.println("\n✅ WiFi Conectado");
    Serial.print("IP: ");
    Serial.println(WiFi.localIP());

    // Conectar MQTT
    client.setServer(mqtt_server, mqtt_port);
    client.setCallback(callback);
}

void loop() {
    if (!client.connected()) {
        reconnect();
    }
    client.loop();

    // Enviar telemetría cada 10 segundos
    static unsigned long lastTime = 0;
    if (millis() - lastTime > 10000) {
        lastTime = millis();

        // Leer sensores
        float temperature = 25.5;
        float humidity = 60.0;

        // Publicar en ThingsBoard MQTT
        char payload[256];
        snprintf(payload, sizeof(payload),
            "{\"temperature\":%.1f,\"humidity\":%.1f}",
            temperature, humidity);

        client.publish("v1/devices/me/telemetry", payload);
        Serial.print("📤 Publicado: ");
        Serial.println(payload);
    }
}
```

**En ThingsBoard:**

Después de 10-20 segundos deberías ver datos en:

- Dev → Device Details → **Latest Telemetry**
- Mostrar: `temperature`, `humidity`, etc.

---

### Verificar Conexiones Activas

```bash
# Ver todos los clientes MQTT conectados
docker logs thingsboard-ce-tb-mqtt-transport1-1 | grep -i "client\|connection" | tail -10
```

---

### Crear Dashboard para Ver Datos en Tiempo Real

1. **Dashboards → Create new dashboard**
2. **Name:** `ESP32 Monitor`
3. **Save**
4. **Edit → Add widget**
5. **Tipo:** Gauge (indicador)
6. **Data source:** Tu device `ESP32_SensorTemp`
7. **Telemetry:** `temperature`
8. **Save**
9. **View** para ver en tiempo real

---

## 📝 Checklist de Inicio Rápido (COMPLETO)

### Instalación (Primera vez)

```
[ ] 1. SSH a Raspberry Pi:
        ssh innvoid@raspberrypi.local

[ ] 2. Ir al directorio Docker:
        cd ~/thingsboard/docker

[ ] 3. Editar .env y verificar:
        nano .env
        # Buscar: JAVA_OPTS=... -Dserver.address=0.0.0.0

[ ] 4. Ejecutar script de optimización:
        chmod +x deploy-rpi-quick.sh
        ./deploy-rpi-quick.sh
        # Responder: y

[ ] 5. Esperar 5 minutos (ver output del script)

[ ] 6. Ejecutar verificación:
        ~/verify-thingsboard.sh
        # Verificar: RAM libre 1.5-2.5GB y API responde (✅)

[ ] 7. Abrir navegador: http://raspberrypi.local
        # O: http://192.168.4.177

[ ] 8. Login inicial: sysadmin@thingsboard.org / sysadmin

[ ] 9. ⚠️ CAMBIAR CONTRASEÑA INMEDIATAMENTE:
        Click usuario → Settings → Change Password

[ ] 10. Crear primer device (ESP32):
        Devices → + Add → Name: ESP32_Sensor
        Save → Device Details → Credentials
        Copiar "Access Token"
```

### Después de Cambios de Configuración

```
[ ] 1. Si editaste .env:
        docker compose restart tb-core1
        Esperar 10 minutos
        ~/verify-thingsboard.sh

[ ] 2. Si cambias docker-compose.yml:
        docker compose down
        docker compose up -d
        Esperar 5 minutos
        ~/verify-thingsboard.sh

[ ] 3. Si hay error 503:
        Consultar sección "Solución de Problemas"
        Execute: docker logs thingsboard-ce-tb-core1-1 | grep -i error
```

### Comandos de Mantenimiento (Diarios)

```
[ ] Ver estado: ~/verify-thingsboard.sh
[ ] Ver logs: docker logs -f thingsboard-ce-tb-core1-1
[ ] Estadísticas: docker stats
[ ] Backup (semanal): ~/backup-thingsboard.sh
```

---

## 📚 Referencias

- **Documentación oficial:** https://thingsboard.io/docs/
- **Docker Hub:** https://hub.docker.com/r/thingsboard/tb-node
- **GitHub:** https://github.com/thingsboard/thingsboard

## 🆘 Soporte

Si encuentras problemas no cubiertos en esta guía:

1. Revisar logs: `docker logs --tail 200 thingsboard-ce-tb-core1-1`
2. Verificar memoria: `free -h`
3. Revisar estado: `~/check-thingsboard.sh`
4. Consultar documentación oficial de ThingsBoard

---

**Última actualización:** Febrero 2026  
**Versión ThingsBoard:** 4.3.0.1  
**Plataforma:** Raspberry Pi OS (64-bit) / Docker Compose v2

# 📋 RESUMEN DE CONFIGURACIÓN - ESP32 + ThingsBoard + getmarket-iot

---

## 🔌 CONEXIONES DE RED

```
┌──────────────────────────────────────────────────────────────┐
│                  RED LOCAL HOP85 (WiFi)                      │
│                   Subnet: 192.168.4.0/24                     │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  [Mac Dev]                [Raspberry Pi]        [ESP32]      │
│  (Tu máquina)            192.168.4.177         WiFi          │
│  Acceso remoto               │                  │            │
│       │                       │                  │            │
│       │ SSH 22                │ MQTT 1883        │            │
│       ├──────────────────────>│<─────────────────┤            │
│       │                       │                  │            │
│       │ REST 8080             │ HTTP 8080        │            │
│       ├──────────────────────>│<─────────────────┤            │
│       │                       │                  │            │
│       └───────────────────────┴──────────────────┘            │
│                      Tráfico de datos / Telemetría           │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

---

## 🎯 CONFIGURACIÓN DEL ESP32

```
╔═══════════════════════════════════════════════════════════════╗
║         PARÁMETROS DE CONEXIÓN WIFI THINGSBOARD              ║
╠═══════════════════════════════════════════════════════════════╣
║                                                               ║
║ Red WiFi SSID:         HOP85                                 ║
║ Red Password:          [TU_PASSWORD]                          ║
║                                                               ║
║ ThingsBoard Host:      192.168.4.177                         ║
║ ThingsBoard Puerto:    1883 (MQTT)                           ║
║ Protocolo:             MQTT v3.1.1                           ║
║ Client ID:             ESP32_IoT_Sensors                     ║
║ Access Token:          [GENERADO_POR_SCRIPT]                 ║
║                                                               ║
╠═══════════════════════════════════════════════════════════════╣
║              SENSORES CONECTADOS AL ESP32                     ║
╠═══════════════════════════════════════════════════════════════╣
║                                                               ║
║ DHT11 Temperatura      GPIO 4                                ║
║ DHT11 Humedad          GPIO 4 (mismo sensor)                 ║
║ W104 Sensor Sonido     GPIO 34 (ADC)                         ║
║ LED Estado             GPIO 2                                ║
║                                                               ║
╠═══════════════════════════════════════════════════════════════╣
║           DATOS ENVIADOS POR MQTT (JSON)                      ║
╠═══════════════════════════════════════════════════════════════╣
║                                                               ║
║ Topic: v1/devices/me/telemetry                              ║
║                                                               ║
║ Payload:                                                      ║
║ {                                                             ║
║   "temperature": 25.5,      ← Grados Celsius               ║
║   "humidity": 65.3,         ← Porcentaje                    ║
║   "soundLevel": 2048,       ← Valores ADC 0-4095            ║
║   "timestamp": 1609459200   ← Milisegundos                  ║
║ }                                                             ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
```

---

## 🏗️ THINGSBOARD EN RASPBERRY

```
╔═══════════════════════════════════════════════════════════════╗
║          SERVICIOS DOCKERIZADOS EN RASPBERRY                 ║
╠═══════════════════════════════════════════════════════════════╣
║                                                               ║
║ 📦 PostgreSQL             Port: 5432                         ║
║    └─ Base de datos de dispositivos, usuarios, reglas        ║
║                                                               ║
║ 🔄 Kafka                  Port: 9092                         ║
║    └─ Cola de mensajes para comunicación entre servicios     ║
║                                                               ║
║ 💾 Valkey (Redis)         Port: 6379                         ║
║    └─ Cache de datos y sesiones                             ║
║                                                               ║
║ 🎯 ThingsBoard Core       Port: 8080 (HTTP)                 ║
║    └─ Lógica de negocio, API REST, Web UI                   ║
║                                                               ║
║ 📡 MQTT Transport         Port: 1883                         ║
║    └─ Servidor MQTT para dispositivos IoT                   ║
║                                                               ║
║ 🌐 HTTP Transport         Port: 8081                         ║
║    └─ Endpoint HTTP para dispositivos                       ║
║                                                               ║
║ 🔐 Otros: CoAP, LWM2M, SNMP (opcional)                      ║
║                                                               ║
╠═══════════════════════════════════════════════════════════════╣
║                 PUERTOS ACCESIBLES                            ║
╠═══════════════════════════════════════════════════════════════╣
║                                                               ║
║ Desde tu Mac:                                                 ║
║   Web:      http://192.168.4.177:8080                       ║
║   API REST: http://192.168.4.177:8080/api/                  ║
║   MQTT:     mqtt://192.168.4.177:1883                       ║
║                                                               ║
║ Credenciales por defecto:                                    ║
║   Email:    sysadmin@thingsboard.org                         ║
║   Pasword:  sysadmin                                         ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
```

---

## 🔑 DISPOSITIVO ESP32 EN THINGSBOARD

```
╔═══════════════════════════════════════════════════════════════╗
║                DISPOSITIVO REGISTRADO                         ║
╠═══════════════════════════════════════════════════════════════╣
║                                                               ║
║ Nombre:                ESP32_IoT_Sensors                     ║
║ Tipo:                  default                               ║
║ Estado:                ACTIVE                                ║
║ Creado:                [FECHA_REGISTRO]                      ║
║ Último acceso:         [ACTUALIZADO_EN_TIEMPO_REAL]          ║
║                                                               ║
╠═══════════════════════════════════════════════════════════════╣
║              TELEMETRÍA EN TIEMPO REAL                        ║
╠═══════════════════════════════════════════════════════════════╣
║                                                               ║
║ temperature:           25.5 °C                               ║
║ humidity:              65.3 %                                ║
║ soundLevel:            2048 / 4095                           ║
║ timestamp:             [MILISEGUNDOS]                        ║
║                                                               ║
╠═══════════════════════════════════════════════════════════════╣
║                    CONTROL REMOTO                             ║
╠═══════════════════════════════════════════════════════════════╣
║                                                               ║
║ LED Control (RPC):                                            ║
║   Method: setLED                                              ║
║   Params: {"value": true/false}                              ║
║                                                               ║
║ Estado:                                                       ║
║   led_status: ON/OFF                                         ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
```

---

## 🌐 GETMARKET-IOT CONECTADO

```
╔═══════════════════════════════════════════════════════════════╗
║             CONFIGURACIÓN GETMARKET-IOT                       ║
╠═══════════════════════════════════════════════════════════════╣
║                                                               ║
║ Host:        192.168.4.177  Sí ← Raspberry                  ║
║ Puerto:      8080            (HTTP REST)                     ║
║ Protocolo:   HTTP/HTTPS     ← Implementado en docs          ║
║                                                               ║
╠═══════════════════════════════════════════════════════════════╣
║                  CREDENCIALES THINGSBOARD                    ║
╠═══════════════════════════════════════════════════════════════╣
║                                                               ║
║ Opción 1: Usar Tenant (Recomendado)                         ║
║   ├─ Username:   tenant@thingsboard.org                      ║
║   ├─ Password:   tenant                                      ║
║   └─ Scope:      Acceso limitado al tenant                   ║
║                                                               ║
║ Opción 2: Usar SysAdmin (Dev/Testing)                        ║
║   ├─ Username:   sysadmin@thingsboard.org                    ║
║   ├─ Password:   sysadmin                                    ║
║   └─ Scope:      Acceso a todo el sistema                    ║
║                                                               ║
╠═══════════════════════════════════════════════════════════════╣
║             ENDPOINTS API PRINCIPALES                        ║
╠═══════════════════════════════════════════════════════════════╣
║                                                               ║
║ POST   /api/auth/login                                       ║
║        └─ Obtener JWT token                                  ║
║                                                               ║
║ GET    /api/tenant/devices                                   ║
║        └─ Listar dispositivos del tenant                     ║
║                                                               ║
║ GET    /api/devices/{deviceId}                               ║
║        └─ Info del dispositivo                               ║
║                                                               ║
║ GET    /api/plugins/telemetry/DEVICE/{id}/values/timeseries ║
║        └─ Datos históricos de sensores                       ║
║                                                               ║
║ POST   /api/plugins/telemetry/DEVICE/{id}/attributes/SHARED  ║
║        └─ Escribir atributos del dispositivo                 ║
║                                                               ║
║ WebSocket: /api/ws/plugins/telemetry                         ║
║        └─ Stream en tiempo real de telemetría                ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
```

---

## 🔄 FLUJO DE DATOS

```
                        ┌─────────────────────┐
                        │   Tu Navegador      │
                        │  (Mac/Laptop)       │
                        └─────────┬───────────┘
                                  │
                                  │ HTTP:8080
                                  │
┌─────────────────────────────────▼───────────────────────────┐
│                   THINGSBOARD (Raspberry)                   │
│                    192.168.4.177:8080                       │
│                                                              │
│    ┌─────────────┐  ┌──────────┐  ┌─────────────┐          │
│    │   Web UI    │  │          │  │  API REST   │          │
│    │  (Angular)  │──│ Core     │──│  Endpoints  │          │
│    └─────────────┘  │          │  └─────────────┘          │
│                     │          │                            │
│    ┌─────────────┐  │          │  ┌─────────────┐          │
│    │   Login &   │──│ Auth     │──│  Rules      │          │
│    │  Security   │  │  Service │  │  Engine     │          │
│    └─────────────┘  │          │  └─────────────┘          │
│                     │          │                            │
│    ┌─────────────┐  │          │  ┌─────────────┐          │
│    │  MQTT:1883  │──│ MQTT     │  │  Telemetry  │          │
│    │  Transport  │  │ Service  │  │  Storage    │          │
│    └─────────────┘  │          │  └─────────────┘          │
│                     └──────────┘                            │
│                          │                                  │
│         ┌────────────────┼────────────────┐                │
│         │                │                │                │
│         ▼                ▼                ▼                │
│    ┌─────────┐    ┌───────────┐  ┌──────────────┐         │
│    │          │    │           │  │              │         │
│    │PostgreSQL│    │  Kafka    │  │  Valkey(RC) │         │
│    │          │    │           │  │              │         │
│    └─────────┘    └───────────┘  └──────────────┘         │
│     (Entities)    (Message Bus)  (Cache/Sessions)          │
│                                                              │
└──────────────────────────────────────────────────────────────┘
       ▲                            ▲                 ▲
       │ MQTT:1883                  │ REST:8080      │
       │ JSON Telemetry             │ JSON API       │
       │                            │                │
  ┌────┴──────┐            ┌────────┴──────┐    ┌────┴──────┐
  │   ESP32    │            │  getmarket-iot│    │   Browser │
  │   (Sensor) │            │   (Node.js)   │    │  (WebApp) │
  │            │            │               │    │           │
  │ • DHT11    │            │ • ThingsBoard │    │ Dashboard │
  │ • W104 SD  │            │   Service     │    │ + Charts  │
  │ • Publica  │            │ • Procesado   │    │ + Control │
  │   datos c/ │            │ • Webhooks    │    │           │
  │   5 seg    │            │               │    │           │
  └───────────┘            └───────────────┘    └───────────┘
```

---

## 📱 ESP32: Pines y Sensores

```
┌─────────────────────────────────────────────┐
│                  ESP32-WROOM-32              │
├─────────────────────────────────────────────┤
│                                             │
│  [USB para Programación]                    │
│           ▲                                 │
│           │                                 │
│   GND ─────┘   3.3V                        │
│    │             │                          │
│    └─────┬───────┘                         │
│          │                                  │
│   ┌──────┴──────┐                          │
│   │             │   EN (Reset)             │
│   │   ESP32     │                          │
│   │             │                          │
│   └──────┬──────┘                          │
│          │                                  │
│  ┌─ GPIO ─────────────────────────┐        │
│  │                                 │        │
│  │  GPIO 4:  DHT11 (Temp+Hum)     │        │
│  │  GPIO 34: W104 Sonido (ADC)    │        │
│  │  GPIO 2:  LED Estado            │        │
│  │  GPIO 15: (Disponible)         │        │
│  │  GPIO 13: (Disponible)         │        │
│  │                                 │        │
│  └─ UART ────────────────────────┘        │
│     │                                      │
│     ├─ TX (GPIO 1)   → Monitor Serial      │
│     └─ RX (GPIO 3)   ← Comandos           │
│                                             │
│  Power Supply:  5V USB → Regulator → 3.3V │
│  Consumo:       80-160 mA                  │
│                                             │
└─────────────────────────────────────────────┘
```

---

## ✅ CHECKLIST PRE-DESPLIEGUE

```
ANTES DE EJECUTAR deploy-thingsboard-raspberry.sh:
  ☐ Raspberry Pi conectada a LAN (cable o WiFi)
  ☐ SSH accesible: ssh innvoid@192.168.4.177
  ☐ Docker y docker-compose v2+ instalados
  ☐ ~20GB espacio libre en Raspberry
  ☐ 4GB RAM disponible (8GB recomendable)
  ☐ Internet para descargar imágenes Docker

DESPUÉS DE DESPLEGAR THINGSBOARD:
  ☐ Acceder a http://192.168.4.177:8080
  ☐ Login con sysadmin@thingsboard.org
  ☐ Ver página de inicio sin errores
  ☐ Verificar servicios en status page

ANTES DE REGISTRAR ESP32:
  ☐ ThingsBoard corriendo en Raspberry
  ☐ Acceso SSH funcional
  ☐ Red WiFi asignada al ESP32
  ☐ Arduino IDE o PlatformIO listo

DESPUÉS DE REGISTRAR ESP32:
  ☐ Dispositivo visible en Devices
  ☐ Access Token generado
  ☐ Código Arduino copiado
  ☐ Sensores calibrados (opcional)

ANTES DE CARGAR EN ESP32:
  ☐ ESP32 conectado por USB
  ☐ Driver CH340/FT232 instalado
  ☐ Arduino IDE detecta puerto
  ☐ WiFi password correcto
  ☐ Token MQTT copiado

DESPUÉS DE CARGAR ESP32:
  ☐ Monitor serial muestra WiFi conectado
  ☐ "Telemetría enviada: ✓" en serial
  ☐ Datos llegan a ThingsBoard en <5 seg
  ☐ Temperature/Humidity/Sound visibles

ANTES DE DESPLEGAR getmarket-iot:
  ☐ ESP32 funcionando con ThingsBoard
  ☐ ConfigMap actualizado en k3s
  ☐ Código ThingsBoardService implementado
  ☐ Endpoints REST creados

DESPUÉS DE DESPLEGAR getmarket-iot:
  ☐ Pod ejecutándose sin errores
  ☐ Health check conecta con ThingsBoard
  ☐ GET /devices retorna lista
  ☐ GET /devices/{id}/telemetry retorna datos
```

---

## 📞 NÚMEROS DE CONTACTO RÁPIDO

```
SI ALGO FALLA:

1. ThingsBoard no inicia
   → Ver logs: docker compose logs tb-core1
   → Espacio disco: df -h
   → Memoria: free -h

2. ESP32 no envía datos
   → Ver monitor serial (115200 baud)
   → Verificar WiFi SSID y password
   → Ping a 192.168.4.177 desde ESP32

3. getmarket-iot tiene errores
   → Logs: kubectl logs deployment/getmarket-iot
   → Health: curl localhost:3000/health/thingsboard
   → ConfigMap: kubectl get configmap getmarket-iot-config

4. Conexión rechazada
   → Firewall: sudo ufw status
   → Puerto bloqueado: ss -tulpn | grep 8080
   → SSH sin clave: ssh-keygen + ssh-copy-id
```

---

## 🎓 CONCEPTOS CLAVE

| Término | Significado |
|---------|------------|
| **MQTT** | Protocolo ligero para IoT (Pub/Sub) |
| **Device** | Entidad física (ESP32, sensor) en ThingsBoard |
| **Telemetry** | Datos de sensores (temperatura, humedad) |
| **Access Token** | Credencial para que dispositivo envíe datos |
| **Rule Engine** | Procesamiento automático de datos |
| **Tenant** | Aislamiento de datos multi-usuario |
| **Kafka** | Bus de mensajes para comunicación interna |
| **RPC** | Llamada remota (orden desde servidor a dispositivo) |

---

**🚀 ¡LISTO PARA COMENZAR!**

Archivo inicial: `PLAN_EJECUCION.md`

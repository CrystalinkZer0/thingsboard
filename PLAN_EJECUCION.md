# 🚀 PLAN DE EJECUCIÓN: ThingsBoard + ESP32 + getmarket-iot

**Estado**: Documentación completa ✅  
**Fecha**: Febrero 5, 2026  
**Raspberry**: 192.168.4.177 (innvoid)

---

## 📋 Archivos Creados

```
✅ docker/deploy-thingsboard-raspberry.sh
   → Script de despliegue automático a Raspberry

✅ docker/register-esp32.sh  
   → Registrador interactivo de ESP32

✅ GUIA_DEPLOYMENT_IOT_COMPLETO.md
   → Guía paso a paso con ejemplos de código

✅ THINGSBOARD_INTEGRATION.md (ya existía)
   → Integración entre getmarket-iot y ThingsBoard
```

---

## 🎯 Próximos Pasos (En Orden)

### FASE 1: Desplegar ThingsBoard en Raspberry ✓ PREPARADO

```bash
cd /Users/pedrovalenzuela/Documents/Innvoid/Desarrollo/thingsboard

# 1. Compilar imagen (10-15 minutos, se puede hacer ahora)
export MAVEN_OPTS="-Xmx1024m"
mvn clean install -DskipTests -T2

# 2. Ejecutar despliegue (5-10 minutos)
cd docker
./deploy-thingsboard-raspberry.sh

# ⏳ El script verificará conectividad, copiará archivos y levantará contenedores
```

**Lo que hará**:
- Conectar a Raspberry por SSH
- Crear estructura de directorios
- Copiar archivos Docker
- Levantar: PostgreSQL, Kafka, Valkey, ThingsBoard Core, Transports
- Verificar servicios

**Verificación**:
```bash
# Ver estado
ssh innvoid@192.168.4.177 "cd ~/docker-projects/thingsboard/docker && docker compose ps"

# Acceder a interfaz web
# Abre en navegador: http://192.168.4.177:8080
# Login: sysadmin@thingsboard.org / sysadmin
```

---

### FASE 2: Registrar ESP32 en ThingsBoard ✓ PREPARADO

Una vez ThingsBoard esté listo:

```bash
cd /Users/pedrovalenzuela/Documents/Innvoid/Desarrollo/thingsboard/docker
./register-esp32.sh

# El script pedirá:
# - URL: http://192.168.4.177:8080
# - Usuario: sysadmin@thingsboard.org
# - Contraseña: sysadmin
```

**Lo que hará**:
- ✅ Crear dispositivo "ESP32_IoT_Sensors"
- ✅ Generar Access Token
- ✅ Configurar atributos
- ✅ Mostrar código Arduino ejemplo
- ✅ Verificar que datos llegan

**Resultado**: Obtendrás un Access Token para configurar en ESP32

---

### FASE 3: Cargar Código en ESP32 ✓ PREPARADO

El script `register-esp32.sh` generará código Arduino.

```bash
1. Copiar código generado al Arduino IDE
2. Cambiar WiFi SSID y Password
3. Cambiar MQTT Token (del paso FASE 2)
4. Compilar y cargar (115200 baud)
5. Verificar en monitor serial que conecta
```

**Datos que viste enviarse**:
- `temperature` (°C)
- `humidity` (%)
- `soundLevel` (0-4095)

---

### FASE 4: Conectar getmarket-iot ✓ PREPARADO

Una vez todo funcione:

```bash
cd /Users/pedrovalenzuela/Documents/Innvoid/Desarrollo/getmarket-iot

# 1. Actualizar .env o ConfigMap con:
THINGSBOARD_HOST=192.168.4.177
THINGSBOARD_PORT=8080
THINGSBOARD_USERNAME=tenant@thingsboard.org
THINGSBOARD_PASSWORD=tenant

# 2. Implementar ThingsBoardService (ver documento adjunto)
# 3. Deployar en k3s
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/deployment.yaml

# 4. Verificar conectividad
curl http://localhost:3000/health/thingsboard
# Resultado: {"status":"healthy","thingsboard":"connected"}
```

---

## ⚠️ PUNTOS CRÍTICOS

### 1. Memoria en Raspberry
ThingsBoard es demandante. Monitorear:
```bash
ssh innvoid@192.168.4.177 "free -h"
ssh innvoid@192.168.4.177 "docker stats"
```

### 2. Persistencia de Datos
Los datos de ThingsBoard se guardan en volúmenes Docker:
```bash
ssh innvoid@192.168.4.177 "docker volume ls | grep thingsboard"
```

Para hacer backup:
```bash
ssh innvoid@192.168.4.177 "cd ~/docker-projects/thingsboard/docker && \
docker compose exec -T postgres pg_dump -U postgres -d thingsboard > backup.sql"
```

### 3. Conectividad Red
Verificar que todos estén en la misma red:
- Mac: En la red WiFi local
- Raspberry: En la red 192.168.4.x
- ESP32: Conectado a HOP85 WiFi

```bash
# Verificar desde Mac
ping 192.168.4.177

# Verificar desde Raspberry
ssh innvoid@192.168.4.177 "ip addr show | grep 192.168"
```

---

## 📊 ARQUITECTURA FINAL

```
┌─────────────────────────────────────────────────────────────┐
│                      Tu Red WiFi (HOP85)                    │
│  192.168.4.0/24                                              │
└──────┬────────────────────────┬───────────────────┬──────────┘
       │                        │                   │
       ▼                        ▼                   ▼
   ┌──────────┐          ┌──────────────┐      ┌─────────┐
   │   Mac    │          │  Raspberry   │      │  ESP32  │
   │          │          │  192.168.4.177      │ WiFi    │
   │          │          │              │      │         │
   │ getmarket│          │ ThingsBoard  │      │ Sensores│
   │   -iot   │          │ + PostgreSQL │      │ MQTT    │
   └──────────┘          │ + Kafka      │      │         │
        ▲                │ + Valkey     │      │         │
        │                └──────┬───────┘      └────┬────┘
        │                       │                   │
        │                       │ REST/HTTP         │ MQTT:1883
        │                       │ :8080             │
        └───────────────────────┴───────────────────┘
                    API REST Calls +
                    Device Telemetry
```

**Flujos de Datos**:
1. **ESP32 → ThingsBoard**: MQTT (temperatura, humedad, sonido)
2. **getmarket-iot → ThingsBoard**: REST API (leer dispositivos/datos)
3. **ThingsBoard → getmarket-iot**: Webhooks/API (procesamiento de reglas)

---

## 🔍 VERIFICACIÓN POR FASE

### ✓ Fase 1: ThingsBoard Corriendo
```bash
curl http://192.168.4.177:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"sysadmin@thingsboard.org","password":"sysadmin"}'

# Resultado: {"token":"eyJhbGc..."}
```

### ✓ Fase 2: ESP32 Registrado
```bash
# En ThingsBoard Web:
# Devices → ESP32_IoT_Sensors → Latest Telemetry
# Debe mostrar datos en tiempo real
```

### ✓ Fase 3: ESP32 Enviando Datos
```bash
# Verificar en logs del ESP32:
# "Telemetría enviada: ✓"

# En ThingsBoard, datos frescos en:
# - temperature
# - humidity  
# - soundLevel
# - timestamp
```

### ✓ Fase 4: getmarket-iot Conectado
```bash
curl http://localhost:3000/health/thingsboard

# Resultado: {
#   "status": "healthy",
#   "thingsboard": "connected"
# }
```

---

## 📞 SOPORTE & TROUBLESHOOTING

### Problema: SSH pide contraseña
Configurar clave SSH sin contraseña:
```bash
ssh-keygen -t rsa -N "" -f ~/.ssh/raspberry_key
ssh-copy-id -i ~/.ssh/raspberry_key.pub innvoid@192.168.4.177
```

### Problema: No hay espacio en Raspberry
```bash
# Limpiar imágenes Docker viejas
ssh innvoid@192.168.4.177 "docker image prune -a"

# Limpiar volúmenes
ssh innvoid@192.168.4.177 "docker volume prune"
```

### Problema: Puerto 8080 ya en uso
```bash
# Cambiar puerto en deploy-thingsboard-raspberry.sh
# Buscar "8080" y cambiar a otro puerto (ej: 8090)
```

---

## 📚 DOCUMENTACIÓN GENERADA

| Archivo | Propósito |
|---------|-----------|
| `GUIA_DEPLOYMENT_IOT_COMPLETO.md` | Guía paso a paso con ejemplos |
| `THINGSBOARD_INTEGRATION.md` | Configuración getmarket-iot |
| `deploy-thingsboard-raspberry.sh` | Automatizar despliegue |
| `register-esp32.sh` | Registro automático ESP32 |

---

## ⏱️ ESTIMADO DE TIEMPO

| Fase | Tarea | Tiempo |
|------|-------|--------|
| 1 | Compilar ThingsBoard | 15 min |
| 1 | Desplegar a Raspberry | 10 min |
| 1 | Verificar acceso | 5 min |
| 2 | Registrar ESP32 | 5 min |
| 3 | Cargar en ESP32 | 10 min |
| 3 | Verificar datos | 5 min |
| 4 | Configurar getmarket-iot | 10 min |
| 4 | Desplegar | 5 min |
| **TOTAL** | | **~65 minutos** |

---

## 🎯 ÉXITO = CUANDO...

✅ Puedas acceder a http://192.168.4.177:8080  
✅ ESP32 apareça en Devices con datos en tiempo real  
✅ getmarket-iot responda en /health/thingsboard  
✅ Veas datos de temperatura/humedad/sonido en ThingsBoard  
✅ Puedas crear reglas de procesamiento en ThingsBoard  

---

**¿Listo para comenzar? Ejecuta**:
```bash
cd /Users/pedrovalenzuela/Documents/Innvoid/Desarrollo/thingsboard
./docker/deploy-thingsboard-raspberry.sh
```

**¿Preguntas sobre algún paso?** Consulta:
- `GUIA_DEPLOYMENT_IOT_COMPLETO.md` - Detalles completos
- `THINGSBOARD_INTEGRATION.md` - Integración getmarket-iot
- Aquí puedo revisar logs específicos

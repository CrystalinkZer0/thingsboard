# ⚡ INICIO RÁPIDO - ESP32 → ThingsBoard

## ✅ Ya Completado

```
✓ Dispositivo creado en ThingsBoard: ESP32_IoT_Sensors
✓ Access Token: iY4xA8dhAmxTrc8yF0mF
✓ Protocolo: MQTT
✓ Código generado en: esp32-thingsboard/
```

---

## 🚀 Próximos 3 Pasos (5 minutos)

### 1️⃣ Configurar WiFi Password

```bash
# Abrir archivo de configuración
code esp32-thingsboard/include/config.h

# Cambiar esta línea:
#define WIFI_PASSWORD "tu_password_wifi_aqui"
# Por:
#define WIFI_PASSWORD "PASSWORD_REAL_DE_HOP85"  # ⚠️ TU PASSWORD AQUÍ
```

### 2️⃣ Conectar Hardware

**Conexiones mínimas:**

```
DHT11:
  VCC  → ESP32: 3V3
  OUT  → ESP32: GPIO 4
  GND  → ESP32: GND

W104:
  VCC  → ESP32: 3V3
  OUT  → ESP32: GPIO 34
  GND  → ESP32: GND

LED: Ya incluido en ESP32 (GPIO 2)
```

**Ver diagrama completo:** [CONEXION_HARDWARE.md](CONEXION_HARDWARE.md)

### 3️⃣ Compilar y Subir

```bash
cd esp32-thingsboard

# Compilar
pio run

# Subir al ESP32 (conectar USB primero)
pio run --target upload

# Ver monitor serial
pio device monitor
```

**Output esperado:**

```
[WiFi] ✓ Conectado
[MQTT] ✓ Conectado
[TELEMETRY] Leyendo sensores...
[DHT11] Temperatura: 24.5 °C | Humedad: 55.2 %
[MQTT] ✓ Telemetría enviada
```

---

## 🔍 Verificar en ThingsBoard

1. **Abrir:** http://192.168.4.177
2. **Login:** sysadmin@thingsboard.org / sysadmin
3. **Ir a:** Devices → ESP32_IoT_Sensors
4. **Tab:** Latest telemetry
5. **Ver datos actualizándose cada 5 segundos** ✅

---

## 🆘 Si Algo Falla

### Script de diagnóstico automático:

```bash
cd esp32-thingsboard
./verify-setup.sh
```

### Errores comunes:

**WiFi no conecta:**

```
→ Verificar password en config.h
→ Estar cerca del router HOP85
→ HOP85 debe ser red 2.4GHz (no 5GHz)
```

**MQTT error -2:**

```
→ Verificar ThingsBoard corriendo:
  http://192.168.4.177
→ Verificar Access Token correcto
```

**DHT11 error:**

```
→ Verificar conexión GPIO 4
→ Agregar resistencia pull-up 4.7kΩ
→ Esperar 2-3 segundos tras conectar
```

---

## 📚 Documentación Completa

- [README.md](README.md) - Guía completa paso a paso
- [CONEXION_HARDWARE.md](CONEXION_HARDWARE.md) - Diagramas y troubleshooting hardware
- [config.h](include/config.h) - Configuración WiFi/ThingsBoard
- [main.cpp](src/main.cpp) - Código fuente completo

---

## 🎯 Tu Siguiente Paso

```bash
# 1. Editar password WiFi
code esp32-thingsboard/include/config.h

# 2. Conectar hardware según diagrama

# 3. Compilar y subir
cd esp32-thingsboard
pio run --target upload
pio device monitor
```

**¡3 pasos y listo! 🎉**

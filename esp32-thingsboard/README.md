# 🔌 ESP32 → ThingsBoard - Guía Completa de Conexión

## 📋 Información del Dispositivo

```
Dispositivo: ESP32_IoT_Sensors
Access Token: iY4xA8dhAmxTrc8yF0mF
Protocolo: MQTT
ThingsBoard: 192.168.4.177:1883
Red WiFi: HOP85
```

---

## 🔧 Paso 2: Configurar WiFi

Abre `include/config.h` y **modifica esta línea**:

```cpp
#define WIFI_PASSWORD "tu_password_wifi_aqui"  // ⚠️ CAMBIAR ESTO
```

Ponle la contraseña de tu red **HOP85**.

---

## 🔌 Paso 3: Conectar Hardware

### Diagrama de Conexión

```
┌─────────────────────────────────────────┐
│         ESP32 DevKit V1                 │
├─────────────────────────────────────────┤
│                                         │
│  [3V3] ────┬──────────────┬────────┐   │
│            │              │        │   │
│  [GPIO 4]──┼──┐           │        │   │ DHT11
│            │  │ DHT11     │        │   │ ┌─────┐
│  [GND] ────┼──┴──────┐    │        │   │ │ ┌─┐ │
│            │         │    │        │   │ │ │-│ │
│  [GPIO 34]─┼─────────┼────┘        │   │ │ │+│ │
│            │         │ W104        │   │ │ │S│ │
│  [GPIO 2]  │         └─────────────┘   │ │ └─┘ │
│  (LED interno)                          │ └─────┘
│                                         │
│  [GND] ────┴─────────────┴────────┘    │
│                                         │
└─────────────────────────────────────────┘
```

### Tabla de Conexiones

| Sensor/Actuador    | Pin Sensor | Pin ESP32 | Notas                      |
| ------------------ | ---------- | --------- | -------------------------- |
| **DHT11**          |            |           |                            |
| └─ VCC (Rojo)      | +          | 3V3       | Alimentación 3.3V          |
| └─ Data (Amarillo) | OUT        | GPIO 4    | Señal digital              |
| └─ GND (Negro)     | -          | GND       | Tierra                     |
| **W104 (Sonido)**  |            |           |                            |
| └─ VCC             | +          | 3V3       | Alimentación 3.3V          |
| └─ OUT             | A0         | GPIO 34   | Señal analógica (ADC1_CH6) |
| └─ GND             | -          | GND       | Tierra                     |
| **LED**            |            |           |                            |
| └─ LED interno     | -          | GPIO 2    | LED azul integrado         |

### ⚠️ Notas Importantes

1. **DHT11 necesita resistencia pull-up** (4.7kΩ - 10kΩ entre Data y VCC)
   - Algunos módulos DHT11 ya la incluyen
   - Si no funciona, agrega una resistencia

2. **GPIO 34 es solo INPUT**
   - Perfecto para sensor analógico W104
   - No puede ser OUTPUT

3. **Alimentación**
   - Todos los sensores a 3.3V (no 5V)
   - Comparte la tierra (GND común)

---

## 📦 Paso 4: Compilar y Subir

### Opción A: Desde VSCode + PlatformIO

1. **Abrir proyecto**:

   ```bash
   code /Users/pedrovalenzuela/Documents/Innvoid/Desarrollo/thingsboard/esp32-thingsboard
   ```

2. **Conectar ESP32** via USB

3. **Compilar**: Click en ✓ (checkmark) en la barra inferior

4. **Subir**: Click en → (flecha derecha) en la barra inferior

5. **Monitor Serial**: Click en 🔌 (enchufe) para ver logs

### Opción B: Desde Terminal

```bash
cd /Users/pedrovalenzuela/Documents/Innvoid/Desarrollo/thingsboard/esp32-thingsboard

# Compilar
pio run

# Subir código
pio run --target upload

# Monitor serial
pio device monitor
```

---

## 🖥️ Paso 5: Verificar en Monitor Serial

Deberías ver algo como:

```
╔══════════════════════════════════════════════════════╗
║  ESP32 → ThingsBoard MQTT                            ║
║  Device: ESP32_IoT_Sensors                           ║
╚══════════════════════════════════════════════════════╝

[SETUP] Inicializando sensor DHT11...
[WiFi] Conectando a red: HOP85
..........
[WiFi] ✓ Conectado
[WiFi] IP: 192.168.4.XXX
[WiFi] RSSI: -45 dBm
[MQTT] Servidor: 192.168.4.177:1883
[MQTT] Conectando a ThingsBoard... ✓ Conectado
[MQTT] ✓ Suscrito a attributes
[MQTT] ✓ Atributos del dispositivo enviados
[SETUP] ✓ Inicialización completa

[TELEMETRY] Leyendo sensores...
[DHT11] Temperatura: 24.5 °C | Humedad: 55.2 %
[W104] Nivel sonido: 235 ADC (5.7%) - Categoría: Bajo
[WiFi] RSSI: -46 dBm
[MQTT] ✓ Telemetría enviada (187 bytes)
```

### ❌ Si ves errores:

**Error de WiFi:**

```
[WiFi] ✗ Error de conexión
```

→ Verifica contraseña en `config.h`
→ Confirma que estás cerca del router HOP85

**Error MQTT:**

```
[MQTT] ✗ Error, estado: -2
```

→ Verifica que ThingsBoard está corriendo: `http://192.168.4.177`
→ Confirma que el Access Token es correcto
→ Verifica firewall/puertos en Raspberry Pi

**Error DHT11:**

```
[DHT11] ✗ Error de lectura
```

→ Verifica conexiones (especialmente Data en GPIO 4)
→ Agrega resistencia pull-up si no tiene
→ Espera 2-3 segundos después de conectar

---

## 📊 Paso 6: Verificar en ThingsBoard

1. **Abrir navegador**: http://192.168.4.177

2. **Login**: `sysadmin@thingsboard.org` / `sysadmin`

3. **Ir a Devices**: Menu lateral → Devices

4. **Click en "ESP32_IoT_Sensors"**

5. **Tab "Latest telemetry"**: Deberías ver:

   ```
   temperature:       24.5
   humidity:          55.2
   soundLevel:        235
   soundLevelPercent: 5.7
   soundCategory:     "Bajo"
   ledState:          false
   rssi:              -46
   errorCount:        0
   uptime:            12
   ```

6. **Actualización**: Los datos se actualizan cada 5 segundos

### ✅ Señales de Éxito

- ✓ Valores de temperatura entre 0-50°C
- ✓ Valores de humedad entre 20-90%
- ✓ soundLevel cambia cuando haces ruido
- ✓ rssi negativo (ej: -45 dBm = buena señal)
- ✓ uptime incrementa cada lectura
- ✓ errorCount = 0

---

## 🎮 Paso 7: Control Remoto del LED

### Desde ThingsBoard Dashboard:

1. **Crear Widget de Control**:
   - Devices → ESP32_IoT_Sensors → Add widget
   - Control widgets → Switch (o Button)
   - Configurar:
     - Attribute: `ledControl`
     - Values: `"on"`, `"off"`, `"blink"`

2. **Usar el Switch**:
   - ON → LED enciende
   - OFF → LED apaga
   - BLINK → LED parpadea 5 veces

### Desde MQTT (Manual):

```bash
# Encender LED
mosquitto_pub -h 192.168.4.177 -u iY4xA8dhAmxTrc8yF0mF \
  -t v1/devices/me/attributes \
  -m '{"ledControl":"on"}'

# Apagar LED
mosquitto_pub -h 192.168.4.177 -u iY4xA8dhAmxTrc8yF0mF \
  -t v1/devices/me/attributes \
  -m '{"ledControl":"off"}'

# Parpadear
mosquitto_pub -h 192.168.4.177 -u iY4xA8dhAmxTrc8yF0mF \
  -t v1/devices/me/attributes \
  -m '{"ledControl":"blink"}'
```

---

## 📈 Paso 8: Crear Dashboard

### Widgets Recomendados:

1. **Temperatura**:
   - Widget: Gauge
   - Range: 0-50°C
   - Umbrales: <15 (azul), 15-25 (verde), >25 (naranja)

2. **Humedad**:
   - Widget: Gauge
   - Range: 0-100%
   - Umbrales: <30 (rojo), 30-70 (verde), >70 (azul)

3. **Nivel de Sonido**:
   - Widget: Chart (línea temporal)
   - Key: soundLevelPercent
   - Time window: últimos 5 minutos

4. **Categoría de Sonido**:
   - Widget: Label
   - Key: soundCategory
   - Colores: Silencio (verde), Bajo (azul), Normal (amarillo), Alto (rojo)

5. **Control LED**:
   - Widget: Switch control
   - Attribute: ledControl
   - Values: on/off

6. **WiFi Signal**:
   - Widget: Indicator
   - Key: rssi
   - Umbrales: >-50 (excelente), -50 a -70 (bueno), <-70 (débil)

---

## 🐛 Troubleshooting

### Problema: No conecta a WiFi

```
Síntomas:
[WiFi] ✗ Error de conexión

Soluciones:
1. Verificar contraseña en config.h
2. Verificar que ESP32 está cerca del router
3. Reiniciar ESP32 (botón EN)
4. Verificar que HOP85 está en 2.4GHz (ESP32 no soporta 5GHz)
```

### Problema: No conecta a MQTT

```
Síntomas:
[MQTT] ✗ Error, estado: -2

Soluciones:
1. Verificar que ThingsBoard está corriendo:
   ssh innvoid@192.168.4.177 'docker ps | grep tb-core1'

2. Verificar puerto 1883 abierto:
   telnet 192.168.4.177 1883

3. Verificar Access Token correcto en config.h

4. Ver logs ThingsBoard:
   ssh innvoid@192.168.4.177 'docker logs --tail 100 thingsboard-ce-tb-core1-1'
```

### Problema: DHT11 no lee

```
Síntomas:
[DHT11] ✗ Error de lectura
temperature: 0.0
humidity: 0.0

Soluciones:
1. Verificar conexiones:
   - VCC → 3V3 (no 5V)
   - Data → GPIO 4
   - GND → GND

2. Agregar resistencia pull-up 4.7kΩ entre Data y VCC

3. Esperar 2-3 segundos después de conectar

4. Probar con otro sensor DHT11 (puede estar dañado)
```

### Problema: Sensor de sonido siempre 0 o 4095

```
Síntomas:
soundLevel: 0 (o 4095)

Soluciones:
1. Verificar que W104 está conectado a GPIO 34 (ADC1_CH6)

2. GPIO 34 es SOLO INPUT (no puede ser OUTPUT)

3. Verificar alimentación 3.3V del sensor

4. Ajustar potenciómetro del módulo W104 (si tiene)

5. Probar con multímetro la salida del sensor
```

---

## 📝 Modificaciones Comunes

### Cambiar intervalo de envío

Editar `config.h`:

```cpp
#define TELEMETRY_INTERVAL  10000   // 10 segundos en lugar de 5
```

### Agregar más sensores

1. Editar `config.h`: agregar `#define NUEVO_SENSOR_PIN X`
2. Editar `main.cpp`: agregar lectura en `readAndSendTelemetry()`
3. Agregar key al JSON de telemetría

### Calibrar sensor de sonido

Editar `config.h`:

```cpp
#define SOUND_SILENCE       150    // Tu valor de silencio
#define SOUND_NORMAL        600    // Tu valor conversación
#define SOUND_HIGH          2000   // Tu valor ruido alto
```

---

## 📚 Archivos del Proyecto

```
esp32-thingsboard/
├── platformio.ini          # Configuración PlatformIO
├── include/
│   └── config.h            # ⚠️ EDITAR: WiFi password
├── src/
│   └── main.cpp            # Código principal
└── README.md               # Esta guía
```

---

## ✅ Checklist Final

```
[ ] WiFi password configurado en config.h
[ ] Hardware conectado (DHT11, W104)
[ ] Código compilado sin errores
[ ] Código subido al ESP32
[ ] Monitor serial muestra conexión exitosa
[ ] ThingsBoard recibe telemetría
[ ] Dashboard creado con widgets
[ ] Control remoto LED funciona
```

---

## 🆘 Ayuda Adicional

- **Documentación ThingsBoard**: https://thingsboard.io/docs/
- **PlatformIO**: https://docs.platformio.org/
- **ESP32 Pinout**: https://randomnerdtutorials.com/esp32-pinout-reference-gpios/
- **DHT11 Library**: https://github.com/adafruit/DHT-sensor-library

---

**¡Listo para enviar datos! 🎉**

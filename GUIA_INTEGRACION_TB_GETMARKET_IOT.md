# Guia paso a paso: ThingsBoard <-> getmarket-iot con ESP32

## 1) Prerrequisitos
- ThingsBoard en Docker operativo (login OK).
- getmarket-iot operativo en k3s o local.
- ESP32 Devkitv1 con firmware que publica telemetria por MQTT o HTTP.
- Red WiFi: HOP85.

## 2) Verificar conectividad ThingsBoard
Desde la maquina que tiene Docker:

```bash
curl -I -m 10 http://192.168.4.177:8080
```

Si responde, la UI esta activa.

## 3) Crear el dispositivo en ThingsBoard
1. Abrir UI: http://192.168.4.177:8080
2. Login con credenciales de tenant.
3. Ir a Devices -> Add new device.
4. Nombre: ESP32_IoT_Sensors
5. Guardar.

## 4) Obtener credenciales del dispositivo (token)
1. Abrir el dispositivo creado.
2. Ir a Device credentials.
3. Tipo: Access token.
4. Copiar el token (se usara en el ESP32 y/o en getmarket-iot).

**VALORES ACTUALES:**
- Device UUID: `7f518fd0-02d4-11f1-858f-f53c4c194ba5`
- Access Token: `iY4xA8dhAmxTrc8yF0mF`

## 5) Configurar el ESP32 para enviar telemetria
### Opcion A: MQTT (recomendado)
- Host: 192.168.4.177
- Puerto: 1883
- Topic: v1/devices/me/telemetry
- Token: el Access Token del dispositivo

Payload JSON (ejemplo):
```json
{
  "temperature": 24.3,
  "humidity": 56.1,
  "soundLevel": 345,
  "soundLevelPercent": 8.4,
  "ledState": true,
  "rssi": -62,
  "errorCount": 0
}
```

### Opcion B: HTTP
- URL: http://192.168.4.177:8080/api/v1/<ACCESS_TOKEN>/telemetry
- Metodo: POST
- Headers: Content-Type: application/json

Payload JSON igual al anterior.

## 6) Definir atributos compartidos (control remoto)
Estos atributos se escriben desde ThingsBoard y los lee el ESP32:
- ledControl: "on" | "off" | "blink"
- blinkInterval: 100-2000
- sensorInterval: 1000-10000

Ejemplo para setear atributos:

```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -H "X-Authorization: Bearer <JWT>" \
  http://192.168.4.177:8080/api/plugins/telemetry/DEVICE/<DEVICE_ID>/attributes/SHARED \
  -d '{"ledControl":"blink","blinkInterval":500,"sensorInterval":2000}'
```

## 7) Mapear telemetria (claves oficiales)
- temperature (float)
- humidity (float)
- soundLevel (int)
- soundLevelPercent (float)
- ledState (boolean)
- rssi (int)
- errorCount (int)

Notas:
- soundLevelPercent = (soundLevel / 4095) * 100
- Umbrales recomendados:
  - Silencio: 150-200
  - Conversacion: 200-500
  - Ruido alto: 500-1500
  - Muy alto: >1500

## 8) Dashboard en ThingsBoard
Crear un dashboard con widgets:
- Temperature: gauge (0-50)
- Humidity: gauge (0-100)
- Sound: time series chart + gauge actual
- LED control: switch/button
- RSSI: indicator

## 9) Configurar getmarket-iot para leer ThingsBoard
### ConfigMap (k8s) sugerido
```yaml
thingsboard-host: "192.168.4.177"
thingsboard-port: "8080"
thingsboard-username: "tenant@thingsboard.org"
thingsboard-password: "tenant"
```

### Endpoints usados por el microservicio
- Login: POST /api/auth/login
- Devices: GET /api/tenant/devices?pageSize=100&page=0
- Telemetria: GET /api/plugins/telemetry/DEVICE/{deviceId}/values/timeseries?keys={keys}

### Ejemplo de login
```bash
curl -X POST http://192.168.4.177:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"tenant@thingsboard.org","password":"tenant"}'
```

## 10) Validar flujo completo
1. ESP32 publica telemetria.
2. ThingsBoard muestra datos en Latest telemetry.
3. getmarket-iot puede leer esos datos via REST API.

## 11) Checklist rapido
- [ ] Dispositivo creado y token copiado
- [ ] ESP32 publica payload JSON correcto
- [ ] ThingsBoard muestra telemetria
- [ ] getmarket-iot autentica y lee datos
- [ ] Dashboard muestra valores

## 12) Siguientes pasos recomendados
- Agregar healthcheck en getmarket-iot para ThingsBoard.
- Crear cron o worker de sync si se requiere historico.
- Guardar telemetria en DB propia si aplica.

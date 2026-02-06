# 🎯 PUNTO DE INICIO - Sistema IoT Completo

**Estado**: Listo para desplegar ✅  
**Versión ThingsBoard**: 4.4.0  
**Rama Git**: getmarket-iot  

---

## 🆘 ¿Problemas al Iniciar Docker ThingsBoard?

Si ves errores como:
- ⚠️ `The "JAVA_OPTS" variable is not set`
- ❌ Contenedores restarting sin iniciar
- ❌ `Cannot connect to database`

**→ Ver**: [TROUBLESHOOTING_DOCKER_TB.md](./TROUBLESHOOTING_DOCKER_TB.md) (Soluciones rápidas)

---

## 📌 ANTES DE EMPEZAR

```bash
# 1. Verifica que estés en la rama correcta
cd /Users/pedrovalenzuela/Documents/Innvoid/Desarrollo/thingsboard
git branch

# Salida esperada: * getmarket-iot

# 2. Verifica cambios locales
git status

# Deberías ver cambios en `docker/` y `application/`
```

---

## 🚀 EJECUTA ESTO AHORA (En Orden)

### PASO 1: Desplegar ThingsBoard (15 minutos)

```bash
cd /Users/pedrovalenzuela/Documents/Innvoid/Desarrollo/thingsboard

# Compilar imagen
export MAVEN_OPTS="-Xmx1024m"
mvn clean install -DskipTests -T2

# Si todo compila sin errores, despliega:
cd docker
./deploy-thingsboard-raspberry.sh

# Espera a que termine el script
```

**Verificación**: Abre navegador → http://192.168.4.177:8080  
Deberías ver login de ThingsBoard

---

### PASO 2: Registrar ESP32 (5 minutos)

Una vez ThingsBoard esté corriendo:

```bash
cd /Users/pedrovalenzuela/Documents/Innvoid/Desarrollo/thingsboard/docker

./register-esp32.sh

# El script te pedirá:
#   URL: http://192.168.4.177:8080
#   Usuario: sysadmin@thingsboard.org
#   Contraseña: sysadmin
```

**Resultado**: Recibirás un Access Token para el ESP32

---

### PASO 3: Cargar Código en ESP32 (10 minutos)

El script anterior generó código Arduino. Ahora:

```bash
1. Abre Arduino IDE o PlatformIO
2. Crea nuevo sketch
3. Copia el código generado por el script
4. Cambiar SOLO esto:
   - const char* ssid = "HOP85";
   - const char* password = "[TU_PASSWORD_WIFI]";
   - const char* mqtt_token = "[TOKEN_DEL_SCRIPT]";
5. Compilar y cargar a ESP32
6. Abrir Monitor Serial (115200 baud)
```

**Verificación**: Monitor serial muestra:
```
WiFi conectado: 192.168.4.XXX
Conectando a MQTT... conectado!
Telemetría enviada: ✓
Temp: 25.5C, Hum: 65.3%, Sonido: 2048
```

---

### PASO 4: Verificar en ThingsBoard (2 minutos)

```bash
# Abre navegador
http://192.168.4.177:8080

# Login
Usuario: sysadmin@thingsboard.org
Password: sysadmin

# Ve a: Devices → ESP32_IoT_Sensors → Latest Telemetry

# Deberías ver datos actualizándose en tiempo real:
- temperature: 25.5
- humidity: 65.3
- soundLevel: 2048
```

---

### PASO 5: Conectar getmarket-iot (10 minutos)

```bash
cd /Users/pedrovalenzuela/Documents/Innvoid/Desarrollo/getmarket-iot

# 1. Actualizar .env
cat > .env << 'EOF'
THINGSBOARD_HOST=192.168.4.177
THINGSBOARD_PORT=8080
THINGSBOARD_USERNAME=tenant@thingsboard.org
THINGSBOARD_PASSWORD=tenant
NODE_ENV=production
PORT=3000
EOF

# 2. Implementar ThingsBoardService
# Usa código del documento THINGSBOARD_INTEGRATION.md

# 3. Crear endpoints REST (ver GUIA_DEPLOYMENT_IOT_COMPLETO.md)

# 4. Desplegar
docker build -t getmarket-iot:latest .
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/deployment.yaml

# 5. Verificar
curl http://localhost:3000/health/thingsboard
# Resultado: {"status":"healthy","thingsboard":"connected"}
```

---

## 📚 DOCUMENTACIÓN DE REFERENCIA

| Documento | Use cuando... |
|-----------|--------------|
| **[PLAN_EJECUCION.md](PLAN_EJECUCION.md)** | Necesites entender las 4 fases completas |
| **[GUIA_DEPLOYMENT_IOT_COMPLETO.md](GUIA_DEPLOYMENT_IOT_COMPLETO.md)** | Necesites detalles paso a paso con ejemplos |
| **[RESUMEN_CONFIGURACION.md](RESUMEN_CONFIGURACION.md)** | Necesites referencia rápida de puertos y APIs |
| **[THINGSBOARD_INTEGRATION.md](THINGSBOARD_INTEGRATION.md)** | Implementes código en getmarket-iot |

---

## ⚠️ TROUBLESHOOTING RÁPIDO

### ThingsBoard no inicia
```bash
# Ver por qué error
ssh innvoid@192.168.4.177 \
  "cd ~/docker-projects/thingsboard/docker && docker compose logs tb-core1 --tail 50"
```

### ESP32 no conecta a WiFi
```
Monitor Serial (115200 baud):
- Mira la red WiFi que está intentando (SSID)
- Verifica password
- Verifica que la red es 2.4GHz (ESP32 no soporta 5GHz)
```

### getmarket-iot no conecta con ThingsBoard
```bash
# Verifica que Raspberry sea accesible
ping 192.168.4.177

# Verifica credenciales
curl http://192.168.4.177:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"tenant@thingsboard.org","password":"tenant"}'
```

---

## 🎯 INDICADORES DE ÉXITO

✅ **Fase 1**: ThingsBoard accesible en http://192.168.4.177:8080  
✅ **Fase 2**: ESP32_IoT_Sensors aparece en Devices  
✅ **Fase 3**: Datos (temp, humedad, sonido) se actualizan en tiempo real  
✅ **Fase 4**: getmarket-iot responde en /health/thingsboard  

---

## 🔄 DIAGRAMA DE FLUJO

```
START
  │
  ├─► ¿ThingsBoard corriendo? 
  │   NO → `./deploy-thingsboard-raspberry.sh`
  │   SÍ → Siguiente
  │
  ├─► ¿ESP32 registrado?
  │   NO → `./register-esp32.sh`
  │   SÍ → Siguiente
  │
  ├─► ¿ESP32 enviando datos?
  │   NO → Compilar código Arduino y cargar
  │   SÍ → Siguiente
  │
  ├─► ¿Datos en ThingsBoard?
  │   NO → Ver logs de ESP32
  │   SÍ → Siguiente
  │
  ├─► ¿getmarket-iot desplegado?
  │   NO → Implementar ThingsBoardService y desplegar
  │   SÍ → ÉXITO ✅
  │
END
```

---

## ⏱️ TIEMPO TOTAL ESTIMADO: **1 HORA**

```
Compilar ThingsBoard:        15 min
Desplegar a Raspberry:       10 min
Registrar ESP32:             5 min
Cargar en ESP32:             10 min
Verificar datos:             5 min
Configurar getmarket-iot:    10 min
Desplegar getmarket-iot:     5 min
────────────────────────────
TOTAL:                       60 min
```

---

## 🎓 SI TIENES DUDAS

1. **Revisar documentación específica** (ver tabla arriba)
2. **Ejecutar script con `-v`** para modo verbose:
   ```bash
   bash -x ./deploy-thingsboard-raspberry.sh
   ```
3. **Ver logs detallados**:
   ```bash
   ssh innvoid@192.168.4.177 "docker logs -f thingsboard-ce-tb-core1-1"
   ```
4. **Prueba de conectividad básica**:
   ```bash
   ssh innvoid@192.168.4.177 "docker ps"
   ```

---

## 💡 TIPS PROFESIONALES

- ✅ **Compilar localmente, desplegar en Raspberry** → Más rápido
- ✅ **Usar SSH sin contraseña** → `ssh-keygen && ssh-copy-id`
- ✅ **Monitorizar primero** → Asegura que servicios suben antes de registrar
- ✅ **Datos lososos inicialmente** → Normal, DHT11 necesita ~2 seg entre lecturas
- ✅ **Hacer backup antes de cambios** → El script ya lo hace ✓

---

## 📱 SIGUIENTES PASOS (OPCIONAL)

Una vez todo funcione:

1. **Crear Reglas en ThingsBoard**
   - Alertas si temperatura > 30°C
   - Notificaciones por email
   - Control de LED remoto (RPC)

2. **Crear Dashboard Público**
   - Compartir datos en tiempo real
   - Exportar datos a CSV

3. **Expandir con más sensores**
   - Presión atmosférica (BMP280)
   - Luz ambiente (LDR)
   - Movimiento (PIR)

4. **Integrar con getmarket-iot**
   - API para sincronizar datos
   - Webhooks para procesamiento
   - Almacenamiento en BD propia

---

## 🎉 ¡BUENA SUERTE!

El sistema está completamente documentado. Ejecuta los pasos en orden y llegarás al éxito.

**Primer comando a ejecutar**:
```bash
cd /Users/pedrovalenzuela/Documents/Innvoid/Desarrollo/thingsboard/docker
./deploy-thingsboard-raspberry.sh
```

**¿Necesitas ayuda?** Todos los scripts tienen logs detallados. Revisa la salida.

---

**Última actualización**: Febrero 5, 2026

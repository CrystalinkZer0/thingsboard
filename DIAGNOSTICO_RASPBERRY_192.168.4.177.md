# 📊 Diagnóstico Raspberry Pi 192.168.4.177

**Fecha:** 10 de febrero de 2026  
**IP Local:** 192.168.4.177  
**Usuario:** innvoid

---

## 🔍 Estado Actual

### Hardware y Sistema Operativo

```
Sistema:     Debian (Raspberry Pi OS)
Arquitectura: aarch64 (ARM 64-bit)
Kernel:      6.12.62+rpt-rpi-2712

RAM Total:   8 GB
RAM Usada:   6.4 GB (81%)
RAM Libre:   495 MB (6%)
Swap:        2 GB (350 MB usados)

Disco Total: 234 GB
Disco Usado: 23 GB (11%)
Disco Libre: 202 GB
```

**⚠️ PROBLEMA CRÍTICO:** Uso de RAM muy alto (81%), dejando solo 495MB libres. Esto puede causar lentitud y crashes.

---

## 🐳 Servicios Docker Activos

| Servicio                 | Estado        | Uso RAM | CPU % | Problema          |
| ------------------------ | ------------- | ------- | ----- | ----------------- |
| **tb-core1**             | ✅ UP         | 1.28 GB | 4.79% | -                 |
| **tb-rule-engine1**      | ✅ UP         | 1.16 GB | 8.14% | -                 |
| **kafka**                | ✅ UP         | 1.17 GB | 6.56% | -                 |
| **tb-mqtt-transport1**   | ✅ UP         | 691 MB  | 1.34% | -                 |
| **postgres**             | ✅ UP         | 97 MB   | 0.01% | -                 |
| **zookeeper**            | ✅ UP         | 145 MB  | 0.11% | -                 |
| **tb-web-ui1**           | ✅ UP         | 27 MB   | 0.00% | -                 |
| **tb-js-executor-1**     | ✅ UP         | 19 MB   | 0.00% | -                 |
| **tb-js-executor-2**     | ✅ UP         | 29 MB   | 0.00% | -                 |
| **haproxy-certbot**      | ✅ UP         | 63 MB   | 0.14% | -                 |
| **portainer**            | ✅ UP         | 22 MB   | 0.00% | -                 |
| **tb-coap-transport-1**  | ❌ Restarting | 0 B     | -     | 🔴 **ERROR LOGS** |
| **tb-http-transport1-1** | ❌ Restarting | 0 B     | -     | 🔴 **ERROR LOGS** |

**Total RAM usada por Docker:** ~4.7 GB

---

## 🔴 Problemas Identificados

### 1. Contenedores en Loop de Reinicio

**Servicios afectados:**

- `tb-coap-transport-1`
- `tb-http-transport1-1`

**Causa raíz:** Error de permisos al intentar escribir logs

```
ERROR: java.io.FileNotFoundException: /var/log/tb-coap-transport/logback.log (Permission denied)
```

**Solución:** Las carpetas de logs tienen permisos de `root`, pero los contenedores corren con usuario diferente.

```bash
# En la Raspberry:
cd ~/docker-projects/thingsboard/docker
sudo chown -R innvoid:innvoid tb-transports/*/log
sudo chmod -R 755 tb-transports/*/log
```

---

### 2. Uso Excesivo de RAM

**Problema:** Sin límites de memoria configurados, los servicios Java consumen más RAM de lo necesario.

**Configuración actual:**

```bash
# En .env (línea comentada):
# JAVA_OPTS=-Xmx2048M -Xms2048M -Xss384k -XX:+AlwaysPreTouch
```

**Impacto:** Cada servicio Java puede crecer sin límite, consumiendo toda la RAM disponible.

**Solución:** Configurar límites específicos para cada servicio:

```bash
# Distribución optimizada para Raspberry Pi 8GB:
tb-core:         -Xmx1200M -Xms1200M
tb-rule-engine:  -Xmx1024M -Xms1024M
tb-mqtt:         -Xmx512M -Xms512M
tb-transports:   -Xmx512M -Xms512M
tb-js-executor:  -Xmx256M -Xms256M
kafka:           KAFKA_HEAP_OPTS="-Xmx768m -Xms768m"
```

---

### 3. Servicios Innecesarios Activos

**Servicios que consumen recursos sin ser usados:**

- **CoAP Transport:** Para sensores CoAP (poco común)
- **HTTP Transport:** Si solo usas MQTT, no se necesita
- **2 instancias de JS Executor:** 1 es suficiente para desarrollo

**Ahorro estimado:** ~500-800 MB RAM si se deshabilitan los no necesarios.

---

### 4. Sin Acceso Remoto Configurado

**Problema:** Solo accesible desde red local (192.168.4.x)

**Opciones disponibles:**

1. **Tailscale (RECOMENDADO)** ⭐
   - ✅ Más fácil (5 min setup)
   - ✅ Seguro (cifrado WireGuard)
   - ✅ Gratis (hasta 100 dispositivos)
   - ✅ No requiere abrir puertos en router
   - ✅ Acceso desde cualquier red (4G, WiFi público, etc.)

2. **Cloudflare Tunnel**
   - ✅ Para acceso público con dominio
   - ✅ Protección DDoS incluida
   - ⚠️ Más complejo de configurar

3. **WireGuard Manual**
   - ✅ Control total
   - ⚠️ Requiere configuración manual compleja

---

## ✅ Plan de Optimización

### Fase 1: Corrección Inmediata (5 minutos)

```bash
# Desde tu Mac:
cd /Users/pedrovalenzuela/Documents/Innvoid/Desarrollo/thingsboard/docker
./optimize-raspberry.sh
```

**Este script hará:**

1. ✅ Corregir permisos de logs
2. ✅ Configurar límites de memoria
3. ✅ Instalar Tailscale
4. ✅ Crear docker-compose optimizado
5. ✅ (Opcional) Reiniciar servicios

---

### Fase 2: Configurar Acceso Remoto (10 minutos)

**Opción A: Tailscale (Recomendado)**

```bash
# 1. En tu Mac, ejecuta el script de optimización
cd /Users/pedrovalenzuela/Documents/Innvoid/Desarrollo/thingsboard/docker
./optimize-raspberry.sh

# 2. Conecta a la Raspberry
ssh innvoid@192.168.4.177

# 3. Configura Tailscale
sudo tailscale up

# 4. Abre el link que aparece en tu navegador y autoriza

# 5. Obtén tu nueva IP privada
tailscale ip -4
# Ejemplo: 100.101.102.103

# 6. Instala Tailscale en tu Mac
brew install --cask tailscale
# O descarga desde: https://tailscale.com/download/mac

# 7. Accede desde cualquier red
# ThingsBoard: http://100.101.102.103:30080
# Portainer:   https://100.101.102.103:9443
# SSH:         ssh innvoid@100.101.102.103
```

**Opción B: Cloudflare Tunnel (Para acceso público)**

```bash
# Ver guía completa en:
cat GUIA_ACCESO_REMOTO_SEGURO.md
```

---

### Fase 3: Optimización a Largo Plazo

#### 3.1. Deshabilitar Servicios No Usados

Edita `~/docker-projects/thingsboard/docker/.env`:

```bash
# Deshabilitar transportes no utilizados
ENABLE_COAP_TRANSPORT=false      # Solo si no usas sensores CoAP
ENABLE_HTTP_TRANSPORT=false      # Solo si no usas API HTTP para dispositivos
ENABLE_LWM2M_TRANSPORT=false     # Solo si no usas LWM2M
ENABLE_SNMP_TRANSPORT=false      # Solo si no usas SNMP
```

**Ahorro:** ~500-800 MB RAM

#### 3.2. Usar Docker Compose Optimizado

```bash
cd ~/docker-projects/thingsboard/docker
docker compose down
docker compose -f docker-compose.rpi-optimized.yml up -d
```

#### 3.3. Monitoreo Automático

Crea un script de monitoreo:

```bash
# Crear archivo de monitoreo
cat > ~/monitor-resources.sh << 'EOF'
#!/bin/bash
echo "=== $(date) ==="
echo "RAM:"
free -h | grep Mem
echo ""
echo "CPU y RAM por contenedor:"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"
echo ""
EOF

chmod +x ~/monitor-resources.sh

# Ejecutar cada 5 minutos
crontab -e
# Agregar línea:
# */5 * * * * ~/monitor-resources.sh >> ~/resource-monitor.log 2>&1
```

---

## 📊 Resultados Esperados

### Antes de Optimización

```
RAM Total:   8.0 GB
RAM Usada:   6.4 GB (81%)
RAM Libre:   0.5 GB (6%)

Servicios Activos: 13
Servicios Fallando: 2
```

### Después de Optimización

```
RAM Total:   8.0 GB
RAM Usada:   ~4.5 GB (56%)
RAM Libre:   ~3.5 GB (44%)

Servicios Activos: 11
Servicios Fallando: 0
```

**Mejora:** +3 GB RAM libre (600% más memoria disponible)

---

## 🌐 Configuración para Sensores en Terreno

### Escenario: Raspberry en terreno con sensores ESP32

```
                  INTERNET
                     |
            [Tailscale VPN]
                     |
        ┌────────────┴────────────┐
        |                         |
   TU MAC/MÓVIL            RASPBERRY PI
   (100.x.x.1)             (100.x.x.177)
                                 |
                    ┌────────────┴────────────┐
                    |                         |
              ThingsBoard              Sensores ESP32
              (MQTT 1883)              (WiFi Local)
                    |                         |
                    └─────────────────────────┘
```

### Configuración de Sensores

Los ESP32 se conectan a la Raspberry por **red local** (192.168.4.177):

```cpp
// En código ESP32:
const char* mqtt_server = "192.168.4.177";
const int mqtt_port = 1883;  // Puerto mapeado por HAProxy

// O si tienes dominio configurado:
const char* mqtt_server = "tu-dominio.com";
const int mqtt_port = 1883;
```

### Acceso Administrativo

Tú accedes desde cualquier lugar vía **Tailscale** (100.x.x.177):

```bash
# Administración remota
ssh innvoid@100.x.x.177

# Ver ThingsBoard
http://100.x.x.177:30080

# Gestionar Docker
https://100.x.x.177:9443  # Portainer
```

---

## 🔒 Recomendaciones de Seguridad

### 1. Firewall en Raspberry

```bash
# Instalar UFW
sudo apt update && sudo apt install -y ufw

# Configurar reglas
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow from 192.168.4.0/24  # Red local
sudo ufw allow 1883/tcp             # MQTT para sensores
sudo ufw enable
```

### 2. Autenticación MQTT

Configura credenciales en ThingsBoard:

```bash
# En ThingsBoard UI:
1. Ir a "Devices"
2. Crear dispositivo
3. Obtener "Access Token"
4. Usar en ESP32:
   - Username: [dejar vacío]
   - Password: [Access Token]
```

### 3. Backup Automático

```bash
# Script de backup
cat > ~/backup-thingsboard.sh << 'EOF'
#!/bin/bash
BACKUP_DIR=~/backups/$(date +%Y%m%d)
mkdir -p $BACKUP_DIR

# Backup PostgreSQL
docker exec thingsboard-ce-postgres-1 pg_dumpall -U postgres > $BACKUP_DIR/postgres.sql

# Backup configuración
cp -r ~/docker-projects/thingsboard/docker/*.env $BACKUP_DIR/

# Mantener solo últimos 7 días
find ~/backups/ -type d -mtime +7 -exec rm -rf {} \;
EOF

chmod +x ~/backup-thingsboard.sh

# Ejecutar diariamente a las 2 AM
crontab -e
# Agregar: 0 2 * * * ~/backup-thingsboard.sh
```

---

## 📞 Solución de Problemas

### Si los servicios no inician

```bash
# Ver logs
docker logs thingsboard-ce-tb-core1-1 --tail 50

# Reiniciar servicios específicos
docker restart thingsboard-ce-tb-core1-1

# Reiniciar todo
cd ~/docker-projects/thingsboard/docker
docker compose down && docker compose up -d
```

### Si no hay conexión remota

```bash
# Verificar Tailscale
tailscale status
tailscale ping 100.x.x.177

# Reiniciar Tailscale
sudo systemctl restart tailscaled
sudo tailscale up
```

### Si los sensores no conectan

```bash
# Verificar MQTT
docker logs thingsboard-ce-tb-mqtt-transport1-1

# Probar conexión MQTT
mosquitto_pub -h 192.168.4.177 -p 1883 -t "test" -m "hello"

# Ver puertos abiertos
sudo netstat -tlnp | grep 1883
```

---

## 📚 Documentación Relacionada

- [GUIA_ACCESO_REMOTO_SEGURO.md](GUIA_ACCESO_REMOTO_SEGURO.md) - Opciones de acceso remoto
- [GUIA_DESPLIEGUE_RASPBERRY.md](GUIA_DESPLIEGUE_RASPBERRY.md) - Gestión remota
- [GUIA_HIBRIDA_TAILSCALE_NGINX.md](GUIA_HIBRIDA_TAILSCALE_NGINX.md) - Configuración híbrida
- [MANUAL_CONFIGURACION.md](MANUAL_CONFIGURACION.md) - Configuración detallada

---

## ⚡ Inicio Rápido

```bash
# 1. Optimizar sistema (desde tu Mac)
cd /Users/pedrovalenzuela/Documents/Innvoid/Desarrollo/thingsboard/docker
./optimize-raspberry.sh

# 2. Configurar acceso remoto (en la Raspberry)
ssh innvoid@192.168.4.177
sudo tailscale up
tailscale ip -4

# 3. Instalar Tailscale en tu Mac
brew install --cask tailscale

# 4. Acceder desde cualquier lado
# http://[IP_TAILSCALE]:30080
```

**Tiempo total:** ~15 minutos  
**Ahorro de RAM:** ~3 GB (60% más disponible)  
**Resultado:** Sistema estable y accesible desde cualquier red

---

**🎯 Próximos Pasos Recomendados:**

1. ✅ Ejecutar script de optimización
2. ✅ Configurar Tailscale
3. ✅ Probar acceso remoto
4. ✅ Configurar sensores ESP32
5. ✅ Configurar backup automático
6. ✅ Monitorear uso de recursos durante 24-48h

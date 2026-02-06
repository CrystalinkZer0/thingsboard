# 🔄 Arquitectura Híbrida: Tailscale + Nginx

## 🎯 Caso de Uso

**Tu escenario:**
- Raspberry Pi como servidor de desarrollo del ERP
- Equipo de desarrollo necesita acceso seguro (SSH, Portainer, k8s)
- Usuarios finales necesitan acceder a APIs públicas desde web
- Dispositivos IoT (ESP32) envían datos a ThingsBoard

**Solución:** Acceso dual con capas de seguridad

---

## 📐 Arquitectura

```
                    INTERNET
                       |
        ┌──────────────┼──────────────┐
        |              |              |
    DESARROLLO    USUARIOS FINALES   ESP32
    (Tailscale)   (Nginx + HTTPS)   (MQTT TLS)
        |              |              |
        └──────────────┴──────────────┘
                       |
                 RASPBERRY PI
                       |
        ┌──────────────┴──────────────┐
        |                             |
    ThingsBoard                 ERP/Microservicios
    (k8s)                       (getmarket-iot)
        |                             |
        └──────────────┬──────────────┘
                       |
                  PostgreSQL
```

---

## 🔒 Tabla de Accesos

| Usuario/Servicio | Método | Puerto/URL | Uso |
|------------------|--------|------------|-----|
| **Desarrollo** | Tailscale VPN | 100.x.x.x | Admin, SSH, Portainer |
| **Usuarios Web** | Nginx HTTPS | https://api.tudominio.com | Consultar datos ERP |
| **ESP32/IoT** | Nginx MQTTS | tudominio.com:8883 | Enviar telemetría |
| **APIs Públicas** | Nginx HTTPS | https://api.tudominio.com/api/ | REST APIs |

---

## 🚀 Instalación Rápida

### 1. Ejecutar Script de Configuración

```bash
cd /Users/pedrovalenzuela/Documents/Innvoid/Desarrollo/thingsboard/docker

# Configurar todo (Tailscale + Nginx + SSL)
chmod +x setup-hybrid-access.sh
./setup-hybrid-access.sh api.tuempresa.com admin@tuempresa.com
```

**Requisitos previos:**
1. ✅ Dominio registrado (ej: `api.tuempresa.com`)
2. ✅ DNS apuntando a tu IP pública
3. ✅ Router con puertos 80 y 443 abiertos hacia 192.168.4.177

### 2. Verificar Configuración

```bash
# Ver IP de Tailscale
ssh innvoid@192.168.4.177 "tailscale ip -4"

# Probar Nginx
curl -I https://api.tuempresa.com

# Ver certificados SSL
ssh innvoid@192.168.4.177 "sudo certbot certificates"
```

---

## 🔧 Configuración Manual (Paso a Paso)

Si prefieres entender cada paso:

### Paso 1: Instalar Tailscale

```bash
ssh innvoid@192.168.4.177

# Instalar
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up

# Obtener IP (ejemplo: 100.101.102.103)
tailscale ip -4
```

### Paso 2: Instalar Nginx y Certbot

```bash
# Aún en SSH de Raspberry
sudo apt update
sudo apt install -y nginx certbot python3-certbot-nginx
```

### Paso 3: Configurar DNS

En tu proveedor de dominios (ej: Cloudflare, GoDaddy):

```
Tipo: A
Nombre: api.tuempresa.com
Valor: TU_IP_PUBLICA
TTL: Auto
```

Para obtener tu IP pública:
```bash
curl ifconfig.me
```

### Paso 4: Configurar Router (Port Forwarding)

Entra a tu router (generalmente 192.168.1.1):

```
Puerto Externo → Puerto Interno → IP
80  →  80  →  192.168.4.177
443 →  443 →  192.168.4.177
8883 → 8883 → 192.168.4.177 (MQTTS)
```

### Paso 5: Configurar Nginx

```bash
ssh innvoid@192.168.4.177
sudo nano /etc/nginx/sites-available/erp-apis
```

Contenido:
```nginx
# HTTP → HTTPS redirect
server {
    listen 80;
    server_name api.tuempresa.com;
    
    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }
    
    location / {
        return 301 https://$server_name$request_uri;
    }
}

# HTTPS
server {
    listen 443 ssl http2;
    server_name api.tuempresa.com;
    
    # Certbot llenará estos automáticamente
    # ssl_certificate ...
    # ssl_certificate_key ...
    
    # ThingsBoard API
    location /api/ {
        proxy_pass http://localhost:30080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
    
    # ThingsBoard Web UI
    location / {
        proxy_pass http://localhost:30080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
    
    # Tu microservicio ERP
    location /erp/ {
        proxy_pass http://localhost:30081;  # Puerto de tu servicio
        proxy_set_header Host $host;
    }
}
```

Activar:
```bash
sudo ln -s /etc/nginx/sites-available/erp-apis /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

### Paso 6: Obtener Certificado SSL

```bash
sudo certbot --nginx -d api.tuempresa.com --email admin@tuempresa.com

# Verificar auto-renovación
sudo certbot renew --dry-run
```

---

## 🔐 Configuración de Seguridad Adicional

### Rate Limiting (Prevenir DDoS)

Edita `/etc/nginx/nginx.conf`:

```nginx
http {
    # Limitar requests por IP
    limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;
    
    # En tu server block
    server {
        location /api/ {
            limit_req zone=api_limit burst=20 nodelay;
            # ... resto de configuración
        }
    }
}
```

### Fail2Ban (Bloquear ataques)

```bash
ssh innvoid@192.168.4.177

sudo apt install -y fail2ban

# Configurar para Nginx
sudo nano /etc/fail2ban/jail.local
```

Contenido:
```ini
[nginx-http-auth]
enabled = true
port = http,https
logpath = /var/log/nginx/erp-api-error.log
maxretry = 5
bantime = 3600
```

```bash
sudo systemctl restart fail2ban
```

---

## 📱 Configuración de Clientes

### Para tu Equipo de Desarrollo

**1. Instalar Tailscale:**
```bash
# Mac
brew install --cask tailscale

# Windows
# Descargar de https://tailscale.com/download/windows

# Linux
curl -fsSL https://tailscale.com/install.sh | sh
```

**2. Autenticar:**
- Abrir Tailscale
- Iniciar sesión con la misma cuenta

**3. Acceder:**
```bash
# Obtener IP de la Raspberry
tailscale status | grep raspberry

# Ejemplo: 100.101.102.103

# SSH
ssh innvoid@100.101.102.103

# Portainer
open https://100.101.102.103:9443

# kubectl remoto
export KUBECONFIG=~/.kube/raspberry-config
kubectl get pods -A
```

### Para Usuarios Finales (Web)

Simplemente acceden a:
```
https://api.tuempresa.com
```

No necesitan VPN ni configuración especial.

### Para Dispositivos IoT (ESP32)

**Configuración en PlatformIO:**

```cpp
#include <WiFi.h>
#include <PubSubClient.h>
#include <WiFiClientSecure.h>

const char* WIFI_SSID = "TuWiFi";
const char* WIFI_PASSWORD = "password";

// Público vía Nginx
const char* THINGSBOARD_HOST = "api.tuempresa.com";
const int THINGSBOARD_PORT = 8883;  // MQTTS con TLS
const char* ACCESS_TOKEN = "tu_token_de_thingsboard";

WiFiClientSecure wifiClient;
PubSubClient client(wifiClient);

void setup() {
    Serial.begin(115200);
    
    // Conectar WiFi
    WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
    while (WiFi.status() != WL_CONNECTED) {
        delay(500);
        Serial.print(".");
    }
    
    // IMPORTANTE: Permitir certificados auto-firmados (desarrollo)
    // En producción, valida el certificado correctamente
    wifiClient.setInsecure();
    
    // Configurar MQTT
    client.setServer(THINGSBOARD_HOST, THINGSBOARD_PORT);
    
    // Conectar
    while (!client.connected()) {
        Serial.println("Conectando a ThingsBoard...");
        if (client.connect("ESP32_Device", ACCESS_TOKEN, NULL)) {
            Serial.println("Conectado!");
        } else {
            Serial.print("Error: ");
            Serial.println(client.state());
            delay(5000);
        }
    }
}

void loop() {
    if (!client.connected()) {
        // Reconectar
    }
    
    // Enviar telemetría
    String payload = "{\"temperature\": 25.5, \"humidity\": 60}";
    client.publish("v1/devices/me/telemetry", payload.c_str());
    
    client.loop();
    delay(10000);  // Cada 10 segundos
}
```

---

## 🔍 Monitoreo y Logs

### Ver Logs de Nginx

```bash
# Acceso
ssh innvoid@192.168.4.177
sudo tail -f /var/log/nginx/erp-api-access.log

# Errores
sudo tail -f /var/log/nginx/erp-api-error.log

# Logs en tiempo real (ambos)
sudo tail -f /var/log/nginx/erp-api-*.log
```

### Ver Conexiones Activas

```bash
# Conexiones Tailscale
ssh innvoid@192.168.4.177
tailscale status

# Conexiones Nginx
sudo ss -tlnp | grep nginx
```

### Estadísticas de Nginx

```bash
# Configurar stub_status
sudo nano /etc/nginx/sites-available/erp-apis
```

Agregar dentro del server block:
```nginx
location /nginx_status {
    stub_status on;
    access_log off;
    allow 100.0.0.0/8;  # Solo Tailscale
    deny all;
}
```

Acceder:
```bash
curl http://100.101.102.103/nginx_status
```

---

## 🚨 Troubleshooting

### Problema: Certificado SSL no se obtiene

**Causa:** DNS no apunta correctamente o puertos cerrados

**Solución:**
```bash
# Verificar DNS
nslookup api.tuempresa.com

# Debe retornar tu IP pública

# Verificar puertos
ssh innvoid@192.168.4.177
sudo netstat -tlnp | grep :80
sudo netstat -tlnp | grep :443

# Probar desde fuera
curl -I http://api.tuempresa.com
```

### Problema: ESP32 no conecta por MQTTS

**Causa:** Certificado SSL o puerto bloqueado

**Solución:**
```bash
# Verificar puerto 8883 abierto
sudo netstat -tlnp | grep :8883

# Probar conexión MQTT
mosquitto_sub -h api.tuempresa.com -p 8883 -t "test" --capath /etc/ssl/certs/

# En ESP32, usar setInsecure() temporalmente para testing
wifiClient.setInsecure();
```

### Problema: Tailscale no encuentra dispositivos

**Solución:**
```bash
# Verificar estado
tailscale status

# Re-autenticar
sudo tailscale down
sudo tailscale up

# Ver logs
sudo journalctl -u tailscaled -f
```

---

## 📊 Comparación: Antes vs Después

| Aspecto | Solo Red Local | Híbrido (Tailscale + Nginx) |
|---------|----------------|------------------------------|
| Acceso desarrollo | Solo en oficina | Desde cualquier lugar |
| Acceso usuarios | ❌ No disponible | ✅ Web público con HTTPS |
| ESP32 remoto | ❌ No funciona | ✅ MQTTS con TLS |
| Seguridad | Red local | VPN + TLS + Firewall |
| Costo | $0 | $0 (dominio ~$10/año) |
| Complejidad | Baja | Media |

---

## 🎓 Mejores Prácticas

### 1. **Separar Ambientes**

```bash
# Desarrollo (Tailscale)
tailscale_ip=100.101.102.103
http://${tailscale_ip}:30080

# Producción (Nginx)
https://api.tuempresa.com
```

### 2. **Autenticación Fuerte**

- ThingsBoard: Cambiar contraseña por defecto
- Nginx: Configurar Basic Auth para endpoints admin:

```nginx
location /admin/ {
    auth_basic "Admin Area";
    auth_basic_user_file /etc/nginx/.htpasswd;
    proxy_pass http://localhost:9443;
}
```

Crear usuarios:
```bash
sudo apt install -y apache2-utils
sudo htpasswd -c /etc/nginx/.htpasswd admin
```

### 3. **Backups Regulares**

```bash
# Agregar a crontab
crontab -e

# Backup diario a las 3 AM
0 3 * * * /home/innvoid/backup-k8s.sh
```

---

## 📞 Comandos de Referencia Rápida

```bash
# Reiniciar servicios
ssh innvoid@192.168.4.177 "sudo systemctl restart nginx"

# Ver certificados
ssh innvoid@192.168.4.177 "sudo certbot certificates"

# Renovar certificado manualmente
ssh innvoid@192.168.4.177 "sudo certbot renew"

# Ver pods
ssh innvoid@192.168.4.177 "export KUBECONFIG=~/.kube/config && kubectl get pods -A"

# Ver IP Tailscale
ssh innvoid@192.168.4.177 "tailscale ip -4"
```

---

## ✅ Checklist de Configuración

- [ ] Dominio registrado y DNS configurado
- [ ] Puertos 80, 443, 8883 abiertos en router
- [ ] Tailscale instalado en Raspberry
- [ ] Tailscale instalado en laptops del equipo
- [ ] Nginx configurado y funcionando
- [ ] Certificado SSL obtenido (Let's Encrypt)
- [ ] ThingsBoard accesible vía HTTPS
- [ ] ESP32 conectando por MQTTS
- [ ] Firewall (UFW) configurado
- [ ] Fail2Ban instalado (opcional)
- [ ] Rate limiting configurado
- [ ] Backups automatizados
- [ ] Documentación del equipo actualizada

---

## 🚀 Próximos Pasos

1. **Desplegar getmarket-iot en k3s**
2. **Configurar CI/CD** para deployments automáticos
3. **Monitoreo** con Prometheus + Grafana
4. **Alertas** vía email/Slack cuando servicios caen
5. **Escalado horizontal** cuando crezca el tráfico

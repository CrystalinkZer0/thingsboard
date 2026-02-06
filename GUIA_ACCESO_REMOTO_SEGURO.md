# 🔒 Guía de Acceso Remoto Seguro a ThingsBoard

## 🎯 Tu Pregunta

**¿Puedo conectarme desde otra red manteniendo la seguridad de los datos?**

**Respuesta:** Sí, pero necesitas configurar una de estas soluciones. Ahora mismo solo tienes acceso local (192.168.4.x).

---

## 📊 Comparación de Soluciones

| Solución | Seguridad | Facilidad | Costo | Recomendado Para |
|----------|-----------|-----------|-------|------------------|
| **Tailscale** ⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | Gratis | Acceso personal/equipo pequeño |
| **WireGuard** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | Gratis | Control total, configuración manual |
| **Cloudflare Tunnel** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | Gratis | Acceso público con protección |
| **Reverse Proxy + Let's Encrypt** | ⭐⭐⭐⭐ | ⭐⭐ | Gratis | Producción con dominio propio |
| **Port Forwarding** | ⭐ | ⭐⭐⭐⭐ | Gratis | ❌ NO RECOMENDADO (inseguro) |

---

## 1️⃣ Tailscale (RECOMENDADO) ⭐

### ¿Por qué Tailscale?
- ✅ **Más fácil de configurar** (5 minutos)
- ✅ **Zero-trust networking** (cada dispositivo se autentica)
- ✅ **Cifrado punto a punto** (WireGuard bajo el capó)
- ✅ **Gratis para uso personal** (hasta 100 dispositivos)
- ✅ **Multi-plataforma** (Mac, Windows, Linux, iOS, Android)
- ✅ **Sin abrir puertos en router**
- ✅ **IPs privadas estables** (100.x.x.x)

### Instalación

#### En Raspberry Pi:
```bash
ssh innvoid@192.168.4.177

# Instalar Tailscale
curl -fsSL https://tailscale.com/install.sh | sh

# Iniciar y autenticar
sudo tailscale up

# Abrir el link que aparece en un navegador y autorizar
# Ejemplo: https://login.tailscale.com/a/xxxxx

# Ver tu IP de Tailscale
tailscale ip -4
# Ejemplo: 100.101.102.103
```

#### En tu Mac:
```bash
# Descargar desde: https://tailscale.com/download/mac
# O con Homebrew:
brew install --cask tailscale

# Abrir Tailscale y autorizar con la misma cuenta
```

#### En tu teléfono/tablet:
- iOS: https://apps.apple.com/app/tailscale/id1470499037
- Android: https://play.google.com/store/apps/details?id=com.tailscale.ipn

### Uso

Una vez configurado:

```bash
# Desde cualquier red (4G, WiFi pública, otra casa)
# Acceder usando la IP de Tailscale de tu Raspberry

# ThingsBoard
http://100.101.102.103:30080

# MQTT
100.101.102.103:31883

# SSH seguro
ssh innvoid@100.101.102.103

# Portainer
https://100.101.102.103:9443
```

**Beneficios:**
- 🔒 Todo el tráfico cifrado (WireGuard)
- 🌐 Acceso desde cualquier red sin configurar router
- 📱 Funciona en datos móviles
- 👥 Puedes invitar a otros usuarios de tu equipo

---

## 2️⃣ WireGuard (Control Total)

### ¿Cuándo usar WireGuard?
- ✅ Quieres control total de la configuración
- ✅ No quieres depender de servicios de terceros
- ✅ Necesitas rendimiento máximo

### Instalación

```bash
ssh innvoid@192.168.4.177

# Instalar WireGuard
sudo apt install wireguard -y

# Generar claves del servidor
wg genkey | sudo tee /etc/wireguard/server_private.key
sudo cat /etc/wireguard/server_private.key | wg pubkey | sudo tee /etc/wireguard/server_public.key

# Configurar servidor
sudo nano /etc/wireguard/wg0.conf
```

**Contenido de `/etc/wireguard/wg0.conf`:**
```ini
[Interface]
Address = 10.200.200.1/24
ListenPort = 51820
PrivateKey = <CONTENIDO_DE_server_private.key>
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

# Cliente 1 (Tu Mac)
[Peer]
PublicKey = <CLAVE_PUBLICA_DE_TU_MAC>
AllowedIPs = 10.200.200.2/32

# Cliente 2 (Tu teléfono)
[Peer]
PublicKey = <CLAVE_PUBLICA_DE_TU_TELEFONO>
AllowedIPs = 10.200.200.3/32
```

```bash
# Habilitar IP forwarding
echo "net.ipv4.ip_forward = 1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Iniciar WireGuard
sudo systemctl enable wg-quick@wg0
sudo systemctl start wg-quick@wg0

# Ver estado
sudo wg show
```

### Configurar Clientes

**En tu Mac:**
```bash
# Generar claves
wg genkey > ~/wireguard_private.key
cat ~/wireguard_private.key | wg pubkey > ~/wireguard_public.key

# Crear configuración
nano ~/wireguard_client.conf
```

**Contenido:**
```ini
[Interface]
Address = 10.200.200.2/24
PrivateKey = <CONTENIDO_DE_wireguard_private.key>
DNS = 1.1.1.1

[Peer]
PublicKey = <CONTENIDO_DE_server_public.key_DE_RASPBERRY>
Endpoint = TU_IP_PUBLICA:51820
AllowedIPs = 10.200.200.0/24, 192.168.4.0/24
PersistentKeepalive = 25
```

**Configurar puerto en router:**
- Abrir puerto UDP 51820 hacia 192.168.4.177

---

## 3️⃣ Cloudflare Tunnel (Acceso Web Público)

### ¿Cuándo usar Cloudflare Tunnel?
- ✅ Necesitas acceso web público (no solo tu equipo)
- ✅ Quieres HTTPS automático
- ✅ Protección DDoS incluida
- ✅ No puedes/quieres abrir puertos en router

### Instalación

```bash
ssh innvoid@192.168.4.177

# Instalar cloudflared
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64.deb
sudo dpkg -i cloudflared-linux-arm64.deb

# Autenticar (abre link en navegador)
cloudflared tunnel login

# Crear túnel
cloudflared tunnel create raspberry-thingsboard

# Anotar el Tunnel ID que aparece
# Ejemplo: a1b2c3d4-1234-5678-90ab-cdef12345678
```

**Crear configuración:**
```bash
mkdir -p ~/.cloudflared
nano ~/.cloudflared/config.yml
```

**Contenido:**
```yaml
tunnel: <TUNNEL-ID>
credentials-file: /home/innvoid/.cloudflared/<TUNNEL-ID>.json

ingress:
  # ThingsBoard
  - hostname: thingsboard.tudominio.com
    service: http://localhost:30080
    originRequest:
      noTLSVerify: true
  
  # Portainer
  - hostname: portainer.tudominio.com
    service: https://localhost:9443
    originRequest:
      noTLSVerify: true
  
  # MQTT (requiere cloudflared en cliente)
  - hostname: mqtt.tudominio.com
    service: tcp://localhost:31883
  
  # Catch-all rule (requerido)
  - service: http_status:404
```

**Configurar DNS en Cloudflare:**
```bash
# Apuntar subdominios al túnel
cloudflared tunnel route dns raspberry-thingsboard thingsboard.tudominio.com
cloudflared tunnel route dns raspberry-thingsboard portainer.tudominio.com
cloudflared tunnel route dns raspberry-thingsboard mqtt.tudominio.com
```

**Iniciar túnel:**
```bash
# Probar
cloudflared tunnel run raspberry-thingsboard

# Si funciona, configurar como servicio
sudo cloudflared service install
sudo systemctl start cloudflared
sudo systemctl enable cloudflared
```

**Acceso:**
- https://thingsboard.tudominio.com
- https://portainer.tudominio.com

⚠️ **Consideración:** Expones servicios a internet público (usa autenticación fuerte).

---

## 4️⃣ Reverse Proxy + Let's Encrypt (Producción)

### Requisitos:
- Dominio propio
- IP pública estática (o DynDNS)
- Puerto 80/443 abiertos en router

### Instalación

```bash
ssh innvoid@192.168.4.177

# Instalar Nginx y Certbot
sudo apt install nginx certbot python3-certbot-nginx -y

# Configurar Nginx
sudo nano /etc/nginx/sites-available/thingsboard
```

**Contenido:**
```nginx
# Redirigir HTTP a HTTPS
server {
    listen 80;
    server_name thingsboard.tudominio.com;
    return 301 https://$server_name$request_uri;
}

# HTTPS
server {
    listen 443 ssl http2;
    server_name thingsboard.tudominio.com;

    # Let's Encrypt configurará esto automáticamente
    # ssl_certificate /etc/letsencrypt/live/thingsboard.tudominio.com/fullchain.pem;
    # ssl_certificate_key /etc/letsencrypt/live/thingsboard.tudominio.com/privkey.pem;

    location / {
        proxy_pass http://localhost:30080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

```bash
# Habilitar sitio
sudo ln -s /etc/nginx/sites-available/thingsboard /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx

# Obtener certificado SSL (automático)
sudo certbot --nginx -d thingsboard.tudominio.com

# Auto-renovación (ya configurado)
sudo systemctl status certbot.timer
```

**Configurar router:**
- Puerto 80 → 192.168.4.177:80
- Puerto 443 → 192.168.4.177:443

---

## 🆚 Comparación Detallada

### Seguridad

| Característica | Tailscale | WireGuard | Cloudflare | Reverse Proxy |
|----------------|-----------|-----------|------------|---------------|
| Cifrado | ✅ WireGuard | ✅ WireGuard | ✅ TLS 1.3 | ✅ TLS 1.3 |
| Autenticación | ✅ OAuth | ⚠️ Claves | ✅ Cloudflare | ⚠️ App-level |
| Zero-trust | ✅ Sí | ⚠️ Manual | ❌ No | ❌ No |
| Puertos expuestos | ✅ Ninguno | ⚠️ 51820 UDP | ✅ Ninguno | ⚠️ 80, 443 |

### Facilidad de Uso

| Aspecto | Tailscale | WireGuard | Cloudflare | Reverse Proxy |
|---------|-----------|-----------|------------|---------------|
| Setup inicial | 5 min | 30 min | 20 min | 45 min |
| Agregar dispositivo | 2 min | 10 min | 5 min | N/A |
| Mantenimiento | Automático | Manual | Bajo | Medio |
| Requiere IP pública | ❌ No | ✅ Sí | ❌ No | ✅ Sí |

---

## 🎯 Recomendación Final

### Para tu caso (ESP32 → ThingsBoard → Microservicio):

**OPCIÓN 1: Tailscale (Más simple) ⭐⭐⭐⭐⭐**

```bash
# 1. Instalar en Raspberry
ssh innvoid@192.168.4.177
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up

# 2. Instalar en tu Mac
brew install --cask tailscale

# 3. Usar IP de Tailscale
TAILSCALE_IP=$(ssh innvoid@192.168.4.177 "tailscale ip -4")
echo "ThingsBoard: http://${TAILSCALE_IP}:30080"
echo "MQTT: ${TAILSCALE_IP}:31883"

# 4. Configurar ESP32 con la IP de Tailscale
# (Si el ESP32 está en la misma red local, usa 192.168.4.177)
```

**OPCIÓN 2: Cloudflare Tunnel (Para acceso web público)**

Si necesitas que clientes externos accedan (no solo tú):
- ThingsBoard web: Cloudflare Tunnel
- MQTT devices (ESP32): Mantener en red local o VPN

**OPCIÓN 3: Híbrido (Recomendado para producción)**

```
ESP32 (red local) -----> ThingsBoard (k3s) -----> Microservicio
                            |
                            |
                         Tailscale (para administración)
                         Cloudflare (para usuarios web)
```

---

## 🔧 Scripts de Instalación Rápida

### Script: Instalar Tailscale

```bash
#!/bin/bash
# install-tailscale.sh

echo "🔒 Instalando Tailscale en Raspberry Pi..."

ssh innvoid@192.168.4.177 << 'EOF'
  curl -fsSL https://tailscale.com/install.sh | sh
  sudo tailscale up
  echo ""
  echo "✅ Tailscale instalado!"
  echo "IP de Tailscale:"
  tailscale ip -4
  echo ""
  echo "Configura Tailscale en tu Mac desde: https://tailscale.com/download/mac"
EOF
```

### Script: Verificar Acceso

```bash
#!/bin/bash
# check-access.sh

echo "🔍 Verificando acceso a ThingsBoard..."

# Obtener IP de Tailscale
TAILSCALE_IP=$(ssh innvoid@192.168.4.177 "tailscale ip -4" 2>/dev/null)

if [ -n "$TAILSCALE_IP" ]; then
    echo "✅ Tailscale IP: $TAILSCALE_IP"
    echo "Probando acceso..."
    curl -s -o /dev/null -w "%{http_code}" "http://${TAILSCALE_IP}:30080/login"
else
    echo "⚠️  Tailscale no configurado"
    echo "Usando IP local: 192.168.4.177"
    curl -s -o /dev/null -w "%{http_code}" "http://192.168.4.177:30080/login"
fi
```

---

## 📞 Próximos Pasos

1. **Esperar a que ThingsBoard termine de iniciar** (~10 min más)
2. **Decidir solución de acceso remoto:** Tailscale (recomendado) o Cloudflare
3. **Instalar solución elegida**
4. **Configurar ESP32** con la IP correcta
5. **Integrar con microservicio getmarket-iot**

---

## ❓ FAQ

**P: ¿Puedo usar múltiples soluciones?**
R: Sí, por ejemplo: Tailscale para administración + Cloudflare para acceso público.

**P: ¿Cuál consume menos recursos?**
R: Tailscale ~20MB RAM, WireGuard ~10MB, Cloudflare ~30MB.

**P: ¿Funcionará con ESP32?**
R: ESP32 no puede correr Tailscale/VPN. Opciones:
- Mantener ESP32 en red local (192.168.4.177:31883)
- Usar Cloudflare Tunnel para MQTT
- Usar SIM con IP pública

**P: ¿Es legal usar VPN?**
R: Sí, completamente legal en Chile y la mayoría de países.

**P: ¿Qué pasa si cambio de ISP/IP pública?**
R: Tailscale y Cloudflare funcionan sin cambios. WireGuard/Reverse Proxy necesitan actualizar IP.

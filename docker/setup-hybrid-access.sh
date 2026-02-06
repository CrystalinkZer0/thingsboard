#!/bin/bash
#
# Copyright © 2016-2026 The Thingsboard Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#

# Configuración Híbrida: Tailscale + Nginx Reverse Proxy
# - Tailscale: Acceso privado para equipo de desarrollo
# - Nginx: APIs públicas con HTTPS (Let's Encrypt)
#

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

RASPBERRY_HOST="innvoid@192.168.4.177"

# Verificar parámetros
if [ "$#" -lt 1 ]; then
    echo "Uso: $0 <tu-dominio.com> [email@ejemplo.com]"
    echo ""
    echo "Ejemplo: $0 api.miempresa.com admin@miempresa.com"
    echo ""
    echo "Requisitos previos:"
    echo "  1. Dominio apuntando a tu IP pública"
    echo "  2. Puerto 80 y 443 abiertos en router → 192.168.4.177"
    exit 1
fi

DOMAIN=$1
EMAIL=${2:-"admin@${DOMAIN}"}

log_step "1. Instalando Tailscale (VPN para desarrollo)"
log_info "Esto permitirá a tu equipo acceder de forma segura..."

ssh ${RASPBERRY_HOST} << 'ENDSSH'
    # Instalar Tailscale si no está instalado
    if ! command -v tailscale &> /dev/null; then
        echo "Instalando Tailscale..."
        curl -fsSL https://tailscale.com/install.sh | sh
        sudo tailscale up
        echo ""
        echo "✅ Tailscale instalado"
    else
        echo "✅ Tailscale ya está instalado"
    fi
    
    echo "IP de Tailscale:"
    tailscale ip -4
ENDSSH

echo ""
log_step "2. Instalando Nginx y Certbot (HTTPS para APIs públicas)"

ssh ${RASPBERRY_HOST} << 'ENDSSH'
    # Actualizar e instalar
    sudo apt update
    sudo apt install -y nginx certbot python3-certbot-nginx
    
    echo "✅ Nginx y Certbot instalados"
ENDSSH

echo ""
log_step "3. Configurando Nginx para ThingsBoard y APIs del ERP"

# Crear configuración de Nginx
ssh ${RASPBERRY_HOST} "sudo tee /etc/nginx/sites-available/erp-apis > /dev/null" << EOF
# Redirigir HTTP a HTTPS
server {
    listen 80;
    server_name ${DOMAIN};
    
    # Dejar que Certbot use este bloque para validación
    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }
    
    # Redirigir todo lo demás a HTTPS
    location / {
        return 301 https://\$server_name\$request_uri;
    }
}

# HTTPS - ThingsBoard y APIs
server {
    listen 443 ssl http2;
    server_name ${DOMAIN};
    
    # Certbot configurará estos certificados automáticamente
    # ssl_certificate /etc/letsencrypt/live/${DOMAIN}/fullchain.pem;
    # ssl_certificate_key /etc/letsencrypt/live/${DOMAIN}/privkey.pem;
    
    # Configuración SSL moderna
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    
    # Headers de seguridad
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options SAMEORIGIN;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    
    # Logs
    access_log /var/log/nginx/erp-api-access.log;
    error_log /var/log/nginx/erp-api-error.log;
    
    # ThingsBoard (API pública para IoT)
    location /api/ {
        proxy_pass http://localhost:30080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    # ThingsBoard Web UI (también público)
    location / {
        proxy_pass http://localhost:30080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }
    
    # Tu microservicio getmarket-iot
    location /iot/ {
        # Cuando despliegues getmarket-iot en k8s:
        # proxy_pass http://localhost:PORT_DEL_SERVICIO;
        
        # Por ahora, retornar 503
        return 503 "Servicio en construcción";
        add_header Content-Type text/plain;
    }
    
    # Health check endpoint
    location /health {
        access_log off;
        return 200 "OK";
        add_header Content-Type text/plain;
    }
}

# Stream para MQTT (puerto 8883 con TLS)
stream {
    upstream mqtt_backend {
        server localhost:31883;
    }
    
    server {
        listen 8883 ssl;
        proxy_pass mqtt_backend;
        
        # Usar los mismos certificados de Let's Encrypt
        ssl_certificate /etc/letsencrypt/live/${DOMAIN}/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/${DOMAIN}/privkey.pem;
        
        ssl_protocols TLSv1.2 TLSv1.3;
    }
}
EOF

echo ""
log_info "Habilitando sitio..."
ssh ${RASPBERRY_HOST} << 'ENDSSH'
    sudo ln -sf /etc/nginx/sites-available/erp-apis /etc/nginx/sites-enabled/
    sudo nginx -t
    sudo systemctl restart nginx
    echo "✅ Nginx configurado"
ENDSSH

echo ""
log_step "4. Obteniendo certificado SSL de Let's Encrypt"
log_warn "IMPORTANTE: Verifica que ${DOMAIN} apunta a tu IP pública"
log_warn "Y que los puertos 80 y 443 están abiertos en tu router"

read -p "¿Continuar con la obtención del certificado? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    ssh ${RASPBERRY_HOST} << ENDSSH
        sudo certbot --nginx \
            -d ${DOMAIN} \
            --email ${EMAIL} \
            --agree-tos \
            --non-interactive \
            --redirect
        
        echo ""
        echo "✅ Certificado SSL obtenido"
        echo ""
        echo "Configurando renovación automática..."
        sudo systemctl enable certbot.timer
        sudo systemctl start certbot.timer
ENDSSH
else
    log_warn "Certificado SSL no configurado. Ejecuta manualmente:"
    log_warn "  ssh ${RASPBERRY_HOST}"
    log_warn "  sudo certbot --nginx -d ${DOMAIN}"
fi

echo ""
log_step "5. Configurando firewall (opcional pero recomendado)"
ssh ${RASPBERRY_HOST} << 'ENDSSH'
    if command -v ufw &> /dev/null; then
        echo "Configurando UFW..."
        sudo ufw allow 22/tcp comment "SSH"
        sudo ufw allow 80/tcp comment "HTTP"
        sudo ufw allow 443/tcp comment "HTTPS"
        sudo ufw allow 8883/tcp comment "MQTTS"
        sudo ufw --force enable
        echo "✅ Firewall configurado"
    else
        echo "⚠️  UFW no instalado, saltando configuración de firewall"
    fi
ENDSSH

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ CONFIGURACIÓN HÍBRIDA COMPLETADA"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🔒 Acceso Privado (Tailscale - Solo tu equipo):"
TAILSCALE_IP=$(ssh ${RASPBERRY_HOST} "tailscale ip -4" 2>/dev/null || echo "Configurar")
echo "   SSH:       ssh innvoid@${TAILSCALE_IP}"
echo "   Portainer: https://${TAILSCALE_IP}:9443"
echo "   k3s:       kubectl --kubeconfig=..."
echo ""
echo "🌐 Acceso Público (HTTPS):"
echo "   Web:       https://${DOMAIN}"
echo "   API:       https://${DOMAIN}/api/"
echo "   MQTT TLS:  ${DOMAIN}:8883"
echo ""
echo "📱 Configuración ESP32 (Desde internet):"
echo "   Host: ${DOMAIN}"
echo "   Port: 8883 (MQTTS con TLS)"
echo ""
echo "🛠️  Próximos pasos:"
echo "   1. Instalar Tailscale en tu Mac/laptop"
echo "   2. Desplegar getmarket-iot en k3s"
echo "   3. Configurar ESP32 con las credenciales"
echo ""

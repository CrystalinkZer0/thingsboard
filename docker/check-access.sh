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

# Verificar acceso a ThingsBoard desde redes remotas
#

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[!]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

RASPBERRY_HOST="innvoid@192.168.4.177"

echo "🔍 Verificando acceso a ThingsBoard..."
echo ""

# 1. Verificar red local
log_info "1. Probando red local (192.168.4.177)..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://192.168.4.177:30080/login" 2>/dev/null || echo "000")

if [ "$HTTP_CODE" = "200" ]; then
    log_info "   ✅ Red local OK - ThingsBoard respondiendo"
    LOCAL_URL="http://192.168.4.177:30080"
else
    log_warn "   ⏳ ThingsBoard aún inicializando (HTTP $HTTP_CODE)"
    LOCAL_URL="http://192.168.4.177:30080 (esperando...)"
fi

echo ""

# 2. Verificar Tailscale
log_info "2. Probando Tailscale..."
TAILSCALE_IP=$(ssh ${RASPBERRY_HOST} "tailscale ip -4" 2>/dev/null || echo "")

if [ -n "$TAILSCALE_IP" ]; then
    log_info "   ✅ Tailscale configurado"
    log_info "   IP: $TAILSCALE_IP"
    
    # Probar acceso por Tailscale
    HTTP_CODE_TS=$(curl -s -o /dev/null -w "%{http_code}" "http://${TAILSCALE_IP}:30080/login" 2>/dev/null || echo "000")
    
    if [ "$HTTP_CODE_TS" = "200" ]; then
        log_info "   ✅ Acceso remoto OK"
        TAILSCALE_URL="http://${TAILSCALE_IP}:30080"
    else
        log_warn "   ⏳ ThingsBoard aún inicializando"
        TAILSCALE_URL="http://${TAILSCALE_IP}:30080 (esperando...)"
    fi
else
    log_warn "   ⚠️  Tailscale NO configurado"
    TAILSCALE_URL="No configurado"
fi

echo ""

# 3. Verificar k3s
log_info "3. Verificando estado de k3s..."
K3S_STATUS=$(ssh ${RASPBERRY_HOST} "sudo systemctl is-active k3s" 2>/dev/null || echo "inactive")

if [ "$K3S_STATUS" = "active" ]; then
    log_info "   ✅ k3s activo"
    
    # Ver pods
    PODS=$(ssh ${RASPBERRY_HOST} "export KUBECONFIG=~/.kube/config && kubectl get pods -n thingsboard --no-headers 2>/dev/null" || echo "")
    
    if [ -n "$PODS" ]; then
        echo "   Pods de ThingsBoard:"
        echo "$PODS" | while read line; do
            echo "      $line"
        done
    fi
else
    log_error "   ✗ k3s no está activo"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 RESUMEN DE ACCESO"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🏠 Red Local:"
echo "   HTTP:  $LOCAL_URL"
echo "   MQTT:  192.168.4.177:31883"
echo "   SSH:   ssh ${RASPBERRY_HOST}"
echo ""

if [ "$TAILSCALE_URL" != "No configurado" ]; then
    echo "🔒 Remoto (Tailscale):"
    echo "   HTTP:  $TAILSCALE_URL"
    echo "   MQTT:  ${TAILSCALE_IP}:31883"
    echo "   SSH:   ssh innvoid@${TAILSCALE_IP}"
    echo ""
else
    echo "⚠️  Acceso remoto no configurado"
    echo "   Ejecuta: ./install-tailscale.sh"
    echo ""
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 4. Test de conectividad ESP32
echo "📡 Configuración para ESP32:"
echo ""
echo "En red local:"
echo '  const char* THINGSBOARD_HOST = "192.168.4.177";'
echo '  const int THINGSBOARD_PORT = 31883;'
echo ""

if [ "$TAILSCALE_URL" != "No configurado" ]; then
    echo "Si ESP32 tiene Tailscale (poco probable):"
    echo "  const char* THINGSBOARD_HOST = \"${TAILSCALE_IP}\";"
    echo '  const int THINGSBOARD_PORT = 31883;'
fi

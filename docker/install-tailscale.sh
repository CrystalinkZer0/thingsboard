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

# Instalación rápida de Tailscale en Raspberry Pi
#

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

RASPBERRY_HOST="innvoid@192.168.4.177"

log_info "🔒 Instalando Tailscale en Raspberry Pi..."

# Instalar en Raspberry
ssh ${RASPBERRY_HOST} << 'ENDSSH'
    echo "Instalando Tailscale..."
    curl -fsSL https://tailscale.com/install.sh | sh
    
    echo ""
    echo "Iniciando Tailscale..."
    sudo tailscale up
    
    echo ""
    echo "✅ Tailscale instalado!"
    echo ""
    echo "📝 Abre el link de arriba en un navegador para autenticar"
    echo ""
    echo "Cuando termines, tu IP de Tailscale será:"
    sleep 5
    tailscale ip -4
ENDSSH

log_info ""
log_info "✅ Instalación completada en Raspberry Pi"
log_info ""
log_info "📱 Ahora instala Tailscale en tus dispositivos:"
log_info "   Mac: https://tailscale.com/download/mac"
log_info "   iOS: https://apps.apple.com/app/tailscale/id1470499037"
log_info "   Android: https://play.google.com/store/apps/details?id=com.tailscale.ipn"
log_info ""
log_info "Para ver tu IP de Tailscale:"
log_info "   ssh ${RASPBERRY_HOST} 'tailscale ip -4'"

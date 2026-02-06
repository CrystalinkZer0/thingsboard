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

# Instalación de k3s (Kubernetes ligero) en Raspberry Pi
# k3s es perfecto para Raspberry Pi - consume menos recursos que Kubernetes completo
#

set -e

echo "🚀 Instalando k3s en Raspberry Pi..."

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Verificar que estamos en Raspberry Pi
if ! grep -q "Raspberry Pi" /proc/cpuinfo && ! grep -q "BCM" /proc/cpuinfo; then
    log_warn "Este script está diseñado para Raspberry Pi"
    read -p "¿Continuar de todas formas? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Actualizar sistema
log_info "Actualizando sistema..."
sudo apt-get update
sudo apt-get upgrade -y

# Habilitar cgroups (requerido para k3s)
log_info "Configurando cgroups..."
if ! grep -q "cgroup_memory=1 cgroup_enable=memory" /boot/cmdline.txt; then
    sudo sed -i '$ s/$/ cgroup_memory=1 cgroup_enable=memory/' /boot/cmdline.txt
    log_warn "cgroups configurado. Se requiere reinicio."
    NEEDS_REBOOT=true
fi

# Instalar k3s
log_info "Instalando k3s..."
curl -sfL https://get.k3s.io | sh -s - \
    --write-kubeconfig-mode 644 \
    --disable traefik \
    --disable servicelb

# Esperar a que k3s esté listo
log_info "Esperando a que k3s esté listo..."
sleep 10

# Configurar kubectl
log_info "Configurando kubectl..."
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config
export KUBECONFIG=~/.kube/config
echo "export KUBECONFIG=~/.kube/config" >> ~/.bashrc

# Verificar instalación
log_info "Verificando instalación..."
kubectl get nodes

# Instalar Helm (gestor de paquetes para Kubernetes)
log_info "Instalando Helm..."
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

log_info "✅ k3s instalado exitosamente!"
echo ""
echo "Comandos útiles:"
echo "  kubectl get nodes              # Ver nodos"
echo "  kubectl get pods --all-namespaces  # Ver todos los pods"
echo "  kubectl config view            # Ver configuración"
echo ""

if [ "$NEEDS_REBOOT" = true ]; then
    log_warn "⚠️  Se requiere reinicio para aplicar cambios de cgroups"
    echo "Ejecuta: sudo reboot"
fi

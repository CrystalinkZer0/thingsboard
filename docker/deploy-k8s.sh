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

# Despliegue a Kubernetes (k3s) en Raspberry Pi
#

set -e

RASPBERRY_HOST="innvoid@192.168.4.177"
PROJECT_NAME="thingsboard"

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar que k3s está instalado
log_info "Verificando k3s en Raspberry Pi..."
if ! ssh ${RASPBERRY_HOST} "command -v kubectl >/dev/null 2>&1"; then
    log_error "k3s no está instalado en la Raspberry Pi"
    echo "Ejecuta primero: scp install-k3s.sh ${RASPBERRY_HOST}:~ && ssh ${RASPBERRY_HOST} 'bash install-k3s.sh'"
    exit 1
fi

# Copiar manifiestos
log_info "Copiando manifiestos de Kubernetes..."
ssh ${RASPBERRY_HOST} "mkdir -p ~/k8s-deployments/${PROJECT_NAME}"
scp -r ../k8s/* ${RASPBERRY_HOST}:~/k8s-deployments/${PROJECT_NAME}/

# Aplicar manifiestos
log_info "Aplicando manifiestos..."
ssh ${RASPBERRY_HOST} "
    export KUBECONFIG=~/.kube/config
    kubectl apply -f ~/k8s-deployments/${PROJECT_NAME}/
"

# Esperar a que los pods estén listos
log_info "Esperando a que los pods estén listos..."
ssh ${RASPBERRY_HOST} "
    export KUBECONFIG=~/.kube/config
    kubectl wait --for=condition=ready pod -l app=${PROJECT_NAME} -n ${PROJECT_NAME} --timeout=300s
"

# Mostrar estado
log_info "Estado del despliegue:"
ssh ${RASPBERRY_HOST} "
    export KUBECONFIG=~/.kube/config
    echo ''
    echo 'Pods:'
    kubectl get pods -n ${PROJECT_NAME}
    echo ''
    echo 'Services:'
    kubectl get services -n ${PROJECT_NAME}
    echo ''
    echo 'Acceso:'
    echo '  HTTP: http://192.168.4.177:30080'
    echo '  MQTT: 192.168.4.177:31883'
"

log_info "✅ Despliegue completado!"

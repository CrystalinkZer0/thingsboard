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

# Script de despliegue a Raspberry Pi
# Uso: ./deploy-to-raspberry.sh [proyecto] [ambiente]
#

set -e

# Configuración
RASPBERRY_HOST="innvoid@192.168.4.177"
RASPBERRY_BASE_DIR="~/docker-projects"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Función para imprimir mensajes
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar parámetros
if [ $# -lt 1 ]; then
    log_error "Uso: $0 <proyecto> [ambiente]"
    echo "Ejemplo: $0 thingsboard production"
    exit 1
fi

PROJECT=$1
ENVIRONMENT=${2:-"development"}
PROJECT_DIR="${RASPBERRY_BASE_DIR}/${PROJECT}"

log_info "Desplegando proyecto: ${PROJECT}"
log_info "Ambiente: ${ENVIRONMENT}"

# Verificar conectividad
log_info "Verificando conectividad con Raspberry Pi..."
if ! ping -c 1 192.168.4.177 > /dev/null 2>&1; then
    log_error "No se puede conectar a la Raspberry Pi"
    exit 1
fi

# Crear estructura de directorios en Raspberry
log_info "Creando estructura de directorios..."
ssh ${RASPBERRY_HOST} "mkdir -p ${PROJECT_DIR}/{docker,backups,logs}"

# Copiar archivos del proyecto
log_info "Copiando archivos del proyecto..."
if [ -d "./${PROJECT}" ]; then
    rsync -avz --progress ./${PROJECT}/ ${RASPBERRY_HOST}:${PROJECT_DIR}/docker/
else
    log_warn "Directorio ${PROJECT} no encontrado, copiando directorio actual..."
    rsync -avz --progress --exclude='.git' --exclude='node_modules' --exclude='*.log' \
        ./ ${RASPBERRY_HOST}:${PROJECT_DIR}/docker/
fi

# Hacer backup si existe una versión anterior
log_info "Creando backup de la versión anterior..."
ssh ${RASPBERRY_HOST} "cd ${PROJECT_DIR}/docker && \
    if docker compose ps -q | grep -q .; then \
        docker compose ps -q | xargs docker inspect --format='{{.Name}}: {{.State.Status}}' > ../backups/pre-deploy-\$(date +%Y%m%d-%H%M%S).txt; \
    fi"

# Detener contenedores anteriores
log_info "Deteniendo contenedores anteriores..."
ssh ${RASPBERRY_HOST} "cd ${PROJECT_DIR}/docker && \
    docker compose down || true"

# Levantar nuevos contenedores
log_info "Levantando contenedores..."
if [ "${ENVIRONMENT}" == "production" ]; then
    log_info "Modo producción detectado"
    ssh ${RASPBERRY_HOST} "cd ${PROJECT_DIR}/docker && \
        docker compose -f docker-compose.yml -f docker-compose.postgres.yml up -d"
else
    log_info "Modo desarrollo detectado"
    ssh ${RASPBERRY_HOST} "cd ${PROJECT_DIR}/docker && \
        docker compose up -d"
fi

# Verificar estado
log_info "Verificando estado de contenedores..."
sleep 5
ssh ${RASPBERRY_HOST} "cd ${PROJECT_DIR}/docker && docker compose ps"

log_info "✅ Despliegue completado exitosamente!"
log_info "Puedes monitorear los logs con:"
echo "  ssh ${RASPBERRY_HOST} 'cd ${PROJECT_DIR}/docker && docker compose logs -f'"

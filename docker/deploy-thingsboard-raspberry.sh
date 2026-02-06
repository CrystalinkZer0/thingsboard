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

# Script de despliegue de ThingsBoard a Raspberry Pi
# Uso: ./deploy-thingsboard-raspberry.sh
#

set -e

# Configuración
RASPBERRY_HOST="innvoid@192.168.4.177"
RASPBERRY_BASE_DIR="~/docker-projects"
PROJECT="thingsboard"
PROJECT_DIR="${RASPBERRY_BASE_DIR}/${PROJECT}"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Funciones de log
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

log_step() {
    echo -e "${BLUE}[PASO]${NC} $1"
}

# Paso 1: Verificar conectividad
log_step "1. Verificando conectividad con Raspberry Pi..."
if ! ping -c 1 192.168.4.177 > /dev/null 2>&1; then
    log_error "No se puede conectar a la Raspberry Pi en 192.168.4.177"
fi
log_info "✅ Raspberry Pi es accesible"

# Paso 2: Crear estructura de directorios
log_step "2. Creando estructura de directorios en Raspberry..."
ssh ${RASPBERRY_HOST} "mkdir -p ${PROJECT_DIR}/{docker,docker/tb-node/log,docker/tb-node/data,backups,logs}" || log_error "Error creando directorios"
log_info "✅ Directorios creados"

# Paso 3: Copiar archivos de docker
log_step "3. Copiando archivos de configuración Docker..."
cd /Users/pedrovalenzuela/Documents/Innvoid/Desarrollo/thingsboard

# Copiar archivos principales
scp docker/.env ${RASPBERRY_HOST}:${PROJECT_DIR}/docker/ 2>/dev/null || log_error "Error copiando .env"
scp docker/docker-compose.yml ${RASPBERRY_HOST}:${PROJECT_DIR}/docker/ 2>/dev/null || log_error "Error copiando docker-compose.yml"
scp docker/docker-compose.postgres.yml ${RASPBERRY_HOST}:${PROJECT_DIR}/docker/ 2>/dev/null
scp docker/docker-compose.valkey.yml ${RASPBERRY_HOST}:${PROJECT_DIR}/docker/ 2>/dev/null
scp docker/docker-compose.kafka.yml ${RASPBERRY_HOST}:${PROJECT_DIR}/docker/ 2>/dev/null
scp docker/compose-utils.sh ${RASPBERRY_HOST}:${PROJECT_DIR}/docker/ 2>/dev/null
scp docker/cache-valkey.env ${RASPBERRY_HOST}:${PROJECT_DIR}/docker/ 2>/dev/null
scp docker/queue-kafka.env ${RASPBERRY_HOST}:${PROJECT_DIR}/docker/ 2>/dev/null

# Copiar archivos de configuración de servicios
scp docker/tb-node.env ${RASPBERRY_HOST}:${PROJECT_DIR}/docker/ 2>/dev/null
scp docker/tb-mqtt-transport.env ${RASPBERRY_HOST}:${PROJECT_DIR}/docker/ 2>/dev/null
scp docker/tb-http-transport.env ${RASPBERRY_HOST}:${PROJECT_DIR}/docker/ 2>/dev/null
scp docker/tb-coap-transport.env ${RASPBERRY_HOST}:${PROJECT_DIR}/docker/ 2>/dev/null
scp docker/tb-lwm2m-transport.env ${RASPBERRY_HOST}:${PROJECT_DIR}/docker/ 2>/dev/null
scp docker/kafka.env ${RASPBERRY_HOST}:${PROJECT_DIR}/docker/ 2>/dev/null

# Copiar todos los archivos .env adicionales
rsync -avz --include='*.env' --exclude='*' docker/ ${RASPBERRY_HOST}:${PROJECT_DIR}/docker/

# Copiar configuración de transports
ssh ${RASPBERRY_HOST} "mkdir -p ${PROJECT_DIR}/docker/tb-transports/{mqtt,http,coap,lwm2m}/conf"

scp -r docker/tb-transports/mqtt/conf/* ${RASPBERRY_HOST}:${PROJECT_DIR}/docker/tb-transports/mqtt/conf/ 2>/dev/null || true
scp -r docker/tb-transports/http/conf/* ${RASPBERRY_HOST}:${PROJECT_DIR}/docker/tb-transports/http/conf/ 2>/dev/null || true
scp -r docker/tb-transports/coap/conf/* ${RASPBERRY_HOST}:${PROJECT_DIR}/docker/tb-transports/coap/conf/ 2>/dev/null || true
scp -r docker/tb-transports/lwm2m/conf/* ${RASPBERRY_HOST}:${PROJECT_DIR}/docker/tb-transports/lwm2m/conf/ 2>/dev/null || true

log_info "✅ Archivos de configuración copiados"

# Paso 4: Hacer backup de la versión anterior
log_step "4. Creando backup de versión anterior..."
ssh ${RASPBERRY_HOST} "cd ${PROJECT_DIR}/docker && \
    if [ -f docker-compose.yml ]; then \
        cp docker-compose.yml ../backups/docker-compose-\$(date +%Y%m%d-%H%M%S).bak; \
    fi && \
    docker compose down 2>/dev/null || true" || true
log_info "✅ Backup completado"

# Paso 5: Detener contenedores
log_step "5. Deteniendo contenedores actuales..."
ssh ${RASPBERRY_HOST} "cd ${PROJECT_DIR}/docker && docker compose down 2>/dev/null || true" || true
sleep 2
log_info "✅ Contenedores detenidos"

# Paso 6: Limpiar volúmenes viejos (opcional)
log_step "6. Verificando volúmenes Docker..."
ssh ${RASPBERRY_HOST} "docker volume ls | grep thingsboard" || log_info "No hay volúmenes antiguos"

# Paso 7: Levantar servicios con docker-compose
log_step "7. Levantando imagenes de Docker..."
ssh ${RASPBERRY_HOST} "cd ${PROJECT_DIR}/docker && \
    docker compose -f docker-compose.yml \
                   -f docker-compose.postgres.yml \
                   -f docker-compose.valkey.yml \
                   -f docker-compose.kafka.yml \
                   up -d" || log_error "Error levantando contenedores"

log_info "✅ Contenedores levantados"

# Paso 8: Esperar a que los servicios estén listos
log_step "8. Esperando a que los servicios estén listos..."
sleep 10

# Paso 9: Verificar estado
log_step "9. Verificando estado de contenedores..."
ssh ${RASPBERRY_HOST} "cd ${PROJECT_DIR}/docker && docker compose ps" || log_error "Error verificando estado"

# Paso 10: Pruebas de conectividad
log_step "10. Realizando pruebas de conectividad..."

# Test MongoDB/PostgreSQL
log_info "  - Probando PostgreSQL..."
ssh ${RASPBERRY_HOST} "docker exec -it thingsboard-ce-postgres-1 pg_isready -U postgres 2>/dev/null && echo 'PostgreSQL OK' || echo 'PostgreSQL pendiente'" || true

# Test Redis/Valkey
log_info "  - Probando Valkey..."
ssh ${RASPBERRY_HOST} "docker exec thingsboard-ce-valkey-1 redis-cli ping 2>/dev/null | grep -q PONG && echo 'Valkey OK' || echo 'Valkey pendiente'" || true

# Test Kafka
log_info "  - Probando Kafka..."
ssh ${RASPBERRY_HOST} "docker exec thingsboard-ce-zookeeper-1 echo 'stat' | nc 127.0.0.1 2181 2>/dev/null && echo 'Zookeeper OK' || echo 'Zookeeper pendiente'" || true

log_info "✅ Pruebas completadas"

# Paso 11: Mostrar información de acceso
log_step "11. Información de acceso a ThingsBoard"
echo ""
echo -e "${BLUE}===========================================${NC}"
echo -e "${GREEN}ThingsBoard está accesible en:${NC}"
echo -e "  URL: ${BLUE}http://192.168.4.177:8080${NC}"
echo ""
echo -e "${GREEN}Credenciales por defecto:${NC}"
echo -e "  Usuario: ${BLUE}sysadmin@thingsboard.org${NC}"
echo -e "  Contraseña: ${BLUE}sysadmin${NC}"
echo ""
echo -e "${GREEN}Conexión MQTT desde ESP32:${NC}"
echo -e "  Host: ${BLUE}192.168.4.177${NC}"
echo -e "  Puerto: ${BLUE}1883${NC}"
echo ""
echo -e "${GREEN}Conexión desde getmarket-iot:${NC}"
echo -e "  Host: ${BLUE}192.168.4.177${NC}"
echo -e "  Puerto REST: ${BLUE}8080${NC}"
echo -e "  MQTT: ${BLUE}1883${NC}"
echo ""
echo -e "${BLUE}===========================================${NC}"
echo ""

# Paso 12: Command para ver logs
echo -e "${GREEN}Para ver logs ejecuta:${NC}"
echo "  ssh ${RASPBERRY_HOST} 'cd ${PROJECT_DIR}/docker && docker compose logs -f'"
echo ""
echo -e "${GREEN}Para detener el servicio:${NC}"
echo "  ssh ${RASPBERRY_HOST} 'cd ${PROJECT_DIR}/docker && docker compose down'"
echo ""

log_info "✅ Despliegue completado exitosamente!"

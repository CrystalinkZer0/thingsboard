#!/bin/bash

##############################################################################
# Script para Convertir a Single-Node ThingsBoard en Raspberry Pi
# Ejecutar DIRECTAMENTE en la Raspberry Pi
# 
# Uso: 
#   scp apply-single-node.sh innvoid@192.168.4.177:~/
#   ssh innvoid@192.168.4.177
#   cd ~/docker-projects/thingsboard/docker
#   bash ~/apply-single-node.sh
##############################################################################

set -e

PROJECT_DIR="$HOME/docker-projects/thingsboard/docker"

echo "🔧 Configuración Single-Node para Raspberry Pi"
echo "=============================================="
echo ""

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

cd $PROJECT_DIR || { echo "Error: Directorio no encontrado"; exit 1; }

echo -e "${YELLOW}1. Creando backup del docker-compose.yml...${NC}"
cp docker-compose.yml docker-compose.yml.backup.$(date +%Y%m%d_%H%M%S)
echo "✅ Backup creado"
echo ""

echo -e "${YELLOW}2. Deteniendo servicios actuales...${NC}"
docker compose down
echo "✅ Servicios detenidos"
echo ""

echo -e "${YELLOW}3. Creando docker-compose.yml optimizado single-node...${NC}"

cat > docker-compose.single-node.yml << 'COMPOSE_END'
version: '3.8'

services:
  # === INFRAESTRUCTURA BASE ===
  
  postgres:
    restart: always
    image: "postgres:15"
    ports:
      - "${POSTGRES_PORT:-5432}:5432"
    environment:
      POSTGRES_DB: ${POSTGRES_DB:-thingsboard}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-postgres}
    volumes:
      - ~/.tb-data/postgres:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 30s
      timeout: 10s
      retries: 5

  zookeeper:
    restart: always
    image: "zookeeper:3.8"
    ports:
      - "2181:2181"
    environment:
      ZOO_MY_ID: 1
      ZOO_SERVERS: server.1=0.0.0.0:2888:3888;2181
      ZOO_TICK_TIME: 2000
      ZOO_INIT_LIMIT: 5
      ZOO_SYNC_LIMIT: 2
    volumes:
      - ~/.tb-data/zookeeper/data:/data
      - ~/.tb-data/zookeeper/datalog:/datalog

  kafka:
    restart: always
    image: "confluentinc/cp-kafka:7.4.0"
    ports:
      - "9092:9092"
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: 'zookeeper:2181'
      KAFKA_LISTENERS: INSIDE://0.0.0.0:9093,OUTSIDE://0.0.0.0:9092
      KAFKA_ADVERTISED_LISTENERS: INSIDE://kafka:9093,OUTSIDE://localhost:9092
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: INSIDE:PLAINTEXT,OUTSIDE:PLAINTEXT
      KAFKA_INTER_BROKER_LISTENER_NAME: INSIDE
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
      KAFKA_TRANSACTION_STATE_LOG_MIN_ISR: 1
      KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR: 1
      KAFKA_HEAP_OPTS: "-Xmx768m -Xms768m"
      KAFKA_LOG_RETENTION_HOURS: 168
    depends_on:
      - zookeeper
    volumes:
      - ~/.tb-data/kafka:/var/lib/kafka/data

  # === THINGSBOARD CORE (SINGLE NODE) ===
  
  tb-core1:
    restart: always
    image: "${DOCKER_REPO:-thingsboard}/${TB_NODE_DOCKER_NAME:-tb-node}:${TB_VERSION:-latest}"
    ports:
      - "8080:8080"
      - "7070:7070"
    logging:
      driver: "json-file"
      options:
        max-size: "50m"
        max-file: "3"
    environment:
      TB_SERVICE_ID: tb-core1
      TB_SERVICE_TYPE: tb-core
      TB_QUEUE_TYPE: kafka
      TB_KAFKA_SERVERS: kafka:9093
      JAVA_OPTS: "${JAVA_OPTS:--Xmx1200M -Xms1200M -Xss256k -XX:+AlwaysPreTouch}"
      TB_QUEUE_CORE_POLL_INTERVAL_MS: 25
      TB_QUEUE_CORE_PACK_PROCESSING_TIMEOUT_MS: 2000
      TB_QUEUE_RULE_ENGINE_POLL_INTERVAL_MS: 25
      CACHE_TYPE: caffeine
    env_file:
      - tb-node.env
    volumes:
      - ./tb-node/conf:/config
      - ./tb-node/log:/var/log/thingsboard
    depends_on:
      - kafka
      - postgres

  # === RULE ENGINE (SINGLE NODE) ===
  
  tb-rule-engine1:
    restart: always
    image: "${DOCKER_REPO:-thingsboard}/${TB_NODE_DOCKER_NAME:-tb-node}:${TB_VERSION:-latest}"
    logging:
      driver: "json-file"
      options:
        max-size: "50m"
        max-file: "3"
    environment:
      TB_SERVICE_ID: tb-rule-engine1
      TB_SERVICE_TYPE: tb-rule-engine
      TB_QUEUE_TYPE: kafka
      TB_KAFKA_SERVERS: kafka:9093
      JAVA_OPTS: "${JAVA_OPTS:--Xmx1024M -Xms1024M -Xss256k -XX:+AlwaysPreTouch}"
      CACHE_TYPE: caffeine
    env_file:
      - tb-node.env
    volumes:
      - ./tb-node/conf:/config
      - ./tb-node/log:/var/log/thingsboard
    depends_on:
      - kafka
      - postgres
      - tb-core1

  # === MQTT TRANSPORT (SINGLE NODE) ===
  
  tb-mqtt-transport1:
    restart: always
    image: "${DOCKER_REPO:-thingsboard}/${MQTT_TRANSPORT_DOCKER_NAME:-tb-mqtt-transport}:${TB_VERSION:-latest}"
    ports:
      - "1883:1883"
    logging:
      driver: "json-file"
      options:
        max-size: "50m"
        max-file: "3"
    environment:
      TB_SERVICE_ID: tb-mqtt-transport1
      TB_KAFKA_SERVERS: kafka:9093
      JAVA_OPTS: "${JAVA_OPTS:--Xmx512M -Xms512M -Xss256k -XX:+AlwaysPreTouch}"
    env_file:
      - tb-mqtt-transport.env
    volumes:
      - ./tb-transports/mqtt/conf:/config
      - ./tb-transports/mqtt/log:/var/log/tb-mqtt-transport
    depends_on:
      - kafka
      - tb-core1

  # === WEB UI (SINGLE NODE) ===
  
  tb-web-ui1:
    restart: always
    image: "${DOCKER_REPO:-thingsboard}/${WEB_UI_DOCKER_NAME:-tb-web-ui}:${TB_VERSION:-latest}"
    logging:
      driver: "json-file"
      options:
        max-size: "50m"
        max-file: "3"
    env_file:
      - tb-web-ui.env

  # === JS EXECUTOR (2 INSTANCIAS PARA ESTABILIDAD) ===
  
  tb-js-executor-1:
    restart: always
    image: "${DOCKER_REPO:-thingsboard}/${JS_EXECUTOR_DOCKER_NAME:-tb-js-executor}:${TB_VERSION:-latest}"
    logging:
      driver: "json-file"
      options:
        max-size: "25m"
        max-file: "2"
    environment:
      JAVA_OPTS: "-Xmx256M -Xms256M -Xss256k"
    env_file:
      - tb-js-executor.env

  tb-js-executor-2:
    restart: always
    image: "${DOCKER_REPO:-thingsboard}/${JS_EXECUTOR_DOCKER_NAME:-tb-js-executor}:${TB_VERSION:-latest}"
    logging:
      driver: "json-file"
      options:
        max-size: "25m"
        max-file: "2"
    environment:
      JAVA_OPTS: "-Xmx256M -Xms256M -Xss256k"
    env_file:
      - tb-js-executor.env

  # === LOAD BALANCER ===
  
  haproxy-certbot:
    restart: always
    container_name: "${LOAD_BALANCER_NAME}"
    image: "nmarus/haproxy-certbot:latest"
    volumes:
      - ./haproxy/config:/config
      - ./haproxy/letsencrypt:/etc/letsencrypt
      - ./haproxy/certs.d:/usr/local/etc/haproxy/certs.d
    ports:
      - "80:80"
      - "443:443"
      - "1883:1883"
      - "7070:7070"
      - "9999:9999"
    cap_add:
      - NET_ADMIN
    environment:
      HTTP_PORT: 80
      HTTPS_PORT: 443
      MQTT_PORT: 1883

  # === ADMINISTRACIÓN ===
  
  portainer:
    restart: always
    image: "portainer/portainer-ce:latest"
    ports:
      - "9000:9000"
      - "9443:9443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - portainer_data:/data

volumes:
  portainer_data:

# NOTA: Configuración optimizada para Raspberry Pi
# - Solo 1 instancia de core, rule-engine, mqtt-transport
# - 2 js-executors para estabilidad
# - Transportes CoAP, HTTP, LWM2M, SNMP deshabilitados (ahorrar RAM)
# - Límites de memoria configurados via JAVA_OPTS en .env
# - Logs limitados para ahorrar espacio en SD
COMPOSE_END

echo "✅ docker-compose.single-node.yml creado"
echo ""

echo -e "${YELLOW}4. Verificando configuración .env...${NC}"

# Verificar que JAVA_OPTS esté configurado
if grep -q "^JAVA_OPTS=" .env; then
    echo "✅ JAVA_OPTS ya configurado:"
    grep "^JAVA_OPTS=" .env
else
    echo "⚠️  JAVA_OPTS no encontrado, agregando..."
    echo "" >> .env
    echo "# Límites de memoria para Raspberry Pi" >> .env
    echo "JAVA_OPTS=-Xmx512M -Xms512M -Xss256k -XX:+AlwaysPreTouch" >> .env
    echo "✅ JAVA_OPTS agregado"
fi
echo ""

echo -e "${YELLOW}5. Limpiando contenedores huérfanos y volúmenes no usados...${NC}"
docker system prune -f
echo "✅ Limpieza completada"
echo ""

echo -e "${YELLOW}6. Iniciando servicios en modo single-node...${NC}"
docker compose -f docker-compose.single-node.yml up -d

echo ""
echo "⏳ Esperando que los servicios inicien (60 segundos)..."
sleep 60

echo ""
echo -e "${GREEN}✅ Configuración Single-Node Aplicada${NC}"
echo ""
echo "📊 Estado de servicios:"
docker ps --format 'table {{.Names}}\t{{.Status}}'
echo ""

echo "💾 Uso de memoria actual:"
free -h | grep Mem
echo ""

echo -e "${YELLOW}📝 Resumen de Configuración:${NC}"
echo "  ✅ PostgreSQL:      1 instancia"
echo "  ✅ Kafka/Zookeeper: 1 instancia c/u"
echo "  ✅ TB Core:         1 instancia (tb-core1)"
echo "  ✅ TB Rule Engine:  1 instancia (tb-rule-engine1)"
echo "  ✅ TB MQTT:         1 instancia (tb-mqtt-transport1)"
echo "  ✅ TB Web UI:       1 instancia"
echo "  ✅ JS Executors:    2 instancias (estabilidad)"
echo "  ✅ HAProxy:         1 instancia"
echo "  ✅ Portainer:       1 instancia"
echo "  ❌ CoAP, HTTP, LWM2M, SNMP: Deshabilitados"
echo ""
echo "  Total: ~11 contenedores (vs 26+ anterior)"
echo ""

echo -e "${YELLOW}🔍 Verificación de servicios:${NC}"
echo "  1. ThingsBoard UI:  http://192.168.4.177:8080"
echo "  2. Portainer:       https://192.168.4.177:9443"
echo "  3. MQTT (sensores): 192.168.4.177:1883"
echo ""

echo -e "${YELLOW}📊 Monitorear recursos:${NC}"
echo "  docker stats --no-stream"
echo "  docker logs -f tb-core1"
echo ""

echo -e "${YELLOW}🔄 Para volver a la configuración anterior:${NC}"
echo "  docker compose -f docker-compose.single-node.yml down"
echo "  docker compose -f docker-compose.yml up -d"
echo ""

echo -e "${GREEN}✨ ¡Listo! Sistema optimizado para Raspberry Pi${NC}"
echo ""

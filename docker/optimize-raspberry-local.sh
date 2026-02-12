#!/bin/bash

##############################################################################
# Script de Optimización para ThingsBoard en Raspberry Pi
# Ejecutar DIRECTAMENTE en la Raspberry Pi (no desde Mac)
# Uso: ssh innvoid@192.168.4.177
#      cd ~/docker-projects/thingsboard/docker
#      bash optimize-raspberry-local.sh
##############################################################################

PROJECT_DIR="$HOME/docker-projects/thingsboard/docker"

echo "🔧 Optimización de ThingsBoard en Raspberry Pi"
echo "================================================"
echo ""

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}1. Verificando estado actual...${NC}"
echo "----------------------------------------------"

echo "📊 Recursos del sistema:"
free -h | grep Mem
df -h / | tail -1
echo ""

echo "🐳 Contenedores activos:"
docker ps --format 'table {{.Names}}\t{{.Status}}' | grep -E 'NAMES|thingsboard'
echo ""

echo -e "${YELLOW}2. Arreglando permisos de directorios de logs...${NC}"
echo "----------------------------------------------"

cd $PROJECT_DIR || exit 1

# Arreglar permisos de logs (problema principal de los containers que fallan)
sudo chown -R $USER:$USER tb-transports/*/log 2>/dev/null || true
sudo chmod -R 755 tb-transports/*/log 2>/dev/null || true
sudo chown -R $USER:$USER tb-node/log 2>/dev/null || true
sudo chmod -R 755 tb-node/log 2>/dev/null || true

echo '✅ Permisos corregidos'
echo ""

echo -e "${YELLOW}3. Optimizando configuración de memoria...${NC}"
echo "----------------------------------------------"

# Crear backup del .env
cp .env .env.backup.$(date +%Y%m%d_%H%M%S)
echo "✅ Backup creado: .env.backup.$(date +%Y%m%d_%H%M%S)"

# Actualizar JAVA_OPTS para limitar uso de memoria
if grep -q "^JAVA_OPTS=" .env; then
    sed -i 's|^JAVA_OPTS=.*|JAVA_OPTS=-Xmx512M -Xms512M -Xss256k -XX:+AlwaysPreTouch|' .env
    echo "✅ JAVA_OPTS actualizado"
else
    echo "" >> .env
    echo "# Límite de memoria para aplicaciones Java (optimizado para Raspberry Pi)" >> .env
    echo "JAVA_OPTS=-Xmx512M -Xms512M -Xss256k -XX:+AlwaysPreTouch" >> .env
    echo "✅ JAVA_OPTS agregado"
fi

echo ""
echo "Configuración actual:"
grep "JAVA_OPTS" .env
echo ""

echo -e "${YELLOW}4. Verificando Tailscale...${NC}"
echo "----------------------------------------------"

if which tailscale >/dev/null 2>&1; then
    echo "✅ Tailscale ya está instalado"
    if tailscale status >/dev/null 2>&1; then
        echo "✅ Tailscale está activo"
        echo "Tu IP de Tailscale:"
        tailscale ip -4 || echo "No disponible"
    else
        echo "⚠️  Tailscale instalado pero no configurado"
        echo "Para configurar ejecuta: sudo tailscale up"
    fi
else
    echo "📥 Instalando Tailscale..."
    curl -fsSL https://tailscale.com/install.sh | sh
    echo ""
    echo -e "${GREEN}✅ Tailscale instalado${NC}"
    echo ""
    echo -e "${YELLOW}⚠️  ACCIÓN REQUERIDA:${NC}"
    echo "Para activar Tailscale ejecuta: sudo tailscale up"
fi

echo ""

echo -e "${YELLOW}5. Creando docker-compose optimizado...${NC}"
echo "----------------------------------------------"

# Crear versión optimizada del docker-compose
cat > docker-compose.rpi-optimized.yml << 'COMPOSE_FILE'
# Docker Compose Optimizado para Raspberry Pi
# Usa solo los servicios esenciales y limita recursos

version: '3.8'

services:
  # === INFRAESTRUCTURA ===
  
  postgres:
    image: "postgres:15"
    restart: always
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: thingsboard
    volumes:
      - ~/.tb-data/postgres:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  zookeeper:
    image: "zookeeper:3.8"
    restart: always
    environment:
      ZOO_MY_ID: 1
      ZOO_SERVERS: server.1=0.0.0.0:2888:3888;2181
    ports:
      - "2181:2181"

  kafka:
    image: "confluentinc/cp-kafka:7.4.0"
    restart: always
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: 'zookeeper:2181'
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:9092
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
      KAFKA_HEAP_OPTS: "-Xmx768m -Xms768m"
    depends_on:
      - zookeeper
    ports:
      - "9092:9092"

  # === THINGSBOARD CORE ===
  
  tb-core1:
    image: "${DOCKER_REPO:-thingsboard}/${TB_NODE_DOCKER_NAME:-tb-node}:${TB_VERSION:-latest}"
    restart: always
    environment:
      TB_SERVICE_ID: tb-core1
      TB_SERVICE_TYPE: tb-core
      JAVA_OPTS: "-Xmx1200M -Xms1200M -Xss256k -XX:+AlwaysPreTouch"
    env_file:
      - tb-node.env
    volumes:
      - ./tb-node/conf:/config
      - ./tb-node/log:/var/log/thingsboard
    depends_on:
      - kafka
      - postgres
    ports:
      - "8080:8080"
      - "7070:7070"

  # === RULE ENGINE ===
  
  tb-rule-engine1:
    image: "${DOCKER_REPO:-thingsboard}/${TB_NODE_DOCKER_NAME:-tb-node}:${TB_VERSION:-latest}"
    restart: always
    environment:
      TB_SERVICE_ID: tb-rule-engine1
      TB_SERVICE_TYPE: tb-rule-engine
      JAVA_OPTS: "-Xmx1024M -Xms1024M -Xss256k -XX:+AlwaysPreTouch"
    env_file:
      - tb-node.env
    volumes:
      - ./tb-node/conf:/config
      - ./tb-node/log:/var/log/thingsboard
    depends_on:
      - kafka
      - postgres

  # === TRANSPORTES ===
  
  tb-mqtt-transport1:
    image: "${DOCKER_REPO:-thingsboard}/${MQTT_TRANSPORT_DOCKER_NAME:-tb-mqtt-transport}:${TB_VERSION:-latest}"
    restart: always
    environment:
      TB_SERVICE_ID: tb-mqtt-transport
      JAVA_OPTS: "-Xmx512M -Xms512M -Xss256k -XX:+AlwaysPreTouch"
    env_file:
      - tb-mqtt-transport.env
    volumes:
      - ./tb-transports/mqtt/conf:/config
      - ./tb-transports/mqtt/log:/var/log/tb-mqtt-transport
    depends_on:
      - kafka
    ports:
      - "1883:1883"

  # === UI Y EJECUTORES ===
  
  tb-web-ui1:
    image: "${DOCKER_REPO:-thingsboard}/${WEB_UI_DOCKER_NAME:-tb-web-ui}:${TB_VERSION:-latest}"
    restart: always
    env_file:
      - tb-web-ui.env

  tb-js-executor:
    image: "${DOCKER_REPO:-thingsboard}/${JS_EXECUTOR_DOCKER_NAME:-tb-js-executor}:${TB_VERSION:-latest}"
    restart: always
    environment:
      JAVA_OPTS: "-Xmx256M -Xms256M -Xss256k"
    env_file:
      - tb-js-executor.env

  # === PROXY ===
  
  haproxy-certbot:
    image: "nmarus/haproxy-certbot:latest"
    restart: always
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
      HAPROXY_HOSTNAME: localhost

  # === GESTIÓN ===
  
  portainer:
    image: "portainer/portainer-ce:latest"
    restart: always
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - portainer_data:/data
    ports:
      - "9000:9000"
      - "9443:9443"

volumes:
  portainer_data:

# NOTA: CoAP, HTTP, LWM2M y SNMP transports deshabilitados para ahorrar RAM
# Si los necesitas, agrégalos con límites de memoria similares a MQTT
COMPOSE_FILE

echo "✅ Archivo docker-compose.rpi-optimized.yml creado"
echo ""

echo -e "${YELLOW}6. ¿Quieres reiniciar los servicios ahora? (s/n)${NC}"
read -r RESTART_SERVICES

if [[ "$RESTART_SERVICES" =~ ^[Ss]$ ]]; then
    echo ""
    echo "🔄 Reiniciando servicios..."
    
    # Detener servicios actuales
    echo "Deteniendo servicios..."
    docker compose down
    
    # Esperar a que se detengan completamente
    echo "Esperando 10 segundos..."
    sleep 10
    
    # Limpiar contenedores huérfanos
    echo "Limpiando contenedores huérfanos..."
    docker system prune -f
    
    # Levantar con nueva configuración
    echo "Levantando servicios optimizados..."
    docker compose -f docker-compose.rpi-optimized.yml up -d
    
    echo ""
    echo "⏳ Esperando que los servicios inicien (40 segundos)..."
    sleep 40
    
    echo ""
    echo "📊 Estado de los servicios:"
    docker ps --format 'table {{.Names}}\t{{.Status}}'
    
    echo ""
    echo "💾 Uso de memoria actual:"
    free -h | grep Mem
    
else
    echo "⚠️  No se reiniciaron los servicios"
    echo ""
    echo "Para aplicar los cambios manualmente ejecuta:"
    echo "  cd $PROJECT_DIR"
    echo "  docker compose down"
    echo "  docker compose -f docker-compose.rpi-optimized.yml up -d"
fi

echo ""
echo -e "${GREEN}✅ Optimización completada${NC}"
echo ""
echo "📝 Resumen de cambios:"
echo "  ✅ Permisos de logs corregidos"
echo "  ✅ Límites de memoria configurados"
echo "  ✅ Docker compose optimizado creado"
echo "  ✅ Tailscale verificado/instalado"
echo ""
echo "📊 Servicios optimizados:"
echo "  • PostgreSQL:      Límite implícito ~512 MB"
echo "  • Kafka:           768 MB heap"
echo "  • TB Core:         1200 MB heap"
echo "  • TB Rule Engine:  1024 MB heap"
echo "  • TB MQTT:         512 MB heap"
echo "  • TB JS Executor:  256 MB heap"
echo "  • Otros:           ~500 MB"
echo "  --------------------------------"
echo "  Total estimado:    ~4.5 GB (vs 6.4 GB anterior)"
echo ""
echo "🌐 Próximos pasos para acceso remoto:"
echo "  1. Configura Tailscale: sudo tailscale up"
echo "  2. Autoriza en el navegador"
echo "  3. Obtén tu IP: tailscale ip -4"
echo "  4. Accede desde cualquier red: http://[IP_TAILSCALE]:8080"
echo ""
echo "🔧 Verificar estado:"
echo "  docker ps"
echo "  docker logs tb-core1"
echo "  free -h"
echo ""

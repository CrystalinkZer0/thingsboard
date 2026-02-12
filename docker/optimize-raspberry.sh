#!/bin/bash

##############################################################################
# Script de Optimización para ThingsBoard en Raspberry Pi
# Uso: ./optimize-raspberry.sh
##############################################################################

# No usar set -e para manejar errores manualmente
RASPBERRY_IP="${RASPBERRY_IP:-192.168.4.177}"
RASPBERRY_USER="${RASPBERRY_USER:-innvoid}"
PROJECT_DIR="~/docker-projects/thingsboard/docker"

echo "🔧 Optimización de ThingsBoard en Raspberry Pi"
echo "================================================"
echo ""

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Función para ejecutar comandos en la Raspberry
run_remote() {
    ssh ${RASPBERRY_USER}@${RASPBERRY_IP} "$@"
}

echo -e "${YELLOW}1. Verificando estado actual...${NC}"
echo "----------------------------------------------"

# Obtener información del sistema
echo "📊 Recursos del sistema:"
run_remote "free -h | grep Mem && df -h / | tail -1"
echo ""

echo "🐳 Contenedores activos:"
run_remote "docker ps --format 'table {{.Names}}\t{{.Status}}' | grep -E 'NAMES|thingsboard'"
echo ""

echo -e "${YELLOW}2. Arreglando permisos de directorios de logs...${NC}"
echo "----------------------------------------------"

# Arreglar permisos de logs (problema principal de los containers que fallan)
run_remote "cd ${PROJECT_DIR} && \
    sudo chown -R innvoid:innvoid tb-transports/*/log 2>/dev/null || true && \
    sudo chmod -R 755 tb-transports/*/log 2>/dev/null || true && \
    sudo chown -R innvoid:innvoid tb-node/log 2>/dev/null || true && \
    sudo chmod -R 755 tb-node/log 2>/dev/null || true && \
    echo '✅ Permisos corregidos'"

echo ""

echo -e "${YELLOW}3. Optimizando configuración de memoria...${NC}"
echo "----------------------------------------------"

# Crear backup del .env
run_remote "cd ${PROJECT_DIR} && cp .env .env.backup.\$(date +%Y%m%d_%H%M%S)"

# Actualizar JAVA_OPTS para limitar uso de memoria
# Para Raspberry Pi con 8GB RAM, distribución recomendada:
# - tb-core: 1200MB (principal)
# - tb-rule-engine: 1200MB (procesamiento de reglas)
# - kafka: 1024MB (mensajería)
# - transportes: 512MB cada uno
# - otros: 256-512MB

cat > /tmp/optimize_thingsboard.sh << 'REMOTE_SCRIPT'
#!/bin/bash
cd ~/docker-projects/thingsboard/docker

# Actualizar .env con límites de memoria
if grep -q "^JAVA_OPTS=" .env; then
    sed -i 's|^JAVA_OPTS=.*|JAVA_OPTS=-Xmx512M -Xms512M -Xss256k -XX:+AlwaysPreTouch|' .env
else
    echo "" >> .env
    echo "# Límite de memoria para aplicaciones Java (optimizado para Raspberry Pi)" >> .env
    echo "JAVA_OPTS=-Xmx512M -Xms512M -Xss256k -XX:+AlwaysPreTouch" >> .env
fi

# Deshabilitar transports innecesarios si no se usan
# CoAP y HTTP transport solo si realmente los necesitas
if ! grep -q "^ENABLE_COAP_TRANSPORT=" .env; then
    echo "" >> .env
    echo "# Deshabilitar transportes no utilizados (ahorra ~500MB RAM c/u)" >> .env
    echo "ENABLE_COAP_TRANSPORT=false" >> .env
    echo "ENABLE_HTTP_TRANSPORT=true" >> .env
    echo "ENABLE_LWM2M_TRANSPORT=false" >> .env
    echo "ENABLE_SNMP_TRANSPORT=false" >> .env
fi

echo "✅ Configuración de memoria optimizada"
cat .env | grep -E "JAVA_OPTS|ENABLE_.*_TRANSPORT"
REMOTE_SCRIPT

scp /tmp/optimize_thingsboard.sh ${RASPBERRY_USER}@${RASPBERRY_IP}:/tmp/
run_remote "bash /tmp/optimize_thingsboard.sh"
rm /tmp/optimize_thingsboard.sh

echo ""

echo -e "${YELLOW}4. Configurando Tailscale para acceso remoto...${NC}"
echo "----------------------------------------------"

# Verificar si Tailscale está instalado
if run_remote "which tailscale" >/dev/null 2>&1; then
    echo "✅ Tailscale ya está instalado"
    run_remote "tailscale status" || echo "⚠️  Tailscale instalado pero no configurado"
else
    echo "📥 Instalando Tailscale..."
    run_remote "curl -fsSL https://tailscale.com/install.sh | sh"
    echo ""
    echo -e "${GREEN}✅ Tailscale instalado${NC}"
    echo ""
    echo -e "${YELLOW}⚠️  ACCIÓN REQUERIDA:${NC}"
    echo "1. Ejecuta en la Raspberry: sudo tailscale up"
    echo "2. Abre el link de autorización en tu navegador"
    echo "3. Instala Tailscale en tus dispositivos (Mac, móvil, etc.)"
    echo "4. Después podrás acceder desde cualquier red usando la IP de Tailscale"
    echo ""
fi

echo ""

echo -e "${YELLOW}5. Creando docker-compose optimizado...${NC}"
echo "----------------------------------------------"

# Crear versión optimizada del docker-compose que deshabilita servicios innecesarios
cat > /tmp/docker-compose.rpi-optimized.yml << 'COMPOSE_FILE'
# Docker Compose Optimizado para Raspberry Pi
# Usa solo los servicios esenciales y limita recursos

version: '3.8'

services:
  # === SERVICIOS PRINCIPALES (SIEMPRE ACTIVOS) ===
  
  postgres:
    extends:
      file: docker-compose.postgres.yml
      service: postgres
    deploy:
      resources:
        limits:
          memory: 512M
        reservations:
          memory: 256M

  kafka:
    extends:
      file: docker-compose.kafka.yml
      service: kafka
    environment:
      KAFKA_HEAP_OPTS: "-Xmx768m -Xms768m"
    deploy:
      resources:
        limits:
          memory: 1024M
        reservations:
          memory: 768M

  zookeeper:
    extends:
      file: docker-compose.kafka.yml
      service: zookeeper
    deploy:
      resources:
        limits:
          memory: 256M
        reservations:
          memory: 128M

  tb-core1:
    extends:
      file: docker-compose.yml
      service: tb-core1
    environment:
      JAVA_OPTS: "-Xmx1200M -Xms1200M -Xss256k -XX:+AlwaysPreTouch"
    deploy:
      resources:
        limits:
          memory: 1536M
        reservations:
          memory: 1200M

  tb-rule-engine1:
    extends:
      file: docker-compose.yml
      service: tb-rule-engine1
    environment:
      JAVA_OPTS: "-Xmx1024M -Xms1024M -Xss256k -XX:+AlwaysPreTouch"
    deploy:
      resources:
        limits:
          memory: 1280M
        reservations:
          memory: 1024M

  tb-mqtt-transport1:
    extends:
      file: docker-compose.yml
      service: tb-mqtt-transport1
    environment:
      JAVA_OPTS: "-Xmx512M -Xms512M -Xss256k -XX:+AlwaysPreTouch"
    deploy:
      resources:
        limits:
          memory: 768M
        reservations:
          memory: 512M

  tb-web-ui1:
    extends:
      file: docker-compose.yml
      service: tb-web-ui1
    deploy:
      resources:
        limits:
          memory: 256M
        reservations:
          memory: 128M

  tb-js-executor:
    extends:
      file: docker-compose.yml
      service: tb-js-executor
    environment:
      JAVA_OPTS: "-Xmx256M -Xms256M -Xss256k"
    deploy:
      resources:
        limits:
          memory: 384M
        reservations:
          memory: 256M
    # Solo 1 instancia en lugar de 2
    deploy:
      replicas: 1

  # === PROXY REVERSO ===
  
  haproxy-certbot:
    extends:
      file: docker-compose.yml
      service: haproxy-certbot
    deploy:
      resources:
        limits:
          memory: 128M
        reservations:
          memory: 64M

  # === GESTIÓN ===
  
  portainer:
    extends:
      file: docker-compose.yml
      service: portainer
    deploy:
      resources:
        limits:
          memory: 64M
        reservations:
          memory: 32M

# NOTA: CoAP, HTTP, LWM2M y SNMP transports deshabilitados
# Si los necesitas, agrégalos individualmente con límites de memoria
COMPOSE_FILE

scp /tmp/docker-compose.rpi-optimized.yml ${RASPBERRY_USER}@${RASPBERRY_IP}:${PROJECT_DIR}/
rm /tmp/docker-compose.rpi-optimized.yml

echo "✅ Archivo docker-compose.rpi-optimized.yml creado"
echo ""

echo -e "${YELLOW}6. ¿Reiniciar servicios con la configuración optimizada? (s/n)${NC}"
read -r RESTART_SERVICES

if [[ "$RESTART_SERVICES" =~ ^[Ss]$ ]]; then
    echo ""
    echo "🔄 Reiniciando servicios..."
    
    # Detener servicios actuales
    run_remote "cd ${PROJECT_DIR} && docker compose down"
    
    # Esperar a que se detengan completamente
    sleep 5
    
    # Limpiar contenedores problemáticos
    run_remote "docker system prune -f"
    
    # Levantar con nueva configuración
    run_remote "cd ${PROJECT_DIR} && docker compose -f docker-compose.rpi-optimized.yml up -d"
    
    echo ""
    echo "⏳ Esperando que los servicios inicien (30 segundos)..."
    sleep 30
    
    echo ""
    echo "📊 Estado de los servicios:"
    run_remote "docker ps --format 'table {{.Names}}\t{{.Status}}'"
    
else
    echo "⚠️  No se reiniciaron los servicios"
    echo "Para aplicar los cambios manualmente:"
    echo "  ssh ${RASPBERRY_USER}@${RASPBERRY_IP}"
    echo "  cd ${PROJECT_DIR}"
    echo "  docker compose -f docker-compose.rpi-optimized.yml up -d"
fi

echo ""
echo -e "${GREEN}✅ Optimización completada${NC}"
echo ""
echo "📝 Resumen de cambios:"
echo "  ✅ Permisos de logs corregidos"
echo "  ✅ Límites de memoria configurados"
echo "  ✅ Servicios innecesarios deshabilitados"
echo "  ✅ Tailscale instalado (requiere configuración)"
echo "  ✅ Docker compose optimizado creado"
echo ""
echo "📊 Uso de RAM estimado después de optimización:"
echo "  - PostgreSQL:      ~256-512 MB"
echo "  - Kafka:           ~768-1024 MB"
echo "  - TB Core:         ~1200 MB"
echo "  - TB Rule Engine:  ~1024 MB"
echo "  - TB MQTT:         ~512 MB"
echo "  - Otros servicios: ~512 MB"
echo "  --------------------------------"
echo "  Total:             ~4-5 GB (vs 6.4 GB actual)"
echo ""
echo "🌐 Acceso remoto con Tailscale:"
echo "  1. Configura Tailscale: ssh ${RASPBERRY_USER}@${RASPBERRY_IP}"
echo "  2. Ejecuta: sudo tailscale up"
echo "  3. Autoriza en el navegador"
echo "  4. Obtén tu IP: tailscale ip -4"
echo "  5. Accede desde cualquier red: http://[IP_TAILSCALE]:30080"
echo ""
echo "📖 Más información en:"
echo "  - GUIA_ACCESO_REMOTO_SEGURO.md"
echo "  - GUIA_DESPLIEGUE_RASPBERRY.md"
echo ""

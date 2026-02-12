#!/bin/bash
set -e

echo "🔧 Optimizando ThingsBoard - Desactivando servicios innecesarios"
echo "================================================================"
echo ""

cd ~/docker-projects/thingsboard/docker

# 1. Asegurar que docker-compose.yml original está en uso
if [ -f docker-compose.yml.backup.20260210_133304 ]; then
    echo "📦 Restaurando docker-compose.yml original..."
    cp docker-compose.yml.backup.20260210_133304 docker-compose.yml
fi

# 2. Verificar y configurar JAVA_OPTS en .env
if ! grep -q "^JAVA_OPTS=" .env 2>/dev/null; then
    echo "⚙️  Agregando JAVA_OPTS a .env..."
    echo "JAVA_OPTS=-Xmx512M -Xms512M -Xss256k -XX:+AlwaysPreTouch" >> .env
else
    echo "✅ JAVA_OPTS ya configurado en .env"
fi

# 3. Levantar solo servicios esenciales
echo ""
echo "🚀 Levantando servicios esenciales..."
echo "   - PostgreSQL + Kafka + Zookeeper"
echo "   - 1x TB Core, 1x Rule Engine, 1x MQTT Transport"
echo "   - 2x JS Executors, 1x Web UI"
echo "   - HAProxy + Portainer"

docker compose up -d \
  postgres \
  zookeeper \
  kafka \
  tb-core1 \
  tb-rule-engine1 \
  tb-mqtt-transport1 \
  tb-web-ui1 \
  tb-js-executor-1 \
  tb-js-executor-2 \
  haproxy-certbot \
  portainer

echo ""
echo "⏳ Esperando 90 segundos para que los servicios estabilicen..."
sleep 90

# 4. Verificar estado
echo ""
echo "📊 Estado de Servicios:"
echo "======================="
docker ps --format 'table {{.Names}}\t{{.Status}}' | grep -E "NAMES|postgres|kafka|zookeeper|tb-|haproxy|portainer"

echo ""
echo "💾 Uso de Memoria:"
echo "=================="
free -h | grep Mem

echo ""
echo "📈 Contenedores Activos:"
TOTAL=$(docker ps -q | wc -l)
echo "   Total: $TOTAL (esperado: 11)"

echo ""
echo "✅ Optimización completada!"
echo ""
echo "🌐 Acceso:"
echo "   ThingsBoard: http://192.168.4.177:8080"
echo "   Portainer:   https://192.168.4.177:9443"
echo ""
echo "🔑 Credenciales ThingsBoard:"
echo "   Usuario: sysadmin@thingsboard.org"
echo "   Contraseña: sysadmin"
echo ""
echo "⚠️  IMPORTANTE:"
echo "   - Los servicios desactivados (HTTP/CoAP/LWM2M/SNMP transports) no arrancarán"
echo "   - Solo MQTT está disponible en puerto 1883"
echo "   - Para usar otros protocolos, levántalos manualmente con:"
echo "     docker compose up -d tb-http-transport1 tb-coap-transport"

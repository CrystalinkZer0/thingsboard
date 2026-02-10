#!/bin/bash
#
# Script para desplegar ThingsBoard optimizado en Raspberry Pi
# Modifica docker-compose.yml para usar configuración reducida
#

set -e

cd ~/thingsboard-docker

echo "================================================"
echo "ThingsBoard - Optimización Rápida Raspberry Pi"
echo "================================================"
echo ""

# Detener todos los servicios
echo "🛑 Deteniendo servicios existentes..."
docker compose down

echo ""
echo "⚙️  Aplicando optimizaciones..."

# Modificar replicas de JS Executor de 10 a 2
sed -i 's/replicas: 10/replicas: 2/g' docker-compose.yml

# Reducir memoria JAVA_OPTS en .env si existe
if [ -f ".env" ]; then
    if grep -q "JAVA_OPTS" .env; then
        sed -i 's/JAVA_OPTS=.*/JAVA_OPTS=-Xms512M -Xmx1024M/g' .env
    fi
fi

echo "  ✓ JS Executors: 10 → 2"
echo "  ✓ Memoria JAVA_OPTS optimizada"
echo ""

# Iniciar solo servicios esenciales
echo "🚀 Iniciando servicios esenciales..."
docker compose up -d \
    zookeeper \
    tb-js-executor \
    tb-rule-engine1 \
    tb-core1 \
    tb-mqtt-transport1 \
    tb-http-transport1 \
    tb-coap-transport \
    tb-web-ui1

echo ""
echo "⏳ Esperando inicialización (90 segundos)..."
sleep 90

echo ""
echo "📊 Estado de servicios:"
docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "NAME|tb-|zookeeper"

echo ""
echo "💾 Uso de memoria:"
free -h | grep -E "Mem|Swap|total"

echo ""
echo "✅ Despliegue optimizado completado"
echo ""
echo "Servicios activos:"
echo "  🌐 Web UI: http://localhost"
echo "  📡 MQTT: localhost:1883"
echo "  🔌 HTTP API: localhost:8081"
echo ""
echo "Para restaurar configuración original:"
echo "  cd ~/thingsboard-docker"
echo "  docker compose down"
echo "  cp docker-compose.yml.backup docker-compose.yml"
echo "  docker compose up -d"
echo ""

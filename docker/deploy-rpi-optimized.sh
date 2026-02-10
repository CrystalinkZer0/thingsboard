#!/bin/bash
#
# Script para desplegar ThingsBoard optimizado en Raspberry Pi 4
# Reduce servicios a configuración mínima funcional
#

set -e

echo "================================================"
echo "ThingsBoard - Despliegue Optimizado Raspberry Pi"
echo "================================================"
echo ""

# Colores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Verificar que estamos en el directorio correcto
if [ ! -f "docker-compose.yml" ]; then
    echo -e "${RED}✗ Error: docker-compose.yml no encontrado${NC}"
    echo "Ejecuta este script desde el directorio docker/"
    exit 1
fi

# Verificar que existe el archivo optimizado
if [ ! -f "docker-compose.rpi-optimized.yml" ]; then
    echo -e "${RED}✗ Error: docker-compose.rpi-optimized.yml no encontrado${NC}"
    exit 1
fi

echo -e "${YELLOW}📋 Configuración Optimizada:${NC}"
echo "  ✓ JS Executors: 2 (en lugar de 10)"
echo "  ✓ TB Core: 1 instancia (en lugar de 2)"
echo "  ✓ Rule Engine: 1 instancia (en lugar de 2)"
echo "  ✓ MQTT Transport: 1 instancia"
echo "  ✓ HTTP Transport: 1 instancia"
echo "  ✓ CoAP Transport: 1 instancia"
echo "  ✗ LWM2M Transport: DESHABILITADO"
echo "  ✗ SNMP Transport: DESHABILITADO"
echo "  ✗ VC Executors: DESHABILITADOS"
echo ""
echo -e "${GREEN}💾 Ahorro estimado: ~5GB RAM${NC}"
echo -e "${GREEN}⚡ Cores libres: ~1-2 cores disponibles${NC}"
echo ""

# Preguntar confirmación
read -p "¿Continuar con el despliegue optimizado? (y/n): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Operación cancelada"
    exit 0
fi

echo ""
echo -e "${YELLOW}🛑 Deteniendo servicios existentes...${NC}"
docker compose down

echo ""
echo -e "${YELLOW}🧹 Limpiando contenedores detenidos...${NC}"
docker system prune -f

echo ""
echo -e "${YELLOW}🚀 Iniciando ThingsBoard optimizado...${NC}"
docker compose -f docker-compose.yml -f docker-compose.rpi-optimized.yml up -d

echo ""
echo -e "${YELLOW}⏳ Esperando inicialización de servicios (60 segundos)...${NC}"
sleep 60

echo ""
echo -e "${YELLOW}📊 Estado de contenedores:${NC}"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "NAME|tb-|zookeeper|haproxy" || true

echo ""
echo -e "${YELLOW}💾 Uso de memoria:${NC}"
free -h

echo ""
echo -e "${GREEN}✅ Despliegue completado${NC}"
echo ""
echo "Acceso a ThingsBoard:"
echo "  🌐 Web UI: http://localhost"
echo "  📡 MQTT: localhost:1883"
echo "  🔌 HTTP API: localhost:8081"
echo ""
echo "Comandos útiles:"
echo "  Ver logs tb-core:          docker logs -f thingsboard-ce-tb-core1-1"
echo "  Ver logs MQTT transport:   docker logs -f thingsboard-ce-tb-mqtt-transport1-1"
echo "  Reiniciar servicios:       docker compose -f docker-compose.yml -f docker-compose.rpi-optimized.yml restart"
echo "  Detener todo:              docker compose down"
echo ""

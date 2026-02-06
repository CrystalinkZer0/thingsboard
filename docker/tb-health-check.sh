#!/bin/bash
#
# ThingsBoard Docker Health Check & Quick Fix
# Script para diagnosticar y arreglar problemas comunes de inicio de ThingsBoard
#

set -e

echo "═══════════════════════════════════════════════════════════════════"
echo "🔍 ThingsBoard Docker - Health Check & Quick Diagnostic"
echo "═══════════════════════════════════════════════════════════════════"
echo ""

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Contador de problemas encontrados
ISSUES=0

echo "${BLUE}1️⃣  Verificando si Docker está corriendo...${NC}"
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker no está instalado${NC}"
    ISSUES=$((ISSUES + 1))
else
    echo -e "${GREEN}✓ Docker está instalado${NC}"
fi

echo ""
echo "${BLUE}2️⃣  Verificando JAVA_OPTS en .env...${NC}"
if grep -q "^JAVA_OPTS=" .env; then
    JAVA_OPTS_VALUE=$(grep "^JAVA_OPTS=" .env | cut -d'=' -f2)
    echo -e "${GREEN}✓ JAVA_OPTS configurado: ${JAVA_OPTS_VALUE}${NC}"
else
    echo -e "${YELLOW}⚠️  JAVA_OPTS NO configurado (solo warning, pero se recomienda)${NC}"
    echo "   Ejecutar: ./tb-fix-java-opts.sh"
    ISSUES=$((ISSUES + 1))
fi

echo ""
echo "${BLUE}3️⃣  Verificando servicios Docker corriendo...${NC}"
SERVICES=("postgres" "zookeeper" "kafka" "valkey" "tb-core1" "tb-core2" "tb-rule-engine1" "tb-rule-engine2")

RUNNING=0
STOPPED=0

for service in "${SERVICES[@]}"; do
    if docker compose ps | grep -q "$service"; then
        STATUS=$(docker compose ps | grep "$service" | awk '{print $NF}')
        if [[ $STATUS == "Up" ]] || [[ $STATUS == "running" ]]; then
            echo -e "${GREEN}✓ $service${NC} - running"
            RUNNING=$((RUNNING + 1))
        else
            echo -e "${RED}❌ $service${NC} - $STATUS"
            STOPPED=$((STOPPED + 1))
            ISSUES=$((ISSUES + 1))
        fi
    else
        echo -e "${YELLOW}⚠️  $service${NC} - no encontrado"
        ISSUES=$((ISSUES + 1))
    fi
done

echo ""
echo "${BLUE}4️⃣  Verificando conectividad de base de datos...${NC}"
if docker compose ps | grep -q "postgres.*Up"; then
    if docker exec -it $(docker compose ps -q postgres 2>/dev/null) psql -U postgres -c "SELECT version();" &> /dev/null; then
        echo -e "${GREEN}✓ PostgreSQL accesible${NC}"
    else
        echo -e "${RED}❌ PostgreSQL no responde${NC}"
        ISSUES=$((ISSUES + 1))
    fi
else
    echo -e "${RED}❌ PostgreSQL no está corriendo${NC}"
    ISSUES=$((ISSUES + 1))
fi

echo ""
echo "${BLUE}5️⃣  Verificando conectividad de cache...${NC}"
if docker compose ps | grep -q "valkey.*Up"; then
    VALKEY_CONTAINER=$(docker compose ps -q valkey 2>/dev/null)
    if echo "PING" | docker exec -i $VALKEY_CONTAINER nc localhost 6379 &> /dev/null; then
        echo -e "${GREEN}✓ Valkey (Redis) accesible${NC}"
    else
        echo -e "${RED}❌ Valkey no responde en puerto 6379${NC}"
        ISSUES=$((ISSUES + 1))
    fi
else
    echo -e "${RED}❌ Valkey no está corriendo${NC}"
    ISSUES=$((ISSUES + 1))
fi

echo ""
echo "${BLUE}6️⃣  Verificando espacio en disco...${NC}"
DISK_USAGE=$(df . | tail -1 | awk '{print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -gt 80 ]; then
    echo -e "${RED}❌ Disco casi lleno: $DISK_USAGE%${NC}"
    ISSUES=$((ISSUES + 1))
else
    echo -e "${GREEN}✓ Espacio en disco: $DISK_USAGE%${NC}"
fi

echo ""
echo "${BLUE}7️⃣  Verificando memoria RAM disponible...${NC}"
FREE_MEMORY=$(free -h | grep Mem | awk '{print $7}')
echo "   Memoria libre: $FREE_MEMORY"

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo "📊 RESUMEN"
echo "═══════════════════════════════════════════════════════════════════"
echo ""
echo "Servicios corriendo: $RUNNING/8"
echo "Servicios detenidos: $STOPPED/8"
echo "Total de problemas: $ISSUES"
echo ""

if [ $ISSUES -eq 0 ]; then
    echo -e "${GREEN}✅ TODO ESTÁ BIEN - ThingsBoard debería estar funcionando${NC}"
    echo ""
    echo "Verificar logs:"
    echo "  docker logs thingsboard-ce-tb-core1-1"
    echo ""
    echo "Acceder a ThingsBoard:"
    echo "  http://192.168.4.177:8080"
else
    echo -e "${YELLOW}⚠️  ENCONTRADOS $ISSUES PROBLEMAS - Ejecutar reparación${NC}"
    echo ""
    echo "Opciones de reparación:"
    echo ""
    echo "  OPCIÓN 1 - Reparación automática simple"
    echo "  $ ./docker-fix-java-opts.sh"
    echo ""
    echo "  OPCIÓN 2 - Reiniciar todos los servicios"
    echo "  $ ./docker-stop-services.sh"
    echo "  $ ./docker-start-services.sh"
    echo ""
    echo "  OPCIÓN 3 - Instalación completa desde cero"
    echo "  $ ./docker-install-tb.sh"
    echo ""
    echo "  OPCIÓN 4 - Ver guía completa de troubleshooting"
    echo "  $ cat ../TROUBLESHOOTING_DOCKER_TB.md"
fi

echo ""
echo "═══════════════════════════════════════════════════════════════════"

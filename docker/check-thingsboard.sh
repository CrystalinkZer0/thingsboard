#!/bin/bash
#
# Script de Verificación de ThingsBoard en Raspberry Pi
# Uso: ./check-thingsboard.sh
# 
# Este script verifica:
# - Estado de memoria RAM y Swap
# - Contenedores Docker activos
# - Uso de recursos por servicio
# - Conectividad del API
#

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  ThingsBoard - Estado del Sistema (Raspberry Pi)          ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# =============================================================================
# 1. ESTADO DE MEMORIA
# =============================================================================
echo "═══════════════════════════════════════════════════════════"
echo "📊 Estado de Memoria"
echo "═══════════════════════════════════════════════════════════"
free -h | grep -E "(total|Mem:|Inter:)"

# Análisis de swap
SWAP_USED=$(free | grep Swap | awk '{printf "%.0f", ($3/$2)*100}')
if [ "$SWAP_USED" -gt 80 ]; then
    echo -e "${RED}⚠️  WARNING: Swap usage > 80% ($SWAP_USED%)${NC}"
    echo -e "${YELLOW}   Considera detener servicios redundantes${NC}"
elif [ "$SWAP_USED" -gt 50 ]; then
    echo -e "${YELLOW}⚠️  CAUTION: Swap usage = $SWAP_USED%${NC}"
else
    echo -e "${GREEN}✓ Swap usage OK: $SWAP_USED%${NC}"
fi
echo ""

# =============================================================================
# 2. SERVICIOS DOCKER - ESTADO
# =============================================================================
echo "═══════════════════════════════════════════════════════════"
echo "🐳 Servicios Docker - Estado"
echo "═══════════════════════════════════════════════════════════"

# Verificar que Docker está corriendo
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker no está corriendo${NC}"
    exit 1
fi

# Mostrar servicios críticos
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | \
    grep -E "(NAME|tb-core1|tb-rule-engine1|kafka|postgres|zookeeper|haproxy|tb-web-ui)" | \
    head -10

echo ""

# Verificar servicios que NO deberían estar corriendo (optimización RPi4)
SHOULD_BE_STOPPED="tb-core2 tb-rule-engine2 tb-js-executor-6 tb-js-executor-7 tb-js-executor-8 tb-js-executor-9 tb-js-executor-10"
RUNNING_REDUNDANT=""

for service in $SHOULD_BE_STOPPED; do
    if docker ps --format "{{.Names}}" | grep -q "$service"; then
        RUNNING_REDUNDANT="$RUNNING_REDUNDANT $service"
    fi
done

if [ -n "$RUNNING_REDUNDANT" ]; then
    echo -e "${YELLOW}⚠️  Servicios redundantes corriendo (consumiendo RAM):${NC}"
    echo -e "${YELLOW}   $RUNNING_REDUNDANT${NC}"
    echo -e "${YELLOW}   Recomendación: docker compose stop$RUNNING_REDUNDANT${NC}"
    echo ""
fi

# =============================================================================
# 3. USO DE RECURSOS POR CONTENEDOR
# =============================================================================
echo "═══════════════════════════════════════════════════════════"
echo "💾 Uso de Memoria por Contenedor"
echo "═══════════════════════════════════════════════════════════"
docker stats --no-stream --format "table {{.Name}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.CPUPerc}}" | \
    grep -E "(NAME|tb-core1|tb-rule-engine1|kafka|postgres|zookeeper)" | \
    head -8
echo ""

# =============================================================================
# 4. TEST DE CONECTIVIDAD
# =============================================================================
echo "═══════════════════════════════════════════════════════════"
echo "🌐 Test de Conectividad"
echo "═══════════════════════════════════════════════════════════"

# Test 1: Puerto interno de tb-core1
echo -n "Test 1 - Puerto interno tb-core1:8080... "
if docker exec thingsboard-ce-tb-core1-1 bash -c "(timeout 2 bash -c '(echo > /dev/tcp/127.0.0.1/8080)') 2>/dev/null"; then
    echo -e "${GREEN}✓ OPEN${NC}"
    PORT_INTERNAL=true
else
    echo -e "${RED}✗ CLOSED${NC}"
    PORT_INTERNAL=false
fi

# Test 2: Conectividad desde HAProxy
echo -n "Test 2 - HAProxy → tb-core1... "
if docker exec haproxy-certbot busybox wget -q --timeout=3 -O- http://tb-core1:8080/api/auth/login 2>&1 | grep -q "401\|Unauthorized\|credentials"; then
    echo -e "${GREEN}✓ OK${NC}"
    HAPROXY_OK=true
elif docker exec haproxy-certbot busybox wget -q --timeout=3 -O- http://tb-core1:8080/api/auth/login 2>&1 | grep -q "refused"; then
    echo -e "${RED}✗ REFUSED${NC}"
    HAPROXY_OK=false
else
    echo -e "${YELLOW}? UNKNOWN${NC}"
    HAPROXY_OK=false
fi

# Test 3: API externa
echo -n "Test 3 - API externa (HTTP)... "
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 3 http://localhost/api/auth/login 2>/dev/null)
if [ "$HTTP_CODE" == "401" ] || [ "$HTTP_CODE" == "200" ]; then
    echo -e "${GREEN}✓ OK (HTTP $HTTP_CODE)${NC}"
    API_OK=true
elif [ "$HTTP_CODE" == "503" ]; then
    echo -e "${RED}✗ ERROR 503 (Service Unavailable)${NC}"
    API_OK=false
elif [ "$HTTP_CODE" == "000" ]; then
    echo -e "${RED}✗ NO RESPONSE${NC}"
    API_OK=false
else
    echo -e "${YELLOW}? HTTP $HTTP_CODE${NC}"
    API_OK=false
fi

echo ""

# =============================================================================
# 5. LOGS RECIENTES (ERRORES)
# =============================================================================
echo "═══════════════════════════════════════════════════════════"
echo "📋 Últimos Errores en tb-core1 (últimas 200 líneas)"
echo "═══════════════════════════════════════════════════════════"
ERROR_COUNT=$(docker logs --tail 200 thingsboard-ce-tb-core1-1 2>&1 | grep -icE "(error|exception|failed)" || echo "0")

if [ "$ERROR_COUNT" -gt 0 ]; then
    echo -e "${YELLOW}⚠️  Encontrados $ERROR_COUNT errores/excepciones:${NC}"
    docker logs --tail 200 thingsboard-ce-tb-core1-1 2>&1 | \
        grep -iE "(error|exception|failed)" | \
        tail -5
    echo ""
    echo "Para ver todos los errores:"
    echo "  docker logs --tail 500 thingsboard-ce-tb-core1-1 | grep -iE '(error|exception|failed)'"
else
    echo -e "${GREEN}✓ No se encontraron errores recientes${NC}"
fi
echo ""

# =============================================================================
# 6. VERIFICACIÓN DE INICIO COMPLETO
# =============================================================================
echo "═══════════════════════════════════════════════════════════"
echo "🚀 Verificación de Inicio de ThingsBoard"
echo "═══════════════════════════════════════════════════════════"

if docker logs --tail 100 thingsboard-ce-tb-core1-1 2>&1 | grep -q "Started ThingsboardServerApplication"; then
    echo -e "${GREEN}✓ ThingsBoard completamente iniciado${NC}"
    
    # Extraer tiempo de inicio
    START_TIME=$(docker logs --tail 500 thingsboard-ce-tb-core1-1 2>&1 | \
        grep "Started ThingsboardServerApplication" | \
        tail -1 | \
        grep -oP "in \K[0-9.]+ seconds" || echo "unknown")
    
    if [ "$START_TIME" != "unknown" ]; then
        echo "  Tiempo de inicio: $START_TIME"
    fi
else
    # Verificar si está procesando datos (señal de que está casi listo)
    if docker logs --tail 50 thingsboard-ce-tb-core1-1 2>&1 | grep -q "TbSqlBlockingQueue"; then
        echo -e "${YELLOW}⏳ ThingsBoard inicializando... (procesando datos)${NC}"
        echo "   Estado: Inicialización avanzada"
    else
        echo -e "${YELLOW}⏳ ThingsBoard aún inicializando...${NC}"
        
        # Mostrar últimas 3 líneas de log para dar contexto
        echo ""
        echo "Últimas líneas de log:"
        docker logs --tail 3 thingsboard-ce-tb-core1-1 2>&1 | sed 's/^/  /'
    fi
fi
echo ""

# =============================================================================
# 7. RESUMEN Y RECOMENDACIONES
# =============================================================================
echo "═══════════════════════════════════════════════════════════"
echo "📝 Resumen y Recomendaciones"
echo "═══════════════════════════════════════════════════════════"

ALL_OK=true

if [ "$PORT_INTERNAL" = true ] && [ "$HAPROXY_OK" = true ] && [ "$API_OK" = true ]; then
    echo -e "${GREEN}✅ Sistema funcionando correctamente${NC}"
    echo ""
    echo "Acceso web: http://$(hostname -I | awk '{print $1}')"
    echo "Credenciales: sysadmin@thingsboard.org / sysadmin"
else
    echo -e "${RED}❌ Se detectaron problemas:${NC}"
    echo ""
    
    if [ "$PORT_INTERNAL" = false ]; then
        echo -e "${RED}• Puerto 8080 interno cerrado${NC}"
        echo "  → tb-core1 aún no ha terminado de iniciar"
        echo "  → Espera 5-10 minutos más"
        echo "  → Verifica logs: docker logs -f thingsboard-ce-tb-core1-1"
        ALL_OK=false
    fi
    
    if [ "$HAPROXY_OK" = false ]; then
        echo -e "${RED}• HAProxy no puede conectar con tb-core1${NC}"
        echo "  → Verifica que JAVA_OPTS tenga -Dserver.address=0.0.0.0"
        echo "  → Archivo: ~/thingsboard-docker/.env"
        ALL_OK=false
    fi
    
    if [ "$API_OK" = false ]; then
        echo -e "${RED}• API no responde externamente${NC}"
        echo "  → Verifica HAProxy: docker logs haproxy-certbot"
        echo "  → Verifica tb-core1: docker logs thingsboard-ce-tb-core1-1"
        ALL_OK=false
    fi
    
    if [ "$SWAP_USED" -gt 80 ]; then
        echo -e "${RED}• Swap > 80% - Sistema sobrecargado${NC}"
        echo "  → Detén servicios redundantes:"
        echo "    cd ~/thingsboard-docker"
        echo "    docker compose stop tb-core2 tb-rule-engine2 tb-js-executor-{6..10}"
        ALL_OK=false
    fi
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "Para más información, revisa: GUIA_STARTUP_RASPBERRY.md"
echo "═══════════════════════════════════════════════════════════"

# Exit code
if [ "$ALL_OK" = true ]; then
    exit 0
else
    exit 1
fi

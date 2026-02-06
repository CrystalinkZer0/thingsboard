#!/bin/bash
#
# Fix JAVA_OPTS in .env and restart ThingsBoard services
# Reparación automática para el warning de JAVA_OPTS no configurado
#

set -e

echo "═══════════════════════════════════════════════════════════════════"
echo "🔧 Configurando JAVA_OPTS para ThingsBoard"
echo "═══════════════════════════════════════════════════════════════════"
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Verificar que estamos en el directorio correcto
if [ ! -f ".env" ]; then
    echo "❌ Archivo .env no encontrado. Ejecuta este script desde docker/"
    exit 1
fi

echo "${BLUE}1️⃣  Verificando RAM disponible en Raspberry Pi...${NC}"
RAM=$(free -h | grep Mem | awk '{print $2}' | sed 's/Gi//' | cut -d'.' -f1)
echo "   RAM total: ${RAM}GB"

if [ "$RAM" -le 2 ]; then
    JAVA_OPTS="-Xmx512M -Xms256M -Xss128k"
    echo "   → Usando configuración para 2GB: $JAVA_OPTS"
elif [ "$RAM" -le 4 ]; then
    JAVA_OPTS="-Xmx1024M -Xms512M -Xss256k"
    echo "   → Usando configuración para 4GB: $JAVA_OPTS"
else
    JAVA_OPTS="-Xmx2048M -Xms1024M -Xss384k"
    echo "   → Usando configuración para 8GB+: $JAVA_OPTS"
fi

echo ""
echo "${BLUE}2️⃣  Actualizando .env con JAVA_OPTS...${NC}"

# Hacer backup
cp .env .env.backup
echo "   ✓ Backup creado: .env.backup"

# Actualizar o añadir JAVA_OPTS
if grep -q "^JAVA_OPTS=" .env; then
    # Reemplazar línea existente
    sed -i.bak "s/^JAVA_OPTS=.*/JAVA_OPTS=${JAVA_OPTS}/" .env
    echo "   ✓ JAVA_OPTS actualizado"
else
    # Añadir nueva línea
    echo "JAVA_OPTS=${JAVA_OPTS}" >> .env
    echo "   ✓ JAVA_OPTS añadido"
fi

echo ""
echo "${BLUE}3️⃣  Verificando cambios en .env...${NC}"
grep "JAVA_OPTS=" .env
echo "   ✓ Configuración aplicada"

echo ""
echo "${BLUE}4️⃣  Reiniciando servicios de ThingsBoard...${NC}"
echo "   (Esto puede tomar ~30 segundos)"
echo ""

# Hacer stop
echo "   → Deteniendo servicios..."
./docker-stop-services.sh > /dev/null 2>&1 || true
sleep 5

# Hacer start
echo "   → Iniciando servicios..."
./docker-start-services.sh > /dev/null 2>&1

# Esperar un poco
sleep 10

echo ""
echo "${BLUE}5️⃣  Esperando a que ThingsBoard se inicie...${NC}"

# Esperar a que tb-core1 esté disponible
MAX_ATTEMPTS=30
ATTEMPT=0
while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    if docker logs thingsboard-ce-tb-core1-1 2>&1 | grep -q "Started ThingsboardServerApplication"; then
        echo "   ✓ ThingsBoard iniciado correctamente"
        break
    fi
    
    ATTEMPT=$((ATTEMPT + 1))
    echo -n "."
    sleep 2
done

if [ $ATTEMPT -ge $MAX_ATTEMPTS ]; then
    echo ""
    echo "   ⚠️  ThingsBoard aún no aparece como iniciado completamente"
    echo "   Esperando más tiempo..."
fi

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo -e "${GREEN}✅ REPARACIÓN COMPLETADA${NC}"
echo "═══════════════════════════════════════════════════════════════════"
echo ""
echo "Verificar estado:"
echo "  docker compose ps"
echo ""
echo "Ver logs:"
echo "  docker logs thingsboard-ce-tb-core1-1"
echo ""
echo "Acceder a ThingsBoard:"
echo "  http://192.168.4.177:8080"
echo ""

# Ejecutar health check
echo "${BLUE}Ejecutando health check final...${NC}"
if [ -f "tb-health-check.sh" ]; then
    sleep 10
    ./tb-health-check.sh
fi

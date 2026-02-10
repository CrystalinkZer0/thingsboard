#!/bin/bash
#
# Script de Verificación - ESP32 → ThingsBoard
# Verifica que el entorno está listo para el ESP32
#

echo "╔══════════════════════════════════════════════════════╗"
echo "║  Verificación ESP32 → ThingsBoard                    ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

ERRORS=0

# =============================================================================
# 1. Verificar ThingsBoard está corriendo
# =============================================================================
echo "1. Verificando ThingsBoard..."
if curl -s -o /dev/null -w "%{http_code}" http://192.168.4.177/api/auth/login | grep -q "401"; then
    echo -e "${GREEN}   ✓ ThingsBoard respondiendo${NC}"
else
    echo -e "${RED}   ✗ ThingsBoard no responde${NC}"
    echo -e "${YELLOW}   → Inicia ThingsBoard en Raspberry Pi${NC}"
    ERRORS=$((ERRORS + 1))
fi

# =============================================================================
# 2. Verificar puerto MQTT 1883
# =============================================================================
echo "2. Verificando puerto MQTT (1883)..."
if timeout 3 bash -c "(echo > /dev/tcp/192.168.4.177/1883)" 2>/dev/null; then
    echo -e "${GREEN}   ✓ Puerto MQTT abierto${NC}"
else
    echo -e "${RED}   ✗ Puerto MQTT cerrado o inaccesible${NC}"
    echo -e "${YELLOW}   → Verifica firewall en Raspberry Pi${NC}"
    ERRORS=$((ERRORS + 1))
fi

# =============================================================================
# 3. Verificar PlatformIO instalado
# =============================================================================
echo "3. Verificando PlatformIO..."
if command -v pio &> /dev/null; then
    PIO_VERSION=$(pio --version)
    echo -e "${GREEN}   ✓ PlatformIO instalado ($PIO_VERSION)${NC}"
else
    echo -e "${RED}   ✗ PlatformIO no encontrado${NC}"
    echo -e "${YELLOW}   → Instalar: https://platformio.org/install${NC}"
    ERRORS=$((ERRORS + 1))
fi

# =============================================================================
# 4. Verificar proyecto ESP32 existe
# =============================================================================
echo "4. Verificando proyecto ESP32..."
if [ -f "esp32-thingsboard/platformio.ini" ]; then
    echo -e "${GREEN}   ✓ Proyecto encontrado${NC}"
    
    # Verificar config.h editado
    if grep -q "tu_password_wifi_aqui" esp32-thingsboard/include/config.h 2>/dev/null; then
        echo -e "${YELLOW}   ⚠️  WiFi password NO configurado en config.h${NC}"
        echo -e "${YELLOW}   → Editar: esp32-thingsboard/include/config.h${NC}"
        ERRORS=$((ERRORS + 1))
    else
        echo -e "${GREEN}   ✓ WiFi password configurado${NC}"
    fi
else
    echo -e "${RED}   ✗ Proyecto no encontrado${NC}"
    echo -e "${YELLOW}   → Crear proyecto siguiendo README.md${NC}"
    ERRORS=$((ERRORS + 1))
fi

# =============================================================================
# 5. Verificar dispositivo en ThingsBoard
# =============================================================================
echo "5. Verificando dispositivo ESP32_IoT_Sensors..."
echo -e "${YELLOW}   ℹ  Verifica manualmente en:${NC}"
echo -e "${YELLOW}      http://192.168.4.177 → Devices${NC}"

# =============================================================================
# 6. Resumen
# =============================================================================
echo ""
echo "═══════════════════════════════════════════════════════"
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✅ Todo listo para conectar ESP32${NC}"
    echo ""
    echo "Próximos pasos:"
    echo "  1. Conectar hardware según diagrama en README.md"
    echo "  2. cd esp32-thingsboard"
    echo "  3. pio run --target upload"
    echo "  4. pio device monitor"
else
    echo -e "${RED}❌ Se encontraron $ERRORS problema(s)${NC}"
    echo -e "${YELLOW}   Revisa los mensajes arriba${NC}"
fi
echo "═══════════════════════════════════════════════════════"

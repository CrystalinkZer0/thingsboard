#!/bin/bash

##############################################################################
# Script Final de Optimización - Ejecutar desde Mac
# Consolida todas las optimizaciones en la Raspberry Pi
##############################################################################

RASPBERRY_IP="192.168.4.177"
RASPBERRY_USER="innvoid"

echo "🚀 Finalizando Optimización de Raspberry Pi"
echo "==========================================="
echo ""

echo "📝 Pasos a realizar:"
echo "  1. Detener servicios actuales"
echo "  2. Aplicar configuración single-node"
echo "  3. Verificar resultado"
echo ""

echo "⚠️  Este script te pedirá la contraseña varias veces"
echo "    Presiona ENTER para continuar o Ctrl+C para cancelar"
read

echo ""
echo "Paso 1/3: Deteniendo servicios..."
echo "=================================="
ssh ${RASPBERRY_USER}@${RASPBERRY_IP} "cd ~/docker-projects/thingsboard/docker && docker compose down"

echo ""
echo "Paso 2/3: Aplicando configuración single-node..."
echo "================================================="
ssh ${RASPBERRY_USER}@${RASPBERRY_IP} "cd ~/docker-projects/thingsboard/docker && bash ~/apply-single-node.sh"

echo ""
echo "⏳ Esperando que los servicios se estabilicen (30 segundos)..."
sleep 30

echo ""
echo "Paso 3/3: Verificando resultado..."
echo "=================================="
echo ""

ssh ${RASPBERRY_USER}@${RASPBERRY_IP} << 'VERIFY_END'
echo "📊 Contenedores activos:"
docker ps --format 'table {{.Names}}\t{{.Status}}' | head -15

echo ""
echo "💾 Uso de RAM:"
free -h | grep Mem

echo ""
echo "🔢 Total de contenedores:"
docker ps | wc -l

echo ""
echo "✅ Servicios principales:"
docker ps --format '{{.Names}}' | grep -E '(tb-core|tb-rule-engine|tb-mqtt|postgres|kafka)' || echo "Esperando servicios..."
VERIFY_END

echo ""
echo "✅ Optimización completada"
echo ""
echo "🌐 Accesos:"
echo "  ThingsBoard: http://192.168.4.177:8080"
echo "  Portainer:   https://192.168.4.177:9443"
echo "  MQTT:        192.168.4.177:1883"
echo ""
echo "📖 Próximos pasos:"
echo "  1. Configurar Tailscale: ssh innvoid@192.168.4.177 'sudo tailscale up'"
echo "  2. Verificar logs: ssh innvoid@192.168.4.177 'docker logs tb-core1'"
echo "  3. Ver diagnóstico completo: DIAGNOSTICO_RASPBERRY_192.168.4.177.md"
echo ""

#!/bin/bash
#
# Script de diagnóstico rápido para verificar conectividad Kafka en ThingsBoard
#

COMPOSE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$COMPOSE_DIR"

echo "=========================================="
echo "ThingsBoard Kafka Connectivity Check"
echo "=========================================="
echo ""

# 1. Estado de contenedores
echo "=== 1. Estado de contenedores clave ==="
docker compose ps | grep -E "NAME|kafka|zookeeper|tb-core|tb-mqtt|tb-http" | head -20
echo ""

# 2. Configuración de transports
echo "=== 2. Configuración Kafka en transports ==="
echo ""
echo "tb-mqtt-transport.env:"
grep -E "TB_QUEUE_TYPE|TB_KAFKA_SERVERS" tb-mqtt-transport.env 2>/dev/null || echo "❌ NO CONFIGURADO"
echo ""
echo "tb-http-transport.env:"
grep -E "TB_QUEUE_TYPE|TB_KAFKA_SERVERS" tb-http-transport.env 2>/dev/null || echo "❌ NO CONFIGURADO"
echo ""

# 3. Topics de Kafka
echo "=== 3. Topics de Kafka relacionados con transport ==="
docker exec thingsboard-ce-kafka-1 kafka-topics.sh --list --bootstrap-server localhost:9092 2>/dev/null | grep transport || echo "⚠️  No se encontraron topics de transport"
echo ""

# 4. Conectividad Kafka de tb-core
echo "=== 4. Conectividad Kafka de tb-core ==="
echo ""
echo "tb-core1:"
docker compose logs tb-core1 2>/dev/null | grep -i "kafka.*connected\|partitionservice" | tail -3
echo ""
echo "tb-core2:"
docker compose logs tb-core2 2>/dev/null | grep -i "kafka.*connected\|partitionservice" | tail -3
echo ""

# 5. Conectividad Kafka de transports
echo "=== 5. Conectividad Kafka de MQTT transports ==="
echo ""
echo "tb-mqtt-transport1:"
docker compose logs tb-mqtt-transport1 2>/dev/null | grep -iE "kafka|partitionservice|routing info" | tail -5
echo ""
echo "tb-mqtt-transport2:"
docker compose logs tb-mqtt-transport2 2>/dev/null | grep -iE "kafka|partitionservice|routing info" | tail -5
echo ""

# 6. Errores críticos
echo "=== 6. Errores críticos (últimos 2 minutos) ==="
error_count=$(docker compose logs --since 2m tb-mqtt-transport1 tb-mqtt-transport2 2>/dev/null | grep -c "Failed to await queues routing info" || true)
if [ "$error_count" -gt 0 ]; then
    echo "❌ Se encontraron $error_count errores de routing info"
    docker compose logs --since 2m tb-mqtt-transport1 tb-mqtt-transport2 2>/dev/null | grep "Failed to await queues routing info" | tail -3
else
    echo "✅ No se encontraron errores de routing info"
fi
echo ""

# 7. Verificación de puerto MQTT
echo "=== 7. Verificación de puerto MQTT ==="
if command -v nc >/dev/null 2>&1; then
    if echo "" | nc -z localhost 1883 2>/dev/null; then
        echo "✅ Puerto MQTT 1883 está abierto"
    else
        echo "❌ Puerto MQTT 1883 no responde"
    fi
else
    echo "⚠️  netcat (nc) no disponible"
fi
echo ""

# 8. Resumen de diagnóstico
echo "=========================================="
echo "Resumen de Diagnóstico"
echo "=========================================="
echo ""

# Verificar si Kafka está configurado en transports
mqtt_kafka=$(grep -c "TB_KAFKA_SERVERS" tb-mqtt-transport.env 2>/dev/null || echo "0")
http_kafka=$(grep -c "TB_KAFKA_SERVERS" tb-http-transport.env 2>/dev/null || echo "0")

if [ "$mqtt_kafka" -eq 0 ] || [ "$http_kafka" -eq 0 ]; then
    echo "❌ PROBLEMA: Kafka no está configurado en archivos de transport"
    echo ""
    echo "Solución:"
    echo "  1. Ejecuta: ./deploy-kafka-fix.sh (desde tu Mac)"
    echo "  O manualmente agrega a los archivos .env de transport:"
    echo "     TB_QUEUE_TYPE=kafka"
    echo "     TB_KAFKA_SERVERS=kafka:9092"
    echo ""
else
    echo "✅ Configuración Kafka presente en transports"
    
    if [ "$error_count" -gt 0 ]; then
        echo "⚠️  PROBLEMA: Errores de routing info detectados"
        echo ""
        echo "Solución:"
        echo "  ./docker-restart-fix-mqtt.sh"
    else
        echo "✅ No se detectaron errores de routing info"
    fi
fi

echo ""
echo "Para más información:"
echo "  docker compose logs -f tb-mqtt-transport1"
echo ""

#!/bin/bash
#
# Script para reiniciar servicios ThingsBoard después de corregir configuración de Kafka en transports
# Este script soluciona el problema de "Failed to await queues routing info"
#

set -e

COMPOSE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$COMPOSE_DIR"

echo "=========================================="
echo "ThingsBoard Transport Kafka Fix & Restart"
echo "=========================================="
echo ""

# Función para esperar que un servicio esté saludable
wait_for_service() {
    local service=$1
    local max_wait=$2
    local check_interval=5
    local elapsed=0
    
    echo "⏳ Esperando que $service esté listo (máximo ${max_wait}s)..."
    
    while [ $elapsed -lt $max_wait ]; do
        if docker compose logs "$service" 2>/dev/null | grep -q "Started ThingsBoard"; then
            echo "✅ $service está listo"
            return 0
        fi
        sleep $check_interval
        elapsed=$((elapsed + check_interval))
        echo "   ... esperando (${elapsed}s / ${max_wait}s)"
    done
    
    echo "⚠️  Tiempo de espera agotado para $service"
    return 1
}

# Función para verificar conectividad Kafka de un servicio
check_kafka_connectivity() {
    local service=$1
    echo ""
    echo "=== Verificando conectividad Kafka de $service ==="
    docker compose logs "$service" 2>/dev/null | grep -i "kafka.*connected\|partitionservice.*queues routing" | tail -5
}

# 1. Verificar configuración actual
echo "=== 1. Verificando archivos de configuración ==="
echo ""
echo "tb-mqtt-transport.env:"
grep -E "TB_QUEUE_TYPE|TB_KAFKA_SERVERS" tb-mqtt-transport.env || echo "❌ Falta configuración de Kafka"
echo ""
echo "tb-http-transport.env:"
grep -E "TB_QUEUE_TYPE|TB_KAFKA_SERVERS" tb-http-transport.env || echo "❌ Falta configuración de Kafka"
echo ""

# 2. Verificar que Kafka está funcionando
echo "=== 2. Verificando Kafka ==="
if ! docker compose ps kafka | grep -q "Up"; then
    echo "❌ Kafka no está corriendo. Iniciando..."
    docker compose up -d zookeeper kafka
    echo "⏳ Esperando 30s para que Kafka esté listo..."
    sleep 30
fi
echo "✅ Kafka está corriendo"
echo ""

# 3. Verificar topics de Kafka
echo "=== 3. Topics de Kafka ==="
docker exec thingsboard-ce-kafka-1 kafka-topics.sh --list --bootstrap-server localhost:9092 2>/dev/null | grep transport || echo "⚠️  No se encontraron topics de transport"
echo ""

# 4. Reiniciar tb-core (para asegurar que están listos para recibir conexiones)
echo "=== 4. Reiniciando tb-core (1 y 2) ==="
docker compose restart tb-core1 tb-core2
wait_for_service tb-core1 90
wait_for_service tb-core2 90
echo ""

# Espera adicional para que tb-core esté completamente listo
echo "⏳ Espera adicional de 20s para estabilización de tb-core..."
sleep 20

# 5. Reiniciar MQTT transports
echo "=== 5. Reiniciando MQTT transports ==="
docker compose restart tb-mqtt-transport1 tb-mqtt-transport2
wait_for_service tb-mqtt-transport1 60
wait_for_service tb-mqtt-transport2 60
echo ""

# 6. Verificar conectividad Kafka de los transports
echo "=== 6. Verificación de conectividad Kafka ==="
check_kafka_connectivity tb-mqtt-transport1
check_kafka_connectivity tb-mqtt-transport2
echo ""

# 7. Verificar errores de routing
echo "=== 7. Verificando errores de routing (no deberían existir) ==="
error_count=$(docker compose logs tb-mqtt-transport1 tb-mqtt-transport2 2>/dev/null | grep -c "Failed to await queues routing info" || true)
if [ "$error_count" -eq 0 ]; then
    echo "✅ No se encontraron errores de routing"
else
    echo "⚠️  Se encontraron $error_count errores de routing"
    docker compose logs tb-mqtt-transport1 tb-mqtt-transport2 2>/dev/null | grep "Failed to await queues routing info" | tail -3
fi
echo ""

# 8. Reiniciar HTTP transport (opcional)
echo "=== 8. Reiniciando HTTP transport ==="
docker compose restart tb-http-transport1 tb-http-transport2
echo "⏳ Esperando 20s para HTTP transports..."
sleep 20
echo ""

# 9. Estado final de servicios
echo "=== 9. Estado final de servicios ==="
docker compose ps | grep -E "tb-core|tb-mqtt|tb-http|kafka"
echo ""

# 10. Prueba de conectividad MQTT
echo "=== 10. Prueba de puerto MQTT ==="
if command -v nc >/dev/null 2>&1; then
    if echo "" | nc -z localhost 1883 2>/dev/null; then
        echo "✅ Puerto MQTT 1883 está abierto"
    else
        echo "❌ Puerto MQTT 1883 no responde"
    fi
else
    echo "⚠️  netcat (nc) no está disponible para prueba de puerto"
fi
echo ""

echo "=========================================="
echo "✅ Proceso completado"
echo "=========================================="
echo ""
echo "Para verificar logs en tiempo real:"
echo "  docker compose logs -f tb-mqtt-transport1"
echo ""
echo "Para probar conexión MQTT desde ESP32:"
echo "  Asegúrate de usar el token correcto del dispositivo"
echo ""

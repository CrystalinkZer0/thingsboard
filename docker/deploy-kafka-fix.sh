#!/bin/bash
#
# Script para desplegar corrección de Kafka en Raspberry Pi y reiniciar servicios
#

set -e

# Configuración
RASPBERRY_USER="${RASPBERRY_USER:-innvoid}"
RASPBERRY_HOST="${RASPBERRY_HOST:-raspberrypi.local}"
REMOTE_DIR="~/thingsboard-docker"

echo "=========================================="
echo "Desplegando corrección Kafka a Raspberry Pi"
echo "=========================================="
echo ""
echo "Host: $RASPBERRY_USER@$RASPBERRY_HOST"
echo "Directorio remoto: $REMOTE_DIR"
echo ""

# 1. Verificar conectividad SSH
echo "=== 1. Verificando conectividad SSH ==="
if ! ssh -o ConnectTimeout=10 "$RASPBERRY_USER@$RASPBERRY_HOST" "echo 'Conexión exitosa'" 2>/dev/null; then
    echo "❌ No se puede conectar a Raspberry Pi"
    echo ""
    echo "Verifica:"
    echo "  - Que la Raspberry Pi esté encendida"
    echo "  - Que puedas hacer ping: ping $RASPBERRY_HOST"
    echo "  - Que tengas SSH configurado correctamente"
    exit 1
fi
echo "✅ Conexión SSH exitosa"
echo ""

# 2. Hacer backup de archivos originales
echo "=== 2. Creando backup de archivos originales ==="
ssh "$RASPBERRY_USER@$RASPBERRY_HOST" "cd $REMOTE_DIR && \
    mkdir -p backups && \
    cp -f tb-mqtt-transport.env backups/tb-mqtt-transport.env.bak.\$(date +%Y%m%d_%H%M%S) 2>/dev/null || true && \
    cp -f tb-http-transport.env backups/tb-http-transport.env.bak.\$(date +%Y%m%d_%H%M%S) 2>/dev/null || true && \
    cp -f tb-coap-transport.env backups/tb-coap-transport.env.bak.\$(date +%Y%m%d_%H%M%S) 2>/dev/null || true && \
    echo 'Backup completado'"
echo ""

# 3. Copiar archivos actualizados
echo "=== 3. Copiando archivos de configuración actualizados ==="
scp -q tb-mqtt-transport.env "$RASPBERRY_USER@$RASPBERRY_HOST:$REMOTE_DIR/"
scp -q tb-http-transport.env "$RASPBERRY_USER@$RASPBERRY_HOST:$REMOTE_DIR/"
scp -q tb-coap-transport.env "$RASPBERRY_USER@$RASPBERRY_HOST:$REMOTE_DIR/"
scp -q docker-restart-fix-mqtt.sh "$RASPBERRY_USER@$RASPBERRY_HOST:$REMOTE_DIR/"
echo "✅ Archivos copiados"
echo ""

# 4. Dar permisos de ejecución al script
echo "=== 4. Configurando permisos ==="
ssh "$RASPBERRY_USER@$RASPBERRY_HOST" "chmod +x $REMOTE_DIR/docker-restart-fix-mqtt.sh"
echo "✅ Permisos configurados"
echo ""

# 5. Ejecutar script de reinicio
echo "=== 5. Ejecutando script de reinicio en Raspberry Pi ==="
echo ""
echo "Este proceso tomará aproximadamente 3-4 minutos..."
echo ""

ssh "$RASPBERRY_USER@$RASPBERRY_HOST" "cd $REMOTE_DIR && ./docker-restart-fix-mqtt.sh"

echo ""
echo "=========================================="
echo "✅ Despliegue completado exitosamente"
echo "=========================================="
echo ""
echo "Para verificar el estado:"
echo "  ssh $RASPBERRY_USER@$RASPBERRY_HOST 'cd $REMOTE_DIR && docker compose ps'"
echo ""
echo "Para ver logs de MQTT transport:"
echo "  ssh $RASPBERRY_USER@$RASPBERRY_HOST 'cd $REMOTE_DIR && docker compose logs -f tb-mqtt-transport1'"
echo ""

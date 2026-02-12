#!/bin/bash
set -e

echo "🔧 Optimizando ThingsBoard en Raspberry Pi - Reducción de RAM"
echo "============================================================"
echo ""

cd ~/docker-projects/thingsboard/docker

# 1. Detener todos los servicios gradualmente
echo "⏹️  Deteniendo servicios..."
docker compose down || true
sleep 5

# 2. Restaurar docker-compose.yml original (con datos de PostgreSQL intactos)
if [ -f docker-compose.yml.backup.20260210_133304 ]; then
    echo "📦 Restaurando configuración original..."
    cp docker-compose.yml.backup.20260210_133304 docker-compose.yml
else
    echo "❌ Error: No se encontró el backup del docker-compose.yml"
    exit 1
fi

# 3. Crear versión optimizada comentando servicios innecesarios
echo "✂️  Creando configuración optimizada..."
cat docker-compose.yml | \
  sed -E '/^  tb-core2:/,/^  [a-z-]+:/{/^  tb-core2:/s/^/# /; /^  [a-z-]+:/!s/^/# /}' | \
  sed -E '/^  tb-rule-engine2:/,/^  [a-z-]+:/{/^  tb-rule-engine2:/s/^/# /; /^  [a-z-]+:/!s/^/# /}' | \
  sed -E '/^  tb-web-ui2:/,/^  [a-z-]+:/{/^  tb-web-ui2:/s/^/# /; /^  [a-z-]+:/!s/^/# /}' | \
  sed -E '/^  tb-mqtt-transport2:/,/^  [a-z-]+:/{/^  tb-mqtt-transport2:/s/^/# /; /^  [a-z-]+:/!s/^/# /}' | \
  sed -E '/^  tb-http-transport1:/,/^  [a-z-]+:/{/^  tb-http-transport1:/s/^/# /; /^  [a-z-]+:/!s/^/# /}' | \
  sed -E '/^  tb-http-transport2:/,/^  [a-z-]+:/{/^  tb-http-transport2:/s/^/# /; /^  [a-z-]+:/!s/^/# /}' | \
  sed -E '/^  tb-coap-transport:/,/^  [a-z-]+:/{/^  tb-coap-transport:/s/^/# /; /^  [a-z-]+:/!s/^/# /}' | \
  sed -E '/^  tb-lwm2m-transport:/,/^  [a-z-]+:/{/^  tb-lwm2m-transport:/s/^/# /; /^  [a-z-]+:/!s/^/# /}' | \
  sed -E '/^  tb-snmp-transport:/,/^  [a-z-]+:/{/^  tb-snmp-transport:/s/^/# /; /^  [a-z-]+:/!s/^/# /}' | \
  sed -E '/^  tb-vc-executor1:/,/^  [a-z-]+:/{/^  tb-vc-executor1:/s/^/# /; /^  [a-z-]+:/!s/^/# /}' | \
  sed -E '/^  tb-vc-executor2:/,/^  [a-z-]+:/{/^  tb-vc-executor2:/s/^/# /; /^  [a-z-]+:/!s/^/# /}' | \
  sed -E '/^  tb-js-executor-3:/,/^  [a-z-]+:/{/^  tb-js-executor-3:/s/^/# /; /^  [a-z-]+:/!s/^/# /}' | \
  sed -E '/^  tb-js-executor-4:/,/^  [a-z-]+:/{/^  tb-js-executor-4:/s/^/# /; /^  [a-z-]+:/!s/^/# /}' | \
  sed -E '/^  tb-js-executor-5:/,/^  [a-z-]+:/{/^  tb-js-executor-5:/s/^/# /; /^  [a-z-]+:/!s/^/# /}' | \
  sed -E '/^  tb-js-executor-6:/,/^  [a-z-]+:/{/^  tb-js-executor-6:/s/^/# /; /^  [a-z-]+:/!s/^/# /}' | \
  sed -E '/^  tb-js-executor-7:/,/^  [a-z-]+:/{/^  tb-js-executor-7:/s/^/# /; /^  [a-z-]+:/!s/^/# /}' | \
  sed -E '/^  tb-js-executor-8:/,/^  [a-z-]+:/{/^  tb-js-executor-8:/s/^/# /; /^  [a-z-]+:/!s/^/# /}' | \
  sed -E '/^  tb-js-executor-9:/,/^  [a-z-]+:/{/^  tb-js-executor-9:/s/^/# /; /^  [a-z-]+:/!s/^/# /}' | \
  sed -E '/^  tb-js-executor-10:/,/^  [a-z-]+:/{/^  tb-js-executor-10:/s/^/# /; /^  [a-z-]+:/!s/^/# /}' \
  > docker-compose.optimized.yml

# 4. Verificar que JAVA_OPTS está configurado en .env
if ! grep -q "JAVA_OPTS=" .env 2>/dev/null; then
    echo "⚙️  Configurando límites de memoria en .env..."
    echo "JAVA_OPTS=-Xmx512M -Xms512M -Xss256k -XX:+AlwaysPreTouch" >> .env
fi

# 5. Levantar servicios optimizados
echo "🚀 Levantando servicios optimizados..."
docker compose -f docker-compose.optimized.yml up -d

echo ""
echo "⏳ Esperando 60 segundos para que los servicios inicien..."
sleep 60

# 6. Mostrar estado final
echo ""
echo "📊 Estado Final:"
echo "==============="
docker ps --format 'table {{.Names}}\t{{.Status}}' | head -15
echo ""
echo "💾 Memoria:"
free -h | grep Mem

echo ""
echo "✅ Optimización completada!"
echo ""
echo "Servicios activos (esperado: ~11-13):"
docker ps | wc -l
echo ""
echo "📝 Accede a ThingsBoard en: http://192.168.4.177:8080"
echo "    Usuario: sysadmin@thingsboard.org"
echo "    Contraseña: sysadmin"

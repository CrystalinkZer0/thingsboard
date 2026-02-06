#!/bin/bash
#
# Copyright © 2016-2026 The Thingsboard Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Script de monitoreo de inicialización de ThingsBoard
# Verifica cada 30 segundos si el puerto 8080 está disponible

RASPBERRY_HOST="innvoid@192.168.4.177"
MAX_ATTEMPTS=30  # 15 minutos (30 intentos x 30 segundos)
ATTEMPT=0

echo "🔍 Monitoreando inicialización de ThingsBoard en Raspberry Pi..."
echo "   Esto puede tomar 10-15 minutos en hardware limitado"
echo ""

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    ATTEMPT=$((ATTEMPT + 1))
    ELAPSED=$((ATTEMPT * 30))
    
    echo "[$(date +'%H:%M:%S')] Intento $ATTEMPT/$MAX_ATTEMPTS (${ELAPSED}s transcurridos)..."
    
    # Verificar si el puerto responde
    HTTP_CODE=$(ssh -o ConnectTimeout=5 ${RASPBERRY_HOST} "curl -s -o /dev/null -w '%{http_code}' http://localhost:8080 2>/dev/null" 2>/dev/null || echo "000")
    
    if [ "$HTTP_CODE" != "000" ] && [ "$HTTP_CODE" != "" ]; then
        echo ""
        echo "✅ ¡ThingsBoard está ACTIVO!"
        echo "   HTTP Status: $HTTP_CODE"
        echo ""
        echo "🌐 Accede a la interfaz web en:"
        echo "   http://192.168.4.177:8080"
        echo ""
        echo "🔑 Credenciales por defecto:"
        echo "   Usuario: sysadmin@thingsboard.org"
        echo "   Contraseña: sysadmin"
        echo ""
        
        # Mostrar últimas líneas del log
        echo "📋 Últimas líneas del log:"
        ssh ${RASPBERRY_HOST} "docker logs --tail 5 thingsboard-ce-tb-core1-1 2>&1"
        exit 0
    fi
    
    # Verificar si el contenedor sigue corriendo
    CONTAINER_STATUS=$(ssh ${RASPBERRY_HOST} "docker inspect -f '{{.State.Status}}' thingsboard-ce-tb-core1-1 2>/dev/null" || echo "not-found")
    
    if [ "$CONTAINER_STATUS" != "running" ]; then
        echo "⚠️  ADVERTENCIA: El contenedor no está corriendo (Status: $CONTAINER_STATUS)"
        echo "   Verificando logs de error..."
        ssh ${RASPBERRY_HOST} "docker logs --tail 20 thingsboard-ce-tb-core1-1 2>&1"
        exit 1
    fi
    
    # Mostrar progreso cada 3 intentos (90 segundos)
    if [ $((ATTEMPT % 3)) -eq 0 ]; then
        echo "   📊 Progreso de inicialización:"
        LAST_LOG=$(ssh ${RASPBERRY_HOST} "docker logs --tail 1 thingsboard-ce-tb-core1-1 2>&1 | head -1")
        echo "      $LAST_LOG"
    fi
    
    # Esperar 30 segundos antes del próximo intento
    if [ $ATTEMPT -lt $MAX_ATTEMPTS ]; then
        sleep 30
    fi
done

echo ""
echo "❌ Timeout: ThingsBoard no respondió después de 15 minutos"
echo "   Verifica los logs manualmente:"
echo "   ssh ${RASPBERRY_HOST} 'docker logs --tail 50 thingsboard-ce-tb-core1-1'"
exit 1

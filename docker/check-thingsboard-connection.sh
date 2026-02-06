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

#

# Verificar conectividad entre getmarket-iot y ThingsBoard en k3s
#

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[!]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

RASPBERRY_HOST="innvoid@192.168.4.177"

echo "🔍 Verificando configuración de ThingsBoard y getmarket-iot en k3s..."
echo ""

# 1. Verificar ThingsBoard
log_step "1. Verificando ThingsBoard en k3s"

TB_STATUS=$(ssh ${RASPBERRY_HOST} "export KUBECONFIG=~/.kube/config && kubectl get pods -n thingsboard --no-headers 2>/dev/null | grep thingsboard | awk '{print \$3}'" || echo "Error")

if [ "$TB_STATUS" = "Running" ]; then
    log_info "ThingsBoard está Running"
    
    # Obtener IP del servicio
    TB_SERVICE=$(ssh ${RASPBERRY_HOST} "export KUBECONFIG=~/.kube/config && kubectl get svc -n thingsboard thingsboard -o jsonpath='{.spec.clusterIP}' 2>/dev/null" || echo "")
    
    if [ -n "$TB_SERVICE" ]; then
        log_info "Servicio ThingsBoard: ${TB_SERVICE}"
    fi
else
    log_warn "ThingsBoard estado: ${TB_STATUS}"
fi

echo ""

# 2. Verificar si getmarket-iot existe
log_step "2. Verificando microservicio getmarket-iot"

GMI_EXISTS=$(ssh ${RASPBERRY_HOST} "export KUBECONFIG=~/.kube/config && kubectl get deployment getmarket-iot 2>/dev/null" || echo "No existe")

if [[ "$GMI_EXISTS" == *"No existe"* ]]; then
    log_warn "getmarket-iot NO está desplegado en k3s todavía"
    NEEDS_DEPLOY=true
else
    log_info "getmarket-iot está desplegado"
    NEEDS_DEPLOY=false
fi

echo ""

# 3. Configuración recomendada
log_step "3. Configuración de Conexión"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 CONFIGURACIÓN PARA getmarket-iot"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ "$NEEDS_DEPLOY" = true ]; then
    cat << 'EOF'
🎯 OPCIÓN 1: Desplegar en el mismo namespace (RECOMENDADO)

En tu ConfigMap de getmarket-iot:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: getmarket-iot-config
  namespace: thingsboard  # ← Mismo namespace
data:
  THINGSBOARD_HOST: "thingsboard"  # ← Nombre del servicio
  THINGSBOARD_PORT: "80"
  THINGSBOARD_USERNAME: "tenant@thingsboard.org"
  THINGSBOARD_PASSWORD: "tenant"
```

Deployment:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: getmarket-iot
  namespace: thingsboard  # ← Mismo namespace
spec:
  replicas: 1
  selector:
    matchLabels:
      app: getmarket-iot
  template:
    metadata:
      labels:
        app: getmarket-iot
    spec:
      containers:
      - name: getmarket-iot
        image: getmarket-iot:latest
        imagePullPolicy: Never
        ports:
        - containerPort: 3000
        envFrom:
        - configMapRef:
            name: getmarket-iot-config
```

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎯 OPCIÓN 2: Namespace diferente (con DNS completo)

En tu ConfigMap:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: getmarket-iot-config
  namespace: default  # ← Namespace diferente
data:
  THINGSBOARD_HOST: "thingsboard.thingsboard.svc.cluster.local"
  THINGSBOARD_PORT: "80"
  THINGSBOARD_USERNAME: "tenant@thingsboard.org"
  THINGSBOARD_PASSWORD: "tenant"
```

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📝 NOTAS IMPORTANTES:

1. URL completa dentro de k3s:
   http://thingsboard:80/api/auth/login

2. Desde fuera de k3s (desarrollo local):
   http://192.168.4.177:30080/api/auth/login

3. Credenciales por defecto:
   - Usuario: tenant@thingsboard.org
   - Password: tenant

4. El puerto 80 es el puerto INTERNO del servicio k3s
   (no el 30080 que es el NodePort externo)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
else
    cat << EOF
✅ getmarket-iot ya está desplegado

Para verificar la configuración actual:

  ssh ${RASPBERRY_HOST}
  export KUBECONFIG=~/.kube/config
  kubectl get configmap getmarket-iot-config -o yaml
  
Para actualizar:

  kubectl edit configmap getmarket-iot-config
  
Luego reinicia el pod:

  kubectl rollout restart deployment/getmarket-iot
EOF
fi

echo ""

# 4. Test de conectividad (si ThingsBoard está corriendo)
if [ "$TB_STATUS" = "Running" ]; then
    log_step "4. Test de Conectividad"
    
    echo "Probando conexión a ThingsBoard..."
    
    TEST_RESULT=$(ssh ${RASPBERRY_HOST} "export KUBECONFIG=~/.kube/config && kubectl run test-tb-connection --image=curlimages/curl --rm -i --restart=Never --namespace=thingsboard -- curl -s -o /dev/null -w '%{http_code}' http://thingsboard:80/login 2>/dev/null" || echo "Error")
    
    if [ "$TEST_RESULT" = "200" ]; then
        log_info "✅ Conexión exitosa (HTTP 200)"
    else
        log_warn "⏳ ThingsBoard respondió: HTTP $TEST_RESULT (aún inicializando)"
    fi
fi

echo ""

# 5. Comandos útiles
log_step "5. Comandos Útiles"

cat << EOF

# Ver servicios de ThingsBoard
ssh ${RASPBERRY_HOST} "export KUBECONFIG=~/.kube/config && kubectl get svc -n thingsboard"

# Ver pods
ssh ${RASPBERRY_HOST} "export KUBECONFIG=~/.kube/config && kubectl get pods -n thingsboard"

# Logs de ThingsBoard
ssh ${RASPBERRY_HOST} "export KUBECONFIG=~/.kube/config && kubectl logs -f deployment/thingsboard -n thingsboard"

# Test de conexión desde un pod
ssh ${RASPBERRY_HOST} "export KUBECONFIG=~/.kube/config && kubectl run test --image=curlimages/curl --rm -i --restart=Never --namespace=thingsboard -- curl http://thingsboard:80/login"

EOF

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 🔌 Conectar getmarket-iot con ThingsBoard en k3s

## 🎯 Configuración Rápida

### Paso 1: Verificar Estado Actual

```bash
cd /Users/pedrovalenzuela/Documents/Innvoid/Desarrollo/thingsboard/docker
chmod +x check-thingsboard-connection.sh
./check-thingsboard-connection.sh
```

Este script te mostrará:
- ✅ Estado de ThingsBoard
- ✅ Configuración exacta para getmarket-iot
- ✅ Test de conectividad

---

## 📋 Configuración en getmarket-iot

### Opción 1: Mismo Namespace (RECOMENDADO)

**Ventaja:** DNS simple, más seguro

**En tu proyecto getmarket-iot, crea/edita:**

`k8s/configmap.yaml`:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: getmarket-iot-config
  namespace: thingsboard  # ← Mismo namespace que ThingsBoard
data:
  # ThingsBoard connection (dentro de k3s)
  THINGSBOARD_HOST: "thingsboard"
  THINGSBOARD_PORT: "80"
  THINGSBOARD_USERNAME: "tenant@thingsboard.org"
  THINGSBOARD_PASSWORD: "tenant"
  
  # Base de datos (PostgreSQL compartida)
  DATABASE_HOST: "postgres"
  DATABASE_PORT: "5432"
  DATABASE_NAME: "getmarket_iot"
  DATABASE_USER: "postgres"
  
  # Configuración de la app
  NODE_ENV: "production"
  PORT: "3000"
```

`k8s/secret.yaml`:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: getmarket-iot-secrets
  namespace: thingsboard
type: Opaque
stringData:
  DATABASE_PASSWORD: "tb-postgres-2026-secure"
  THINGSBOARD_API_TOKEN: ""  # Se obtendrá después de login
```

`k8s/deployment.yaml`:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: getmarket-iot
  namespace: thingsboard
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
        env:
        - name: DATABASE_PASSWORD
          valueFrom:
            secretKeyRef:
              name: getmarket-iot-secrets
              key: DATABASE_PASSWORD
        envFrom:
        - configMapRef:
            name: getmarket-iot-config
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 10
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: getmarket-iot
  namespace: thingsboard
spec:
  type: NodePort
  selector:
    app: getmarket-iot
  ports:
  - port: 80
    targetPort: 3000
    nodePort: 30081  # Acceso externo
```

---

### Opción 2: Namespace Diferente

Si prefieres separar los namespaces:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: getmarket-iot-config
  namespace: default  # O cualquier otro namespace
data:
  # DNS completo para cross-namespace
  THINGSBOARD_HOST: "thingsboard.thingsboard.svc.cluster.local"
  THINGSBOARD_PORT: "80"
  # ... resto igual
```

---

## 🚀 Desplegar getmarket-iot

### Paso 1: Construir Imagen Docker

```bash
cd /Users/pedrovalenzuela/Documents/Innvoid/Desarrollo/getmarket-iot

# Crear Dockerfile si no existe
cat > Dockerfile << 'EOF'
FROM node:18-alpine

WORKDIR /app

# Copiar package files
COPY package*.json ./

# Instalar dependencias
RUN npm ci --only=production

# Copiar código fuente
COPY . .

# Compilar TypeScript
RUN npm run build

# Exponer puerto
EXPOSE 3000

# Comando de inicio
CMD ["node", "dist/index.js"]
EOF

# Construir imagen
docker build -t getmarket-iot:latest .
```

### Paso 2: Copiar Imagen a Raspberry

```bash
# Opción A: Guardar y copiar imagen
docker save getmarket-iot:latest | gzip > getmarket-iot.tar.gz
scp getmarket-iot.tar.gz innvoid@192.168.4.177:~
ssh innvoid@192.168.4.177 "gunzip -c getmarket-iot.tar.gz | sudo k3s ctr images import -"

# Opción B: Usar registry local (más avanzado)
# Ver sección "Registry Local" más abajo
```

### Paso 3: Desplegar en k3s

```bash
# Copiar manifiestos
scp -r k8s/ innvoid@192.168.4.177:~/k8s-deployments/getmarket-iot/

# Aplicar
ssh innvoid@192.168.4.177 "export KUBECONFIG=~/.kube/config && kubectl apply -f ~/k8s-deployments/getmarket-iot/"

# Ver estado
ssh innvoid@192.168.4.177 "export KUBECONFIG=~/.kube/config && kubectl get pods -n thingsboard -l app=getmarket-iot"
```

---

## 🧪 Probar Conexión

### Test 1: Desde el Pod

```bash
ssh innvoid@192.168.4.177

export KUBECONFIG=~/.kube/config

# Ejecutar comando dentro del pod
kubectl exec -it deployment/getmarket-iot -n thingsboard -- sh

# Dentro del pod, probar conexión a ThingsBoard
wget -O- http://thingsboard:80/login

# O con curl (si está disponible)
curl http://thingsboard:80/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"tenant@thingsboard.org","password":"tenant"}'
```

### Test 2: Health Check

```bash
# Desde tu Mac
curl http://192.168.4.177:30081/health

# Debería retornar algo como:
# {
#   "status": "healthy",
#   "thingsboard": "connected",
#   "database": "connected"
# }
```

---

## 🔑 Autenticación con ThingsBoard

### Obtener Token de Acceso

```bash
# Desde el pod de getmarket-iot o cualquier pod en el namespace
kubectl run test-auth --image=curlimages/curl --rm -i --restart=Never --namespace=thingsboard -- \
  curl -X POST http://thingsboard:80/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"tenant@thingsboard.org","password":"tenant"}'

# Respuesta:
# {
#   "token": "eyJhbGciOiJIUzUxMiJ9...",
#   "refreshToken": "..."
# }
```

### Guardar Token en Secret

```bash
# Actualizar secret con el token
kubectl create secret generic getmarket-iot-secrets \
  --from-literal=THINGSBOARD_API_TOKEN='eyJhbGciOiJIUzUxMiJ9...' \
  --namespace=thingsboard \
  --dry-run=client -o yaml | kubectl apply -f -

# Reiniciar deployment
kubectl rollout restart deployment/getmarket-iot -n thingsboard
```

---

## 📊 Código de Integración

### Actualizar ThingsBoardService

En tu `src/services/ThingsBoardService.ts`:

```typescript
import axios, { AxiosInstance } from 'axios';

export class ThingsBoardService {
  private client: AxiosInstance;
  private token: string | null = null;

  constructor() {
    // Usar variables de entorno del ConfigMap
    const host = process.env.THINGSBOARD_HOST || 'thingsboard';
    const port = process.env.THINGSBOARD_PORT || '80';
    
    this.client = axios.create({
      baseURL: `http://${host}:${port}/api`,
      timeout: 10000,
    });

    console.log(`📡 ThingsBoard client configured: http://${host}:${port}`);
  }

  async authenticate(): Promise<string> {
    const username = process.env.THINGSBOARD_USERNAME;
    const password = process.env.THINGSBOARD_PASSWORD;

    try {
      const response = await this.client.post('/auth/login', {
        username,
        password,
      });
      
      this.token = response.data.token;
      this.client.defaults.headers.common['X-Authorization'] = `Bearer ${this.token}`;
      
      console.log('✅ Authenticated with ThingsBoard');
      return this.token;
    } catch (error) {
      console.error('❌ ThingsBoard authentication failed:', error.message);
      throw error;
    }
  }

  async getDevices() {
    if (!this.token) {
      await this.authenticate();
    }

    try {
      const response = await this.client.get('/tenant/devices', {
        params: { pageSize: 100, page: 0 },
      });
      
      return response.data;
    } catch (error) {
      console.error('❌ Failed to get devices:', error.message);
      throw error;
    }
  }

  async getDeviceTelemetry(deviceId: string, keys: string[]) {
    if (!this.token) {
      await this.authenticate();
    }

    try {
      const response = await this.client.get(
        `/plugins/telemetry/DEVICE/${deviceId}/values/timeseries`,
        {
          params: {
            keys: keys.join(','),
            limit: 100,
          },
        }
      );
      
      return response.data;
    } catch (error) {
      console.error('❌ Failed to get telemetry:', error.message);
      throw error;
    }
  }
}

export default new ThingsBoardService();
```

### Health Check Endpoint

```typescript
// src/routes/health.ts
import express from 'express';
import thingsBoardService from '../services/ThingsBoardService';

const router = express.Router();

router.get('/health', async (req, res) => {
  const health: any = {
    status: 'healthy',
    timestamp: new Date().toISOString(),
  };

  // Test ThingsBoard connection
  try {
    await thingsBoardService.authenticate();
    health.thingsboard = 'connected';
  } catch (error) {
    health.thingsboard = 'disconnected';
    health.status = 'degraded';
  }

  // Test Database connection (si aplica)
  // ...

  const statusCode = health.status === 'healthy' ? 200 : 503;
  res.status(statusCode).json(health);
});

export default router;
```

---

## 🔄 CI/CD para getmarket-iot

### Script de Despliegue Automático

`deploy-getmarket-iot.sh`:
```bash
#!/bin/bash
set -e

echo "🚀 Desplegando getmarket-iot a Raspberry Pi..."

# Construir imagen
docker build -t getmarket-iot:latest .

# Exportar y copiar
docker save getmarket-iot:latest | gzip > /tmp/getmarket-iot.tar.gz
scp /tmp/getmarket-iot.tar.gz innvoid@192.168.4.177:~

# Importar en k3s
ssh innvoid@192.168.4.177 << 'EOF'
  sudo k3s ctr images import <(gunzip -c ~/getmarket-iot.tar.gz)
  rm ~/getmarket-iot.tar.gz
EOF

# Copiar manifiestos
scp -r k8s/ innvoid@192.168.4.177:~/k8s-deployments/getmarket-iot/

# Aplicar cambios
ssh innvoid@192.168.4.177 << 'EOF'
  export KUBECONFIG=~/.kube/config
  kubectl apply -f ~/k8s-deployments/getmarket-iot/
  kubectl rollout restart deployment/getmarket-iot -n thingsboard
  kubectl rollout status deployment/getmarket-iot -n thingsboard
EOF

echo "✅ Despliegue completado!"
echo ""
echo "🌐 Acceso:"
echo "   API: http://192.168.4.177:30081"
echo "   Health: http://192.168.4.177:30081/health"
```

---

## 🐛 Troubleshooting

### Problema: Pod no puede conectar a ThingsBoard

```bash
# Ver logs del pod
kubectl logs -f deployment/getmarket-iot -n thingsboard

# Verificar DNS
kubectl exec -it deployment/getmarket-iot -n thingsboard -- nslookup thingsboard

# Probar conexión
kubectl exec -it deployment/getmarket-iot -n thingsboard -- wget -O- http://thingsboard:80/login
```

### Problema: Imagen no encontrada

```bash
# Verificar imágenes en k3s
ssh innvoid@192.168.4.177 "sudo k3s crictl images | grep getmarket"

# Si no está, volver a importar
docker save getmarket-iot:latest | gzip | ssh innvoid@192.168.4.177 "gunzip | sudo k3s ctr images import -"
```

### Problema: ConfigMap no se aplica

```bash
# Ver ConfigMap actual
kubectl get configmap getmarket-iot-config -n thingsboard -o yaml

# Forzar actualización
kubectl delete configmap getmarket-iot-config -n thingsboard
kubectl apply -f k8s/configmap.yaml
kubectl rollout restart deployment/getmarket-iot -n thingsboard
```

---

## 📚 Próximos Pasos

1. ✅ Desplegar getmarket-iot en k3s
2. ✅ Verificar conexión con ThingsBoard
3. 🔄 Configurar ESP32 para enviar datos
4. 📊 Crear endpoints para consultar datos
5. 🔐 Configurar acceso híbrido (Tailscale + Nginx)
6. 🚀 Automatizar deployments con CI/CD

---

## 🔗 Referencias

- [ThingsBoard REST API](https://thingsboard.io/docs/reference/rest-api/)
- [Kubernetes DNS](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/)
- [k3s Images](https://docs.k3s.io/installation/private-registry)

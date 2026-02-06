# 🚀 CI/CD y Despliegue Continuo con SSH

## 📋 Tabla de Contenidos

1. [Opciones de Despliegue](#opciones-de-despliegue)
2. [GitHub Actions](#github-actions)
3. [GitLab CI/CD](#gitlab-cicd)
4. [Kubernetes (k3s)](#kubernetes-k3s)
5. [Comparación de Soluciones](#comparación-de-soluciones)
6. [Configuración Inicial](#configuración-inicial)

---

## Opciones de Despliegue

### 🐳 Docker Compose (Actual)
**Mejor para:** Proyectos simples, desarrollo rápido
- ✅ Configuración sencilla
- ✅ Bajo consumo de recursos
- ❌ Sin auto-scaling
- ❌ Rollbacks manuales

### ☸️ Kubernetes (k3s)
**Mejor para:** Múltiples microservicios, alta disponibilidad
- ✅ Auto-scaling horizontal
- ✅ Rollbacks automáticos
- ✅ Health checks nativos
- ❌ Mayor complejidad
- ❌ Mayor consumo de RAM (~1GB más)

---

## GitHub Actions

### Configuración de Secrets

Ve a tu repositorio → Settings → Secrets → Actions:

```
RASPBERRY_HOST = 192.168.4.177
RASPBERRY_USER = innvoid
RASPBERRY_SSH_KEY = <contenido de tu clave privada SSH>
```

### Generar SSH Key

```bash
# En tu Mac
ssh-keygen -t ed25519 -C "github-actions@raspberry" -f ~/.ssh/github_raspberry

# Copiar clave pública a Raspberry
ssh-copy-id -i ~/.ssh/github_raspberry.pub innvoid@192.168.4.177

# Copiar clave privada (para GitHub Secrets)
cat ~/.ssh/github_raspberry
```

### Workflow Disponible

**Archivo:** [.github/workflows/deploy-raspberry.yml](.github/workflows/deploy-raspberry.yml)

#### Triggers:
- `push` a `main`, `production`, `development`
- Manual desde GitHub UI

#### Ambientes:
- `development` → rama `development`
- `staging` → rama `main`
- `production` → rama `production` (requiere aprobación manual)

### Uso

```bash
# Desarrollo automático
git checkout development
git commit -am "feat: nueva funcionalidad"
git push origin development
# ✅ Se despliega automáticamente

# Producción manual
git checkout production
git merge main
git push origin production
# Ve a GitHub → Actions → Aprobar despliegue
```

---

## GitLab CI/CD

### Configuración de Variables

Ve a tu repositorio → Settings → CI/CD → Variables:

```
RASPBERRY_HOST = 192.168.4.177
RASPBERRY_USER = innvoid
RASPBERRY_SSH_KEY = <contenido de tu clave privada SSH>
```

**Tipo:** File (para SSH_KEY) o Variable (para HOST/USER)

### Pipeline Disponible

**Archivo:** [.gitlab-ci.yml](.gitlab-ci.yml)

#### Stages:
1. **Build** - Construcción de imágenes (si aplica)
2. **Test** - Pruebas automatizadas
3. **Deploy** - Despliegue a Raspberry

#### Ambientes:
- `development` → automático en rama `development`
- `staging` → automático en rama `main`
- `production` → manual en rama `production`

### Uso

```bash
# Desarrollo
git checkout development
git commit -am "feat: nueva funcionalidad"
git push origin development
# ✅ Se despliega automáticamente

# Producción
git checkout production
git merge main
git push origin production
# Ve a GitLab → CI/CD → Pipelines → Deploy → Play ▶️
```

---

## Kubernetes (k3s)

### ¿Por qué k3s?

k3s es una versión ligera de Kubernetes optimizada para:
- ✅ ARM (Raspberry Pi)
- ✅ Dispositivos edge/IoT
- ✅ Bajo consumo de recursos
- ✅ Configuración simplificada

**Comparación de consumo:**
- Docker Compose: ~400MB RAM base
- k3s: ~500MB RAM base
- Kubernetes completo: ~2GB RAM base

### Instalación

```bash
# Copiar script a Raspberry
scp docker/install-k3s.sh innvoid@192.168.4.177:~

# Instalar
ssh innvoid@192.168.4.177
bash install-k3s.sh

# Reiniciar (requerido la primera vez)
sudo reboot

# Verificar (después del reinicio)
kubectl get nodes
# NAME          STATUS   ROLES                  AGE   VERSION
# raspberry     Ready    control-plane,master   1m    v1.28.x
```

### Despliegue

```bash
# Desde tu Mac, usando el script
cd docker
./deploy-k8s.sh

# O manualmente
kubectl apply -f ../k8s/thingsboard-deployment.yaml
kubectl get pods -n thingsboard -w
```

### Comandos Útiles

```bash
# Ver todos los recursos
kubectl get all -n thingsboard

# Logs de un pod
kubectl logs -f deployment/thingsboard -n thingsboard

# Escalar horizontalmente
kubectl scale deployment/thingsboard --replicas=3 -n thingsboard

# Rollback a versión anterior
kubectl rollout undo deployment/thingsboard -n thingsboard

# Ver historial de despliegues
kubectl rollout history deployment/thingsboard -n thingsboard

# Health check
kubectl describe pod <pod-name> -n thingsboard
```

### Acceso a Servicios

Con k3s, los servicios se exponen vía NodePort:

- **HTTP:** http://192.168.4.177:30080
- **MQTT:** 192.168.4.177:31883

---

## Comparación de Soluciones

| Característica | Docker Compose | k3s Kubernetes |
|----------------|----------------|----------------|
| **Complejidad** | ⭐ Baja | ⭐⭐⭐ Media |
| **Recursos** | 400MB RAM | 500MB RAM |
| **Escalabilidad** | Manual | Automática |
| **Rollbacks** | Manual | Automático |
| **Health Checks** | Básico | Avanzado |
| **Multi-nodo** | ❌ No | ✅ Sí |
| **Service Mesh** | ❌ No | ✅ Sí (con Istio) |
| **Tiempo setup** | 5 min | 30 min |

### Recomendación

**Usa Docker Compose si:**
- Tienes 1-3 servicios
- No necesitas alta disponibilidad
- Quieres simplicidad

**Usa k3s si:**
- Tienes 5+ microservicios
- Necesitas auto-scaling
- Planeas crecer a múltiples Raspberry Pi
- Quieres experiencia real con Kubernetes

---

## Configuración Inicial

### 1. Configurar Git

```bash
cd /Users/pedrovalenzuela/Documents/Innvoid/Desarrollo/thingsboard

# Si no tienes Git inicializado
git init
git add .
git commit -m "Initial commit with CI/CD"

# Agregar remote (GitHub o GitLab)
git remote add origin https://github.com/tu-usuario/thingsboard.git
git push -u origin main
```

### 2. Estructura de Ramas

```bash
# Crear ramas de trabajo
git checkout -b development
git push origin development

git checkout -b production
git push origin production

git checkout main
```

**Flujo recomendado:**
```
development → main → production
  (auto)      (auto)   (manual)
```

### 3. Probar Localmente

```bash
# Simular el despliegue
cd docker
./deploy-to-raspberry.sh thingsboard development

# Verificar
ssh innvoid@192.168.4.177 "docker ps"
```

---

## Workflow Completo

### Desarrollo de Nueva Funcionalidad

```bash
# 1. Crear rama de feature
git checkout development
git checkout -b feature/nueva-funcionalidad

# 2. Desarrollar y probar localmente
# ... hacer cambios ...
docker compose up -d

# 3. Commit y push
git add .
git commit -m "feat: implementar nueva funcionalidad"
git push origin feature/nueva-funcionalidad

# 4. Crear Pull Request a development
# En GitHub/GitLab → New PR

# 5. Merge a development
# ✅ Se despliega automáticamente a ambiente de desarrollo

# 6. Verificar en desarrollo
curl http://192.168.4.177/api/test

# 7. Si todo OK, merge a main
git checkout main
git merge development
git push origin main
# ✅ Se despliega automáticamente a staging

# 8. Si todo OK, merge a production
git checkout production
git merge main
git push origin production
# En GitHub/GitLab → Aprobar despliegue manual
# ✅ Se despliega a producción
```

### Rollback de Emergencia

**Con Docker Compose:**
```bash
ssh innvoid@192.168.4.177 "
  cd ~/docker-projects/thingsboard/backups
  ls -la  # Ver backups disponibles
  cd ../docker
  docker compose down
  # Restaurar versión anterior manualmente
  docker compose up -d
"
```

**Con k3s:**
```bash
# Automático - rollback a versión anterior
kubectl rollout undo deployment/thingsboard -n thingsboard

# O a versión específica
kubectl rollout undo deployment/thingsboard --to-revision=3 -n thingsboard
```

---

## Monitoring y Logs

### Docker Compose

```bash
# Logs en tiempo real
ssh innvoid@192.168.4.177 "cd ~/docker-projects/thingsboard/docker && docker compose logs -f"

# Logs de servicio específico
ssh innvoid@192.168.4.177 "docker logs -f thingsboard-ce-tb-core1-1"

# Últimas 100 líneas
ssh innvoid@192.168.4.177 "docker logs --tail 100 thingsboard-ce-tb-core1-1"
```

### k3s

```bash
# Logs de todos los pods
kubectl logs -f deployment/thingsboard -n thingsboard

# Logs de pod específico
kubectl logs -f <pod-name> -n thingsboard

# Dashboard de Kubernetes
kubectl proxy
# Abre: http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
```

---

## Troubleshooting

### Pipeline falla con "Permission denied"

```bash
# Verificar permisos SSH
ssh innvoid@192.168.4.177 "ls -la ~/.ssh/authorized_keys"

# Regenerar y copiar clave
ssh-keygen -t ed25519 -f ~/.ssh/github_raspberry
ssh-copy-id -i ~/.ssh/github_raspberry.pub innvoid@192.168.4.177
```

### k3s no arranca pods

```bash
# Ver eventos
kubectl get events -n thingsboard --sort-by='.lastTimestamp'

# Describir pod con errores
kubectl describe pod <pod-name> -n thingsboard

# Ver logs del sistema
ssh innvoid@192.168.4.177 "sudo journalctl -u k3s -f"
```

### Despliegue lento

```bash
# Verificar recursos
ssh innvoid@192.168.4.177 "free -h && df -h"

# Aumentar swap si es necesario
ssh innvoid@192.168.4.177 "
  sudo fallocate -l 2G /swapfile
  sudo chmod 600 /swapfile
  sudo mkswap /swapfile
  sudo swapon /swapfile
"
```

---

## Próximos Pasos

1. **Configurar Secrets** en GitHub/GitLab
2. **Probar pipeline** con un commit a `development`
3. **Decidir:** ¿Docker Compose o k3s?
4. **Configurar monitoring** (Prometheus + Grafana)
5. **Agregar tests** automatizados al pipeline

---

## 📞 Referencias

- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [GitLab CI/CD Docs](https://docs.gitlab.com/ee/ci/)
- [k3s Documentation](https://docs.k3s.io/)
- [Kubernetes Docs](https://kubernetes.io/docs/)

# Guía de Despliegue Remoto a Raspberry Pi

## 🎯 Arquitectura de Gestión Remota

Esta configuración permite gestionar múltiples microservicios dockerizados en la Raspberry Pi desde cualquier red.

### Componentes Instalados:

1. **Portainer** - Interfaz web para gestión de Docker
2. **Docker Context SSH** - Acceso CLI desde tu Mac
3. **Script de Despliegue** - Automatización de actualizaciones

---

## 📍 Acceso a Portainer

### Desde la Red Local (192.168.4.x):
```
https://192.168.4.177:9443
```

### Configuración Inicial:
1. Primera vez: Crea un usuario admin con contraseña segura
2. Selecciona: "Get Started" → Gestionar ambiente local
3. Ya puedes ver y gestionar todos los contenedores

---

## 💻 Uso del Docker Context (Desde tu Mac)

### Comandos Básicos:

```bash
# Ver contextos disponibles
docker context ls

# Cambiar a Raspberry Pi
docker context use raspberry

# Ahora todos los comandos se ejecutan en la Raspberry
docker ps
docker images
docker compose up -d
docker logs thingsboard-ce-tb-core1-1

# Volver a tu Mac
docker context use default
```

### Ventajas:
- ✅ Usas tus comandos Docker locales
- ✅ Funciona desde la misma red
- ✅ No expone puertos adicionales
- ✅ Usa tu SSH existente

---

## 🚀 Script de Despliegue Automático

### Uso Básico:

```bash
cd /Users/pedrovalenzuela/Documents/Innvoid/Desarrollo/thingsboard/docker

# Desplegar ThingsBoard
./deploy-to-raspberry.sh thingsboard production

# Desplegar otro proyecto
./deploy-to-raspberry.sh mi-microservicio development
```

### Lo que hace el script:
1. ✅ Verifica conectividad
2. ✅ Crea estructura de directorios
3. ✅ Copia archivos del proyecto
4. ✅ Hace backup de versión anterior
5. ✅ Detiene contenedores viejos
6. ✅ Levanta nueva versión
7. ✅ Verifica estado

### Estructura en Raspberry:
```
~/docker-projects/
├── thingsboard/
│   ├── docker/          # Archivos docker-compose y configs
│   ├── backups/         # Backups pre-despliegue
│   └── logs/            # Logs de aplicación
├── microservicio1/
│   ├── docker/
│   ├── backups/
│   └── logs/
└── microservicio2/
    ├── docker/
    ├── backups/
    └── logs/
```

---

## 🌐 Acceso desde Otras Redes

### Opción 1: VPN (Recomendada para producción)

Instala WireGuard o Tailscale en la Raspberry:

```bash
# WireGuard
ssh innvoid@192.168.4.177
sudo apt install wireguard -y

# O Tailscale (más fácil)
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```

### Opción 2: SSH Tunnel (Temporal)

Desde cualquier red con acceso SSH:

```bash
# Crear túnel para Docker
ssh -N -L 2375:/var/run/docker.sock innvoid@TU_IP_PUBLICA:22

# En otra terminal
export DOCKER_HOST=tcp://localhost:2375
docker ps
```

### Opción 3: Cloudflare Tunnel (Acceso Web)

Para exponer Portainer de forma segura:

```bash
ssh innvoid@192.168.4.177

# Instalar cloudflared
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64.deb
sudo dpkg -i cloudflared-linux-arm64.deb

# Autenticar
cloudflared tunnel login

# Crear túnel
cloudflared tunnel create raspberry-docker

# Configurar
nano ~/.cloudflared/config.yml
```

Contenido:
```yaml
tunnel: <TUNNEL-ID>
credentials-file: /home/innvoid/.cloudflared/<TUNNEL-ID>.json

ingress:
  - hostname: portainer.tudominio.com
    service: https://localhost:9443
  - hostname: thingsboard.tudominio.com
    service: http://localhost:80
  - service: http_status:404
```

```bash
# Ejecutar
cloudflared tunnel run raspberry-docker
```

---

## 🔧 Comandos Útiles

### Gestión de Proyectos:

```bash
# Ver todos los proyectos
ssh innvoid@192.168.4.177 "ls -la ~/docker-projects/"

# Ver logs de un proyecto
ssh innvoid@192.168.4.177 "cd ~/docker-projects/thingsboard/docker && docker compose logs -f"

# Reiniciar un proyecto
ssh innvoid@192.168.4.177 "cd ~/docker-projects/thingsboard/docker && docker compose restart"

# Ver estadísticas de recursos
ssh innvoid@192.168.4.177 "docker stats"
```

### Backup Manual:

```bash
# Crear backup de volúmenes
ssh innvoid@192.168.4.177 "cd ~/docker-projects/thingsboard/docker && \
  docker run --rm -v thingsboard-ce_tb-postgres-data:/data -v ~/backups:/backup \
  alpine tar czf /backup/thingsboard-db-\$(date +%Y%m%d).tar.gz /data"
```

### Limpieza:

```bash
# Limpiar imágenes no usadas
ssh innvoid@192.168.4.177 "docker image prune -a"

# Limpiar volúmenes huérfanos
ssh innvoid@192.168.4.177 "docker volume prune"
```

---

## 📊 Monitoreo

### Portainer:
- Dashboard con uso de CPU, RAM, red
- Logs en tiempo real
- Consola interactiva
- Gestión de stacks

### CLI:
```bash
# Uso de recursos
docker context use raspberry
docker stats

# Estado de contenedores
docker ps -a

# Logs en tiempo real
docker compose -f ~/docker-projects/thingsboard/docker/docker-compose.yml logs -f
```

---

## 🔐 Seguridad

### Recomendaciones:

1. **Cambiar contraseñas por defecto**
   - Portainer: Contraseña fuerte
   - ThingsBoard: `tenant@thingsboard.org` / nueva contraseña

2. **Firewall**
   ```bash
   ssh innvoid@192.168.4.177
   sudo ufw enable
   sudo ufw allow 22/tcp      # SSH
   sudo ufw allow 80/tcp      # HTTP
   sudo ufw allow 443/tcp     # HTTPS
   sudo ufw allow 9443/tcp    # Portainer (solo red local)
   sudo ufw allow 1883/tcp    # MQTT
   ```

3. **Autenticación SSH con llaves**
   ```bash
   # En tu Mac
   ssh-keygen -t ed25519 -C "tu@email.com"
   ssh-copy-id innvoid@192.168.4.177
   ```

4. **Actualizar regularmente**
   ```bash
   ssh innvoid@192.168.4.177
   sudo apt update && sudo apt upgrade -y
   ```

---

## 🎓 Workflows Recomendados

### Desarrollo Local → Raspberry:

1. Desarrolla y prueba localmente
2. Commitea cambios a Git
3. Deploy a Raspberry:
   ```bash
   ./deploy-to-raspberry.sh proyecto development
   ```
4. Verifica en Portainer
5. Cuando esté listo para producción:
   ```bash
   ./deploy-to-raspberry.sh proyecto production
   ```

### Actualización desde Otra Red:

1. Conecta a VPN/Tailscale
2. Usa Docker Context:
   ```bash
   docker context use raspberry
   cd ~/tu-proyecto
   docker compose pull
   docker compose up -d
   ```

---

## 📝 Troubleshooting

### Portainer no carga:
```bash
ssh innvoid@192.168.4.177
docker restart portainer
docker logs portainer
```

### Docker Context falla:
```bash
docker context rm raspberry
docker context create raspberry --docker "host=ssh://innvoid@192.168.4.177"
```

### Contenedores no inician:
```bash
docker context use raspberry
docker compose logs
docker inspect <container-name>
```

---

## 🔗 URLs Importantes

- **Portainer**: https://192.168.4.177:9443
- **ThingsBoard**: http://192.168.4.177
- **Script Deploy**: `/Users/pedrovalenzuela/Documents/Innvoid/Desarrollo/thingsboard/docker/deploy-to-raspberry.sh`

---

## 📞 Soporte

Para más información sobre comandos Docker y Compose:
- Docker Docs: https://docs.docker.com
- Portainer Docs: https://docs.portainer.io
- Compose Docs: https://docs.docker.com/compose/

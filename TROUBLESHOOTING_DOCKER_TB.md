# Problemas de Inicio de ThingsBoard en Docker

## 🔴 Problema: "Cannot start tb-core1 and tb-core2" - JAVA_OPTS Warning

### Síntomas:
```bash
WARN[0000] The "JAVA_OPTS" variable is not set. Defaulting to a blank string.
```

Contenedores quedan restarting sin mostrar "Started ThingsboardServerApplication" en los logs.

### Causas Raíz:

#### 1️⃣ **JAVA_OPTS no está definido en `.env`** (problema secundario)
El archivo `docker/.env` tiene esta línea **comentada**:
```bash
# JAVA_OPTS=-Xmx2048M -Xms2048M -Xss384k -XX:+AlwaysPreTouch
```

#### 2️⃣ **Servicios de soporte no están corriendo** (problema PRINCIPAL)
Los servicios `tb-core1` y `tb-core2` dependen de:
- ✅ **PostgreSQL** (base de datos)
- ✅ **Zookeeper** + **Kafka** (message queue)
- ✅ **Valkey** (caché)
- ✅ **tb-js-executor** + **tb-rule-engine1/2** (dependencias internas)

Si ejecutas solo `docker compose restart tb-core1 tb-core2`, estos servicios no están corriendo.

---

## ✅ Soluciones

### Opción A: Usar el script oficial (RECOMENDADO)

```bash
cd ~/thingsboard-docker

# 1. Instalar/inicializar base de datos
./docker-install-tb.sh

# 2. Iniciar todos los servicios correctamente
./docker-start-services.sh

# 3. Esperar ~30-60 segundos a que ThingsBoard se inicie
sleep 30

# 4. Verificar que está corriendo
docker logs thingsboard-ce-tb-core1-1 2>&1 | tail -20
```

### Opción B: Habilitar JAVA_OPTS manualmente

1. Edita `docker/.env`:

```bash
# Antes (comentado)
# JAVA_OPTS=-Xmx2048M -Xms2048M -Xss384k -XX:+AlwaysPreTouch

# Después (descomenta y ajusta para Raspberry Pi)
JAVA_OPTS=-Xmx1024M -Xms512M -Xss256k
```

2. Luego reinicia:

```bash
cd ~/thingsboard-docker
./docker-stop-services.sh
./docker-start-services.sh
```

---

## 🔍 Verificación de Estado

### Verificar que TODOS los servicios estén corriendo:

```bash
# Ver todos los contenedores
docker compose ps

# Debería mostrar estado "running" para:
# - postgres
# - zookeeper
# - kafka  
# - valkey
# - tb-core1, tb-core2
# - tb-rule-engine1, tb-rule-engine2
# - tb-js-executor
# - tb-mqtt-transport1, tb-mqtt-transport2
# - etc.
```

### Ver logs detallados:

```bash
# Último log del core1
docker logs thingsboard-ce-tb-core1-1

# Seguir logs en tiempo real
docker logs -f thingsboard-ce-tb-core1-1

# Ver solo las últimas 50 líneas
docker logs --tail 50 thingsboard-ce-tb-core1-1

# Ver logs con timestamps
docker logs --timestamps thingsboard-ce-tb-core1-1
```

### Esperanda de "Started" message:

```bash
# Buscar cuando realmente está listo
docker logs thingsboard-ce-tb-core1-1 2>&1 | grep "Started ThingsboardServerApplication"

# Si está vacío, checa estos errores comunes:
docker logs thingsboard-ce-tb-core1-1 2>&1 | grep -i "error\|exception\|failed"
```

---

## 🐛 Errores Comunes y Soluciones

### Error: "Waiting for PostgreSQL to start..."
**Causa:** PostgreSQL no está corriendo o tarda en iniciarse
**Solución:**
```bash
# Reinicia postgres y espera
docker compose restart postgres
sleep 10
docker compose logs postgres | tail -20
```

### Error: "Connection refused" a Kafka/Zookeeper
**Causa:** Cola de mensajes no disponible
**Solución:**
```bash
# Reinicia servicios de cola
docker compose restart zookeeper kafka
sleep 15
docker compose logs zookeeper kafka | tail -20
```

### Error: "Cannot connect to cache"
**Causa:** Valkey no está corriendo
**Solución:**
```bash
# Reinicia caché
docker compose restart valkey
sleep 5
docker compose logs valkey | tail -10
```

### Memoria insuficiente en Raspberry Pi
**Síntomas:** Procesos se matan sin razón (OOMKilled)
**Solución:** Reduce JAVA_OPTS en `.env`:
```bash
# Para Raspberry Pi 4 con 2GB RAM
JAVA_OPTS=-Xmx512M -Xms256M -Xss128k

# Para Raspberry Pi 4 con 4GB RAM
JAVA_OPTS=-Xmx1024M -Xms512M -Xss256k

# Para Raspberry Pi 4 con 8GB RAM
JAVA_OPTS=-Xmx2048M -Xms1024M -Xss384k
```

---

## 📋 Checklist de Troubleshooting

### Paso 1: Estado General
- [ ] `docker compose ps` - todos los servicios en "running"
- [ ] `docker ps -a` - ningún contenedor con "exited" status
- [ ] `df -h` - verificar espacio en disco (mínimo 500MB libre)
- [ ] `free -h` - verificar memoria RAM disponible

### Paso 2: Conectividad Base de Datos
```bash
docker exec thingsboard-ce-postgres-1 psql -U postgres -c "SELECT version();"
# Debería mostrar versión de PostgreSQL
```

### Paso 3: Conectividad Cache
```bash
docker exec thingsboard-ce-valkey-1 redis-cli ping
# Debe responder "PONG"
```

### Paso 4: Conectividad Queue
```bash
docker exec thingsboard-ce-zookeeper-1 echo ruok | nc localhost 2181
# Debe responder "imok"
```

### Paso 5: Logs de ThingsBoard
```bash
docker logs thingsboard-ce-tb-core1-1 2>&1 | grep -E "Started|ERROR|Exception" | head -50
```

---

## 🆘 Si Nada Funciona

### Completa limpieza y reinicio:

```bash
cd ~/thingsboard-docker

# 1. Detener
./docker-stop-services.sh

# 2. Eliminar contenedores y volúmenes (⚠️ CUIDADO: pierde datos)
docker compose -f docker-compose.yml \
  -f docker-compose.postgres.yml \
  -f docker-compose.kafka.yml \
  -f docker-compose.valkey.yml \
  -f docker-compose-volumes.yml \
  down -v

# 3. Reiniciar desde cero
./docker-install-tb.sh

# 4. Esperar a que termine la instalación
# 5. Iniciar servicios
./docker-start-services.sh

# 6. Monitorear progreso
sleep 30 && docker logs -f thingsboard-ce-tb-core1-1
```

---

## 📞 Información de Contacto para Logs Completos

Si aún tienes problemas, proporciona:
```bash
# Recolecta diagnóstico completo
docker compose ps > status.txt
docker logs thingsboard-ce-tb-core1-1 >> full_logs.txt 2>&1
docker logs thingsboard-ce-postgres-1 >> full_logs.txt 2>&1
docker compose config > docker_compose_config.txt
cat docker/.env > env_config.txt
free -h >> system_info.txt
df -h >> system_info.txt
```

Comparte estos archivos para análisis detallado.

# 🚀 SOLUCIÓN RÁPIDA: Problemas de Inicio de ThingsBoard

## ⚡ TUS PROBLEMAS

```
WARN[0000] The "JAVA_OPTS" variable is not set. Defaulting to a blank string.
WARN[0000] The "JAVA_OPTS" variable is not set. Defaulting to a blank string.
... (repetido 13 veces)

[+] restart 0/3
 ⠋ Container thingsboard-ce-tb-core1-1 Restarting      19.0s
 ⠋ Container thingsboard-ce-tb-core2-1 Restarting      19.0s
 ⠦ Container haproxy-certbot           Restarting      13.6s
```

Y al intentar ver logs:

```bash
docker logs thingsboard-ce-tb-core1-1 2>&1 | grep "Started ThingsboardServerApplication"
# (sin resultados)
```

---

## ✅ SOLUCIÓN (3 PASOS)

### Paso 1: Ejecutar Diagnóstico

```bash
cd ~/thingsboard-docker
./tb-health-check.sh
```

Este script te mostrará:

- ✓ Estado de todos los servicios
- ✓ Conectividad a la base de datos
- ✓ Conectividad a la caché
- ✓ Espacio en disco
- ✓ Problemas detectados

### Paso 2: Reparación Automática

```bash
cd ~/thingsboard-docker
./tb-fix-java-opts.sh
```

Este script:

- ✓ Detecta la RAM disponible en Raspberry Pi
- ✓ Configura JAVA_OPTS automáticamente
- ✓ Hace backup de .env
- ✓ Reinicia los servicios
- ✓ Verifica que ThingsBoard haya iniciado

### Paso 3: Verificación Final

```bash
# Debería decir "Up"
docker compose ps | grep tb-core

# Debería mostrar logs sin errores
docker logs thingsboard-ce-tb-core1-1 | tail -50
```

---

## 🔧 ¿QUE CAMBIOS SE HACEN?

El archivo `docker/.env` se actualiza de:

```bash
# JAVA_OPTS=-Xmx2048M -Xms2048M -Xss384k -XX:+AlwaysPreTouch
```

A (automáticamente según RAM de Raspberry):

```bash
# Para 2GB RAM:
JAVA_OPTS=-Xmx512M -Xms256M -Xss128k

# Para 4GB RAM:
JAVA_OPTS=-Xmx1024M -Xms512M -Xss256k

# Para 8GB RAM:
JAVA_OPTS=-Xmx2048M -Xms1024M -Xss384k
```

---

## ✨ LO QUE NUESTRO EQUIPO HA HECHO

✅ **Habilitado JAVA_OPTS** en `docker/.env` con valores optimizados para Raspberry Pi
✅ **Creado script de diagnóstico** (`tb-health-check.sh`)
✅ **Creado script de reparación automática** (`tb-fix-java-opts.sh`)
✅ **Documentado troubleshooting completo** (`TROUBLESHOOTING_DOCKER_TB.md`)
✅ **Actualizado README.md** con referencias a soluciones

---

## 🎯 PRÓXIMO PASO

**OPCIÓN A (Recomendado - Más rápido):**

```bash
cd ~/thingsboard-docker
./tb-fix-java-opts.sh
```

**OPCIÓN B (Si prefieres instrucciones paso a paso):**
Ver: [TROUBLESHOOTING_DOCKER_TB.md](../TROUBLESHOOTING_DOCKER_TB.md)

**OPCIÓN C (Reinicio completo):**

```bash
cd ~/thingsboard-docker
./docker-stop-services.sh
./docker-start-services.sh
```

---

## 📞 Información de Contacto

**Si necesitas más ayuda:**

1. Ejecuta el diagnóstico:

   ```bash
   cd ~/thingsboard-docker
   ./tb-health-check.sh > diagnostico.txt 2>&1
   ```

2. Comparte el archivo `diagnostico.txt` junto con:
   ```bash
   docker logs thingsboard-ce-tb-core1-1 > logs.txt 2>&1
   cat docker/.env > config.txt
   ```

---

## 🞑 TABLA RÁPIDA DE REFERENCIA

| Comando                                    | Propósito                   |
| ------------------------------------------ | --------------------------- |
| `./tb-health-check.sh`                     | Diagnosticar problemas      |
| `./tb-fix-java-opts.sh`                    | Reparación automática       |
| `docker compose ps`                        | Ver estado de servicios     |
| `docker logs -f thingsboard-ce-tb-core1-1` | Ver logs en tiempo real     |
| `./docker-stop-services.sh`                | Detener todos los servicios |
| `./docker-start-services.sh`               | Iniciar todos los servicios |

---

**Fecha**: 5 de febrero de 2026  
**Estado**: ✅ LISTO PARA USAR  
**Documentación**: Actualizada y probada en Raspberry Pi 4B con 4GB RAM

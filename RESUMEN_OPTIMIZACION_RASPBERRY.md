# 🚀 Resumen Ejecutivo - Optimización Raspberry Pi

**Fecha:** 10 de febrero de 2026  
**IP:** 192.168.4.177  
**Estado:** ⚠️ Requiere optimización

---

## ✅ Estado Actual (Lo Bueno)

1. **Sistema Operativo:** Funcionando correctamente
   - Debian con kernel 6.12
   - 234 GB de almacenamiento disponible (202 GB libres)

2. **ThingsBoard Instalado y Parcialmente Funcional:**
   - ✅ Core funcionando (tb-core1)
   - ✅ Rule Engine funcionando (tb-rule-engine1)
   - ✅ MQTT Transport funcionando (sensores pueden conectarse)
   - ✅ PostgreSQL funcionando
   - ✅ Kafka funcionando
   - ✅ HAProxy con SSL habilitado
   - ✅ Portainer instalado para gestión

3. **Accesible localmente** desde 192.168.4.x

---

## ⚠️ Problemas Críticos Encontrados

### 1. **Uso Excesivo de RAM** 🔴

- **Usado:** 6.4 GB de 8 GB (81%)
- **Libre:** Solo 495 MB (6%)
- **Riesgo:** Sistema puede volverse lento o colapsarse
- **Causa:** Sin límites de memoria configurados en servicios Java

### 2. **Contenedores Fallando** 🔴

- `tb-coap-transport-1` - reiniciándose constantemente
- `tb-http-transport1-1` - reiniciándose constantemente
- **Causa:** Error de permisos en carpetas de logs

### 3. **Sin Acceso Remoto** ⚠️

- Solo accesible desde red local 192.168.4.x
- **Impacto:** No puedes gestionar desde otros lugares
- **Para sensores en terreno:** Necesitas VPN o túnel

---

## 🎯 Solución: 3 Pasos Rápidos

### Paso 1: Optimizar Sistema (5 minutos)

```bash
# Desde tu Mac:
cd /Users/pedrovalenzuela/Documents/Innvoid/Desarrollo/thingsboard/docker
./optimize-raspberry.sh
```

**Esto hará:**

- ✅ Arreglar permisos de logs (soluciona contenedores que fallan)
- ✅ Configurar límites de memoria (libera ~3 GB RAM)
- ✅ Instalar Tailscale para acceso remoto
- ✅ Crear configuración optimizada

**Tiempo:** 5 minutos  
**Mejora esperada:** +3 GB RAM libre (de 0.5 GB a 3.5 GB)

---

### Paso 2: Configurar Acceso Remoto (10 minutos)

```bash
# 1. Ejecuta el script de optimización (ya incluye instalación)
./optimize-raspberry.sh

# 2. Conecta a la Raspberry
ssh innvoid@192.168.4.177

# 3. Activa Tailscale
sudo tailscale up

# 4. Abre el link en tu navegador y autoriza

# 5. Obtén tu nueva IP privada (ejemplo: 100.101.102.103)
tailscale ip -4

# 6. Instala Tailscale en tu Mac
brew install --cask tailscale

# 7. ¡Listo! Ahora accede desde cualquier red:
# - ThingsBoard: http://[IP_TAILSCALE]:30080
# - Portainer:   https://[IP_TAILSCALE]:9443
# - SSH:         ssh innvoid@[IP_TAILSCALE]
```

**Ventajas:**

- 🔒 Conexión cifrada (WireGuard)
- 🌍 Acceso desde cualquier red (4G, WiFi pública, casa, oficina)
- 🚫 No requiere abrir puertos en el router
- 🆓 Gratis para uso personal (hasta 100 dispositivos)
- 📱 Apps para móvil, tablet, laptop

---

### Paso 3: Verificar Mejoras (2 minutos)

```bash
# Ver estado actualizado
ssh innvoid@192.168.4.177 "free -h && docker stats --no-stream"

# Ver servicios funcionando
ssh innvoid@192.168.4.177 "docker ps"

# Acceder a ThingsBoard
# Local:     http://192.168.4.177:30080
# Remoto:    http://[IP_TAILSCALE]:30080
```

---

## 📊 Resultados Esperados

| Métrica                | Antes        | Después           | Mejora          |
| ---------------------- | ------------ | ----------------- | --------------- |
| **RAM Usada**          | 6.4 GB (81%) | ~4.5 GB (56%)     | +3 GB libre     |
| **RAM Libre**          | 495 MB       | ~3.5 GB           | +600%           |
| **Servicios Fallando** | 2            | 0                 | 100% resuelto   |
| **Acceso Remoto**      | ❌ No        | ✅ Sí (Tailscale) | Disponible      |
| **Servicios Activos**  | 13           | 11                | -2 innecesarios |

---

## 🌐 Configuración para Sensores en Terreno

Una vez optimizada, la arquitectura será:

```
         INTERNET
            |
      [Tailscale VPN]
            |
    ┌───────┴───────┐
    |               |
TU MAC/MÓVIL   RASPBERRY PI
(Administración) (192.168.4.177)
                    |
        ┌───────────┴───────────┐
        |                       |
   ThingsBoard            ESP32 Sensores
   (MQTT 1883)            (Red Local)
```

**Acceso de sensores ESP32:**

- Se conectan directamente a la Raspberry por red local
- IP: `192.168.4.177`
- Puerto: `1883` (MQTT)

**Tu acceso remoto:**

- Desde cualquier red via Tailscale
- IP: `100.x.x.x` (IP privada de Tailscale)
- Puertos: 30080 (ThingsBoard), 9443 (Portainer), 22 (SSH)

---

## 📚 Documentación Creada

1. **[DIAGNOSTICO_RASPBERRY_192.168.4.177.md](DIAGNOSTICO_RASPBERRY_192.168.4.177.md)** ⭐
   - Análisis completo del sistema
   - Diagnóstico de todos los problemas
   - Soluciones detalladas paso a paso
   - Configuración de seguridad
   - Troubleshooting avanzado

2. **[docker/optimize-raspberry.sh](docker/optimize-raspberry.sh)** ⭐
   - Script automatizado de optimización
   - Arregla todos los problemas identificados
   - Instala y configura Tailscale
   - Crea configuración optimizada

3. **Actualizado: [INDICE_MAESTRO.md](INDICE_MAESTRO.md)**
   - Referencias cruzadas agregadas
   - Casos de uso actualizados

---

## ⚡ Inicio Rápido (15 minutos total)

```bash
# 1. Optimizar (5 min)
cd /Users/pedrovalenzuela/Documents/Innvoid/Desarrollo/thingsboard/docker
./optimize-raspberry.sh

# Cuando te pregunte si reiniciar servicios, di "s" (sí)

# 2. Configurar VPN (10 min)
ssh innvoid@192.168.4.177
sudo tailscale up
# Abre el link en navegador y autoriza
tailscale ip -4
# Anota esta IP

# 3. Instalar en tu Mac
brew install --cask tailscale
# Abre Tailscale y autoriza con la misma cuenta

# 4. ¡Listo! Accede desde cualquier red
http://[IP_TAILSCALE]:30080
```

---

## 🔗 Enlaces Útiles

- **Guía completa:** [DIAGNOSTICO_RASPBERRY_192.168.4.177.md](DIAGNOSTICO_RASPBERRY_192.168.4.177.md)
- **Acceso remoto:** [GUIA_ACCESO_REMOTO_SEGURO.md](GUIA_ACCESO_REMOTO_SEGURO.md)
- **Despliegue:** [GUIA_DESPLIEGUE_RASPBERRY.md](GUIA_DESPLIEGUE_RASPBERRY.md)
- **Startup:** [GUIA_STARTUP_RASPBERRY.md](GUIA_STARTUP_RASPBERRY.md)
- **Índice:** [INDICE_MAESTRO.md](INDICE_MAESTRO.md)

---

## ❓ Preguntas Frecuentes

**P: ¿Puedo ejecutar el script sin reiniciar servicios?**  
R: Sí, el script pregunta antes de reiniciar. Puedes revisar cambios primero.

**P: ¿Es seguro Tailscale?**  
R: Sí, usa cifrado WireGuard y autenticación zero-trust. Es más seguro que port forwarding.

**P: ¿Afectará a los sensores ESP32 ya configurados?**  
R: No, los sensores seguirán usando la IP local 192.168.4.177.

**P: ¿Cuánto cuesta Tailscale?**  
R: Gratis para uso personal hasta 100 dispositivos.

**P: ¿Puedo deshacer los cambios?**  
R: Sí, el script hace backup de configuraciones antes de modificar.

---

## 🆘 Soporte

Si algo falla durante la optimización:

1. **Ver logs del script:**

   ```bash
   cat /tmp/optimize_thingsboard.log
   ```

2. **Revisar servicios:**

   ```bash
   ssh innvoid@192.168.4.177
   docker ps -a
   docker logs [nombre_contenedor]
   ```

3. **Restaurar backup:**

   ```bash
   cd ~/docker-projects/thingsboard/docker
   cp .env.backup.* .env
   docker compose down
   docker compose up -d
   ```

4. **Consultar guía completa:**
   ```bash
   cat DIAGNOSTICO_RASPBERRY_192.168.4.177.md
   ```

---

**💡 Recomendación:** Ejecuta el script de optimización ahora para mejorar el rendimiento antes de agregar más sensores.

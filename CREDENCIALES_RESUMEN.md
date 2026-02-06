# 🔐 Respuestas Rápidas - Credenciales ThingsBoard

## ❓ ¿Necesito crear cuenta para usar ThingsBoard local?

### **NO** ❌

Cuando instalas ThingsBoard con Docker en tu máquina local:

- ✅ **NO necesitas** registrarte en ningún sitio web
- ✅ **NO necesitas** internet (excepto para descargar imágenes Docker la primera vez)
- ✅ Se crean usuarios **automáticamente** durante la instalación
- ✅ Todo funciona **100% local** en tu computadora

---

## 👤 Credenciales por defecto

### Instalación básica

```bash
cd docker
./docker-install-tb.sh
./docker-start-services.sh
```

**Usuario creado:**
```
Email:    sysadmin@thingsboard.org
Password: sysadmin
Rol:      System Administrator
```

### Instalación con datos demo

```bash
cd docker
./docker-install-tb.sh --loadDemo
./docker-start-services.sh
```

**Usuarios creados:**

| Rol | Email | Password | Permisos |
|-----|-------|----------|----------|
| **System Admin** | `sysadmin@thingsboard.org` | `sysadmin` | Todo el sistema |
| **Tenant Admin** | `tenant@thingsboard.org` | `tenant` | Su tenant |
| **Customer User** | `customer@thingsboard.org` | `customer` | Ver dashboards |

---

## 🔑 ¿Qué es un Access Token?

Un **Access Token** es como una "contraseña" que identifica a un dispositivo IoT.

### Diferencias clave:

| Concepto | Para qué se usa | Ejemplo |
|----------|-----------------|---------|
| **Usuario/Password** | Login en interfaz web | `tenant@thingsboard.org` / `tenant` |
| **Access Token** | Dispositivos envían datos | `A1_WEATHER_SENSOR_TOKEN` |
| **JWT Token** | API REST (temporal, expira) | `eyJhbGciOiJIUzUxMiJ9...` |

### ¿Cuándo necesitas cada uno?

**Usuario/Password** 👤
- Iniciar sesión en `http://localhost`
- Gestionar dispositivos desde la web
- Ver dashboards

**Access Token** 📡
- Enviar datos desde un sensor
- Publicar telemetría por MQTT
- POST de datos por HTTP

---

## 🚀 Inicio rápido (5 minutos)

### 1. Instalar y arrancar

```bash
cd docker
./docker-install-tb.sh --loadDemo
./docker-start-services.sh

# Esperar 2-3 minutos
```

### 2. Acceder a la interfaz

```
URL: http://localhost
Email: tenant@thingsboard.org
Password: tenant
```

### 3. Crear un dispositivo

```
Menú → Devices → + (Add Device)
Nombre: Mi Sensor
Type: default
→ Add
```

### 4. Obtener Access Token

```
Click en "Mi Sensor" → Pestaña "Credentials"
Copiar el Access Token mostrado
```

### 5. Enviar datos

```bash
# Reemplaza YOUR_ACCESS_TOKEN con el token copiado
curl -X POST http://localhost:8080/api/v1/YOUR_ACCESS_TOKEN/telemetry \
  -H "Content-Type: application/json" \
  -d '{"temperature": 25.5, "humidity": 60}'
```

### 6. Ver los datos

```
Devices → Mi Sensor → Latest telemetry
¡Deberías ver temperature: 25.5 y humidity: 60!
```

---

## 🛠️ Script de gestión de credenciales

He creado un script interactivo para gestionar credenciales:

```bash
cd docker
./manage_credentials.sh
```

**Funcionalidades:**
- ✅ Ver credenciales por defecto
- ✅ Verificar login de usuario
- ✅ Listar dispositivos y sus Access Tokens
- ✅ Crear nuevos dispositivos
- ✅ Probar envío de datos

---

## 📚 Documentación completa

Para más detalles, consulta:

1. **[GUIA_CREDENCIALES.md](../GUIA_CREDENCIALES.md)** - Guía completa de autenticación
2. **[MANUAL_CONFIGURACION.md](../MANUAL_CONFIGURACION.md)** - Manual general de ThingsBoard
3. **[docker/README.md](README.md)** - Instrucciones de Docker

---

## 🔧 Comandos útiles

```bash
# Ver si ThingsBoard está corriendo
docker-compose ps

# Ver logs
docker-compose logs -f tb-core1

# Detener servicios
./docker-stop-services.sh

# Reiniciar desde cero (borra todo)
./docker-remove-services.sh
./docker-install-tb.sh --loadDemo
./docker-start-services.sh
```

---

## ❓ Preguntas frecuentes

### ¿Puedo cambiar las contraseñas por defecto?

**Sí.** Desde la interfaz web:
```
Login → Profile (esquina superior derecha) → Change password
```

### ¿Los Access Tokens son únicos?

**Sí.** Cada dispositivo tiene su propio Access Token único generado automáticamente.

### ¿Puedo personalizar un Access Token?

**Sí.** Al crear o editar un dispositivo, puedes cambiar el token en la pestaña "Credentials".

### ¿Los datos persisten después de detener Docker?

**Sí.** Los datos se guardan en volúmenes de Docker. Solo se borran si ejecutas:
```bash
./docker-remove-services.sh  # Borra TODO incluyendo datos
```

### ¿Necesito crear un tenant?

**Depende:**
- Si usas `--loadDemo`: Ya hay un tenant creado (`tenant@thingsboard.org`)
- Si no: Puedes crear tenants desde el usuario `sysadmin@thingsboard.org`
- **Recomendación**: Usa `--loadDemo` para empezar rápido

---

## 📞 Ayuda

Si tienes problemas:

1. **Verifica que ThingsBoard esté corriendo:**
   ```bash
   docker-compose ps
   curl http://localhost:8080/api/noauth/health
   ```

2. **Revisa los logs:**
   ```bash
   docker-compose logs tb-core1
   ```

3. **Usa el script de gestión:**
   ```bash
   cd docker
   ./manage_credentials.sh
   ```

---

**Última actualización:** 30 de enero de 2026

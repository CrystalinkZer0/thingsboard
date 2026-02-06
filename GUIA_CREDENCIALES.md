# Guía de Credenciales y Autenticación en ThingsBoard

**Fecha**: Enero 2026  
**Versión ThingsBoard**: 4.4.0

---

## 📋 Índice

1. [Tipos de credenciales en ThingsBoard](#tipos-de-credenciales)
2. [Instalación local con Docker - ¿Necesitas cuenta?](#instalación-local-con-docker)
3. [Usuarios y roles por defecto](#usuarios-y-roles-por-defecto)
4. [Access Tokens de dispositivos](#access-tokens-de-dispositivos)
5. [Crear nuevos tenants](#crear-nuevos-tenants)
6. [Generar y gestionar Access Tokens](#generar-y-gestionar-access-tokens)
7. [Ejemplos prácticos](#ejemplos-prácticos)

---

## Tipos de credenciales en ThingsBoard

ThingsBoard maneja **dos tipos principales** de credenciales:

### 1. **Credenciales de Usuario** (Usuario/Contraseña)
Para acceder a la interfaz web y APIs REST.

```
┌──────────────────────────────────────┐
│  Usuario: email@example.com          │
│  Contraseña: tu_contraseña           │
│  Rol: Tenant Admin / Customer User   │
└──────────────────────────────────────┘
```

**Uso**: Login en interfaz web, obtener JWT tokens para APIs

### 2. **Credenciales de Dispositivo** (Access Token)
Para que dispositivos/sensores envíen datos.

```
┌──────────────────────────────────────┐
│  Access Token: dGVzdF9kZXZpY2U=     │
│  Device ID: 1234-5678-90ab-cdef      │
└──────────────────────────────────────┘
```

**Uso**: Enviar telemetría por MQTT, HTTP, CoAP

---

## Instalación local con Docker - ¿Necesitas cuenta?

### ❌ **NO necesitas crear cuenta externa**

Cuando instalas ThingsBoard localmente con Docker:

1. **Se crea automáticamente** un usuario System Administrator
2. **NO necesitas** registrarte en ningún sitio web
3. **NO necesitas** internet para usar ThingsBoard
4. **Todo es local** en tu máquina

### ✅ **Credenciales por defecto tras instalación**

#### A. Instalación sin datos demo

```bash
cd docker
./docker-install-tb.sh
./docker-start-services.sh
```

**Credenciales creadas automáticamente:**

```
System Administrator (Superusuario)
├─ Email: sysadmin@thingsboard.org
├─ Password: sysadmin
└─ Permisos: Gestión total del sistema
```

#### B. Instalación CON datos demo

```bash
cd docker
./docker-install-tb.sh --loadDemo
./docker-start-services.sh
```

**Credenciales creadas automáticamente:**

```
System Administrator
├─ Email: sysadmin@thingsboard.org
├─ Password: sysadmin
└─ Permisos: Gestión total del sistema

Tenant Administrator (Inquilino de ejemplo)
├─ Email: tenant@thingsboard.org
├─ Password: tenant
└─ Permisos: Gestión de su tenant

Customer User (Usuario cliente de ejemplo)
├─ Email: customer@thingsboard.org
├─ Password: customer
└─ Permisos: Ver dashboards asignados
```

---

## Usuarios y roles por defecto

### Jerarquía de usuarios en ThingsBoard

```
┌─────────────────────────────────────────────────┐
│         SYSTEM ADMINISTRATOR                    │
│  • Gestiona toda la plataforma                  │
│  • Crea y gestiona Tenants                      │
│  • Configura sistema global                     │
└──────────────────┬──────────────────────────────┘
                   │
      ┌────────────┴────────────┐
      │                         │
┌─────▼──────────────┐  ┌──────▼─────────────────┐
│  TENANT ADMIN      │  │  TENANT ADMIN          │
│  (Tenant A)        │  │  (Tenant B)            │
│  • Gestiona        │  │  • Gestiona            │
│    dispositivos    │  │    dispositivos        │
│  • Crea Customers  │  │  • Crea Customers      │
│  • Configura Rules │  │  • Configura Rules     │
└─────┬──────────────┘  └──────┬─────────────────┘
      │                        │
┌─────▼──────────────┐  ┌──────▼─────────────────┐
│  CUSTOMER USER     │  │  CUSTOMER USER         │
│  • Ve dashboards   │  │  • Ve dashboards       │
│  • Solo lectura    │  │  • Solo lectura        │
└────────────────────┘  └────────────────────────┘
```

### Explicación de roles

| Rol | Descripción | Puede crear | Acceso |
|-----|-------------|-------------|--------|
| **System Admin** | Superusuario | Tenants, configuración global | Todo el sistema |
| **Tenant Admin** | Administrador de inquilino | Dispositivos, Customers, Rules | Su tenant |
| **Customer User** | Usuario final | Nada (solo lectura) | Dashboards asignados |

---

## Access Tokens de dispositivos

### ¿Qué es un Access Token?

Un **Access Token** es como una "contraseña" que identifica a un dispositivo IoT cuando envía datos.

```
Dispositivo físico
     │
     │ Envía datos con Access Token
     │
     ▼
┌─────────────────────────┐
│  ThingsBoard            │
│  Verifica token         │
│  Asocia con dispositivo │
└─────────────────────────┘
```

### ¿Cuándo necesitas Access Token?

✅ **SÍ necesitas Access Token cuando**:
- Envías datos de telemetría desde un sensor
- Publicas datos por MQTT
- Haces POST de datos por HTTP
- Un dispositivo físico se conecta

❌ **NO necesitas Access Token cuando**:
- Inicias sesión en la interfaz web
- Usas la API REST con JWT token
- Navegas por los dashboards

---

## Crear nuevos tenants

### Método 1: Desde la interfaz web

1. **Login como System Administrator**
   ```
   http://localhost
   Email: sysadmin@thingsboard.org
   Password: sysadmin
   ```

2. **Ir a Tenants**
   - Menú izquierdo → **Tenants**
   - Click en **+** (Add Tenant)

3. **Completar formulario**
   ```
   Title: Mi Empresa IoT
   Email: admin@miempresa.com
   Region: us-east
   ```

4. **Crear usuario administrador para el tenant**
   - Después de crear el tenant, haz click en él
   - Pestaña **"Users"**
   - Click **+** (Add User)
   ```
   Email: admin@miempresa.com
   Password: password123
   First Name: Admin
   Last Name: Empresa
   ```

### Método 2: Mediante API REST

```bash
# 1. Obtener token como System Administrator
TOKEN=$(curl -s -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "sysadmin@thingsboard.org",
    "password": "sysadmin"
  }' | jq -r '.token')

# 2. Crear nuevo tenant
curl -X POST http://localhost:8080/api/tenant \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "title": "Mi Empresa IoT",
    "region": "us-east",
    "email": "admin@miempresa.com"
  }'

# 3. Crear usuario administrador para ese tenant
curl -X POST http://localhost:8080/api/user \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "email": "admin@miempresa.com",
    "firstName": "Admin",
    "lastName": "Empresa",
    "authority": "TENANT_ADMIN"
  }'
```

---

## Generar y gestionar Access Tokens

### Método 1: Crear dispositivo con token desde interfaz web

1. **Login como Tenant Admin**
   ```
   Email: tenant@thingsboard.org  (o tu usuario)
   Password: tenant
   ```

2. **Crear dispositivo**
   - Menú → **Devices**
   - Click **+** (Add Device)
   - Name: `Sensor Temperatura 01`
   - Device Profile: `default`
   - Click **Add**

3. **Obtener Access Token**
   - Click en el dispositivo recién creado
   - Pestaña **"Credentials"**
   - Verás algo como:
   ```
   Credential Type: Access Token
   Access Token: A1_WEATHER_SENSOR_TOKEN
   ```
   - **Copia ese token**

### Método 2: Crear dispositivo y token mediante API

```bash
# 1. Login como Tenant Admin
TOKEN=$(curl -s -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "tenant@thingsboard.org",
    "password": "tenant"
  }' | jq -r '.token')

# 2. Crear dispositivo
DEVICE=$(curl -s -X POST http://localhost:8080/api/device \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "name": "Sensor Temperatura 01",
    "type": "default"
  }')

# Extraer Device ID
DEVICE_ID=$(echo $DEVICE | jq -r '.id.id')
echo "Device ID: $DEVICE_ID"

# 3. Obtener credenciales (Access Token)
CREDENTIALS=$(curl -s -X GET \
  "http://localhost:8080/api/device/$DEVICE_ID/credentials" \
  -H "Authorization: Bearer $TOKEN")

ACCESS_TOKEN=$(echo $CREDENTIALS | jq -r '.credentialsId')
echo "Access Token: $ACCESS_TOKEN"
```

### Método 3: Cambiar Access Token de un dispositivo

Si quieres personalizar el token:

```bash
# Cambiar token a uno personalizado
curl -X POST http://localhost:8080/api/device/credentials \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "deviceId": {
      "id": "'$DEVICE_ID'"
    },
    "credentialsType": "ACCESS_TOKEN",
    "credentialsId": "MI_TOKEN_PERSONALIZADO_123"
  }'
```

---

## Ejemplos prácticos

### Ejemplo 1: Setup completo desde cero (Local con Docker)

```bash
# Paso 1: Instalar ThingsBoard con datos demo
cd docker
./docker-install-tb.sh --loadDemo
./docker-start-services.sh

# Paso 2: Esperar que inicie (2-3 minutos)
# Verificar logs
docker-compose logs -f tb-core1

# Paso 3: Acceder a la interfaz
# Navegador: http://localhost

# Paso 4: Login con usuario por defecto
# Email: tenant@thingsboard.org
# Password: tenant

# Paso 5: Crear tu primer dispositivo
# Menú → Devices → + (Add Device)
# Name: Mi Sensor
# Type: default
# → Add

# Paso 6: Obtener Access Token
# Click en "Mi Sensor" → Pestaña "Credentials"
# Copia el Access Token
```

### Ejemplo 2: Enviar datos desde Python

```python
#!/usr/bin/env python3
# archivo: send_data.py

import requests
import json
import time
import random

# CONFIGURACIÓN
THINGSBOARD_HOST = "http://localhost:8080"
ACCESS_TOKEN = "TU_ACCESS_TOKEN_AQUI"  # ← Copia desde interfaz web

def send_telemetry(temperature, humidity):
    """Envía datos de telemetría a ThingsBoard"""
    url = f"{THINGSBOARD_HOST}/api/v1/{ACCESS_TOKEN}/telemetry"
    
    data = {
        "temperature": temperature,
        "humidity": humidity,
        "timestamp": int(time.time() * 1000)
    }
    
    headers = {"Content-Type": "application/json"}
    
    try:
        response = requests.post(url, json=data, headers=headers)
        
        if response.status_code == 200:
            print(f"✓ Datos enviados: Temp={temperature}°C, Hum={humidity}%")
        else:
            print(f"✗ Error: {response.status_code} - {response.text}")
    
    except Exception as e:
        print(f"✗ Excepción: {e}")

def main():
    print("Enviando datos a ThingsBoard...")
    print(f"Host: {THINGSBOARD_HOST}")
    print(f"Token: {ACCESS_TOKEN[:10]}...")
    print("-" * 50)
    
    while True:
        # Simular lectura de sensor
        temp = round(random.uniform(18.0, 30.0), 2)
        hum = random.randint(40, 80)
        
        send_telemetry(temp, hum)
        
        time.sleep(5)  # Enviar cada 5 segundos

if __name__ == "__main__":
    main()
```

**Ejecutar:**
```bash
# 1. Instalar dependencias
pip3 install requests

# 2. Editar send_data.py y poner tu Access Token
nano send_data.py

# 3. Ejecutar
python3 send_data.py
```

### Ejemplo 3: Enviar datos con MQTT

```bash
# Instalar cliente MQTT (macOS)
brew install mosquitto

# Publicar datos una vez
mosquitto_pub \
  -h localhost \
  -p 1883 \
  -t v1/devices/me/telemetry \
  -u "TU_ACCESS_TOKEN_AQUI" \
  -m '{"temperature": 25.5, "humidity": 65}'

# Script para publicar continuamente
cat > mqtt_sender.sh << 'EOF'
#!/bin/bash

ACCESS_TOKEN="TU_ACCESS_TOKEN_AQUI"
HOST="localhost"
PORT=1883

while true; do
  TEMP=$(echo "20 + $RANDOM % 15" | bc)
  HUM=$(echo "40 + $RANDOM % 40" | bc)
  TIMESTAMP=$(date +%s000)
  
  mosquitto_pub \
    -h $HOST \
    -p $PORT \
    -t v1/devices/me/telemetry \
    -u "$ACCESS_TOKEN" \
    -m "{\"temperature\": $TEMP, \"humidity\": $HUM, \"timestamp\": $TIMESTAMP}"
  
  echo "✓ Enviado: Temp=${TEMP}°C, Hum=${HUM}%"
  sleep 5
done
EOF

chmod +x mqtt_sender.sh
./mqtt_sender.sh
```

### Ejemplo 4: Verificar credenciales mediante API

```bash
#!/bin/bash
# Script: verify_credentials.sh

echo "=== Verificación de Credenciales ThingsBoard ==="

# Intentar login
echo -n "Email: "
read EMAIL

echo -n "Password: "
read -s PASSWORD
echo ""

echo "Intentando login..."

RESPONSE=$(curl -s -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"$EMAIL\",\"password\":\"$PASSWORD\"}")

TOKEN=$(echo $RESPONSE | jq -r '.token')

if [ "$TOKEN" != "null" ] && [ -n "$TOKEN" ]; then
  echo "✓ Login exitoso!"
  echo "Token JWT: ${TOKEN:0:50}..."
  
  # Obtener información del usuario
  USER_INFO=$(curl -s -X GET http://localhost:8080/api/auth/user \
    -H "Authorization: Bearer $TOKEN")
  
  echo ""
  echo "Información del usuario:"
  echo $USER_INFO | jq .
else
  echo "✗ Login fallido. Verifica tus credenciales."
  echo "Respuesta: $RESPONSE"
fi
```

---

## Resumen rápido

### ¿Necesitas cuenta para usar ThingsBoard local?

**NO** ❌

Al instalar con Docker:
- Se crean usuarios automáticamente
- Todo es local, sin internet
- No necesitas registrarte en ningún sitio

### Credenciales por defecto

```
System Admin:
  tenant@thingsboard.org / tenant
  sysadmin@thingsboard.org / sysadmin

Con --loadDemo también:
  tenant@thingsboard.org / tenant
  customer@thingsboard.org / customer
```

### Access Token vs Usuario/Password

| Concepto | Uso | Ejemplo |
|----------|-----|---------|
| **Usuario/Password** | Login interfaz web, API REST | `tenant@thingsboard.org` / `tenant` |
| **Access Token** | Dispositivos IoT envían datos | `A1_WEATHER_SENSOR_TOKEN` |
| **JWT Token** | APIs REST (temporal) | `eyJhbGciOiJIUzUxMiJ9...` |

### Comandos útiles

```bash
# Ver usuarios en base de datos
docker-compose exec postgres psql -U postgres -d thingsboard \
  -c "SELECT email, authority FROM tb_user;"

# Ver dispositivos y sus tokens
docker-compose exec postgres psql -U postgres -d thingsboard \
  -c "SELECT d.name, dc.credentials_id FROM device d 
      JOIN device_credentials dc ON d.id = dc.device_id 
      LIMIT 10;"

# Resetear password de un usuario (desde System Admin)
# → Interfaz Web → Tenants → Users → (usuario) → Cambiar password
```

---

## Troubleshooting de autenticación

### "Invalid username or password"

```bash
# Verificar que el servicio esté corriendo
docker-compose ps tb-core1

# Ver logs
docker-compose logs tb-core1 | grep -i "auth"

# Solución: Usar credenciales por defecto
# sysadmin@thingsboard.org / sysadmin
```

### "Connection refused" al enviar datos

```bash
# Verificar que el transport MQTT esté corriendo
docker-compose ps tb-mqtt-transport1

# Probar conectividad
nc -zv localhost 1883

# Ver logs del transport
docker-compose logs tb-mqtt-transport1
```

### "Unauthorized" al enviar telemetría

- **Causa**: Access Token incorrecto
- **Solución**: Verificar token en: Devices → (tu dispositivo) → Credentials

### Olvidé la contraseña del System Admin

```bash
# Opción 1: Reinstalar (perderás datos)
cd docker
./docker-remove-services.sh
./docker-install-tb.sh --loadDemo
./docker-start-services.sh

# Opción 2: Resetear en base de datos (avanzado)
docker-compose exec postgres psql -U postgres -d thingsboard
# ... requiere conocimientos de SQL
```

---

**Última actualización**: 30 de enero de 2026  
**Autor**: Equipo Innvoid

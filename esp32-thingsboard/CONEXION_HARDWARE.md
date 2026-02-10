# 🔌 Diagrama de Conexión ESP32

## Vista Física - ESP32 DevKit V1

```
                    ╔═══════════════════════════════════╗
                    ║      ESP32 DevKit V1              ║
                    ║   (Vista desde arriba)            ║
                    ╠═══════════════════════════════════╣
        Izquierda   ║                                   ║   Derecha
                    ║                                   ║
     3V3 ●──────────╣ 3V3                          GND ╠──────────● GND
                    ║                                   ║
                    ║                                   ║
                    ║ (Pines no usados...)              ║
                    ║                                   ║
 GPIO 4 ●──────────╣ GPIO 4                       IO23 ╠
 (DHT11)            ║                                   ║
                    ║                                   ║
                    ║     ┌─────────────┐               ║
                    ║     │   ESP32     │               ║
                    ║     │   Chip      │               ║
                    ║     └─────────────┘               ║
                    ║                                   ║
                    ║ (Pines no usados...)              ║
                    ║                                   ║
GPIO 34 ●──────────╣ GPIO 34                      IO22 ╠
 (W104)             ║ (SVP - Solo INPUT)                ║
                    ║                                   ║
                    ║                                   ║
     GND ●──────────╣ GND                           3V3 ╠──────────● 3V3
                    ║                                   ║
                    ║  GPIO 2 = LED interno (azul)      ║
                    ╚═══════════════════════════════════╝
                            │          │
                           USB      Micro USB
                         (programar)
```

---

## Conexión DHT11 (Temperatura y Humedad)

```
┌─────────────────────┐
│     Módulo DHT11    │
│   ┌─────────────┐   │
│   │   [][][]    │   │  Visto de frente
│   │    ╱ ╲      │   │  (rejilla del sensor)
│   │   ╱   ╲     │   │
│   └─────────────┘   │
│                     │
│  -   OUT    +       │  3 Pines
│  │    │     │       │
└──┼────┼─────┼───────┘
   │    │     │
   │    │     └──────────────> ESP32: 3V3 (Rojo)
   │    │
   │    └────────────────────> ESP32: GPIO 4 (Amarillo/Verde)
   │
   └─────────────────────────> ESP32: GND (Negro)

NOTA: Si el módulo tiene 4 pines, el cuarto (NC) no se conecta.
NOTA: Algunos módulos necesitan resistencia pull-up 4.7kΩ entre OUT y +
```

### Resistencia Pull-up (si es necesario)

```
          4.7kΩ - 10kΩ
     3V3 ──────/\/\/\────┬──── GPIO 4
                         │
                      DHT11 OUT
```

---

## Conexión W104 (Sensor de Sonido)

```
┌─────────────────────────┐
│  Módulo Sensor W104     │
│  Detector de Sonido     │
│                         │
│   ┌───┐   ┌─┐          │
│   │MIC│   │P│ ← Potenciómetro sensibilidad
│   └───┘   └─┘          │
│                         │
│  GND   OUT   VCC        │  3 Pines
│   │     │     │         │
└───┼─────┼─────┼─────────┘
    │     │     │
    │     │     └─────────────> ESP32: 3V3 (Rojo)
    │     │
    │     └───────────────────> ESP32: GPIO 34 (Amarillo)
    │                           (SVP = ADC1_CH6)
    └─────────────────────────> ESP32: GND (Negro)

IMPORTANTE: GPIO 34 es SOLO INPUT (no puede ser OUTPUT)
```

---

## LED Integrado

```
El ESP32 DevKit V1 tiene un LED azul interno conectado a GPIO 2.

NO REQUIERE CONEXIÓN FÍSICA.

Para identificarlo:
┌─────────────────┐
│   ESP32 Board   │
│                 │
│   ● ← LED azul  │  Cerca del chip ESP32
│     (GPIO 2)    │
└─────────────────┘

Se enciende cuando GPIO 2 = HIGH
Se apaga cuando GPIO 2 = LOW
```

---

## Diagrama Completo con Protoboard

```
                        ┌─────────────────────────────┐
                        │   ESP32 DevKit V1           │
                        │                             │
           3V3  ●───────┤ 3V3                     GND ├────────● GND
                        │                             │
       GPIO 4  ●───────┤ GPIO 4                      │
       (DHT11)          │                             │
                        │                             │
      GPIO 34  ●───────┤ GPIO 34 (SVP)               │
       (W104)           │                             │
                        │                             │
           GND  ●───────┤ GND                         │
                        │                             │
                        └─────────────────────────────┘
                               │
═══════════════════════════════╪═══════════════════════════════════════
                    Protoboard │
═══════════════════════════════╪═══════════════════════════════════════

    Rail + (Rojo)              │
    ─────────●─────────────────┤
             │                 │
             │                 │
             ├─────────────────> DHT11 VCC
             │
             └─────────────────> W104 VCC


    Rail - (Azul/Negro)        │
    ─────────●─────────────────┤
             │                 │
             │                 │
             ├─────────────────> DHT11 GND
             │
             └─────────────────> W104 GND


    DHT11 OUT ────────────────> ESP32 GPIO 4

    W104 OUT  ────────────────> ESP32 GPIO 34
```

---

## Prueba de Conexiones con Multímetro

### Verificar Alimentación

```
Multímetro en modo VDC (voltaje DC):

1. Punta roja → 3V3 del ESP32
2. Punta negra → GND del ESP32
3. Lectura esperada: ~3.3V

Si lee 0V: ESP32 no tiene alimentación USB
Si lee <3.0V: Alimentación insuficiente, probar otro cable/puerto USB
```

### Verificar Sensor DHT11

```
Multímetro en modo VDC:

1. Con ESP32 encendido
2. Punta roja → DHT11 VCC
3. Punta negra → DHT11 GND
4. Lectura esperada: ~3.3V

Si lee 0V: Verificar conexión de alimentación
```

### Verificar Sensor W104

```
Multímetro en modo VDC:

1. Con ESP32 encendido
2. Punta roja → W104 OUT
3. Punta negra → GND
4. Lectura esperada: 0.1V - 3.3V (varía con el sonido)

Prueba:
- Silencio: ~0.2-0.5V
- Hablar cerca: ~0.8-1.5V
- Palmada: ~2.0-3.0V

Si lee 0V constante: Sensor sin alimentación o dañado
Si lee 3.3V constante: Sensor saturado, ajustar potenciómetro
```

---

## Checklist de Verificación Física

```
[ ] ESP32 conectado a USB y LED de alimentación encendido
[ ] DHT11 conectado a 3V3, GPIO 4 y GND
[ ] W104 conectado a 3V3, GPIO 34 y GND
[ ] No hay cortos entre VCC y GND (verificar con multímetro)
[ ] Todos los cables bien insertados en protoboard
[ ] Protoboard a ESP32 con cables cortos (< 20cm)
[ ] Cable USB de datos (no solo carga)
```

---

## Problemas Comunes de Hardware

### LED de ESP32 no enciende

```
Causa: No hay alimentación
Solución:
- Verificar cable USB (debe ser de datos, no solo carga)
- Probar otro puerto USB
- Probar cable diferente
```

### DHT11 siempre da error

```
Causa: Señal de datos débil
Solución:
- Agregar resistencia pull-up 4.7kΩ entre OUT y VCC
- Cables cortos (< 20cm)
- Verificar que Data está en GPIO 4 exacto
```

### W104 siempre lee 0 o 4095

```
Causa: Pin incorrecto o sensor saturado
Solución:
- Confirmar que está en GPIO 34 (no otro GPIO)
- Ajustar potenciómetro del módulo W104
- Verificar alimentación 3.3V (no 5V)
```

### ESP32 se reinicia constantemente

```
Causa: Consumo excesivo de corriente
Solución:
- Usar alimentación USB de PC (no hub sin alimentar)
- Verificar no hay cortos entre pines
- Desconectar sensores y probar solo ESP32
```

---

## Fotos de Referencia

### Identificar GPIO 4

```
Busca en la placa ESP32 el pin marcado:
"GPIO4" o "D4" o "IO4"

Típicamente está en el lado izquierdo,
cerca de la mitad de la placa.
```

### Identificar GPIO 34 (SVP)

```
Busca en la placa ESP32 el pin marcado:
"GPIO34" o "SVP" o "A6" o "IO34"

Típicamente está en el lado izquierdo,
cerca de la parte inferior.

IMPORTANTE: Viene marcado como "SVP" en muchas placas.
```

### Identificar GPIO 2 (LED)

```
El LED interno NO requiere conexión.
Está soldado en la placa cerca del chip ESP32.

Es de color azul y enciende cuando el código
envía digitalWrite(LED_PIN, HIGH).
```

---

## ¿Necesitas Ayuda?

Si después de verificar todo sigue sin funcionar:

1. Toma fotos de tus conexiones
2. Copia el output del monitor serial
3. Anota qué LEDs encienden en el ESP32
4. Comparte esta información para diagnosticar

---

**¡Ahora conecta tu hardware! 🔌**

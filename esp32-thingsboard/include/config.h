/**
 * Configuración ESP32 → ThingsBoard
 * Device: ESP32_IoT_Sensors
 * Red: HOP85
 */

#ifndef CONFIG_H
#define CONFIG_H

// ============================================================================
// CONFIGURACIÓN WIFI
// ============================================================================
#define WIFI_SSID     "HOP85"
#define WIFI_PASSWORD "1234567890"

// ============================================================================
// CONFIGURACIÓN THINGSBOARD
// ============================================================================
#define TB_SERVER     "192.168.4.177"          // IP de tu Raspberry Pi
#define TB_PORT       1883                      // Puerto MQTT
#define ACCESS_TOKEN  "iY4xA8dhAmxTrc8yF0mF"  // Token del dispositivo

// ============================================================================
// CONFIGURACIÓN DE PINES GPIO
// ============================================================================
#define DHT_PIN       4    // GPIO 4 - Sensor DHT11 (temperatura/humedad)
#define SOUND_PIN     34   // GPIO 34 - Sensor W104 (sonido analógico)
#define LED_PIN       2    // GPIO 2 - LED integrado del ESP32

// ============================================================================
// CONFIGURACIÓN DEL SENSOR DHT
// ============================================================================
#define DHT_TYPE      DHT11  // Tipo de sensor (DHT11 o DHT22)

// ============================================================================
// INTERVALOS DE TIEMPO
// ============================================================================
#define TELEMETRY_INTERVAL  5000   // Enviar telemetría cada 5 segundos
#define WIFI_RETRY_INTERVAL 10000  // Reintentar WiFi cada 10 segundos
#define MQTT_RETRY_INTERVAL 5000   // Reintentar MQTT cada 5 segundos

// ============================================================================
// CALIBRACIÓN SENSOR DE SONIDO W104
// ============================================================================
#define SOUND_MIN_VALUE     0      // Valor mínimo ADC
#define SOUND_MAX_VALUE     4095   // Valor máximo ADC (12 bits)
#define SOUND_SILENCE       200    // Umbral de silencio
#define SOUND_NORMAL        500    // Umbral conversación
#define SOUND_HIGH          1500   // Umbral ruido alto

// ============================================================================
// CONFIGURACIÓN DE DEBUG
// ============================================================================
#define DEBUG_SERIAL        true   // Habilitar mensajes de debug en serial
#define DEBUG_SENSORS       true   // Debug de lecturas de sensores
#define DEBUG_MQTT          true   // Debug de mensajes MQTT

#endif // CONFIG_H

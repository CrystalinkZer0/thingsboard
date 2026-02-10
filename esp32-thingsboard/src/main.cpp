/**
 * ESP32 → ThingsBoard MQTT
 * Device: ESP32_IoT_Sensors
 * 
 * Sensores:
 *  - DHT11 (Temperatura y Humedad) en GPIO 4
 *  - W104 (Sonido analógico) en GPIO 34
 *  - LED (Actuador) en GPIO 2
 * 
 * Envía telemetría:
 *  - temperature (°C)
 *  - humidity (%)
 *  - soundLevel (ADC 0-4095)
 *  - soundLevelPercent (0-100%)
 *  - ledState (true/false)
 *  - rssi (WiFi signal strength)
 */

#include <Arduino.h>
#include <WiFi.h>
#include <PubSubClient.h>
#include <DHT.h>
#include <ArduinoJson.h>
#include "config.h"

// ============================================================================
// OBJETOS GLOBALES
// ============================================================================
WiFiClient espClient;
PubSubClient mqttClient(espClient);
DHT dhtSensor(DHT_PIN, DHT_TYPE);

// ============================================================================
// VARIABLES GLOBALES
// ============================================================================
unsigned long lastTelemetry = 0;
unsigned long lastWifiCheck = 0;
unsigned long lastMqttCheck = 0;

int dhtErrorCount = 0;
bool ledState = false;

// Promedios de lecturas (para estabilizar sensor de sonido)
const int NUM_SOUND_SAMPLES = 10;
int soundReadings[NUM_SOUND_SAMPLES];
int soundReadIndex = 0;
long soundTotal = 0;

// ============================================================================
// DECLARACIÓN DE FUNCIONES
// ============================================================================
void setupWiFi();
void setupMQTT();
void reconnectWiFi();
void reconnectMQTT();
void readAndSendTelemetry();
void mqttCallback(char* topic, byte* payload, unsigned int length);
void processSharedAttributes(JsonDocument& doc);
int readSoundLevel();
String getSoundCategory(int level);

// ============================================================================
// SETUP
// ============================================================================
void setup() {
  // Inicializar serial
  Serial.begin(115200);
  delay(1000);
  
  Serial.println("\n\n");
  Serial.println("╔══════════════════════════════════════════════════════╗");
  Serial.println("║  ESP32 → ThingsBoard MQTT                            ║");
  Serial.println("║  Device: ESP32_IoT_Sensors                           ║");
  Serial.println("╚══════════════════════════════════════════════════════╝");
  Serial.println();

  // Configuración de pines
  pinMode(LED_PIN, OUTPUT);
  pinMode(SOUND_PIN, INPUT);
  digitalWrite(LED_PIN, LOW);
  
  // Inicializar sensor DHT
  Serial.println("[SETUP] Inicializando sensor DHT11...");
  dhtSensor.begin();
  delay(2000); // DHT11 necesita 2 segundos para estabilizarse
  
  // Inicializar array de sonido
  for (int i = 0; i < NUM_SOUND_SAMPLES; i++) {
    soundReadings[i] = 0;
  }
  
  // Conectar WiFi
  setupWiFi();
  
  // Configurar MQTT
  setupMQTT();
  
  Serial.println("[SETUP] ✓ Inicialización completa\n");
}

// ============================================================================
// LOOP PRINCIPAL
// ============================================================================
void loop() {
  unsigned long currentMillis = millis();
  
  // Verificar conexión WiFi
  if (WiFi.status() != WL_CONNECTED) {
    if (currentMillis - lastWifiCheck >= WIFI_RETRY_INTERVAL) {
      lastWifiCheck = currentMillis;
      reconnectWiFi();
    }
    return;
  }
  
  // Verificar conexión MQTT
  if (!mqttClient.connected()) {
    if (currentMillis - lastMqttCheck >= MQTT_RETRY_INTERVAL) {
      lastMqttCheck = currentMillis;
      reconnectMQTT();
    }
    return;
  }
  
  // Mantener conexión MQTT activa
  mqttClient.loop();
  
  // Enviar telemetría periódicamente
  if (currentMillis - lastTelemetry >= TELEMETRY_INTERVAL) {
    lastTelemetry = currentMillis;
    readAndSendTelemetry();
  }
}

// ============================================================================
// CONFIGURACIÓN WIFI
// ============================================================================
void setupWiFi() {
  Serial.println("[WiFi] Conectando a red: " + String(WIFI_SSID));
  
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 20) {
    delay(500);
    Serial.print(".");
    attempts++;
  }
  
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n[WiFi] ✓ Conectado");
    Serial.println("[WiFi] IP: " + WiFi.localIP().toString());
    Serial.println("[WiFi] RSSI: " + String(WiFi.RSSI()) + " dBm");
  } else {
    Serial.println("\n[WiFi] ✗ Error de conexión");
    Serial.println("[WiFi] Reintentando en " + String(WIFI_RETRY_INTERVAL/1000) + " segundos...");
  }
}

void reconnectWiFi() {
  Serial.println("[WiFi] Reconectando...");
  WiFi.disconnect();
  delay(100);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 10) {
    delay(500);
    Serial.print(".");
    attempts++;
  }
  
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n[WiFi] ✓ Reconectado");
    Serial.println("[WiFi] IP: " + WiFi.localIP().toString());
  } else {
    Serial.println("\n[WiFi] ✗ Fallo al reconectar");
  }
}

// ============================================================================
// CONFIGURACIÓN MQTT
// ============================================================================
void setupMQTT() {
  mqttClient.setServer(TB_SERVER, TB_PORT);
  mqttClient.setCallback(mqttCallback);
  mqttClient.setKeepAlive(60);
  
  Serial.println("[MQTT] Servidor: " + String(TB_SERVER) + ":" + String(TB_PORT));
  
  reconnectMQTT();
}

void reconnectMQTT() {
  if (WiFi.status() != WL_CONNECTED) {
    return;
  }
  
  Serial.print("[MQTT] Conectando a ThingsBoard... ");
  
  // Conectar con Access Token como username
  if (mqttClient.connect("ESP32_IoT_Sensors", ACCESS_TOKEN, NULL)) {
    Serial.println("✓ Conectado");
    
    // Suscribirse a shared attributes (para control remoto)
    mqttClient.subscribe("v1/devices/me/attributes");
    Serial.println("[MQTT] ✓ Suscrito a attributes");
    
    // Enviar atributos del dispositivo al conectar
    StaticJsonDocument<256> deviceAttributes;
    deviceAttributes["deviceType"] = "ESP32 DevKit V1";
    deviceAttributes["firmware"] = "1.0.0";
    deviceAttributes["sensors"] = "DHT11, W104, LED";
    
    char buffer[256];
    serializeJson(deviceAttributes, buffer);
    mqttClient.publish("v1/devices/me/attributes", buffer);
    
    Serial.println("[MQTT] ✓ Atributos del dispositivo enviados");
    
    // Parpadear LED para indicar conexión exitosa
    for (int i = 0; i < 3; i++) {
      digitalWrite(LED_PIN, HIGH);
      delay(200);
      digitalWrite(LED_PIN, LOW);
      delay(200);
    }
    
  } else {
    Serial.print("✗ Error, estado: ");
    Serial.println(mqttClient.state());
    Serial.println("[MQTT] Códigos de error:");
    Serial.println("  -4: Connection timeout");
    Serial.println("  -3: Connection lost");
    Serial.println("  -2: Connect failed");
    Serial.println("  -1: Disconnected");
    Serial.println("   0: Connected");
  }
}

// ============================================================================
// CALLBACK MQTT (Recibir comandos desde ThingsBoard)
// ============================================================================
void mqttCallback(char* topic, byte* payload, unsigned int length) {
  Serial.print("[MQTT] Mensaje recibido en topic: ");
  Serial.println(topic);
  
  // Convertir payload a string
  char message[length + 1];
  memcpy(message, payload, length);
  message[length] = '\0';
  
  if (DEBUG_MQTT) {
    Serial.print("[MQTT] Payload: ");
    Serial.println(message);
  }
  
  // Parsear JSON
  StaticJsonDocument<256> doc;
  DeserializationError error = deserializeJson(doc, message);
  
  if (error) {
    Serial.print("[MQTT] ✗ Error parseando JSON: ");
    Serial.println(error.c_str());
    return;
  }
  
  // Procesar atributos compartidos (shared attributes)
  if (String(topic) == "v1/devices/me/attributes") {
    processSharedAttributes(doc);
  }
}

// ============================================================================
// PROCESAR COMANDOS REMOTOS
// ============================================================================
void processSharedAttributes(JsonDocument& doc) {
  // Control del LED
  if (doc.containsKey("ledControl")) {
    String command = doc["ledControl"].as<String>();
    
    if (command == "on") {
      digitalWrite(LED_PIN, HIGH);
      ledState = true;
      Serial.println("[LED] ✓ Encendido remotamente");
    } 
    else if (command == "off") {
      digitalWrite(LED_PIN, LOW);
      ledState = false;
      Serial.println("[LED] ✓ Apagado remotamente");
    }
    else if (command == "blink") {
      for (int i = 0; i < 5; i++) {
        digitalWrite(LED_PIN, HIGH);
        delay(200);
        digitalWrite(LED_PIN, LOW);
        delay(200);
      }
      Serial.println("[LED] ✓ Parpadeo ejecutado");
    }
  }
  
  // Cambiar intervalo de telemetría (no implementado por simplicidad)
  if (doc.containsKey("sensorInterval")) {
    int newInterval = doc["sensorInterval"];
    Serial.print("[CONFIG] Nuevo intervalo solicitado: ");
    Serial.print(newInterval);
    Serial.println(" ms (requiere reinicio para aplicar)");
  }
}

// ============================================================================
// LEER Y ENVIAR TELEMETRÍA
// ============================================================================
void readAndSendTelemetry() {
  Serial.println("\n[TELEMETRY] Leyendo sensores...");
  
  // Leer DHT11 (temperatura y humedad)
  float temperature = dhtSensor.readTemperature();
  float humidity = dhtSensor.readHumidity();
  
  // Verificar lecturas válidas del DHT
  bool dhtValid = !isnan(temperature) && !isnan(humidity);
  
  if (!dhtValid) {
    dhtErrorCount++;
    Serial.println("[DHT11] ✗ Error de lectura (sensor desconectado?)");
    temperature = 0.0;
    humidity = 0.0;
  } else {
    dhtErrorCount = 0;
    if (DEBUG_SENSORS) {
      Serial.print("[DHT11] Temperatura: ");
      Serial.print(temperature);
      Serial.print(" °C | Humedad: ");
      Serial.print(humidity);
      Serial.println(" %");
    }
  }
  
  // Leer sensor de sonido (promedio de múltiples lecturas)
  int soundLevel = readSoundLevel();
  float soundPercent = (soundLevel / (float)SOUND_MAX_VALUE) * 100.0;
  String soundCategory = getSoundCategory(soundLevel);
  
  if (DEBUG_SENSORS) {
    Serial.print("[W104] Nivel sonido: ");
    Serial.print(soundLevel);
    Serial.print(" ADC (");
    Serial.print(soundPercent, 1);
    Serial.print("%) - Categoría: ");
    Serial.println(soundCategory);
  }
  
  // Leer señal WiFi
  int rssi = WiFi.RSSI();
  
  if (DEBUG_SENSORS) {
    Serial.print("[WiFi] RSSI: ");
    Serial.print(rssi);
    Serial.println(" dBm");
  }
  
  // Crear JSON con telemetría
  StaticJsonDocument<512> telemetry;
  telemetry["temperature"] = dhtValid ? temperature : JsonVariant();
  telemetry["humidity"] = dhtValid ? humidity : JsonVariant();
  telemetry["soundLevel"] = soundLevel;
  telemetry["soundLevelPercent"] = soundPercent;
  telemetry["soundCategory"] = soundCategory;
  telemetry["ledState"] = ledState;
  telemetry["rssi"] = rssi;
  telemetry["errorCount"] = dhtErrorCount;
  telemetry["uptime"] = millis() / 1000; // Segundos de uptime
  
  // Serializar a string
  char buffer[512];
  size_t n = serializeJson(telemetry, buffer);
  
  // Enviar a ThingsBoard
  if (mqttClient.publish("v1/devices/me/telemetry", buffer, n)) {
    Serial.println("[MQTT] ✓ Telemetría enviada (" + String(n) + " bytes)");
    
    if (DEBUG_MQTT) {
      Serial.print("[MQTT] JSON: ");
      Serial.println(buffer);
    }
    
    // Parpadeo rápido para indicar envío exitoso
    digitalWrite(LED_PIN, HIGH);
    delay(50);
    digitalWrite(LED_PIN, ledState ? HIGH : LOW);
    
  } else {
    Serial.println("[MQTT] ✗ Error enviando telemetría");
    Serial.println("[MQTT] Estado MQTT: " + String(mqttClient.state()));
  }
}

// ============================================================================
// LEER NIVEL DE SONIDO (CON PROMEDIO MÓVIL)
// ============================================================================
int readSoundLevel() {
  // Restar la lectura anterior del total
  soundTotal = soundTotal - soundReadings[soundReadIndex];
  
  // Leer nuevo valor
  soundReadings[soundReadIndex] = analogRead(SOUND_PIN);
  
  // Agregar al total
  soundTotal = soundTotal + soundReadings[soundReadIndex];
  
  // Avanzar índice
  soundReadIndex = (soundReadIndex + 1) % NUM_SOUND_SAMPLES;
  
  // Calcular promedio
  return soundTotal / NUM_SOUND_SAMPLES;
}

// ============================================================================
// CATEGORIZAR NIVEL DE SONIDO
// ============================================================================
String getSoundCategory(int level) {
  if (level < SOUND_SILENCE) {
    return "Silencio";
  } else if (level < SOUND_NORMAL) {
    return "Bajo";
  } else if (level < SOUND_HIGH) {
    return "Normal";
  } else {
    return "Alto";
  }
}

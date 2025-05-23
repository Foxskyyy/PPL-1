#define BLYNK_TEMPLATE_ID "TMPL6maYaPgcz"
#define BLYNK_TEMPLATE_NAME "Water Sensor"
#define BLYNK_AUTH_TOKEN "tV9m1PYrBYdUqUKvCOmGvkGRhgcTxQR4"

#include <ESP8266WiFi.h>
#include <WiFiClientSecure.h>
#include <ESP8266HTTPClient.h>
#include <BlynkSimpleEsp8266.h>
#include <time.h>

char auth[] = BLYNK_AUTH_TOKEN;
char ssid[] = "DHIN1";
char pass[] = "16161725";

const char* ntpServer = "pool.ntp.org";
const long gmtOffset_sec = 7 * 3600;
const int daylightOffset_sec = 0;

#define SENSOR D5
#define DEVICE_NAME "ET-bd7df152-d9c4-465c-ae54-714c8e7159a0"

BlynkTimer timer;

// Remove trailing slash from endpoint
const char* serverName = "https://api-ecotrack.interphaselabs.com/api/v1/water-usage/";

volatile byte pulseCount = 0;

long previousMillis = 0;
const int interval = 1000;

float calibrationFactor = 8.0;
float flowRate = 0.0;
float totalLitres = 0.0;
float totalMeterKubik = 0.0;
unsigned int cost = 0;

// Store previous values to avoid unnecessary API calls
float prevFlowRate = 0.0;
float prevTotalLitres = 0.0;
unsigned int prevCost = 0;

void ICACHE_RAM_ATTR pulseCounter() {
  pulseCount++;
}

void setup() {
  Serial.begin(9600);
  Serial.print("Connecting to WiFi network: ");
  Serial.println(ssid);

  WiFi.begin(ssid, pass);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nSuccessfully connected");
  Serial.print("IP address: ");
  Serial.println(WiFi.localIP());

  configTime(gmtOffset_sec, daylightOffset_sec, ntpServer);

  pinMode(SENSOR, INPUT_PULLUP);
  attachInterrupt(digitalPinToInterrupt(SENSOR), pulseCounter, FALLING);

  Blynk.begin(auth, ssid, pass);
  timer.setInterval(interval, sendData);

  previousMillis = millis();
}

void loop() {
  Blynk.run();
  timer.run();
}

unsigned int roundToNearestHundred(unsigned int value) {
  return ((value + 50) / 100) * 100;
}

void sendData() {
  unsigned long currentMillis = millis();

  if (currentMillis - previousMillis >= interval) {
    // Calculate flow rate
    byte pulse1Sec = pulseCount;
    pulseCount = 0;

    unsigned long intervalMillis = currentMillis - previousMillis;
    previousMillis = currentMillis;

    if (intervalMillis == 0) return; // avoid division by zero

    flowRate = ((1000.0 / intervalMillis) * pulse1Sec) / calibrationFactor;
    float flowLitres = flowRate / 60.0;  // L/s to L/min
    float flowMeterKubik = flowLitres / 1000.0;

    totalLitres += flowLitres;
    totalMeterKubik += flowMeterKubik;
    cost = totalLitres * 1000;

    unsigned int roundedCost = roundToNearestHundred(cost);

    // Only send if values changed to avoid unnecessary POSTs
    if (flowRate != prevFlowRate || totalLitres != prevTotalLitres || roundedCost != prevCost) {
      Serial.print("Flow rate: ");
      Serial.print(flowRate);
      Serial.print(" L/min\t");
      Serial.print("Total: ");
      Serial.print(totalMeterKubik, 3);
      Serial.print(" M3 / ");
      Serial.print(totalLitres);
      Serial.print(" L\t");
      Serial.print("Cost: ");
      Serial.println(roundedCost);

      // Send to Blynk app
      Blynk.virtualWrite(V0, flowRate);
      Blynk.virtualWrite(V1, totalLitres);
      Blynk.virtualWrite(V2, roundedCost);

      // Send to API if connected and flowRate > 0
      if (WiFi.status() == WL_CONNECTED && flowRate > 0.0) {
        WiFiClientSecure wifiClient;
        wifiClient.setInsecure(); // Use this if you do NOT need to check server certificate

        HTTPClient http;
        Serial.print("HTTP POST to: "); Serial.println(serverName);

        if (http.begin(wifiClient, serverName)) {
          http.addHeader("Content-Type", "application/json");

          // Get UTC time for timestamp
          time_t now = time(nullptr);
          struct tm* timeinfo = gmtime(&now);
          char timestamp[25];
          strftime(timestamp, sizeof(timestamp), "%Y-%m-%dT%H:%M:%SZ", timeinfo);

          String postData = "{";
          postData += "\"device_id\":\"" + String(DEVICE_NAME) + "\",";
          postData += "\"flow_rate\":" + String(flowRate, 2) + ",";
          postData += "\"total_usage\":" + String(totalLitres, 2) + ",";
          postData += "\"recorded_at\":\"" + String(timestamp) + "\"";
          postData += "}";

          Serial.print("Payload: ");
          Serial.println(postData);

          int httpResponseCode = http.POST(postData);

          Serial.print("HTTP Response code: ");
          Serial.println(httpResponseCode);
          Serial.print("HTTP Response body: ");
          Serial.println(http.getString());

          if (httpResponseCode > 0) {
            Serial.println("Data sent successfully!");
          } else {
            Serial.println("Failed to send data.");
          }

          http.end();
        } else {
          Serial.println("Unable to connect to server");
        }
      } else {
        Serial.println("WiFi disconnected or flowRate zero; skipping API send");
      }

      prevFlowRate = flowRate;
      prevTotalLitres = totalLitres;
      prevCost = roundedCost;
    }
  }
}
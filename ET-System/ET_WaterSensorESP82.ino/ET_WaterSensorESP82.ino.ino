#define BLYNK_TEMPLATE_ID "TMPL6maYaPgcz"
#define BLYNK_TEMPLATE_NAME "Water Sensor"
#define BLYNK_AUTH_TOKEN "tV9m1PYrBYdUqUKvCOmGvkGRhgcTxQR4"

#include <ESP8266WiFi.h>
#include <ESP8266HTTPClient.h>
#include <BlynkSimpleEsp8266.h>
#include <time.h>

char auth[] = BLYNK_AUTH_TOKEN;
char ssid[] = "DHIN1";
char pass[] = "16161725";

const char* ntpServer = "pool.ntp.org";
const long gmtOffset_sec = 7 * 3600;
const int daylightOffset_sec = 0;

// Use D5 (GPIO14) for YF-S401 signal
#define SENSOR D5
#define DEVICE_NAME "ET-bd7df152-d9c4-465c-ae54-714c8e7159a0"

BlynkTimer timer;

const char* serverName = "https://api-ecotrack.interphaselabs.com/api/v1/water-usage/";

long currentMillis = 0;
long previousMillis = 0;
int interval = 1000;
float calibrationFactor = 8;
volatile byte pulseCount;
byte pulse1Sec = 0;
float flowRate;
float flowMeterKubik;
float totalMeterKubik;
float flowLitres;
float totalLitres;
unsigned int cost;

// Store previous values to avoid unnecessary API calls
float prevFlowRate = 0;
float prevTotalLitres = 0;
unsigned int prevCost = 0;

void ICACHE_RAM_ATTR pulseCounter() {
  pulseCount++;
}

void setup() {
  Serial.begin(115200);
  Serial.print("Connecting to WiFi network: ");
  Serial.print(ssid);

  WiFi.begin(ssid, pass);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nSuccessfully connected to: ");
  Serial.print(ssid);
  Serial.print(" with IP address: ");
  Serial.println(WiFi.localIP());

  configTime(gmtOffset_sec, daylightOffset_sec, ntpServer);

  pinMode(SENSOR, INPUT_PULLUP);
  Blynk.begin(auth, ssid, pass);
  timer.setInterval(1000L, sendData);

  pulseCount = 0;
  flowRate = 0.0;
  flowMeterKubik = 0.000;
  totalMeterKubik = 0;
  previousMillis = 0;
  cost = 0;

  attachInterrupt(digitalPinToInterrupt(SENSOR), pulseCounter, FALLING);
}

void loop() {
  Blynk.run();
  timer.run();
}

unsigned int roundToNearestHundred(unsigned int value) {
  return ((value + 50) / 100) * 100;
}

void sendData() {
  currentMillis = millis();

  if (currentMillis - previousMillis > interval) {
    pulse1Sec = pulseCount;
    pulseCount = 0;
    flowRate = ((1000.0 / (millis() - previousMillis)) * pulse1Sec) / calibrationFactor;
    previousMillis = millis();
    flowLitres = (flowRate / 60.0);
    flowMeterKubik = flowLitres / 1000.0;
    totalMeterKubik += flowMeterKubik;
    totalLitres += flowLitres;
    cost = totalLitres * 1000;

    unsigned int roundedCost = roundToNearestHundred(cost);

    if ((flowRate != prevFlowRate || totalLitres != prevTotalLitres || roundedCost != prevCost)) {
      // Print Data to Serial Monitor
      Serial.print("Flow rate: ");
      Serial.print(flowRate);
      Serial.print(" L/min\t");
      Serial.print("Output: ");
      Serial.print(totalMeterKubik, 3);
      Serial.print(" M3 / ");
      Serial.print(totalLitres);
      Serial.print(" L\t");
      Serial.print("Cost: ");
      Serial.println(roundedCost);

      // Send Data to Blynk
      Blynk.virtualWrite(V0, String(flowRate));
      Blynk.virtualWrite(V1, String(totalLitres));
      Blynk.virtualWrite(V2, String(roundedCost));

      // Send Data to API
      if (WiFi.status() == WL_CONNECTED && flowRate > 0.00) {
        WiFiClient wifiClient;
        HTTPClient http;
        http.begin(wifiClient, serverName);
        http.addHeader("Content-Type", "application/json");

        time_t now = time(nullptr);
        struct tm *timeinfo;
        char timestamp[25];
        timeinfo = localtime(&now);
        strftime(timestamp, sizeof(timestamp), "%Y-%m-%dT%H:%M:%SZ", timeinfo);

        // Properly formatted JSON
        String postData = "{";
        postData += "\"device_id\": \"" + String(DEVICE_NAME) + "\",";
        postData += "\"flow_rate\": " + String(flowRate, 2) + ",";
        postData += "\"total_usage\": " + String(totalLitres, 2) + ",";
        postData += "\"recorded_at\": \"" + String(timestamp) + "\"";
        postData += "}";

        int httpResponseCode = http.POST(postData);

        if (httpResponseCode > 0) {
          Serial.print("Data sent! Response code: ");
          Serial.println(httpResponseCode);
          Serial.println("Sending JSON payload:");
          Serial.println(postData);
        } else {
          Serial.print("Error sending data. HTTP response code: ");
          Serial.println(httpResponseCode);
        }

        http.end();
      } else {
        Serial.println("WiFi disconnected or flowRate=0. Cannot send data.");
      }

      prevFlowRate = flowRate;
      prevTotalLitres = totalLitres;
      prevCost = roundedCost;
    }
  }
}
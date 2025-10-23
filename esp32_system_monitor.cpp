#include <TFT_eSPI.h>
#include <ArduinoJson.h>

// Display setup
TFT_eSPI tft = TFT_eSPI();
#define TFT_WIDTH 240
#define TFT_HEIGHT 320

// Serial communication
#define BAUD_RATE 115200

// Colors
#define BACKGROUND_COLOR TFT_BLACK
#define TEXT_COLOR TFT_WHITE
#define CPU_COLOR TFT_RED
#define MEMORY_COLOR TFT_BLUE
#define DISK_COLOR TFT_GREEN
#define TEMP_COLOR TFT_YELLOW
#define LOAD_COLOR TFT_CYAN
#define BORDER_COLOR TFT_DARKGREY

// Progress bar settings
#define BAR_WIDTH 170
#define BAR_HEIGHT 18
#define BAR_X 55
#define START_Y 45
#define SPACING 32

struct SystemData {
  float cpu;
  float memory_percent;
  float memory_used;
  float memory_total;
  float disk_percent;
  float disk_used;
  float disk_total;
  float load_1min;
  float load_5min;
  float load_15min;
  float cpu_temp;
  String timestamp;
};

SystemData currentData;
bool dataReceived = false;

void setup() {
  Serial.begin(BAUD_RATE);
  tft.init();
  tft.setRotation(1); // Landscape mode
  tft.fillScreen(BACKGROUND_COLOR);

  // Initial display
  showHeader();
  showWaitingMessage();

  Serial.println("ESP32 System Monitor Ready");
  Serial.println("Waiting for data from Mac...");
}

void loop() {
  if (Serial.available()) {
    String jsonString = Serial.readStringUntil('\n');

    if (jsonString.length() > 0) {
      parseJsonData(jsonString);
      updateDisplay();
      dataReceived = true;
    }
  }

  // Show connection status if no data received
  if (!dataReceived) {
    static unsigned long lastBlink = 0;
    if (millis() - lastBlink > 500) {
      showConnectionStatus();
      lastBlink = millis();
    }
  }
}

void parseJsonData(String jsonString) {
  StaticJsonDocument<512> doc;

  DeserializationError error = deserializeJson(doc, jsonString);

  if (error) {
    Serial.println("JSON parsing failed: " + String(error.c_str()));
    return;
  }

  currentData.cpu = doc["cpu"];
  currentData.memory_percent = doc["memory_percent"];
  currentData.memory_used = doc["memory_used"];
  currentData.memory_total = doc["memory_total"];
  currentData.disk_percent = doc["disk_percent"];
  currentData.disk_used = doc["disk_used"];
  currentData.disk_total = doc["disk_total"];
  currentData.load_1min = doc["load_1min"];
  currentData.load_5min = doc["load_5min"];
  currentData.load_15min = doc["load_15min"];
  currentData.cpu_temp = doc["cpu_temp"];
  currentData.timestamp = doc["timestamp"].as<String>();

  Serial.println("Data received and parsed successfully");
}

void showHeader() {
  tft.fillScreen(BACKGROUND_COLOR);

  // Title
  tft.setTextColor(TEXT_COLOR, BACKGROUND_COLOR);
  tft.setTextSize(2);
  tft.drawString("MacBook M1 Monitor", 20, 5);

  // Timestamp
  tft.setTextSize(1);
  tft.drawString("Last Update: --:--:--", 20, 25);
}

void showWaitingMessage() {
  tft.setTextColor(TEXT_COLOR, BACKGROUND_COLOR);
  tft.setTextSize(1);
  tft.drawString("Waiting for data...", 80, TFT_HEIGHT/2);
}

void showConnectionStatus() {
  static bool showDot = false;
  tft.setTextColor(TEXT_COLOR, BACKGROUND_COLOR);
  tft.setTextSize(1);

  if (showDot) {
    tft.drawString("Waiting for data...", 80, TFT_HEIGHT/2);
  } else {
    tft.drawString("Waiting for data   ", 80, TFT_HEIGHT/2);
  }

  showDot = !showDot;
}

void updateDisplay() {
  // Clear display area
  tft.fillRect(0, 35, TFT_WIDTH, TFT_HEIGHT-35, BACKGROUND_COLOR);

  int yPos = START_Y;

  // CPU Usage
  drawResourceBar("CPU", currentData.cpu, CPU_COLOR, yPos);
  yPos += SPACING;

  // Memory Usage
  drawResourceBar("RAM", currentData.memory_percent, MEMORY_COLOR, yPos);
  drawMemoryInfo(yPos - 15);
  yPos += SPACING;

  // Disk Usage
  drawResourceBar("Disk", currentData.disk_percent, DISK_COLOR, yPos);
  drawDiskInfo(yPos - 15);
  yPos += SPACING;

  // System Load
  drawLoadInfo(yPos);
  yPos += SPACING;

  // CPU Temperature
  if (currentData.cpu_temp > 0) {
    drawTemperatureInfo(yPos);
    yPos += SPACING;
  }

  // Timestamp
  tft.setTextColor(TEXT_COLOR, BACKGROUND_COLOR);
  tft.setTextSize(1);
  tft.drawString("Last Update: " + currentData.timestamp, 20, 25);
}

void drawResourceBar(String label, float percentage, uint16_t color, int yPos) {
  // Label
  tft.setTextColor(TEXT_COLOR, BACKGROUND_COLOR);
  tft.setTextSize(1);
  tft.drawString(label + ":", 10, yPos + 4);

  // Background bar with rounded corners effect
  tft.drawRect(BAR_X, yPos, BAR_WIDTH, BAR_HEIGHT, BORDER_COLOR);
  tft.drawRect(BAR_X + 1, yPos + 1, BAR_WIDTH - 2, BAR_HEIGHT - 2, BACKGROUND_COLOR);

  // Fill bar based on percentage
  int fillWidth = map(percentage, 0, 100, 0, BAR_WIDTH - 4);
  if (fillWidth > 0) {
    tft.fillRect(BAR_X + 2, yPos + 2, fillWidth, BAR_HEIGHT - 4, color);
  }

  // Percentage text
  tft.setTextColor(TEXT_COLOR, BACKGROUND_COLOR);
  tft.setTextSize(1);
  String percentStr = String((int)percentage) + "%";
  int textWidth = tft.textWidth(percentStr);
  tft.drawString(percentStr, BAR_X + BAR_WIDTH - textWidth - 8, yPos + 4);
}

void drawMemoryInfo(int yPos) {
  // Format: 8.0/16.0GB
  String memStr = String(currentData.memory_used, 1) + "/" +
                  String(currentData.memory_total, 1) + "GB";
  
  // Position next to the bar
  int textWidth = tft.textWidth(memStr);
  tft.setTextColor(MEMORY_COLOR, BACKGROUND_COLOR);
  tft.setTextSize(1);
  tft.drawString(memStr, BAR_X + BAR_WIDTH - textWidth - 8, yPos + 22);
}

void drawDiskInfo(int yPos) {
  // Format: 150/500GB
  String diskStr = String(currentData.disk_used, 1) + "/" +
                   String(currentData.disk_total, 1) + "GB";
  
  // Position next to the bar
  int textWidth = tft.textWidth(diskStr);
  tft.setTextColor(DISK_COLOR, BACKGROUND_COLOR);
  tft.setTextSize(1);
  tft.drawString(diskStr, BAR_X + BAR_WIDTH - textWidth - 8, yPos + 22);
}

void drawLoadInfo(int yPos) {
  tft.setTextColor(TEXT_COLOR, BACKGROUND_COLOR);
  tft.setTextSize(1);
  tft.drawString("Load Average:", 10, yPos + 2);

  // Format: 1m:1.23 5m:0.85 15m:0.67
  String loadStr = "1m:" + String(currentData.load_1min, 2) + 
                   " 5m:" + String(currentData.load_5min, 2) + 
                   " 15m:" + String(currentData.load_15min, 2);

  tft.setTextColor(LOAD_COLOR, BACKGROUND_COLOR);
  tft.drawString(loadStr, 10, yPos + 15);
}

void drawTemperatureInfo(int yPos) {
  tft.setTextColor(TEXT_COLOR, BACKGROUND_COLOR);
  tft.setTextSize(1);
  tft.drawString("CPU Temp:", 10, yPos + 2);

  // Format: 65.0°C
  String tempStr = String(currentData.cpu_temp, 1) + "°C";
  tft.setTextColor(TEMP_COLOR, BACKGROUND_COLOR);
  int textWidth = tft.textWidth(tempStr);
  tft.drawString(tempStr, BAR_X + BAR_WIDTH - textWidth - 8, yPos + 2);
}

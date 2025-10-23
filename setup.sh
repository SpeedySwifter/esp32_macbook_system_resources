#!/bin/bash
# Setup script for Mac System Monitor

echo "=== Mac System Monitor Setup ==="
echo ""

# Check if Python 3 is installed
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is not installed. Please install Python 3 first."
    exit 1
fi

echo "✅ Python 3 found"

# Install Python dependencies
echo ""
echo "Installing Python dependencies..."
pip3 install -r requirements.txt

if [ $? -eq 0 ]; then
    echo "✅ Dependencies installed successfully"
else
    echo "❌ Failed to install dependencies"
    exit 1
fi

# Check if ESP32 is connected
echo ""
echo "Checking for ESP32 connection..."
echo "Make sure your ESP32 is connected via USB and running the esp32_system_monitor.cpp program"
echo ""

# Show usage instructions
echo ""
echo "=== Display Features ==="
echo "✅ CPU-Auslastung mit rotem Fortschrittsbalken"
echo "✅ RAM-Verbrauch mit blauem Balken (8.0/16.0GB Format)"
echo "✅ Festplatten-Nutzung mit grünem Balken (150/500GB Format)"
echo "✅ Systemlast (1, 5, 15 Minuten Durchschnitt)"
echo "✅ CPU-Temperatur (falls verfügbar)"
echo "✅ Live-Uhrzeit der letzten Aktualisierung"
echo ""

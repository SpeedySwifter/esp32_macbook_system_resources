#!/bin/bash
# ESP32 System Monitor Installation Script
# Sets up the system monitor as a background service

set -e  # Exit on any error

echo "=== ESP32 TTGO T-Display V1.1 Board System Monitor Installation ==="
echo ""

# Check if we're in the right directory
if [ ! -f "mac_system_monitor.py" ]; then
    echo "❌ Error: mac_system_monitor.py not found in current directory"
    echo "Please run this script from the ESP32 system monitor project directory"
    exit 1
fi

echo "✅ Found project files"

# Create logs directory
echo "📁 Creating log directory..."
mkdir -p ~/Library/Logs/ESP32SystemMonitor

# Set executable permissions
echo "🔧 Setting executable permissions..."
chmod +x service_manager.sh
chmod +x run_background.sh
chmod +x stop_background.sh

# Check Python dependencies
echo "🐍 Checking Python dependencies..."
python3 -c "import psutil, serial, json" 2>/dev/null || {
    echo "⚠️  Warning: Required Python modules may not be installed"
    echo "   Installing dependencies..."
    pip3 install -r requirements.txt || {
        echo "❌ Error: Could not install Python dependencies"
        echo "   Please run: pip3 install psutil pyserial"
        exit 1
    }
}

echo "✅ Python dependencies OK"

# Test ESP32 connection (optional)
echo ""
echo "🔌 Checking for ESP32 TTGO T-Display V1.1 Board..."
if [ -f "run_background.sh" ]; then
    echo "   Run './run_background.sh status' to check connection"
fi

echo ""
echo "=== Installation Complete! ==="
echo ""
echo "🚀 To start the system monitor:"
echo ""
echo "Option 1 - Simple background service:"
echo "   ./run_background.sh start"
echo ""
echo "Option 2 - macOS system service (auto-start on login):"
echo "   ./service_manager.sh install"
echo "   ./service_manager.sh start"
echo ""
echo "📊 View logs:"
echo "   ./service_manager.sh logs"
echo ""
echo "📖 For more options, run:"
echo "   ./service_manager.sh help"
echo ""
echo "The system monitor will continuously send your Mac's system"
echo "resources (CPU, RAM, disk, load) to your ESP32 TTGO T-Display V1.1 Board!"
echo ""
echo "Have fun monitoring your system! 🎉"

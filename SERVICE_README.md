# ESP32 System Monitor - Service Management

This directory contains scripts for running the ESP32 TTGO T-Display V1.1 Board system monitor as a background service.

## Quick Start

### Option 1: Simple Background Service
```bash
# Start in background
./run_background.sh start

# Check if running
./run_background.sh status

# View logs
./run_background.sh logs

# Stop service
./stop_background.sh
```

### Option 2: macOS Launch Agent (Recommended)
```bash
# Install and start as system service
./service_manager.sh install
./service_manager.sh start

# Check status
./service_manager.sh status

# View logs
./service_manager.sh logs

# Stop service
./service_manager.sh stop
```

## Files Description

- **`service_manager.sh`** - Full-featured service manager for macOS Launch Agent
- **`run_background.sh`** - Simple background runner using nohup
- **`stop_background.sh`** - Stop script for background processes
- **`com.esp32.systemmonitor.plist`** - macOS Launch Agent configuration

## Features

- ✅ Automatic start on system login
- ✅ Error recovery and reconnection
- ✅ Comprehensive logging
- ✅ Easy start/stop/status management
- ✅ Multiple operation modes (interactive/daemon)

## Log Files

- Main logs: `~/Library/Logs/ESP32SystemMonitor/system_monitor.log`
- Daemon output: `~/Library/Logs/ESP32SystemMonitor/daemon.out`
- Daemon errors: `~/Library/Logs/ESP32SystemMonitor/daemon.err`

## Troubleshooting

If the service doesn't start:
1. Check ESP32 board connection
2. Verify serial port permissions
3. View logs with `./service_manager.sh logs`
4. Try running interactively first: `python3 mac_system_monitor.py`

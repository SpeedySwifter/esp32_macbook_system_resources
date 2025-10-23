# ESP32 Mac System Monitor

This program displays your MacBook M1 system resources on the TFT display of an ESP32. It monitors CPU, RAM, disk usage, and system load in real-time.

## Enhanced Display Features

### ✅ **Optimized Formatting**
- **RAM**: 8.0/16.0GB (used/total)
- **Disk**: 150/500GB (used/total)
- **CPU**: 75% with red progress bar
- **Load**: 1m:1.23 5m:0.85 15m:0.67
- **Temp**: 65.0°C (if available)

### ✅ **Visual Improvements**
- Borders around progress bars for better visibility
- Optimized text positioning for better readability
- Consistent spacing between display elements
- Live timestamp of last update

## Hardware Requirements

- ESP32 Development Board with TFT display
- USB connection between Mac and ESP32
- TFT_eSPI Library for Arduino IDE

## Software Setup

### 1. Set up Python environment

```bash
# Run the setup script
./setup.sh

# Or manually:
pip3 install -r requirements.txt
```

### 2. Upload ESP32 program

1. Open `esp32_system_monitor.cpp` in the Arduino IDE
2. Install the TFT_eSPI Library if not already present
3. Compile and upload the program to your ESP32

### 3. Start System Monitor

```bash
python3 mac_system_monitor.py
```

## How it Works

1. **Python script** on Mac reads system information
2. **Data transmission** via USB serial to ESP32
3. **TFT display** shows data in a clear format

## Display Layout

```
MacBook M1 Monitor     Last Update: 14:30:25
┌─────────────────────────────────────────┐
│ CPU:     [████████████░░░░] 75%         │
│ RAM:     [████████░░░░░░░░] 50%  8.0/16GB│
│ Disk:    [██████░░░░░░░░░░] 30% 150/500GB│
│ Load: 1m:1.2 5m:0.8 15m:0.6             │
│ Temp: 65°C                              │
└─────────────────────────────────────────┘
```

## Color Coding

- 🔴 **CPU**: Red - Shows high utilization
- 🔵 **RAM**: Blue - Memory consumption
- 🟢 **Disk**: Green - Disk usage
- 🟡 **Temp**: Yellow - CPU temperature
- 🔷 **Load**: Cyan - System load

## Configuration

### Customize Python Script

```python
# Change serial interface (Default: /dev/ttyUSB0)
serial_port = '/dev/ttyUSB0'  # On macOS: /dev/ttyUSB0, /dev/ttyACM0, etc.

# Change update interval (Default: 2 seconds)
time.sleep(2)  # In seconds

# Change baud rate (must match ESP32)
baud_rate = 115200
```

### Customize ESP32 Display

```cpp
// Change display rotation
tft.setRotation(1); // 0=Portrait, 1=Landscape, 2=Portrait 180°, 3=Landscape 180°

// Customize colors
#define CPU_COLOR TFT_RED
#define MEMORY_COLOR TFT_BLUE
#define DISK_COLOR TFT_GREEN
```

## Troubleshooting

### Problem: ESP32 not recognized

```bash
# Show available serial interfaces
ls /dev/tty*

# Run script with different interface
python3 mac_system_monitor.py
# Then manually specify the correct port
```

### Problem: No data on TFT display

- ✅ ESP32 program uploaded successfully?
- ✅ USB connection stable?
- ✅ Python script running without errors?
- ✅ Serial Monitor shows received data?

### Problem: Display only shows "Waiting for data"

- ✅ Python script started?
- ✅ Correct serial interface?
- ✅ ESP32 connected via USB?

### Problem: Missing Python dependencies

```bash
# Reinstall dependencies
pip3 install --upgrade psutil pyserial
```

## Technical Details

- **Data format**: JSON over serial connection
- **Update rate**: 2 seconds (configurable)
- **Baud rate**: 115200 (standard)
- **Display**: 240x320 TFT with ILI9341 controller
- **Python modules**: psutil, pyserial

## Advanced Features

### CPU Temperature (if supported)

The script automatically attempts to read CPU temperature information. If not available, this section will be hidden.

### System Load Optimization

Even under high system load, all values are displayed correctly. The Python script is designed to be resource-efficient.

## Performance

- **Mac CPU overhead**: < 1%
- **ESP32 RAM**: ~15KB
- **Network**: No network traffic
- **Update latency**: < 100ms

## Support

If you have problems:
1. Enable Serial Monitor (ESP32)
2. Check Python script outputs
3. Test USB connection
4. Use Arduino IDE debug mode

Have fun with your Mac System Monitor! 🎉

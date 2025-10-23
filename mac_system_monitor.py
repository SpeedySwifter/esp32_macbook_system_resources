#!/usr/bin/env python3
"""
Mac System Monitor for ESP32 TFT Display
Sends CPU, memory, and disk usage data to ESP32 via serial connection
"""

import psutil
import serial
import time
import json
from datetime import datetime

def get_system_info():
    """Get current system resource usage"""
    # CPU usage
    cpu_percent = psutil.cpu_percent(interval=1)

    # Memory usage
    memory = psutil.virtual_memory()
    memory_percent = memory.percent
    memory_used = memory.used / (1024**3)  # Convert to GB
    memory_total = memory.total / (1024**3)  # Convert to GB

    # Disk usage
    disk = psutil.disk_usage('/')
    disk_percent = disk.percent
    disk_used = disk.used / (1024**3)  # Convert to GB
    disk_total = disk.total / (1024**3)  # Convert to GB

    # System load (1, 5, 15 minute averages)
    load_avg = psutil.getloadavg()

    # Temperature (if available)
    try:
        temps = psutil.sensors_temperatures()
        cpu_temp = None
        if 'coretemp' in temps:
            cpu_temp = temps['coretemp'][0].current
    except:
        cpu_temp = None

    return {
        'cpu': cpu_percent,
        'memory_percent': memory_percent,
        'memory_used': round(memory_used, 1),
        'memory_total': round(memory_total, 1),
        'disk_percent': disk_percent,
        'disk_used': round(disk_used, 1),
        'disk_total': round(disk_total, 1),
        'load_1min': round(load_avg[0], 2),
        'load_5min': round(load_avg[1], 2),
        'load_15min': round(load_avg[2], 2),
        'cpu_temp': cpu_temp,
        'timestamp': datetime.now().strftime('%H:%M:%S')
    }

def send_to_esp32(data, serial_port='/dev/ttyUSB0', baud_rate=115200):
    """Send data to ESP32 via serial"""
    try:
        # Format data as JSON string
        json_data = json.dumps(data)

        # Open serial connection
        with serial.Serial(serial_port, baud_rate, timeout=1) as ser:
            # Send data with newline terminator
            ser.write((json_data + '\n').encode('utf-8'))
            print(f"Sent: {json_data}")

            # Small delay to ensure ESP32 can process
            time.sleep(0.1)

        return True
    except serial.SerialException as e:
        print(f"Serial error: {e}")
        return False
    except Exception as e:
        print(f"Error sending data: {e}")
        return False

def find_esp32_port():
    """Find the ESP32 serial port automatically"""
    import glob

    # Common ESP32 serial port patterns on macOS
    patterns = [
        '/dev/ttyUSB*',
        '/dev/ttyACM*',
        '/dev/tty.wchusbserial*',
        '/dev/tty.SLAB_USBtoUART*'
    ]

    for pattern in patterns:
        ports = glob.glob(pattern)
        if ports:
            return ports[0]

    return '/dev/ttyUSB0'  # Default fallback

def main():
    """Main monitoring loop"""
    print("Mac System Monitor for ESP32 TFT Display")
    print("=" * 40)

    # Find ESP32 serial port
    serial_port = find_esp32_port()
    print(f"Using serial port: {serial_port}")

    # Test serial connection
    try:
        with serial.Serial(serial_port, 115200, timeout=1) as ser:
            print("ESP32 connection test: OK")
    except:
        print("Warning: Could not connect to ESP32. Make sure it's plugged in and the correct port is selected.")
        print("Continuing anyway...")

    print("Starting system monitoring. Press Ctrl+C to stop.\n")

    try:
        while True:
            # Get system information
            system_info = get_system_info()

            # Send to ESP32
            success = send_to_esp32(system_info, serial_port)

            if success:
                print(f"✓ Data sent at {system_info['timestamp']}")
            else:
                print(f"✗ Failed to send data at {system_info['timestamp']}")

            # Wait before next update (adjust as needed)
            time.sleep(2)

    except KeyboardInterrupt:
        print("\nMonitoring stopped by user.")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    main()

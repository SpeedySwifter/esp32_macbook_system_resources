#!/usr/bin/env python3
"""
Mac System Monitor for ESP32 TTGO T-Display V1.1 Board - Daemon Version
Sends CPU, memory, and disk usage data to ESP32 TTGO T-Display V1.1 Board via serial connection
Background service version with logging support
"""

import psutil
import serial
import time
import json
import logging
import os
import sys
from datetime import datetime

# Setup logging
def setup_logging(daemon_mode=True):
    """Setup logging configuration"""
    if daemon_mode:
        # Create logs directory if it doesn't exist
        log_dir = os.path.expanduser("~/Library/Logs/ESP32SystemMonitor")
        os.makedirs(log_dir, exist_ok=True)
        log_file = os.path.join(log_dir, "system_monitor.log")

        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler(log_file),
                logging.StreamHandler()  # Still show on console for debugging
            ]
        )
    else:
        logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

    return logging.getLogger(__name__)

logger = setup_logging()

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
            logger.debug(f"Sent: {json_data}")

            # Small delay to ensure ESP32 can process
            time.sleep(0.1)

        return True
    except serial.SerialException as e:
        logger.error(f"Serial error: {e}")
        return False
    except Exception as e:
        logger.error(f"Error sending data: {e}")
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

def daemon_main():
    """Main daemon function for background operation"""
    logger.info("Starting ESP32 TTGO T-Display V1.1 Board System Monitor Daemon")
    logger.info("=" * 60)

    # Find ESP32 serial port
    serial_port = find_esp32_port()
    logger.info(f"Using serial port: {serial_port}")

    # Test serial connection
    try:
        with serial.Serial(serial_port, 115200, timeout=1) as ser:
            logger.info("ESP32 TTGO T-Display V1.1 Board connection test: OK")
    except Exception as e:
        logger.warning(f"Could not connect to ESP32 TTGO T-Display V1.1 Board: {e}")
        logger.info("Continuing in retry mode...")

    logger.info("System monitor daemon started successfully")

    consecutive_errors = 0
    max_consecutive_errors = 10

    try:
        while True:
            try:
                # Get system information
                system_info = get_system_info()

                # Send to ESP32
                success = send_to_esp32(system_info, serial_port)

                if success:
                    consecutive_errors = 0  # Reset error counter
                    logger.debug(f"Data sent successfully at {system_info['timestamp']}")
                else:
                    consecutive_errors += 1
                    logger.warning(f"Failed to send data at {system_info['timestamp']} (error #{consecutive_errors})")

                    # If too many consecutive errors, try to reconnect
                    if consecutive_errors >= max_consecutive_errors:
                        logger.error(f"Too many consecutive errors ({consecutive_errors}). Attempting to reconnect...")
                        try:
                            serial_port = find_esp32_port()
                            logger.info(f"Reconnected to new port: {serial_port}")
                            consecutive_errors = 0
                        except Exception as e:
                            logger.error(f"Reconnection failed: {e}")

            except Exception as e:
                consecutive_errors += 1
                logger.error(f"Unexpected error in monitoring loop: {e}")

                if consecutive_errors >= max_consecutive_errors:
                    logger.critical("Too many errors, restarting monitoring loop...")
                    consecutive_errors = 0
                    time.sleep(5)  # Wait before restarting

            # Wait before next update
            time.sleep(2)

    except KeyboardInterrupt:
        logger.info("Daemon stopped by user (SIGINT)")
    except Exception as e:
        logger.critical(f"Daemon crashed: {e}")
        raise

def main():
    """Main function with daemon/interactive mode selection"""
    if len(sys.argv) > 1 and sys.argv[1] == '--daemon':
        # Daemon mode - no console output, just logging
        setup_logging(daemon_mode=True)
        daemon_main()
    else:
        # Interactive mode - show console output
        setup_logging(daemon_mode=False)
        logger.info("Mac System Monitor for ESP32 TTGO T-Display V1.1 Board")
        logger.info("=" * 40)

        # Find ESP32 serial port
        serial_port = find_esp32_port()
        logger.info(f"Using serial port: {serial_port}")

        # Test serial connection
        try:
            with serial.Serial(serial_port, 115200, timeout=1) as ser:
                logger.info("ESP32 connection test: OK")
        except:
            logger.warning("Could not connect to ESP32 TTGO T-Display V1.1 Board. Make sure it's plugged in and the correct port is selected.")
            logger.info("Continuing anyway...")

        logger.info("Starting system monitoring. Press Ctrl+C to stop.\n")

        consecutive_errors = 0
        max_consecutive_errors = 5

        try:
            while True:
                # Get system information
                system_info = get_system_info()

                # Send to ESP32
                success = send_to_esp32(system_info, serial_port)

                if success:
                    consecutive_errors = 0
                    logger.info(f"✓ Data sent at {system_info['timestamp']}")
                else:
                    consecutive_errors += 1
                    logger.error(f"✗ Failed to send data at {system_info['timestamp']}")

                    if consecutive_errors >= max_consecutive_errors:
                        logger.error(f"Too many consecutive errors ({consecutive_errors}). Trying to reconnect...")
                        serial_port = find_esp32_port()
                        consecutive_errors = 0

                # Wait before next update
                time.sleep(2)

        except KeyboardInterrupt:
            logger.info("\nMonitoring stopped by user.")
        except Exception as e:
            logger.error(f"Error: {e}")

if __name__ == "__main__":
    main()

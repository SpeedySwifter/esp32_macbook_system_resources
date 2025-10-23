#!/bin/bash
# ESP32 System Monitor Background Stopper
# Simple script to stop the background system monitor

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PID_FILE="$SCRIPT_DIR/system_monitor.pid"

if [ ! -f "$PID_FILE" ]; then
    echo "No PID file found. System monitor may not be running."
    exit 1
fi

PID=$(cat "$PID_FILE")

if kill -0 "$PID" 2>/dev/null; then
    echo "Stopping ESP32 System Monitor (PID: $PID)..."
    kill "$PID"

    # Wait for graceful shutdown
    COUNT=0
    while kill -0 "$PID" 2>/dev/null && [ $COUNT -lt 10 ]; do
        sleep 1
        COUNT=$((COUNT + 1))
    done

    # Force kill if still running
    if kill -0 "$PID" 2>/dev/null; then
        echo "Force killing process..."
        kill -9 "$PID"
    fi

    echo "System monitor stopped successfully"
else
    echo "Process $PID is not running (stale PID file)"
fi

# Clean up PID file
rm -f "$PID_FILE"

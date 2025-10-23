#!/bin/bash
# ESP32 System Monitor Background Runner
# Simple script to run the system monitor in the background

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_SCRIPT="$SCRIPT_DIR/mac_system_monitor.py"
PID_FILE="$SCRIPT_DIR/system_monitor.pid"
LOG_FILE="$SCRIPT_DIR/system_monitor.log"

start_background() {
    echo "Starting ESP32 System Monitor in background..."

    # Check if already running
    if [ -f "$PID_FILE" ]; then
        if kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
            echo "System monitor is already running (PID: $(cat "$PID_FILE"))"
            exit 1
        else
            echo "Removing stale PID file..."
            rm "$PID_FILE"
        fi
    fi

    # Start in background with daemon mode
    nohup python3 "$PYTHON_SCRIPT" --daemon > "$LOG_FILE" 2>&1 &
    local pid=$!

    # Save PID
    echo $pid > "$PID_FILE"

    echo "System monitor started in background (PID: $pid)"
    echo "Log file: $LOG_FILE"
    echo "Use 'kill $pid' or './stop_background.sh' to stop"
}

stop_background() {
    echo "Stopping ESP32 System Monitor..."

    if [ ! -f "$PID_FILE" ]; then
        echo "No PID file found. System monitor may not be running."
        exit 1
    fi

    local pid=$(cat "$PID_FILE")

    if kill -0 "$pid" 2>/dev/null; then
        echo "Stopping process $pid..."
        kill "$pid"

        # Wait for process to stop
        local count=0
        while kill -0 "$pid" 2>/dev/null && [ $count -lt 10 ]; do
            sleep 1
            count=$((count + 1))
        done

        # Force kill if still running
        if kill -0 "$pid" 2>/dev/null; then
            echo "Force killing process $pid..."
            kill -9 "$pid"
        fi

        echo "System monitor stopped successfully"
    else
        echo "Process $pid is not running"
    fi

    rm -f "$PID_FILE"
}

show_status() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")

        if kill -0 "$pid" 2>/dev/null; then
            echo "System monitor is running (PID: $pid)"
            echo "Log file: $LOG_FILE"
        else
            echo "PID file exists but process is not running (stale PID file)"
            rm "$PID_FILE"
        fi
    else
        echo "System monitor is not running"
    fi
}

# Main script logic
case "$1" in
    start)
        start_background
        ;;
    stop)
        stop_background
        ;;
    status)
        show_status
        ;;
    logs)
        if [ -f "$LOG_FILE" ]; then
            echo "Recent log entries:"
            tail -20 "$LOG_FILE"
        else
            echo "No log file found"
        fi
        ;;
    help|--help|-h)
        echo "ESP32 System Monitor Background Runner"
        echo "Usage: $0 {start|stop|status|logs}"
        echo ""
        echo "Commands:"
        echo "  start   - Start in background (using nohup)"
        echo "  stop    - Stop background process"
        echo "  status  - Show if process is running"
        echo "  logs    - Show recent log entries"
        echo ""
        echo "Alternative to the Launch Agent service for simpler usage."
        ;;
    *)
        echo "Error: Unknown command '$1'"
        echo ""
        echo "Usage: $0 {start|stop|status|logs|help}"
        exit 1
        ;;
esac

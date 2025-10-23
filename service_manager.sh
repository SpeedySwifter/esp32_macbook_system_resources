#!/bin/bash
# ESP32 System Monitor Service Manager
# Start/Stop/Restart script for the ESP32 TTGO T-Display V1.1 Board system monitor

SERVICE_NAME="com.esp32.systemmonitor"
LAUNCH_AGENT="$HOME/Library/LaunchAgents/$SERVICE_NAME.plist"

show_help() {
    echo "ESP32 System Monitor Service Manager"
    echo "Usage: $0 {start|stop|restart|status|logs|install}"
    echo ""
    echo "Commands:"
    echo "  start    - Start the system monitor service"
    echo "  stop     - Stop the system monitor service"
    echo "  restart  - Restart the system monitor service"
    echo "  status   - Show service status"
    echo "  logs     - Show service logs"
    echo "  install  - Install launch agent (requires sudo for system-wide)"
    echo ""
    echo "The service monitors your Mac's system resources and sends them"
    echo "to the ESP32 TTGO T-Display V1.1 Board via serial connection."
}

start_service() {
    echo "Starting ESP32 System Monitor Service..."
    launchctl load "$LAUNCH_AGENT" 2>/dev/null || echo "Warning: Launch agent may already be loaded"
    launchctl start "$SERVICE_NAME"
    echo "Service started successfully"
}

stop_service() {
    echo "Stopping ESP32 System Monitor Service..."
    launchctl stop "$SERVICE_NAME" 2>/dev/null
    launchctl unload "$LAUNCH_AGENT" 2>/dev/null
    echo "Service stopped successfully"
}

restart_service() {
    echo "Restarting ESP32 System Monitor Service..."
    stop_service
    sleep 2
    start_service
}

show_status() {
    echo "ESP32 System Monitor Service Status:"
    echo "=================================="

    # Check if launch agent exists
    if [ -f "$LAUNCH_AGENT" ]; then
        echo "✓ Launch agent: $LAUNCH_AGENT"
    else
        echo "✗ Launch agent not found: $LAUNCH_AGENT"
        echo "Run '$0 install' to install the launch agent"
        return 1
    fi

    # Check if service is loaded
    if launchctl list | grep -q "$SERVICE_NAME"; then
        echo "✓ Service loaded: Yes"
    else
        echo "✗ Service loaded: No"
    fi

    # Check if service is running
    if launchctl list | grep -q "$SERVICE_NAME"; then
        echo "✓ Service running: Yes"
    else
        echo "✗ Service running: No"
    fi

    echo ""
    echo "Log files:"
    echo "  Main log: ~/Library/Logs/ESP32SystemMonitor/system_monitor.log"
    echo "  Daemon out: ~/Library/Logs/ESP32SystemMonitor/daemon.out"
    echo "  Daemon err: ~/Library/Logs/ESP32SystemMonitor/daemon.err"
}

show_logs() {
    echo "ESP32 System Monitor Service Logs:"
    echo "================================="

    LOG_FILE="$HOME/Library/Logs/ESP32SystemMonitor/system_monitor.log"

    if [ -f "$LOG_FILE" ]; then
        echo "Recent log entries (last 20 lines):"
        echo "----------------------------------"
        tail -20 "$LOG_FILE"
    else
        echo "No log file found. The service may not have been started yet."
    fi
}

install_agent() {
    echo "Installing ESP32 System Monitor Launch Agent..."
    echo "This will install the launch agent for the current user."

    # Check if launch agent exists
    if [ ! -f "$LAUNCH_AGENT" ]; then
        echo "Error: Launch agent not found at $LAUNCH_AGENT"
        echo "Please make sure the repository is in the correct location."
        exit 1
    fi

    # Set correct permissions
    chmod 644 "$LAUNCH_AGENT"

    # Load the agent
    launchctl load "$LAUNCH_AGENT"
    echo "Launch agent installed and loaded successfully"

    # Start the service
    start_service
}

# Main script logic
case "$1" in
    start)
        start_service
        ;;
    stop)
        stop_service
        ;;
    restart)
        restart_service
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs
        ;;
    install)
        install_agent
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "Error: Unknown command '$1'"
        echo ""
        show_help
        exit 1
        ;;
esac

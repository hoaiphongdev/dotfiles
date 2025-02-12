#!/bin/bash

# Function to print messages with a formatted header
function print_message() {
    echo "========================================"
    echo "$1"
    echo "========================================"
}

# Function to safely remove files/directories with error checking
function safe_remove() {
    if [ -e "$1" ]; then
        rm -rf "$1" > /dev/null 2>&1
        if [ $? -ne 0 ]; then
            echo "Warning: Failed to remove $1"
        fi
    fi
}

# Get the current user
USER=$(whoami)

# Ask for confirmation
print_message "WARNING: This script will delete various caches and logs"
echo "This may affect application behavior and cannot be undone."
read -p "Are you sure you want to continue? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo "Operation cancelled."
    exit 1
fi

# System Logs Cleanup
print_message "Cleaning system logs..."
if [ -d "/private/var/log/privoxy" ]; then
    sudo mv /private/var/log/privoxy /private/var/privoxy > /dev/null 2>&1
fi
sudo find /private/var/log -type f -exec rm {} \; > /dev/null 2>&1
if [ -d "/private/var/privoxy" ]; then
    sudo mv /private/var/privoxy /private/var/log/privoxy > /dev/null 2>&1
fi
echo "System logs cleanup completed."
echo ""

# User and System Caches Cleanup
print_message "Cleaning user and system caches..."
safe_remove "/Users/$USER/Library/Logs/*"
safe_remove "/Library/Logs/DiagnosticReports/*.*"
safe_remove "/private/var/tmp/com.apple.messages"
safe_remove "/Users/$USER/Library/Caches/*"
safe_remove "/private/var/db/diagnostics/*/*"
safe_remove "/Library/Logs/DiagnosticReports/ProxiedDevice-Bridge/*.ips"
safe_remove "/Users/$USER/Library/Application Support/CrashReporter/*"
safe_remove "/private/tmp/gzexe*"
echo "User and system caches cleanup completed."
echo ""

# Safari Caches Cleanup
print_message "Cleaning Safari caches..."
safe_remove "/Users/$USER/Library/Containers/com.apple.Safari/Data/Library/Caches/*"
safe_remove "/private/var/folders/ry/*/*/com.apple.Safari/com.apple.Safari/com.apple.metal/*/libraries.data"
safe_remove "/private/var/folders/ry/*/*/com.apple.Safari/com.apple.Safari/com.apple.metal/*/libraries.maps"
safe_remove "/Users/$USER/Library/Containers/io.te0.WebView/Data/Library/Caches/WebKit"
echo "Safari caches cleanup completed."
echo ""

# Chrome Caches Cleanup (Login-Safe Version)
print_message "Cleaning Chrome caches (preserving logins)..."
ChromePath="/Applications/Google Chrome.app"
if [[ -d $ChromePath ]]; then
    # Only clean non-essential caches
    safe_remove "/Users/$USER/Library/Application Support/Google/Chrome/*/GPUCache/*"
    safe_remove "/Users/$USER/Library/Application Support/Google/Chrome/*/Storage/ext/*/def/GPUCache/*"
    
    # Avoid cleaning these files to preserve logins
    # NOT deleting: Extension State, Session Storage, Current Session, Cookie files
    
    # Safe to clean
    safe_remove "/Users/$USER/Library/Application Support/Google/Chrome/*/*-journal"
    safe_remove "/Users/$USER/Library/Application Support/Google/Chrome/*/databases/*-journal"
    safe_remove "/Users/$USER/Library/Application Support/Google/Chrome/*/*.log"
    
    echo "Chrome caches cleanup completed (login information preserved)."
else
    echo "Chrome not installed, skipping Chrome cleanup."
fi
echo ""

# Download History Cleanup
print_message "Cleaning download history..."
sqlite3 ~/Library/Preferences/com.apple.LaunchServices.QuarantineEventsV* 'delete from LSQuarantineEvent' > /dev/null 2>&1
echo "Download history cleanup completed."
echo ""

# Terminal History Cleanup - Ask first
print_message "Do you want to clean terminal history? (y/n): "
read -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    safe_remove "/Users/$USER/.bash_sessions/*"
    safe_remove "/Users/$USER/.bash_history"
    safe_remove "/Users/$USER/.zsh_sessions/*"
    safe_remove "/Users/$USER/.zsh_history"
    echo "Terminal history cleanup completed."
fi
echo ""

print_message "Cleanup process completed"
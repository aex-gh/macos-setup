#!/usr/bin/env zsh

readonly SCRIPT_NAME="${0:t}"
readonly SCRIPT_DIR="${0:A:h}"

source "${SCRIPT_DIR}/../lib/common.zsh"

readonly DEVICE_TYPE="mac-studio"
readonly SERVER_BASE="/Users/Shared/Server"
readonly TIME_MACHINE_BASE="/Users/Shared/TimeMachine"
readonly FILE_SHARE_BASE="/Users/Shared/FileShare"

# Configure central file server functionality
configure_file_server() {
    header "Configuring central file server functionality"
    
    local server_dirs=(
        "$FILE_SHARE_BASE" "$FILE_SHARE_BASE/Public" "$FILE_SHARE_BASE/Family"
        "$FILE_SHARE_BASE/Documents" "$FILE_SHARE_BASE/Media" "$FILE_SHARE_BASE/Software"
        "$FILE_SHARE_BASE/Backups" "$SERVER_BASE" "$SERVER_BASE/Logs"
        "$SERVER_BASE/Config" "$SERVER_BASE/Scripts" "$SERVER_BASE/Monitoring"
    )
    
    create_directories "${server_dirs[@]}"
    enable_file_sharing_service
    configure_file_server_permissions
    create_file_server_guidelines
}

# Enable File Sharing service
enable_file_sharing_service() {
    info "Enabling File Sharing services"
    
    sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.smbd.plist 2>/dev/null && success "SMB enabled" || warn "Enable SMB manually"
    sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.AppleFileServer.plist 2>/dev/null && success "AFP enabled" || info "AFP not available"
    
    info "Configure shared folders in System Preferences > Sharing > File Sharing"
}

# Configure file server permissions
configure_file_server_permissions() {
    info "Configuring file server permissions"
    
    if [[ -d "$FILE_SHARE_BASE" ]]; then
        sudo chmod +a "group:staff allow read,write,execute,delete,add_file,add_subdirectory,file_inherit,directory_inherit" "$FILE_SHARE_BASE" 2>/dev/null || warn "Could not set ACL"
        sudo chmod g+s "$FILE_SHARE_BASE"
        success "File server permissions configured"
    fi
}

# Create simplified file server guidelines
create_file_server_guidelines() {
    local guidelines_file="$FILE_SHARE_BASE/README_File_Server.md"
    
    [[ -f "$guidelines_file" ]] && return 0
    
    sudo tee "$guidelines_file" > /dev/null << 'EOF'
# Mac Studio File Server

## Shared Folders
- Public: General file sharing
- Family: Long-term family storage
- Documents: Shared work documents
- Media: Centralised media storage
- Software: Family software archive

## Access
- macOS: Connect to Server (⌘K) → smb://10.20.0.10
- Windows: File Explorer → \\10.20.0.10
- iOS: Files → Connect to Server → smb://10.20.0.10

## Security
- Use family member credentials
- Report access issues to administrator
- Keep shared folders organised
EOF
    
    sudo chown root:staff "$guidelines_file"
    sudo chmod 664 "$guidelines_file"
    success "Created file server guidelines"
}

# Configure Time Machine backup server
configure_time_machine_server() {
    header "Configuring Time Machine backup server"
    
    local backup_dirs=(
        "$TIME_MACHINE_BASE" "$TIME_MACHINE_BASE/MacBook-Pro-Backup"
        "$TIME_MACHINE_BASE/Mac-Mini-Backup" "$TIME_MACHINE_BASE/Family-Archive"
    )
    
    create_directories "${backup_dirs[@]}"
    
    # Create backup destination info files
    local destinations=(
        "MacBook-Pro-Backup:Andrew's MacBook Pro"
        "Mac-Mini-Backup:Family Mac Mini"
        "Family-Archive:Shared Family Backup"
    )
    
    for dest_spec in "${destinations[@]}"; do
        local dest_dir="${dest_spec%%:*}"
        local dest_desc="${dest_spec##*:}"
        local dest_path="$TIME_MACHINE_BASE/$dest_dir"
        
        [[ -d "$dest_path" ]] || continue
        
        sudo tee "$dest_path/README.txt" > /dev/null << EOF
Time Machine Backup: $dest_desc
Created: $(date)
Path: $dest_path
Do not manually modify files in this directory.
EOF
        
        sudo chown root:admin "$dest_path/README.txt"
        success "Configured backup destination: $dest_desc"
    done
    
    info "Enable Time Machine sharing in System Preferences > Sharing > File Sharing"
}

# Configure headless operation optimisations
configure_headless_optimisations() {
    header "Configuring headless operation optimisations"
    
    # Server power management
    sudo pmset -a sleep 0 displaysleep 30 womp 1 autorestart 1 panicrestart 1 sms 0 2>/dev/null || warn "Power management partially configured"
    success "Server power management configured"
    
    # Headless preferences
    set_default com.apple.screensaver idleTime 0 int
    set_default com.apple.dock autohide true bool
    set_default com.apple.dock autohide-delay 0 float
    set_default com.apple.dock autohide-time-modifier 0 float
    
    sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload -bool false
    sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticallyInstallMacOSUpdates -bool false
    success "Headless preferences configured"
    
    # Login window configuration
    sudo defaults write /Library/Preferences/com.apple.loginwindow SHOWFULLNAME -bool true
    sudo defaults write /Library/Preferences/com.apple.loginwindow HideLocalUsers -bool false
    sudo defaults write /Library/Preferences/com.apple.loginwindow HideMobileAccounts -bool false
    sudo defaults write /Library/Preferences/com.apple.loginwindow GuestEnabled -bool false
    success "Login window configured"
    
    # Optional automatic login
    read -p "Enable automatic login for headless operation? [y/N]: " auto_login_choice
    if [[ "$auto_login_choice" =~ ^[Yy]$ ]]; then
        sudo defaults write /Library/Preferences/com.apple.loginwindow autoLoginUser "$(whoami)"
        success "Automatic login enabled"
        warn "Security notice: Automatic login reduces security - ensure FileVault is enabled"
    fi
    
    create_startup_script
}

# Create simplified startup script
create_startup_script() {
    local startup_script="$SERVER_BASE/Scripts/server_startup.zsh"
    
    sudo tee "$startup_script" > /dev/null << 'EOF'
#!/usr/bin/env zsh
echo "$(date): Mac Studio server startup" >> /var/log/server_startup.log
launchctl load -w /System/Library/LaunchDaemons/com.apple.smbd.plist 2>/dev/null || true
launchctl load -w /System/Library/LaunchDaemons/com.apple.screensharing.plist 2>/dev/null || true
[[ -d "/Applications/Jump Desktop Connect.app" ]] && open -a "Jump Desktop Connect" 2>/dev/null || true
df -h / >> /var/log/server_startup.log
EOF
    
    sudo chmod 755 "$startup_script"
    sudo chown root:staff "$startup_script"
    success "Server startup script created"
    info "Add to System Preferences > Users & Groups > Login Items"
}

# Create monitoring and maintenance scripts
create_monitoring_scripts() {
    header "Creating monitoring and maintenance scripts"
    
    create_system_monitor_script
    create_backup_monitor_script
    create_maintenance_script
    setup_automated_monitoring
}

# Create simplified system monitoring script
create_system_monitor_script() {
    local monitor_script="$SERVER_BASE/Scripts/system_monitor.zsh"
    
    sudo tee "$monitor_script" > /dev/null << 'EOF'
#!/usr/bin/env zsh
readonly LOG_FILE="/var/log/system_monitor.log"
log_msg() { echo "$(date '+%Y-%m-%d %H:%M:%S'): $*" >> "$LOG_FILE"; }

log_msg "Starting system monitoring"
disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
[[ $disk_usage -gt 90 ]] && log_msg "ALERT: Disk ${disk_usage}%" || log_msg "INFO: Disk ${disk_usage}%"

for service in com.apple.smbd com.apple.screensharing; do
    launchctl list | grep -q "$service" && log_msg "INFO: $service running" || log_msg "ALERT: $service not running"
done
log_msg "Monitoring completed"
EOF
    
    sudo chmod 755 "$monitor_script"
    sudo chown root:staff "$monitor_script"
    success "Created system monitoring script"
}

# Create simplified backup monitoring script
create_backup_monitor_script() {
    local backup_script="$SERVER_BASE/Scripts/backup_monitor.zsh"
    
    sudo tee "$backup_script" > /dev/null << 'EOF'
#!/usr/bin/env zsh
readonly LOG_FILE="/var/log/backup_monitor.log"
readonly TM_BASE="/Users/Shared/TimeMachine"
log_msg() { echo "$(date '+%Y-%m-%d %H:%M:%S'): $*" >> "$LOG_FILE"; }

log_msg "Starting backup monitoring"
[[ ! -d "$TM_BASE" ]] && { log_msg "ERROR: TimeMachine directory missing"; exit 1; }

destinations=0
for dest in "$TM_BASE"/*; do
    [[ -d "$dest" ]] && { log_msg "INFO: Backup $(basename "$dest") found"; ((destinations++)); }
done
log_msg "INFO: $destinations backup destinations found"

used_pct=$(df "$TM_BASE" | tail -1 | awk '{print $5}' | sed 's/%//')
[[ $used_pct -gt 85 ]] && log_msg "ALERT: Backup storage ${used_pct}%" || log_msg "INFO: Backup storage ${used_pct}%"
log_msg "Backup monitoring completed"
EOF
    
    sudo chmod 755 "$backup_script"
    sudo chown root:staff "$backup_script"
    success "Created backup monitoring script"
}

# Create simplified maintenance script
create_maintenance_script() {
    local maintenance_script="$SERVER_BASE/Scripts/server_maintenance.zsh"
    
    sudo tee "$maintenance_script" > /dev/null << 'EOF'
#!/usr/bin/env zsh
readonly LOG_FILE="/var/log/server_maintenance.log"
log_msg() { echo "$(date '+%Y-%m-%d %H:%M:%S'): $*" >> "$LOG_FILE"; }

log_msg "Starting server maintenance"

# Cleanup logs
find /var/log -name "*.log" -size +100M -exec gzip {} \; 2>/dev/null || true
find /var/log -name "*.log.gz" -mtime +30 -delete 2>/dev/null || true
log_msg "Log cleanup completed"

# Update Homebrew
if command -v brew &>/dev/null; then
    brew update --quiet && brew upgrade --quiet && brew cleanup --quiet 2>/dev/null || true
    log_msg "Homebrew updated"
fi

# Storage cleanup
sudo rm -rf /Users/*/.Trash/* /tmp/* /var/tmp/* 2>/dev/null || true
log_msg "Storage cleanup completed"

log_msg "Server maintenance completed"
EOF
    
    sudo chmod 755 "$maintenance_script"
    sudo chown root:staff "$maintenance_script"
    success "Created maintenance script"
}

# Set up automated monitoring
setup_automated_monitoring() {
    local monitoring_plist="$HOME/Library/LaunchAgents/com.family.mac-studio.monitoring.plist"
    
    cat > "$monitoring_plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.family.mac-studio.monitoring</string>
    <key>ProgramArguments</key>
    <array><string>$SERVER_BASE/Scripts/system_monitor.zsh</string></array>
    <key>StartInterval</key>
    <integer>3600</integer>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
EOF
    
    launchctl load "$monitoring_plist" 2>/dev/null || warn "Manual load required"
    success "Automated monitoring configured (hourly)"
}

# Help function
usage() {
    cat << EOF
$SCRIPT_NAME - Mac Studio Server Configuration

USAGE: $SCRIPT_NAME [OPTIONS]

Configure Mac Studio as a family server with file sharing, Time Machine backup,
headless optimisations, and automated monitoring.

OPTIONS:
    -h, --help    Show this help message

FEATURES:
    • File server (SMB/AFP) at /Users/Shared/FileShare/
    • Time Machine backup destinations at /Users/Shared/TimeMachine/
    • Headless operation optimisations and power management
    • Automated monitoring and maintenance scripts
    • Network configuration for 10.20.0.10

NOTES:
    Requires manual configuration in System Preferences > Sharing
EOF
}

# Main execution
main() {
    # Verify Mac Studio (with option to continue)
    if ! is_mac_studio; then
        local model_identifier
        model_identifier=$(get_mac_model)
        warn "Designed for Mac Studio (current: $model_identifier)"
        read -p "Continue anyway? [y/N]: " continue_choice
        [[ "$continue_choice" =~ ^[Yy]$ ]] || { info "Setup cancelled"; exit 0; }
    fi
    
    header "Mac Studio Server Configuration"
    
    configure_file_server
    configure_time_machine_server
    configure_headless_optimisations
    create_monitoring_scripts
    
    success "Mac Studio server configuration completed!"
    info "Next steps:"
    info "1. Configure sharing in System Preferences > Sharing"
    info "2. Set up Time Machine destinations for client devices"
    info "3. Test remote access from family devices"
}

# Parse arguments and run
case "${1:-}" in
    -h|--help) usage; exit 0 ;;
    "") main ;;
    *) error "Unknown option: $1"; usage; exit 1 ;;
esac
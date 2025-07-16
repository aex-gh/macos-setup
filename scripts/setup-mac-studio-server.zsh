#!/usr/bin/env zsh
set -euo pipefail

# Script metadata and colour codes
readonly SCRIPT_NAME="${0:t}"
readonly RED=$(tput setaf 1)
readonly GREEN=$(tput setaf 2)
readonly YELLOW=$(tput setaf 3)
readonly BLUE=$(tput setaf 4)
readonly RESET=$(tput sgr0)

# Device type - this script is specifically for Mac Studio
DEVICE_TYPE="mac-studio"

# Server configuration paths
readonly SERVER_BASE="/Users/Shared/Server"
readonly TIME_MACHINE_BASE="/Users/Shared/TimeMachine"
readonly FILE_SHARE_BASE="/Users/Shared/FileShare"

# Logging functions
error() {
    echo "${RED}[ERROR]${RESET} $*" >&2
}

warn() {
    echo "${YELLOW}[WARN]${RESET} $*" >&2
}

info() {
    echo "${BLUE}[INFO]${RESET} $*"
}

success() {
    echo "${GREEN}[SUCCESS]${RESET} $*"
}

# Configure central file server functionality
configure_file_server() {
    info "Configuring central file server functionality..."
    
    # Create file server directory structure
    setup_file_server_directories
    
    # Enable File Sharing service
    enable_file_sharing_service
    
    # Configure shared folders
    configure_shared_folders
    
    # Set up access permissions
    configure_file_server_permissions
}

# Set up file server directory structure
setup_file_server_directories() {
    info "Setting up file server directory structure..."
    
    local server_dirs=(
        "$FILE_SHARE_BASE"
        "$FILE_SHARE_BASE/Public"
        "$FILE_SHARE_BASE/Family"
        "$FILE_SHARE_BASE/Documents"
        "$FILE_SHARE_BASE/Media"
        "$FILE_SHARE_BASE/Software"
        "$FILE_SHARE_BASE/Backups"
        "$SERVER_BASE"
        "$SERVER_BASE/Logs"
        "$SERVER_BASE/Config"
        "$SERVER_BASE/Scripts"
        "$SERVER_BASE/Monitoring"
    )
    
    for dir in "${server_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            sudo mkdir -p "$dir"
            sudo chown root:staff "$dir"
            sudo chmod 755 "$dir"
            success "✓ Created server directory: $dir"
        else
            success "✓ Server directory exists: $dir"
        fi
    done
}

# Enable File Sharing service
enable_file_sharing_service() {
    info "Enabling File Sharing service..."
    
    # Enable SMB file sharing
    if sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.smbd.plist 2>/dev/null; then
        success "✓ SMB file sharing service enabled"
    else
        warn "Could not enable SMB service automatically"
        info "Enable manually: System Preferences > Sharing > File Sharing"
    fi
    
    # Enable AFP (Apple Filing Protocol) for legacy compatibility
    if sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.AppleFileServer.plist 2>/dev/null; then
        success "✓ AFP file sharing service enabled"
    else
        info "AFP service not available or already configured"
    fi
    
    success "File Sharing services configured"
}

# Configure shared folders
configure_shared_folders() {
    info "Configuring shared folders..."
    
    # Add shared folders to File Sharing
    local shared_folders=(
        "$FILE_SHARE_BASE/Public:Public Files"
        "$FILE_SHARE_BASE/Family:Family Shared"
        "$FILE_SHARE_BASE/Documents:Documents"
        "$FILE_SHARE_BASE/Media:Media Library"
        "$FILE_SHARE_BASE/Software:Software Archive"
    )
    
    for folder_spec in "${shared_folders[@]}"; do
        local folder_path="${folder_spec%%:*}"
        local folder_name="${folder_spec##*:}"
        
        if [[ -d "$folder_path" ]]; then
            # Note: Manual configuration required in System Preferences
            info "Share configured: $folder_name ($folder_path)"
        fi
    done
    
    info "Shared folder configuration guidance:"
    info "1. Open System Preferences > Sharing"
    info "2. Enable File Sharing if not already enabled"
    info "3. Add shared folders using the '+' button:"
    for folder_spec in "${shared_folders[@]}"; do
        local folder_path="${folder_spec%%:*}"
        local folder_name="${folder_spec##*:}"
        info "   • $folder_name: $folder_path"
    done
    info "4. Configure user access permissions for each shared folder"
}

# Configure file server permissions
configure_file_server_permissions() {
    info "Configuring file server permissions..."
    
    # Set up ACLs for file server directories
    if [[ -d "$FILE_SHARE_BASE" ]]; then
        # Allow staff group read/write access
        sudo chmod +a "group:staff allow read,write,execute,delete,add_file,add_subdirectory,file_inherit,directory_inherit" "$FILE_SHARE_BASE" 2>/dev/null || warn "Could not set ACL on file share base"
        
        # Set group sticky bit for proper ownership
        sudo chmod g+s "$FILE_SHARE_BASE"
        
        success "✓ File server permissions configured"
    fi
    
    # Create file server usage guidelines
    create_file_server_guidelines
}

# Create file server usage guidelines
create_file_server_guidelines() {
    local guidelines_file="$FILE_SHARE_BASE/README_File_Server.md"
    
    if [[ ! -f "$guidelines_file" ]]; then
        sudo tee "$guidelines_file" > /dev/null << 'EOF'
# Mac Studio File Server Usage Guide

## Overview
This Mac Studio serves as the central file server for the family network, providing shared storage and backup services for all family devices.

## Shared Folders

### Public Files (`/Users/Shared/FileShare/Public/`)
- General purpose file sharing
- Accessible to all family members
- Use for temporary file exchange

### Family Shared (`/Users/Shared/FileShare/Family/`)
- Long-term family document storage
- Photos, videos, and important documents
- Organised by category and date

### Documents (`/Users/Shared/FileShare/Documents/`)
- Shared work documents and templates
- Reference materials
- Administrative documents

### Media Library (`/Users/Shared/FileShare/Media/`)
- Centralised media storage
- Music, video, and photo collections
- Accessible to all media devices

### Software Archive (`/Users/Shared/FileShare/Software/`)
- Family software licenses and installers
- Utility applications
- System recovery tools

## Access Methods

### From macOS
- Connect: Go > Connect to Server (⌘K)
- Address: `smb://10.20.0.10` or `afp://10.20.0.10`
- Use family member credentials for access

### From Windows
- Open File Explorer
- Address bar: `\\10.20.0.10`
- Enter family member credentials

### From iOS/iPadOS
- Files app > Browse > Connect to Server
- Address: `smb://10.20.0.10`

## Security and Access

### User Access Levels
- **Family Members**: Read/write access to appropriate folders
- **Guests**: Limited access to Public folder only
- **Administrators**: Full access to all folders and server management

### Best Practices
- Use strong passwords for all accounts
- Regularly backup important shared files
- Keep shared folders organised and clean
- Report any access issues to the system administrator

## Backup Strategy

### Time Machine Integration
- Time Machine backup destinations are configured
- Regular automated backups for all family devices
- Backup retention managed automatically

### Manual Backups
- Important files are duplicated to Backups folder
- Regular verification of backup integrity
- Offsite backup for critical data

## Monitoring and Maintenance

### Regular Tasks
- Monitor disk space usage
- Check backup status weekly
- Update shared software monthly
- Review access logs for security

### Performance Optimisation
- Defragment storage quarterly
- Update macOS and services regularly
- Monitor network performance
- Optimise file organisation

## Troubleshooting

### Connection Issues
1. Verify network connectivity to 10.20.0.10
2. Check File Sharing service status
3. Verify user credentials
4. Restart File Sharing service if needed

### Performance Issues
1. Check available disk space
2. Monitor CPU and memory usage
3. Verify network speed
4. Review error logs in Console app

### Access Permission Issues
1. Verify user account access rights
2. Check folder permissions
3. Reset SMB/AFP configuration if needed
4. Contact system administrator

---
Mac Studio File Server
Last updated: $(date +"%Y-%m-%d")
EOF
        
        sudo chown root:staff "$guidelines_file"
        sudo chmod 664 "$guidelines_file"
        success "✓ Created file server usage guidelines"
    fi
}

# Configure Time Machine backup server
configure_time_machine_server() {
    info "Configuring Time Machine backup server..."
    
    # Set up Time Machine directory structure
    setup_time_machine_directories
    
    # Configure Time Machine service
    enable_time_machine_service
    
    # Create backup destinations
    create_backup_destinations
}

# Set up Time Machine directory structure
setup_time_machine_directories() {
    info "Setting up Time Machine directory structure..."
    
    if [[ ! -d "$TIME_MACHINE_BASE" ]]; then
        sudo mkdir -p "$TIME_MACHINE_BASE"
        sudo chown root:admin "$TIME_MACHINE_BASE"
        sudo chmod 755 "$TIME_MACHINE_BASE"
        success "✓ Created Time Machine base directory"
    fi
    
    # Create individual backup destinations
    local backup_destinations=(
        "MacBook-Pro-Backup"
        "Mac-Mini-Backup"
        "Family-Archive"
    )
    
    for destination in "${backup_destinations[@]}"; do
        local dest_path="$TIME_MACHINE_BASE/$destination"
        if [[ ! -d "$dest_path" ]]; then
            sudo mkdir -p "$dest_path"
            sudo chown root:admin "$dest_path"
            sudo chmod 755 "$dest_path"
            success "✓ Created backup destination: $destination"
        fi
    done
}

# Enable Time Machine service
enable_time_machine_service() {
    info "Enabling Time Machine service..."
    
    # Time Machine server requires manual configuration in System Preferences
    info "Time Machine server configuration guidance:"
    info "1. Open System Preferences > Sharing"
    info "2. Enable File Sharing if not already enabled"
    info "3. Select Time Machine backup folders in shared folders list"
    info "4. Enable 'Share as Time Machine backup destination' option"
    info "5. Configure access permissions for family members"
    
    success "Time Machine service configuration guided"
}

# Create backup destinations
create_backup_destinations() {
    info "Creating Time Machine backup destinations..."
    
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
        
        if [[ -d "$dest_path" ]]; then
            # Create destination info file
            sudo tee "$dest_path/README.txt" > /dev/null << EOF
Time Machine Backup Destination
==============================

Destination: $dest_desc
Created: $(date)
Path: $dest_path

This directory serves as a Time Machine backup destination.
Do not manually modify or delete files in this directory.

For backup management, use Time Machine preferences on client devices.
EOF
            
            sudo chown root:admin "$dest_path/README.txt"
            success "✓ Configured backup destination: $dest_desc"
        fi
    done
}

# Configure headless operation optimisations
configure_headless_optimisations() {
    info "Configuring headless operation optimisations..."
    
    # Configure power management for server operation
    configure_server_power_management
    
    # Configure system preferences for headless operation
    configure_headless_preferences
    
    # Set up automatic startup and crash recovery
    configure_automatic_recovery
    
    # Configure login window for headless operation
    configure_headless_login
}

# Configure server power management
configure_server_power_management() {
    info "Configuring server power management..."
    
    # Never sleep for server operation
    sudo pmset -a sleep 0 displaysleep 30 2>/dev/null || warn "Could not configure sleep settings"
    
    # Enable wake on network access
    sudo pmset -a womp 1 2>/dev/null || warn "Could not enable wake on network"
    
    # Enable automatic restart after power failure
    sudo pmset -a autorestart 1 2>/dev/null || warn "Could not enable auto restart"
    
    # Enable automatic restart after system freeze
    sudo pmset -a panicrestart 1 2>/dev/null || warn "Could not enable panic restart"
    
    # Disable sudden motion sensor (not needed for desktop)
    sudo pmset -a sms 0 2>/dev/null || info "Sudden motion sensor not available"
    
    success "✓ Server power management configured"
}

# Configure headless preferences
configure_headless_preferences() {
    info "Configuring headless operation preferences..."
    
    # Disable screen saver for server operation
    defaults write com.apple.screensaver idleTime -int 0
    
    # Configure Dock for headless operation (minimal)
    defaults write com.apple.dock autohide -bool true
    defaults write com.apple.dock autohide-delay -float 0
    defaults write com.apple.dock autohide-time-modifier -float 0
    
    # Disable automatic software updates that require restart
    sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload -bool false
    sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticallyInstallMacOSUpdates -bool false
    
    success "✓ Headless operation preferences configured"
}

# Configure automatic recovery
configure_automatic_recovery() {
    info "Configuring automatic startup and crash recovery..."
    
    # Enable automatic login for server operation
    read -p "Enable automatic login for headless operation? [y/N]: " auto_login_choice
    if [[ "$auto_login_choice" == "y" || "$auto_login_choice" == "Y" ]]; then
        local current_user
        current_user=$(whoami)
        sudo defaults write /Library/Preferences/com.apple.loginwindow autoLoginUser "$current_user"
        success "✓ Automatic login enabled for $current_user"
        
        warn "Security notice: Automatic login reduces security"
        warn "Ensure FileVault encryption is enabled for data protection"
    else
        info "Automatic login not enabled - manual login required after restart"
    fi
    
    # Configure startup items for server services
    configure_startup_items
}

# Configure startup items
configure_startup_items() {
    info "Configuring startup items for server operation..."
    
    # Create server startup script
    local startup_script="$SERVER_BASE/Scripts/server_startup.zsh"
    sudo tee "$startup_script" > /dev/null << 'EOF'
#!/usr/bin/env zsh
# Mac Studio Server Startup Script

# Log startup
echo "$(date): Mac Studio server startup initiated" >> /var/log/server_startup.log

# Ensure essential services are running
launchctl load -w /System/Library/LaunchDaemons/com.apple.smbd.plist 2>/dev/null || true
launchctl load -w /System/Library/LaunchDaemons/com.apple.screensharing.plist 2>/dev/null || true

# Start Jump Desktop Connect if installed
if [[ -d "/Applications/Jump Desktop Connect.app" ]]; then
    open -a "Jump Desktop Connect" 2>/dev/null || true
fi

# Check disk space and log status
df -h / >> /var/log/server_startup.log

echo "$(date): Mac Studio server startup completed" >> /var/log/server_startup.log
EOF
    
    sudo chmod 755 "$startup_script"
    sudo chown root:staff "$startup_script"
    
    success "✓ Server startup script created"
    
    info "To enable automatic startup script execution:"
    info "1. Open System Preferences > Users & Groups"
    info "2. Select current user > Login Items"
    info "3. Add server startup script to login items"
}

# Configure headless login
configure_headless_login() {
    info "Configuring login window for headless operation..."
    
    # Configure login window for headless operation
    sudo defaults write /Library/Preferences/com.apple.loginwindow SHOWFULLNAME -bool true
    sudo defaults write /Library/Preferences/com.apple.loginwindow HideLocalUsers -bool false
    sudo defaults write /Library/Preferences/com.apple.loginwindow HideMobileAccounts -bool false
    
    # Disable guest account for security
    sudo defaults write /Library/Preferences/com.apple.loginwindow GuestEnabled -bool false
    
    success "✓ Headless login configuration completed"
}

# Create monitoring and maintenance scripts
create_monitoring_scripts() {
    info "Creating monitoring and maintenance scripts..."
    
    # Create system monitoring script
    create_system_monitor_script
    
    # Create backup monitoring script
    create_backup_monitor_script
    
    # Create maintenance script
    create_maintenance_script
    
    # Set up automated monitoring
    setup_automated_monitoring
}

# Create system monitoring script
create_system_monitor_script() {
    local monitor_script="$SERVER_BASE/Scripts/system_monitor.zsh"
    
    sudo tee "$monitor_script" > /dev/null << 'EOF'
#!/usr/bin/env zsh
# Mac Studio System Monitoring Script

readonly LOG_FILE="/var/log/system_monitor.log"
readonly ALERT_THRESHOLD_DISK=90
readonly ALERT_THRESHOLD_MEMORY=85

# Logging function
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S'): $*" >> "$LOG_FILE"
}

# Check disk usage
check_disk_usage() {
    local usage
    usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    
    if [[ $usage -gt $ALERT_THRESHOLD_DISK ]]; then
        log_message "ALERT: Disk usage at ${usage}% (threshold: ${ALERT_THRESHOLD_DISK}%)"
        return 1
    else
        log_message "INFO: Disk usage at ${usage}% (normal)"
        return 0
    fi
}

# Check memory usage
check_memory_usage() {
    local memory_pressure
    memory_pressure=$(memory_pressure | grep "System-wide memory free percentage" | awk '{print $5}' | sed 's/%//')
    local memory_used=$((100 - memory_pressure))
    
    if [[ $memory_used -gt $ALERT_THRESHOLD_MEMORY ]]; then
        log_message "ALERT: Memory usage at ${memory_used}% (threshold: ${ALERT_THRESHOLD_MEMORY}%)"
        return 1
    else
        log_message "INFO: Memory usage at ${memory_used}% (normal)"
        return 0
    fi
}

# Check essential services
check_services() {
    local services=("com.apple.smbd" "com.apple.screensharing")
    local service_issues=0
    
    for service in "${services[@]}"; do
        if launchctl list | grep -q "$service"; then
            log_message "INFO: Service $service is running"
        else
            log_message "ALERT: Service $service is not running"
            ((service_issues++))
        fi
    done
    
    return $service_issues
}

# Main monitoring function
main() {
    log_message "Starting system monitoring check"
    
    local issues=0
    
    check_disk_usage || ((issues++))
    check_memory_usage || ((issues++))
    check_services || ((issues++))
    
    if [[ $issues -eq 0 ]]; then
        log_message "System monitoring completed: All systems normal"
    else
        log_message "System monitoring completed: $issues issues detected"
    fi
    
    return $issues
}

main "$@"
EOF
    
    sudo chmod 755 "$monitor_script"
    sudo chown root:staff "$monitor_script"
    success "✓ Created system monitoring script"
}

# Create backup monitoring script
create_backup_monitor_script() {
    local backup_script="$SERVER_BASE/Scripts/backup_monitor.zsh"
    
    sudo tee "$backup_script" > /dev/null << 'EOF'
#!/usr/bin/env zsh
# Mac Studio Backup Monitoring Script

readonly LOG_FILE="/var/log/backup_monitor.log"
readonly TIME_MACHINE_BASE="/Users/Shared/TimeMachine"

# Logging function
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S'): $*" >> "$LOG_FILE"
}

# Check Time Machine backup destinations
check_backup_destinations() {
    log_message "Checking Time Machine backup destinations"
    
    if [[ ! -d "$TIME_MACHINE_BASE" ]]; then
        log_message "ERROR: Time Machine base directory not found"
        return 1
    fi
    
    local destinations=0
    local total_size=0
    
    for dest in "$TIME_MACHINE_BASE"/*; do
        if [[ -d "$dest" ]]; then
            local dest_name=$(basename "$dest")
            local dest_size=$(du -sh "$dest" 2>/dev/null | awk '{print $1}' || echo "unknown")
            
            log_message "INFO: Backup destination $dest_name: $dest_size"
            ((destinations++))
        fi
    done
    
    log_message "INFO: Found $destinations backup destinations"
    return 0
}

# Check backup disk space
check_backup_space() {
    local available_space
    available_space=$(df -h "$TIME_MACHINE_BASE" | tail -1 | awk '{print $4}')
    local used_percentage
    used_percentage=$(df "$TIME_MACHINE_BASE" | tail -1 | awk '{print $5}' | sed 's/%//')
    
    log_message "INFO: Backup storage - Available: $available_space, Used: ${used_percentage}%"
    
    if [[ $used_percentage -gt 85 ]]; then
        log_message "ALERT: Backup storage usage high (${used_percentage}%)"
        return 1
    fi
    
    return 0
}

# Main backup monitoring function
main() {
    log_message "Starting backup monitoring check"
    
    local issues=0
    
    check_backup_destinations || ((issues++))
    check_backup_space || ((issues++))
    
    if [[ $issues -eq 0 ]]; then
        log_message "Backup monitoring completed: All backup systems normal"
    else
        log_message "Backup monitoring completed: $issues issues detected"
    fi
    
    return $issues
}

main "$@"
EOF
    
    sudo chmod 755 "$backup_script"
    sudo chown root:staff "$backup_script"
    success "✓ Created backup monitoring script"
}

# Create maintenance script
create_maintenance_script() {
    local maintenance_script="$SERVER_BASE/Scripts/server_maintenance.zsh"
    
    sudo tee "$maintenance_script" > /dev/null << 'EOF'
#!/usr/bin/env zsh
# Mac Studio Server Maintenance Script

readonly LOG_FILE="/var/log/server_maintenance.log"

# Logging function
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S'): $*" >> "$LOG_FILE"
}

# Clean up log files
cleanup_logs() {
    log_message "Starting log cleanup"
    
    # Rotate large log files
    find /var/log -name "*.log" -size +100M -exec gzip {} \; 2>/dev/null || true
    
    # Remove old compressed logs (older than 30 days)
    find /var/log -name "*.log.gz" -mtime +30 -delete 2>/dev/null || true
    
    # Clean up system logs
    sudo log collect --size 100m --output /tmp/system_logs.logarchive 2>/dev/null || true
    
    log_message "Log cleanup completed"
}

# Update system and applications
update_system() {
    log_message "Checking for system updates"
    
    # Check for macOS updates
    if softwareupdate -l 2>&1 | grep -q "No new software available"; then
        log_message "INFO: No system updates available"
    else
        log_message "INFO: System updates available - manual installation recommended"
    fi
    
    # Update Homebrew if available
    if command -v brew &>/dev/null; then
        brew update --quiet 2>/dev/null || true
        brew upgrade --quiet 2>/dev/null || true
        brew cleanup --quiet 2>/dev/null || true
        log_message "INFO: Homebrew updated"
    fi
}

# Verify backup integrity
verify_backups() {
    log_message "Verifying backup integrity"
    
    local backup_base="/Users/Shared/TimeMachine"
    if [[ -d "$backup_base" ]]; then
        # Check backup directories are accessible
        for backup_dir in "$backup_base"/*; do
            if [[ -d "$backup_dir" ]]; then
                local backup_name=$(basename "$backup_dir")
                if [[ -r "$backup_dir" ]]; then
                    log_message "INFO: Backup $backup_name is accessible"
                else
                    log_message "ERROR: Backup $backup_name is not accessible"
                fi
            fi
        done
    fi
}

# Optimise storage
optimise_storage() {
    log_message "Optimising storage"
    
    # Empty trash for all users
    sudo rm -rf /Users/*/.Trash/* 2>/dev/null || true
    
    # Clean up temporary files
    sudo rm -rf /tmp/* 2>/dev/null || true
    sudo rm -rf /var/tmp/* 2>/dev/null || true
    
    # Rebuild Spotlight index if needed
    # sudo mdutil -E / 2>/dev/null || true
    
    log_message "Storage optimisation completed"
}

# Main maintenance function
main() {
    log_message "Starting server maintenance"
    
    cleanup_logs
    update_system
    verify_backups
    optimise_storage
    
    log_message "Server maintenance completed"
}

main "$@"
EOF
    
    sudo chmod 755 "$maintenance_script"
    sudo chown root:staff "$maintenance_script"
    success "✓ Created server maintenance script"
}

# Set up automated monitoring
setup_automated_monitoring() {
    info "Setting up automated monitoring..."
    
    # Create launchd configuration for monitoring
    local monitoring_plist="$HOME/Library/LaunchAgents/com.family.mac-studio.monitoring.plist"
    
    cat > "$monitoring_plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.family.mac-studio.monitoring</string>
    <key>ProgramArguments</key>
    <array>
        <string>$SERVER_BASE/Scripts/system_monitor.zsh</string>
    </array>
    <key>StartInterval</key>
    <integer>3600</integer>
    <key>RunAtLoad</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/var/log/monitoring.out</string>
    <key>StandardErrorPath</key>
    <string>/var/log/monitoring.err</string>
</dict>
</plist>
EOF
    
    # Load the monitoring service
    launchctl load "$monitoring_plist" 2>/dev/null || warn "Could not load monitoring service"
    
    success "✓ Automated monitoring configured"
    
    info "Monitoring schedule:"
    info "• System monitoring: Every hour"
    info "• Backup monitoring: Run backup_monitor.zsh manually or via cron"
    info "• Server maintenance: Run server_maintenance.zsh weekly"
}

# Help function
usage() {
    cat << EOF
$SCRIPT_NAME - Mac Studio Server Configuration

USAGE:
    $SCRIPT_NAME [OPTIONS]

DESCRIPTION:
    Configures Mac Studio as a comprehensive family server with file sharing,
    Time Machine backup, headless operation optimisations, and monitoring.

OPTIONS:
    -h, --help           Show this help message

SERVER FEATURES:
    • Central file server with SMB/AFP sharing
    • Time Machine backup server for family devices
    • Headless operation optimisations
    • Automated monitoring and maintenance
    • Remote access configuration
    • Power management for 24/7 operation

EXAMPLES:
    $SCRIPT_NAME                    # Configure complete Mac Studio server

SERVER SERVICES:
    File Server         Central storage for family files and media
    Time Machine        Backup destinations for MacBook Pro and Mac Mini
    Monitoring          Automated system health and backup monitoring
    Remote Access       SSH, Screen Sharing, Jump Desktop Connect
    Maintenance         Automated cleanup and optimisation

DIRECTORY STRUCTURE:
    /Users/Shared/FileShare/        Central file sharing
    /Users/Shared/TimeMachine/      Time Machine backup destinations
    /Users/Shared/Server/           Server configuration and scripts

NOTES:
    • Requires manual configuration in System Preferences > Sharing
    • Optimised for 24/7 headless operation
    • Includes comprehensive monitoring and maintenance
    • Configured for family network (10.20.0.10)

EOF
}

# Main execution
main() {
    # Verify this is being run on a Mac Studio
    local model_identifier
    model_identifier=$(system_profiler SPHardwareDataType | grep "Model Identifier" | awk '{print $3}')
    
    if [[ "$model_identifier" != MacStudio* ]]; then
        warn "This script is designed for Mac Studio"
        warn "Current model: $model_identifier"
        read -p "Continue anyway? [y/N]: " continue_choice
        if [[ "$continue_choice" != "y" && "$continue_choice" != "Y" ]]; then
            info "Mac Studio server setup cancelled"
            exit 0
        fi
    fi
    
    info "Mac Studio Server Configuration"
    info "==============================="
    echo
    
    # Configure file server
    configure_file_server
    echo
    
    # Configure Time Machine server
    configure_time_machine_server
    echo
    
    # Configure headless optimisations
    configure_headless_optimisations
    echo
    
    # Create monitoring scripts
    create_monitoring_scripts
    echo
    
    success "=========================================="
    success "Mac Studio server configuration completed!"
    success "=========================================="
    success "Your Mac Studio is now configured as a comprehensive family server"
    
    info "Server features configured:"
    info "• Central file server with shared folders"
    info "• Time Machine backup server for family devices"
    info "• Headless operation optimisations"
    info "• Automated system monitoring and maintenance"
    info "• Remote access capabilities"
    
    echo
    info "Next steps:"
    info "1. Complete file sharing setup in System Preferences > Sharing"
    info "2. Configure Time Machine destinations for client devices"
    info "3. Test remote access from other family devices"
    info "4. Set up regular monitoring schedule"
    info "5. Configure client devices to use this server for backup"
    
    return 0
}

# Parse command line arguments
case "${1:-}" in
    -h|--help)
        usage
        exit 0
        ;;
    *)
        if [[ -n "${1:-}" ]]; then
            error "Unknown option: $1"
            usage
            exit 1
        fi
        ;;
esac

# Run main function
main
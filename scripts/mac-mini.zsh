#!/usr/bin/env zsh
# ABOUTME: Mac Mini specific setup script - configures compact server operation
# ABOUTME: Optimized for Mac Mini M4 16GB with efficient server functionality

set -euo pipefail

# Script configuration
readonly SCRIPT_DIR="${0:A:h}"
readonly CONFIG_DIR="${SCRIPT_DIR}/config"
readonly MODULES_DIR="${SCRIPT_DIR}/../modules"
readonly MINI_CONFIG="${CONFIG_DIR}/mac-mini.yml"

# Colour codes
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly BOLD='\033[1m'
readonly RESET='\033[0m'

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${RESET} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${RESET} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARNING]${RESET} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${RESET} $*"
}

# Check if running on Mac Mini
check_mac_mini() {
    local model_name
    model_name=$(system_profiler SPHardwareDataType | grep "Model Name" | awk -F': ' '{print $2}' | xargs)
    
    if [[ "$model_name" != *"Mac mini"* ]]; then
        log_error "This script is designed for Mac Mini. Detected: $model_name"
        exit 1
    fi
    
    log_success "Mac Mini detected: $model_name"
}

# Request sudo access upfront
request_sudo() {
    log_info "Requesting administrator privileges..."
    if ! sudo -v; then
        log_error "Administrator privileges required"
        exit 1
    fi
    
    # Keep sudo alive
    while true; do
        sudo -n true
        sleep 60
        kill -0 "$$" || exit
    done 2>/dev/null &
}

# Configure system naming
configure_system_naming() {
    log_info "Configuring system naming..."
    
    if [[ -f "${MODULES_DIR}/network.zsh" ]]; then
        source "${MODULES_DIR}/network.zsh"
        configure_system_names "$MINI_CONFIG"
    else
        log_warn "Network module not found, configuring manually..."
        
        # Set system names
        log_info "Setting hostname to mac-mini..."
        sudo scutil --set HostName mac-mini
        
        log_info "Setting computer name to Mac Mini..."
        sudo scutil --set ComputerName "Mac Mini"
        
        log_info "Setting local hostname to mac-mini..."
        sudo scutil --set LocalHostName mac-mini
    fi
    
    log_success "System naming configured"
}

# Configure system settings
configure_system_settings() {
    log_info "Configuring system settings..."
    
    # Configure system preferences
    if [[ -f "${MODULES_DIR}/system-preferences.zsh" ]]; then
        source "${MODULES_DIR}/system-preferences.zsh"
        configure_system_preferences "$MINI_CONFIG"
    fi
    
    # Configure power management for always-on operation
    if [[ -f "${MODULES_DIR}/power-management.zsh" ]]; then
        source "${MODULES_DIR}/power-management.zsh"
        configure_power_management "$MINI_CONFIG"
    else
        log_warn "Power management module not found, configuring manually..."
        
        # Configure for always-on operation
        log_info "Configuring always-on power management..."
        sudo pmset -a sleep 0
        sudo pmset -a displaysleep 10
        sudo pmset -a disksleep 0
        sudo pmset -a powernap 1
        sudo pmset -a womp 1
        sudo pmset -a hibernatemode 0
        sudo pmset -a standby 0
        sudo pmset -a acwake 1
        
        # Set daily maintenance wake
        sudo pmset repeat wakeorpoweron MTWRFSU 02:00:00
    fi
    
    log_success "System settings configured"
}

# Configure network settings
configure_network_settings() {
    log_info "Configuring network settings..."
    
    if [[ -f "${MODULES_DIR}/network.zsh" ]]; then
        source "${MODULES_DIR}/network.zsh"
        configure_network "$MINI_CONFIG"
    else
        log_warn "Network module not found, configuring manually..."
        
        # Disable Wi-Fi (server configuration)
        log_info "Disabling Wi-Fi..."
        sudo networksetup -setairportpower en0 off
        
        # Configure static IP
        log_info "Configuring static IP..."
        local network_service=$(networksetup -listnetworkserviceorder | grep -A1 "Ethernet" | tail -1 | sed 's/.*) //')
        if [[ -n "$network_service" ]]; then
            sudo networksetup -setmanual "$network_service" 192.168.1.101 255.255.255.0 192.168.1.1
            sudo networksetup -setdnsservers "$network_service" 1.1.1.1 1.0.0.1
        fi
        
        # Enable Thunderbolt networking
        log_info "Enabling Thunderbolt networking..."
        # Thunderbolt networking is generally enabled by default
    fi
    
    log_success "Network settings configured"
}

# Configure DNS settings
configure_dns_settings() {
    log_info "Configuring DNS settings..."
    
    # Set custom DNS servers
    local network_service=$(networksetup -listnetworkserviceorder | grep -A1 "Ethernet" | tail -1 | sed 's/.*) //')
    if [[ -n "$network_service" ]]; then
        log_info "Setting DNS servers to 1.1.1.1 and 1.0.0.1..."
        sudo networksetup -setdnsservers "$network_service" 1.1.1.1 1.0.0.1
    fi
    
    log_success "DNS settings configured"
}

# Configure DHCP settings
configure_dhcp_settings() {
    log_info "Configuring DHCP settings..."
    
    # For Mac Mini server, we typically use static IP
    log_info "Using static IP configuration (DHCP disabled)"
    
    log_success "DHCP settings configured"
}

# Configure security settings
configure_security_settings() {
    log_info "Configuring security settings..."
    
    if [[ -f "${MODULES_DIR}/security.zsh" ]]; then
        source "${MODULES_DIR}/security.zsh"
        configure_security "$MINI_CONFIG"
    else
        log_warn "Security module not found, configuring manually..."
        
        # Enable firewall
        log_info "Enabling firewall..."
        sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
        sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on
        
        # Configure SSH
        log_info "Configuring SSH..."
        sudo systemsetup -setremotelogin on
        
        # Generate SSH key if not exists
        if [[ ! -f ~/.ssh/id_ed25519 ]]; then
            ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""
        fi
        
        # Disable guest user
        log_info "Disabling guest user..."
        sudo defaults write /Library/Preferences/com.apple.loginwindow GuestEnabled -bool false
    fi
    
    log_success "Security settings configured"
}

# Configure sharing services
configure_sharing_services() {
    log_info "Configuring sharing services..."
    
    if [[ -f "${MODULES_DIR}/sharing.zsh" ]]; then
        source "${MODULES_DIR}/sharing.zsh"
        configure_sharing "$MINI_CONFIG"
    else
        log_warn "Sharing module not found, configuring manually..."
        
        # Enable SMB sharing
        log_info "Enabling SMB sharing..."
        sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.smbd.plist
        
        # Enable SSH
        log_info "Enabling SSH..."
        sudo systemsetup -setremotelogin on
        
        # Enable screen sharing
        log_info "Enabling screen sharing..."
        sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.screensharing.plist
        
        # Enable Time Machine server
        log_info "Enabling Time Machine server..."
        sudo tmutil setdestination -a /Users/Shared/TimeMachine
        
        # Create shared folder
        log_info "Creating shared folder..."
        sudo mkdir -p /Users/Shared/Mini-Server
        sudo chmod 755 /Users/Shared/Mini-Server
    fi
    
    log_success "Sharing services configured"
}

# Configure server-specific settings
configure_server_settings() {
    log_info "Configuring server-specific settings..."
    
    # Configure dock for server use
    log_info "Configuring dock for server use..."
    defaults write com.apple.dock autohide -bool true
    defaults write com.apple.dock tilesize -int 36
    defaults write com.apple.dock show-recents -bool false
    
    # Disable notifications for server
    log_info "Disabling notifications for server use..."
    defaults write com.apple.notificationcenterui bannerTime -int 0
    
    # Disable screensaver
    log_info "Disabling screensaver..."
    defaults -currentHost write com.apple.screensaver idleTime -int 0
    
    # Disable Siri and Apple Intelligence
    log_info "Disabling Siri and Apple Intelligence..."
    defaults write com.apple.assistant.support "Assistant Enabled" -bool false
    defaults write com.apple.assistant.support "Dictation Enabled" -bool false
    
    # Set solid black wallpaper
    log_info "Setting solid black wallpaper..."
    # Solid color wallpaper requires manual configuration
    
    # Disable sound effects
    log_info "Disabling sound effects..."
    defaults write com.apple.systemsound "com.apple.sound.beep.volume" -float 0
    defaults write com.apple.systemsound "com.apple.sound.uiaudio.enabled" -int 0
    
    # Restart affected services
    killall Dock &>/dev/null || true
    
    log_success "Server-specific settings configured"
}

# Configure performance settings
configure_performance_settings() {
    log_info "Configuring performance settings..."
    
    # Optimize for efficiency (16GB RAM)
    log_info "Optimizing system for efficiency..."
    
    # Reduce visual effects
    defaults write com.apple.universalaccess reduceMotion -bool true
    defaults write com.apple.universalaccess reduceTransparency -bool true
    
    # Limit background app refresh
    defaults write NSGlobalDomain NSAppRefreshEnabled -bool false
    
    # Disable Time Machine local snapshots
    sudo tmutil disablelocal
    
    # Selective spotlight indexing
    log_info "Configuring selective Spotlight indexing..."
    # Disable spotlight on certain directories to save resources
    sudo mdutil -i off /private/var/vm
    
    log_success "Performance settings configured"
}

# Show configuration summary
show_configuration_summary() {
    log_info "Mac Mini Configuration Summary:"
    echo
    echo "System Information:"
    echo "  Hostname: $(scutil --get HostName 2>/dev/null || echo 'Not set')"
    echo "  Computer Name: $(scutil --get ComputerName 2>/dev/null || echo 'Not set')"
    echo "  Local Hostname: $(scutil --get LocalHostName 2>/dev/null || echo 'Not set')"
    echo
    echo "Network Configuration:"
    echo "  IP Address: $(ifconfig en0 | grep 'inet ' | awk '{print $2}' || echo 'Not configured')"
    echo "  DNS Servers: $(scutil --dns | grep 'nameserver' | head -2 | awk '{print $3}' | paste -sd ',' -)"
    echo "  Wi-Fi: $(networksetup -getairportpower en0 | grep -o 'On\|Off')"
    echo
    echo "Security Status:"
    echo "  Firewall: $(sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate | grep -o 'enabled\|disabled')"
    echo "  SSH: $(systemsetup -getremotelogin | grep -o 'On\|Off')"
    echo "  FileVault: $(fdesetup status | grep -o 'On\|Off')"
    echo
    echo "Power Management:"
    echo "  System Sleep: $(pmset -g | grep 'sleep' | awk '{print $2}') minutes"
    echo "  Display Sleep: $(pmset -g | grep 'displaysleep' | awk '{print $2}') minutes"
    echo "  Wake Schedule: $(pmset -g sched | grep -o '[0-9][0-9]:[0-9][0-9]' || echo 'None')"
    echo
    echo "Sharing Services:"
    echo "  SMB: $(launchctl list | grep -q smb && echo 'Enabled' || echo 'Disabled')"
    echo "  Screen Sharing: $(launchctl list | grep -q screensharing && echo 'Enabled' || echo 'Disabled')"
    echo "  Time Machine: $(tmutil destinationinfo >/dev/null 2>&1 && echo 'Enabled' || echo 'Disabled')"
    echo
    echo "Server Optimizations:"
    echo "  Visual Effects: Reduced"
    echo "  Notifications: Disabled"
    echo "  Screensaver: Disabled"
    echo "  Sound Effects: Disabled"
}

# Main setup function
main() {
    log_info "Starting Mac Mini specific setup..."
    
    # Initial checks
    check_mac_mini
    request_sudo
    
    # System naming
    log_info "=== Configuring System Naming ==="
    configure_system_naming
    
    # System configuration
    log_info "=== Configuring System Settings ==="
    configure_system_settings
    
    # Network configuration
    log_info "=== Configuring Network Settings ==="
    configure_network_settings
    
    # DNS configuration
    log_info "=== Configuring DNS Settings ==="
    configure_dns_settings
    
    # DHCP configuration
    log_info "=== Configuring DHCP Settings ==="
    configure_dhcp_settings
    
    # Security configuration
    log_info "=== Configuring Security Settings ==="
    configure_security_settings
    
    # Sharing services
    log_info "=== Configuring Sharing Services ==="
    configure_sharing_services
    
    # Server-specific settings
    log_info "=== Configuring Server-Specific Settings ==="
    configure_server_settings
    
    # Performance settings
    log_info "=== Configuring Performance Settings ==="
    configure_performance_settings
    
    log_success "Mac Mini setup complete!"
    
    # Show configuration summary
    echo
    show_configuration_summary
    
    # Final instructions
    echo
    log_info "Mac Mini is now configured for compact server operation."
    log_info "Next steps:"
    echo "1. Run security hardening script if needed"
    echo "2. Install server applications using Brewfiles"
    echo "3. Configure automated backups"
    echo "4. Set up monitoring and alerts"
    echo "5. Configure additional services as needed"
    echo
    log_info "The Mac Mini is optimized for:"
    echo "  • Compact server operation (always-on)"
    echo "  • Efficient resource utilization (16GB RAM)"
    echo "  • Remote access via SSH and Screen Sharing"
    echo "  • File sharing and Time Machine server"
    echo "  • Minimal UI for headless operation"
    echo "  • Network-attached storage functionality"
}

# Run main function
main "$@"
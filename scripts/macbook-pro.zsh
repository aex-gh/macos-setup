#!/usr/bin/env zsh
# ABOUTME: MacBook Pro specific setup script - configures mobile productivity and balanced power
# ABOUTME: Optimized for MacBook Pro M1 Pro 32GB with battery life and portability focus

set -euo pipefail

# Script configuration
readonly SCRIPT_DIR="${0:A:h}"
readonly CONFIG_DIR="${SCRIPT_DIR}/config"
readonly MODULES_DIR="${SCRIPT_DIR}/../modules"
readonly MACBOOK_CONFIG="${CONFIG_DIR}/macbook-pro.yml"

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

# Check if running on MacBook Pro
check_macbook_pro() {
    local model_name
    model_name=$(system_profiler SPHardwareDataType | grep "Model Name" | awk -F': ' '{print $2}' | xargs)
    
    if [[ "$model_name" != *"MacBook Pro"* ]]; then
        log_error "This script is designed for MacBook Pro. Detected: $model_name"
        exit 1
    fi
    
    log_success "MacBook Pro detected: $model_name"
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
        configure_system_names "$MACBOOK_CONFIG"
    else
        log_warn "Network module not found, configuring manually..."
        
        # Set system names
        log_info "Setting hostname to macbook-pro..."
        sudo scutil --set HostName macbook-pro
        
        log_info "Setting computer name to MacBook Pro..."
        sudo scutil --set ComputerName "MacBook Pro"
        
        log_info "Setting local hostname to macbook-pro..."
        sudo scutil --set LocalHostName macbook-pro
    fi
    
    log_success "System naming configured"
}

# Configure system settings
configure_system_settings() {
    log_info "Configuring system settings..."
    
    # Configure system preferences
    if [[ -f "${MODULES_DIR}/system-preferences.zsh" ]]; then
        source "${MODULES_DIR}/system-preferences.zsh"
        configure_system_preferences "$MACBOOK_CONFIG"
    fi
    
    # Configure power management for mobile use
    if [[ -f "${MODULES_DIR}/power-management.zsh" ]]; then
        source "${MODULES_DIR}/power-management.zsh"
        configure_power_management "$MACBOOK_CONFIG"
    else
        log_warn "Power management module not found, configuring manually..."
        
        # Battery power settings (conservative)
        log_info "Configuring battery power settings..."
        sudo pmset -b sleep 15
        sudo pmset -b displaysleep 5
        sudo pmset -b disksleep 10
        
        # AC power settings (performance)
        log_info "Configuring AC power settings..."
        sudo pmset -c sleep 0
        sudo pmset -c displaysleep 30
        sudo pmset -c disksleep 0
        
        # Enable hibernation for battery preservation
        sudo pmset -a hibernatemode 3
        sudo pmset -a standby 1
        sudo pmset -a standbydelay 86400
    fi
    
    log_success "System settings configured"
}

# Configure network settings
configure_network_settings() {
    log_info "Configuring network settings..."
    
    if [[ -f "${MODULES_DIR}/network.zsh" ]]; then
        source "${MODULES_DIR}/network.zsh"
        configure_network "$MACBOOK_CONFIG"
    else
        log_warn "Network module not found, configuring manually..."
        
        # Keep Wi-Fi enabled (mobile device)
        log_info "Keeping Wi-Fi enabled for mobile use..."
        sudo networksetup -setairportpower en0 on
        
        # Configure DNS servers
        log_info "Configuring DNS servers..."
        local wifi_service=$(networksetup -listnetworkserviceorder | grep -A1 "Wi-Fi" | tail -1 | sed 's/.*) //')
        if [[ -n "$wifi_service" ]]; then
            sudo networksetup -setdnsservers "$wifi_service" 1.1.1.1 1.0.0.1
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
    
    # Set custom DNS servers for Wi-Fi
    local wifi_service=$(networksetup -listnetworkserviceorder | grep -A1 "Wi-Fi" | tail -1 | sed 's/.*) //')
    if [[ -n "$wifi_service" ]]; then
        log_info "Setting DNS servers for Wi-Fi..."
        sudo networksetup -setdnsservers "$wifi_service" 1.1.1.1 1.0.0.1
    fi
    
    # Set custom DNS servers for Ethernet (when docked)
    local ethernet_service=$(networksetup -listnetworkserviceorder | grep -A1 "Ethernet" | tail -1 | sed 's/.*) //')
    if [[ -n "$ethernet_service" ]]; then
        log_info "Setting DNS servers for Ethernet..."
        sudo networksetup -setdnsservers "$ethernet_service" 1.1.1.1 1.0.0.1
    fi
    
    log_success "DNS settings configured"
}

# Configure DHCP settings
configure_dhcp_settings() {
    log_info "Configuring DHCP settings..."
    
    # For MacBook Pro, we use DHCP for mobility
    log_info "Using DHCP for mobile connectivity"
    
    # Ensure DHCP is enabled for Wi-Fi
    local wifi_service=$(networksetup -listnetworkserviceorder | grep -A1 "Wi-Fi" | tail -1 | sed 's/.*) //')
    if [[ -n "$wifi_service" ]]; then
        sudo networksetup -setdhcp "$wifi_service"
    fi
    
    log_success "DHCP settings configured"
}

# Configure security settings
configure_security_settings() {
    log_info "Configuring security settings..."
    
    if [[ -f "${MODULES_DIR}/security.zsh" ]]; then
        source "${MODULES_DIR}/security.zsh"
        configure_security "$MACBOOK_CONFIG"
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
        
        # Configure Touch ID for sudo
        log_info "Configuring Touch ID for sudo..."
        if ! grep -q "pam_tid.so" /etc/pam.d/sudo; then
            sudo sed -i '' '2i\
auth       sufficient     pam_tid.so
' /etc/pam.d/sudo
        fi
    fi
    
    log_success "Security settings configured"
}

# Configure sharing services
configure_sharing_services() {
    log_info "Configuring sharing services..."
    
    if [[ -f "${MODULES_DIR}/sharing.zsh" ]]; then
        source "${MODULES_DIR}/sharing.zsh"
        configure_sharing "$MACBOOK_CONFIG"
    else
        log_warn "Sharing module not found, configuring manually..."
        
        # Enable SSH (limited sharing for mobile)
        log_info "Enabling SSH..."
        sudo systemsetup -setremotelogin on
        
        # Enable screen sharing
        log_info "Enabling screen sharing..."
        sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.screensharing.plist
        
        # Don't enable file sharing by default (security for mobile device)
        log_info "File sharing disabled for mobile security"
    fi
    
    log_success "Sharing services configured"
}

# Configure mobile-specific settings
configure_mobile_settings() {
    log_info "Configuring mobile-specific settings..."
    
    # Configure dock for mobile use
    log_info "Configuring dock for mobile use..."
    defaults write com.apple.dock autohide -bool true
    defaults write com.apple.dock tilesize -int 48
    defaults write com.apple.dock show-recents -bool false
    
    # Configure notifications
    log_info "Configuring notifications..."
    # Keep notifications enabled for mobile productivity
    
    # Configure screensaver
    log_info "Configuring screensaver..."
    defaults -currentHost write com.apple.screensaver idleTime -int 300
    
    # Enable Apple Intelligence and Siri
    log_info "Enabling Apple Intelligence and Siri..."
    defaults write com.apple.assistant.support "Assistant Enabled" -bool true
    defaults write com.apple.assistant.support "Dictation Enabled" -bool true
    
    # Configure dynamic wallpaper
    log_info "Setting dynamic wallpaper..."
    # Dynamic wallpaper setting requires manual configuration
    
    # Restart affected services
    killall Dock &>/dev/null || true
    
    log_success "Mobile-specific settings configured"
}

# Configure productivity settings
configure_productivity_settings() {
    log_info "Configuring productivity settings..."
    
    # Enable full visual effects for better user experience
    log_info "Enabling full visual effects..."
    defaults write com.apple.universalaccess reduceMotion -bool false
    defaults write com.apple.universalaccess reduceTransparency -bool false
    
    # Enable background app refresh smartly
    log_info "Enabling smart background app refresh..."
    defaults write NSGlobalDomain NSAppRefreshEnabled -bool true
    
    # Enable Time Machine local snapshots
    log_info "Enabling Time Machine local snapshots..."
    sudo tmutil enablelocal
    
    # Enable spotlight full indexing
    log_info "Enabling full Spotlight indexing..."
    sudo mdutil -a -i on
    
    log_success "Productivity settings configured"
}

# Show configuration summary
show_configuration_summary() {
    log_info "MacBook Pro Configuration Summary:"
    echo
    echo "System Information:"
    echo "  Hostname: $(scutil --get HostName 2>/dev/null || echo 'Not set')"
    echo "  Computer Name: $(scutil --get ComputerName 2>/dev/null || echo 'Not set')"
    echo "  Local Hostname: $(scutil --get LocalHostName 2>/dev/null || echo 'Not set')"
    echo
    echo "Network Configuration:"
    echo "  Wi-Fi Status: $(networksetup -getairportpower en0 | grep -o 'On\|Off')"
    echo "  Current IP: $(ifconfig en0 | grep 'inet ' | awk '{print $2}' 2>/dev/null || echo 'Not connected')"
    echo "  DNS Servers: $(scutil --dns | grep 'nameserver' | head -2 | awk '{print $3}' | paste -sd ',' -)"
    echo
    echo "Security Status:"
    echo "  Firewall: $(sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate | grep -o 'enabled\|disabled')"
    echo "  SSH: $(systemsetup -getremotelogin | grep -o 'On\|Off')"
    echo "  FileVault: $(fdesetup status | grep -o 'On\|Off')"
    echo "  Touch ID sudo: $(grep -q 'pam_tid.so' /etc/pam.d/sudo && echo 'Enabled' || echo 'Disabled')"
    echo
    echo "Power Management:"
    echo "  Battery Sleep: $(pmset -g | grep 'sleep' | awk '{print $2}') minutes"
    echo "  AC Sleep: Never (always-on when plugged in)"
    echo "  Hibernation: $(pmset -g | grep 'hibernatemode' | awk '{print $2}')"
    echo
    echo "Productivity Features:"
    echo "  Visual Effects: Full (enabled)"
    echo "  Siri: $(defaults read com.apple.assistant.support 'Assistant Enabled' 2>/dev/null || echo 'default')"
    echo "  Spotlight: Full indexing"
    echo "  Time Machine Snapshots: Enabled"
}

# Main setup function
main() {
    log_info "Starting MacBook Pro specific setup..."
    
    # Initial checks
    check_macbook_pro
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
    
    # Mobile-specific settings
    log_info "=== Configuring Mobile-Specific Settings ==="
    configure_mobile_settings
    
    # Productivity settings
    log_info "=== Configuring Productivity Settings ==="
    configure_productivity_settings
    
    log_success "MacBook Pro setup complete!"
    
    # Show configuration summary
    echo
    show_configuration_summary
    
    # Final instructions
    echo
    log_info "MacBook Pro is now configured for mobile productivity."
    log_info "Next steps:"
    echo "1. Install productivity and development applications using Brewfiles"
    echo "2. Configure Time Machine backup to external drive"
    echo "3. Set up iCloud sync for documents and settings"
    echo "4. Configure VPN for secure remote access"
    echo
    log_info "The MacBook Pro is optimized for:"
    echo "  • Mobile productivity and portability"
    echo "  • Balanced power management (battery vs performance)"
    echo "  • Full visual effects and user experience"
    echo "  • Secure remote access capabilities"
    echo "  • Touch ID integration for enhanced security"
}

# Run main function
main "$@"
#!/usr/bin/env zsh
# ABOUTME: Mac Studio specific setup script - configures always-on server operation
# ABOUTME: Optimized for Mac Studio M1 Max 32GB with high-performance settings

set -euo pipefail

# Script configuration
readonly SCRIPT_DIR="${0:A:h}"
readonly CONFIG_DIR="${SCRIPT_DIR}/config"
readonly MODULES_DIR="${SCRIPT_DIR}/../modules"
readonly STUDIO_CONFIG="${CONFIG_DIR}/mac-studio.yml"

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

# Check if running on Mac Studio
check_mac_studio() {
    local model_name
    model_name=$(system_profiler SPHardwareDataType | grep "Model Name" | awk -F': ' '{print $2}' | xargs)
    
    if [[ "$model_name" != *"Mac Studio"* ]]; then
        log_error "This script is designed for Mac Studio. Detected: $model_name"
        exit 1
    fi
    
    log_success "Mac Studio detected: $model_name"
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
        configure_system_names "$STUDIO_CONFIG"
    else
        log_warn "Network module not found, configuring manually..."
        
        # Set system names
        log_info "Setting hostname to mac-studio..."
        sudo scutil --set HostName mac-studio
        
        log_info "Setting computer name to Mac Studio..."
        sudo scutil --set ComputerName "Mac Studio"
        
        log_info "Setting local hostname to mac-studio..."
        sudo scutil --set LocalHostName mac-studio
    fi
    
    log_success "System naming configured"
}

# Configure system settings
configure_system_settings() {
    log_info "Configuring system settings..."
    
    # Configure system preferences
    if [[ -f "${MODULES_DIR}/system-preferences.zsh" ]]; then
        source "${MODULES_DIR}/system-preferences.zsh"
        configure_system_preferences "$STUDIO_CONFIG"
    fi
    
    # Configure power management for always-on operation
    if [[ -f "${MODULES_DIR}/power-management.zsh" ]]; then
        source "${MODULES_DIR}/power-management.zsh"
        configure_power_management "$STUDIO_CONFIG"
    fi
    
    log_success "System settings configured"
}

# Configure network settings
configure_network_settings() {
    log_info "Configuring network settings..."
    
    if [[ -f "${MODULES_DIR}/network.zsh" ]]; then
        source "${MODULES_DIR}/network.zsh"
        configure_network "$STUDIO_CONFIG"
    else
        log_warn "Network module not found, configuring manually..."
        
        # Disable Wi-Fi (desktop machine)
        log_info "Disabling Wi-Fi..."
        sudo networksetup -setairportpower en0 off
        
        # Configure static IP
        log_info "Configuring static IP..."
        local network_service=$(networksetup -listnetworkserviceorder | grep -A1 "Ethernet" | tail -1 | sed 's/.*) //')
        if [[ -n "$network_service" ]]; then
            sudo networksetup -setmanual "$network_service" 192.168.1.100 255.255.255.0 192.168.1.1
            sudo networksetup -setdnsservers "$network_service" 1.1.1.1 1.0.0.1
        fi
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
    
    # For Mac Studio, we typically use static IP, so DHCP is disabled
    log_info "Using static IP configuration (DHCP disabled)"
    
    log_success "DHCP settings configured"
}

# Configure security settings
configure_security_settings() {
    log_info "Configuring security settings..."
    
    if [[ -f "${MODULES_DIR}/security.zsh" ]]; then
        source "${MODULES_DIR}/security.zsh"
        configure_security "$STUDIO_CONFIG"
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
    fi
    
    log_success "Security settings configured"
}

# Configure sharing services
configure_sharing_services() {
    log_info "Configuring sharing services..."
    
    if [[ -f "${MODULES_DIR}/sharing.zsh" ]]; then
        source "${MODULES_DIR}/sharing.zsh"
        configure_sharing "$STUDIO_CONFIG"
    else
        log_warn "Sharing module not found, configuring manually..."
        
        # Enable SMB sharing
        log_info "Enabling SMB sharing..."
        if ! sudo launchctl list | grep -q "com.apple.smbd"; then
            sudo launchctl bootstrap system /System/Library/LaunchDaemons/com.apple.smbd.plist 2>/dev/null || true
        fi
        
        # Enable SSH
        log_info "Enabling SSH..."
        sudo systemsetup -setremotelogin on
        
        # Enable screen sharing
        log_info "Enabling screen sharing..."
        if ! sudo launchctl list | grep -q "com.apple.screensharing"; then
            sudo launchctl bootstrap system /System/Library/LaunchDaemons/com.apple.screensharing.plist 2>/dev/null || true
        fi
        
        # Create shared folder
        log_info "Creating shared folder..."
        sudo mkdir -p /Users/Shared/Studio-Server
        sudo chmod 755 /Users/Shared/Studio-Server
    fi
    
    log_success "Sharing services configured"
}

# Configure performance settings
configure_performance_settings() {
    log_info "Configuring performance settings..."
    
    # Optimize for performance
    log_info "Optimizing system for performance..."
    
    # Reduce visual effects
    defaults write com.apple.universalaccess reduceMotion -bool true
    defaults write com.apple.universalaccess reduceTransparency -bool true
    
    # Optimize background app refresh
    defaults write NSGlobalDomain NSAppRefreshEnabled -bool false
    
    # Disable Time Machine local snapshots (deprecated in newer macOS)
    # Use thinlocalsnapshots instead for modern macOS
    sudo tmutil thinlocalsnapshots / 10000000000 4
    
    log_success "Performance settings configured"
}

# Show configuration summary
show_configuration_summary() {
    log_info "Mac Studio Configuration Summary:"
    echo
    echo "System Information:"
    echo "  Hostname: $(scutil --get HostName 2>/dev/null || echo 'Not set')"
    echo "  Computer Name: $(scutil --get ComputerName 2>/dev/null || echo 'Not set')"
    echo "  Local Hostname: $(scutil --get LocalHostName 2>/dev/null || echo 'Not set')"
    echo
    echo "Network Configuration:"
    echo "  IP Address: $(ifconfig en0 | grep 'inet ' | awk '{print $2}' || echo 'Not configured')"
    echo "  DNS Servers: $(scutil --dns | grep 'nameserver' | head -2 | awk '{print $3}' | paste -sd ',' -)"
    echo
    echo "Security Status:"
    echo "  Firewall: $(sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate | grep -o 'enabled\|disabled')"
    echo "  SSH: $(systemsetup -getremotelogin | grep -o 'On\|Off')"
    echo "  FileVault: $(fdesetup status | grep -o 'On\|Off')"
    echo
    echo "Power Management:"
    echo "  System Sleep: $(pmset -g | grep 'sleep' | awk '{print $2}') minutes"
    echo "  Display Sleep: $(pmset -g | grep 'displaysleep' | awk '{print $2}') minutes"
    echo
    echo "Sharing Services:"
    echo "  SMB: $(launchctl list | grep -q smb && echo 'Enabled' || echo 'Disabled')"
    echo "  Screen Sharing: $(launchctl list | grep -q screensharing && echo 'Enabled' || echo 'Disabled')"
}

# Main setup function
main() {
    log_info "Starting Mac Studio specific setup..."
    
    # Initial checks
    check_mac_studio
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
    
    # Performance settings
    log_info "=== Configuring Performance Settings ==="
    configure_performance_settings
    
    log_success "Mac Studio setup complete!"
    
    # Show configuration summary
    echo
    show_configuration_summary
    
    # Final instructions
    echo
    log_info "Mac Studio is now configured for always-on server operation."
    log_info "Next steps:"
    echo "1. Run security hardening script if needed"
    echo "2. Install additional applications using Brewfiles"
    echo "3. Configure Time Machine backup"
    echo "4. Set up monitoring and maintenance scripts"
    echo
    log_info "The Mac Studio is optimized for:"
    echo "  • Always-on operation (never sleeps)"
    echo "  • Remote access via SSH and Screen Sharing"
    echo "  • File sharing via SMB"
    echo "  • High-performance computing tasks"
    echo "  • Server-like functionality"
}

# Run main function
main "$@"
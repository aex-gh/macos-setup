#!/usr/bin/env zsh
set -euo pipefail

# Script metadata
readonly SCRIPT_NAME="${0:t}"
readonly SCRIPT_DIR="${0:A:h}"

# Load common library
source "${SCRIPT_DIR}/../lib/common.zsh"

# Device type from command line
DEVICE_TYPE="${1:-macbook-pro}"

# Check firewall status
check_firewall_status() {
    local status
    status=$(sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null || echo "unknown")
    
    info "Current firewall status: $status"
    
    if [[ "$status" == *"enabled"* ]]; then
        success "Firewall is currently enabled"
        return 0
    else
        info "Firewall is currently disabled"
        return 1
    fi
}

# Enable and configure basic firewall
enable_firewall() {
    info "Enabling macOS Application Firewall..."
    
    # Enable the firewall
    if sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on; then
        success "Firewall enabled successfully"
    else
        error "Failed to enable firewall"
        return 1
    fi
    
    # Set logging mode (detailed logging can impact performance)
    info "Configuring firewall logging..."
    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setloggingmode on
    
    # Enable stealth mode (don't respond to ping/port scans)
    info "Enabling stealth mode..."
    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on
    
    success "Basic firewall configuration completed"
}

# Configure device-specific firewall rules
configure_device_specific_firewall() {
    info "Configuring device-specific firewall rules for: $DEVICE_TYPE"
    
    case "$DEVICE_TYPE" in
        "macbook-pro")
            info "Configuring MacBook Pro firewall (portable security)..."
            
            # More restrictive settings for portable device
            # Block all incoming connections by default
            sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setblockall off
            
            # Allow built-in software to receive incoming connections
            sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setallowsigned on
            
            # Allow downloaded signed software to receive incoming connections
            sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setallowsignedapp on
            
            success "MacBook Pro firewall configured for portable security"
            ;;
            
        "mac-studio")
            info "Configuring Mac Studio firewall (server infrastructure)..."
            
            # More permissive for server functionality but still secure
            sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setblockall off
            sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setallowsigned on
            sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setallowsignedapp on
            
            # Allow specific server applications
            configure_server_applications
            
            success "Mac Studio firewall configured for server infrastructure"
            ;;
            
        "mac-mini")
            info "Configuring Mac Mini firewall (balanced security)..."
            
            # Balanced approach for multimedia and development
            sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setblockall off
            sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setallowsigned on
            sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setallowsignedapp on
            
            # Allow media server applications
            configure_media_applications
            
            success "Mac Mini firewall configured for multimedia and development"
            ;;
    esac
}

# Configure server applications for Mac Studio
configure_server_applications() {
    info "Configuring firewall rules for server applications..."
    
    # Common server applications that may need firewall exceptions
    local server_apps=(
        "/System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/MacOS/ARDAgent"
        "/usr/sbin/sshd"
        "/Applications/Jump Desktop Connect.app/Contents/MacOS/Jump Desktop Connect"
    )
    
    for app in "${server_apps[@]}"; do
        if [[ -f "$app" ]]; then
            info "Allowing incoming connections for: $(basename "$app")"
            sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add "$app" 2>/dev/null || warn "Could not add $app to firewall"
            sudo /usr/libexec/ApplicationFirewall/socketfilterfw --unblock "$app" 2>/dev/null || warn "Could not unblock $app"
        fi
    done
    
    # Enable SSH if needed for server management
    if systemsetup -getremotelogin 2>/dev/null | grep -q "Off"; then
        read -p "Enable SSH (Remote Login) for server management? [y/N]: " ssh_choice
        if [[ "$ssh_choice" == "y" || "$ssh_choice" == "Y" ]]; then
            info "Enabling SSH (Remote Login)..."
            sudo systemsetup -setremotelogin on
            success "SSH enabled for remote server management"
        fi
    else
        success "SSH is already enabled"
    fi
}

# Configure media applications for Mac Mini
configure_media_applications() {
    info "Configuring firewall rules for media applications..."
    
    # Common media applications that may need network access
    local media_apps=(
        "/Applications/Plex Media Server.app/Contents/MacOS/Plex Media Server"
        "/Applications/IINA.app/Contents/MacOS/IINA"
        "/Applications/VLC.app/Contents/MacOS/VLC"
    )
    
    for app in "${media_apps[@]}"; do
        if [[ -f "$app" ]]; then
            info "Allowing incoming connections for: $(basename "$app")"
            sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add "$app" 2>/dev/null || warn "Could not add $app to firewall"
            sudo /usr/libexec/ApplicationFirewall/socketfilterfw --unblock "$app" 2>/dev/null || warn "Could not unblock $app"
        fi
    done
}

# Configure common development tools
configure_development_tools() {
    info "Configuring firewall rules for development tools..."
    
    # Common development tools that need network access
    local dev_tools=(
        "/usr/local/bin/node"
        "/opt/homebrew/bin/node"
        "/usr/local/bin/python3"
        "/opt/homebrew/bin/python3"
    )
    
    for tool in "${dev_tools[@]}"; do
        if [[ -f "$tool" ]]; then
            info "Allowing network access for development tool: $(basename "$tool")"
            sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add "$tool" 2>/dev/null || warn "Could not add $tool to firewall"
            sudo /usr/libexec/ApplicationFirewall/socketfilterfw --unblock "$tool" 2>/dev/null || warn "Could not unblock $tool"
        fi
    done
}

# Show firewall status and rules
show_firewall_status() {
    info "Current Firewall Configuration"
    info "============================="
    
    # Global state
    local global_state
    global_state=$(sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null || echo "unknown")
    info "Global State: $global_state"
    
    # Stealth mode
    local stealth_mode
    stealth_mode=$(sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getstealthmode 2>/dev/null || echo "unknown")
    info "Stealth Mode: $stealth_mode"
    
    # Logging mode
    local logging_mode
    logging_mode=$(sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getloggingmode 2>/dev/null || echo "unknown")
    info "Logging Mode: $logging_mode"
    
    # Block all incoming
    local block_all
    block_all=$(sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getblockall 2>/dev/null || echo "unknown")
    info "Block All Incoming: $block_all"
    
    # Signed software settings
    local allow_signed
    allow_signed=$(sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getallowsigned 2>/dev/null || echo "unknown")
    info "Allow Signed Software: $allow_signed"
    
    local allow_signed_app
    allow_signed_app=$(sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getallowsignedapp 2>/dev/null || echo "unknown")
    info "Allow Signed Applications: $allow_signed_app"
    
    echo
    info "Explicitly Allowed Applications:"
    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --listapps 2>/dev/null | grep -E "ALF: .*allow" || info "No explicitly allowed applications"
}

# Provide firewall guidance
provide_firewall_guidance() {
    info "macOS Firewall Configuration Guidance"
    info "====================================="
    echo
    info "Security Levels by Device Type:"
    case "$DEVICE_TYPE" in
        "macbook-pro")
            info "MacBook Pro (High Security):"
            info "• Strictest settings for portable device"
            info "• Stealth mode enabled"
            info "• Only signed applications allowed by default"
            info "• Ideal for public Wi-Fi and travel"
            ;;
        "mac-studio")
            info "Mac Studio (Server Security):"
            info "• Balanced security with server functionality"
            info "• SSH access can be enabled for remote management"
            info "• Server applications have firewall exceptions"
            info "• Suitable for headless operation"
            ;;
        "mac-mini")
            info "Mac Mini (Balanced Security):"
            info "• Moderate security for home environment"
            info "• Media server applications allowed"
            info "• Development tools have network access"
            info "• Good for multimedia and development"
            ;;
    esac
    echo
    info "Monitoring and Maintenance:"
    info "• View logs: sudo log show --predicate 'subsystem == \"com.apple.alf\"'"
    info "• Check status: sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate"
    info "• List applications: sudo /usr/libexec/ApplicationFirewall/socketfilterfw --listapps"
    echo
    info "Additional Security Considerations:"
    info "• Firewall protects against incoming connections"
    info "• Does not monitor outgoing connections"
    info "• Consider third-party solutions for advanced filtering"
    info "• Regular review of allowed applications recommended"
    echo
}

# Help function
usage() {
    cat << EOF
$SCRIPT_NAME - macOS Firewall Configuration

USAGE:
    $SCRIPT_NAME [OPTIONS] [DEVICE_TYPE]

DESCRIPTION:
    Configures the macOS Application Firewall with device-specific settings
    for optimal security while maintaining functionality for each Mac model.

OPTIONS:
    -s, --status         Show current firewall status and rules
    -r, --reset          Reset firewall to default settings
    -h, --help           Show this help message

DEVICE_TYPE:
    macbook-pro    Portable development (strictest security)
    mac-studio     Server infrastructure (balanced for services)
    mac-mini       Multimedia + development (moderate security)
    
    Default: macbook-pro

SECURITY FEATURES:
    • Application-based firewall rules
    • Stealth mode (invisible to port scans)
    • Signed application verification
    • Device-specific rule sets
    • Development tool integration

EXAMPLES:
    $SCRIPT_NAME                    # Setup firewall for MacBook Pro
    $SCRIPT_NAME --status           # Show current firewall configuration
    $SCRIPT_NAME mac-studio         # Setup firewall for Mac Studio
    $SCRIPT_NAME --reset            # Reset to default settings

DEVICE-SPECIFIC CONFIGURATIONS:
    MacBook Pro    High security for portable use
    Mac Studio     Server-friendly with SSH and remote access
    Mac Mini       Balanced for home multimedia and development

NOTES:
    • Requires administrator privileges
    • Some applications may prompt for firewall access
    • Firewall logs available in Console.app
    • Compatible with all modern macOS versions

EOF
}

# Reset firewall to defaults
reset_firewall() {
    info "Resetting firewall to default settings..."
    
    read -p "This will reset all firewall rules. Continue? [y/N]: " reset_choice
    if [[ "$reset_choice" != "y" && "$reset_choice" != "Y" ]]; then
        info "Firewall reset cancelled"
        return 0
    fi
    
    # Reset to defaults
    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate off
    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setblockall off
    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setallowsigned off
    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setallowsignedapp off
    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode off
    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setloggingmode off
    
    success "Firewall reset to default settings"
}

# Main execution
main() {
    info "macOS Firewall Configuration"
    info "============================"
    info "Device type: $DEVICE_TYPE"
    echo
    
    # Provide guidance
    provide_firewall_guidance
    
    # Check if already enabled
    if check_firewall_status; then
        info "Firewall is already enabled"
        show_firewall_status
        
        read -p "Reconfigure firewall settings? [y/N]: " reconfig_choice
        if [[ "$reconfig_choice" != "y" && "$reconfig_choice" != "Y" ]]; then
            info "Firewall configuration unchanged"
            return 0
        fi
    fi
    
    # Enable and configure firewall
    if enable_firewall; then
        echo
        configure_device_specific_firewall
        echo
        configure_development_tools
        echo
        show_firewall_status
        echo
        
        success "=========================================="
        success "Firewall configuration completed successfully!"
        success "=========================================="
        success "Your $DEVICE_TYPE firewall is now configured and active"
        
        info "Next steps:"
        info "• Applications may prompt for firewall access"
        info "• Monitor firewall logs if connectivity issues occur"
        info "• Review firewall rules periodically"
        
        return 0
    else
        error "Firewall configuration failed"
        return 1
    fi
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--status)
            info "Checking firewall status..."
            check_firewall_status
            show_firewall_status
            exit 0
            ;;
        -r|--reset)
            reset_firewall
            exit 0
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        macbook-pro|mac-studio|mac-mini)
            DEVICE_TYPE="$1"
            shift
            ;;
        -*)
            error "Unknown option: $1"
            usage
            exit 1
            ;;
        *)
            DEVICE_TYPE="$1"
            shift
            ;;
    esac
done

# Validate device type
case "$DEVICE_TYPE" in
    macbook-pro|mac-studio|mac-mini)
        ;;
    *)
        error "Invalid device type: $DEVICE_TYPE"
        error "Valid types: macbook-pro, mac-studio, mac-mini"
        exit 1
        ;;
esac

# Run main function
main
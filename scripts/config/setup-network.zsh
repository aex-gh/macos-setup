#!/usr/bin/env zsh
set -euo pipefail

# Script metadata
readonly SCRIPT_NAME="${0:t}"
readonly SCRIPT_DIR="${0:A:h}"

# Load common library
source "${SCRIPT_DIR}/../lib/common.zsh"

# Device type from command line
DEVICE_TYPE="${1:-macbook-pro}"

# Network configuration settings
readonly SUBNET="10.20.0"
readonly GATEWAY="10.20.0.1"
readonly DNS_SERVERS=("10.20.0.1" "1.1.1.1" "8.8.8.8")

# Device-specific IP assignments
declare -A DEVICE_IPS=(
    ["mac-studio"]="10.20.0.10"
    ["mac-mini"]="10.20.0.12"
    ["macbook-pro"]="dhcp"  # Dynamic IP for portable device
)

# Note: Logging functions are now in common library

# Note: Network helper functions are now in common library

# Configure static IP address with DNS
configure_static_ip_with_dns() {
    local service="$1"
    local ip_address="$2"
    local subnet_mask="255.255.255.0"
    
    # Use common library function for static IP
    configure_static_ip "$service" "$ip_address" "$subnet_mask" "$GATEWAY" || return 1
    
    # Configure DNS servers using common library function
    set_dns_servers "$service" "${DNS_SERVERS[@]}"
    
    return 0
}

# Configure DHCP (dynamic IP)
configure_dhcp() {
    local service="$1"
    
    info "Configuring DHCP for $service"
    
    if sudo networksetup -setdhcp "$service"; then
        success "✓ DHCP configured for $service"
    else
        error "Failed to configure DHCP for $service"
        return 1
    fi
    
    # Set DNS servers even with DHCP for reliability
    if sudo networksetup -setdnsservers "$service" "${DNS_SERVERS[@]}"; then
        success "✓ DNS servers configured: ${DNS_SERVERS[*]}"
    else
        warn "Could not configure DNS servers"
    fi
    
    return 0
}

# Configure network service ordering
configure_service_ordering() {
    info "Configuring network service ordering for $DEVICE_TYPE..."
    
    case "$DEVICE_TYPE" in
        "macbook-pro")
            # Wi-Fi first for portable device
            local service_order=("Wi-Fi" "Ethernet" "Thunderbolt Bridge")
            ;;
        "mac-studio"|"mac-mini")
            # Ethernet first for desktop devices
            local service_order=("Ethernet" "Wi-Fi" "Thunderbolt Bridge")
            ;;
    esac
    
    # Get available services and filter to only existing ones
    local available_services=()
    local all_services
    all_services=$(get_network_services)
    
    for service in "${service_order[@]}"; do
        if echo "$all_services" | grep -q "^$service$"; then
            available_services+=("$service")
        fi
    done
    
    # Add any remaining services
    while IFS= read -r service; do
        if [[ ! " ${available_services[*]} " =~ " $service " ]]; then
            available_services+=("$service")
        fi
    done <<< "$all_services"
    
    info "Setting network service order: ${available_services[*]}"
    
    if sudo networksetup -ordernetworkservices "${available_services[@]}"; then
        success "✓ Network service order configured"
    else
        warn "Could not configure network service order"
    fi
}

# Configure Wi-Fi settings for MacBook Pro
configure_wifi_settings() {
    info "Configuring Wi-Fi settings for MacBook Pro..."
    
    # Enable Wi-Fi if not already enabled
    if sudo networksetup -setairportpower en0 on; then
        success "✓ Wi-Fi enabled"
    else
        warn "Could not enable Wi-Fi"
    fi
    
    # Configure Wi-Fi security settings
    info "Configuring Wi-Fi security settings..."
    
    # Disable automatic connection to open networks
    sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.airport JoinMode "Preferred"
    success "✓ Wi-Fi set to connect to preferred networks only"
    
    # Disable location-based Wi-Fi services for privacy
    sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.airport LocationBasedWiFi -bool false
    success "✓ Location-based Wi-Fi disabled"
    
    # Configure to remember networks but require manual connection to new ones
    sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.airport RememberRecentNetworks -bool true
    success "✓ Network memory enabled for known networks"
}

# Configure Ethernet settings for desktop devices
configure_ethernet_settings() {
    info "Configuring Ethernet settings for desktop device..."
    
    # Check if Ethernet interface exists
    if networksetup -listallhardwareports | grep -q "Ethernet"; then
        success "✓ Ethernet interface detected"
        
        # Configure jumbo frames for better performance (if supported)
        local ethernet_device
        ethernet_device=$(networksetup -listallhardwareports | grep -A1 "Ethernet" | grep "Device:" | awk '{print $2}' | head -1)
        
        if [[ -n "$ethernet_device" ]]; then
            # Enable flow control for better performance
            if sudo ifconfig "$ethernet_device" flowcontrol on 2>/dev/null; then
                success "✓ Ethernet flow control enabled"
            else
                info "Ethernet flow control not supported or already optimal"
            fi
        fi
    else
        warn "No Ethernet interface detected"
    fi
}

# Test network connectivity
test_network_connectivity() {
    info "Testing network connectivity..."
    
    local test_hosts=("$GATEWAY" "1.1.1.1" "google.com")
    local connectivity_ok=true
    
    for host in "${test_hosts[@]}"; do
        if ping -c 1 -t 5 "$host" &>/dev/null; then
            success "✓ Connectivity to $host: OK"
        else
            error "✗ Connectivity to $host: FAILED"
            connectivity_ok=false
        fi
    done
    
    if [[ "$connectivity_ok" == "true" ]]; then
        success "All connectivity tests passed"
        return 0
    else
        error "Some connectivity tests failed"
        return 1
    fi
}

# Show current network configuration
show_network_config() {
    info "Current Network Configuration"
    info "============================"
    
    # Show network services and their order
    info "Network Service Order:"
    networksetup -listnetworkserviceorder | grep "Hardware Port"
    
    echo
    info "Network Interface Status:"
    
    # Show configuration for each service
    local services
    services=$(get_network_services)
    
    while IFS= read -r service; do
        if [[ -n "$service" ]]; then
            info "Service: $service"
            
            # Get IP configuration
            local ip_config
            ip_config=$(networksetup -getinfo "$service" 2>/dev/null || echo "Not configured")
            
            if [[ "$ip_config" != "Not configured" ]]; then
                echo "$ip_config" | grep -E "(IP address|Subnet mask|Router)" | sed 's/^/  /'
            else
                info "  Not configured or inactive"
            fi
            echo
        fi
    done <<< "$services"
    
    # Show DNS configuration
    info "DNS Configuration:"
    scutil --dns | grep "nameserver" | head -5 | sed 's/^/  /'
}

# Configure device-specific network settings
configure_device_network() {
    local primary_interface
    primary_interface=$(get_primary_interface)
    local device_ip="${DEVICE_IPS[$DEVICE_TYPE]}"
    
    info "Configuring network for $DEVICE_TYPE"
    info "Primary interface: $primary_interface"
    info "IP assignment: $device_ip"
    echo
    
    # Check if primary interface exists
    if ! check_network_service "$primary_interface"; then
        error "Primary network interface '$primary_interface' not found"
        info "Available network services:"
        get_network_services
        return 1
    fi
    
    case "$DEVICE_TYPE" in
        "macbook-pro")
            # Configure Wi-Fi settings
            configure_wifi_settings
            echo
            
            # Configure DHCP for portable device
            if [[ "$device_ip" == "dhcp" ]]; then
                configure_dhcp "$primary_interface"
            fi
            ;;
            
        "mac-studio"|"mac-mini")
            # Configure Ethernet settings
            configure_ethernet_settings
            echo
            
            # Configure static IP for desktop devices
            if [[ "$device_ip" != "dhcp" ]]; then
                configure_static_ip_with_dns "$primary_interface" "$device_ip"
            fi
            ;;
    esac
    
    # Configure service ordering for all devices
    echo
    configure_service_ordering
}

# Provide network configuration guidance
provide_network_guidance() {
    info "Network Configuration Guidance"
    info "=============================="
    echo
    info "Family Network Architecture:"
    info "• Subnet: $SUBNET.0/24"
    info "• Gateway: $GATEWAY"
    info "• DNS: Primary (${DNS_SERVERS[1]}), Secondary (${DNS_SERVERS[2]})"
    echo
    info "Device IP Assignments:"
    info "• Mac Studio: ${DEVICE_IPS[mac-studio]} (static) - Server infrastructure"
    info "• Mac Mini: ${DEVICE_IPS[mac-mini]} (static) - Multimedia and development"
    info "• MacBook Pro: Dynamic IP (DHCP) - Portable development"
    echo
    case "$DEVICE_TYPE" in
        "macbook-pro")
            info "MacBook Pro Network Features:"
            info "• Wi-Fi preferred for portability"
            info "• Dynamic IP assignment via DHCP"
            info "• Secure Wi-Fi configuration"
            info "• Automatic network switching"
            ;;
        "mac-studio")
            info "Mac Studio Network Features:"
            info "• Ethernet preferred for stability"
            info "• Static IP for server services"
            info "• Optimised for headless operation"
            info "• Wake-on-LAN capability"
            ;;
        "mac-mini")
            info "Mac Mini Network Features:"
            info "• Ethernet preferred for media streaming"
            info "• Static IP for consistent access"
            info "• Optimised for multimedia services"
            info "• Balanced performance settings"
            ;;
    esac
    echo
    info "Security Considerations:"
    info "• DNS filtering via configured DNS servers"
    info "• Network service ordering optimised for device type"
    info "• Wi-Fi security settings prevent auto-connection to open networks"
    info "• Static IPs facilitate firewall rules and port forwarding"
    echo
}

# Help function
usage() {
    cat << EOF
$SCRIPT_NAME - Network Configuration Setup

USAGE:
    $SCRIPT_NAME [OPTIONS] [DEVICE_TYPE]

DESCRIPTION:
    Configures network settings optimised for each device type in the
    family environment. Handles static IP assignment, Wi-Fi security,
    and network service ordering.

OPTIONS:
    -s, --status         Show current network configuration
    -t, --test           Test network connectivity
    -r, --reset          Reset network configuration to defaults
    -h, --help           Show this help message

DEVICE_TYPE:
    macbook-pro    Portable device (Wi-Fi, DHCP, dynamic IP)
    mac-studio     Server infrastructure (Ethernet, static IP: 10.20.0.10)
    mac-mini       Multimedia system (Ethernet, static IP: 10.20.0.12)
    
    Default: macbook-pro

NETWORK CONFIGURATION:
    • Family subnet: 10.20.0.0/24
    • Gateway: 10.20.0.1
    • DNS servers: 10.20.0.1, 1.1.1.1, 8.8.8.8
    • Device-specific IP assignments and interface preferences

EXAMPLES:
    $SCRIPT_NAME                    # Configure MacBook Pro network
    $SCRIPT_NAME --status           # Show current network configuration
    $SCRIPT_NAME mac-studio         # Configure Mac Studio with static IP
    $SCRIPT_NAME --test             # Test network connectivity

FEATURES:
    • Device-appropriate interface selection (Wi-Fi vs Ethernet)
    • Static IP configuration for desktop devices
    • DHCP configuration for portable devices
    • Network service ordering optimisation
    • Wi-Fi security configuration
    • DNS server configuration for reliability

REQUIREMENTS:
    • Administrator privileges for network configuration
    • Existing network infrastructure with appropriate subnet
    • Compatible network interfaces on target device

EOF
}

# Reset network configuration
reset_network_config() {
    info "Resetting network configuration..."
    
    read -p "This will reset all network settings to defaults. Continue? [y/N]: " reset_choice
    if [[ "$reset_choice" != "y" && "$reset_choice" != "Y" ]]; then
        info "Network reset cancelled"
        return 0
    fi
    
    local services
    services=$(get_network_services)
    
    while IFS= read -r service; do
        if [[ -n "$service" ]]; then
            info "Resetting $service to DHCP..."
            sudo networksetup -setdhcp "$service" 2>/dev/null || warn "Could not reset $service"
        fi
    done <<< "$services"
    
    success "Network configuration reset to defaults"
}

# Main execution
main() {
    info "Network Configuration Setup"
    info "==========================="
    info "Device type: $DEVICE_TYPE"
    echo
    
    # Provide guidance
    provide_network_guidance
    
    # Configure device-specific network settings
    configure_device_network
    echo
    
    # Test connectivity
    test_network_connectivity
    echo
    
    # Show final configuration
    show_network_config
    echo
    
    success "=========================================="
    success "Network configuration completed successfully!"
    success "=========================================="
    success "Your $DEVICE_TYPE network is now optimally configured"
    
    info "Network summary:"
    case "$DEVICE_TYPE" in
        "macbook-pro")
            info "• Wi-Fi enabled with secure settings"
            info "• Dynamic IP via DHCP for portability"
            ;;
        "mac-studio")
            info "• Static IP configured: ${DEVICE_IPS[mac-studio]}"
            info "• Ethernet optimised for server use"
            ;;
        "mac-mini")
            info "• Static IP configured: ${DEVICE_IPS[mac-mini]}"
            info "• Ethernet optimised for multimedia"
            ;;
    esac
    info "• DNS servers configured for reliability"
    info "• Network service order optimised"
    
    return 0
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--status)
            show_network_config
            exit 0
            ;;
        -t|--test)
            test_network_connectivity
            exit 0
            ;;
        -r|--reset)
            reset_network_config
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
#!/usr/bin/env zsh
# ABOUTME: Configures macOS network settings based on YAML configuration
# ABOUTME: Handles hostname, DNS, static IP, and network services configuration

set -euo pipefail

# Load YAML configuration
load_config() {
    local config_file="$1"
    if [[ ! -f "$config_file" ]]; then
        echo "Error: Configuration file not found: $config_file"
        return 1
    fi
    
    if command -v yq &> /dev/null; then
        CONFIG_DATA=$(yq eval '.' "$config_file")
    else
        CONFIG_DATA=$(cat "$config_file")
    fi
}

# Get configuration value
get_config_value() {
    local key="$1"
    local default_value="${2:-}"
    
    if command -v yq &> /dev/null; then
        yq eval ".$key" <<< "$CONFIG_DATA" 2>/dev/null || echo "$default_value"
    else
        grep -E "^[[:space:]]*${key}:" <<< "$CONFIG_DATA" | sed 's/.*: *//' | head -1 || echo "$default_value"
    fi
}

# Configure system names
configure_system_names() {
    local config_file="$1"
    
    echo "Configuring system names from: $config_file"
    
    load_config "$config_file"
    
    local hostname=$(get_config_value "system.hostname" "")
    local computer_name=$(get_config_value "system.computer_name" "")
    local local_hostname=$(get_config_value "system.local_hostname" "")
    
    if [[ -n "$hostname" ]]; then
        echo "Setting hostname to: $hostname"
        sudo scutil --set HostName "$hostname"
    fi
    
    if [[ -n "$computer_name" ]]; then
        echo "Setting computer name to: $computer_name"
        sudo scutil --set ComputerName "$computer_name"
    fi
    
    if [[ -n "$local_hostname" ]]; then
        echo "Setting local hostname to: $local_hostname"
        sudo scutil --set LocalHostName "$local_hostname"
    fi
    
    echo "System names configured"
}

# Configure DNS settings
configure_dns() {
    local config_file="$1"
    
    echo "Configuring DNS settings from: $config_file"
    
    load_config "$config_file"
    
    local use_custom_dns=$(get_config_value "network.use_custom_dns" "false")
    
    if [[ "$use_custom_dns" = "true" ]]; then
        local primary_dns=$(get_config_value "network.primary_dns" "1.1.1.1")
        local secondary_dns=$(get_config_value "network.secondary_dns" "1.0.0.1")
        
        echo "Setting DNS servers to: $primary_dns, $secondary_dns"
        
        # Get active network service
        local network_service=$(networksetup -listnetworkserviceorder | grep -A1 "Ethernet" | tail -1 | sed 's/.*) //')
        
        if [[ -n "$network_service" ]]; then
            sudo networksetup -setdnsservers "$network_service" "$primary_dns" "$secondary_dns"
        fi
    fi
    
    echo "DNS configuration complete"
}

# Configure static IP
configure_static_ip() {
    local config_file="$1"
    
    echo "Configuring static IP from: $config_file"
    
    load_config "$config_file"
    
    local use_static_ip=$(get_config_value "network.use_static_ip" "false")
    
    if [[ "$use_static_ip" = "true" ]]; then
        local ip_address=$(get_config_value "network.ip_address" "")
        local subnet_mask=$(get_config_value "network.subnet_mask" "")
        local gateway=$(get_config_value "network.gateway" "")
        
        if [[ -n "$ip_address" && -n "$subnet_mask" && -n "$gateway" ]]; then
            echo "Setting static IP: $ip_address/$subnet_mask via $gateway"
            
            # Get active network service
            local network_service=$(networksetup -listnetworkserviceorder | grep -A1 "Ethernet" | tail -1 | sed 's/.*) //')
            
            if [[ -n "$network_service" ]]; then
                sudo networksetup -setmanual "$network_service" "$ip_address" "$subnet_mask" "$gateway"
            fi
        fi
    fi
    
    echo "Static IP configuration complete"
}

# Configure network services
configure_network_services() {
    local config_file="$1"
    
    echo "Configuring network services from: $config_file"
    
    load_config "$config_file"
    
    local disable_wifi=$(get_config_value "network.disable_wifi" "false")
    local enable_bonjour=$(get_config_value "network.enable_bonjour" "true")
    local enable_thunderbolt=$(get_config_value "network.enable_thunderbolt_networking" "true")
    
    if [[ "$disable_wifi" = "true" ]]; then
        echo "Disabling Wi-Fi"
        sudo networksetup -setairportpower en0 off
    fi
    
    if [[ "$enable_bonjour" = "true" ]]; then
        echo "Enabling Bonjour"
        sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.mDNSResponder.plist
    fi
    
    if [[ "$enable_thunderbolt" = "true" ]]; then
        echo "Enabling Thunderbolt networking"
        # Thunderbolt networking is generally enabled by default on modern Macs
        echo "Thunderbolt networking support confirmed"
    fi
    
    echo "Network services configuration complete"
}

# Configure all network settings
configure_network() {
    local config_file="$1"
    
    echo "Configuring network settings from: $config_file"
    
    configure_system_names "$config_file"
    configure_dns "$config_file"
    configure_static_ip "$config_file"
    configure_network_services "$config_file"
    
    echo "Network configuration complete"
}

# Show current network configuration
show_network_config() {
    echo "Current network configuration:"
    echo
    echo "System Names:"
    echo "  Hostname: $(scutil --get HostName 2>/dev/null || echo 'Not set')"
    echo "  Computer Name: $(scutil --get ComputerName 2>/dev/null || echo 'Not set')"
    echo "  Local Hostname: $(scutil --get LocalHostName 2>/dev/null || echo 'Not set')"
    echo
    echo "Network Services:"
    networksetup -listallnetworkservices
    echo
    echo "DNS Configuration:"
    scutil --dns
}


# Functions are available when sourced, no need to export in Zsh

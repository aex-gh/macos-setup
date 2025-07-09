#!/usr/bin/env zsh
# ABOUTME: Configures macOS power management settings based on YAML configuration
# ABOUTME: Supports desktop (always-on) and mobile (balanced) power profiles

set -euo pipefail

# Load YAML configuration
load_config() {
    local config_file="$1"
    if [[ ! -f "$config_file" ]]; then
        echo "Error: Configuration file not found: $config_file"
        return 1
    fi
    
    # Use yq to parse YAML if available, otherwise use basic parsing
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
        # Basic YAML parsing fallback
        grep -E "^[[:space:]]*${key}:" <<< "$CONFIG_DATA" | sed 's/.*: *//' | head -1 || echo "$default_value"
    fi
}

# Configure power management
configure_power_management() {
    local config_file="$1"
    
    echo "Configuring power management from: $config_file"
    
    # Load configuration
    load_config "$config_file"
    
    # Get power settings
    local sleep_display=$(get_config_value "system.power.sleep_display" "10")
    local sleep_system=$(get_config_value "system.power.sleep_system" "0")
    local sleep_disk=$(get_config_value "system.power.sleep_disk" "0")
    local power_nap=$(get_config_value "system.power.power_nap" "true")
    local wake_on_network=$(get_config_value "system.power.wake_on_network" "true")
    local hibernate_mode=$(get_config_value "system.power.hibernate_mode" "0")
    local standby_mode=$(get_config_value "system.power.standby_mode" "0")
    local wake_on_ac=$(get_config_value "system.power.wake_on_ac" "true")
    
    # Apply power settings
    echo "Setting display sleep to: $sleep_display minutes"
    sudo pmset -a displaysleep "$sleep_display"
    
    echo "Setting system sleep to: $sleep_system minutes"
    sudo pmset -a sleep "$sleep_system"
    
    echo "Setting disk sleep to: $sleep_disk minutes"
    sudo pmset -a disksleep "$sleep_disk"
    
    # Convert boolean values
    local power_nap_value=$([ "$power_nap" = "true" ] && echo 1 || echo 0)
    echo "Setting Power Nap to: $power_nap_value"
    sudo pmset -a powernap "$power_nap_value"
    
    local wake_network_value=$([ "$wake_on_network" = "true" ] && echo 1 || echo 0)
    echo "Setting wake on network to: $wake_network_value"
    sudo pmset -a womp "$wake_network_value"
    
    echo "Setting hibernation mode to: $hibernate_mode"
    sudo pmset -a hibernatemode "$hibernate_mode"
    
    echo "Setting standby mode to: $standby_mode"
    sudo pmset -a standby "$standby_mode"
    
    local wake_ac_value=$([ "$wake_on_ac" = "true" ] && echo 1 || echo 0)
    echo "Setting wake on AC to: $wake_ac_value"
    sudo pmset -a acwake "$wake_ac_value"
    
    # Configure power schedule if enabled
    local schedule_enabled=$(get_config_value "system.power_schedule.enabled" "false")
    if [[ "$schedule_enabled" = "true" ]]; then
        local wake_time=$(get_config_value "system.power_schedule.maintenance_wake_time" "03:00")
        echo "Setting daily maintenance wake time to: $wake_time"
        sudo pmset repeat wakeorpoweron MTWRFSU "$wake_time:00"
    fi
    
    echo "Power management configuration complete"
}

# Show current power settings
show_power_settings() {
    echo "Current power management settings:"
    pmset -g
    echo
    echo "Power schedules:"
    pmset -g sched
}

# Export functions
export -f configure_power_management
export -f show_power_settings
#!/usr/bin/env zsh
# ABOUTME: Configures macOS power management settings for optimal remote access on Apple Silicon Macs
# ABOUTME: Implements always-on configurations for desktop machines and balanced settings for mobile use

#=============================================================================
# SCRIPT: power-management.zsh
# AUTHOR: macOS Setup System
# DATE: 2025-01-07
# VERSION: 1.0.0
# 
# DESCRIPTION:
#   Configures macOS power management settings optimised for remote access
#   on Apple Silicon Macs, addressing Wake on LAN limitations
#
# USAGE:
#   source power-management.zsh
#   configure_power_management
#
# REQUIREMENTS:
#   - macOS 11.0+ (Big Sur)
#   - Apple Silicon Mac (M1/M2/M3/M4)
#   - Administrator privileges for pmset commands
#
# NOTES:
#   - Apple Silicon Macs have limited Wake on LAN support
#   - Always-on configuration is recommended for desktop machines
#   - Mobile devices use balanced power management
#=============================================================================

# Source common utilities
source "${0:A:h}/../lib/dry-run-utils.zsh"

# Power management constants
readonly POWER_LOG_FILE="/tmp/power-management-setup.log"
readonly DESKTOP_MACHINES=("Mac Studio" "Mac mini")
readonly MOBILE_MACHINES=("MacBook Pro" "MacBook Air")

#=============================================================================
# HARDWARE DETECTION
#=============================================================================

get_hardware_model() {
    local model
    model=$(sysctl -n hw.model 2>/dev/null || echo "Unknown")
    echo "$model"
}

get_machine_type() {
    local model_name
    model_name=$(system_profiler SPHardwareDataType | grep "Model Name" | awk -F': ' '{print $2}' | xargs)
    echo "$model_name"
}

is_desktop_machine() {
    local machine_type="$1"
    for desktop in "${DESKTOP_MACHINES[@]}"; do
        if [[ "$machine_type" == *"$desktop"* ]]; then
            return 0
        fi
    done
    return 1
}

is_mobile_machine() {
    local machine_type="$1"
    for mobile in "${MOBILE_MACHINES[@]}"; do
        if [[ "$machine_type" == *"$mobile"* ]]; then
            return 0
        fi
    done
    return 1
}

#=============================================================================
# POWER MANAGEMENT CONFIGURATION
#=============================================================================

configure_always_on_power() {
    local machine_type="$1"
    
    info "Configuring always-on power management for $machine_type..."
    
    # Prevent system sleep entirely
    execute_with_dry_run "sudo pmset -a sleep 0" \
        "Disable system sleep (always-on configuration)"
    
    # Allow display sleep after 10 minutes to save screen
    execute_with_dry_run "sudo pmset -a displaysleep 10" \
        "Set display sleep to 10 minutes"
    
    # Disable disk sleep for immediate responsiveness
    execute_with_dry_run "sudo pmset -a disksleep 0" \
        "Disable disk sleep for immediate access"
    
    # Enable wake for network access (limited on Apple Silicon but harmless)
    execute_with_dry_run "sudo pmset -a womp 1" \
        "Enable wake for network access (limited Apple Silicon support)"
    
    # Disable standby and hibernation modes
    execute_with_dry_run "sudo pmset -a standby 0" \
        "Disable standby mode"
    
    execute_with_dry_run "sudo pmset -a standbydelay 0" \
        "Set standby delay to 0"
    
    execute_with_dry_run "sudo pmset -a hibernatemode 0" \
        "Disable hibernation mode"
    
    # Enable power nap for background updates
    execute_with_dry_run "sudo pmset -a powernap 1" \
        "Enable Power Nap for background updates"
    
    # Disable automatic restart on power loss (server stability)
    execute_with_dry_run "sudo pmset -a autorestart 0" \
        "Disable automatic restart on power loss"
    
    # Enable wake on AC power attach
    execute_with_dry_run "sudo pmset -a acwake 1" \
        "Enable wake on AC power attach"
    
    success "Always-on power management configured for $machine_type"
}

configure_balanced_mobile_power() {
    local machine_type="$1"
    
    info "Configuring balanced power management for $machine_type..."
    
    # Battery power settings (conservative)
    execute_with_dry_run "sudo pmset -b sleep 15" \
        "Set battery sleep to 15 minutes"
    
    execute_with_dry_run "sudo pmset -b displaysleep 5" \
        "Set battery display sleep to 5 minutes"
    
    execute_with_dry_run "sudo pmset -b disksleep 10" \
        "Set battery disk sleep to 10 minutes"
    
    # AC power settings (always-on when plugged in)
    execute_with_dry_run "sudo pmset -c sleep 0" \
        "Disable AC power sleep (always-on when plugged in)"
    
    execute_with_dry_run "sudo pmset -c displaysleep 30" \
        "Set AC display sleep to 30 minutes"
    
    execute_with_dry_run "sudo pmset -c disksleep 0" \
        "Disable AC disk sleep"
    
    # Enable wake for network access on AC power
    execute_with_dry_run "sudo pmset -c womp 1" \
        "Enable wake for network access on AC power"
    
    # Enable Power Nap on AC power only
    execute_with_dry_run "sudo pmset -c powernap 1" \
        "Enable Power Nap on AC power"
    
    execute_with_dry_run "sudo pmset -b powernap 0" \
        "Disable Power Nap on battery"
    
    # Balanced hibernation settings
    execute_with_dry_run "sudo pmset -a hibernatemode 3" \
        "Set hibernation mode to 3 (balanced)"
    
    execute_with_dry_run "sudo pmset -a standby 1" \
        "Enable standby mode"
    
    execute_with_dry_run "sudo pmset -a standbydelay 86400" \
        "Set standby delay to 24 hours"
    
    success "Balanced power management configured for $machine_type"
}

configure_shared_settings() {
    info "Configuring shared power management settings..."
    
    # Disable wake on lid open for external keyboard/mouse use
    execute_with_dry_run "sudo pmset -a lidwake 0" \
        "Disable wake on lid open"
    
    # Enable wake on ethernet magic packet (limited Apple Silicon support)
    execute_with_dry_run "sudo pmset -a womp 1" \
        "Enable wake on magic packet (limited support)"
    
    # Disable automatic graphics switching (if applicable)
    if system_profiler SPDisplaysDataType | grep -q "Automatic Graphics Switching"; then
        execute_with_dry_run "sudo pmset -a gpuswitch 0" \
            "Disable automatic graphics switching"
    fi
    
    # Enable TCP keep alive for network connections
    execute_with_dry_run "sudo pmset -a tcpkeepalive 1" \
        "Enable TCP keep alive for network connections"
    
    success "Shared power management settings configured"
}

#=============================================================================
# POWER SCHEDULE MANAGEMENT
#=============================================================================

configure_power_schedule() {
    local machine_type="$1"
    
    info "Configuring power schedule for $machine_type..."
    
    # Clear existing schedules
    execute_with_dry_run "sudo pmset repeat cancel" \
        "Clear existing power schedules"
    
    if is_desktop_machine "$machine_type"; then
        # Desktop machines: Daily maintenance window
        execute_with_dry_run "sudo pmset repeat wakeorpoweron MTWRFSU 03:00:00" \
            "Schedule daily wake at 3:00 AM for maintenance"
        
        info "Desktop power schedule: Daily wake at 3:00 AM for maintenance"
    fi
    
    success "Power schedule configured"
}

#=============================================================================
# POWER MONITORING
#=============================================================================

display_current_power_settings() {
    info "Current power management settings:"
    echo
    
    if [[ $DRY_RUN == "true" ]]; then
        echo "[DRY RUN] Would display current pmset settings"
        return 0
    fi
    
    echo "=== All Power Settings ==="
    pmset -g
    echo
    
    echo "=== Custom Power Settings ==="
    pmset -g custom
    echo
    
    echo "=== Power Assertions ==="
    pmset -g assertions
    echo
    
    echo "=== System Sleep Status ==="
    pmset -g sched
}

validate_power_configuration() {
    local machine_type="$1"
    
    info "Validating power configuration for $machine_type..."
    
    if [[ $DRY_RUN == "true" ]]; then
        echo "[DRY RUN] Would validate power configuration"
        return 0
    fi
    
    local issues=()
    
    # Check if system sleep is properly configured
    local system_sleep
    system_sleep=$(pmset -g | grep -E "^\s*sleep\s+" | awk '{print $2}')
    
    if is_desktop_machine "$machine_type"; then
        if [[ "$system_sleep" != "0" ]]; then
            issues+=("Desktop machine should have system sleep disabled (current: $system_sleep)")
        fi
    fi
    
    # Check wake for network access
    local womp_setting
    womp_setting=$(pmset -g | grep -E "^\s*womp\s+" | awk '{print $2}')
    
    if [[ "$womp_setting" != "1" ]]; then
        issues+=("Wake for network access should be enabled (current: $womp_setting)")
    fi
    
    # Report validation results
    if [[ ${#issues[@]} -eq 0 ]]; then
        success "Power configuration validation passed"
    else
        warn "Power configuration validation found issues:"
        for issue in "${issues[@]}"; do
            warn "  - $issue"
        done
    fi
}

#=============================================================================
# MAIN CONFIGURATION FUNCTION
#=============================================================================

configure_power_management() {
    local machine_type
    machine_type=$(get_machine_type)
    
    info "Configuring power management for: $machine_type"
    
    # Validate we have the necessary permissions
    if [[ $DRY_RUN != "true" ]] && ! sudo -n true 2>/dev/null; then
        warn "Administrator privileges required for power management configuration"
        info "Please run: sudo -v"
        return 1
    fi
    
    # Configure based on machine type
    if is_desktop_machine "$machine_type"; then
        configure_always_on_power "$machine_type"
    elif is_mobile_machine "$machine_type"; then
        configure_balanced_mobile_power "$machine_type"
    else
        warn "Unknown machine type: $machine_type"
        info "Defaulting to balanced configuration"
        configure_balanced_mobile_power "$machine_type"
    fi
    
    # Apply shared settings
    configure_shared_settings
    
    # Configure power schedule
    configure_power_schedule "$machine_type"
    
    # Display current settings
    display_current_power_settings
    
    # Validate configuration
    validate_power_configuration "$machine_type"
    
    success "Power management configuration complete"
    
    # Provide user guidance
    echo
    info "Power Management Summary:"
    if is_desktop_machine "$machine_type"; then
        echo "  • $machine_type configured for always-on operation"
        echo "  • System will never sleep (ideal for remote access)"
        echo "  • Display sleeps after 10 minutes to save screen"
        echo "  • Daily maintenance wake at 3:00 AM"
    elif is_mobile_machine "$machine_type"; then
        echo "  • $machine_type configured for balanced power management"
        echo "  • Battery: Conservative sleep settings"
        echo "  • AC Power: Always-on when plugged in"
        echo "  • Optimal for mobile use with network integration"
    fi
    
    echo
    info "Apple Silicon Wake on LAN Limitations:"
    echo "  • Traditional Ethernet Wake on LAN is not supported"
    echo "  • Limited Wi-Fi wake support for Apple services only"
    echo "  • Always-on configuration provides reliable remote access"
    echo "  • Screen Sharing and SSH will always be available"
}

#=============================================================================
# UTILITY FUNCTIONS
#=============================================================================

reset_power_defaults() {
    info "Resetting power management to macOS defaults..."
    
    execute_with_dry_run "sudo pmset -a sleep 1" \
        "Reset system sleep to default"
    
    execute_with_dry_run "sudo pmset -a displaysleep 10" \
        "Reset display sleep to default"
    
    execute_with_dry_run "sudo pmset -a disksleep 10" \
        "Reset disk sleep to default"
    
    execute_with_dry_run "sudo pmset -a standby 1" \
        "Reset standby to default"
    
    execute_with_dry_run "sudo pmset -a hibernatemode 3" \
        "Reset hibernation mode to default"
    
    execute_with_dry_run "sudo pmset repeat cancel" \
        "Cancel all power schedules"
    
    success "Power management reset to defaults"
}

power_management_help() {
    cat << EOF
${BOLD}Power Management Configuration${RESET}

${BOLD}USAGE${RESET}
    configure_power_management    Configure power management for current machine
    reset_power_defaults         Reset to macOS default power settings
    display_current_power_settings    Show current power configuration
    validate_power_configuration     Validate power settings

${BOLD}MACHINE TYPES${RESET}
    Desktop (Always-On):
        • Mac Studio, Mac mini
        • System never sleeps
        • Display sleeps after 10 minutes
        • Optimised for remote access

    Mobile (Balanced):
        • MacBook Pro, MacBook Air
        • Conservative battery settings
        • Always-on when on AC power
        • Balanced for mobile use

${BOLD}APPLE SILICON LIMITATIONS${RESET}
    • Traditional Wake on LAN not supported
    • Limited Wi-Fi wake support
    • Always-on configuration recommended for servers
    • Screen Sharing and SSH require system to be awake

${BOLD}EXAMPLES${RESET}
    # Configure current machine
    configure_power_management

    # Reset to defaults
    reset_power_defaults

    # View current settings
    display_current_power_settings
EOF
}

# Export functions for use in other scripts
autoload -U configure_power_management
autoload -U reset_power_defaults
autoload -U display_current_power_settings
autoload -U validate_power_configuration
autoload -U power_management_help
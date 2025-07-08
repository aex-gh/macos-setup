#!/usr/bin/env zsh
# ABOUTME: Configures power management and remote access for Apple Silicon Macs
# ABOUTME: Implements always-on configurations and secure remote access services

#=============================================================================
# SCRIPT: 10-power-remote-access.zsh
# AUTHOR: macOS Setup System
# DATE: 2025-01-07
# VERSION: 1.0.0
#
# DESCRIPTION:
#   Configures power management and remote access services for macOS,
#   addressing Apple Silicon Wake on LAN limitations with always-on
#   configurations and comprehensive remote access setup.
#
# USAGE:
#   ./10-power-remote-access.zsh [options]
#
# OPTIONS:
#   -h, --help      Show this help message
#   -v, --verbose   Enable verbose output
#   -d, --debug     Enable debug mode
#   -n, --dry-run   Preview changes without applying them
#   -f, --force     Skip confirmation prompts
#
# REQUIREMENTS:
#   - macOS 11.0+ (Big Sur)
#   - Apple Silicon Mac (M1/M2/M3/M4)
#   - Administrator privileges for power management
#   - Network connectivity for remote access testing
#
# NOTES:
#   - Automatically detects machine type and applies appropriate configuration
#   - Desktop machines (Mac Studio, Mac mini) configured for always-on operation
#   - Mobile machines (MacBook Pro/Air) use balanced power management
#   - Comprehensive remote access setup with security hardening
#=============================================================================

# Strict mode
set -euo pipefail

# Script metadata
readonly SCRIPT_NAME="${0:t}"
readonly SCRIPT_DIR="${0:A:h}"
readonly SCRIPT_VERSION="1.0.0"

# Colour codes (using tput for compatibility)
readonly RED=$(tput setaf 1)
readonly GREEN=$(tput setaf 2)
readonly YELLOW=$(tput setaf 3)
readonly BLUE=$(tput setaf 4)
readonly MAGENTA=$(tput setaf 5)
readonly CYAN=$(tput setaf 6)
readonly WHITE=$(tput setaf 7)
readonly BOLD=$(tput bold)
readonly RESET=$(tput sgr0)

# Global variables
declare -g VERBOSE=false
declare -g DEBUG=false
declare -g DRY_RUN=false
declare -g FORCE=false

#=============================================================================
# LOGGING FUNCTIONS
#=============================================================================

log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Log to console based on level
    case $level in
        ERROR)
            echo "${RED}${BOLD}[ERROR]${RESET} $message" >&2
            ;;
        WARN)
            echo "${YELLOW}${BOLD}[WARN]${RESET} $message" >&2
            ;;
        INFO)
            echo "${BLUE}${BOLD}[INFO]${RESET} $message"
            ;;
        DEBUG)
            [[ $DEBUG == true ]] && echo "${CYAN}[DEBUG]${RESET} $message" || true
            ;;
        SUCCESS)
            echo "${GREEN}${BOLD}[✓]${RESET} $message"
            ;;
        STEP)
            echo "${MAGENTA}${BOLD}[STEP]${RESET} $message"
            ;;
    esac
}

error() { log ERROR "$@"; }
warn() { log WARN "$@"; }
info() { log INFO "$@"; }
debug() { log DEBUG "$@"; }
success() { log SUCCESS "$@"; }
step() { log STEP "$@"; }

#=============================================================================
# UTILITY FUNCTIONS
#=============================================================================

# Confirmation prompt
confirm() {
    local message="${1:-Are you sure?}"
    
    [[ $FORCE == true ]] && return 0
    
    echo -n "${YELLOW}${BOLD}[?]${RESET} $message (y/N): "
    read -r response
    [[ $response =~ ^[Yy]$ ]]
}

# Check if running on macOS
check_macos() {
    if [[ $(uname) != "Darwin" ]]; then
        error "This script requires macOS"
        exit 1
    fi
}

# Check for administrator privileges
check_admin_privileges() {
    if [[ $DRY_RUN == true ]]; then
        debug "DRY RUN: Skipping admin privilege check"
        return 0
    fi
    
    if ! sudo -n true 2>/dev/null; then
        warn "Administrator privileges required for power management configuration"
        info "Please enter your password when prompted"
        sudo -v || {
            error "Administrator privileges required but not granted"
            exit 1
        }
    fi
}

# Get hardware model
get_machine_type() {
    system_profiler SPHardwareDataType | grep "Model Name" | awk -F': ' '{print $2}' | xargs
}

# Check if machine is desktop type
is_desktop_machine() {
    local machine_type="$1"
    [[ "$machine_type" == *"Mac Studio"* || "$machine_type" == *"Mac mini"* ]]
}

# Check if machine is mobile type
is_mobile_machine() {
    local machine_type="$1"
    [[ "$machine_type" == *"MacBook"* ]]
}

#=============================================================================
# MODULE LOADING
#=============================================================================

load_modules() {
    step "Loading power management and remote access modules..."
    
    local modules_dir="$SCRIPT_DIR/modules"
    
    # Load required modules
    local required_modules=(
        "power-management.zsh"
        "remote-access.zsh"
        "system-health.zsh"
    )
    
    for module in "${required_modules[@]}"; do
        local module_path="$modules_dir/$module"
        
        if [[ -f "$module_path" ]]; then
            source "$module_path"
            debug "Loaded module: $module"
        else
            error "Required module not found: $module_path"
            exit 1
        fi
    done
    
    success "All modules loaded successfully"
}

#=============================================================================
# CONFIGURATION FUNCTIONS
#=============================================================================

configure_power_management() {
    step "Configuring power management..."
    
    local machine_type
    machine_type=$(get_machine_type)
    
    info "Detected machine type: $machine_type"
    
    if is_desktop_machine "$machine_type"; then
        info "Applying always-on configuration for desktop machine"
    elif is_mobile_machine "$machine_type"; then
        info "Applying balanced configuration for mobile machine"
    else
        warn "Unknown machine type, applying balanced configuration"
    fi
    
    if [[ $DRY_RUN == true ]]; then
        info "DRY RUN: Would configure power management"
        export DRY_RUN=true
    fi
    
    # Call the power management configuration function from loaded module
    configure_power_management_impl() {
        source "$SCRIPT_DIR/modules/power-management.zsh"
        configure_power_management
    }
    
    configure_power_management_impl
    
    success "Power management configuration completed"
}

configure_remote_access_services() {
    step "Configuring remote access services..."
    
    if [[ $DRY_RUN == true ]]; then
        info "DRY RUN: Would configure remote access services"
        export DRY_RUN=true
    fi
    
    # Call the remote access configuration function from loaded module
    configure_remote_access_impl() {
        source "$SCRIPT_DIR/modules/remote-access.zsh"
        configure_remote_access
    }
    
    configure_remote_access_impl
    
    success "Remote access configuration completed"
}

run_system_health_check() {
    step "Running system health check..."
    
    if [[ $DRY_RUN == true ]]; then
        info "DRY RUN: Would run system health check"
        export DRY_RUN=true
    fi
    
    # Call the system health check function from loaded module
    system_health_check_impl() {
        source "$SCRIPT_DIR/modules/system-health.zsh"
        system_health_check
    }
    
    system_health_check_impl
    
    success "System health check completed"
}

#=============================================================================
# VERIFICATION FUNCTIONS
#=============================================================================

verify_configuration() {
    step "Verifying power management and remote access configuration..."
    
    local verification_passed=true
    
    # Verify power management
    info "Checking power management settings..."
    local machine_type
    machine_type=$(get_machine_type)
    
    if [[ $DRY_RUN == false ]]; then
        local system_sleep
        system_sleep=$(pmset -g | grep -E "^\s*sleep\s+" | awk '{print $2}')
        
        if is_desktop_machine "$machine_type"; then
            if [[ "$system_sleep" != "0" ]]; then
                warn "Desktop machine should have system sleep disabled (current: $system_sleep)"
                verification_passed=false
            else
                success "Power management correctly configured for desktop machine"
            fi
        elif is_mobile_machine "$machine_type"; then
            success "Power management configured for mobile machine"
        fi
    else
        info "DRY RUN: Would verify power management settings"
    fi
    
    # Verify remote access services
    info "Checking remote access services..."
    if [[ $DRY_RUN == false ]]; then
        local services_ok=true
        
        # Check SSH
        if nc -z localhost 22 2>/dev/null; then
            success "SSH service is accessible"
        else
            warn "SSH service is not accessible"
            services_ok=false
        fi
        
        # Check VNC
        if nc -z localhost 5900 2>/dev/null; then
            success "VNC service is accessible"
        else
            warn "VNC service is not accessible"
            services_ok=false
        fi
        
        if [[ $services_ok == true ]]; then
            success "Remote access services are running"
        else
            verification_passed=false
        fi
    else
        info "DRY RUN: Would verify remote access services"
    fi
    
    if [[ $verification_passed == true ]]; then
        success "Configuration verification passed"
    else
        warn "Some verification checks failed - please review configuration"
    fi
    
    return $([ "$verification_passed" = true ])
}

display_connection_info() {
    step "Displaying connection information..."
    
    local hostname
    hostname=$(hostname)
    
    echo
    info "Remote Access Information:"
    echo "  Machine: $(get_machine_type)"
    echo "  Hostname: $hostname"
    echo "  Local: $hostname.local"
    echo
    
    echo "Connection Methods:"
    echo "  SSH:      ssh $(whoami)@$hostname.local"
    echo "  VNC:      vnc://$hostname.local:5900"
    echo "  SMB:      smb://$hostname.local"
    echo "  AFP:      afp://$hostname.local"
    echo
    
    if [[ $DRY_RUN == false ]]; then
        echo "Network Interfaces:"
        ifconfig | grep -E "inet [0-9]" | grep -v "127.0.0.1" | while read -r line; do
            local ip
            ip=$(echo "$line" | awk '{print $2}')
            echo "  IP: $ip"
        done
    else
        echo "DRY RUN: Would display network interface information"
    fi
    
    echo
}

#=============================================================================
# MAIN EXECUTION
#=============================================================================

# Display usage information
usage() {
    cat << EOF
${BOLD}NAME${RESET}
    $SCRIPT_NAME - Power management and remote access setup

${BOLD}SYNOPSIS${RESET}
    $SCRIPT_NAME [options]

${BOLD}DESCRIPTION${RESET}
    Configures power management and remote access services for Apple Silicon Macs.
    Addresses Wake on LAN limitations with always-on configurations for desktop
    machines and balanced power management for mobile devices.

${BOLD}OPTIONS${RESET}
    -h, --help          Show this help message
    -v, --verbose       Enable verbose output
    -d, --debug         Enable debug mode
    -n, --dry-run       Preview changes without applying them
    -f, --force         Skip confirmation prompts

${BOLD}FEATURES${RESET}
    Power Management:
    • Always-on configuration for Mac Studio and Mac mini
    • Balanced configuration for MacBook Pro and MacBook Air
    • Apple Silicon optimisation
    • Automatic hardware detection

    Remote Access:
    • SSH with hardened security configuration
    • Screen Sharing (VNC) with encryption
    • File Sharing (SMB/AFP) with network discovery
    • Firewall configuration with service exceptions

    Monitoring:
    • Comprehensive system health checks
    • Power management validation
    • Remote service connectivity testing
    • Performance monitoring

${BOLD}APPLE SILICON NOTES${RESET}
    Traditional Wake on LAN is not supported on Apple Silicon Macs.
    This script implements always-on configurations for reliable remote access.

${BOLD}AUTHOR${RESET}
    macOS Setup System <noreply@anthropic.com>

${BOLD}VERSION${RESET}
    $SCRIPT_VERSION
EOF
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -d|--debug)
                DEBUG=true
                shift
                ;;
            -n|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -f|--force)
                FORCE=true
                shift
                ;;
            -*)
                error "Unknown option: $1"
                usage
                exit 1
                ;;
            *)
                error "Unexpected argument: $1"
                usage
                exit 1
                ;;
        esac
    done
}

# Main script logic
main() {
    # Parse arguments
    parse_args "$@"
    
    info "Starting power management and remote access setup"
    debug "Script version: $SCRIPT_VERSION"
    
    # Pre-flight checks
    check_macos
    
    # Load required modules
    load_modules
    
    # Check for admin privileges if not dry run
    if [[ $DRY_RUN == false ]]; then
        check_admin_privileges
    fi
    
    # Display machine information
    local machine_type
    machine_type=$(get_machine_type)
    info "Configuring: $machine_type"
    
    # Configuration confirmation
    if [[ $DRY_RUN == false && $FORCE == false ]]; then
        echo
        warn "This script will modify power management and remote access settings"
        
        if is_desktop_machine "$machine_type"; then
            info "Desktop machine detected - will configure for always-on operation"
            info "• System will never sleep"
            info "• Display will sleep after 10 minutes"
            info "• All remote access services will be enabled"
        elif is_mobile_machine "$machine_type"; then
            info "Mobile machine detected - will configure balanced power management"
            info "• Conservative battery settings"
            info "• Always-on when connected to AC power"
            info "• Remote access services will be available"
        fi
        
        echo
        if ! confirm "Continue with configuration?"; then
            info "Configuration cancelled by user"
            exit 0
        fi
    fi
    
    # Run configuration
    echo
    configure_power_management
    echo
    configure_remote_access_services
    echo
    run_system_health_check
    echo
    verify_configuration
    echo
    display_connection_info
    
    success "Power management and remote access setup completed!"
    
    if [[ $DRY_RUN == false ]]; then
        echo
        info "Configuration Summary:"
        if is_desktop_machine "$machine_type"; then
            info "• $machine_type configured for always-on operation"
            info "• System will remain awake for reliable remote access"
            info "• Annual power cost: approximately \$20-40 AUD"
        elif is_mobile_machine "$machine_type"; then
            info "• $machine_type configured for balanced power management"
            info "• Conservative battery settings when unplugged"
            info "• Always-on behaviour when connected to AC power"
        fi
        
        echo
        info "Apple Silicon Wake on LAN Information:"
        info "• Traditional Ethernet Wake on LAN is not supported"
        info "• Wi-Fi wake support is limited to Apple services"
        info "• Always-on configuration provides reliable alternative"
        
        echo
        info "Next Steps:"
        info "• Test remote connections from other devices"
        info "• Monitor system health: system_health_check"
        info "• Review logs for any issues or warnings"
        info "• Consider setting up VPN for internet access"
        
        echo
        info "For troubleshooting, see: docs/POWER-MANAGEMENT-REMOTE-ACCESS.md"
    fi
}

#=============================================================================
# SCRIPT EXECUTION
#=============================================================================

# Only run main if script is executed directly
if [[ "${(%):-%x}" == "${0}" ]]; then
    main "$@"
fi
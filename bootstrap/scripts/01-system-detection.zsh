#!/usr/bin/env zsh
# -*- coding: utf-8 -*-

#=============================================================================
# SCRIPT: 01-system-detection.zsh
# AUTHOR: Andrew Exley
# DATE: 2025-01-07
# VERSION: 1.0.0
#
# DESCRIPTION:
#   Hardware detection and system capability assessment for macOS setup.
#   Identifies Mac model, chip type, memory, and other hardware characteristics
#   to enable hardware-specific optimisations in subsequent setup modules.
#
# USAGE:
#   ./01-system-detection.zsh [options]
#   source ./01-system-detection.zsh  # To set global variables
#
# OPTIONS:
#   -h, --help      Show this help message
#   -v, --verbose   Enable verbose output
#   -d, --debug     Enable debug mode
#   -j, --json      Output detection results as JSON
#
# REQUIREMENTS:
#   - macOS 10.15+ (Catalina)
#   - Zsh 5.8+
#
# NOTES:
#   - Sets global variables for use by other setup modules
#   - Creates hardware profile for configuration selection
#   - Detects Apple Silicon vs Intel architecture
#   - Identifies Mac model for hardware-specific settings
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
declare -g JSON_OUTPUT=false

# Hardware detection results (exported for use by other modules)
declare -gx HARDWARE_TYPE=""           # laptop, desktop, mini, studio
declare -gx HARDWARE_MODEL=""          # MacBook Pro, Mac Studio, etc.
declare -gx HARDWARE_IDENTIFIER=""     # Model identifier (e.g., MacBookPro18,3)
declare -gx CHIP_TYPE=""               # apple_silicon, intel
declare -gx CHIP_NAME=""               # M1, M1 Pro, M1 Max, M2, Intel Core i7, etc.
declare -gx MEMORY_GB=""               # Total RAM in GB
declare -gx STORAGE_GB=""              # Total storage in GB
declare -gx SERIAL_NUMBER=""           # Hardware serial number
declare -gx MACOS_VERSION=""           # macOS version
declare -gx MACOS_BUILD=""             # macOS build number
declare -gx NETWORK_INTERFACES=()     # Available network interfaces
declare -gx HAS_TOUCHID=""             # true/false for Touch ID availability
declare -gx HAS_DISCRETE_GPU=""        # true/false for discrete graphics
declare -gx HARDWARE_CAPABILITIES=()  # Array of hardware capabilities

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
            [[ $DEBUG == true ]] && echo "${CYAN}[DEBUG]${RESET} $message"
            ;;
        SUCCESS)
            echo "${GREEN}${BOLD}[✓]${RESET} $message"
            ;;
    esac
}

error() { log ERROR "$@"; }
warn() { log WARN "$@"; }
info() { log INFO "$@"; }
debug() { log DEBUG "$@"; }
success() { log SUCCESS "$@"; }

#=============================================================================
# HARDWARE DETECTION FUNCTIONS
#=============================================================================

# Detect basic system information
detect_system_info() {
    debug "Detecting basic system information..."
    
    # macOS version and build
    MACOS_VERSION=$(sw_vers -productVersion)
    MACOS_BUILD=$(sw_vers -buildVersion)
    
    # Hardware model and identifier
    HARDWARE_MODEL=$(system_profiler SPHardwareDataType | grep "Model Name:" | awk -F': ' '{print $2}' | xargs)
    HARDWARE_IDENTIFIER=$(system_profiler SPHardwareDataType | grep "Model Identifier:" | awk -F': ' '{print $2}' | xargs)
    
    # Serial number
    SERIAL_NUMBER=$(system_profiler SPHardwareDataType | grep "Serial Number (system):" | awk -F': ' '{print $2}' | xargs)
    
    debug "System: $HARDWARE_MODEL ($HARDWARE_IDENTIFIER)"
    debug "macOS: $MACOS_VERSION ($MACOS_BUILD)"
}

# Detect chip architecture and type
detect_chip_info() {
    debug "Detecting chip architecture..."
    
    local chip_info=$(system_profiler SPHardwareDataType | grep "Chip:" | awk -F': ' '{print $2}' | xargs)
    local processor_info=$(system_profiler SPHardwareDataType | grep "Processor Name:" | awk -F': ' '{print $2}' | xargs)
    
    if [[ -n $chip_info ]]; then
        # Apple Silicon
        CHIP_TYPE="apple_silicon"
        CHIP_NAME="$chip_info"
        HARDWARE_CAPABILITIES+=("apple_silicon")
        
        # Detect specific Apple Silicon features
        case $CHIP_NAME in
            *"M1 Pro"*|*"M1 Max"*|*"M2 Pro"*|*"M2 Max"*|*"M3 Pro"*|*"M3 Max"*|*"M4 Pro"*|*"M4 Max"*)
                HARDWARE_CAPABILITIES+=("pro_chip")
                ;;
            *"M1 Ultra"*|*"M2 Ultra"*)
                HARDWARE_CAPABILITIES+=("ultra_chip")
                ;;
        esac
    elif [[ -n $processor_info ]]; then
        # Intel Mac
        CHIP_TYPE="intel"
        CHIP_NAME="$processor_info"
        HARDWARE_CAPABILITIES+=("intel")
    else
        warn "Could not determine chip type"
        CHIP_TYPE="unknown"
        CHIP_NAME="Unknown"
    fi
    
    debug "Chip: $CHIP_NAME ($CHIP_TYPE)"
}

# Detect hardware type based on model
detect_hardware_type() {
    debug "Detecting hardware type..."
    
    case $HARDWARE_MODEL in
        *"MacBook"*)
            HARDWARE_TYPE="laptop"
            HARDWARE_CAPABILITIES+=("portable" "battery")
            
            # Check for Touch ID (available on newer MacBooks)
            if system_profiler SPiBridgeDataType 2>/dev/null | grep -q "Touch ID"; then
                HAS_TOUCHID="true"
                HARDWARE_CAPABILITIES+=("touchid")
            else
                HAS_TOUCHID="false"
            fi
            ;;
        *"Mac Studio"*)
            HARDWARE_TYPE="studio"
            HARDWARE_CAPABILITIES+=("desktop" "high_performance")
            HAS_TOUCHID="false"
            ;;
        *"Mac mini"*)
            HARDWARE_TYPE="mini"
            HARDWARE_CAPABILITIES+=("desktop" "compact")
            HAS_TOUCHID="false"
            ;;
        *"Mac Pro"*)
            HARDWARE_TYPE="pro"
            HARDWARE_CAPABILITIES+=("desktop" "workstation" "expandable")
            HAS_TOUCHID="false"
            ;;
        *"iMac"*)
            HARDWARE_TYPE="imac"
            HARDWARE_CAPABILITIES+=("desktop" "all_in_one")
            HAS_TOUCHID="false"
            ;;
        *)
            HARDWARE_TYPE="unknown"
            HAS_TOUCHID="false"
            warn "Unknown hardware type: $HARDWARE_MODEL"
            ;;
    esac
    
    debug "Hardware type: $HARDWARE_TYPE"
    debug "Touch ID: $HAS_TOUCHID"
}

# Detect memory configuration
detect_memory_info() {
    debug "Detecting memory configuration..."
    
    # Get memory in bytes and convert to GB
    local memory_bytes=$(sysctl -n hw.memsize)
    MEMORY_GB=$((memory_bytes / 1024 / 1024 / 1024))
    
    # Determine memory tier for optimisations
    if [[ $MEMORY_GB -ge 64 ]]; then
        HARDWARE_CAPABILITIES+=("high_memory")
    elif [[ $MEMORY_GB -ge 32 ]]; then
        HARDWARE_CAPABILITIES+=("medium_memory")
    elif [[ $MEMORY_GB -ge 16 ]]; then
        HARDWARE_CAPABILITIES+=("standard_memory")
    else
        HARDWARE_CAPABILITIES+=("low_memory")
    fi
    
    debug "Memory: ${MEMORY_GB}GB"
}

# Detect storage configuration
detect_storage_info() {
    debug "Detecting storage configuration..."
    
    # Get root filesystem size
    local storage_info=$(df -g / | awk 'NR==2 {print $2}')
    STORAGE_GB="$storage_info"
    
    # Determine storage tier
    if [[ $STORAGE_GB -ge 2000 ]]; then
        HARDWARE_CAPABILITIES+=("high_storage")
    elif [[ $STORAGE_GB -ge 1000 ]]; then
        HARDWARE_CAPABILITIES+=("medium_storage")
    elif [[ $STORAGE_GB -ge 500 ]]; then
        HARDWARE_CAPABILITIES+=("standard_storage")
    else
        HARDWARE_CAPABILITIES+=("low_storage")
    fi
    
    debug "Storage: ${STORAGE_GB}GB"
}

# Detect graphics capabilities
detect_graphics_info() {
    debug "Detecting graphics capabilities..."
    
    # Check for discrete GPU
    local gpu_info=$(system_profiler SPDisplaysDataType | grep -c "Chipset Model:" || echo "0")
    
    if [[ $gpu_info -gt 1 ]]; then
        HAS_DISCRETE_GPU="true"
        HARDWARE_CAPABILITIES+=("discrete_gpu")
    else
        HAS_DISCRETE_GPU="false"
        HARDWARE_CAPABILITIES+=("integrated_gpu")
    fi
    
    # Check for specific GPU features
    if system_profiler SPDisplaysDataType | grep -q "Metal"; then
        HARDWARE_CAPABILITIES+=("metal_support")
    fi
    
    debug "Discrete GPU: $HAS_DISCRETE_GPU"
}

# Detect network interfaces
detect_network_info() {
    debug "Detecting network interfaces..."
    
    # Get available network interfaces
    local interfaces=($(networksetup -listallhardwareports | grep "Hardware Port" | awk -F': ' '{print $2}'))
    NETWORK_INTERFACES=("${interfaces[@]}")
    
    # Check for specific interface types
    for interface in "${interfaces[@]}"; do
        case $interface in
            *"Wi-Fi"*|*"AirPort"*)
                HARDWARE_CAPABILITIES+=("wifi")
                ;;
            *"Ethernet"*)
                HARDWARE_CAPABILITIES+=("ethernet")
                ;;
            *"Thunderbolt"*)
                HARDWARE_CAPABILITIES+=("thunderbolt_bridge")
                ;;
        esac
    done
    
    debug "Network interfaces: ${NETWORK_INTERFACES[*]}"
}

# Detect additional capabilities
detect_additional_capabilities() {
    debug "Detecting additional capabilities..."
    
    # Check for Thunderbolt ports
    if system_profiler SPThunderboltDataType 2>/dev/null | grep -q "Thunderbolt"; then
        HARDWARE_CAPABILITIES+=("thunderbolt")
    fi
    
    # Check for USB-C ports
    if system_profiler SPUSBDataType 2>/dev/null | grep -q "USB-C"; then
        HARDWARE_CAPABILITIES+=("usb_c")
    fi
    
    # Check for audio capabilities
    if system_profiler SPAudioDataType 2>/dev/null | grep -q "Built-in"; then
        HARDWARE_CAPABILITIES+=("audio")
    fi
    
    # Check for camera
    if system_profiler SPCameraDataType 2>/dev/null | grep -q "Camera"; then
        HARDWARE_CAPABILITIES+=("camera")
    fi
    
    # Check for Secure Enclave (Apple Silicon)
    if [[ $CHIP_TYPE == "apple_silicon" ]]; then
        HARDWARE_CAPABILITIES+=("secure_enclave")
    fi
}

#=============================================================================
# OUTPUT FUNCTIONS
#=============================================================================

# Display hardware summary
display_hardware_summary() {
    echo ""
    echo "${BOLD}${CYAN}🔍 Hardware Detection Results${RESET}"
    echo "${BOLD}${CYAN}════════════════════════════════════════════════════════════════════════════════${RESET}"
    echo ""
    
    printf "%-20s: %s\n" "Model" "$HARDWARE_MODEL"
    printf "%-20s: %s\n" "Identifier" "$HARDWARE_IDENTIFIER"
    printf "%-20s: %s\n" "Type" "$HARDWARE_TYPE"
    printf "%-20s: %s\n" "Chip" "$CHIP_NAME"
    printf "%-20s: %s\n" "Architecture" "$CHIP_TYPE"
    printf "%-20s: %s GB\n" "Memory" "$MEMORY_GB"
    printf "%-20s: %s GB\n" "Storage" "$STORAGE_GB"
    printf "%-20s: %s\n" "Touch ID" "$HAS_TOUCHID"
    printf "%-20s: %s\n" "Discrete GPU" "$HAS_DISCRETE_GPU"
    printf "%-20s: %s\n" "macOS Version" "$MACOS_VERSION"
    printf "%-20s: %s\n" "Serial Number" "${SERIAL_NUMBER:0:8}..."
    
    echo ""
    echo "${BOLD}Network Interfaces:${RESET}"
    for interface in "${NETWORK_INTERFACES[@]}"; do
        echo "  • $interface"
    done
    
    echo ""
    echo "${BOLD}Hardware Capabilities:${RESET}"
    for capability in "${HARDWARE_CAPABILITIES[@]}"; do
        echo "  • $capability"
    done
    echo ""
}

# Output detection results as JSON
output_json() {
    cat << EOF
{
  "hardware": {
    "model": "$HARDWARE_MODEL",
    "identifier": "$HARDWARE_IDENTIFIER",
    "type": "$HARDWARE_TYPE",
    "serial_number": "$SERIAL_NUMBER"
  },
  "chip": {
    "name": "$CHIP_NAME",
    "type": "$CHIP_TYPE"
  },
  "memory": {
    "total_gb": $MEMORY_GB
  },
  "storage": {
    "total_gb": $STORAGE_GB
  },
  "features": {
    "touch_id": $HAS_TOUCHID,
    "discrete_gpu": $HAS_DISCRETE_GPU
  },
  "system": {
    "macos_version": "$MACOS_VERSION",
    "macos_build": "$MACOS_BUILD"
  },
  "network_interfaces": [$(printf '"%s",' "${NETWORK_INTERFACES[@]}" | sed 's/,$//')],
  "capabilities": [$(printf '"%s",' "${HARDWARE_CAPABILITIES[@]}" | sed 's/,$//')],
  "detection_timestamp": "$(date -Iseconds)"
}
EOF
}

# Export hardware profile for other scripts
export_hardware_profile() {
    local profile_file="$HOME/.config/dotfiles-setup/hardware-profile.env"
    
    mkdir -p "$(dirname "$profile_file")"
    
    cat > "$profile_file" << EOF
# Hardware Detection Profile
# Generated: $(date)

export HARDWARE_TYPE="$HARDWARE_TYPE"
export HARDWARE_MODEL="$HARDWARE_MODEL"
export HARDWARE_IDENTIFIER="$HARDWARE_IDENTIFIER"
export CHIP_TYPE="$CHIP_TYPE"
export CHIP_NAME="$CHIP_NAME"
export MEMORY_GB="$MEMORY_GB"
export STORAGE_GB="$STORAGE_GB"
export SERIAL_NUMBER="$SERIAL_NUMBER"
export MACOS_VERSION="$MACOS_VERSION"
export MACOS_BUILD="$MACOS_BUILD"
export HAS_TOUCHID="$HAS_TOUCHID"
export HAS_DISCRETE_GPU="$HAS_DISCRETE_GPU"
export NETWORK_INTERFACES=($(printf '"%s" ' "${NETWORK_INTERFACES[@]}"))
export HARDWARE_CAPABILITIES=($(printf '"%s" ' "${HARDWARE_CAPABILITIES[@]}"))
EOF
    
    debug "Hardware profile exported to: $profile_file"
}

#=============================================================================
# CAPABILITY CHECKS
#=============================================================================

# Check if hardware has specific capability
has_capability() {
    local capability=$1
    [[ " ${HARDWARE_CAPABILITIES[*]} " =~ " ${capability} " ]]
}

# Recommend optimisations based on hardware
recommend_optimisations() {
    local recommendations=()
    
    if has_capability "apple_silicon"; then
        recommendations+=("Use native ARM64 applications")
        recommendations+=("Enable optimised Metal rendering")
    fi
    
    if has_capability "low_memory"; then
        recommendations+=("Limit background processes")
        recommendations+=("Reduce visual effects")
    elif has_capability "high_memory"; then
        recommendations+=("Enable memory-intensive features")
        recommendations+=("Configure large caches")
    fi
    
    if has_capability "portable"; then
        recommendations+=("Optimise power management")
        recommendations+=("Enable battery conservation")
    else
        recommendations+=("Disable sleep modes")
        recommendations+=("Enable wake-on-LAN")
    fi
    
    if has_capability "touchid"; then
        recommendations+=("Configure Touch ID for sudo")
        recommendations+=("Enable biometric authentication")
    fi
    
    if [[ ${#recommendations[@]} -gt 0 ]]; then
        echo ""
        echo "${BOLD}Hardware-Specific Recommendations:${RESET}"
        for rec in "${recommendations[@]}"; do
            echo "  💡 $rec"
        done
        echo ""
    fi
}

#=============================================================================
# MAIN FUNCTIONS
#=============================================================================

# Display usage information
usage() {
    cat << EOF
${BOLD}NAME${RESET}
    $SCRIPT_NAME - Hardware detection and system capability assessment

${BOLD}SYNOPSIS${RESET}
    $SCRIPT_NAME [options]

${BOLD}DESCRIPTION${RESET}
    Detects macOS hardware characteristics and capabilities to enable
    hardware-specific optimisations in setup modules. Exports detection
    results as global variables for use by other scripts.

${BOLD}OPTIONS${RESET}
    -h, --help          Show this help message
    -v, --verbose       Enable verbose output
    -d, --debug         Enable debug mode
    -j, --json          Output detection results as JSON

${BOLD}EXAMPLES${RESET}
    # Basic hardware detection
    $SCRIPT_NAME

    # Detailed debug output
    $SCRIPT_NAME --debug

    # JSON output for automation
    $SCRIPT_NAME --json

${BOLD}EXPORTED VARIABLES${RESET}
    HARDWARE_TYPE       - laptop, desktop, mini, studio, etc.
    HARDWARE_MODEL      - Human-readable model name
    CHIP_TYPE          - apple_silicon or intel
    MEMORY_GB          - Total RAM in gigabytes
    HAS_TOUCHID        - Touch ID availability (true/false)
    HARDWARE_CAPABILITIES - Array of hardware features

${BOLD}AUTHOR${RESET}
    Andrew Exley (with Claude) <noreply@anthropic.com>

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
            -j|--json)
                JSON_OUTPUT=true
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

# Run hardware detection
run_detection() {
    debug "Starting hardware detection..."
    
    detect_system_info
    detect_chip_info
    detect_hardware_type
    detect_memory_info
    detect_storage_info
    detect_graphics_info
    detect_network_info
    detect_additional_capabilities
    
    success "Hardware detection completed"
}

# Main script logic
main() {
    # Parse arguments
    parse_args "$@"
    
    # Run detection
    run_detection
    
    # Export profile for other scripts
    export_hardware_profile
    
    # Output results
    if [[ $JSON_OUTPUT == true ]]; then
        output_json
    else
        display_hardware_summary
        recommend_optimisations
    fi
    
    return 0
}

#=============================================================================
# SCRIPT EXECUTION
#=============================================================================

# Only run main if script is executed directly (not sourced)
if [[ "${(%):-%x}" == "${0}" ]]; then
    main "$@"
else
    # Script is being sourced, just run detection and export variables
    run_detection
    export_hardware_profile
fi
#!/usr/bin/env zsh

#=============================================================================
# COMMON LIBRARY: common.zsh
# PURPOSE: Shared functions for macOS setup automation scripts
# AUTHOR: Andrew Exley
# VERSION: 1.0.0
#
# DESCRIPTION:
#   Common library containing shared logging functions, colour definitions,
#   device detection helpers, and validation utilities used across all
#   macOS setup automation scripts.
#
# USAGE:
#   # Source this library in your scripts
#   source "${SCRIPT_DIR}/lib/common.zsh"
#
# REQUIREMENTS:
#   - macOS 11.0+ (Big Sur)
#   - Zsh 5.8+
#=============================================================================

# Only load once
[[ -n ${COMMON_LIB_LOADED:-} ]] && return 0
readonly COMMON_LIB_LOADED=1

#=============================================================================
# COLOUR DEFINITIONS
#=============================================================================

readonly RED=$(tput setaf 1)
readonly GREEN=$(tput setaf 2)
readonly YELLOW=$(tput setaf 3)
readonly BLUE=$(tput setaf 4)
readonly MAGENTA=$(tput setaf 5)
readonly CYAN=$(tput setaf 6)
readonly WHITE=$(tput setaf 7)
readonly BOLD=$(tput bold)
readonly RESET=$(tput sgr0)

#=============================================================================
# LOGGING FUNCTIONS
#=============================================================================

# Central logging function
log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local log_file="${LOG_FILE:-/tmp/${SCRIPT_NAME%.zsh}.log}"

    # Create log directory if it doesn't exist
    [[ ! -d "$(dirname "$log_file")" ]] && mkdir -p "$(dirname "$log_file")"

    # Log to file
    echo "[$timestamp] [$level] $message" >> "$log_file"

    # Log to console based on level
    case $level in
        ERROR)
            echo "${RED}[ERROR]${RESET} $message" >&2
            ;;
        WARN)
            echo "${YELLOW}[WARN]${RESET} $message" >&2
            ;;
        INFO)
            echo "${BLUE}[INFO]${RESET} $message"
            ;;
        DEBUG)
            [[ ${DEBUG:-false} == true ]] && echo "${CYAN}[DEBUG]${RESET} $message" >&2
            ;;
        SUCCESS)
            echo "${GREEN}[SUCCESS]${RESET} $message"
            ;;
        HEADER)
            echo "${MAGENTA}[SETUP]${RESET} $message"
            ;;
        *)
            echo "$message"
            ;;
    esac
}

# Convenience logging functions
error() { log ERROR "$@"; }
warn() { log WARN "$@"; }
info() { log INFO "$@"; }
debug() { log DEBUG "$@"; }
success() { log SUCCESS "$@"; }
header() { log HEADER "$@"; }

#=============================================================================
# DEVICE DETECTION HELPERS
#=============================================================================

# Get Mac model identifier
get_mac_model() {
    sysctl -n hw.model
}

# Get Mac product name
get_mac_product_name() {
    system_profiler SPHardwareDataType | grep "Model Name" | awk -F': ' '{print $2}' | xargs
}

# Detect device type based on model
detect_device_type() {
    local model
    model=$(get_mac_model)
    
    case $model in
        MacBookPro*)
            echo "macbook-pro"
            ;;
        MacStudio*)
            echo "mac-studio"
            ;;
        Macmini*)
            echo "mac-mini"
            ;;
        iMac*)
            echo "imac"
            ;;
        MacBookAir*)
            echo "macbook-air"
            ;;
        MacPro*)
            echo "mac-pro"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# Check if running on specific device type
is_macbook_pro() {
    [[ $(detect_device_type) == "macbook-pro" ]]
}

is_mac_studio() {
    [[ $(detect_device_type) == "mac-studio" ]]
}

is_mac_mini() {
    [[ $(detect_device_type) == "mac-mini" ]]
}

is_portable_mac() {
    local device_type
    device_type=$(detect_device_type)
    [[ $device_type == "macbook-pro" || $device_type == "macbook-air" ]]
}

is_desktop_mac() {
    local device_type
    device_type=$(detect_device_type)
    [[ $device_type == "mac-studio" || $device_type == "mac-mini" || $device_type == "imac" || $device_type == "mac-pro" ]]
}

#=============================================================================
# VALIDATION UTILITIES
#=============================================================================

# Check if running on macOS
check_macos() {
    if [[ $(uname) != "Darwin" ]]; then
        error "This script requires macOS"
        return 1
    fi
}

# Check macOS version
check_macos_version() {
    local required_version="${1:-11.0}"
    local current_version
    current_version=$(sw_vers -productVersion)

    if ! is_version_gte "$current_version" "$required_version"; then
        error "macOS $required_version or later required (current: $current_version)"
        return 1
    fi
}

# Version comparison helper
is_version_gte() {
    [ "$1" = "$(echo -e "$1\n$2" | sort -V | tail -n1)" ]
}

# Check for required commands
check_requirements() {
    local requirements=("$@")
    local missing=()

    for cmd in "${requirements[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing+=("$cmd")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        error "Missing required commands: ${missing[*]}"
        info "Install with: brew install ${missing[*]}"
        return 1
    fi
}

# Check if Homebrew is installed
check_homebrew() {
    if ! command -v brew &>/dev/null; then
        error "Homebrew is not installed or not in PATH"
        return 1
    fi
}

# Check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Check if file exists and is readable
file_readable() {
    [[ -f "$1" && -r "$1" ]]
}

# Check if directory exists and is writable
dir_writable() {
    [[ -d "$1" && -w "$1" ]]
}

#=============================================================================
# MACOS INTEGRATION HELPERS
#=============================================================================

# Send macOS notification
notify() {
    local title="${1:-Script Notification}"
    local message="${2:-Task completed}"
    local sound="${3:-default}"

    if command_exists terminal-notifier; then
        terminal-notifier -title "$title" -message "$message" -sound "$sound"
    else
        osascript -e "display notification \"$message\" with title \"$title\""
    fi
}

# Get/set macOS defaults
get_default() {
    local domain=$1
    local key=$2
    defaults read "$domain" "$key" 2>/dev/null || echo ""
}

set_default() {
    local domain=$1
    local key=$2
    local value=$3
    local type=${4:-string}

    defaults write "$domain" "$key" "-$type" "$value"
}

# Check if app is running
is_app_running() {
    local app_name=$1
    osascript -e "tell application \"System Events\" to (name of processes) contains \"$app_name\"" 2>/dev/null
}

#=============================================================================
# BREWFILE HELPERS
#=============================================================================

# Get Brewfile path for device type
get_brewfile_path() {
    local device_type="${1:-$(detect_device_type)}"
    local project_root="${PROJECT_ROOT:-$(dirname "$(dirname "${BASH_SOURCE[0]}")")}"
    
    echo "$project_root/configs/$device_type/Brewfile"
}

# Get common Brewfile path
get_common_brewfile_path() {
    local project_root="${PROJECT_ROOT:-$(dirname "$(dirname "${BASH_SOURCE[0]}")")}"
    echo "$project_root/configs/common/Brewfile"
}

# Check if Brewfile exists for device type
brewfile_exists() {
    local device_type="${1:-$(detect_device_type)}"
    local brewfile_path
    brewfile_path=$(get_brewfile_path "$device_type")
    
    file_readable "$brewfile_path"
}

#=============================================================================
# DIRECTORY CREATION HELPERS
#=============================================================================

# Create directory with proper permissions
create_directory() {
    local dir_path=$1
    local permissions=${2:-755}
    local owner=${3:-$USER}
    local group=${4:-staff}

    if [[ ! -d "$dir_path" ]]; then
        if sudo mkdir -p "$dir_path"; then
            sudo chown "$owner:$group" "$dir_path"
            sudo chmod "$permissions" "$dir_path"
            success "Created directory: $dir_path"
        else
            error "Failed to create directory: $dir_path"
            return 1
        fi
    else
        debug "Directory already exists: $dir_path"
    fi
}

# Create multiple directories from array
create_directories() {
    local directories=("$@")
    local failed=()

    for dir in "${directories[@]}"; do
        if ! create_directory "$dir"; then
            failed+=("$dir")
        fi
    done

    if [[ ${#failed[@]} -gt 0 ]]; then
        error "Failed to create directories: ${failed[*]}"
        return 1
    fi
}

#=============================================================================
# PROGRESS TRACKING
#=============================================================================

# Progress counter
typeset -g PROGRESS_CURRENT=0
typeset -g PROGRESS_TOTAL=0

# Initialize progress tracking
init_progress() {
    PROGRESS_TOTAL=${1:-100}
    PROGRESS_CURRENT=0
}

# Update progress
update_progress() {
    local increment=${1:-1}
    local message=${2:-"Processing..."}
    
    ((PROGRESS_CURRENT += increment))
    
    local percentage=$((PROGRESS_CURRENT * 100 / PROGRESS_TOTAL))
    local bar_length=20
    local filled_length=$((percentage * bar_length / 100))
    local bar=""
    
    for ((i = 0; i < filled_length; i++)); do
        bar+="█"
    done
    
    for ((i = filled_length; i < bar_length; i++)); do
        bar+="░"
    done
    
    printf "\r${BLUE}[%s] %d%% %s${RESET}" "$bar" "$percentage" "$message"
    
    if [[ $PROGRESS_CURRENT -ge $PROGRESS_TOTAL ]]; then
        echo ""
        success "Progress complete!"
    fi
}

#=============================================================================
# CLEANUP HELPERS
#=============================================================================

# Global cleanup functions array
typeset -g CLEANUP_FUNCTIONS=()

# Register cleanup function
register_cleanup() {
    CLEANUP_FUNCTIONS+=("$1")
}

# Execute all cleanup functions
execute_cleanup() {
    local exit_code=${1:-0}
    
    debug "Running cleanup functions..."
    
    for cleanup_func in "${CLEANUP_FUNCTIONS[@]}"; do
        if declare -f "$cleanup_func" > /dev/null; then
            debug "Executing cleanup function: $cleanup_func"
            "$cleanup_func" || true
        fi
    done
    
    return "$exit_code"
}

# Standard cleanup function
standard_cleanup() {
    # Remove temporary files
    [[ -n ${TEMP_DIR:-} && -d $TEMP_DIR ]] && rm -rf "$TEMP_DIR"
    
    # Clear sensitive variables
    unset TEMP_DIR 2>/dev/null || true
}

# Register standard cleanup
register_cleanup standard_cleanup

#=============================================================================
# USER MANAGEMENT HELPERS
#=============================================================================

# Check if user exists
user_exists() {
    local username="$1"
    if id "$username" &>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Get next available UID
get_next_uid() {
    local max_uid=500
    local existing_uids
    existing_uids=$(dscl . -list /Users UniqueID | awk '{print $2}' | sort -n)
    
    for uid in $existing_uids; do
        if [[ $uid -ge $max_uid ]]; then
            max_uid=$((uid + 1))
        fi
    done
    
    echo $max_uid
}

# Check if user is admin
is_user_admin() {
    local username="${1:-$USER}"
    dscl . -read /Groups/admin GroupMembership 2>/dev/null | grep -q "\b$username\b"
}

# Get user's full name
get_user_full_name() {
    local username="${1:-$USER}"
    dscl . -read "/Users/$username" RealName 2>/dev/null | sed -n 's/^RealName: //p'
}

# Get user's home directory
get_user_home() {
    local username="${1:-$USER}"
    dscl . -read "/Users/$username" NFSHomeDirectory 2>/dev/null | sed -n 's/^NFSHomeDirectory: //p'
}

#=============================================================================
# SYSTEM INFORMATION HELPERS
#=============================================================================

# Get macOS version
get_macos_version() {
    sw_vers -productVersion
}

# Get macOS build version
get_macos_build() {
    sw_vers -buildVersion
}

# Get system uptime
get_system_uptime() {
    uptime | sed 's/.*up \([^,]*\),.*/\1/'
}

# Get CPU information
get_cpu_info() {
    sysctl -n machdep.cpu.brand_string
}

# Get memory information (in GB)
get_memory_info() {
    echo $(( $(sysctl -n hw.memsize) / 1024 / 1024 / 1024 ))GB
}

# Get disk usage for path
get_disk_usage() {
    local path="${1:-/}"
    df -h "$path" | awk 'NR==2 {print $5}' | sed 's/%//'
}

# Get network interface MAC address
get_interface_mac() {
    local interface="${1:-en0}"
    ifconfig "$interface" 2>/dev/null | awk '/ether/{print $2}'
}

#=============================================================================
# SERVICE MANAGEMENT HELPERS
#=============================================================================

# Check if service is running
is_service_running() {
    local service_name="$1"
    launchctl list | grep -q "$service_name"
}

# Get service status
get_service_status() {
    local service_name="$1"
    launchctl list | grep "$service_name" | awk '{print $1}' | head -1
}

# Enable service
enable_service() {
    local service_name="$1"
    local service_path="$2"
    
    if [[ -f "$service_path" ]]; then
        launchctl load "$service_path"
        success "Enabled service: $service_name"
    else
        error "Service file not found: $service_path"
        return 1
    fi
}

# Disable service
disable_service() {
    local service_name="$1"
    local service_path="$2"
    
    if [[ -f "$service_path" ]]; then
        launchctl unload "$service_path"
        success "Disabled service: $service_name"
    else
        warn "Service file not found: $service_path"
    fi
}

#=============================================================================
# ENHANCED CLEANUP HELPERS
#=============================================================================

# Create secure temporary directory
create_temp_directory() {
    local template="${1:-setup.XXXXXX}"
    local temp_dir
    
    temp_dir=$(mktemp -d -t "$template") || {
        error "Failed to create temporary directory"
        return 1
    }
    
    # Set secure permissions
    chmod 700 "$temp_dir"
    
    # Register for cleanup
    register_cleanup "rm -rf '$temp_dir'"
    
    echo "$temp_dir"
}

# Secure file creation
create_secure_file() {
    local file_path="$1"
    local permissions="${2:-600}"
    local owner="${3:-$USER}"
    local group="${4:-staff}"
    
    # Create file with secure permissions
    touch "$file_path"
    chmod "$permissions" "$file_path"
    chown "$owner:$group" "$file_path"
    
    success "Created secure file: $file_path"
}

# Enhanced cleanup with resource tracking
typeset -g TEMP_FILES=()
typeset -g TEMP_DIRECTORIES=()

# Register temporary file for cleanup
register_temp_file() {
    local file_path="$1"
    TEMP_FILES+=("$file_path")
    register_cleanup "rm -f '$file_path'"
}

# Register temporary directory for cleanup
register_temp_directory() {
    local dir_path="$1"
    TEMP_DIRECTORIES+=("$dir_path")
    register_cleanup "rm -rf '$dir_path'"
}

# Enhanced standard cleanup
enhanced_cleanup() {
    debug "Running enhanced cleanup..."
    
    # Clean up temporary files
    for file in "${TEMP_FILES[@]}"; do
        [[ -f "$file" ]] && rm -f "$file"
    done
    
    # Clean up temporary directories
    for dir in "${TEMP_DIRECTORIES[@]}"; do
        [[ -d "$dir" ]] && rm -rf "$dir"
    done
    
    # Clear arrays
    TEMP_FILES=()
    TEMP_DIRECTORIES=()
}

# Register enhanced cleanup
register_cleanup enhanced_cleanup

#=============================================================================
# 1PASSWORD INTEGRATION HELPERS
#=============================================================================

# Check if 1Password app is installed
check_1password_app() {
    [[ -d "/Applications/1Password 7 - Password Manager.app" || -d "/Applications/1Password.app" ]] && {
        return 0
    }
    return 1
}

# Check if 1Password CLI is installed
check_1password_cli() {
    command_exists op && {
        return 0
    }
    return 1
}

# Check if 1Password CLI is authenticated
check_1password_auth() {
    command_exists op || return 1
    op account list &>/dev/null && return 0
    return 1
}

# Install 1Password CLI via Homebrew
install_1password_cli() {
    info "Installing 1Password CLI..."
    check_homebrew || return 1
    
    if brew install --cask 1password-cli; then
        success "1Password CLI installed"
        return 0
    else
        error "Failed to install 1Password CLI"
        return 1
    fi
}

# Authenticate 1Password CLI
authenticate_1password_cli() {
    command_exists op || { error "1Password CLI not installed"; return 1; }
    check_1password_auth && return 0
    
    info "1Password CLI requires authentication"
    if op signin; then
        success "1Password CLI authenticated"
        return 0
    else
        error "1Password CLI authentication failed"
        return 1
    fi
}

# Get password from 1Password item
op_get_password() {
    [[ $# -eq 0 ]] && { echo "Usage: op_get_password \"Item Name\""; return 1; }
    check_1password_auth || { error "1Password CLI not authenticated"; return 1; }
    
    op item get "$1" --fields password 2>/dev/null || {
        error "Error retrieving password for '$1'"
        return 1
    }
}

# Get field from 1Password item
op_get_field() {
    [[ $# -lt 2 ]] && { echo "Usage: op_get_field \"Item\" \"field\""; return 1; }
    check_1password_auth || { error "1Password CLI not authenticated"; return 1; }
    
    op item get "$1" --fields "$2" 2>/dev/null || {
        error "Error retrieving field '$2' from '$1'"
        return 1
    }
}

# Get SSH key from 1Password item
op_get_ssh_key() {
    [[ $# -eq 0 ]] && { echo "Usage: op_get_ssh_key \"Key Name\""; return 1; }
    check_1password_auth || { error "1Password CLI not authenticated"; return 1; }
    
    op item get "$1" --fields "private key" 2>/dev/null || {
        error "Error retrieving SSH key '$1'"
        return 1
    }
}

# List 1Password items
op_list_items() {
    check_1password_auth || { error "1Password CLI not authenticated"; return 1; }
    op item list --format=table 2>/dev/null || {
        error "Error listing 1Password items"
        return 1
    }
}

# Search 1Password items
op_search() {
    [[ $# -eq 0 ]] && { echo "Usage: op_search \"term\""; return 1; }
    check_1password_auth || { error "1Password CLI not authenticated"; return 1; }
    
    op item list --format=table | grep -i "$1" || {
        warn "No items found matching: $1"
        return 1
    }
}

#=============================================================================
# NETWORK CONFIGURATION HELPERS
#=============================================================================

# Get available network services
get_network_services() {
    networksetup -listallnetworkservices | grep -v "asterisk" | tail -n +2
}

# Check if network service exists
check_network_service() {
    local service="$1"
    networksetup -listallnetworkservices | grep -q "^$service$"
}

# Get primary network interface for device type
get_primary_interface() {
    local device_type="${1:-$(detect_device_type)}"
    
    case "$device_type" in
        "macbook-pro"|"macbook-air")
            # Prefer Wi-Fi for portable devices
            echo "Wi-Fi"
            ;;
        "mac-studio"|"mac-mini"|"imac"|"mac-pro")
            # Prefer Ethernet for desktop devices
            echo "Ethernet"
            ;;
        *)
            # Default to Wi-Fi
            echo "Wi-Fi"
            ;;
    esac
}

# Configure static IP address
configure_static_ip() {
    local service="$1"
    local ip_address="$2"
    local subnet_mask="${3:-255.255.255.0}"
    local gateway="${4:-10.20.0.1}"
    
    info "Configuring static IP for $service: $ip_address"
    
    if sudo networksetup -setmanual "$service" "$ip_address" "$subnet_mask" "$gateway"; then
        success "Static IP configured: $ip_address"
        return 0
    else
        error "Failed to configure static IP"
        return 1
    fi
}

# Configure DHCP for network service
configure_dhcp() {
    local service="$1"
    
    info "Configuring DHCP for $service"
    
    if sudo networksetup -setdhcp "$service"; then
        success "DHCP configured for $service"
        return 0
    else
        error "Failed to configure DHCP for $service"
        return 1
    fi
}

# Set DNS servers
set_dns_servers() {
    local service="$1"
    shift
    local dns_servers=("$@")
    
    info "Setting DNS servers for $service: ${dns_servers[*]}"
    
    if sudo networksetup -setdnsservers "$service" "${dns_servers[@]}"; then
        success "DNS servers configured"
        return 0
    else
        error "Failed to set DNS servers"
        return 1
    fi
}

# Get current IP address for interface
get_current_ip() {
    local interface="${1:-en0}"
    ifconfig "$interface" 2>/dev/null | awk '/inet /{print $2}' | head -1
}

# Get network service for interface
get_network_service_for_interface() {
    local interface="$1"
    networksetup -listallhardwareports | awk "/Device: $interface/{getline; print \$2 \$3 \$4}" | sed 's/Service://'
}

#=============================================================================
# PACKAGE VALIDATION HELPERS
#=============================================================================

# Validate Brewfile using brew bundle check
validate_brewfile() {
    local brewfile="$1"
    local brewfile_name="${brewfile:t}"
    local brewfile_dir="${brewfile:h}"
    
    if ! file_readable "$brewfile"; then
        error "Brewfile not found: $brewfile"
        return 1
    fi
    
    info "Validating $brewfile_name..."
    
    # Change to brewfile directory for proper relative path handling
    local current_dir="$PWD"
    cd "$brewfile_dir" || return 1
    
    # Use brew bundle check for validation
    if brew bundle check --file="$brewfile" --verbose; then
        success "✓ $brewfile_name validation passed"
        cd "$current_dir"
        return 0
    else
        error "✗ $brewfile_name validation failed"
        cd "$current_dir"
        return 1
    fi
}

# Validate multiple Brewfiles
validate_brewfiles() {
    local brewfiles=("$@")
    local failed_files=()
    
    for brewfile in "${brewfiles[@]}"; do
        if ! validate_brewfile "$brewfile"; then
            failed_files+=("$brewfile")
        fi
    done
    
    if [[ ${#failed_files[@]} -eq 0 ]]; then
        success "All Brewfiles validated successfully"
        return 0
    else
        error "Failed to validate: ${failed_files[*]}"
        return 1
    fi
}

# Check if formula/cask exists in Homebrew
check_brew_package() {
    local package="$1"
    local type="${2:-formula}"  # formula or cask
    
    case "$type" in
        "formula")
            brew search --formula "$package" | grep -q "^$package$"
            ;;
        "cask")
            brew search --cask "$package" | grep -q "^$package$"
            ;;
        *)
            # Try both
            brew search --formula "$package" | grep -q "^$package$" || \
            brew search --cask "$package" | grep -q "^$package$"
            ;;
    esac
}

# Install missing packages from Brewfile
install_brewfile_packages() {
    local brewfile="$1"
    local brewfile_dir="${brewfile:h}"
    
    if ! file_readable "$brewfile"; then
        error "Brewfile not found: $brewfile"
        return 1
    fi
    
    info "Installing packages from ${brewfile:t}..."
    
    # Change to brewfile directory for proper relative path handling
    local current_dir="$PWD"
    cd "$brewfile_dir" || return 1
    
    if brew bundle install --file="$brewfile" --verbose; then
        success "Package installation completed"
        cd "$current_dir"
        return 0
    else
        error "Package installation failed"
        cd "$current_dir"
        return 1
    fi
}

#=============================================================================
# INITIALIZATION
#=============================================================================

# Auto-detect script metadata if not set
if [[ -z ${SCRIPT_NAME:-} ]]; then
    readonly SCRIPT_NAME="${0:t}"
fi

if [[ -z ${SCRIPT_DIR:-} ]]; then
    readonly SCRIPT_DIR="${0:A:h}"
fi

if [[ -z ${PROJECT_ROOT:-} ]]; then
    readonly PROJECT_ROOT="${SCRIPT_DIR}/.."
fi

# Set up basic error handling
set -euo pipefail

# Trap cleanup on exit
trap 'execute_cleanup $?' EXIT

debug "Common library loaded successfully"
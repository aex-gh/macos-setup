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
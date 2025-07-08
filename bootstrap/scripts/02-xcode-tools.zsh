#!/usr/bin/env zsh
# -*- coding: utf-8 -*-

#=============================================================================
# SCRIPT: 02-xcode-tools.zsh
# AUTHOR: Andrew Exley
# DATE: 2025-01-07
# VERSION: 1.0.0
#
# DESCRIPTION:
#   Xcode Command Line Tools installation and verification module.
#   Ensures development prerequisites are installed before package managers
#   and development tools setup.
#
# USAGE:
#   ./02-xcode-tools.zsh [options]
#
# OPTIONS:
#   -h, --help      Show this help message
#   -v, --verbose   Enable verbose output
#   -d, --debug     Enable debug mode
#   -n, --dry-run   Preview changes without applying them
#   -f, --force     Force reinstallation even if already installed
#
# REQUIREMENTS:
#   - macOS 10.15+ (Catalina)
#   - Admin privileges for installation
#
# NOTES:
#   - Required for Homebrew and most development tools
#   - Installation may require user interaction and restarts
#   - Automatically accepts license agreements
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
            [[ $DEBUG == true ]] && echo "${CYAN}[DEBUG]${RESET} $message"
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

# Check if running on macOS
check_macos() {
    if [[ $(uname) != "Darwin" ]]; then
        error "This script requires macOS"
        exit 1
    fi
}

# Confirmation prompt
confirm() {
    local message="${1:-Are you sure?}"
    
    echo -n "${YELLOW}${BOLD}[?]${RESET} $message (y/N): "
    read -r response
    [[ $response =~ ^[Yy]$ ]]
}

# Print section header
print_section() {
    local title=$1
    local emoji=$2
    
    echo ""
    echo "${BOLD}${CYAN}═══════════════════════════════════════════════════════════════════════════════${RESET}"
    echo "${BOLD}${CYAN}  $emoji $title${RESET}"
    echo "${BOLD}${CYAN}═══════════════════════════════════════════════════════════════════════════════${RESET}"
    echo ""
}

# Execute command with proper logging
execute_command() {
    local description=$1
    shift
    local cmd=("$@")
    
    step "$description"
    
    if [[ $DRY_RUN == false ]]; then
        if "${cmd[@]}"; then
            debug "Executed: ${cmd[*]}"
        else
            error "Failed to execute: ${cmd[*]}"
            return 1
        fi
    else
        debug "DRY RUN: ${cmd[*]}"
    fi
    
    return 0
}

#=============================================================================
# XCODE TOOLS FUNCTIONS
#=============================================================================

# Check if Xcode Command Line Tools are installed
check_xcode_tools_installed() {
    debug "Checking for existing Xcode Command Line Tools installation..."
    
    # Method 1: Check xcode-select path
    if xcode-select -p &>/dev/null; then
        local xcode_path=$(xcode-select -p)
        debug "Xcode tools path: $xcode_path"
        
        # Verify essential tools exist
        local essential_tools=("git" "clang" "make")
        local missing_tools=()
        
        for tool in "${essential_tools[@]}"; do
            if ! command -v "$tool" &>/dev/null; then
                missing_tools+=("$tool")
            fi
        done
        
        if [[ ${#missing_tools[@]} -eq 0 ]]; then
            success "Xcode Command Line Tools are installed and functional"
            return 0
        else
            warn "Xcode Command Line Tools path exists but missing tools: ${missing_tools[*]}"
            return 1
        fi
    else
        debug "Xcode tools not found via xcode-select"
        return 1
    fi
}

# Get Xcode Command Line Tools version
get_xcode_tools_version() {
    if xcode-select -p &>/dev/null; then
        local version=$(xcode-select --version 2>/dev/null | head -n1)
        echo "$version"
    else
        echo "Not installed"
    fi
}

# Check for and install updates
check_xcode_tools_updates() {
    step "Checking for Xcode Command Line Tools updates..."
    
    # Check for software updates
    local updates=$(softwareupdate -l 2>/dev/null | grep -c "Command Line Tools" 2>/dev/null || echo "0")
    
    # Ensure we have a numeric value
    if [[ ! "$updates" =~ ^[0-9]+$ ]]; then
        updates=0
    fi
    
    if [[ $updates -gt 0 ]]; then
        warn "Xcode Command Line Tools updates available"
        
        if [[ $DRY_RUN == false ]]; then
            if confirm "Install Xcode Command Line Tools updates?"; then
                execute_command "Installing Xcode Command Line Tools updates" \
                    sudo softwareupdate -i "Command Line Tools*"
                success "Xcode Command Line Tools updated"
                return 0
            else
                warn "Skipping Xcode Command Line Tools updates"
                return 1
            fi
        else
            info "DRY RUN: Would install Xcode Command Line Tools updates"
            return 0
        fi
    else
        success "Xcode Command Line Tools are up to date"
        return 0
    fi
}

# Install Xcode Command Line Tools
install_xcode_tools() {
    step "Installing Xcode Command Line Tools..."
    
    if [[ $DRY_RUN == true ]]; then
        info "DRY RUN: Would install Xcode Command Line Tools"
        return 0
    fi
    
    # Create a temporary file to track installation
    local placeholder_file="/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress"
    
    # Create the placeholder file to trigger installation
    execute_command "Creating installation trigger" \
        sudo touch "$placeholder_file"
    
    # Find the Command Line Tools update
    info "Searching for available Command Line Tools..."
    local cmd_line_tools=$(softwareupdate -l 2>/dev/null | grep "\*.*Command Line Tools" | tail -n1 | sed 's/^[^C]* //')
    
    if [[ -z $cmd_line_tools ]]; then
        error "No Command Line Tools found in software updates"
        sudo rm -f "$placeholder_file"
        return 1
    fi
    
    info "Found: $cmd_line_tools"
    
    # Install the Command Line Tools
    execute_command "Installing Command Line Tools (this may take a while)" \
        sudo softwareupdate -i "$cmd_line_tools"
    
    # Clean up
    sudo rm -f "$placeholder_file"
    
    # Verify installation
    if check_xcode_tools_installed; then
        success "Xcode Command Line Tools installed successfully"
        return 0
    else
        error "Xcode Command Line Tools installation verification failed"
        return 1
    fi
}

# Accept Xcode license
accept_xcode_license() {
    step "Checking Xcode license agreement..."
    
    if [[ $DRY_RUN == true ]]; then
        info "DRY RUN: Would accept Xcode license if needed"
        return 0
    fi
    
    # Check if xcodebuild is available (requires full Xcode, not just Command Line Tools)
    if ! command -v xcodebuild &>/dev/null; then
        info "Xcode license check skipped (Command Line Tools only, no full Xcode)"
        return 0
    fi
    
    # Check if license needs to be accepted
    if ! xcodebuild -license check &>/dev/null; then
        warn "Xcode license agreement needs to be accepted"
        
        if confirm "Accept Xcode license agreement?"; then
            execute_command "Accepting Xcode license" \
                sudo xcodebuild -license accept
            success "Xcode license accepted"
        else
            error "Xcode license must be accepted to continue"
            return 1
        fi
    else
        success "Xcode license already accepted"
    fi
    
    return 0
}

# Verify essential development tools
verify_development_tools() {
    step "Verifying essential development tools..."
    
    local essential_tools=(
        "git:Git version control"
        "clang:C/C++ compiler"
        "make:Build automation tool"
        "cc:C compiler"
        "cpp:C preprocessor"
        "ld:Linker"
        "ar:Archive utility"
        "strip:Symbol stripper"
        "xcode-select:Xcode tools selector"
    )
    
    local missing_tools=()
    local working_tools=()
    
    for tool_info in "${essential_tools[@]}"; do
        local tool="${tool_info%%:*}"
        local description="${tool_info##*:}"
        
        if command -v "$tool" &>/dev/null; then
            working_tools+=("$tool")
            debug "✓ $tool ($description) - available"
        else
            missing_tools+=("$tool")
            debug "✗ $tool ($description) - missing"
        fi
    done
    
    info "Working tools: ${#working_tools[@]}/${#essential_tools[@]}"
    
    if [[ ${#missing_tools[@]} -eq 0 ]]; then
        success "All essential development tools are available"
        return 0
    else
        error "Missing development tools: ${missing_tools[*]}"
        return 1
    fi
}

# Display tool information
display_tool_info() {
    echo ""
    echo "${BOLD}Development Tools Information:${RESET}"
    echo ""
    
    # Xcode Command Line Tools version
    local xcode_version=$(get_xcode_tools_version)
    printf "%-25s: %s\n" "Xcode Tools Version" "$xcode_version"
    
    # Xcode path
    if xcode-select -p &>/dev/null; then
        printf "%-25s: %s\n" "Xcode Tools Path" "$(xcode-select -p)"
    fi
    
    # Compiler information
    if command -v clang &>/dev/null; then
        local clang_version=$(clang --version | head -n1)
        printf "%-25s: %s\n" "Clang Version" "$clang_version"
    fi
    
    # Git version
    if command -v git &>/dev/null; then
        local git_version=$(git --version)
        printf "%-25s: %s\n" "Git Version" "$git_version"
    fi
    
    echo ""
}

#=============================================================================
# MAIN FUNCTIONS
#=============================================================================

# Display usage information
usage() {
    cat << EOF
${BOLD}NAME${RESET}
    $SCRIPT_NAME - Xcode Command Line Tools installation and verification

${BOLD}SYNOPSIS${RESET}
    $SCRIPT_NAME [options]

${BOLD}DESCRIPTION${RESET}
    Installs and verifies Xcode Command Line Tools, which are required for
    most development activities on macOS including Homebrew, Git, and
    compilation tools.

${BOLD}OPTIONS${RESET}
    -h, --help          Show this help message
    -v, --verbose       Enable verbose output
    -d, --debug         Enable debug mode
    -n, --dry-run       Preview changes without applying them
    -f, --force         Force reinstallation even if already installed

${BOLD}EXAMPLES${RESET}
    # Install Command Line Tools if needed
    $SCRIPT_NAME

    # Force reinstallation
    $SCRIPT_NAME --force

    # Check what would be done
    $SCRIPT_NAME --dry-run

${BOLD}REQUIREMENTS${RESET}
    - macOS 10.15+ (Catalina)
    - Admin privileges for installation
    - Internet connection for downloading tools

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

# Main installation and verification logic
main() {
    # Check environment
    check_macos
    
    # Parse arguments
    parse_args "$@"
    
    print_section "XCODE COMMAND LINE TOOLS SETUP" "🛠️"
    
    # Check if already installed and functional
    if check_xcode_tools_installed && [[ $FORCE != true ]]; then
        display_tool_info
        
        # Still check for updates
        check_xcode_tools_updates
        
        # Verify license
        accept_xcode_license
        
        success "Xcode Command Line Tools setup completed"
        return 0
    fi
    
    # Installation needed
    if [[ $FORCE == true ]]; then
        warn "Force installation requested"
    else
        info "Xcode Command Line Tools installation required"
    fi
    
    # Show what will be installed
    if [[ $DRY_RUN == false ]]; then
        echo ""
        echo "${BOLD}The following will be installed:${RESET}"
        echo "  • Xcode Command Line Tools"
        echo "  • Development headers and libraries"
        echo "  • Essential build tools (git, clang, make, etc.)"
        echo ""
        echo "${YELLOW}Note: Installation may require user interaction and take several minutes.${RESET}"
        echo ""
        
        if ! confirm "Proceed with installation?"; then
            info "Installation cancelled"
            exit 0
        fi
    fi
    
    # Perform installation
    if install_xcode_tools; then
        # Accept license
        accept_xcode_license
        
        # Verify installation
        if verify_development_tools; then
            display_tool_info
            success "Xcode Command Line Tools setup completed successfully"
            
            echo ""
            echo "${BOLD}Next steps:${RESET}"
            echo "  • You can now install Homebrew and other development tools"
            echo "  • Git is now available for version control"
            echo "  • C/C++ compilation tools are ready"
            echo ""
        else
            error "Tool verification failed after installation"
            return 1
        fi
    else
        error "Xcode Command Line Tools installation failed"
        return 1
    fi
}

#=============================================================================
# CLEANUP & ERROR HANDLING
#=============================================================================

# Cleanup function
cleanup() {
    local exit_code=$?
    
    debug "Cleaning up..."
    
    # Remove any temporary files
    sudo rm -f /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress 2>/dev/null || true
    
    # Log exit status
    if [[ $exit_code -eq 0 ]]; then
        debug "Script exited successfully"
    else
        error "Script exited with code: $exit_code"
    fi
    
    exit $exit_code
}

# Error handler
error_handler() {
    local line_no=$1
    error "An error occurred on line $line_no"
    cleanup
}

# Set traps
trap cleanup EXIT
trap 'error_handler $LINENO' ERR

#=============================================================================
# SCRIPT EXECUTION
#=============================================================================

# Only run main if script is executed directly
if [[ "${(%):-%x}" == "${0}" ]]; then
    main "$@"
fi
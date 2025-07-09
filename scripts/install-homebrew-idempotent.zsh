#!/usr/bin/env zsh
# -*- coding: utf-8 -*-

# ABOUTME: This script provides idempotent Homebrew installation with cleanup integration for all system types
# ABOUTME: It orchestrates the homebrew-manager.rb and related tools to ensure consistent package states

#=============================================================================
# SCRIPT: install-homebrew-idempotent.zsh
# VERSION: 1.0.0
# 
# DESCRIPTION:
#   Enhanced Homebrew installation script that provides idempotent package
#   management with automatic cleanup capabilities. Integrates with the
#   existing categorised Brewfile structure while adding safety features.
#
# USAGE:
#   ./install-homebrew-idempotent.zsh [options]
#
# OPTIONS:
#   -h, --help          Show this help message
#   -v, --verbose       Enable verbose output
#   -n, --dry-run       Show what would be done without executing
#   -f, --force         Skip confirmation prompts
#   -b, --backup        Create backup before making changes
#   -c, --cleanup       Perform cleanup of unwanted packages
#   -s, --sync          Full sync (install + cleanup)
#   -t, --track         Enable state tracking
#   --system TYPE       System type (base|dev|productivity|utilities|all)
#   --brewfiles FILES   Specific Brewfiles to use
#=============================================================================

# Strict mode
set -euo pipefail

# Script metadata
readonly SCRIPT_NAME="${0:t}"
readonly SCRIPT_DIR="${0:A:h}"
readonly SCRIPT_VERSION="1.0.0"
readonly BREWFILES_DIR="${SCRIPT_DIR}/../brewfiles"

# Colour codes
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
declare -g DRY_RUN=false
declare -g FORCE=false
declare -g BACKUP=false
declare -g CLEANUP=false
declare -g SYNC=false
declare -g TRACK=false
declare -g SYSTEM_TYPE="base"
declare -g BREWFILES=""
declare -g LOG_FILE="/tmp/${SCRIPT_NAME%.zsh}.log"

# Helper scripts
readonly HOMEBREW_MANAGER="${SCRIPT_DIR}/homebrew-manager.rb"
readonly CLEANUP_SCRIPT="${SCRIPT_DIR}/brew-cleanup-safe.zsh"
readonly STATE_TRACKER="${SCRIPT_DIR}/brew-state-tracker.zsh"

#=============================================================================
# LOGGING FUNCTIONS
#=============================================================================

log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Log to file
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    
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
            [[ $VERBOSE == true ]] && echo "${CYAN}[DEBUG]${RESET} $message"
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
# UTILITY FUNCTIONS
#=============================================================================

# Display usage information
usage() {
    cat << EOF
${BOLD}NAME${RESET}
    $SCRIPT_NAME - Idempotent Homebrew installation with cleanup

${BOLD}SYNOPSIS${RESET}
    $SCRIPT_NAME [options]

${BOLD}DESCRIPTION${RESET}
    This script provides idempotent Homebrew package management with automatic
    cleanup capabilities. It orchestrates the homebrew-manager.rb and related
    tools to ensure consistent package states across different system types.

${BOLD}OPTIONS${RESET}
    -h, --help          Show this help message
    -v, --verbose       Enable verbose output
    -n, --dry-run       Show what would be done without executing
    -f, --force         Skip confirmation prompts
    -b, --backup        Create backup before making changes
    -c, --cleanup       Perform cleanup of unwanted packages
    -s, --sync          Full sync (install + cleanup)
    -t, --track         Enable state tracking
    --system TYPE       System type (base|dev|productivity|utilities|all)
    --brewfiles FILES   Comma-separated list of specific Brewfiles to use

${BOLD}SYSTEM TYPES${RESET}
    base            Essential tools for all systems
    dev             Development environment packages
    productivity    Office and productivity applications
    utilities       System utilities and specialised tools
    all             All available packages

${BOLD}EXAMPLES${RESET}
    # Install base packages only
    $SCRIPT_NAME --system base

    # Full sync with backup
    $SCRIPT_NAME --sync --backup

    # Dry run to see what would change
    $SCRIPT_NAME --dry-run --system all

    # Development environment with cleanup
    $SCRIPT_NAME --system dev --cleanup --verbose

    # Use specific Brewfiles
    $SCRIPT_NAME --brewfiles base.brewfile,dev.brewfile

${BOLD}WORKFLOW${RESET}
    1. Check system requirements
    2. Install/update Homebrew if needed
    3. Create backup if requested
    4. Install packages from selected Brewfiles
    5. Perform cleanup if requested
    6. Track state changes if enabled
    7. Generate summary report

${BOLD}AUTHOR${RESET}
    macOS Setup Project

${BOLD}VERSION${RESET}
    $SCRIPT_VERSION
EOF
}

# Check for required commands and scripts
check_requirements() {
    local requirements=("ruby" "brew")
    local missing=()
    
    for cmd in "${requirements[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing+=("$cmd")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        error "Missing required commands: ${missing[*]}"
        exit 1
    fi
    
    # Check for required scripts
    local scripts=("$HOMEBREW_MANAGER" "$CLEANUP_SCRIPT" "$STATE_TRACKER")
    local missing_scripts=()
    
    for script in "${scripts[@]}"; do
        if [[ ! -f "$script" ]]; then
            missing_scripts+=("$script")
        fi
    done
    
    if [[ ${#missing_scripts[@]} -gt 0 ]]; then
        error "Missing required scripts:"
        printf "  %s\n" "${missing_scripts[@]}"
        exit 1
    fi
}

# Install or update Homebrew
install_homebrew() {
    if command -v brew &> /dev/null; then
        info "Homebrew already installed"
        
        if [[ $DRY_RUN == false ]]; then
            info "Updating Homebrew..."
            brew update
        fi
    else
        info "Installing Homebrew..."
        
        if [[ $DRY_RUN == false ]]; then
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            
            # Add to PATH for Apple Silicon Macs
            if [[ -f /opt/homebrew/bin/brew ]]; then
                eval "$(/opt/homebrew/bin/brew shellenv)"
            fi
        fi
    fi
    
    # Disable analytics
    if [[ $DRY_RUN == false ]]; then
        brew analytics off
    fi
}

# Determine Brewfiles to use
determine_brewfiles() {
    if [[ -n "$BREWFILES" ]]; then
        # Use specified Brewfiles
        echo "$BREWFILES"
        return
    fi
    
    # Determine based on system type
    case $SYSTEM_TYPE in
        base)
            echo "base.brewfile"
            ;;
        dev)
            echo "base.brewfile,dev.brewfile"
            ;;
        productivity)
            echo "base.brewfile,productivity.brewfile"
            ;;
        utilities)
            echo "base.brewfile,utilities.brewfile"
            ;;
        all)
            echo "base.brewfile,dev.brewfile,productivity.brewfile,utilities.brewfile"
            ;;
        *)
            error "Unknown system type: $SYSTEM_TYPE"
            exit 1
            ;;
    esac
}

# Create backup if requested
create_backup() {
    if [[ $BACKUP == false ]]; then
        return 0
    fi
    
    info "Creating backup..."
    
    local cmd_args=("$HOMEBREW_MANAGER" "--backup")
    [[ $VERBOSE == true ]] && cmd_args+=("--verbose")
    
    if [[ $DRY_RUN == false ]]; then
        "${cmd_args[@]}"
    else
        debug "Would create backup: ${cmd_args[*]}"
    fi
}

# Install packages
install_packages() {
    local brewfiles=$(determine_brewfiles)
    
    info "Installing packages from: $brewfiles"
    
    local cmd_args=("$HOMEBREW_MANAGER" "--install")
    [[ $VERBOSE == true ]] && cmd_args+=("--verbose")
    [[ $DRY_RUN == true ]] && cmd_args+=("--dry-run")
    [[ $FORCE == true ]] && cmd_args+=("--force")
    cmd_args+=("--brewfiles" "$brewfiles")
    
    if [[ $DRY_RUN == false ]]; then
        "${cmd_args[@]}"
    else
        debug "Would install packages: ${cmd_args[*]}"
    fi
}

# Perform cleanup
perform_cleanup() {
    if [[ $CLEANUP == false ]]; then
        return 0
    fi
    
    info "Performing cleanup..."
    
    local cmd_args=("$CLEANUP_SCRIPT")
    [[ $VERBOSE == true ]] && cmd_args+=("--verbose")
    [[ $DRY_RUN == true ]] && cmd_args+=("--dry-run")
    [[ $FORCE == true ]] && cmd_args+=("--force")
    
    if [[ -n "$BREWFILES" ]]; then
        cmd_args+=("--brewfiles" "$BREWFILES")
    fi
    
    if [[ $DRY_RUN == false ]]; then
        "${cmd_args[@]}"
    else
        debug "Would perform cleanup: ${cmd_args[*]}"
    fi
}

# Track state changes
track_state() {
    if [[ $TRACK == false ]]; then
        return 0
    fi
    
    info "Tracking state changes..."
    
    local cmd_args=("$STATE_TRACKER" "status")
    [[ $VERBOSE == true ]] && cmd_args+=("--verbose")
    
    if [[ -n "$BREWFILES" ]]; then
        cmd_args+=("--brewfiles" "$BREWFILES")
    fi
    
    "${cmd_args[@]}"
}

# Generate summary report
generate_summary() {
    info "Installation Summary"
    echo ""
    
    # Show current state
    local brewfiles=$(determine_brewfiles)
    local cmd_args=("$HOMEBREW_MANAGER" "--diff")
    [[ $VERBOSE == true ]] && cmd_args+=("--verbose")
    cmd_args+=("--brewfiles" "$brewfiles")
    
    local diff_output=$("${cmd_args[@]}" 2>/dev/null || echo "")
    
    if [[ -z "$diff_output" ]]; then
        success "All packages are in sync"
    else
        warn "Package differences detected:"
        echo "$diff_output"
    fi
    
    echo ""
    info "Package counts:"
    echo "  Taps: $(brew tap | wc -l | tr -d ' ')"
    echo "  Formulae: $(brew list --formula | wc -l | tr -d ' ')"
    echo "  Casks: $(brew list --cask | wc -l | tr -d ' ')"
    
    if command -v mas &> /dev/null; then
        echo "  MAS apps: $(mas list | wc -l | tr -d ' ')"
    fi
    
    if command -v code &> /dev/null; then
        echo "  VS Code extensions: $(code --list-extensions | wc -l | tr -d ' ')"
    fi
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
            -n|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -f|--force)
                FORCE=true
                shift
                ;;
            -b|--backup)
                BACKUP=true
                shift
                ;;
            -c|--cleanup)
                CLEANUP=true
                shift
                ;;
            -s|--sync)
                SYNC=true
                CLEANUP=true
                shift
                ;;
            -t|--track)
                TRACK=true
                shift
                ;;
            --system)
                SYSTEM_TYPE="$2"
                case $SYSTEM_TYPE in
                    base|dev|productivity|utilities|all)
                        ;;
                    *)
                        error "Invalid system type: $SYSTEM_TYPE"
                        exit 1
                        ;;
                esac
                shift 2
                ;;
            --brewfiles)
                BREWFILES="$2"
                shift 2
                ;;
            --version)
                echo "$SCRIPT_NAME v$SCRIPT_VERSION"
                exit 0
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
    
    # Check requirements
    check_requirements
    
    info "Starting $SCRIPT_NAME v$SCRIPT_VERSION"
    info "System type: $SYSTEM_TYPE"
    info "Brewfiles: $(determine_brewfiles)"
    
    if [[ $DRY_RUN == true ]]; then
        info "DRY RUN MODE - No changes will be made"
    fi
    
    echo ""
    
    # Install/update Homebrew
    install_homebrew
    
    # Create backup if requested
    create_backup
    
    # Install packages
    install_packages
    
    # Perform cleanup if requested
    perform_cleanup
    
    # Track state changes if enabled
    track_state
    
    # Generate summary report
    generate_summary
    
    success "Installation completed successfully"
    
    # Suggest next steps
    echo ""
    info "Next steps:"
    info "  • Run 'brew doctor' to check for issues"
    info "  • Run 'brew upgrade' to update packages"
    info "  • Use '$STATE_TRACKER monitor' to track changes"
    info "  • Use '$CLEANUP_SCRIPT --dry-run' to preview cleanups"
}

#=============================================================================
# CLEANUP & ERROR HANDLING
#=============================================================================

# Cleanup function
cleanup() {
    local exit_code=$?
    
    debug "Cleaning up..."
    
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
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
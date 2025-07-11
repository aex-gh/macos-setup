#!/usr/bin/env zsh
# -*- coding: utf-8 -*-

# ABOUTME: This script provides idempotent Homebrew package management using native brew bundle functionality
# ABOUTME: It merges multiple Brewfiles and provides install/cleanup operations with safety features

#=============================================================================
# SCRIPT: homebrew-idempotent.zsh
# VERSION: 1.0.0
# 
# DESCRIPTION:
#   Simplified idempotent Homebrew package manager that uses native brew bundle
#   functionality to install missing packages and remove unlisted ones.
#   Supports multiple Brewfiles and system type selection.
#
# USAGE:
#   ./homebrew-idempotent.zsh [options] [command]
#
# COMMANDS:
#   install    Install missing packages only (default)
#   cleanup    Remove packages not in Brewfiles
#   sync       Install missing and remove unlisted packages
#   diff       Show what would be installed/removed
#   backup     Export current state to Brewfile
#
# OPTIONS:
#   -h, --help          Show this help message
#   -v, --verbose       Enable verbose output
#   -n, --dry-run       Show what would be done without executing
#   -f, --force         Skip confirmation prompts
#   -q, --quiet         Suppress non-error output
#   --system TYPE       System type (base|dev|productivity|utilities|all)
#   --brewfiles FILES   Comma-separated list of specific Brewfiles to use
#   --output FILE       Output file for backup command
#
# SYSTEM TYPES:
#   base            Essential tools for all systems
#   dev             Development environment packages
#   productivity    Office and productivity applications
#   utilities       System utilities and specialised tools
#   all             All available packages
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
declare -g QUIET=false
declare -g SYSTEM_TYPE="base"
declare -g BREWFILES=""
declare -g OUTPUT_FILE=""
declare -g COMMAND="install"
declare -g LOG_FILE="/tmp/${SCRIPT_NAME%.zsh}.log"
declare -g TEMP_BREWFILE=""

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
            [[ $QUIET == false ]] && echo "${YELLOW}${BOLD}[WARN]${RESET} $message" >&2
            ;;
        INFO)
            [[ $QUIET == false ]] && echo "${BLUE}${BOLD}[INFO]${RESET} $message"
            ;;
        DEBUG)
            [[ $VERBOSE == true ]] && echo "${CYAN}[DEBUG]${RESET} $message"
            ;;
        SUCCESS)
            [[ $QUIET == false ]] && echo "${GREEN}${BOLD}[✓]${RESET} $message"
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
    $SCRIPT_NAME - Idempotent Homebrew package manager

${BOLD}SYNOPSIS${RESET}
    $SCRIPT_NAME [options] [command]

${BOLD}DESCRIPTION${RESET}
    This script provides idempotent Homebrew package management using native
    brew bundle functionality. It can install missing packages, remove unlisted
    ones, and maintain consistent package states across different system types.

${BOLD}COMMANDS${RESET}
    install         Install missing packages only (default)
    cleanup         Remove packages not in Brewfiles
    sync            Install missing and remove unlisted packages
    diff            Show what would be installed/removed
    backup          Export current state to Brewfile

${BOLD}OPTIONS${RESET}
    -h, --help          Show this help message
    -v, --verbose       Enable verbose output
    -n, --dry-run       Show what would be done without executing
    -f, --force         Skip confirmation prompts
    -q, --quiet         Suppress non-error output
    --system TYPE       System type (base|dev|productivity|utilities|all)
    --brewfiles FILES   Comma-separated list of specific Brewfiles to use
    --output FILE       Output file for backup command

${BOLD}SYSTEM TYPES${RESET}
    base            Essential tools for all systems
    dev             Development environment packages
    productivity    Office and productivity applications
    utilities       System utilities and specialised tools
    all             All available packages

${BOLD}EXAMPLES${RESET}
    # Install base packages only
    $SCRIPT_NAME --system base

    # Full sync with dry run
    $SCRIPT_NAME sync --dry-run

    # Development environment cleanup
    $SCRIPT_NAME cleanup --system dev --verbose

    # Show differences for all packages
    $SCRIPT_NAME diff --system all

    # Backup current state
    $SCRIPT_NAME backup --output ~/my-brewfile.brewfile

    # Use specific Brewfiles
    $SCRIPT_NAME --brewfiles base.brewfile,dev.brewfile

${BOLD}AUTHOR${RESET}
    macOS Setup Project

${BOLD}VERSION${RESET}
    $SCRIPT_VERSION
EOF
}

# Check for required commands
check_requirements() {
    local requirements=("brew")
    local missing=()
    
    for cmd in "${requirements[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing+=("$cmd")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        error "Missing required commands: ${missing[*]}"
        if [[ " ${missing[*]} " =~ " brew " ]]; then
            info "Install Homebrew from: https://brew.sh"
        fi
        exit 1
    fi
}

# Install Homebrew if missing
install_homebrew() {
    if command -v brew &> /dev/null; then
        debug "Homebrew already installed"
        return 0
    fi
    
    if [[ $DRY_RUN == true ]]; then
        info "Would install Homebrew"
        return 0
    fi
    
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add to PATH for Apple Silicon Macs
    if [[ -f /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    
    # Disable analytics
    brew analytics off
    
    success "Homebrew installed successfully"
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

# Create merged Brewfile from multiple sources
create_merged_brewfile() {
    local brewfiles_list=$(determine_brewfiles)
    local temp_file=$(mktemp -t homebrew-merged.XXXXXX)
    
    debug "Creating merged Brewfile: $temp_file"
    
    # Write header
    cat > "$temp_file" << EOF
# Merged Brewfile generated by $SCRIPT_NAME
# Generated: $(date)
# System type: $SYSTEM_TYPE
# Source files: $brewfiles_list

EOF
    
    # Process each Brewfile
    local -a BREWFILE_ARRAY
    IFS=',' read -A BREWFILE_ARRAY <<< "$brewfiles_list"
    for brewfile in "${BREWFILE_ARRAY[@]}"; do
        local brewfile_path
        
        # Determine full path
        if [[ "$brewfile" == /* ]]; then
            brewfile_path="$brewfile"
        elif [[ -f "$brewfile" ]]; then
            brewfile_path="$brewfile"
        else
            brewfile_path="$BREWFILES_DIR/$brewfile"
        fi
        
        # Check if file exists
        if [[ ! -f "$brewfile_path" ]]; then
            error "Brewfile not found: $brewfile_path"
            rm -f "$temp_file"
            exit 1
        fi
        
        debug "Adding $brewfile_path to merged Brewfile"
        
        # Add section header
        echo "" >> "$temp_file"
        echo "# From: $brewfile" >> "$temp_file"
        echo "" >> "$temp_file"
        
        # Add content (skip comments and empty lines for cleaner output)
        grep -E '^(tap|brew|cask|mas|vscode)' "$brewfile_path" >> "$temp_file" || true
    done
    
    TEMP_BREWFILE="$temp_file"
    debug "Merged Brewfile created with $(wc -l < "$temp_file") lines"
}

# Confirm dangerous operations
confirm_operation() {
    local operation=$1
    
    if [[ $FORCE == true ]]; then
        return 0
    fi
    
    warn "This will $operation"
    echo -n "Are you sure you want to continue? (y/N): "
    read -r response
    
    case "$response" in
        [yY]|[yY][eE][sS])
            return 0
            ;;
        *)
            info "Operation cancelled"
            return 1
            ;;
    esac
}

# Install packages
install_packages() {
    info "Installing packages..."
    
    create_merged_brewfile
    
    local cmd_args=("brew" "bundle" "install" "--file" "$TEMP_BREWFILE")
    [[ $VERBOSE == true ]] && cmd_args+=("--verbose")
    [[ $DRY_RUN == true ]] && cmd_args+=("--dry-run")
    
    if [[ $DRY_RUN == true ]]; then
        info "DRY RUN MODE - Would install packages from merged Brewfile"
        debug "Command: ${cmd_args[*]}"
    else
        debug "Executing: ${cmd_args[*]}"
        "${cmd_args[@]}"
        success "Package installation completed"
    fi
}

# Clean up packages
cleanup_packages() {
    info "Cleaning up packages..."
    
    create_merged_brewfile
    
    # Show what would be removed
    local cleanup_cmd=("brew" "bundle" "cleanup" "--file" "$TEMP_BREWFILE")
    [[ $FORCE == true ]] && cleanup_cmd+=("--force")
    
    if [[ $DRY_RUN == true ]]; then
        info "DRY RUN MODE - Would clean up packages not in Brewfiles"
        debug "Command: ${cleanup_cmd[*]}"
        return 0
    fi
    
    # Get list of packages to remove
    local packages_to_remove
    packages_to_remove=$(brew bundle cleanup --file "$TEMP_BREWFILE" --dry-run 2>/dev/null | grep -E '^(Un|Would remove)' | wc -l | tr -d ' ')
    
    if [[ $packages_to_remove -eq 0 ]]; then
        success "No packages to remove"
        return 0
    fi
    
    # Confirm removal
    if ! confirm_operation "remove $packages_to_remove packages not in Brewfiles"; then
        return 0
    fi
    
    debug "Executing: ${cleanup_cmd[*]}"
    "${cleanup_cmd[@]}"
    success "Package cleanup completed"
}

# Sync packages (install + cleanup)
sync_packages() {
    info "Synchronising packages..."
    install_packages
    cleanup_packages
}

# Show differences
show_diff() {
    info "Showing package differences..."
    
    create_merged_brewfile
    
    # Show what would be installed
    info "Packages to install:"
    brew bundle install --file "$TEMP_BREWFILE" --dry-run 2>/dev/null | grep -E '^(Installing|Would install)' || echo "  None"
    
    echo ""
    
    # Show what would be removed
    info "Packages to remove:"
    brew bundle cleanup --file "$TEMP_BREWFILE" --dry-run 2>/dev/null | grep -E '^(Un|Would remove)' || echo "  None"
}

# Backup current state
backup_current_state() {
    local output_file="${OUTPUT_FILE:-homebrew-backup-$(date +%Y%m%d-%H%M%S).brewfile}"
    
    info "Creating backup: $output_file"
    
    if [[ $DRY_RUN == true ]]; then
        info "DRY RUN MODE - Would create backup at $output_file"
        return 0
    fi
    
    # Generate Brewfile from current state
    brew bundle dump --file "$output_file" --force
    
    success "Backup created: $output_file"
    
    # Show summary
    local taps=$(grep -c '^tap' "$output_file" 2>/dev/null || true)
    local brews=$(grep -c '^brew' "$output_file" 2>/dev/null || true)
    local casks=$(grep -c '^cask' "$output_file" 2>/dev/null || true)
    local mas=$(grep -c '^mas' "$output_file" 2>/dev/null || true)
    local vscode=$(grep -c '^vscode' "$output_file" 2>/dev/null || true)
    
    # Set to 0 if empty
    [[ -z "$taps" ]] && taps=0
    [[ -z "$brews" ]] && brews=0
    [[ -z "$casks" ]] && casks=0
    [[ -z "$mas" ]] && mas=0
    [[ -z "$vscode" ]] && vscode=0
    
    info "Backup contains:"
    info "  Taps: $taps"
    info "  Formulae: $brews"
    info "  Casks: $casks"
    info "  MAS apps: $mas"
    info "  VS Code extensions: $vscode"
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            install|cleanup|sync|diff|backup)
                COMMAND="$1"
                shift
                ;;
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
            -q|--quiet)
                QUIET=true
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
            --output)
                OUTPUT_FILE="$2"
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
    
    # Install Homebrew if missing
    install_homebrew
    
    # Check requirements
    check_requirements
    
    info "Starting $SCRIPT_NAME v$SCRIPT_VERSION"
    debug "Command: $COMMAND"
    debug "System type: $SYSTEM_TYPE"
    debug "Brewfiles: $(determine_brewfiles)"
    
    if [[ $DRY_RUN == true ]]; then
        info "DRY RUN MODE - No changes will be made"
    fi
    
    # Execute command
    case $COMMAND in
        install)
            install_packages
            ;;
        cleanup)
            cleanup_packages
            ;;
        sync)
            sync_packages
            ;;
        diff)
            show_diff
            ;;
        backup)
            backup_current_state
            ;;
        *)
            error "Unknown command: $COMMAND"
            usage
            exit 1
            ;;
    esac
    
    success "Operation completed successfully"
}

#=============================================================================
# CLEANUP & ERROR HANDLING
#=============================================================================

# Cleanup function
cleanup() {
    local exit_code=$?
    
    debug "Cleaning up..."
    
    # Remove temporary Brewfile
    [[ -n "$TEMP_BREWFILE" && -f "$TEMP_BREWFILE" ]] && rm -f "$TEMP_BREWFILE"
    
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
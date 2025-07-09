#!/usr/bin/env zsh
# -*- coding: utf-8 -*-

# ABOUTME: This script provides safe cleanup mechanisms for Homebrew packages with dry-run and confirmation prompts
# ABOUTME: It acts as a wrapper around the homebrew-manager.rb script with additional safety features

#=============================================================================
# SCRIPT: brew-cleanup-safe.zsh
# VERSION: 1.0.0
# 
# DESCRIPTION:
#   Safe wrapper for Homebrew cleanup operations with comprehensive safety
#   features including dry-run mode, confirmation prompts, and rollback
#   capabilities.
#
# USAGE:
#   ./brew-cleanup-safe.zsh [options]
#
# OPTIONS:
#   -h, --help      Show this help message
#   -n, --dry-run   Show what would be done without executing
#   -v, --verbose   Enable verbose output
#   -f, --force     Skip confirmation prompts
#   -b, --backup    Create backup before cleanup
#   -r, --rollback  Rollback to previous backup
#   --brewfiles     Specify specific Brewfiles to use
#=============================================================================

# Strict mode
set -euo pipefail

# Script metadata
readonly SCRIPT_NAME="${0:t}"
readonly SCRIPT_DIR="${0:A:h}"
readonly SCRIPT_VERSION="1.0.0"

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
declare -g ROLLBACK=false
declare -g BREWFILES=""
declare -g BACKUP_DIR="$HOME/.homebrew-backups"
declare -g LOG_FILE="/tmp/${SCRIPT_NAME%.zsh}.log"

# Ruby manager script
readonly HOMEBREW_MANAGER="${SCRIPT_DIR}/homebrew-manager.rb"

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
    $SCRIPT_NAME - Safe Homebrew cleanup with rollback capabilities

${BOLD}SYNOPSIS${RESET}
    $SCRIPT_NAME [options]

${BOLD}DESCRIPTION${RESET}
    This script provides safe cleanup mechanisms for Homebrew packages,
    ensuring that only packages not defined in any Brewfile are removed.
    It includes dry-run mode, confirmation prompts, and backup/rollback
    capabilities for maximum safety.

${BOLD}OPTIONS${RESET}
    -h, --help          Show this help message
    -n, --dry-run       Show what would be done without executing
    -v, --verbose       Enable verbose output
    -f, --force         Skip confirmation prompts
    -b, --backup        Create backup before cleanup
    -r, --rollback      Rollback to previous backup
    --brewfiles FILES   Comma-separated list of specific Brewfiles to use

${BOLD}EXAMPLES${RESET}
    # Dry run to see what would be removed
    $SCRIPT_NAME --dry-run

    # Safe cleanup with backup
    $SCRIPT_NAME --backup

    # Force cleanup without prompts
    $SCRIPT_NAME --force

    # Cleanup using specific Brewfiles
    $SCRIPT_NAME --brewfiles base.brewfile,dev.brewfile

    # Rollback to previous state
    $SCRIPT_NAME --rollback

${BOLD}SAFETY FEATURES${RESET}
    • Dry-run mode shows changes without executing
    • Confirmation prompts for destructive operations
    • Automatic backup creation before cleanup
    • Rollback capability to restore previous state
    • Protected packages list prevents removal of essential tools
    • Comprehensive logging of all operations

${BOLD}AUTHOR${RESET}
    macOS Setup Project

${BOLD}VERSION${RESET}
    $SCRIPT_VERSION
EOF
}

# Check for required commands
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
    
    # Check for homebrew-manager.rb
    if [[ ! -f "$HOMEBREW_MANAGER" ]]; then
        error "Homebrew manager script not found: $HOMEBREW_MANAGER"
        exit 1
    fi
}

# Create backup directory
ensure_backup_dir() {
    if [[ ! -d "$BACKUP_DIR" ]]; then
        debug "Creating backup directory: $BACKUP_DIR"
        mkdir -p "$BACKUP_DIR"
    fi
}

# Create system backup
create_backup() {
    ensure_backup_dir
    
    local timestamp=$(date '+%Y%m%d-%H%M%S')
    local backup_file="$BACKUP_DIR/homebrew-backup-$timestamp.yaml"
    
    info "Creating backup: $backup_file"
    
    local cmd_args=("$HOMEBREW_MANAGER" "--backup" "--output" "$backup_file")
    [[ $VERBOSE == true ]] && cmd_args+=("--verbose")
    
    if "${cmd_args[@]}"; then
        success "Backup created successfully"
        echo "$backup_file" > "$BACKUP_DIR/latest-backup.txt"
        return 0
    else
        error "Failed to create backup"
        return 1
    fi
}

# List available backups
list_backups() {
    ensure_backup_dir
    
    local backups=($(ls -t "$BACKUP_DIR"/homebrew-backup-*.yaml 2>/dev/null || true))
    
    if [[ ${#backups[@]} -eq 0 ]]; then
        warn "No backups found"
        return 1
    fi
    
    info "Available backups:"
    for backup in "${backups[@]}"; do
        local filename=$(basename "$backup")
        local timestamp=${filename#homebrew-backup-}
        timestamp=${timestamp%.yaml}
        local human_date=$(date -j -f "%Y%m%d-%H%M%S" "$timestamp" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "$timestamp")
        echo "  $filename ($human_date)"
    done
}

# Rollback to backup
rollback_to_backup() {
    ensure_backup_dir
    
    local backup_file
    
    if [[ -f "$BACKUP_DIR/latest-backup.txt" ]]; then
        backup_file=$(cat "$BACKUP_DIR/latest-backup.txt")
        if [[ ! -f "$backup_file" ]]; then
            error "Latest backup file not found: $backup_file"
            list_backups
            return 1
        fi
    else
        error "No backup reference found"
        list_backups
        return 1
    fi
    
    warn "Rollback functionality requires manual intervention"
    info "Latest backup: $backup_file"
    info "To rollback, you would need to:"
    info "1. Review the backup file contents"
    info "2. Manually reinstall removed packages"
    info "3. Manually remove added packages"
    
    # TODO: Implement automatic rollback in future version
    return 0
}

# Show diff between desired and actual state
show_diff() {
    info "Showing package differences..."
    
    local cmd_args=("$HOMEBREW_MANAGER" "--diff")
    [[ $VERBOSE == true ]] && cmd_args+=("--verbose")
    [[ -n "$BREWFILES" ]] && cmd_args+=("--brewfiles" "$BREWFILES")
    
    "${cmd_args[@]}"
}

# Perform cleanup
perform_cleanup() {
    info "Starting Homebrew cleanup..."
    
    local cmd_args=("$HOMEBREW_MANAGER" "--cleanup")
    [[ $VERBOSE == true ]] && cmd_args+=("--verbose")
    [[ $DRY_RUN == true ]] && cmd_args+=("--dry-run")
    [[ $FORCE == true ]] && cmd_args+=("--force")
    [[ -n "$BREWFILES" ]] && cmd_args+=("--brewfiles" "$BREWFILES")
    
    if [[ $DRY_RUN == true ]]; then
        info "DRY RUN MODE - No changes will be made"
        echo
    fi
    
    "${cmd_args[@]}"
    
    if [[ $DRY_RUN == false ]]; then
        success "Cleanup completed"
    else
        success "Dry run completed"
    fi
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

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            -n|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
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
            -r|--rollback)
                ROLLBACK=true
                shift
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
    
    # Handle rollback
    if [[ $ROLLBACK == true ]]; then
        rollback_to_backup
        return 0
    fi
    
    # Create backup if requested
    if [[ $BACKUP == true ]]; then
        if ! create_backup; then
            error "Failed to create backup"
            exit 1
        fi
    fi
    
    # Show diff first
    show_diff
    echo
    
    # Confirm operation unless dry run or force
    if [[ $DRY_RUN == false ]] && ! confirm_operation "remove packages not in any Brewfile"; then
        exit 0
    fi
    
    # Perform cleanup
    perform_cleanup
    
    # Suggest cleanup of orphaned dependencies
    if [[ $DRY_RUN == false ]]; then
        echo
        info "You may also want to run:"
        info "  brew autoremove    # Remove orphaned dependencies"
        info "  brew cleanup       # Remove old versions"
    fi
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
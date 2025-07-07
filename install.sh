#!/bin/bash
# -*- coding: utf-8 -*-

#=============================================================================
# SCRIPT: install.sh
# AUTHOR: Andrew Exley (with Claude)
# DATE: 2025-01-07
# VERSION: 1.0.0
#
# DESCRIPTION:
#   One-line installer for macOS dotfiles setup system.
#   Downloads and launches the comprehensive modular setup with hardware detection
#   and profile-based configuration.
#
# USAGE:
#   curl -fsSL https://raw.githubusercontent.com/aex-gh/dotfiles/main/install.sh | bash
#   
#   # Or with options:
#   curl -fsSL https://raw.githubusercontent.com/aex-gh/dotfiles/main/install.sh | bash -s -- --profile developer --force
#
# OPTIONS:
#   -h, --help              Show this help message
#   -p, --profile PROFILE   Setup profile (developer, data-scientist, personal, minimal)
#   -f, --force             Skip confirmation prompts
#   -n, --dry-run           Preview changes without applying them
#   -v, --verbose           Enable verbose output
#   --no-backup             Skip backing up existing dotfiles
#   --branch BRANCH         Install from specific git branch (default: main)
#
# REQUIREMENTS:
#   - macOS 11.0+ (Big Sur)
#   - Git (will prompt to install Xcode Command Line Tools if missing)
#   - Internet connection
#
# SECURITY:
#   This script can be inspected before execution:
#   curl -fsSL https://raw.githubusercontent.com/aex-gh/dotfiles/main/install.sh -o install.sh
#   less install.sh  # Review the script
#   chmod +x install.sh && ./install.sh
#
#=============================================================================

# Strict mode for safety
set -euo pipefail

# Script metadata
readonly SCRIPT_NAME="install.sh"
readonly SCRIPT_VERSION="1.0.0"
readonly INSTALLER_LOG="$HOME/.config/dotfiles-setup/installer_$(date +%Y%m%d_%H%M%S).log"

# Repository configuration
readonly DEFAULT_REPO="https://github.com/aex-gh/dotfiles.git"
readonly DEFAULT_BRANCH="main"
readonly DOTFILES_DIR="$HOME/.dotfiles"

# Colour codes for output (using tput for compatibility)
if command -v tput &> /dev/null && [[ -t 1 ]]; then
    readonly RED=$(tput setaf 1)
    readonly GREEN=$(tput setaf 2)
    readonly YELLOW=$(tput setaf 3)
    readonly BLUE=$(tput setaf 4)
    readonly MAGENTA=$(tput setaf 5)
    readonly CYAN=$(tput setaf 6)
    readonly BOLD=$(tput bold)
    readonly RESET=$(tput sgr0)
else
    # Fallback for environments without tput or non-interactive shells
    readonly RED=""
    readonly GREEN=""
    readonly YELLOW=""
    readonly BLUE=""
    readonly MAGENTA=""
    readonly CYAN=""
    readonly BOLD=""
    readonly RESET=""
fi

# Global variables
PROFILE=""
FORCE=false
DRY_RUN=false
VERBOSE=false
NO_BACKUP=false
BRANCH="$DEFAULT_BRANCH"
REPO_URL="$DEFAULT_REPO"

#=============================================================================
# LOGGING FUNCTIONS
#=============================================================================

# Ensure log directory exists
mkdir -p "$(dirname "$INSTALLER_LOG")"

log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Log to file
    echo "[$timestamp] [$level] $message" >> "$INSTALLER_LOG"
    
    # Log to console based on level
    case $level in
        ERROR)
            echo -e "${RED}${BOLD}[ERROR]${RESET} $message" >&2
            ;;
        WARN)
            echo -e "${YELLOW}${BOLD}[WARN]${RESET} $message" >&2
            ;;
        INFO)
            echo -e "${BLUE}${BOLD}[INFO]${RESET} $message"
            ;;
        SUCCESS)
            echo -e "${GREEN}${BOLD}[✓]${RESET} $message"
            ;;
        STEP)
            echo -e "${MAGENTA}${BOLD}[STEP]${RESET} $message"
            ;;
        DEBUG)
            [[ $VERBOSE == true ]] && echo -e "${CYAN}[DEBUG]${RESET} $message" || true
            ;;
    esac
}

error() { log ERROR "$@"; }
warn() { log WARN "$@"; }
info() { log INFO "$@"; }
success() { log SUCCESS "$@"; }
step() { log STEP "$@"; }
debug() { log DEBUG "$@"; }

#=============================================================================
# UTILITY FUNCTIONS
#=============================================================================

# Display script header
show_header() {
    echo ""
    echo "${BOLD}${BLUE}🍎 macOS Dotfiles One-Line Installer v$SCRIPT_VERSION${RESET}"
    echo "${BOLD}${BLUE}════════════════════════════════════════════════════════════════════════════════${RESET}"
    echo ""
    echo "This installer will set up your Mac with a comprehensive development environment"
    echo "using hardware detection and profile-based configuration."
    echo ""
}

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
        error "This installer requires macOS (detected: $(uname))"
        error "This dotfiles setup is specifically designed for macOS systems."
        exit 1
    fi
    
    # Check macOS version
    local macos_version=$(sw_vers -productVersion)
    local required_version="11.0"
    
    if ! is_version_gte "$macos_version" "$required_version"; then
        error "macOS $required_version or later required (current: $macos_version)"
        error "Please update your macOS before proceeding."
        exit 1
    fi
    
    success "macOS compatibility check passed (version: $macos_version)"
}

# Version comparison utility
is_version_gte() {
    [ "$1" = "$(echo -e "$1\n$2" | sort -V | tail -n1)" ]
}

# Check for Git and Xcode Command Line Tools
check_dependencies() {
    step "Checking system dependencies..."
    
    # Check for Git
    if ! command -v git &> /dev/null; then
        warn "Git not found. Xcode Command Line Tools are required."
        
        if confirm "Install Xcode Command Line Tools now?"; then
            info "Installing Xcode Command Line Tools..."
            xcode-select --install
            
            echo ""
            warn "Please complete the Xcode Command Line Tools installation"
            warn "and re-run this installer when finished."
            echo ""
            echo "Run this command again:"
            echo "  curl -fsSL https://raw.githubusercontent.com/aex-gh/dotfiles/main/install.sh | bash"
            exit 0
        else
            error "Git is required for installation. Please install Xcode Command Line Tools."
            exit 1
        fi
    fi
    
    # Check Git version
    local git_version=$(git --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
    debug "Git version: $git_version"
    
    # Check for curl (should be available on macOS)
    if ! command -v curl &> /dev/null; then
        error "curl is required but not available"
        exit 1
    fi
    
    success "System dependencies check passed"
}

# Backup existing dotfiles
backup_existing_dotfiles() {
    if [[ $NO_BACKUP == true ]]; then
        debug "Skipping backup (--no-backup specified)"
        return 0
    fi
    
    if [[ -d "$DOTFILES_DIR" ]]; then
        local backup_dir="${DOTFILES_DIR}.backup.$(date +%Y%m%d_%H%M%S)"
        
        step "Backing up existing dotfiles..."
        warn "Found existing dotfiles directory: $DOTFILES_DIR"
        
        if [[ $FORCE == false ]] && ! confirm "Backup existing dotfiles to $backup_dir?"; then
            error "Installation cancelled by user"
            exit 1
        fi
        
        if mv "$DOTFILES_DIR" "$backup_dir" 2>/dev/null; then
            success "Existing dotfiles backed up to: $backup_dir"
            info "You can restore them later with: mv '$backup_dir' '$DOTFILES_DIR'"
        else
            error "Failed to backup existing dotfiles"
            exit 1
        fi
    else
        debug "No existing dotfiles directory found"
    fi
}

# Clone the dotfiles repository
clone_repository() {
    step "Downloading dotfiles repository..."
    
    debug "Repository: $REPO_URL"
    debug "Branch: $BRANCH"
    debug "Destination: $DOTFILES_DIR"
    
    if [[ $DRY_RUN == true ]]; then
        info "DRY RUN: Would clone $REPO_URL (branch: $BRANCH) to $DOTFILES_DIR"
        return 0
    fi
    
    # Clone with specific branch
    if git clone --branch "$BRANCH" --single-branch "$REPO_URL" "$DOTFILES_DIR"; then
        success "Repository cloned successfully"
    else
        error "Failed to clone repository"
        error "Please check your internet connection and repository access"
        exit 1
    fi
    
    # Verify the clone
    if [[ ! -f "$DOTFILES_DIR/scripts/00-bootstrap.zsh" ]]; then
        error "Invalid repository structure - bootstrap script not found"
        error "Expected: $DOTFILES_DIR/scripts/00-bootstrap.zsh"
        exit 1
    fi
    
    debug "Repository structure verified"
}

# Launch the bootstrap script
launch_bootstrap() {
    step "Launching dotfiles setup..."
    
    if [[ $DRY_RUN == true ]]; then
        info "DRY RUN: Would change to directory: $DOTFILES_DIR"
    else
        cd "$DOTFILES_DIR"
        # Make bootstrap script executable
        chmod +x scripts/00-bootstrap.zsh
    fi
    
    # Prepare bootstrap arguments
    local bootstrap_args=()
    
    [[ $VERBOSE == true ]] && bootstrap_args+=("--verbose")
    [[ $DRY_RUN == true ]] && bootstrap_args+=("--dry-run")
    [[ $FORCE == true ]] && bootstrap_args+=("--force")
    [[ -n $PROFILE ]] && bootstrap_args+=("--profile" "$PROFILE")
    
    debug "Bootstrap arguments: ${bootstrap_args[*]}"
    
    if [[ $DRY_RUN == true ]]; then
        info "DRY RUN: Would execute: ./scripts/00-bootstrap.zsh ${bootstrap_args[*]}"
        return 0
    fi
    
    info "Executing bootstrap script with profile: ${PROFILE:-interactive selection}"
    echo ""
    
    # Execute the bootstrap script
    if ./scripts/00-bootstrap.zsh "${bootstrap_args[@]}"; then
        success "Dotfiles setup completed successfully!"
    else
        error "Bootstrap script failed"
        error "Check the logs for details: ~/.config/dotfiles-setup/"
        exit 1
    fi
}

# Display installation summary
show_summary() {
    echo ""
    echo "${BOLD}${GREEN}🎉 Installation Summary${RESET}"
    echo "${BOLD}${GREEN}════════════════════════════════════════════════════════════════════════════════${RESET}"
    echo ""
    echo "📁 Dotfiles location: $DOTFILES_DIR"
    echo "📋 Profile: ${PROFILE:-Interactive selection}"
    echo "📝 Installer log: $INSTALLER_LOG"
    echo "📝 Setup logs: ~/.config/dotfiles-setup/"
    echo ""
    
    if [[ $DRY_RUN == true ]]; then
        echo "${BOLD}🔍 Dry Run Complete${RESET}"
        echo "No changes were made to your system."
        echo "Run without --dry-run to apply changes:"
        echo "  curl -fsSL https://raw.githubusercontent.com/aex-gh/dotfiles/main/install.sh | bash"
    else
        echo "${BOLD}🔄 Next Steps:${RESET}"
        echo "1. Restart your terminal or run: ${CYAN}exec zsh${RESET}"
        echo "2. Review any setup warnings in the logs"
        echo "3. Customize settings as needed"
        echo ""
        echo "${BOLD}🛠️  Additional Configuration:${RESET}"
        echo "• Set up 1Password and sync SSH keys"
        echo "• Configure Git signing and remotes" 
        echo "• Authenticate with cloud services (AWS, Azure, GCP)"
        echo "• Import IDE settings and extensions"
    fi
    echo ""
}

#=============================================================================
# ARGUMENT PARSING
#=============================================================================

# Display usage information
usage() {
    cat << EOF
${BOLD}NAME${RESET}
    $SCRIPT_NAME - One-line installer for macOS dotfiles

${BOLD}SYNOPSIS${RESET}
    curl -fsSL https://raw.githubusercontent.com/aex-gh/dotfiles/main/install.sh | bash
    curl -fsSL https://raw.githubusercontent.com/aex-gh/dotfiles/main/install.sh | bash -s -- [options]

${BOLD}DESCRIPTION${RESET}
    Downloads and installs a comprehensive macOS dotfiles setup with hardware 
    detection, multiple user profiles, and automated configuration management.

${BOLD}OPTIONS${RESET}
    -h, --help              Show this help message
    -p, --profile PROFILE   Setup profile (developer, data-scientist, personal, minimal)
    -f, --force             Skip confirmation prompts
    -n, --dry-run           Preview changes without applying them
    -v, --verbose           Enable verbose output
    --no-backup             Skip backing up existing dotfiles
    --branch BRANCH         Install from specific git branch (default: main)

${BOLD}PROFILES${RESET}
    developer               Full development environment setup
    data-scientist          ML/DS focused setup with data tools  
    personal                Basic productivity and personal use
    minimal                 Essential tools only

${BOLD}EXAMPLES${RESET}
    # Interactive installation with profile selection
    curl -fsSL https://raw.githubusercontent.com/aex-gh/dotfiles/main/install.sh | bash

    # Automated developer setup
    curl -fsSL https://raw.githubusercontent.com/aex-gh/dotfiles/main/install.sh | bash -s -- --profile developer --force

    # Preview what would be installed
    curl -fsSL https://raw.githubusercontent.com/aex-gh/dotfiles/main/install.sh | bash -s -- --dry-run

    # Install from development branch
    curl -fsSL https://raw.githubusercontent.com/aex-gh/dotfiles/main/install.sh | bash -s -- --branch develop

${BOLD}SECURITY${RESET}
    To inspect this script before execution:
    curl -fsSL https://raw.githubusercontent.com/aex-gh/dotfiles/main/install.sh -o install.sh
    less install.sh  # Review the script
    chmod +x install.sh && ./install.sh

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
            -p|--profile)
                PROFILE="$2"
                shift 2
                ;;
            -f|--force)
                FORCE=true
                shift
                ;;
            -n|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            --no-backup)
                NO_BACKUP=true
                shift
                ;;
            --branch)
                BRANCH="$2"
                shift 2
                ;;
            --repo)
                REPO_URL="$2"
                shift 2
                ;;
            -*)
                error "Unknown option: $1"
                echo "Run with --help for usage information"
                exit 1
                ;;
            *)
                error "Unexpected argument: $1"
                echo "Run with --help for usage information"
                exit 1
                ;;
        esac
    done
    
    # Validate profile if specified
    if [[ -n $PROFILE ]]; then
        case $PROFILE in
            developer|data-scientist|personal|minimal|custom)
                debug "Valid profile specified: $PROFILE"
                ;;
            *)
                error "Invalid profile: $PROFILE"
                error "Valid profiles: developer, data-scientist, personal, minimal, custom"
                exit 1
                ;;
        esac
    fi
    
    debug "Parsed arguments: PROFILE=$PROFILE, FORCE=$FORCE, DRY_RUN=$DRY_RUN, VERBOSE=$VERBOSE"
}

#=============================================================================
# MAIN EXECUTION
#=============================================================================

# Main installation function
main() {
    # Parse command line arguments
    parse_args "$@"
    
    # Show header
    show_header
    
    # Log installation start
    info "Starting macOS dotfiles installation"
    debug "Installer version: $SCRIPT_VERSION"
    debug "Log file: $INSTALLER_LOG"
    
    # System checks
    check_macos
    check_dependencies
    
    # Backup and clone
    backup_existing_dotfiles
    clone_repository
    
    # Launch setup
    launch_bootstrap
    
    # Show summary
    show_summary
    
    success "Installation completed successfully!"
}

#=============================================================================
# ERROR HANDLING
#=============================================================================

# Cleanup function
cleanup() {
    local exit_code=$?
    
    if [[ $exit_code -ne 0 ]]; then
        echo ""
        error "Installation failed with exit code: $exit_code"
        error "Check the installer log for details: $INSTALLER_LOG"
        echo ""
        echo "For help, please visit: https://github.com/aex-gh/dotfiles/issues"
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

# Execute main function with all arguments
main "$@"
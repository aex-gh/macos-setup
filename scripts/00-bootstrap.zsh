#!/usr/bin/env zsh
# -*- coding: utf-8 -*-

#=============================================================================
# SCRIPT: 00-bootstrap.zsh
# AUTHOR: Andrew Exley
# DATE: 2025-01-07
# VERSION: 1.0.0
#
# DESCRIPTION:
#   Modular macOS setup bootstrap script that orchestrates the entire
#   new Mac configuration process based on hardware detection and user profiles
#
# USAGE:
#   ./00-bootstrap.zsh [options]
#
# OPTIONS:
#   -h, --help         Show this help message
#   -v, --verbose      Enable verbose output
#   -d, --debug        Enable debug mode
#   -n, --dry-run      Preview changes without applying them
#   -p, --profile      Setup profile (developer, data-scientist, personal, custom)
#   -f, --force        Skip confirmation prompts
#   --skip-updates     Skip system updates check
#   --modules-only     Run only specific modules (comma-separated)
#
# REQUIREMENTS:
#   - macOS 11.0+ (Big Sur)
#   - Zsh 5.8+
#   - Admin privileges for some operations
#
# NOTES:
#   - Detects hardware and applies appropriate configurations
#   - Supports multiple setup profiles for different use cases
#   - Creates comprehensive logs and backup points
#   - All operations are reversible
#=============================================================================

# Strict mode
set -euo pipefail

# Script metadata
readonly SCRIPT_NAME="${0:t}"
readonly SCRIPT_DIR="${0:A:h}"
readonly SCRIPT_VERSION="1.0.0"
readonly DOTFILES_ROOT="${SCRIPT_DIR:h}"
readonly LOG_DIR="$HOME/.config/dotfiles-setup"
readonly TIMESTAMP=$(date '+%Y%m%d_%H%M%S')

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
declare -g SKIP_UPDATES=false
declare -g PROFILE=""
declare -g MODULES_ONLY=""
declare -g LOG_FILE="$LOG_DIR/bootstrap_$TIMESTAMP.log"

# Hardware detection variables
declare -g HARDWARE_TYPE=""
declare -g HARDWARE_MODEL=""
declare -g CHIP_TYPE=""
declare -g MEMORY_GB=""

# Setup modules configuration
declare -ga AVAILABLE_MODULES=(
    "01-system-detection"
    "02-xcode-tools"
    "03-homebrew-setup"
    "04-system-setup"
    "05-macos-defaults"
    "06-applications"
    "07-security-hardening"
    "08-development-env"
    "09-post-setup"
)

declare -gA PROFILE_MODULES=(
    [developer]="01,02,03,04,05,06,08,09"
    [data-scientist]="01,02,03,04,05,06,07,08,09"
    [personal]="01,02,03,04,05,09"
    [minimal]="01,02,03,05,09"
)

#=============================================================================
# LOGGING FUNCTIONS
#=============================================================================

log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Create log directory if it doesn't exist
    mkdir -p "${LOG_FILE:h}"
    
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
    
    [[ $FORCE == true ]] && return 0
    
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

# Execute module with error handling
execute_module() {
    local module_script=$1
    local module_path="$SCRIPT_DIR/$module_script.zsh"
    
    if [[ ! -f $module_path ]]; then
        warn "Module not found: $module_path"
        return 1
    fi
    
    step "Executing module: $module_script"
    
    if [[ $DRY_RUN == true ]]; then
        info "DRY RUN: Would execute $module_script"
        return 0
    fi
    
    # Source the module and execute its main function
    if source "$module_path"; then
        success "Module completed: $module_script"
        return 0
    else
        error "Module failed: $module_script"
        return 1
    fi
}

# Display usage information
usage() {
    cat << EOF
${BOLD}NAME${RESET}
    $SCRIPT_NAME - Modular macOS setup bootstrap

${BOLD}SYNOPSIS${RESET}
    $SCRIPT_NAME [options]

${BOLD}DESCRIPTION${RESET}
    Bootstrap script for comprehensive macOS setup. Detects hardware,
    applies appropriate configurations, and supports multiple setup profiles
    for different use cases (development, data science, personal).

${BOLD}OPTIONS${RESET}
    -h, --help              Show this help message
    -v, --verbose           Enable verbose output
    -d, --debug             Enable debug mode
    -n, --dry-run           Preview changes without applying them
    -p, --profile PROFILE   Setup profile (developer, data-scientist, personal, custom)
    -f, --force             Skip confirmation prompts
    --skip-updates          Skip system updates check
    --modules-only LIST     Run only specific modules (comma-separated numbers)

${BOLD}PROFILES${RESET}
    developer               Full development environment setup
    data-scientist          ML/DS focused setup with data tools
    personal                Basic productivity and personal use
    minimal                 Essential tools only
    custom                  Interactive module selection

${BOLD}EXAMPLES${RESET}
    # Interactive setup with profile selection
    $SCRIPT_NAME

    # Data scientist setup
    $SCRIPT_NAME --profile data-scientist

    # Preview changes only
    $SCRIPT_NAME --dry-run --profile developer

    # Run specific modules only
    $SCRIPT_NAME --modules-only "01,03,05"

${BOLD}MODULES${RESET}
    01 - System Detection    Hardware detection and capability assessment
    02 - Xcode Tools        Command Line Tools installation
    03 - Homebrew Setup     Package manager and essential tools
    04 - System Setup       SSH, networking, and system services
    05 - macOS Defaults     UI preferences and system behaviour
    06 - Applications       GUI applications and configurations
    07 - Security Hardening Additional security measures
    08 - Development Env    Language runtimes and dev tools
    09 - Post Setup         Verification and cleanup

${BOLD}AUTHOR${RESET}
    Andrew Exley (with Claude) <noreply@anthropic.com>

${BOLD}VERSION${RESET}
    $SCRIPT_VERSION
EOF
}

#=============================================================================
# PROFILE MANAGEMENT
#=============================================================================

# Display available profiles
show_profiles() {
    echo ""
    echo "${BOLD}Available Setup Profiles:${RESET}"
    echo ""
    echo "  ${BOLD}1) developer${RESET}       - Full development environment"
    echo "     • Programming languages and runtimes"
    echo "     • Development tools and IDEs"
    echo "     • OrbStack (containers), databases, and infrastructure tools"
    echo ""
    echo "  ${BOLD}2) data-scientist${RESET}  - ML/DS focused setup"
    echo "     • Python ML/DS stack (pandas, scikit-learn, jupyter)"
    echo "     • R and Julia environments"
    echo "     • Database clients and visualization tools"
    echo "     • Enhanced security settings"
    echo ""
    echo "  ${BOLD}3) personal${RESET}        - Personal productivity setup"
    echo "     • Essential productivity applications"
    echo "     • Media and communication tools"
    echo "     • Basic development tools"
    echo ""
    echo "  ${BOLD}4) minimal${RESET}         - Essential tools only"
    echo "     • Core system configuration"
    echo "     • Basic command line tools"
    echo "     • Minimal GUI applications"
    echo ""
    echo "  ${BOLD}5) custom${RESET}          - Interactive module selection"
    echo "     • Choose specific modules to run"
    echo "     • Fine-grained control over setup"
    echo ""
}

# Interactive profile selection
select_profile() {
    if [[ -n $PROFILE ]]; then
        return 0  # Profile already specified via command line
    fi
    
    show_profiles
    
    echo -n "Select setup profile (1-5): "
    read -r choice
    
    case $choice in
        1) PROFILE="developer" ;;
        2) PROFILE="data-scientist" ;;
        3) PROFILE="personal" ;;
        4) PROFILE="minimal" ;;
        5) PROFILE="custom" ;;
        *)
            error "Invalid selection"
            return 1
            ;;
    esac
    
    info "Selected profile: $PROFILE"
}

# Interactive module selection for custom profile
select_custom_modules() {
    echo ""
    echo "${BOLD}Available Modules:${RESET}"
    echo ""
    
    local i=1
    for module in "${AVAILABLE_MODULES[@]}"; do
        local module_name=${module#??-}  # Remove number prefix
        module_name=${module_name//-/ }  # Replace hyphens with spaces
        printf "%2d) %-20s - %s\n" $i "$module" "$(get_module_description $module)"
        ((i++))
    done
    
    echo ""
    echo "Enter module numbers to run (comma-separated, e.g., 1,3,5):"
    echo "Or press Enter for all modules:"
    read -r selection
    
    if [[ -z $selection ]]; then
        MODULES_ONLY="01,02,03,04,05,06,07,08,09"
    else
        # Validate and format selection
        MODULES_ONLY=$(echo "$selection" | tr -d ' ')
    fi
}

# Get module description
get_module_description() {
    local module=$1
    
    case $module in
        "01-system-detection")  echo "Hardware detection and capability assessment" ;;
        "02-xcode-tools")       echo "Xcode Command Line Tools installation" ;;
        "03-homebrew-setup")    echo "Homebrew and package management" ;;
        "04-system-setup")      echo "SSH, networking, and system services" ;;
        "05-macos-defaults")    echo "macOS UI preferences and behaviour" ;;
        "06-applications")      echo "GUI applications and configurations" ;;
        "07-security-hardening") echo "Security enhancements and hardening" ;;
        "08-development-env")   echo "Development environments and tools" ;;
        "09-post-setup")        echo "Verification, cleanup, and health checks" ;;
        *) echo "Unknown module" ;;
    esac
}

#=============================================================================
# SYSTEM CHECKS
#=============================================================================

# Check system requirements
check_system_requirements() {
    step "Checking system requirements..."
    
    # macOS version check
    local macos_version=$(sw_vers -productVersion)
    local required_version="11.0"
    
    if ! is_version_gte "$macos_version" "$required_version"; then
        error "macOS $required_version or later required (current: $macos_version)"
        exit 1
    fi
    
    # Zsh version check
    local zsh_version=$ZSH_VERSION
    if [[ ${zsh_version%%.*} -lt 5 ]]; then
        error "Zsh 5.8+ required (current: $zsh_version)"
        exit 1
    fi
    
    # Disk space check (require at least 10GB free)
    local free_space=$(df -g / | awk 'NR==2 {print $4}')
    if [[ $free_space -lt 10 ]]; then
        warn "Low disk space: ${free_space}GB free (10GB+ recommended)"
        if ! confirm "Continue with limited disk space?"; then
            exit 1
        fi
    fi
    
    success "System requirements check passed"
}

# Version comparison utility
is_version_gte() {
    [ "$1" = "$(echo -e "$1\n$2" | sort -V | tail -n1)" ]
}

# Check for system updates
check_system_updates() {
    if [[ $SKIP_UPDATES == true ]]; then
        info "Skipping system updates check"
        return 0
    fi
    
    step "Checking for system updates..."
    
    local updates_available=$(softwareupdate -l 2>&1 | grep -c "recommended" || echo "0")
    
    if [[ $updates_available -gt 0 ]]; then
        warn "$updates_available system updates available"
        
        if confirm "Install system updates before proceeding? (Recommended)"; then
            info "Installing system updates... This may take a while."
            sudo softwareupdate -i -a
            
            if confirm "System updates installed. Restart now?"; then
                sudo shutdown -r now
            else
                warn "Please restart manually before running setup again"
                exit 0
            fi
        fi
    else
        success "System is up to date"
    fi
}

#=============================================================================
# MODULE EXECUTION
#=============================================================================

# Get modules to run based on profile
get_modules_for_profile() {
    local profile=$1
    
    if [[ -n $MODULES_ONLY ]]; then
        # Use explicitly specified modules
        echo "$MODULES_ONLY" | tr ',' ' '
        return 0
    fi
    
    if [[ -n ${PROFILE_MODULES[$profile]} ]]; then
        echo "${PROFILE_MODULES[$profile]}" | tr ',' ' '
    else
        # Default to all modules
        echo "01 02 03 04 05 06 07 08 09"
    fi
}

# Execute selected modules
run_modules() {
    local profile=$1
    local modules_to_run=($(get_modules_for_profile "$profile"))
    
    print_section "EXECUTING SETUP MODULES" "🚀"
    
    info "Profile: $profile"
    info "Modules to run: ${modules_to_run[*]}"
    
    if [[ $DRY_RUN == false ]] && ! confirm "Proceed with module execution?"; then
        info "Setup cancelled"
        exit 0
    fi
    
    local failed_modules=()
    
    for module_num in "${modules_to_run[@]}"; do
        # Find matching module
        local module_script=""
        for available_module in "${AVAILABLE_MODULES[@]}"; do
            if [[ $available_module =~ ^$module_num- ]]; then
                module_script=$available_module
                break
            fi
        done
        
        if [[ -z $module_script ]]; then
            warn "Module $module_num not found, skipping"
            continue
        fi
        
        if ! execute_module "$module_script"; then
            failed_modules+=("$module_script")
            
            if ! confirm "Module $module_script failed. Continue with remaining modules?"; then
                error "Setup aborted due to module failure"
                exit 1
            fi
        fi
    done
    
    # Report results
    if [[ ${#failed_modules[@]} -eq 0 ]]; then
        success "All modules completed successfully"
    else
        error "Failed modules: ${failed_modules[*]}"
        warn "Some modules failed. Check logs for details: $LOG_FILE"
        return 1
    fi
}

#=============================================================================
# MAIN FUNCTIONS
#=============================================================================

# Parse command line arguments
parse_args() {
    local args=()
    
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
            -p|--profile)
                PROFILE="$2"
                shift 2
                ;;
            -f|--force)
                FORCE=true
                shift
                ;;
            --skip-updates)
                SKIP_UPDATES=true
                shift
                ;;
            --modules-only)
                MODULES_ONLY="$2"
                shift 2
                ;;
            -*)
                error "Unknown option: $1"
                usage
                exit 1
                ;;
            *)
                args+=("$1")
                shift
                ;;
        esac
    done
    
    # Validate profile if specified
    if [[ -n $PROFILE && $PROFILE != "custom" && -z ${PROFILE_MODULES[$PROFILE]} ]]; then
        error "Invalid profile: $PROFILE"
        error "Valid profiles: ${(k)PROFILE_MODULES[*]} custom"
        exit 1
    fi
}

# Main script logic
main() {
    # Check environment
    check_macos
    
    # Parse arguments
    parse_args "$@"
    
    # Show header
    echo ""
    echo "${BOLD}${BLUE}🍎 macOS Modular Setup Bootstrap v$SCRIPT_VERSION${RESET}"
    echo "${BOLD}${BLUE}════════════════════════════════════════════════════════════════════════════════${RESET}"
    echo ""
    
    # System checks
    check_system_requirements
    check_system_updates
    
    # Profile selection
    if [[ $PROFILE == "custom" ]]; then
        select_custom_modules
    elif [[ -z $PROFILE ]]; then
        select_profile
        if [[ $PROFILE == "custom" ]]; then
            select_custom_modules
        fi
    fi
    
    # Show mode indicators
    if [[ $DRY_RUN == true ]]; then
        warn "DRY RUN MODE: No changes will be applied"
    fi
    
    # Create backup point
    if [[ $DRY_RUN == false ]]; then
        info "Creating setup log: $LOG_FILE"
        echo "macOS Setup Started: $(date)" > "$LOG_FILE"
        echo "Profile: $PROFILE" >> "$LOG_FILE"
        echo "Hardware: $(system_profiler SPHardwareDataType | grep 'Model Name' | awk -F: '{print $2}' | xargs)" >> "$LOG_FILE"
        echo "" >> "$LOG_FILE"
    fi
    
    # Execute modules
    if run_modules "$PROFILE"; then
        print_section "SETUP COMPLETE" "✅"
        
        if [[ $DRY_RUN == true ]]; then
            info "DRY RUN completed - no changes were applied"
            info "Run without --dry-run to apply changes"
        else
            success "macOS setup completed successfully!"
            
            echo ""
            echo "${BOLD}📋 Setup Summary:${RESET}"
            echo "   • Profile: $PROFILE"
            echo "   • Modules executed: $(get_modules_for_profile "$PROFILE" | wc -w | xargs)"
            echo "   • Log file: $LOG_FILE"
            echo ""
            echo "${BOLD}🔄 Next steps:${RESET}"
            echo "   • Restart your terminal or run: exec zsh"
            echo "   • Review the setup log for any warnings"
            echo "   • Customize settings as needed"
            echo ""
        fi
    else
        print_section "SETUP INCOMPLETE" "⚠️"
        error "Setup completed with errors. Check log: $LOG_FILE"
        exit 1
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
        debug "Bootstrap script exited successfully"
    else
        error "Bootstrap script exited with code: $exit_code"
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
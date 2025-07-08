#!/usr/bin/env zsh
# -*- coding: utf-8 -*-

#=============================================================================
# SCRIPT: 03-homebrew-setup.zsh
# AUTHOR: Andrew Exley
# DATE: 2025-01-07
# VERSION: 1.0.0
#
# DESCRIPTION:
#   Homebrew package manager installation and essential tools setup.
#   Installs Homebrew, configures it for the system, and installs
#   profile-specific packages using modular Brewfiles.
#
# USAGE:
#   ./03-homebrew-setup.zsh [options]
#
# OPTIONS:
#   -h, --help         Show this help message
#   -v, --verbose      Enable verbose output
#   -d, --debug        Enable debug mode
#   -n, --dry-run      Preview changes without applying them
#   -p, --profile      Package profile (base, development, data-science)
#   -f, --force        Force Homebrew reinstallation
#   --skip-bundle      Skip Brewfile bundle installation
#
# REQUIREMENTS:
#   - macOS 10.15+ (Catalina)
#   - Xcode Command Line Tools
#   - Admin privileges for some operations
#
# NOTES:
#   - Detects Apple Silicon vs Intel and configures appropriately
#   - Uses modular Brewfiles for different use cases
#   - Configures shell environment for Homebrew
#=============================================================================

# Strict mode
set -euo pipefail

# Script metadata
readonly SCRIPT_NAME="${0:t}"
readonly SCRIPT_DIR="${0:A:h}"
readonly SCRIPT_VERSION="1.0.0"
readonly DOTFILES_ROOT="${SCRIPT_DIR:h}"

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
declare -g SKIP_BUNDLE=false
declare -g PROFILE=""

# Homebrew configuration
declare -g HOMEBREW_PREFIX=""
declare -g HOMEBREW_REPOSITORY=""
declare -g HOMEBREW_CELLAR=""

# Load dry run utilities
if [[ -f "${SCRIPT_DIR}/lib/dry-run-utils.zsh" ]]; then
    source "${SCRIPT_DIR}/lib/dry-run-utils.zsh"
    dr_set_module "homebrew-setup"
fi

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

# Execute command with proper logging (enhanced with dry run utils)
execute_command() {
    local description=$1
    shift
    local cmd=("$@")
    
    # Use dry run utilities if available
    if command -v dr_execute >/dev/null 2>&1; then
        dr_execute "$description" "${cmd[@]}"
    else
        # Fallback to original implementation
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
    fi
    
    return 0
}

# Source hardware detection if available
load_hardware_profile() {
    local profile_file="$HOME/.config/dotfiles-setup/hardware-profile.env"
    
    if [[ -f $profile_file ]]; then
        source "$profile_file"
        debug "Loaded hardware profile: $HARDWARE_TYPE ($CHIP_TYPE)"
    else
        warn "Hardware profile not found, using defaults"
        # Set basic defaults
        export CHIP_TYPE=$(uname -m | grep -q "arm64" && echo "apple_silicon" || echo "intel")
        export HARDWARE_TYPE="unknown"
    fi
}

#=============================================================================
# HOMEBREW DETECTION AND SETUP
#=============================================================================

# Detect Homebrew installation paths
detect_homebrew_paths() {
    debug "Detecting Homebrew installation paths..."
    
    # Set paths based on architecture
    if [[ $CHIP_TYPE == "apple_silicon" ]]; then
        HOMEBREW_PREFIX="/opt/homebrew"
        HOMEBREW_REPOSITORY="/opt/homebrew"
        HOMEBREW_CELLAR="/opt/homebrew/Cellar"
    else
        HOMEBREW_PREFIX="/usr/local"
        HOMEBREW_REPOSITORY="/usr/local/Homebrew"
        HOMEBREW_CELLAR="/usr/local/Cellar"
    fi
    
    debug "Homebrew prefix: $HOMEBREW_PREFIX"
    debug "Homebrew repository: $HOMEBREW_REPOSITORY"
}

# Check if Homebrew is installed
check_homebrew_installed() {
    debug "Checking for existing Homebrew installation..."
    
    # Check if brew command is available
    if command -v brew &>/dev/null; then
        local brew_path=$(which brew)
        debug "Found brew at: $brew_path"
        
        # Verify it's functional
        if brew --version &>/dev/null; then
            success "Homebrew is installed and functional"
            return 0
        else
            warn "Homebrew found but not functional"
            return 1
        fi
    else
        debug "Homebrew not found in PATH"
        return 1
    fi
}

# Install Homebrew
install_homebrew() {
    step "Installing Homebrew package manager..."
    
    if [[ $DRY_RUN == true ]]; then
        info "DRY RUN: Would install Homebrew"
        return 0
    fi
    
    # Download and run the official Homebrew installer
    info "Downloading Homebrew installer..."
    
    if execute_command "Installing Homebrew" \
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
        
        success "Homebrew installation completed"
        
        # Configure shell environment immediately
        configure_homebrew_environment
        
        return 0
    else
        error "Homebrew installation failed"
        return 1
    fi
}

# Configure Homebrew environment
configure_homebrew_environment() {
    step "Configuring Homebrew environment..."
    
    # Add Homebrew to PATH for current session
    if [[ -f "$HOMEBREW_PREFIX/bin/brew" ]]; then
        eval "$($HOMEBREW_PREFIX/bin/brew shellenv)"
        debug "Homebrew environment configured for current session"
    fi
    
    # Check if already configured in shell profiles
    local zprofile="$HOME/.zprofile"
    local homebrew_config="eval \"\$($HOMEBREW_PREFIX/bin/brew shellenv)\""
    
    if [[ -f $zprofile ]] && grep -q "brew shellenv" "$zprofile"; then
        debug "Homebrew already configured in .zprofile"
    else
        if [[ $DRY_RUN == false ]]; then
            step "Adding Homebrew to shell environment"
            echo "" >> "$zprofile"
            echo "# Homebrew" >> "$zprofile"
            echo "$homebrew_config" >> "$zprofile"
            success "Homebrew configuration added to .zprofile"
        else
            info "DRY RUN: Would add Homebrew to .zprofile"
        fi
    fi
}

# Verify Homebrew installation
verify_homebrew() {
    step "Verifying Homebrew installation..."
    
    # Check brew command availability
    if ! command -v brew &>/dev/null; then
        error "Homebrew installation verification failed - brew command not found"
        return 1
    fi
    
    # Check basic functionality
    if ! brew --version &>/dev/null; then
        error "Homebrew installation verification failed - brew not functional"
        return 1
    fi
    
    # Run brew doctor for system health check
    info "Running Homebrew doctor..."
    if brew doctor; then
        success "Homebrew health check passed"
    else
        warn "Homebrew doctor found issues (may be non-critical)"
    fi
    
    # Display Homebrew information
    display_homebrew_info
    
    return 0
}

# Display Homebrew information
display_homebrew_info() {
    echo ""
    echo "${BOLD}Homebrew Information:${RESET}"
    echo ""
    
    local brew_version=$(brew --version | head -n1)
    local brew_prefix=$(brew --prefix)
    local brew_repository=$(brew --repository)
    
    printf "%-20s: %s\n" "Version" "$brew_version"
    printf "%-20s: %s\n" "Prefix" "$brew_prefix"
    printf "%-20s: %s\n" "Repository" "$brew_repository"
    printf "%-20s: %s\n" "Architecture" "$CHIP_TYPE"
    
    # Show installed package counts
    local formula_count=$(brew list --formula 2>/dev/null | wc -l | xargs)
    local cask_count=$(brew list --cask 2>/dev/null | wc -l | xargs)
    
    printf "%-20s: %s formulae, %s casks\n" "Installed Packages" "$formula_count" "$cask_count"
    echo ""
}

#=============================================================================
# BREWFILE MANAGEMENT
#=============================================================================

# Get Brewfile path based on profile
get_brewfile_path() {
    local profile=$1
    local brewfile=""
    
    case $profile in
        "base"|"")
            brewfile="$DOTFILES_ROOT/config/Brewfile"
            ;;
        "development")
            brewfile="$DOTFILES_ROOT/config/Brewfile.development"
            ;;
        "data-science")
            brewfile="$DOTFILES_ROOT/config/Brewfile.data-science"
            ;;
        "minimal")
            brewfile="$DOTFILES_ROOT/config/Brewfile.minimal"
            ;;
        *)
            brewfile="$DOTFILES_ROOT/config/Brewfile"
            ;;
    esac
    
    echo "$brewfile"
}

# Get hardware-specific Brewfile path
get_hardware_brewfile_path() {
    local hardware_type=${HARDWARE_TYPE:-"unknown"}
    local brewfile=""
    
    case $hardware_type in
        "studio")
            brewfile="$DOTFILES_ROOT/config/hardware/Brewfile.mac-studio"
            ;;
        "laptop")
            brewfile="$DOTFILES_ROOT/config/hardware/Brewfile.macbook-pro"
            ;;
        "mini")
            brewfile="$DOTFILES_ROOT/config/hardware/Brewfile.mac-mini"
            ;;
        *)
            # No hardware-specific Brewfile available
            return 1
            ;;
    esac
    
    if [[ -f $brewfile ]]; then
        echo "$brewfile"
        return 0
    else
        return 1
    fi
}

# Get machine configuration settings
load_machine_config() {
    local hardware_type=${HARDWARE_TYPE:-"unknown"}
    local config_file=""
    
    case $hardware_type in
        "studio")
            config_file="$DOTFILES_ROOT/config/machine-configs/mac-studio.conf"
            ;;
        "laptop")
            config_file="$DOTFILES_ROOT/config/machine-configs/macbook-pro.conf"
            ;;
        "mini")
            config_file="$DOTFILES_ROOT/config/machine-configs/mac-mini.conf"
            ;;
        *)
            debug "No machine config available for hardware type: $hardware_type"
            return 1
            ;;
    esac
    
    if [[ -f $config_file ]]; then
        debug "Loading machine config: $config_file"
        # Parse config file and set variables
        # Note: This is a simplified parser - could be enhanced with proper INI parsing
        while IFS='=' read -r key value; do
            # Skip comments and empty lines
            [[ $key =~ ^#.*$ || -z $key ]] && continue
            # Skip section headers
            [[ $key =~ ^\[.*\]$ ]] && continue
            # Set variables with MACHINE_CONFIG_ prefix
            declare -g "MACHINE_CONFIG_${key}"="${value}"
        done < "$config_file"
        return 0
    else
        debug "Machine config file not found: $config_file"
        return 1
    fi
}

# Install packages from Brewfile
install_brewfile_packages() {
    local profile=${1:-"base"}
    
    if [[ $SKIP_BUNDLE == true ]]; then
        info "Skipping Brewfile bundle installation"
        return 0
    fi
    
    step "Installing packages for profile: $profile"
    
    # Load machine configuration
    load_machine_config
    
    local brewfile=$(get_brewfile_path "$profile")
    local hardware_brewfile=""
    
    if [[ ! -f $brewfile ]]; then
        warn "Brewfile not found: $brewfile"
        return 1
    fi
    
    info "Using Brewfile: $brewfile"
    
    # Check for hardware-specific Brewfile
    if hardware_brewfile=$(get_hardware_brewfile_path); then
        info "Hardware-specific packages: $hardware_brewfile"
    else
        debug "No hardware-specific Brewfile for $HARDWARE_TYPE"
    fi
    
    # Use enhanced dry run utilities if available
    if [[ $DRY_RUN == true ]] && command -v dr_brew_bundle >/dev/null 2>&1; then
        dr_brew_bundle "Install packages for profile: $profile" "$brewfile"
        
        if [[ -n $hardware_brewfile && -f $hardware_brewfile ]]; then
            dr_brew_bundle "Install hardware-specific packages for $HARDWARE_TYPE" "$hardware_brewfile"
        fi
        return 0
    elif [[ $DRY_RUN == true ]]; then
        # Fallback dry run implementation
        info "DRY RUN: Would install packages from $brewfile"
        if [[ -f $brewfile ]]; then
            echo ""
            echo "${BOLD}Profile packages that would be installed:${RESET}"
            grep -E "^(brew|cask|mas)" "$brewfile" | head -15
            local total_packages=$(grep -E "^(brew|cask|mas)" "$brewfile" | wc -l | xargs)
            echo "... and $((total_packages > 15 ? total_packages - 15 : 0)) more profile packages"
        fi
        
        if [[ -n $hardware_brewfile && -f $hardware_brewfile ]]; then
            echo ""
            echo "${BOLD}Hardware-specific packages that would be installed:${RESET}"
            grep -E "^(brew|cask|mas)" "$hardware_brewfile" | head -10
            local hw_packages=$(grep -E "^(brew|cask|mas)" "$hardware_brewfile" | wc -l | xargs)
            echo "... and $((hw_packages > 10 ? hw_packages - 10 : 0)) more hardware packages"
        fi
        return 0
    fi
    
    # Install base packages first if not already using base profile
    if [[ $profile != "base" ]]; then
        local base_brewfile=$(get_brewfile_path "base")
        if [[ -f $base_brewfile ]]; then
            execute_command "Installing base packages" \
                brew bundle --file="$base_brewfile"
        fi
    fi
    
    # Install profile-specific packages
    execute_command "Installing $profile packages" \
        brew bundle --file="$brewfile"
    
    # Install hardware-specific packages
    if [[ -n $hardware_brewfile && -f $hardware_brewfile ]]; then
        if confirm "Install hardware-specific packages for $HARDWARE_TYPE?"; then
            execute_command "Installing hardware-specific packages" \
                brew bundle --file="$hardware_brewfile"
            success "Hardware-specific packages installed"
        else
            info "Skipped hardware-specific packages"
        fi
    fi
    
    success "Package installation completed for profile: $profile"
    return 0
}

# Update Homebrew and packages
update_homebrew() {
    step "Updating Homebrew and packages..."
    
    if [[ $DRY_RUN == true ]]; then
        info "DRY RUN: Would update Homebrew and packages"
        return 0
    fi
    
    # Update Homebrew itself
    execute_command "Updating Homebrew" brew update
    
    # Upgrade installed packages
    execute_command "Upgrading installed packages" brew upgrade
    
    # Clean up old versions
    execute_command "Cleaning up old package versions" brew cleanup
    
    success "Homebrew update completed"
}

#=============================================================================
# CONFIGURATION OPTIMIZATION
#=============================================================================

# Optimize Homebrew configuration
optimize_homebrew_config() {
    step "Optimizing Homebrew configuration..."
    
    local homebrew_env_file="$HOME/.homebrew_env"
    
    if [[ $DRY_RUN == true ]]; then
        info "DRY RUN: Would optimize Homebrew configuration"
        return 0
    fi
    
    # Create optimized environment configuration
    cat > "$homebrew_env_file" << EOF
# Homebrew optimization settings
export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_BUNDLE_FILE="$DOTFILES_ROOT/config/Brewfile"

# Performance optimizations
export HOMEBREW_MAKE_JOBS=\$(sysctl -n hw.ncpu)

# Apple Silicon specific optimizations
$(if [[ $CHIP_TYPE == "apple_silicon" ]]; then
    echo "export HOMEBREW_ARCH=arm64"
fi)
EOF
    
    # Source the configuration
    source "$homebrew_env_file"
    
    success "Homebrew configuration optimized"
}

# Configure services based on hardware type
configure_hardware_services() {
    step "Configuring services for hardware type: $HARDWARE_TYPE"
    
    if [[ $DRY_RUN == true ]]; then
        info "DRY RUN: Would configure hardware-specific services"
        return 0
    fi
    
    # Load machine configuration
    load_machine_config
    
    local services_to_start=()
    local services_to_stop=()
    
    case $HARDWARE_TYPE in
        "studio")
            # Mac Studio: Always-on network server services
            services_to_start=(
                "postgresql@15"      # Database server
                "redis"              # Cache server
                "nginx"              # Web server
                "netatalk"           # AFP file sharing (macOS devices)
                "smbd"               # SMB file sharing (cross-platform)
                "avahi-daemon"       # Service discovery/Bonjour
            )
            
            # Optional database services
            if confirm "Start MongoDB service for document storage?"; then
                services_to_start+=("mongodb-community")
            fi
            
            # Optional monitoring services
            if confirm "Start Elasticsearch for log aggregation?"; then
                services_to_start+=("elasticsearch")
            fi
            
            if confirm "Start Grafana for monitoring dashboards?"; then
                services_to_start+=("grafana")
            fi
            
            # OrbStack starts automatically, no service management needed
            info "OrbStack will start automatically when needed"
            
            info "Mac Studio configured as network server for all devices"
            ;;
            
        "laptop")
            # MacBook Pro: Daily driver with full development stack
            services_to_start=(
                "redis"              # Lightweight, always useful
                "postgresql@15"      # Full database for daily development
            )
            
            # Optional services for development
            if confirm "Start nginx for local development?"; then
                services_to_start+=("nginx")
            fi
            
            # OrbStack for lightweight container development
            info "OrbStack provides container runtime with better battery life"
            
            info "Services will adapt to power state (AC vs battery)"
            ;;
            
        "mini")
            # Mac Mini: Balanced approach
            services_to_start=(
                "redis"  # Lightweight
            )
            
            # Optional services based on config
            if confirm "Start PostgreSQL service for development?"; then
                services_to_start+=("postgresql@15")
            fi
            ;;
            
        *)
            info "No hardware-specific service configuration for $HARDWARE_TYPE"
            return 0
            ;;
    esac
    
    # Start services
    for service in "${services_to_start[@]}"; do
        if brew services list | grep -q "^$service.*stopped"; then
            execute_command "Starting service: $service" \
                brew services start "$service"
        elif brew services list | grep -q "^$service.*started"; then
            debug "Service already running: $service"
        else
            debug "Service not installed: $service"
        fi
    done
    
    # Stop services if specified
    for service in "${services_to_stop[@]}"; do
        if brew services list | grep -q "^$service.*started"; then
            execute_command "Stopping service: $service" \
                brew services stop "$service"
        fi
    done
    
    # Display service status
    if [[ ${#services_to_start[@]} -gt 0 ]]; then
        echo ""
        echo "${BOLD}Service Status:${RESET}"
        for service in "${services_to_start[@]}"; do
            local status=$(brew services list | grep "^$service" | awk '{print $2}' || echo "not installed")
            printf "  %-20s: %s\n" "$service" "$status"
        done
        echo ""
    fi
    
    success "Hardware-specific services configured"
}

#=============================================================================
# MAIN FUNCTIONS
#=============================================================================

# Display usage information
usage() {
    cat << EOF
${BOLD}NAME${RESET}
    $SCRIPT_NAME - Homebrew package manager setup

${BOLD}SYNOPSIS${RESET}
    $SCRIPT_NAME [options]

${BOLD}DESCRIPTION${RESET}
    Installs and configures Homebrew package manager for macOS.
    Detects system architecture and installs profile-specific packages
    using modular Brewfiles.

${BOLD}OPTIONS${RESET}
    -h, --help          Show this help message
    -v, --verbose       Enable verbose output
    -d, --debug         Enable debug mode
    -n, --dry-run       Preview changes without applying them
    -p, --profile       Package profile (base, development, data-science, minimal)
    -f, --force         Force Homebrew reinstallation
    --skip-bundle       Skip Brewfile bundle installation

${BOLD}PROFILES${RESET}
    base                Essential command-line tools and utilities
    development         Full development environment
    data-science        ML/DS tools and databases
    minimal             Absolute essentials only

${BOLD}EXAMPLES${RESET}
    # Install Homebrew with base packages
    $SCRIPT_NAME

    # Install development environment
    $SCRIPT_NAME --profile development

    # Preview installation
    $SCRIPT_NAME --dry-run --profile data-science

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
            -p|--profile)
                PROFILE="$2"
                shift 2
                ;;
            -f|--force)
                FORCE=true
                shift
                ;;
            --skip-bundle)
                SKIP_BUNDLE=true
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
    # Check environment
    check_macos
    
    # Parse arguments
    parse_args "$@"
    
    # Initialize dry run if enabled
    if [[ $DRY_RUN == true ]] && command -v dr_init >/dev/null 2>&1; then
        export DRY_RUN_ENABLED=true
        dr_init "homebrew-setup"
        dr_capture_system_state "homebrew-setup"
        dr_check_conflicts "homebrew-setup"
    fi
    
    # Load hardware profile
    load_hardware_profile
    
    # Detect Homebrew paths
    detect_homebrew_paths
    
    print_section "HOMEBREW PACKAGE MANAGER SETUP" "🍺"
    
    # Check if Homebrew is already installed
    if check_homebrew_installed && [[ $FORCE != true ]]; then
        info "Homebrew is already installed"
        
        # Still run updates and package installation
        update_homebrew
        
        if [[ -n $PROFILE ]]; then
            install_brewfile_packages "$PROFILE"
        fi
        
        # Configure hardware-specific services
        configure_hardware_services
        
        optimize_homebrew_config
        verify_homebrew
        
        success "Homebrew setup completed"
        return 0
    fi
    
    # Installation needed
    if [[ $FORCE == true ]]; then
        warn "Force installation requested"
    else
        info "Homebrew installation required"
    fi
    
    # Show what will be installed
    if [[ $DRY_RUN == false ]]; then
        echo ""
        echo "${BOLD}The following will be installed:${RESET}"
        echo "  • Homebrew package manager ($HOMEBREW_PREFIX)"
        echo "  • Shell environment configuration"
        if [[ -n $PROFILE ]]; then
            echo "  • $PROFILE package profile"
        fi
        echo ""
        echo "${YELLOW}Note: Installation requires internet connection and may take several minutes.${RESET}"
        echo ""
        
        if ! confirm "Proceed with Homebrew installation?"; then
            info "Installation cancelled"
            exit 0
        fi
    fi
    
    # Perform installation
    if install_homebrew; then
        # Verify installation
        if verify_homebrew; then
            # Install packages if profile specified
            if [[ -n $PROFILE ]]; then
                install_brewfile_packages "$PROFILE"
            fi
            
            # Configure hardware-specific services
            configure_hardware_services
            
            # Optimize configuration
            optimize_homebrew_config
            
            success "Homebrew setup completed successfully"
            
            # Finalize dry run reporting
            if [[ $DRY_RUN == true ]] && command -v dr_finalize_module >/dev/null 2>&1; then
                dr_finalize_module "homebrew-setup"
                dr_generate_summary
            else
                echo ""
                echo "${BOLD}Next steps:${RESET}"
                echo "  • Restart your terminal or run: exec zsh"
                echo "  • Use 'brew install <package>' to install additional software"
                echo "  • Use 'brew bundle' to install from Brewfiles"
                echo ""
            fi
        else
            error "Homebrew verification failed after installation"
            return 1
        fi
    else
        error "Homebrew installation failed"
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
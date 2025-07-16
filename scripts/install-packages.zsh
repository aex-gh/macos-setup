#!/usr/bin/env zsh
set -euo pipefail

# Script metadata and colour codes
readonly SCRIPT_NAME="${0:t}"
readonly SCRIPT_DIR="${0:A:h}"
readonly PROJECT_ROOT="${SCRIPT_DIR}/.."
readonly RED=$(tput setaf 1)
readonly GREEN=$(tput setaf 2)
readonly YELLOW=$(tput setaf 3)
readonly BLUE=$(tput setaf 4)
readonly CYAN=$(tput setaf 6)
readonly RESET=$(tput sgr0)

# Device type from command line
DEVICE_TYPE="${1:-macbook-pro}"

# Global variables
FORCE_INSTALL=false
SKIP_MAS=false
VERBOSE=false

# Logging functions
error() {
    echo "${RED}[ERROR]${RESET} $*" >&2
}

warn() {
    echo "${YELLOW}[WARN]${RESET} $*" >&2
}

info() {
    echo "${BLUE}[INFO]${RESET} $*"
}

success() {
    echo "${GREEN}[SUCCESS]${RESET} $*"
}

debug() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo "${CYAN}[DEBUG]${RESET} $*" >&2
    fi
}

# Check if Homebrew is installed and accessible
check_homebrew() {
    if ! command -v brew &>/dev/null; then
        error "Homebrew is not installed or not in PATH"
        error "Please run install-homebrew.zsh first"
        return 1
    fi
    
    local brew_version
    brew_version=$(brew --version | head -1)
    success "Homebrew found: $brew_version"
    return 0
}

# Update Homebrew before installation
update_homebrew() {
    info "Updating Homebrew..."
    
    if brew update; then
        success "Homebrew updated successfully"
    else
        warn "Homebrew update failed, continuing anyway"
    fi
    
    # Update package database
    brew update --quiet
    success "Package database updated"
}

# Install packages from a Brewfile
install_from_brewfile() {
    local brewfile="$1"
    local description="$2"
    
    if [[ ! -f "$brewfile" ]]; then
        error "Brewfile not found: $brewfile"
        return 1
    fi
    
    info "Installing packages from: $description"
    info "Brewfile: $brewfile"
    
    # Count packages for progress reporting
    local brew_count cask_count mas_count
    brew_count=$(grep -c '^brew "' "$brewfile" 2>/dev/null || echo 0)
    cask_count=$(grep -c '^cask "' "$brewfile" 2>/dev/null || echo 0)
    mas_count=$(grep -c '^mas "' "$brewfile" 2>/dev/null || echo 0)
    
    info "Package counts: $brew_count formulae, $cask_count casks, $mas_count MAS apps"
    
    # Install packages using brew bundle
    local bundle_args=(--file="$brewfile")
    
    if [[ "$FORCE_INSTALL" == "true" ]]; then
        bundle_args+=(--force)
    fi
    
    if [[ "$SKIP_MAS" == "true" ]]; then
        bundle_args+=(--no-mas)
    fi
    
    if [[ "$VERBOSE" == "true" ]]; then
        bundle_args+=(--verbose)
    fi
    
    debug "Running: brew bundle ${bundle_args[*]}"
    
    if brew bundle "${bundle_args[@]}"; then
        success "✓ Packages installed from $description"
        return 0
    else
        error "✗ Failed to install packages from $description"
        return 1
    fi
}

# Install mas (Mac App Store CLI) if needed
install_mas_if_needed() {
    if [[ "$SKIP_MAS" == "true" ]]; then
        info "Skipping Mac App Store CLI installation"
        return 0
    fi
    
    if command -v mas &>/dev/null; then
        success "Mac App Store CLI already installed"
        return 0
    fi
    
    info "Installing Mac App Store CLI..."
    if brew install mas; then
        success "Mac App Store CLI installed"
        return 0
    else
        error "Failed to install Mac App Store CLI"
        warn "Continuing without Mac App Store app installation"
        SKIP_MAS=true
        return 1
    fi
}

# Check Mac App Store authentication
check_mas_auth() {
    if [[ "$SKIP_MAS" == "true" ]]; then
        return 0
    fi
    
    if ! command -v mas &>/dev/null; then
        return 0
    fi
    
    info "Checking Mac App Store authentication..."
    
    if mas account &>/dev/null; then
        local account
        account=$(mas account)
        success "Authenticated with Mac App Store: $account"
        return 0
    else
        warn "Not authenticated with Mac App Store"
        warn "Please sign in to the Mac App Store app before running this script"
        warn "Or use --skip-mas to skip Mac App Store app installation"
        
        # Give user option to continue without MAS apps
        if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
            # Script is being sourced, skip interactive prompt
            SKIP_MAS=true
            return 0
        fi
        
        read -p "Continue without Mac App Store apps? [Y/n]: " skip_mas_choice
        if [[ "$skip_mas_choice" == "n" || "$skip_mas_choice" == "N" ]]; then
            error "Please authenticate with Mac App Store and try again"
            return 1
        else
            SKIP_MAS=true
            warn "Continuing without Mac App Store app installation"
            return 0
        fi
    fi
}

# Main package installation process
install_packages() {
    local configs_dir="$PROJECT_ROOT/configs"
    local common_brewfile="$configs_dir/common/Brewfile"
    local device_brewfile="$configs_dir/$DEVICE_TYPE/Brewfile"
    
    info "Package installation for device type: $DEVICE_TYPE"
    echo
    
    # Validate device type and Brewfiles
    if [[ ! -d "$configs_dir/$DEVICE_TYPE" ]]; then
        error "Invalid device type: $DEVICE_TYPE"
        error "Available types: macbook-pro, mac-studio, mac-mini"
        return 1
    fi
    
    if [[ ! -f "$common_brewfile" ]]; then
        error "Common Brewfile not found: $common_brewfile"
        return 1
    fi
    
    if [[ ! -f "$device_brewfile" ]]; then
        error "Device-specific Brewfile not found: $device_brewfile"
        return 1
    fi
    
    # Check prerequisites
    check_homebrew || return 1
    echo
    
    # Update Homebrew
    update_homebrew
    echo
    
    # Install and check mas
    install_mas_if_needed
    check_mas_auth || return 1
    echo
    
    # Install common packages first
    info "Phase 1: Installing common base packages..."
    install_from_brewfile "$common_brewfile" "Common Base Layer" || return 1
    echo
    
    # Install device-specific packages
    info "Phase 2: Installing device-specific packages..."
    install_from_brewfile "$device_brewfile" "$DEVICE_TYPE Configuration" || return 1
    echo
    
    # Cleanup and verify
    info "Phase 3: Cleaning up and verifying installation..."
    cleanup_and_verify
    
    return 0
}

# Cleanup and verify installation
cleanup_and_verify() {
    info "Running Homebrew cleanup..."
    
    # Clean up downloaded packages
    if brew cleanup; then
        success "Homebrew cleanup completed"
    else
        warn "Homebrew cleanup had issues"
    fi
    
    # Verify installation
    info "Verifying installation..."
    
    # Run brew doctor
    if brew doctor &>/dev/null; then
        success "Homebrew doctor check passed"
    else
        warn "Homebrew doctor found issues:"
        brew doctor 2>&1 | head -10
        warn "Check 'brew doctor' output for details"
    fi
    
    # Show installation summary
    info "Installation summary:"
    echo "  Formulae installed: $(brew list --formula | wc -l | xargs)"
    echo "  Casks installed: $(brew list --cask | wc -l | xargs)"
    
    if command -v mas &>/dev/null && [[ "$SKIP_MAS" != "true" ]]; then
        echo "  MAS apps installed: $(mas list | wc -l | xargs)"
    fi
    
    success "Installation verification completed"
}

# Help function
usage() {
    cat << EOF
$SCRIPT_NAME - Package Installation from Brewfiles

USAGE:
    $SCRIPT_NAME [OPTIONS] [DEVICE_TYPE]

DESCRIPTION:
    Installs packages from device-specific Brewfiles using Homebrew bundle.
    Processes both common base packages and device-specific packages.

OPTIONS:
    -f, --force          Force installation of packages (reinstall if exists)
    -s, --skip-mas       Skip Mac App Store app installation
    -v, --verbose        Enable verbose output
    -h, --help           Show this help message

DEVICE_TYPE:
    macbook-pro    Portable development workstation
    mac-studio     Headless server infrastructure
    mac-mini       Lightweight development + multimedia
    
    Default: macbook-pro

INSTALLATION PHASES:
    1. Common Base Layer     Universal tools and applications
    2. Device Configuration  Device-specific packages and applications
    3. Cleanup & Verify     Cleanup and verify installation

EXAMPLES:
    $SCRIPT_NAME                           # Install for MacBook Pro
    $SCRIPT_NAME mac-studio                # Install for Mac Studio
    $SCRIPT_NAME --force mac-mini          # Force reinstall for Mac Mini
    $SCRIPT_NAME --skip-mas --verbose      # Verbose install, skip MAS apps

NOTES:
    • Requires Homebrew to be installed (run install-homebrew.zsh first)
    • Mac App Store authentication required for MAS app installation
    • Uses brew bundle for efficient package management
    • Automatically handles dependencies and conflicts

EOF
}

# Main execution
main() {
    info "macOS Package Installation"
    info "========================="
    info "Device type: $DEVICE_TYPE"
    info "Force install: $FORCE_INSTALL"
    info "Skip MAS: $SKIP_MAS"
    info "Verbose: $VERBOSE"
    echo
    
    # Start installation process
    local start_time=$(date +%s)
    
    if install_packages; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        echo
        success "=========================================="
        success "Package installation completed successfully!"
        success "=========================================="
        success "Device: $DEVICE_TYPE"
        success "Duration: ${duration}s"
        info "All packages installed and verified"
        
        return 0
    else
        error "Package installation failed"
        return 1
    fi
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--force)
            FORCE_INSTALL=true
            shift
            ;;
        -s|--skip-mas)
            SKIP_MAS=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        macbook-pro|mac-studio|mac-mini)
            DEVICE_TYPE="$1"
            shift
            ;;
        -*)
            error "Unknown option: $1"
            usage
            exit 1
            ;;
        *)
            DEVICE_TYPE="$1"
            shift
            ;;
    esac
done

# Validate device type
case "$DEVICE_TYPE" in
    macbook-pro|mac-studio|mac-mini)
        ;;
    *)
        error "Invalid device type: $DEVICE_TYPE"
        error "Valid types: macbook-pro, mac-studio, mac-mini"
        exit 1
        ;;
esac

# Run main function
main
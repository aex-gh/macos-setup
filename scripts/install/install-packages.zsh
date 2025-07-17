#!/usr/bin/env zsh

# Script metadata
readonly SCRIPT_NAME="${0:t}"
readonly SCRIPT_DIR="${0:A:h}"
readonly PROJECT_ROOT="${SCRIPT_DIR}/.."

# Load common library
source "${SCRIPT_DIR}/../lib/common.zsh"

# Global variables
DEVICE_TYPE="${1:-$(detect_device_type)}"
FORCE_INSTALL=false
SKIP_MAS=false
DEBUG=false

# Install packages from Brewfile
install_from_brewfile() {
    local brewfile_path="$1"
    local brewfile_name="${brewfile_path:t}"
    
    if ! file_readable "$brewfile_path"; then
        error "Brewfile not found or not readable: $brewfile_path"
        return 1
    fi
    
    info "Installing packages from $brewfile_name..."
    
    # Change to the directory containing the Brewfile
    local brewfile_dir="${brewfile_path:h}"
    cd "$brewfile_dir" || return 1
    
    # Use brew bundle with progress
    local bundle_args=(--file="$brewfile_path" --verbose)
    [[ "$FORCE_INSTALL" == "true" ]] && bundle_args+=(--force)
    [[ "$SKIP_MAS" == "true" ]] && bundle_args+=(--no-mas)
    
    if brew bundle "${bundle_args[@]}"; then
        success "Packages installed from $brewfile_name"
        return 0
    else
        error "Failed to install packages from $brewfile_name"
        return 1
    fi
}

# Install packages for device type
install_device_packages() {
    local device_type="$1"
    
    header "Installing packages for $device_type"
    
    # Install common packages first
    local common_brewfile
    common_brewfile=$(get_common_brewfile_path)
    
    if file_readable "$common_brewfile"; then
        info "Installing common packages..."
        install_from_brewfile "$common_brewfile" || return 1
    else
        warn "Common Brewfile not found: $common_brewfile"
    fi
    
    # Install device-specific packages
    local device_brewfile
    device_brewfile=$(get_brewfile_path "$device_type")
    
    if file_readable "$device_brewfile"; then
        info "Installing device-specific packages..."
        install_from_brewfile "$device_brewfile" || return 1
    else
        warn "Device-specific Brewfile not found: $device_brewfile"
        info "Skipping device-specific package installation"
    fi
    
    return 0
}

# Cleanup and verification
cleanup_and_verify() {
    info "Cleaning up and verifying installation..."
    
    # Clean up Homebrew
    brew cleanup --quiet
    
    # Verify critical tools are installed
    local essential_tools=("git" "jq" "ripgrep" "bat" "eza")
    local missing_tools=()
    
    for tool in "${essential_tools[@]}"; do
        if ! command_exists "$tool"; then
            missing_tools+=("$tool")
        fi
    done
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        warn "Some essential tools are missing: ${missing_tools[*]}"
        info "You may need to install them manually or check your Brewfiles"
    else
        success "All essential tools verified"
    fi
    
    # Show installation summary
    local formula_count cask_count
    formula_count=$(brew list --formula 2>/dev/null | wc -l | xargs)
    cask_count=$(brew list --cask 2>/dev/null | wc -l | xargs)
    
    info "Installation summary:"
    info "  • $formula_count formulae installed"
    info "  • $cask_count casks installed"
    info "  • Device type: $device_type"
}

# Help function
usage() {
    cat << EOF
$SCRIPT_NAME - Package Installation from Brewfiles

USAGE:
    $SCRIPT_NAME [OPTIONS] [DEVICE_TYPE]

DESCRIPTION:
    Installs packages from device-specific Brewfiles using Homebrew bundle.
    Installs common packages first, then device-specific packages.

OPTIONS:
    -h, --help           Show this help message
    -f, --force          Force reinstallation of packages
    -s, --skip-mas       Skip Mac App Store app installations
    -v, --verbose        Enable verbose output

DEVICE_TYPE:
    Auto-detected if not specified. Valid types:
    macbook-pro, mac-studio, mac-mini

EXAMPLES:
    $SCRIPT_NAME                    # Auto-detect device and install
    $SCRIPT_NAME macbook-pro        # Install for MacBook Pro
    $SCRIPT_NAME --force            # Force reinstall packages

EOF
}

# Main installation process
main() {
    local device_type="${1:-$(detect_device_type)}"
    
    header "Package Installation for $device_type"
    
    # Check requirements
    check_macos
    check_homebrew || {
        error "Homebrew is required but not installed"
        info "Run install-homebrew.zsh first"
        return 1
    }
    
    # Validate device type
    if ! brewfile_exists "$device_type"; then
        error "No Brewfile found for device type: $device_type"
        return 1
    fi
    
    # Show installation plan
    local common_brewfile device_brewfile
    common_brewfile=$(get_common_brewfile_path)
    device_brewfile=$(get_brewfile_path "$device_type")
    
    info "Installation plan:"
    [[ -f "$common_brewfile" ]] && info "  • Common packages: $common_brewfile"
    [[ -f "$device_brewfile" ]] && info "  • Device packages: $device_brewfile"
    echo
    
    # Install packages
    install_device_packages "$device_type" || return 1
    
    # Cleanup and verify
    cleanup_and_verify
    
    success "Package installation completed successfully!"
    notify "Package Installation" "All packages installed for $device_type"
    
    return 0
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            exit 0
            ;;
        -f|--force)
            FORCE_INSTALL=true
            shift
            ;;
        -s|--skip-mas)
            SKIP_MAS=true
            shift
            ;;
        -v|--verbose)
            DEBUG=true
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

# Run main function
main "$DEVICE_TYPE"
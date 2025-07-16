#!/usr/bin/env zsh

# Script metadata
readonly SCRIPT_NAME="${0:t}"
readonly SCRIPT_DIR="${0:A:h}"

# Load common library
source "${SCRIPT_DIR}/lib/common.zsh"

# Homebrew installation URL
readonly HOMEBREW_INSTALL_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"

# Global variables
FORCE_INSTALL=false
SKIP_UPDATE=false

# Get Homebrew installation prefix for current architecture
get_homebrew_prefix() {
    if [[ "$(uname -m)" == "arm64" ]]; then
        echo "/opt/homebrew"
    else
        echo "/usr/local"
    fi
}

# Install Homebrew
install_homebrew() {
    info "Installing Homebrew..."
    
    if /bin/bash -c "$(curl -fsSL $HOMEBREW_INSTALL_URL)"; then
        success "Homebrew installation completed"
        return 0
    else
        error "Homebrew installation failed"
        return 1
    fi
}

# Configure Homebrew PATH in shell profile
configure_homebrew_path() {
    local brew_prefix
    brew_prefix=$(get_homebrew_prefix)
    local shell_profile="$HOME/.zprofile"
    local path_line="export PATH=\"$brew_prefix/bin:$brew_prefix/sbin:\$PATH\""
    
    info "Configuring Homebrew PATH in shell profile..."
    
    # Create .zprofile if it doesn't exist
    [[ ! -f "$shell_profile" ]] && touch "$shell_profile"
    
    # Check if PATH is already configured
    if grep -q "$brew_prefix/bin" "$shell_profile" 2>/dev/null; then
        success "Homebrew PATH already configured"
        return 0
    fi
    
    # Add Homebrew PATH to shell profile
    {
        echo ""
        echo "# Homebrew PATH configuration"
        echo "$path_line"
    } >> "$shell_profile"
    
    success "Added Homebrew PATH to $shell_profile"
    
    # Source the profile for current session
    eval "$path_line"
    success "Homebrew PATH configured for current session"
}

# Verify Homebrew installation and functionality
verify_homebrew() {
    local brew_prefix
    brew_prefix=$(get_homebrew_prefix)
    
    info "Verifying Homebrew installation..."
    
    # Ensure brew command is available
    if ! command_exists brew; then
        export PATH="$brew_prefix/bin:$brew_prefix/sbin:$PATH"
        
        if ! command_exists brew; then
            error "brew command not found after installation"
            error "Please ensure $brew_prefix/bin is in your PATH"
            return 1
        fi
    fi
    
    # Verify brew works
    local brew_version
    brew_version=$(brew --version | head -1)
    success "Homebrew verified: $brew_version"
    
    # Basic Homebrew doctor check
    info "Running Homebrew diagnostic..."
    if brew doctor &>/dev/null; then
        success "Homebrew doctor check passed"
    else
        warn "Homebrew doctor found issues (may be expected on new installations)"
        info "Run 'brew doctor' later to review any issues"
    fi
}

# Help function
usage() {
    cat << EOF
$SCRIPT_NAME - Homebrew Installation and Configuration

USAGE:
    $SCRIPT_NAME [OPTIONS] [DEVICE_TYPE]

DESCRIPTION:
    Installs and configures Homebrew package manager for macOS with
    automatic architecture detection and PATH configuration.

OPTIONS:
    -h, --help           Show this help message
    -f, --force          Force reinstallation even if Homebrew exists
    -s, --skip-update    Skip Homebrew update after installation

EXAMPLES:
    $SCRIPT_NAME                    # Install and configure Homebrew
    $SCRIPT_NAME --force            # Force reinstallation
    $SCRIPT_NAME macbook-pro        # Install for specific device type

EOF
}

# Main installation process
main() {
    local device_type="${1:-}"
    
    header "macOS Homebrew Installation"
    
    # Check requirements
    check_macos
    check_requirements "curl"
    
    # Check if already installed
    if check_homebrew && [[ "$FORCE_INSTALL" != "true" ]]; then
        local brew_version
        brew_version=$(brew --version | head -1)
        success "Homebrew already installed: $brew_version"
        
        if [[ "$SKIP_UPDATE" != "true" ]]; then
            info "Updating Homebrew..."
            brew update --quiet && success "Homebrew updated"
        fi
        
        verify_homebrew
        success "Homebrew setup completed"
        return 0
    fi
    
    # Install Homebrew
    if [[ "$FORCE_INSTALL" == "true" ]] || ! check_homebrew; then
        install_homebrew || return 1
    fi
    
    # Configure PATH
    configure_homebrew_path || return 1
    
    # Verify installation
    verify_homebrew || return 1
    
    # Update Homebrew
    if [[ "$SKIP_UPDATE" != "true" ]]; then
        info "Updating Homebrew..."
        brew update --quiet && success "Homebrew updated"
    fi
    
    success "Homebrew installation completed successfully!"
    info "Run 'source ~/.zprofile' or restart your terminal to ensure PATH is set"
    
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
        -s|--skip-update)
            SKIP_UPDATE=true
            shift
            ;;
        -*)
            error "Unknown option: $1"
            usage
            exit 1
            ;;
        *)
            # Device type for consistency with other scripts
            device_type="$1"
            shift
            ;;
    esac
done

# Run main function
main "$device_type"
#!/usr/bin/env zsh
set -euo pipefail

# Script metadata and colour codes
readonly SCRIPT_NAME="${0:t}"
readonly RED=$(tput setaf 1)
readonly GREEN=$(tput setaf 2)
readonly YELLOW=$(tput setaf 3)
readonly BLUE=$(tput setaf 4)
readonly RESET=$(tput sgr0)

# Homebrew installation URL
readonly HOMEBREW_INSTALL_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"

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

# Check if Homebrew is already installed
check_homebrew_installed() {
    if command -v brew &>/dev/null; then
        local brew_version
        brew_version=$(brew --version | head -1)
        success "Homebrew is already installed: $brew_version"
        return 0
    else
        info "Homebrew is not installed"
        return 1
    fi
}

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
    
    # Download and run the official Homebrew installation script
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
    if [[ ! -f "$shell_profile" ]]; then
        touch "$shell_profile"
        info "Created shell profile: $shell_profile"
    fi
    
    # Check if PATH is already configured
    if grep -q "$brew_prefix/bin" "$shell_profile" 2>/dev/null; then
        success "Homebrew PATH already configured in $shell_profile"
        return 0
    fi
    
    # Add Homebrew PATH to shell profile
    echo >> "$shell_profile"
    echo "# Homebrew PATH configuration" >> "$shell_profile"
    echo "$path_line" >> "$shell_profile"
    
    success "Added Homebrew PATH to $shell_profile"
    
    # Source the profile for current session
    eval "$path_line"
    success "Homebrew PATH configured for current session"
    
    return 0
}

# Verify Homebrew installation and functionality
verify_homebrew() {
    local brew_prefix
    brew_prefix=$(get_homebrew_prefix)
    
    info "Verifying Homebrew installation..."
    
    # Check if brew command is available
    if ! command -v brew &>/dev/null; then
        # Try to source the PATH manually
        export PATH="$brew_prefix/bin:$brew_prefix/sbin:$PATH"
        
        if ! command -v brew &>/dev/null; then
            error "brew command not found after installation"
            error "Please ensure $brew_prefix/bin is in your PATH"
            return 1
        fi
    fi
    
    # Verify brew works
    local brew_version
    brew_version=$(brew --version | head -1)
    success "Homebrew verified: $brew_version"
    
    # Check Homebrew doctor
    info "Running Homebrew diagnostic..."
    if brew doctor &>/dev/null; then
        success "Homebrew doctor check passed"
    else
        warn "Homebrew doctor found issues (this may be expected on new installations)"
        info "Run 'brew doctor' later to review any issues"
    fi
    
    return 0
}

# Update Homebrew and perform initial setup
update_homebrew() {
    info "Updating Homebrew..."
    
    # Update Homebrew itself
    if brew update; then
        success "Homebrew updated successfully"
    else
        warn "Homebrew update failed, continuing anyway"
    fi
    
    # Update package database
    info "Updating package database..."
    brew update --quiet
    
    # Show Homebrew status
    info "Homebrew installation summary:"
    echo "  Version: $(brew --version | head -1)"
    echo "  Prefix: $(brew --prefix)"
    echo "  Repository: $(brew --repository)"
    
    return 0
}

# Install essential development tools
install_essential_tools() {
    info "Installing essential development tools..."
    
    local essential_tools=(
        "git"
        "curl"
        "wget"
    )
    
    for tool in "${essential_tools[@]}"; do
        if brew list "$tool" &>/dev/null; then
            success "✓ $tool already installed"
        else
            info "Installing $tool..."
            if brew install "$tool"; then
                success "✓ $tool installed successfully"
            else
                error "✗ Failed to install $tool"
                return 1
            fi
        fi
    done
    
    return 0
}

# Accept Xcode license if needed
accept_xcode_license() {
    info "Checking Xcode license agreement..."
    
    # Check if Xcode command line tools are installed
    if ! xcode-select -p &>/dev/null; then
        info "Installing Xcode command line tools..."
        xcode-select --install
        
        # Wait for user to complete installation
        warn "Please complete the Xcode command line tools installation in the dialog"
        warn "Press Enter when installation is complete..."
        read
    fi
    
    # Accept Xcode license if needed
    if ! sudo xcodebuild -license accept 2>/dev/null; then
        warn "Could not automatically accept Xcode license"
        warn "You may need to run 'sudo xcodebuild -license accept' manually"
    else
        success "Xcode license accepted"
    fi
    
    return 0
}

# Help function
usage() {
    cat << EOF
$SCRIPT_NAME - Homebrew Installation and Configuration

USAGE:
    $SCRIPT_NAME [OPTIONS] [DEVICE_TYPE]

DESCRIPTION:
    Installs and configures Homebrew package manager for macOS. Handles
    architecture detection, PATH configuration, and essential tool installation.

OPTIONS:
    -h, --help           Show this help message
    -f, --force          Force reinstallation even if Homebrew exists
    -s, --skip-update    Skip Homebrew update after installation

DEVICE_TYPE:
    Device type is accepted but not used by this script (for consistency
    with other setup scripts).

EXAMPLES:
    $SCRIPT_NAME                    # Install and configure Homebrew
    $SCRIPT_NAME --force            # Force reinstallation
    $SCRIPT_NAME macbook-pro        # Install for MacBook Pro (same as default)

NOTES:
    - Detects Apple Silicon vs Intel architecture automatically
    - Configures appropriate PATH in ~/.zprofile
    - Installs Xcode command line tools if needed
    - Runs initial Homebrew diagnostics

EOF
}

# Main installation process
main() {
    local force_install=false
    local skip_update=false
    local device_type="${1:-}"
    
    info "macOS Homebrew Installation and Configuration"
    info "============================================"
    
    # Accept Xcode license first
    accept_xcode_license
    
    # Check if already installed
    if check_homebrew_installed && [[ "$force_install" != "true" ]]; then
        info "Homebrew is already installed and functional"
        
        if [[ "$skip_update" != "true" ]]; then
            update_homebrew
        fi
        
        verify_homebrew
        success "Homebrew setup completed"
        return 0
    fi
    
    # Install Homebrew
    if [[ "$force_install" == "true" ]] || ! check_homebrew_installed; then
        install_homebrew || return 1
    fi
    
    # Configure PATH
    configure_homebrew_path || return 1
    
    # Verify installation
    verify_homebrew || return 1
    
    # Update Homebrew
    if [[ "$skip_update" != "true" ]]; then
        update_homebrew || return 1
    fi
    
    # Install essential tools
    install_essential_tools || return 1
    
    success "=========================================="
    success "Homebrew installation completed successfully!"
    success "=========================================="
    info "Homebrew is ready for package installation"
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
            force_install=true
            shift
            ;;
        -s|--skip-update)
            skip_update=true
            shift
            ;;
        -*)
            error "Unknown option: $1"
            usage
            exit 1
            ;;
        *)
            # Assume it's the device type (for consistency with other scripts)
            device_type="$1"
            shift
            ;;
    esac
done

# Run main function
main "$device_type"
#!/usr/bin/env zsh

# Script metadata
readonly SCRIPT_NAME="${0:t}"
readonly SCRIPT_DIR="${0:A:h}"

# Load common library
source "${SCRIPT_DIR}/../lib/common.zsh"

# Check if font is installed
check_font_installed() {
    local font_name="$1"
    local font_paths=(
        "${HOME}/Library/Fonts"
        "/Library/Fonts"
        "/System/Library/Fonts"
    )
    
    for font_path in "${font_paths[@]}"; do
        if find "$font_path" -name "*${font_name}*" -type f 2>/dev/null | grep -q .; then
            return 0
        fi
    done
    return 1
}

# Install fonts via Homebrew
install_fonts() {
    header "Font Installation"
    
    # Check if Homebrew is installed
    check_homebrew || {
        error "Homebrew is required but not installed"
        info "Run install-homebrew.zsh first"
        return 1
    }
    
    # Essential fonts to install
    local fonts=(
        "font-maple-mono-nf"
        "font-fira-code-nerd-font"
        "font-jetbrains-mono-nerd-font"
        "font-meslo-lg-nerd-font"
    )
    
    # Add font tap if not already added
    if ! brew tap | grep -q "homebrew/cask-fonts"; then
        info "Adding homebrew/cask-fonts tap..."
        brew tap homebrew/cask-fonts
    fi
    
    # Install fonts
    local installed_count=0
    for font in "${fonts[@]}"; do
        if brew list --cask "$font" &>/dev/null; then
            success "✓ $font already installed"
            ((installed_count++))
        else
            info "Installing $font..."
            if brew install --cask "$font"; then
                success "✓ $font installed successfully"
                ((installed_count++))
            else
                error "✗ Failed to install $font"
            fi
        fi
    done
    
    success "Font installation completed ($installed_count/${#fonts[@]} fonts installed)"
    
    # Verify Maple Mono specifically (our standard font)
    if check_font_installed "Maple"; then
        success "✓ Maple Mono Nerd Font is available"
    else
        warn "⚠ Maple Mono Nerd Font may not be properly installed"
    fi
    
    return 0
}

# Help function
usage() {
    cat << EOF
$SCRIPT_NAME - Install Essential Fonts via Homebrew

USAGE:
    $SCRIPT_NAME [OPTIONS]

DESCRIPTION:
    Installs essential fonts including Maple Mono Nerd Font (project standard)
    and other popular development fonts via Homebrew cask-fonts.

OPTIONS:
    -h, --help           Show this help message

EXAMPLES:
    $SCRIPT_NAME                    # Install all essential fonts

EOF
}

# Main execution
main() {
    # Check requirements
    check_macos
    
    # Install fonts
    install_fonts
    
    info "Font installation complete!"
    info "You may need to restart applications to see new fonts"
    
    return 0
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Run main function
main "$@"
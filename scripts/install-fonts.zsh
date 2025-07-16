#!/usr/bin/env zsh
set -euo pipefail

readonly SCRIPT_NAME="${0:t}"
readonly RED=$(tput setaf 1)
readonly GREEN=$(tput setaf 2)
readonly YELLOW=$(tput setaf 3)
readonly BLUE=$(tput setaf 4)
readonly RESET=$(tput sgr0)

info() {
    echo "${BLUE}[INFO]${RESET} $*"
}

success() {
    echo "${GREEN}[SUCCESS]${RESET} $*"
}

warn() {
    echo "${YELLOW}[WARN]${RESET} $*"
}

error() {
    echo "${RED}[ERROR]${RESET} $*" >&2
}

cleanup() {
    local exit_code=$?
    if [[ ${exit_code} -ne 0 ]]; then
        error "Script failed with exit code ${exit_code}"
    fi
    exit ${exit_code}
}

trap cleanup EXIT INT TERM

check_font_installed() {
    local font_name="$1"
    local font_path_user="${HOME}/Library/Fonts"
    local font_path_system="/Library/Fonts"
    local font_path_system_alt="/System/Library/Fonts"
    
    # Check various locations for the font
    if find "${font_path_user}" "${font_path_system}" "${font_path_system_alt}" -name "*${font_name}*" -type f 2>/dev/null | grep -q .; then
        return 0
    else
        return 1
    fi
}

install_maple_mono() {
    info "Installing Maple Mono Nerd Font..."
    
    local font_name="Maple Mono"
    local font_url="https://github.com/subframe7536/maple-font/releases/latest/download/MapleMono-NF.zip"
    local temp_dir
    temp_dir=$(mktemp -d)
    local font_dir="${HOME}/Library/Fonts"
    
    # Check if font is already installed
    if check_font_installed "${font_name}"; then
        success "Maple Mono Nerd Font is already installed"
        return 0
    fi
    
    # Create fonts directory if it doesn't exist
    mkdir -p "${font_dir}"
    
    info "Downloading Maple Mono Nerd Font..."
    if ! curl -L -o "${temp_dir}/MapleMono-NF.zip" "${font_url}"; then
        error "Failed to download Maple Mono Nerd Font"
        rm -rf "${temp_dir}"
        exit 1
    fi
    
    info "Extracting font files..."
    cd "${temp_dir}"
    if ! unzip -q "MapleMono-NF.zip"; then
        error "Failed to extract font archive"
        rm -rf "${temp_dir}"
        exit 1
    fi
    
    # Install font files
    local installed_count=0
    for font_file in *.ttf *.otf; do
        if [[ -f "${font_file}" ]]; then
            cp "${font_file}" "${font_dir}/"
            ((installed_count++))
            info "Installed: ${font_file}"
        fi
    done
    
    # Clean up
    rm -rf "${temp_dir}"
    
    if [[ ${installed_count} -gt 0 ]]; then
        success "Installed ${installed_count} Maple Mono font files"
        
        # Clear font cache
        info "Clearing font cache..."
        sudo atsutil databases -remove 2>/dev/null || true
        atsutil server -shutdown 2>/dev/null || true
        atsutil server -ping 2>/dev/null || true
        
        success "Maple Mono Nerd Font installation complete"
    else
        error "No font files were installed"
        exit 1
    fi
}

install_additional_fonts() {
    info "Installing additional recommended fonts..."
    
    # Use homebrew to install common developer fonts
    local fonts=(
        "font-fira-code"
        "font-jetbrains-mono"
        "font-source-code-pro"
        "font-hack"
        "font-inconsolata"
    )
    
    if ! command -v brew >/dev/null 2>&1; then
        warn "Homebrew not found. Skipping additional fonts."
        return 0
    fi
    
    # Add homebrew fonts tap if not already added
    if ! brew tap | grep -q "homebrew/cask-fonts"; then
        info "Adding homebrew fonts tap..."
        brew tap homebrew/cask-fonts
    fi
    
    local installed_fonts=()
    local skipped_fonts=()
    
    for font in "${fonts[@]}"; do
        if brew list --cask "${font}" >/dev/null 2>&1; then
            skipped_fonts+=("${font}")
        else
            info "Installing ${font}..."
            if brew install --cask "${font}"; then
                installed_fonts+=("${font}")
            else
                warn "Failed to install ${font}"
            fi
        fi
    done
    
    if [[ ${#installed_fonts[@]} -gt 0 ]]; then
        success "Installed fonts: ${installed_fonts[*]}"
    fi
    
    if [[ ${#skipped_fonts[@]} -gt 0 ]]; then
        info "Already installed: ${skipped_fonts[*]}"
    fi
}

verify_font_installation() {
    info "Verifying font installation..."
    
    local fonts_to_check=(
        "Maple Mono"
        "Fira Code"
        "JetBrains Mono"
        "Source Code Pro"
        "Hack"
        "Inconsolata"
    )
    
    local available_fonts=()
    local missing_fonts=()
    
    for font in "${fonts_to_check[@]}"; do
        if check_font_installed "${font}"; then
            available_fonts+=("${font}")
        else
            missing_fonts+=("${font}")
        fi
    done
    
    if [[ ${#available_fonts[@]} -gt 0 ]]; then
        success "Available fonts: ${available_fonts[*]}"
    fi
    
    if [[ ${#missing_fonts[@]} -gt 0 ]]; then
        warn "Missing fonts: ${missing_fonts[*]}"
    fi
    
    # Test if Maple Mono is available to applications
    if system_profiler SPFontsDataType | grep -q "Maple Mono"; then
        success "Maple Mono is registered with the system"
    else
        warn "Maple Mono may not be properly registered. You may need to restart applications or log out and back in."
    fi
}

configure_terminal_font() {
    info "Configuring Terminal.app to use Maple Mono..."
    
    # Create a new Terminal profile with Maple Mono
    local profile_name="Gruvbox Maple Mono"
    
    # Check if the profile already exists
    if defaults read com.apple.Terminal "Window Settings" | grep -q "${profile_name}"; then
        info "Terminal profile '${profile_name}' already exists"
        return 0
    fi
    
    # Create profile with Maple Mono font
    local profile_plist
    profile_plist=$(cat << 'EOF'
{
    BackgroundColor = <62706c69 73743030 d4010203 04050615 16582476 65727369 6f6e5824 6f626a65 63747359 24617263 68697665 72542474 6f70120001 86a0a307 080f5524 6e756c6c d3090a0b 0c0d0e5a 4e53436f 6c6f7253 70616365 5624636c 61737357 4e535768 69746580 00100380 02d2101112 13542463 6c617373 5a246365 6c617373 6e616d65 a2131458 4e53436f 6c6f7258 4e534f62 6a656374 5f101f7b 302e3230 2c20302e 31392c20 302e3138 2c20312e 30307d08 0b1a2429 32376174 77000000 000001ad 01000000 00000000 17000000 00000000 00000000 00000000 8a>;
    CursorColor = <62706c69 73743030 d4010203 04050615 16582476 65727369 6f6e5824 6f626a65 63747359 24617263 68697665 72542474 6f70120001 86a0a307 080f5524 6e756c6c d3090a0b 0c0d0e5a 4e53436f 6c6f7253 70616365 5624636c 61737357 4e535768 69746580 00100380 02d2101112 13542463 6c617373 5a246365 6c617373 6e616d65 a2131458 4e53436f 6c6f7258 4e534f62 6a656374 5f101f7b 302e3932 2c20302e 38352c20 302e36392c20312e30 307d080b 1a242932 37617477 00000000 0001ad01 00000000 00000017 00000000 00000000 00000000 0000008a>;
    Font = <62706c69 73743030 d4010203 04050616 17582476 65727369 6f6e5824 6f626a65 63747359 24617263 68697665 72542474 6f70120001 86a0a308 090e0f55 246e756c 6cd30a0b 0c0d1055 4e53466f 6e745369 7a65584e 5353747269 6e675624 636c6173 735d4e53 466f6e74 44657363 72697074 6f72102d 8003d211 12131454 246e616d 65a21314 584e5353 7472696e 67584e53 4f626a65 6374562d 18d315161 71819541 4e534d75 7461626c 65446963 74696f6e 6172795e 4e53466f 6e74446f 6e744469 63748004 d4191a1b 1c1d1e55 4e53466f 6e744e61 6d655824 636c6173 735d4e53 466f6e74 53697a65 a31f201e 5f102545 746c6d61 706c654d 6f6e6f2d 52656775 6c61725f 4e657264 466f6e74 2d526567 756c6172 1028801b 12232829 323c4553 595c6a7a 80859099 a3abb7c1 c8000000 00000101 01000000 00000000 22000000 00000000 00000000 00000000 ca>;
    ProfileCurrentVersion = "2.07";
    SelectionColor = <62706c69 73743030 d4010203 04050615 16582476 65727369 6f6e5824 6f626a65 63747359 24617263 68697665 72542474 6f70120001 86a0a307 080f5524 6e756c6c d3090a0b 0c0d0e5a 4e53436f 6c6f7253 70616365 5624636c 61737357 4e535768 69746580 00100380 02d2101112 13542463 6c617373 5a246365 6c617373 6e616d65 a2131458 4e53436f 6c6f7258 4e534f62 6a656374 5f101f7b 302e3431 2c20302e 34302c20 302e3337 2c20312e 30307d08 0b1a2429 32376174 77000000 000001ad 01000000 00000000 17000000 00000000 00000000 00000000 8a>;
    TextBoldColor = <62706c69 73743030 d4010203 04050615 16582476 65727369 6f6e5824 6f626a65 63747359 24617263 68697665 72542474 6f70120001 86a0a307 080f5524 6e756c6c d3090a0b 0c0d0e5a 4e53436f 6c6f7253 70616365 5624636c 61737357 4e535768 69746580 00100380 02d2101112 13542463 6c617373 5a246365 6c617373 6e616d65 a2131458 4e53436f 6c6f7258 4e534f62 6a656374 5f101f7b 302e3932 2c20302e 38352c20 302e36392c20312e30 307d080b 1a242932 37617477 00000000 0001ad01 00000000 00000017 00000000 00000000 00000000 0000008a>;
    TextColor = <62706c69 73743030 d4010203 04050615 16582476 65727369 6f6e5824 6f626a65 63747359 24617263 68697665 72542474 6f70120001 86a0a307 080f5524 6e756c6c d3090a0b 0c0d0e5a 4e53436f 6c6f7253 70616365 5624636c 61737357 4e535768 69746580 00100380 02d2101112 13542463 6c617373 5a246365 6c617373 6e616d65 a2131458 4e53436f 6c6f7258 4e534f62 6a656374 5f101f7b 302e3932 2c20302e 38352c20 302e36392c20312e30 307d080b 1a242932 37617477 00000000 0001ad01 00000000 00000017 00000000 00000000 00000000 0000008a>;
    name = "Gruvbox Maple Mono";
    type = "Window Settings";
}
EOF
)
    
    # Add the profile to Terminal settings
    defaults write com.apple.Terminal "Window Settings" -dict-add "${profile_name}" "${profile_plist}"
    
    # Set as default profile
    defaults write com.apple.Terminal "Default Window Settings" "${profile_name}"
    defaults write com.apple.Terminal "Startup Window Settings" "${profile_name}"
    
    success "Configured Terminal.app with Gruvbox Maple Mono profile"
    info "Restart Terminal.app to see the changes"
}

main() {
    info "Starting font installation..."
    
    install_maple_mono
    install_additional_fonts
    verify_font_installation
    configure_terminal_font
    
    success "Font installation complete!"
    info "Maple Mono Nerd Font is now installed and configured"
    info "You may need to restart applications to see the new fonts"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
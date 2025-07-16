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

setup_age_encryption() {
    info "Setting up age encryption for chezmoi..."
    
    local age_dir="${HOME}/.age"
    local age_key="${age_dir}/key.txt"
    
    # Create age directory if it doesn't exist
    if [[ ! -d "${age_dir}" ]]; then
        mkdir -p "${age_dir}"
        chmod 700 "${age_dir}"
        info "Created age directory at ${age_dir}"
    fi
    
    # Generate age key if it doesn't exist
    if [[ ! -f "${age_key}" ]]; then
        if ! command -v age-keygen >/dev/null 2>&1; then
            error "age-keygen not found. Please install age first with: brew install age"
            exit 1
        fi
        
        age-keygen -o "${age_key}"
        chmod 600 "${age_key}"
        success "Generated new age key at ${age_key}"
        
        # Extract public key
        local public_key
        public_key=$(age-keygen -y "${age_key}")
        info "Your age public key: ${public_key}"
        
        # Store in 1Password if available
        if command -v op >/dev/null 2>&1; then
            warn "Consider storing your age keys in 1Password for backup:"
            echo "  op item create --category='Secure Note' --title='chezmoi age keys' --vault='Personal' 'public key=${public_key}' 'private key=<contents of ${age_key}>'"
        fi
    else
        info "Age key already exists at ${age_key}"
    fi
}

configure_chezmoi_encryption() {
    info "Configuring chezmoi encryption..."
    
    local chezmoi_config="${HOME}/.config/chezmoi/chezmoi.toml"
    local age_key="${HOME}/.age/key.txt"
    
    if [[ ! -f "${age_key}" ]]; then
        error "Age key not found. Run setup_age_encryption first."
        exit 1
    fi
    
    # Extract public key for configuration
    local public_key
    public_key=$(age-keygen -y "${age_key}")
    
    # Create chezmoi config directory
    mkdir -p "$(dirname "${chezmoi_config}")"
    
    # Update chezmoi configuration with encryption settings
    if [[ -f "${chezmoi_config}" ]]; then
        # Backup existing config
        cp "${chezmoi_config}" "${chezmoi_config}.backup"
        info "Backed up existing chezmoi config"
    fi
    
    # Add encryption section to config
    cat >> "${chezmoi_config}" << EOF

[encryption]
    command = "age"
    args = ["-d"]

[age]
    identity = "${age_key}"
    recipient = "${public_key}"
EOF
    
    success "Updated chezmoi configuration with encryption settings"
}

store_age_key_in_1password() {
    if ! command -v op >/dev/null 2>&1; then
        warn "1Password CLI not available. Skipping key storage."
        return 0
    fi
    
    local age_key="${HOME}/.age/key.txt"
    
    if [[ ! -f "${age_key}" ]]; then
        error "Age key not found at ${age_key}"
        return 1
    fi
    
    # Check if we're signed in to 1Password
    if ! op account list >/dev/null 2>&1; then
        warn "Not signed in to 1Password. Please sign in first with: op signin"
        return 0
    fi
    
    local public_key
    public_key=$(age-keygen -y "${age_key}")
    local private_key
    private_key=$(cat "${age_key}")
    
    # Create item in 1Password
    local item_title="chezmoi age encryption key"
    
    # Check if item already exists
    if op item get "${item_title}" >/dev/null 2>&1; then
        warn "Item '${item_title}' already exists in 1Password"
        return 0
    fi
    
    # Create new secure note with the keys
    op item create --category='Secure Note' \
        --title="${item_title}" \
        --vault='Personal' \
        "public_key=${public_key}" \
        "private_key=${private_key}" \
        "notes=Age encryption keys for chezmoi dotfiles management. Keep these secure!"
    
    success "Stored age keys in 1Password as '${item_title}'"
}

main() {
    info "Starting chezmoi encryption setup..."
    
    setup_age_encryption
    configure_chezmoi_encryption
    store_age_key_in_1password
    
    success "Chezmoi encryption setup complete!"
    info "You can now encrypt sensitive files with: chezmoi encrypt <file>"
    info "Encrypted files will have the .age suffix and be decrypted automatically by chezmoi"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
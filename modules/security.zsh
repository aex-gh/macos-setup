#!/usr/bin/env zsh
# ABOUTME: Configures macOS security settings based on YAML configuration
# ABOUTME: Handles firewall, FileVault, SSH, and user account security

set -euo pipefail

# Use parent script's logging functions if available, otherwise use plain echo
if ! command -v log_info &> /dev/null; then
    log_info() { echo "$@"; }
    log_success() { echo "$@"; }
    log_warn() { echo "$@"; }
    log_error() { echo "$@" >&2; }
fi

# Load YAML configuration
load_config() {
    local config_file="$1"
    if [[ ! -f "$config_file" ]]; then
        log_error "Configuration file not found: $config_file"
        return 1
    fi
    
    if command -v yq &> /dev/null; then
        CONFIG_DATA=$(yq eval '.' "$config_file")
    else
        CONFIG_DATA=$(cat "$config_file")
    fi
}

# Get configuration value
get_config_value() {
    local key="$1"
    local default_value="${2:-}"
    
    if command -v yq &> /dev/null; then
        yq eval ".$key" <<< "$CONFIG_DATA" 2>/dev/null || echo "$default_value"
    else
        grep -E "^[[:space:]]*${key}:" <<< "$CONFIG_DATA" | sed 's/.*: *//' | head -1 || echo "$default_value"
    fi
}

# Configure firewall
configure_firewall() {
    local config_file="$1"
    
    log_info "Configuring firewall from: $config_file"
    
    load_config "$config_file"
    
    local firewall_enabled=$(get_config_value "security.firewall_enabled" "true")
    local stealth_mode=$(get_config_value "security.stealth_mode" "true")
    
    if [[ "$firewall_enabled" = "true" ]]; then
        log_info "Enabling firewall"
        sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
        
        if [[ "$stealth_mode" = "true" ]]; then
            log_info "Enabling stealth mode"
            sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on
        fi
        
        # Note: Logging is enabled by default when firewall is on
        # There's no separate setloggingmode flag in newer macOS versions
    fi
    
    log_success "Firewall configuration complete"
}

# Configure FileVault
configure_filevault() {
    local config_file="$1"
    
    log_info "Configuring FileVault from: $config_file"
    
    load_config "$config_file"
    
    local filevault_enabled=$(get_config_value "security.file_vault" "true")
    
    if [[ "$filevault_enabled" = "true" ]]; then
        # Check if FileVault is already enabled
        if ! fdesetup status | grep -q "FileVault is On"; then
            log_warn "FileVault is not enabled. Please enable it manually:"
            echo "  System Preferences > Security & Privacy > FileVault > Turn On FileVault"
            echo "  Or use: sudo fdesetup enable (requires user interaction)"
        else
            log_success "FileVault is already enabled"
        fi
    fi
    
    log_success "FileVault configuration complete"
}

# Configure SSH
configure_ssh() {
    local config_file="$1"
    
    log_info "Configuring SSH from: $config_file"
    
    load_config "$config_file"
    
    local ssh_key_type=$(get_config_value "security.ssh_key_type" "ed25519")
    local ssh_disable_password=$(get_config_value "security.ssh_disable_password_auth" "false")
    local ssh_max_tries=$(get_config_value "security.ssh_max_auth_tries" "3")
    
    # Create SSH directory if it doesn't exist
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    
    # Generate SSH key if it doesn't exist
    local ssh_key_path=~/.ssh/id_${ssh_key_type}
    if [[ ! -f "$ssh_key_path" ]]; then
        log_info "Generating $ssh_key_type SSH key"
        ssh-keygen -t "$ssh_key_type" -f "$ssh_key_path" -N ""
    fi
    
    # Configure SSH client
    local ssh_config=~/.ssh/config
    if [[ ! -f "$ssh_config" ]]; then
        log_info "Creating SSH client configuration"
        cat > "$ssh_config" << EOF
Host *
    IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
    UseKeychain yes
    AddKeysToAgent yes
    IdentitiesOnly yes
    PreferredAuthentications publickey,keyboard-interactive,password
    ServerAliveInterval 60
    ServerAliveCountMax 3
EOF
        chmod 600 "$ssh_config"
    fi
    
    log_success "SSH configuration complete"
}

# Configure user accounts
configure_user_accounts() {
    local config_file="$1"
    
    log_info "Configuring user accounts from: $config_file"
    
    load_config "$config_file"
    
    local disable_guest=$(get_config_value "security.disable_guest_user" "true")
    
    if [[ "$disable_guest" = "true" ]]; then
        log_info "Disabling guest user"
        # Only try to delete if Guest user exists in dscl
        if dscl . -list /Users | grep -q "^Guest$"; then
            sudo dscl . -delete /Users/Guest 2>/dev/null || true
        fi
        # Disable guest account via loginwindow preferences
        sudo defaults write /Library/Preferences/com.apple.loginwindow GuestEnabled -bool false
        sudo defaults write /Library/Preferences/com.apple.AppleFileServer guestAccess -bool false
        sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server AllowGuestAccess -bool false
    fi
    
    log_success "User account configuration complete"
}

# Configure all security settings
configure_security() {
    local config_file="$1"
    
    log_info "Configuring security settings from: $config_file"
    
    configure_firewall "$config_file"
    configure_filevault "$config_file"
    configure_ssh "$config_file"
    configure_user_accounts "$config_file"
    
    log_success "Security configuration complete"
}

# Show current security status
show_security_status() {
    log_info "Current security status:"
    echo
    log_info "Firewall Status:"
    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate
    echo
    log_info "FileVault Status:"
    fdesetup status
    echo
    log_info "SSH Keys:"
    ls -la ~/.ssh/id_* 2>/dev/null || echo "No SSH keys found"
    echo
    log_info "User Accounts:"
    dscl . -list /Users | grep -v "^_"
}

# Functions are available when sourced, no need to export in Zsh
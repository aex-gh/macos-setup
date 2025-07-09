#!/usr/bin/env zsh
# ABOUTME: Configures macOS security settings based on YAML configuration
# ABOUTME: Handles firewall, FileVault, SSH, and user account security

set -euo pipefail

# Load YAML configuration
load_config() {
    local config_file="$1"
    if [[ ! -f "$config_file" ]]; then
        echo "Error: Configuration file not found: $config_file"
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
    
    echo "Configuring firewall from: $config_file"
    
    load_config "$config_file"
    
    local firewall_enabled=$(get_config_value "security.firewall_enabled" "true")
    local stealth_mode=$(get_config_value "security.stealth_mode" "true")
    
    if [[ "$firewall_enabled" = "true" ]]; then
        echo "Enabling firewall"
        sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
        
        if [[ "$stealth_mode" = "true" ]]; then
            echo "Enabling stealth mode"
            sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on
        fi
        
        # Enable logging
        sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setloggingmode on
    fi
    
    echo "Firewall configuration complete"
}

# Configure FileVault
configure_filevault() {
    local config_file="$1"
    
    echo "Configuring FileVault from: $config_file"
    
    load_config "$config_file"
    
    local filevault_enabled=$(get_config_value "security.file_vault" "true")
    
    if [[ "$filevault_enabled" = "true" ]]; then
        # Check if FileVault is already enabled
        if ! fdesetup status | grep -q "FileVault is On"; then
            echo "FileVault is not enabled. Please enable it manually:"
            echo "  System Preferences > Security & Privacy > FileVault > Turn On FileVault"
            echo "  Or use: sudo fdesetup enable (requires user interaction)"
        else
            echo "FileVault is already enabled"
        fi
    fi
    
    echo "FileVault configuration complete"
}

# Configure SSH
configure_ssh() {
    local config_file="$1"
    
    echo "Configuring SSH from: $config_file"
    
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
        echo "Generating $ssh_key_type SSH key"
        ssh-keygen -t "$ssh_key_type" -f "$ssh_key_path" -N ""
    fi
    
    # Configure SSH client
    local ssh_config=~/.ssh/config
    if [[ ! -f "$ssh_config" ]]; then
        echo "Creating SSH client configuration"
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
    
    echo "SSH configuration complete"
}

# Configure user accounts
configure_user_accounts() {
    local config_file="$1"
    
    echo "Configuring user accounts from: $config_file"
    
    load_config "$config_file"
    
    local disable_guest=$(get_config_value "security.disable_guest_user" "true")
    
    if [[ "$disable_guest" = "true" ]]; then
        echo "Disabling guest user"
        sudo dscl . -delete /Users/Guest
        sudo defaults write /Library/Preferences/com.apple.loginwindow GuestEnabled -bool false
    fi
    
    echo "User account configuration complete"
}

# Configure all security settings
configure_security() {
    local config_file="$1"
    
    echo "Configuring security settings from: $config_file"
    
    configure_firewall "$config_file"
    configure_filevault "$config_file"
    configure_ssh "$config_file"
    configure_user_accounts "$config_file"
    
    echo "Security configuration complete"
}

# Show current security status
show_security_status() {
    echo "Current security status:"
    echo
    echo "Firewall Status:"
    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate
    echo
    echo "FileVault Status:"
    fdesetup status
    echo
    echo "SSH Keys:"
    ls -la ~/.ssh/id_* 2>/dev/null || echo "No SSH keys found"
    echo
    echo "User Accounts:"
    dscl . -list /Users | grep -v "^_"
}

# Export functions
export -f configure_security
export -f configure_firewall
export -f configure_filevault
export -f configure_ssh
export -f configure_user_accounts
export -f show_security_status
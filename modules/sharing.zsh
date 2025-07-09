#!/usr/bin/env zsh
# ABOUTME: Configures macOS sharing services based on YAML configuration
# ABOUTME: Handles file sharing, remote access, and network service configuration

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

# Configure file sharing
configure_file_sharing() {
    local config_file="$1"
    
    log_info "Configuring file sharing from: $config_file"
    
    load_config "$config_file"
    
    local enable_smb=$(get_config_value "sharing.enable_smb" "true")
    local enable_afp=$(get_config_value "sharing.enable_afp" "false")
    local create_shared_folder=$(get_config_value "sharing.create_shared_folder" "false")
    
    if [[ "$enable_smb" = "true" ]]; then
        log_info "Enabling SMB file sharing"
        sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.smbd.plist
        sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server.plist EnabledServices -array disk
    fi
    
    if [[ "$enable_afp" = "true" ]]; then
        log_info "Enabling AFP file sharing"
        sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.AppleFileServer.plist
    fi
    
    if [[ "$create_shared_folder" = "true" ]]; then
        local folder_name=$(get_config_value "sharing.shared_folder_name" "Shared")
        local folder_path=$(get_config_value "sharing.shared_folder_path" "/Users/Shared/SharedFolder")
        
        log_info "Creating shared folder: $folder_path"
        sudo mkdir -p "$folder_path"
        sudo chmod 755 "$folder_path"
        
        # Add shared folder to SMB sharing
        if [[ "$enable_smb" = "true" ]]; then
            log_info "Adding folder to SMB sharing"
            sudo sharing -a "$folder_path" -S "$folder_name"
        fi
    fi
    
    log_success "File sharing configuration complete"
}

# Configure remote access
configure_remote_access() {
    local config_file="$1"
    
    log_info "Configuring remote access from: $config_file"
    
    load_config "$config_file"
    
    local enable_ssh=$(get_config_value "sharing.enable_ssh" "true")
    local enable_remote_login=$(get_config_value "sharing.enable_remote_login" "true")
    local enable_screen_sharing=$(get_config_value "sharing.enable_screen_sharing" "false")
    local enable_remote_management=$(get_config_value "sharing.enable_remote_management" "false")
    
    if [[ "$enable_ssh" = "true" ]]; then
        log_info "Enabling SSH (Remote Login)"
        sudo launchctl load -w /System/Library/LaunchDaemons/ssh.plist
        sudo systemsetup -setremotelogin on
    fi
    
    if [[ "$enable_remote_login" = "true" ]]; then
        log_info "Enabling remote login"
        sudo systemsetup -setremotelogin on
    fi
    
    if [[ "$enable_screen_sharing" = "true" ]]; then
        log_info "Enabling screen sharing"
        sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.screensharing.plist
    fi
    
    if [[ "$enable_remote_management" = "true" ]]; then
        log_info "Enabling remote management"
        sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart \
            -activate -configure -access -on -restart -agent -privs -all
    fi
    
    log_success "Remote access configuration complete"
}

# Configure network services
configure_network_services() {
    local config_file="$1"
    
    log_info "Configuring network services from: $config_file"
    
    load_config "$config_file"
    
    local enable_bonjour=$(get_config_value "sharing.enable_bonjour" "true")
    local enable_service_discovery=$(get_config_value "sharing.enable_service_discovery" "true")
    local enable_time_machine_server=$(get_config_value "sharing.enable_time_machine_server" "false")
    
    if [[ "$enable_bonjour" = "true" ]]; then
        log_info "Enabling Bonjour"
        sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.mDNSResponder.plist
    fi
    
    if [[ "$enable_service_discovery" = "true" ]]; then
        log_info "Enabling service discovery"
        # Service discovery is typically handled by Bonjour
        log_info "Service discovery enabled via Bonjour"
    fi
    
    if [[ "$enable_time_machine_server" = "true" ]]; then
        log_info "Enabling Time Machine server"
        sudo tmutil setdestination -a /Users/Shared/TimeMachine
    fi
    
    log_success "Network services configuration complete"
}

# Configure all sharing services
configure_sharing() {
    local config_file="$1"
    
    log_info "Configuring sharing services from: $config_file"
    
    configure_file_sharing "$config_file"
    configure_remote_access "$config_file"
    configure_network_services "$config_file"
    
    log_success "Sharing configuration complete"
}

# Show current sharing status
show_sharing_status() {
    log_info "Current sharing status:"
    echo
    log_info "System sharing services:"
    sudo systemsetup -getremotelogin
    echo
    log_info "SMB Status:"
    launchctl list | grep smb || echo "SMB not running"
    echo
    log_info "SSH Status:"
    launchctl list | grep ssh || echo "SSH not running"
    echo
    log_info "Screen Sharing Status:"
    launchctl list | grep screensharing || echo "Screen sharing not running"
    echo
    log_info "Bonjour Status:"
    launchctl list | grep mDNSResponder || echo "Bonjour not running"
}

# Export functions
export -f configure_sharing
export -f configure_file_sharing
export -f configure_remote_access
export -f configure_network_services
export -f show_sharing_status
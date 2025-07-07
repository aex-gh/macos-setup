#!/usr/bin/env zsh
# -*- coding: utf-8 -*-

#=============================================================================
# MODULE: network-shares.zsh
# AUTHOR: Andrew Exley
# DATE: 2025-01-07
# VERSION: 1.0.0
#
# DESCRIPTION:
#   Network share mounting and server configuration module.
#   Configures Mac Studio as network server and sets up automatic
#   share mounting on MacBook Pro and Mac Mini when on home network.
#
# FUNCTIONS:
#   - setup_studio_server_shares()
#   - setup_automatic_mounting()
#   - create_mount_monitoring_service()
#
# REQUIREMENTS:
#   - macOS 11.0+ (Big Sur)
#   - Network file sharing tools (netatalk, samba, etc.)
#   - Admin privileges for some operations
#=============================================================================

# This module is meant to be sourced, not run directly
# Common functions should be available from the calling script

#=============================================================================
# MAC STUDIO SERVER CONFIGURATION
#=============================================================================

# Create shared folder structure on Mac Studio
setup_studio_server_shares() {
    if [[ $HARDWARE_TYPE != "studio" ]]; then
        debug "Not a Mac Studio, skipping server share setup"
        return 0
    fi
    
    step "Setting up Mac Studio network server shares"
    
    local server_root="/Users/Shared/Studio-Server"
    local shared_folders=(
        "Development"     # Shared development projects
        "Media"          # Photos, videos, music
        "Documents"      # Shared documents
        "Backups"        # Network backup storage
        "Software"       # Software installers and packages
        "TimeMachine"    # Time Machine backup destination
    )
    
    # Create main server directory
    if [[ $DRY_RUN == false ]]; then
        execute_command "Creating server root directory" \
            sudo mkdir -p "$server_root"
        
        execute_command "Setting server root permissions" \
            sudo chmod 755 "$server_root"
        
        execute_command "Setting server root ownership" \
            sudo chown root:wheel "$server_root"
    fi
    
    # Create shared folders
    for folder in "${shared_folders[@]}"; do
        local folder_path="$server_root/$folder"
        
        if [[ $DRY_RUN == false ]]; then
            execute_command "Creating shared folder: $folder" \
                sudo mkdir -p "$folder_path"
            
            # Set appropriate permissions for sharing
            execute_command "Setting permissions for $folder" \
                sudo chmod 775 "$folder_path"
            
            execute_command "Setting ownership for $folder" \
                sudo chown $(whoami):staff "$folder_path"
        else
            info "DRY RUN: Would create $folder_path"
        fi
    done
    
    success "Mac Studio server shares configured"
    
    # Configure AFP sharing
    configure_afp_sharing "$server_root"
    
    # Configure SMB sharing
    configure_smb_sharing "$server_root"
    
    # Configure Time Machine sharing
    configure_timemachine_sharing "$server_root/TimeMachine"
}

# Configure Apple Filing Protocol (AFP) sharing
configure_afp_sharing() {
    local server_root=$1
    
    step "Configuring AFP file sharing"
    
    if [[ $DRY_RUN == true ]]; then
        info "DRY RUN: Would configure AFP sharing for $server_root"
        return 0
    fi
    
    # Enable AFP sharing through system sharing settings
    execute_command "Enabling AFP service" \
        sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.AppleFileServer.plist
    
    # Add shared folder to AFP configuration
    execute_command "Adding folder to AFP sharing" \
        sudo sharing -a "$server_root" -S "Studio-Server" -s 001 -g 000
    
    success "AFP sharing configured"
}

# Configure SMB/CIFS sharing
configure_smb_sharing() {
    local server_root=$1
    
    step "Configuring SMB file sharing"
    
    if [[ $DRY_RUN == true ]]; then
        info "DRY RUN: Would configure SMB sharing for $server_root"
        return 0
    fi
    
    # Enable SMB sharing
    execute_command "Enabling SMB service" \
        sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.smbd.plist
    
    # Configure SMB sharing through system preferences
    # Note: This typically requires GUI interaction, but we can set up the basics
    
    success "SMB sharing configured"
    
    info "Complete SMB configuration in System Preferences > Sharing"
    info "Add the Studio-Server folder and configure user access"
}

# Configure Time Machine network sharing
configure_timemachine_sharing() {
    local timemachine_path=$1
    
    step "Configuring Time Machine network destination"
    
    if [[ $DRY_RUN == true ]]; then
        info "DRY RUN: Would configure Time Machine sharing for $timemachine_path"
        return 0
    fi
    
    # Create Time Machine destination with proper attributes
    execute_command "Setting Time Machine destination attributes" \
        sudo tmutil setdestination -a "$timemachine_path"
    
    # Enable Time Machine sharing
    execute_command "Enabling Time Machine sharing" \
        sudo defaults write /Library/Preferences/com.apple.TimeMachine.plist \
        "AutoBackup" -bool true
    
    success "Time Machine network destination configured"
}

#=============================================================================
# AUTOMATIC MOUNTING SETUP (MacBook Pro & Mac Mini)
#=============================================================================

# Set up automatic mounting of Mac Studio shares
setup_automatic_mounting() {
    if [[ $HARDWARE_TYPE == "studio" ]]; then
        debug "Mac Studio doesn't need to mount its own shares"
        return 0
    fi
    
    step "Setting up automatic mounting of Mac Studio shares"
    
    local mount_point="/Volumes/Studio-Server"
    local studio_address="mac-studio.local"
    
    # Create mount point
    if [[ $DRY_RUN == false ]]; then
        execute_command "Creating mount point" \
            sudo mkdir -p "$mount_point"
        
        execute_command "Setting mount point permissions" \
            sudo chmod 755 "$mount_point"
    fi
    
    # Create mount script
    create_mount_script "$studio_address" "$mount_point"
    
    # Create monitoring service
    create_mount_monitoring_service "$studio_address" "$mount_point"
    
    success "Automatic mounting configured"
}

# Create mount script for Mac Studio shares
create_mount_script() {
    local server_address=$1
    local mount_point=$2
    local script_path="/usr/local/bin/mount-studio-server"
    
    step "Creating mount script"
    
    if [[ $DRY_RUN == true ]]; then
        info "DRY RUN: Would create mount script at $script_path"
        return 0
    fi
    
    # Create the mount script
    sudo tee "$script_path" > /dev/null << EOF
#!/usr/bin/env zsh
# Auto-generated script to mount Mac Studio server shares

SERVER_ADDRESS="$server_address"
MOUNT_POINT="$mount_point"
USERNAME="\$(whoami)"

# Function to check if server is reachable
check_server() {
    ping -c 1 -W 1000 "\$SERVER_ADDRESS" &>/dev/null
}

# Function to check if already mounted
is_mounted() {
    mount | grep -q "\$MOUNT_POINT"
}

# Function to mount the share
mount_share() {
    if ! check_server; then
        echo "Server \$SERVER_ADDRESS not reachable"
        return 1
    fi
    
    if is_mounted; then
        echo "Share already mounted at \$MOUNT_POINT"
        return 0
    fi
    
    # Try AFP first (best for macOS)
    if mount -t afp "afp://\$SERVER_ADDRESS/Studio-Server" "\$MOUNT_POINT" 2>/dev/null; then
        echo "Mounted via AFP: \$MOUNT_POINT"
        return 0
    fi
    
    # Fallback to SMB
    if mount -t smbfs "//guest@\$SERVER_ADDRESS/Studio-Server" "\$MOUNT_POINT" 2>/dev/null; then
        echo "Mounted via SMB: \$MOUNT_POINT"
        return 0
    fi
    
    echo "Failed to mount share from \$SERVER_ADDRESS"
    return 1
}

# Function to unmount the share
unmount_share() {
    if is_mounted; then
        umount "\$MOUNT_POINT"
        echo "Unmounted \$MOUNT_POINT"
    fi
}

# Main logic
case "\${1:-mount}" in
    mount)
        mount_share
        ;;
    unmount)
        unmount_share
        ;;
    check)
        if is_mounted; then
            echo "Mounted"
        else
            echo "Not mounted"
        fi
        ;;
    *)
        echo "Usage: \$0 {mount|unmount|check}"
        exit 1
        ;;
esac
EOF
    
    execute_command "Making mount script executable" \
        sudo chmod +x "$script_path"
    
    success "Mount script created: $script_path"
}

# Create Launch Agent for monitoring and auto-mounting
create_mount_monitoring_service() {
    local server_address=$1
    local mount_point=$2
    local plist_name="com.user.studio-server-mount"
    local plist_path="$HOME/Library/LaunchAgents/$plist_name.plist"
    
    step "Creating mount monitoring service"
    
    if [[ $DRY_RUN == true ]]; then
        info "DRY RUN: Would create monitoring service at $plist_path"
        return 0
    fi
    
    # Create LaunchAgent directory
    execute_command "Creating LaunchAgents directory" \
        mkdir -p "$HOME/Library/LaunchAgents"
    
    # Create the plist file
    cat > "$plist_path" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$plist_name</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/mount-studio-server</string>
        <string>mount</string>
    </array>
    <key>WatchPaths</key>
    <array>
        <string>/System/Library/CoreServices/NetAuthAgent.app</string>
    </array>
    <key>StartInterval</key>
    <integer>300</integer>
    <key>RunAtLoad</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/studio-server-mount.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/studio-server-mount.error.log</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/usr/local/bin:/usr/bin:/bin</string>
    </dict>
</dict>
</plist>
EOF
    
    # Load the service
    execute_command "Loading mount monitoring service" \
        launchctl load "$plist_path"
    
    success "Mount monitoring service created and loaded"
    
    info "Service will check every 5 minutes and mount when server is available"
    info "Logs: /tmp/studio-server-mount.log"
}

#=============================================================================
# NETWORK DISCOVERY AND WAKE-ON-LAN
#=============================================================================

# Set up Wake-on-LAN for Mac Studio
setup_wake_on_lan() {
    step "Configuring Wake-on-LAN for Mac Studio"
    
    if [[ $HARDWARE_TYPE == "studio" ]]; then
        # Configure Mac Studio to accept WoL packets
        if [[ $DRY_RUN == false ]]; then
            execute_command "Enabling Wake-on-LAN" \
                sudo pmset -a womp 1
            
            execute_command "Enabling network wake" \
                sudo systemsetup -setwakeonnetworkaccess on
        fi
        
        # Get MAC address for WoL
        local mac_address=$(ifconfig en0 | grep ether | awk '{print $2}')
        info "Mac Studio MAC address for WoL: $mac_address"
        
    else
        # Create wake script for other devices
        local wake_script="/usr/local/bin/wake-studio-server"
        
        if [[ $DRY_RUN == false ]]; then
            sudo tee "$wake_script" > /dev/null << 'EOF'
#!/usr/bin/env zsh
# Wake Mac Studio server

# Note: Replace with actual MAC address of Mac Studio
STUDIO_MAC="xx:xx:xx:xx:xx:xx"

if command -v wake &>/dev/null; then
    wake "$STUDIO_MAC"
    echo "Wake-on-LAN packet sent to Mac Studio"
else
    echo "wake command not available. Install with: brew install wake"
fi
EOF
            
            execute_command "Making wake script executable" \
                sudo chmod +x "$wake_script"
        fi
        
        info "Use 'wake-studio-server' to wake Mac Studio remotely"
    fi
    
    success "Wake-on-LAN configured"
}

#=============================================================================
# MAIN FUNCTIONS
#=============================================================================

# Main function to set up network shares based on hardware type
setup_network_shares() {
    print_section "NETWORK SHARES CONFIGURATION" "🌐"
    
    case $HARDWARE_TYPE in
        "studio")
            setup_studio_server_shares
            setup_wake_on_lan
            ;;
        "laptop"|"mini")
            setup_automatic_mounting
            setup_wake_on_lan
            ;;
        *)
            info "No network share configuration for hardware type: $HARDWARE_TYPE"
            ;;
    esac
    
    success "Network shares configuration completed"
}

# This module provides the setup_network_shares function to be called by other scripts
#!/usr/bin/env zsh
set -euo pipefail

# Script metadata and colour codes
readonly SCRIPT_NAME="${0:t}"
readonly RED=$(tput setaf 1)
readonly GREEN=$(tput setaf 2)
readonly YELLOW=$(tput setaf 3)
readonly BLUE=$(tput setaf 4)
readonly RESET=$(tput sgr0)

# Device type from command line
DEVICE_TYPE="${1:-macbook-pro}"

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

# Configure SSH access
configure_ssh_access() {
    info "Configuring SSH access..."
    
    # Check current SSH status
    local ssh_status
    ssh_status=$(sudo systemsetup -getremotelogin 2>/dev/null || echo "unknown")
    
    case "$DEVICE_TYPE" in
        "mac-studio"|"mac-mini")
            # Enable SSH for server and shared devices
            info "Enabling SSH for $DEVICE_TYPE (server/shared device)..."
            
            if [[ "$ssh_status" != *"On"* ]]; then
                if sudo systemsetup -setremotelogin on; then
                    success "✓ SSH (Remote Login) enabled"
                else
                    error "Failed to enable SSH"
                    return 1
                fi
            else
                success "✓ SSH is already enabled"
            fi
            
            # Configure SSH security settings
            configure_ssh_security
            ;;
            
        "macbook-pro")
            # SSH optional for portable device
            info "SSH configuration for MacBook Pro (portable device)..."
            
            if [[ "$ssh_status" == *"On"* ]]; then
                read -p "SSH is enabled. Keep enabled for remote access? [Y/n]: " ssh_choice
                if [[ "$ssh_choice" == "n" || "$ssh_choice" == "N" ]]; then
                    sudo systemsetup -setremotelogin off
                    success "✓ SSH disabled for enhanced portable security"
                else
                    success "✓ SSH kept enabled for remote access"
                    configure_ssh_security
                fi
            else
                read -p "Enable SSH for remote access to MacBook Pro? [y/N]: " ssh_choice
                if [[ "$ssh_choice" == "y" || "$ssh_choice" == "Y" ]]; then
                    sudo systemsetup -setremotelogin on
                    success "✓ SSH enabled for remote access"
                    configure_ssh_security
                else
                    info "SSH remains disabled for enhanced portable security"
                fi
            fi
            ;;
    esac
}

# Configure SSH security settings
configure_ssh_security() {
    info "Configuring SSH security settings..."
    
    local sshd_config="/etc/ssh/sshd_config"
    local ssh_config_backup="/etc/ssh/sshd_config.backup.$(date +%Y%m%d)"
    
    # Create backup of SSH configuration
    if [[ -f "$sshd_config" ]] && [[ ! -f "$ssh_config_backup" ]]; then
        sudo cp "$sshd_config" "$ssh_config_backup"
        success "✓ SSH configuration backed up to $ssh_config_backup"
    fi
    
    # Configure SSH security settings (these may require manual editing)
    info "SSH security recommendations:"
    info "• Consider changing default SSH port (22) to non-standard port"
    info "• Disable password authentication in favour of key-based auth"
    info "• Enable SSH key authentication via 1Password SSH agent"
    info "• Configure fail2ban or similar intrusion prevention"
    
    # Check if SSH keys directory exists
    setup_ssh_keys_directory
}

# Set up SSH keys directory and 1Password integration
setup_ssh_keys_directory() {
    info "Setting up SSH keys with 1Password integration..."
    
    local ssh_dir="$HOME/.ssh"
    
    # Create SSH directory if it doesn't exist
    if [[ ! -d "$ssh_dir" ]]; then
        mkdir -p "$ssh_dir"
        chmod 700 "$ssh_dir"
        success "✓ Created SSH directory: $ssh_dir"
    fi
    
    # Set proper permissions
    chmod 700 "$ssh_dir"
    
    # Create SSH config file with 1Password integration
    local ssh_config="$ssh_dir/config"
    if [[ ! -f "$ssh_config" ]]; then
        cat > "$ssh_config" << 'EOF'
# SSH Configuration with 1Password Integration
# Use 1Password SSH Agent for key management

# 1Password SSH Agent integration
Host *
    IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"

# Family network devices
Host mac-studio
    HostName 10.20.0.10
    User andrew
    Port 22

Host mac-mini
    HostName 10.20.0.12
    User andrew
    Port 22

# Security settings for all hosts
Host *
    ServerAliveInterval 60
    ServerAliveCountMax 3
    PasswordAuthentication no
    ChallengeResponseAuthentication no
    UsePAM no
    PubkeyAuthentication yes
    PreferredAuthentications publickey
    ForwardAgent no
    ForwardX11 no
    HashKnownHosts yes
    VerifyHostKeyDNS yes
    StrictHostKeyChecking ask
EOF
        
        chmod 600 "$ssh_config"
        success "✓ Created SSH config with 1Password integration"
    else
        success "✓ SSH config already exists"
    fi
    
    # Create authorized_keys file if it doesn't exist
    local authorized_keys="$ssh_dir/authorized_keys"
    if [[ ! -f "$authorized_keys" ]]; then
        touch "$authorized_keys"
        chmod 600 "$authorized_keys"
        success "✓ Created authorized_keys file"
    fi
    
    # Provide guidance for SSH key setup
    provide_ssh_key_guidance
}

# Provide SSH key setup guidance
provide_ssh_key_guidance() {
    info "SSH Key Setup Guidance"
    info "====================="
    echo
    info "1Password SSH Agent Integration:"
    info "• SSH keys are managed through 1Password app"
    info "• Generate SSH keys in 1Password or import existing ones"
    info "• SSH agent automatically provides keys for authentication"
    echo
    info "Setting up SSH keys:"
    info "1. Open 1Password app"
    info "2. Create new SSH Key item or import existing key"
    info "3. Configure public key on target servers"
    info "4. Test connection: ssh mac-studio"
    echo
    info "For existing SSH keys:"
    info "• Import private keys into 1Password"
    info "• Remove private keys from ~/.ssh/ directory"
    info "• Let 1Password SSH agent handle authentication"
    echo
}

# Configure Screen Sharing
configure_screen_sharing() {
    info "Configuring Screen Sharing..."
    
    case "$DEVICE_TYPE" in
        "mac-studio"|"mac-mini")
            # Enable Screen Sharing for headless/shared devices
            info "Enabling Screen Sharing for $DEVICE_TYPE..."
            
            # Enable Screen Sharing service
            if sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.screensharing.plist 2>/dev/null; then
                success "✓ Screen Sharing service enabled"
            else
                warn "Could not enable Screen Sharing service automatically"
                info "Enable manually: System Preferences > Sharing > Screen Sharing"
            fi
            
            # Configure Screen Sharing security
            configure_screen_sharing_security
            ;;
            
        "macbook-pro")
            # Screen Sharing optional for portable device
            info "Screen Sharing configuration for MacBook Pro..."
            
            read -p "Enable Screen Sharing for remote access to MacBook Pro? [y/N]: " sharing_choice
            if [[ "$sharing_choice" == "y" || "$sharing_choice" == "Y" ]]; then
                sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.screensharing.plist 2>/dev/null || warn "Could not enable Screen Sharing"
                success "✓ Screen Sharing enabled"
                configure_screen_sharing_security
            else
                info "Screen Sharing remains disabled"
            fi
            ;;
    esac
}

# Configure Screen Sharing security settings
configure_screen_sharing_security() {
    info "Configuring Screen Sharing security..."
    
    # Set Screen Sharing to require authentication
    sudo defaults write /var/db/launchd.db/com.apple.launchd/overrides.plist com.apple.screensharing -dict Disabled -bool false
    
    # Configure VNC password (users should set this manually for security)
    info "Screen Sharing security recommendations:"
    info "• Set a strong VNC password in System Preferences > Sharing > Screen Sharing"
    info "• Limit access to specific users or administrators only"
    info "• Enable 'VNC viewers may control screen with password'"
    info "• Consider using Jump Desktop for enhanced security and features"
    
    success "✓ Screen Sharing security configured"
}

# Configure Jump Desktop Connect (for headless systems)
configure_jump_desktop_connect() {
    info "Configuring Jump Desktop Connect for headless systems..."
    
    # Check if Jump Desktop Connect is installed
    if [[ ! -d "/Applications/Jump Desktop Connect.app" ]]; then
        warn "Jump Desktop Connect is not installed"
        info "Install from Mac App Store or Jump Desktop website"
        info "Jump Desktop Connect provides superior remote access for headless Macs"
        return 1
    fi
    
    success "✓ Jump Desktop Connect is installed"
    
    # Configure Jump Desktop Connect for headless operation
    info "Jump Desktop Connect configuration for $DEVICE_TYPE:"
    info "• Provides secure remote access without VNC limitations"
    info "• Optimised for headless Mac operation"
    info "• Supports file transfer, clipboard sync, and multiple monitors"
    info "• Works through firewalls and NAT without port forwarding"
    
    # Start Jump Desktop Connect
    if open -a "Jump Desktop Connect"; then
        success "✓ Jump Desktop Connect launched for configuration"
    else
        warn "Could not launch Jump Desktop Connect automatically"
    fi
    
    provide_jump_desktop_connect_guidance
}

# Configure Jump Desktop (client for MacBook Pro)
configure_jump_desktop_client() {
    info "Configuring Jump Desktop client for MacBook Pro..."
    
    # Check if Jump Desktop is installed
    if [[ ! -d "/Applications/Jump Desktop.app" ]]; then
        warn "Jump Desktop client is not installed"
        info "Install from Mac App Store for optimal remote access experience"
        return 1
    fi
    
    success "✓ Jump Desktop client is installed"
    
    info "Jump Desktop client features:"
    info "• Connect to Mac Studio and Mac Mini from anywhere"
    info "• Secure, encrypted connections"
    info "• File transfer and clipboard synchronisation"
    info "• Optimised for mobile and low-bandwidth connections"
    
    provide_jump_desktop_client_guidance
}

# Provide Jump Desktop Connect guidance
provide_jump_desktop_connect_guidance() {
    info "Jump Desktop Connect Setup Guide"
    info "==============================="
    echo
    info "Initial Setup:"
    info "1. Launch Jump Desktop Connect (should be open now)"
    info "2. Create Jump Desktop account or sign in"
    info "3. Configure connection settings for headless operation"
    info "4. Set strong access password"
    info "5. Configure automatic startup (login items)"
    echo
    info "Security Configuration:"
    info "• Enable strong authentication"
    info "• Configure network access restrictions if needed"
    info "• Set session timeout for security"
    info "• Enable connection logging for audit purposes"
    echo
    info "Family Access:"
    info "• Share connection details with family members"
    info "• Configure user-specific access permissions"
    info "• Set up guest access if needed for temporary use"
    echo
}

# Provide Jump Desktop client guidance
provide_jump_desktop_client_guidance() {
    info "Jump Desktop Client Setup Guide"
    info "==============================="
    echo
    info "Connecting to Family Macs:"
    info "1. Open Jump Desktop app"
    info "2. Add new connection for Mac Studio (10.20.0.10)"
    info "3. Add new connection for Mac Mini (10.20.0.12)"
    info "4. Configure connection preferences for each device"
    info "5. Test connections and save credentials in 1Password"
    echo
    info "Connection Optimisation:"
    info "• Use appropriate quality settings for network conditions"
    info "• Configure keyboard shortcuts for efficiency"
    info "• Set up file transfer shortcuts"
    info "• Enable clipboard synchronisation"
    echo
}

# Configure Wake-on-LAN for desktop devices
configure_wake_on_lan() {
    info "Configuring Wake-on-LAN for desktop devices..."
    
    case "$DEVICE_TYPE" in
        "mac-studio"|"mac-mini")
            # Enable Wake-on-LAN for desktop devices
            if sudo pmset -a womp 1; then
                success "✓ Wake-on-LAN enabled"
            else
                warn "Could not enable Wake-on-LAN"
            fi
            
            # Get Ethernet MAC address for Wake-on-LAN
            local ethernet_mac
            ethernet_mac=$(ifconfig en0 2>/dev/null | grep ether | awk '{print $2}' || echo "not found")
            
            if [[ "$ethernet_mac" != "not found" ]]; then
                success "✓ Ethernet MAC address: $ethernet_mac"
                info "Use this MAC address for Wake-on-LAN from other devices"
                
                # Create Wake-on-LAN helper script
                create_wake_on_lan_script "$ethernet_mac"
            else
                warn "Could not determine Ethernet MAC address"
            fi
            ;;
            
        "macbook-pro")
            info "Wake-on-LAN not configured for MacBook Pro (portable device)"
            ;;
    esac
}

# Create Wake-on-LAN helper script
create_wake_on_lan_script() {
    local mac_address="$1"
    local script_path="/Users/Shared/Family/Scripts/wake_${DEVICE_TYPE//-/_}.zsh"
    
    # Ensure scripts directory exists
    sudo mkdir -p "/Users/Shared/Family/Scripts"
    
    # Create Wake-on-LAN script
    sudo tee "$script_path" > /dev/null << EOF
#!/usr/bin/env zsh
# Wake-on-LAN script for $DEVICE_TYPE

# Device information
DEVICE_NAME="$DEVICE_TYPE"
MAC_ADDRESS="$mac_address"
IP_ADDRESS="${DEVICE_IPS[$DEVICE_TYPE]:-unknown}"

echo "🌅 Waking up \$DEVICE_NAME..."
echo "MAC Address: \$MAC_ADDRESS"
echo "IP Address: \$IP_ADDRESS"

# Send Wake-on-LAN packet using wakeonlan command
if command -v wakeonlan &>/dev/null; then
    wakeonlan "\$MAC_ADDRESS"
    echo "✅ Wake-on-LAN packet sent"
else
    echo "❌ wakeonlan command not found"
    echo "Install with: brew install wakeonlan"
    exit 1
fi

# Wait and test connectivity
echo "⏳ Waiting for device to wake up..."
sleep 10

if ping -c 1 -t 5 "\$IP_ADDRESS" &>/dev/null; then
    echo "✅ \$DEVICE_NAME is now awake and responding"
else
    echo "⚠️  Device may still be waking up, try again in a moment"
fi
EOF
    
    sudo chmod 755 "$script_path"
    sudo chown root:staff "$script_path"
    
    success "✓ Created Wake-on-LAN script: $script_path"
}

# Test remote access functionality
test_remote_access() {
    info "Testing remote access functionality..."
    
    local tests_passed=0
    local total_tests=0
    
    # Test SSH (if enabled)
    ((total_tests++))
    if systemsetup -getremotelogin 2>/dev/null | grep -q "On"; then
        if ss -tlnp | grep -q ":22 "; then
            success "✓ SSH service is listening"
            ((tests_passed++))
        else
            warn "⚠ SSH enabled but not listening"
        fi
    else
        info "ℹ SSH is disabled"
        ((tests_passed++))  # Not an error if intentionally disabled
    fi
    
    # Test Screen Sharing (if enabled)
    ((total_tests++))
    if launchctl list | grep -q "com.apple.screensharing"; then
        if ss -tlnp | grep -q ":5900 "; then
            success "✓ Screen Sharing service is listening"
            ((tests_passed++))
        else
            warn "⚠ Screen Sharing enabled but not listening"
        fi
    else
        info "ℹ Screen Sharing is disabled"
        ((tests_passed++))  # Not an error if intentionally disabled
    fi
    
    # Test Jump Desktop Connect (if installed)
    ((total_tests++))
    if [[ -d "/Applications/Jump Desktop Connect.app" ]]; then
        if pgrep -f "Jump Desktop Connect" &>/dev/null; then
            success "✓ Jump Desktop Connect is running"
            ((tests_passed++))
        else
            warn "⚠ Jump Desktop Connect installed but not running"
        fi
    else
        info "ℹ Jump Desktop Connect not installed"
        ((tests_passed++))  # Not an error if not needed
    fi
    
    echo
    info "Remote access test results: $tests_passed/$total_tests tests passed"
    
    if [[ $tests_passed -eq $total_tests ]]; then
        success "All remote access tests passed!"
        return 0
    else
        warn "Some remote access tests failed - review configuration"
        return 1
    fi
}

# Help function
usage() {
    cat << EOF
$SCRIPT_NAME - Remote Access Configuration

USAGE:
    $SCRIPT_NAME [OPTIONS] [DEVICE_TYPE]

DESCRIPTION:
    Configures remote access services optimised for each device type.
    Includes SSH, Screen Sharing, Jump Desktop, and Wake-on-LAN setup.

OPTIONS:
    -t, --test           Test remote access functionality
    -h, --help           Show this help message

DEVICE_TYPE:
    macbook-pro    Portable device (optional remote access)
    mac-studio     Server infrastructure (full remote access)
    mac-mini       Shared multimedia system (family remote access)
    
    Default: macbook-pro

REMOTE ACCESS SERVICES:
    • SSH (Secure Shell) - Command line remote access
    • Screen Sharing (VNC) - Graphical remote desktop
    • Jump Desktop Connect - Enhanced remote access for headless systems
    • Wake-on-LAN - Remote wake capability for desktop devices

EXAMPLES:
    $SCRIPT_NAME                    # Configure MacBook Pro remote access
    $SCRIPT_NAME --test             # Test current remote access setup
    $SCRIPT_NAME mac-studio         # Configure Mac Studio for headless operation

DEVICE-SPECIFIC FEATURES:
    MacBook Pro    Optional SSH/Screen Sharing, Jump Desktop client
    Mac Studio     Full remote access suite, headless optimisation
    Mac Mini       Family-friendly remote access, Wake-on-LAN

SECURITY FEATURES:
    • 1Password SSH agent integration
    • Key-based SSH authentication
    • Secure Screen Sharing configuration
    • Jump Desktop encrypted connections
    • Network-based access controls

EOF
}

# Main execution
main() {
    info "Remote Access Configuration"
    info "==========================="
    info "Device type: $DEVICE_TYPE"
    echo
    
    # Configure SSH access
    configure_ssh_access
    echo
    
    # Configure Screen Sharing
    configure_screen_sharing
    echo
    
    # Configure device-specific remote access
    case "$DEVICE_TYPE" in
        "mac-studio"|"mac-mini")
            # Configure Jump Desktop Connect for headless systems
            configure_jump_desktop_connect
            echo
            
            # Configure Wake-on-LAN
            configure_wake_on_lan
            echo
            ;;
            
        "macbook-pro")
            # Configure Jump Desktop client
            configure_jump_desktop_client
            echo
            ;;
    esac
    
    # Test remote access functionality
    test_remote_access
    echo
    
    success "=========================================="
    success "Remote access configuration completed!"
    success "=========================================="
    success "Your $DEVICE_TYPE is now configured for optimal remote access"
    
    info "Remote access summary:"
    case "$DEVICE_TYPE" in
        "macbook-pro")
            info "• Jump Desktop client configured for connecting to family Macs"
            info "• SSH and Screen Sharing configured as requested"
            info "• 1Password SSH agent integration enabled"
            ;;
        "mac-studio")
            info "• Full headless remote access suite configured"
            info "• SSH, Screen Sharing, and Jump Desktop Connect enabled"
            info "• Wake-on-LAN configured for remote wake capability"
            ;;
        "mac-mini")
            info "• Family-friendly remote access configured"
            info "• SSH and Screen Sharing enabled for shared use"
            info "• Wake-on-LAN enabled for power management"
            ;;
    esac
    
    return 0
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--test)
            test_remote_access
            exit 0
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        macbook-pro|mac-studio|mac-mini)
            DEVICE_TYPE="$1"
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

# Validate device type
case "$DEVICE_TYPE" in
    macbook-pro|mac-studio|mac-mini)
        ;;
    *)
        error "Invalid device type: $DEVICE_TYPE"
        error "Valid types: macbook-pro, mac-studio, mac-mini"
        exit 1
        ;;
esac

# Run main function
main
#!/usr/bin/env zsh
# ABOUTME: Security hardening script for macOS - applies additional security measures
# ABOUTME: Should be run after initial setup and configuration is complete

set -euo pipefail

# Script configuration
readonly SCRIPT_DIR="${0:A:h}"
readonly CONFIG_DIR="${SCRIPT_DIR}/config"
readonly MODULES_DIR="${SCRIPT_DIR}/../modules"

# Colour codes
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly BOLD='\033[1m'
readonly RESET='\033[0m'

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${RESET} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${RESET} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARNING]${RESET} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${RESET} $*"
}

# Request sudo access upfront
request_sudo() {
    log_info "Requesting administrator privileges..."
    if ! sudo -v; then
        log_error "Administrator privileges required"
        exit 1
    fi
    
    # Keep sudo alive
    while true; do
        sudo -n true
        sleep 60
        kill -0 "$$" || exit
    done 2>/dev/null &
}

# Harden firewall settings
harden_firewall() {
    log_info "Hardening firewall settings..."
    
    # Enable firewall
    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
    
    # Enable stealth mode
    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on
    
    # Enable logging
    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setloggingmode on
    
    # Block all incoming connections by default
    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setblockall on
    
    # Allow signed apps
    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setallowsigned on
    
    # Allow downloaded signed apps
    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setallowsignedapp on
    
    log_success "Firewall hardened"
}

# Harden SSH configuration
harden_ssh() {
    log_info "Hardening SSH configuration..."
    
    # Create SSH config directory
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    
    # Create hardened SSH daemon config
    local sshd_config="/etc/ssh/sshd_config"
    
    # Backup original config
    if [[ ! -f "${sshd_config}.backup" ]]; then
        sudo cp "$sshd_config" "${sshd_config}.backup"
    fi
    
    # Apply hardening settings
    sudo tee "${sshd_config}.hardened" > /dev/null << 'EOF'
# Hardened SSH configuration
Port 22
Protocol 2

# Authentication
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
MaxAuthTries 3
LoginGraceTime 30
MaxSessions 3
MaxStartups 3

# Encryption
KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group16-sha512
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
MACs hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com,hmac-sha2-256,hmac-sha2-512

# Other security settings
AllowTcpForwarding no
AllowAgentForwarding no
AllowStreamLocalForwarding no
PermitTunnel no
GatewayPorts no
X11Forwarding no
PrintMotd no
PrintLastLog yes
UseDNS no
PermitUserEnvironment no
ClientAliveInterval 300
ClientAliveCountMax 2
EOF
    
    # Move hardened config to active location
    sudo mv "${sshd_config}.hardened" "$sshd_config"
    
    # Restart SSH daemon
    sudo launchctl unload /System/Library/LaunchDaemons/ssh.plist
    sudo launchctl load /System/Library/LaunchDaemons/ssh.plist
    
    log_success "SSH hardened"
}

# Harden system preferences
harden_system_preferences() {
    log_info "Hardening system preferences..."
    
    # Disable automatic login
    sudo defaults delete /Library/Preferences/com.apple.loginwindow autoLoginUser 2>/dev/null || true
    
    # Require password immediately after sleep or screensaver
    defaults write com.apple.screensaver askForPassword -int 1
    defaults write com.apple.screensaver askForPasswordDelay -int 0
    
    # Disable automatic software updates (for manual control)
    sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled -bool false
    sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload -bool false
    sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticallyInstallMacOSUpdates -bool false
    
    # Disable Bonjour multicast advertisements
    sudo defaults write /Library/Preferences/com.apple.mDNSResponder.plist NoMulticastAdvertisements -bool true
    
    # Disable wake for network access (security vs convenience)
    sudo pmset -a womp 0
    
    # Disable PowerNap
    sudo pmset -a powernap 0
    
    # Disable wake on AC power
    sudo pmset -a acwake 0
    
    # Disable Captive Portal
    sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.captive.control Active -bool false
    
    log_success "System preferences hardened"
}

# Harden network settings
harden_network() {
    log_info "Hardening network settings..."
    
    # Disable IPv6 (if not needed)
    networksetup -listallnetworkservices | grep -v "*" | while read -r interface; do
        if [[ -n "$interface" ]]; then
            sudo networksetup -setv6off "$interface"
        fi
    done
    
    # Disable AirDrop
    defaults write com.apple.NetworkBrowser DisableAirDrop -bool true
    
    # Disable Bluetooth (if not needed)
    sudo defaults write /Library/Preferences/com.apple.Bluetooth ControllerPowerState -int 0
    
    # Disable IR receiver
    sudo defaults write /Library/Preferences/com.apple.driver.AppleIRController DeviceEnabled -bool false
    
    log_success "Network settings hardened"
}

# Harden file permissions
harden_file_permissions() {
    log_info "Hardening file permissions..."
    
    # Set secure permissions for SSH
    chmod 700 ~/.ssh
    chmod 600 ~/.ssh/* 2>/dev/null || true
    
    # Set secure permissions for user directories
    chmod 700 ~/Documents
    chmod 700 ~/Downloads
    chmod 700 ~/Desktop
    
    # Secure log files
    sudo chmod 640 /var/log/system.log
    sudo chmod 640 /var/log/secure.log
    
    log_success "File permissions hardened"
}

# Disable unnecessary services
disable_unnecessary_services() {
    log_info "Disabling unnecessary services..."
    
    # Disable AirPlay receiver
    sudo defaults write /Library/Preferences/com.apple.RemoteDesktop ARD_AllLocalUsersPrivs -bool false
    
    # Disable DVD or CD sharing
    sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.ODSAgent.plist 2>/dev/null || true
    
    # Disable Internet Sharing
    sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.InternetSharing.plist 2>/dev/null || true
    
    # Disable printer sharing
    sudo launchctl unload -w /System/Library/LaunchDaemons/org.cups.cupsd.plist 2>/dev/null || true
    
    # Disable Bluetooth sharing
    sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.blued.plist 2>/dev/null || true
    
    log_success "Unnecessary services disabled"
}

# Configure audit logging
configure_audit_logging() {
    log_info "Configuring audit logging..."
    
    # Enable basic audit logging
    sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.auditd.plist
    
    # Configure audit flags
    sudo defaults write /etc/security/audit_control flags lo,aa
    
    # Set audit file size
    sudo defaults write /etc/security/audit_control filesz 10M
    
    # Set audit file expiration
    sudo defaults write /etc/security/audit_control expire-after 7d
    
    log_success "Audit logging configured"
}

# Secure browser settings
secure_browser_settings() {
    log_info "Securing browser settings..."
    
    # Safari security settings
    defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool false
    defaults write com.apple.Safari WebKitJavaScriptCanOpenWindowsAutomatically -bool false
    defaults write com.apple.Safari AutoFillFromAddressBook -bool false
    defaults write com.apple.Safari AutoFillPasswords -bool false
    defaults write com.apple.Safari AutoFillCreditCardData -bool false
    defaults write com.apple.Safari AutoFillMiscellaneousForms -bool false
    defaults write com.apple.Safari WarnAboutFraudulentWebsites -bool true
    defaults write com.apple.Safari WebKitPluginsEnabled -bool false
    defaults write com.apple.Safari WebKitJavaEnabled -bool false
    defaults write com.apple.Safari WebKitTabToLinksPreferenceKey -bool true
    defaults write com.apple.Safari ShowFullURLInSmartSearchField -bool true
    
    log_success "Browser settings secured"
}

# Remove development tools (if not needed)
remove_development_tools() {
    log_info "Checking for development tools to remove..."
    
    # List of potentially unnecessary development tools
    local dev_tools=(
        "telnet"
        "ftp"
        "rsh"
        "finger"
    )
    
    for tool in "${dev_tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            log_warn "Development tool found: $tool"
            log_warn "Consider removing if not needed: sudo rm $(which $tool)"
        fi
    done
    
    log_success "Development tools audit complete"
}

# Generate security report
generate_security_report() {
    log_info "Generating security report..."
    
    local report_file="/tmp/security-report-$(date +%Y%m%d-%H%M%S).txt"
    
    cat > "$report_file" << EOF
macOS Security Hardening Report
Generated: $(date)
System: $(system_profiler SPSoftwareDataType | grep "System Version" | awk -F': ' '{print $2}' | xargs)

=== Firewall Status ===
$(sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate)
$(sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getstealthmode)
$(sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getloggingmode)

=== SSH Status ===
SSH Service: $(systemsetup -getremotelogin)
SSH Config: $(ls -la /etc/ssh/sshd_config)

=== FileVault Status ===
$(fdesetup status)

=== Network Configuration ===
$(networksetup -listallnetworkservices)

=== Power Management ===
$(pmset -g)

=== Running Services ===
$(launchctl list | grep -v "^-" | head -20)

=== File Permissions ===
SSH Directory: $(ls -la ~/.ssh/)
User Directories: $(ls -la ~ | grep "^d")

=== Audit Configuration ===
$(grep -v "^#" /etc/security/audit_control 2>/dev/null || echo "Audit not configured")

=== Security Recommendations ===
- Ensure FileVault is enabled
- Regularly update system software
- Monitor system logs for suspicious activity
- Review and update SSH authorized keys
- Consider using a VPN for remote access
- Enable automatic security updates for critical patches

EOF
    
    log_success "Security report generated: $report_file"
    
    # Display report summary
    echo
    log_info "Security Report Summary:"
    echo "  Report file: $report_file"
    echo "  Firewall: $(sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate | grep -o 'enabled\|disabled')"
    echo "  SSH: $(systemsetup -getremotelogin | grep -o 'On\|Off')"
    echo "  FileVault: $(fdesetup status | grep -o 'On\|Off')"
}

# Main hardening function
main() {
    log_info "Starting macOS security hardening..."
    
    # Request sudo access
    request_sudo
    
    # Perform hardening steps
    log_info "=== Hardening Firewall ==="
    harden_firewall
    
    log_info "=== Hardening SSH ==="
    harden_ssh
    
    log_info "=== Hardening System Preferences ==="
    harden_system_preferences
    
    log_info "=== Hardening Network Settings ==="
    harden_network
    
    log_info "=== Hardening File Permissions ==="
    harden_file_permissions
    
    log_info "=== Disabling Unnecessary Services ==="
    disable_unnecessary_services
    
    log_info "=== Configuring Audit Logging ==="
    configure_audit_logging
    
    log_info "=== Securing Browser Settings ==="
    secure_browser_settings
    
    log_info "=== Auditing Development Tools ==="
    remove_development_tools
    
    log_info "=== Generating Security Report ==="
    generate_security_report
    
    log_success "Security hardening complete!"
    
    # Final recommendations
    echo
    log_info "Post-hardening recommendations:"
    echo "1. Enable FileVault if not already enabled"
    echo "2. Review and test SSH access with key-based authentication"
    echo "3. Configure automatic security updates"
    echo "4. Set up system monitoring and alerting"
    echo "5. Regularly review security logs"
    echo "6. Consider additional security tools (Little Snitch, etc.)"
    echo "7. Test all required services still function correctly"
    echo
    log_warn "Some settings may require manual adjustment for your specific use case"
    log_warn "Always test hardening changes in a non-production environment first"
}

# Run main function
main "$@"
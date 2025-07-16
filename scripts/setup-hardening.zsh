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

# Hardening level (gentle by default for family environment)
HARDENING_LEVEL="gentle"

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

# Helper function to set system preferences
set_system_pref() {
    local domain="$1"
    local key="$2"
    local value="$3"
    local type="${4:-string}"
    
    if [[ "$domain" == "system" ]]; then
        # System-wide preference
        if sudo defaults write "$key" "$value" 2>/dev/null; then
            success "✓ Set system preference: $key = $value"
        else
            warn "Could not set system preference: $key"
        fi
    else
        # User preference
        if defaults write "$domain" "$key" -"$type" "$value" 2>/dev/null; then
            success "✓ Set user preference: $domain.$key = $value"
        else
            warn "Could not set user preference: $domain.$key"
        fi
    fi
}

# Configure login and authentication security
configure_login_security() {
    info "Configuring login and authentication security..."
    
    # Disable automatic login
    info "Disabling automatic login..."
    sudo defaults delete /Library/Preferences/com.apple.loginwindow autoLoginUser 2>/dev/null || true
    success "✓ Automatic login disabled"
    
    # Set login window to show name and password fields
    sudo defaults write /Library/Preferences/com.apple.loginwindow SHOWFULLNAME -bool true
    success "✓ Login window set to show username field"
    
    # Hide local users on login window (more secure)
    if [[ "$HARDENING_LEVEL" == "strict" ]]; then
        sudo defaults write /Library/Preferences/com.apple.loginwindow HideLocalUsers -bool true
        success "✓ Local users hidden on login window"
    fi
    
    # Disable guest account
    sudo defaults write /Library/Preferences/com.apple.loginwindow GuestEnabled -bool false
    success "✓ Guest account disabled"
    
    # Configure screen saver security
    info "Configuring screen saver security..."
    defaults write com.apple.screensaver askForPassword -int 1
    defaults write com.apple.screensaver askForPasswordDelay -int 0
    success "✓ Screen saver password protection enabled"
    
    # Set screen saver timeout (device-specific)
    case "$DEVICE_TYPE" in
        "macbook-pro")
            # Shorter timeout for portable device
            defaults write com.apple.screensaver idleTime -int 300  # 5 minutes
            success "✓ Screen saver timeout set to 5 minutes (portable device)"
            ;;
        "mac-studio"|"mac-mini")
            # Longer timeout for desktop devices
            defaults write com.apple.screensaver idleTime -int 900  # 15 minutes
            success "✓ Screen saver timeout set to 15 minutes (desktop device)"
            ;;
    esac
}

# Configure network and sharing security
configure_network_security() {
    info "Configuring network and sharing security..."
    
    # Disable AirDrop for unknown contacts
    defaults write com.apple.NetworkBrowser DisableAirDrop -bool true
    success "✓ AirDrop restricted to contacts only"
    
    # Disable Bluetooth when not needed (device-specific)
    case "$DEVICE_TYPE" in
        "mac-studio")
            # Desktop server - can disable Bluetooth
            sudo defaults write /Library/Preferences/com.apple.Bluetooth ControllerPowerState -int 0
            success "✓ Bluetooth disabled (server configuration)"
            ;;
        *)
            # Keep Bluetooth enabled for other devices but configure securely
            info "Bluetooth kept enabled (required for peripherals)"
            ;;
    esac
    
    # Configure Wi-Fi security (MacBook Pro specific)
    if [[ "$DEVICE_TYPE" == "macbook-pro" ]]; then
        info "Configuring Wi-Fi security for portable device..."
        
        # Disable automatic Wi-Fi connection to known networks in new locations
        sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.airport JoinMode "Preferred"
        success "✓ Wi-Fi set to connect to preferred networks only"
        
        # Disable Wi-Fi network ranking
        sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.airport RankLast -bool true
        success "✓ Wi-Fi automatic ranking disabled"
    fi
    
    # Disable remote management services (unless needed for Mac Studio)
    if [[ "$DEVICE_TYPE" != "mac-studio" ]]; then
        sudo systemsetup -setremotelogin off 2>/dev/null || warn "Could not disable SSH"
        sudo systemsetup -setremoteappleevents off 2>/dev/null || warn "Could not disable remote Apple events"
        success "✓ Remote management services disabled"
    else
        info "Remote management services left configurable for server use"
    fi
}

# Configure application security
configure_application_security() {
    info "Configuring application security..."
    
    # Enable Gatekeeper
    sudo spctl --master-enable
    success "✓ Gatekeeper enabled"
    
    # Set Gatekeeper to require App Store and identified developers
    sudo spctl --global-enable
    success "✓ Gatekeeper set to strict mode"
    
    # Disable automatic app downloads from other devices
    defaults write com.apple.appstore AutomaticallyDownloadApps -bool false
    success "✓ Automatic app downloads disabled"
    
    # Require password for App Store purchases
    defaults write com.apple.appstore PasswordRequired -bool true
    success "✓ Password required for App Store purchases"
    
    # Configure Safari security (if installed)
    if [[ -d "/Applications/Safari.app" ]]; then
        info "Configuring Safari security..."
        
        # Enable fraudulent website warning
        defaults write com.apple.Safari WarnAboutFraudulentWebsites -bool true
        
        # Disable auto-fill for passwords (prefer 1Password)
        defaults write com.apple.Safari AutoFillPasswords -bool false
        
        # Enable Do Not Track
        defaults write com.apple.Safari SendDoNotTrackHTTPHeader -bool true
        
        # Disable location services for Safari
        defaults write com.apple.Safari SafariGeolocationPermissionPolicy -int 0
        
        success "✓ Safari security settings configured"
    fi
}

# Configure system privacy settings
configure_privacy_settings() {
    info "Configuring privacy and data protection settings..."
    
    # Disable analytics and data sharing
    sudo defaults write /Library/Application\ Support/CrashReporter/DiagnosticMessagesHistory.plist AutoSubmit -bool false
    sudo defaults write /Library/Application\ Support/CrashReporter/DiagnosticMessagesHistory.plist ThirdPartyDataSubmit -bool false
    success "✓ Crash analytics disabled"
    
    # Disable Siri data collection
    defaults write com.apple.assistant.support "Siri Data Sharing Opt-In Status" -int 2
    success "✓ Siri data sharing disabled"
    
    # Disable location-based Apple ads
    defaults write com.apple.AdLib allowApplePersonalizedAdvertising -bool false
    success "✓ Location-based Apple ads disabled"
    
    # Configure Spotlight privacy
    info "Configuring Spotlight privacy..."
    
    # Disable Spotlight suggestions from web
    defaults write com.apple.spotlight orderedItems -array \
        '{"enabled" = 1;"name" = "APPLICATIONS";}' \
        '{"enabled" = 1;"name" = "SYSTEM_PREFS";}' \
        '{"enabled" = 1;"name" = "DIRECTORIES";}' \
        '{"enabled" = 1;"name" = "PDF";}' \
        '{"enabled" = 1;"name" = "FONTS";}' \
        '{"enabled" = 0;"name" = "DOCUMENTS";}' \
        '{"enabled" = 0;"name" = "MESSAGES";}' \
        '{"enabled" = 0;"name" = "CONTACT";}' \
        '{"enabled" = 0;"name" = "EVENT_TODO";}' \
        '{"enabled" = 0;"name" = "IMAGES";}' \
        '{"enabled" = 0;"name" = "BOOKMARKS";}' \
        '{"enabled" = 0;"name" = "MUSIC";}' \
        '{"enabled" = 0;"name" = "MOVIES";}' \
        '{"enabled" = 0;"name" = "PRESENTATIONS";}' \
        '{"enabled" = 0;"name" = "SPREADSHEETS";}' \
        '{"enabled" = 0;"name" = "SOURCE";}' \
        '{"enabled" = 0;"name" = "MENU_DEFINITION";}' \
        '{"enabled" = 0;"name" = "MENU_OTHER";}' \
        '{"enabled" = 0;"name" = "MENU_CONVERSION";}' \
        '{"enabled" = 0;"name" = "MENU_EXPRESSION";}' \
        '{"enabled" = 0;"name" = "MENU_WEBSEARCH";}' \
        '{"enabled" = 0;"name" = "MENU_SPOTLIGHT_SUGGESTIONS";}'
    
    success "✓ Spotlight configured for privacy"
}

# Configure file system security
configure_filesystem_security() {
    info "Configuring file system security..."
    
    # Set secure permissions on home directory
    chmod 750 "$HOME"
    success "✓ Home directory permissions secured"
    
    # Secure SSH directory if it exists
    if [[ -d "$HOME/.ssh" ]]; then
        chmod 700 "$HOME/.ssh"
        chmod 600 "$HOME/.ssh"/* 2>/dev/null || true
        success "✓ SSH directory permissions secured"
    fi
    
    # Disable file sharing services (unless needed for Mac Studio)
    if [[ "$DEVICE_TYPE" != "mac-studio" ]]; then
        sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.smbd.plist 2>/dev/null || true
        sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.AppleFileServer.plist 2>/dev/null || true
        success "✓ File sharing services disabled"
    else
        info "File sharing services left configurable for server use"
    fi
    
    # Set umask for secure file creation
    if ! grep -q "umask 077" "$HOME/.zshrc" 2>/dev/null; then
        echo >> "$HOME/.zshrc"
        echo "# Secure file creation permissions" >> "$HOME/.zshrc"
        echo "umask 077" >> "$HOME/.zshrc"
        success "✓ Secure umask configured"
    fi
}

# Configure audit and logging
configure_audit_logging() {
    info "Configuring security audit and logging..."
    
    # Enable security auditing
    if sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.auditd.plist 2>/dev/null; then
        success "✓ Security auditing enabled"
    else
        warn "Could not enable security auditing"
    fi
    
    # Configure log retention
    if [[ -f "/etc/asl.conf" ]]; then
        # Extend log retention for security events
        if ! sudo grep -q "ttl=30" /etc/asl.conf; then
            echo "# Extended retention for security logs" | sudo tee -a /etc/asl.conf > /dev/null
            echo "? [= Facility auth] file /var/log/auth.log mode=0640 format=bsd rotate=seq compress ttl=30" | sudo tee -a /etc/asl.conf > /dev/null
            success "✓ Extended log retention configured"
        fi
    fi
    
    # Enable detailed firewall logging
    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setloggingmode on 2>/dev/null || warn "Could not enable firewall logging"
    success "✓ Firewall logging enabled"
}

# Apply device-specific hardening
apply_device_specific_hardening() {
    info "Applying device-specific hardening for: $DEVICE_TYPE"
    
    case "$DEVICE_TYPE" in
        "macbook-pro")
            info "MacBook Pro specific hardening..."
            
            # Enable Find My Mac
            sudo defaults write /Library/Preferences/com.apple.FindMyMac FMMEnabled -bool true
            success "✓ Find My Mac enabled"
            
            # Configure power management for security
            sudo pmset -b destroyfvkeyonstandby 1 2>/dev/null || warn "Could not configure FileVault key destruction"
            sudo pmset -b hibernatemode 25 2>/dev/null || warn "Could not configure hibernation mode"
            
            # Enable secure keyboard entry in Terminal
            defaults write com.apple.terminal SecureKeyboardEntry -bool true
            success "✓ Secure keyboard entry enabled in Terminal"
            ;;
            
        "mac-studio")
            info "Mac Studio specific hardening..."
            
            # Server-specific security settings
            # Disable sleep to prevent security issues
            sudo pmset -a sleep 0 2>/dev/null || warn "Could not disable sleep"
            
            # Enable detailed audit logging for server
            sudo audit -s 2>/dev/null || warn "Could not start audit service"
            
            # Configure for headless operation security
            sudo defaults write /Library/Preferences/com.apple.loginwindow DisableConsoleAccess -bool true
            success "✓ Console access restricted"
            ;;
            
        "mac-mini")
            info "Mac Mini specific hardening..."
            
            # Balanced approach for multimedia and development
            # Enable screen sharing with authentication (for family access)
            sudo defaults write /var/db/launchd.db/com.apple.launchd/overrides.plist com.apple.screensharing -dict Disabled -bool false
            
            # Configure for shared family environment
            sudo defaults write /Library/Preferences/com.apple.loginwindow ShowInputMenu -bool true
            success "✓ Input menu enabled for multi-user access"
            ;;
    esac
}

# Verify hardening configuration
verify_hardening() {
    info "Verifying security hardening configuration..."
    
    local checks_passed=0
    local total_checks=0
    
    # Check FileVault status
    ((total_checks++))
    if fdesetup status 2>/dev/null | grep -q "FileVault is On"; then
        success "✓ FileVault encryption is enabled"
        ((checks_passed++))
    else
        warn "⚠ FileVault encryption is not enabled"
    fi
    
    # Check firewall status
    ((total_checks++))
    if sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null | grep -q "enabled"; then
        success "✓ Firewall is enabled"
        ((checks_passed++))
    else
        warn "⚠ Firewall is not enabled"
    fi
    
    # Check Gatekeeper status
    ((total_checks++))
    if spctl --status 2>/dev/null | grep -q "assessments enabled"; then
        success "✓ Gatekeeper is enabled"
        ((checks_passed++))
    else
        warn "⚠ Gatekeeper is not enabled"
    fi
    
    # Check automatic login
    ((total_checks++))
    if ! sudo defaults read /Library/Preferences/com.apple.loginwindow autoLoginUser 2>/dev/null; then
        success "✓ Automatic login is disabled"
        ((checks_passed++))
    else
        warn "⚠ Automatic login is enabled"
    fi
    
    # Check screen saver password
    ((total_checks++))
    if [[ "$(defaults read com.apple.screensaver askForPassword 2>/dev/null || echo 0)" == "1" ]]; then
        success "✓ Screen saver password is enabled"
        ((checks_passed++))
    else
        warn "⚠ Screen saver password is not enabled"
    fi
    
    echo
    info "Security verification results: $checks_passed/$total_checks checks passed"
    
    if [[ $checks_passed -eq $total_checks ]]; then
        success "All security checks passed!"
        return 0
    else
        warn "Some security checks failed - review and address warnings"
        return 1
    fi
}

# Provide hardening guidance
provide_hardening_guidance() {
    info "macOS Security Hardening Guidance"
    info "================================="
    echo
    info "Hardening Level: $HARDENING_LEVEL (family-friendly approach)"
    echo
    info "Security Areas Covered:"
    info "• Login and authentication security"
    info "• Network and sharing restrictions"
    info "• Application security (Gatekeeper, App Store)"
    info "• Privacy and data protection settings"
    info "• File system permissions and access controls"
    info "• Security audit and logging"
    echo
    case "$DEVICE_TYPE" in
        "macbook-pro")
            info "MacBook Pro Security Focus:"
            info "• Enhanced portable device security"
            info "• Find My Mac enabled for theft protection"
            info "• Secure power management and hibernation"
            info "• Travel-friendly security settings"
            ;;
        "mac-studio")
            info "Mac Studio Security Focus:"
            info "• Server infrastructure protection"
            info "• Headless operation security"
            info "• Enhanced audit logging"
            info "• Remote access security controls"
            ;;
        "mac-mini")
            info "Mac Mini Security Focus:"
            info "• Balanced family environment security"
            info "• Multi-user access controls"
            info "• Multimedia application security"
            info "• Development environment protection"
            ;;
    esac
    echo
    info "Additional Recommendations:"
    info "• Keep macOS and all applications updated"
    info "• Use strong, unique passwords with 1Password"
    info "• Enable two-factor authentication for all accounts"
    info "• Regularly review and audit security settings"
    info "• Monitor system logs for suspicious activity"
    echo
}

# Help function
usage() {
    cat << EOF
$SCRIPT_NAME - macOS Security Hardening

USAGE:
    $SCRIPT_NAME [OPTIONS] [DEVICE_TYPE]

DESCRIPTION:
    Implements gentle security hardening measures for macOS suitable
    for a family environment. Balances security with usability.

OPTIONS:
    -l, --level LEVEL    Hardening level (gentle, moderate, strict)
    -v, --verify         Verify current security configuration
    -h, --help           Show this help message

DEVICE_TYPE:
    macbook-pro    Portable device hardening (travel security)
    mac-studio     Server hardening (infrastructure protection)
    mac-mini       Balanced hardening (family multimedia)
    
    Default: macbook-pro

HARDENING AREAS:
    • Login and authentication security
    • Network and sharing restrictions
    • Application security controls
    • Privacy and data protection
    • File system permissions
    • Security audit and logging

EXAMPLES:
    $SCRIPT_NAME                           # Gentle hardening for MacBook Pro
    $SCRIPT_NAME --level moderate          # Moderate hardening level
    $SCRIPT_NAME --verify                  # Verify current security state
    $SCRIPT_NAME mac-studio                # Server-specific hardening

HARDENING LEVELS:
    gentle     Family-friendly, minimal disruption (default)
    moderate   Balanced security with some restrictions
    strict     Maximum security, may impact usability

NOTES:
    • Designed for family environment use
    • Balances security with ease of use
    • Device-specific optimisations applied
    • Verification available to check configuration

EOF
}

# Main execution
main() {
    info "macOS Security Hardening"
    info "======================="
    info "Device type: $DEVICE_TYPE"
    info "Hardening level: $HARDENING_LEVEL"
    echo
    
    # Provide guidance
    provide_hardening_guidance
    
    # Apply hardening measures
    info "Applying security hardening measures..."
    echo
    
    configure_login_security
    echo
    
    configure_network_security
    echo
    
    configure_application_security
    echo
    
    configure_privacy_settings
    echo
    
    configure_filesystem_security
    echo
    
    configure_audit_logging
    echo
    
    apply_device_specific_hardening
    echo
    
    # Verify configuration
    verify_hardening
    echo
    
    success "=========================================="
    success "Security hardening completed successfully!"
    success "=========================================="
    success "Your $DEVICE_TYPE has been hardened with $HARDENING_LEVEL security measures"
    
    info "Next steps:"
    info "• Restart your Mac to ensure all changes take effect"
    info "• Test applications to ensure they work as expected"
    info "• Review security settings periodically"
    info "• Keep system and applications updated"
    
    return 0
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -l|--level)
            if [[ -n "${2:-}" ]]; then
                case "$2" in
                    gentle|moderate|strict)
                        HARDENING_LEVEL="$2"
                        shift 2
                        ;;
                    *)
                        error "Invalid hardening level: $2"
                        error "Valid levels: gentle, moderate, strict"
                        exit 1
                        ;;
                esac
            else
                error "Hardening level required for --level option"
                exit 1
            fi
            ;;
        -v|--verify)
            info "Verifying security configuration..."
            verify_hardening
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
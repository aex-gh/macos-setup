#!/usr/bin/env zsh

# Script metadata
readonly SCRIPT_NAME="${0:t}"
readonly SCRIPT_DIR="${0:A:h}"

# Load common library
source "${SCRIPT_DIR}/../lib/common.zsh"

# Device type from command line
DEVICE_TYPE="${1:-macbook-pro}"

# Check FileVault status
check_filevault_status() {
    local filevault_status
    filevault_status=$(fdesetup status 2>/dev/null || echo "unknown")
    
    info "Current FileVault status: $filevault_status"
    
    case "$filevault_status" in
        *"FileVault is On"*)
            success "FileVault is already enabled and active"
            return 0
            ;;
        *"FileVault is Off"*)
            info "FileVault is disabled"
            return 1
            ;;
        *"Encryption in progress"*)
            success "FileVault is enabled and encryption is in progress"
            return 0
            ;;
        *"Decryption in progress"*)
            warn "FileVault decryption is in progress"
            return 1
            ;;
        *)
            warn "Unknown FileVault status: $filevault_status"
            return 1
            ;;
    esac
}

# Check if user is eligible for FileVault
check_user_eligibility() {
    local current_user
    current_user=$(whoami)
    
    info "Checking FileVault eligibility for user: $current_user"
    
    # Check if user is admin
    if is_user_admin "$current_user"; then
        success "Current user ($current_user) has admin privileges"
    else
        error "Current user ($current_user) does not have admin privileges"
        error "FileVault setup requires administrator access"
        return 1
    fi
    
    # Check if user has a password
    if dscl . -read "/Users/$current_user" AuthenticationAuthority &>/dev/null; then
        success "User account has authentication configured"
    else
        error "User account authentication is not properly configured"
        return 1
    fi
    
    return 0
}

# Enable FileVault
enable_filevault() {
    info "Enabling FileVault encryption..."
    
    # Check if we're already enabled
    if check_filevault_status; then
        info "FileVault is already enabled, no action needed"
        return 0
    fi
    
    # Check user eligibility
    if ! check_user_eligibility; then
        return 1
    fi
    
    info "FileVault will be enabled for the current user account"
    warn "IMPORTANT: Save the recovery key that will be displayed!"
    warn "You will need this key if you forget your password"
    echo
    
    # Prompt for confirmation
    read -p "Do you want to enable FileVault now? [y/N]: " enable_choice
    if [[ "$enable_choice" != "y" && "$enable_choice" != "Y" ]]; then
        info "FileVault setup cancelled by user"
        return 0
    fi
    
    echo
    info "Enabling FileVault... This may take some time."
    
    # Enable FileVault using fdesetup
    if sudo fdesetup enable -user "$(whoami)"; then
        success "FileVault has been enabled successfully"
        
        # Get encryption status
        local filevault_status
        filevault_status=$(fdesetup status 2>/dev/null || echo "unknown")
        info "Status: $filevault_status"
        
        if [[ "$filevault_status" == *"Encryption in progress"* ]]; then
            info "Encryption is now running in the background"
            info "Your Mac will encrypt data while you use it"
            info "Check progress with: sudo fdesetup status"
        fi
        
        return 0
    else
        error "Failed to enable FileVault"
        return 1
    fi
}

# Configure FileVault settings
configure_filevault_settings() {
    info "Configuring FileVault settings..."
    
    # Set institutional recovery key if desired (for enterprise environments)
    # This is commented out for personal use but can be enabled for organisations
    # if [[ -n "${FILEVAULT_INSTITUTIONAL_KEY:-}" ]]; then
    #     info "Setting institutional recovery key..."
    #     sudo fdesetup changerecovery -institutional -keychain
    # fi
    
    # Configure automatic login (generally not recommended with FileVault)
    info "Disabling automatic login for enhanced security..."
    sudo defaults delete /Library/Preferences/com.apple.loginwindow autoLoginUser 2>/dev/null || true
    
    # Configure login window settings
    sudo defaults write /Library/Preferences/com.apple.loginwindow SHOWFULLNAME -bool true
    sudo defaults write /Library/Preferences/com.apple.loginwindow HideLocalUsers -bool false
    sudo defaults write /Library/Preferences/com.apple.loginwindow HideMobileAccounts -bool false
    
    success "FileVault settings configured"
}

# Provide FileVault information and best practices
provide_filevault_guidance() {
    info "FileVault Best Practices and Information"
    info "======================================="
    echo
    info "Recovery Key Management:"
    info "• Store your recovery key in a secure location"
    info "• Consider using 1Password to store the recovery key"
    info "• The recovery key is required if you forget your password"
    echo
    info "Performance Impact:"
    info "• Modern Macs have hardware encryption with minimal performance impact"
    info "• Initial encryption may take several hours depending on disk size"
    info "• Encryption happens in the background during normal use"
    echo
    info "Device-Specific Considerations:"
    case "$DEVICE_TYPE" in
        "macbook-pro")
            info "• MacBook Pro: FileVault essential for portable device security"
            info "• Protects data if device is lost or stolen"
            info "• Ensure regular backups before travel"
            ;;
        "mac-studio"|"mac-mini")
            info "• Desktop Mac: FileVault provides data protection at rest"
            info "• Important for shared environments or sensitive data"
            info "• Consider institutional recovery keys for family sharing"
            ;;
    esac
    echo
    info "Monitoring and Maintenance:"
    info "• Check status: sudo fdesetup status"
    info "• View recovery key: sudo fdesetup recoverykey"
    info "• Add users: sudo fdesetup add -usertoadd username"
    echo
}

# Check encryption progress
check_encryption_progress() {
    if ! check_filevault_status; then
        return 1
    fi
    
    local filevault_status
    filevault_status=$(fdesetup status 2>/dev/null || echo "unknown")
    
    if [[ "$filevault_status" == *"Encryption in progress"* ]]; then
        info "Checking encryption progress..."
        
        # Try to get percentage if available
        if command -v diskutil &>/dev/null; then
            local progress
            progress=$(diskutil cs list 2>/dev/null | grep -i "conversion progress" || echo "")
            if [[ -n "$progress" ]]; then
                info "Progress: $progress"
            else
                info "Encryption is in progress (progress details not available)"
            fi
        fi
        
        info "Encryption will continue in the background"
        info "Your Mac remains fully usable during encryption"
    elif [[ "$filevault_status" == *"FileVault is On"* ]]; then
        success "Encryption is complete and FileVault is fully active"
    fi
}

# Help function
usage() {
    cat << EOF
$SCRIPT_NAME - FileVault Encryption Setup

USAGE:
    $SCRIPT_NAME [OPTIONS] [DEVICE_TYPE]

DESCRIPTION:
    Sets up FileVault full-disk encryption for enhanced data security.
    Provides device-specific configuration and guidance for different
    Mac models in the family environment.

OPTIONS:
    -s, --status         Check current FileVault status and exit
    -p, --progress       Check encryption progress and exit
    -h, --help           Show this help message

DEVICE_TYPE:
    macbook-pro    Portable development workstation
    mac-studio     Headless server infrastructure
    mac-mini       Lightweight development + multimedia
    
    Default: macbook-pro

SECURITY FEATURES:
    • Full-disk encryption using hardware acceleration
    • User-based recovery key generation
    • Secure login window configuration
    • Device-specific security recommendations

EXAMPLES:
    $SCRIPT_NAME                    # Setup FileVault for MacBook Pro
    $SCRIPT_NAME --status           # Check current FileVault status
    $SCRIPT_NAME mac-studio         # Setup FileVault for Mac Studio
    $SCRIPT_NAME --progress         # Check encryption progress

REQUIREMENTS:
    • Administrator privileges required
    • User account must have password authentication
    • Sufficient disk space for encryption process

NOTES:
    • Recovery key must be stored securely
    • Initial encryption may take several hours
    • Modern Macs have minimal performance impact
    • Compatible with all macOS versions supporting FileVault 2

EOF
}

# Main execution
main() {
    info "FileVault Encryption Setup"
    info "=========================="
    info "Device type: $DEVICE_TYPE"
    echo
    
    # Provide guidance first
    provide_filevault_guidance
    
    # Check current status
    if check_filevault_status; then
        check_encryption_progress
        info "FileVault is already configured properly"
        return 0
    fi
    
    # Enable FileVault
    if enable_filevault; then
        echo
        configure_filevault_settings
        echo
        check_encryption_progress
        echo
        
        success "=========================================="
        success "FileVault setup completed successfully!"
        success "=========================================="
        success "Your $DEVICE_TYPE is now protected with full-disk encryption"
        
        warn "IMPORTANT REMINDERS:"
        warn "• Save your recovery key in a secure location"
        warn "• Test your password before restarting"
        warn "• Encryption will continue in the background"
        
        return 0
    else
        error "FileVault setup failed"
        return 1
    fi
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--status)
            info "Checking FileVault status..."
            check_filevault_status
            check_encryption_progress
            exit 0
            ;;
        -p|--progress)
            info "Checking encryption progress..."
            check_encryption_progress
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
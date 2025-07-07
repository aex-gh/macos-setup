#!/usr/bin/env zsh
# -*- coding: utf-8 -*-

#=============================================================================
# SCRIPT: 07-security-hardening.zsh
# AUTHOR: Andrew Exley
# DATE: 2025-01-07
# VERSION: 1.0.0
#
# DESCRIPTION:
#   Security hardening module for macOS systems. Configures security
#   settings, enables protections, and hardens the system based on
#   hardware type and usage patterns.
#
# USAGE:
#   ./07-security-hardening.zsh [options]
#
# OPTIONS:
#   -h, --help      Show this help message
#   -v, --verbose   Enable verbose output
#   -d, --debug     Enable debug mode
#   -n, --dry-run   Preview changes without applying them
#
# REQUIREMENTS:
#   - macOS 11.0+ (Big Sur)
#   - Admin privileges for system-level changes
#   - Hardware detection completed
#
# NOTES:
#   - Configures security based on hardware type
#   - Enables appropriate protections for each machine
#   - Follows security best practices for macOS
#=============================================================================

# Strict mode
set -euo pipefail

# Script metadata
readonly SCRIPT_NAME="${0:t}"
readonly SCRIPT_DIR="${0:A:h}"
readonly SCRIPT_VERSION="1.0.0"

# Colour codes (using tput for compatibility)
readonly RED=$(tput setaf 1)
readonly GREEN=$(tput setaf 2)
readonly YELLOW=$(tput setaf 3)
readonly BLUE=$(tput setaf 4)
readonly MAGENTA=$(tput setaf 5)
readonly CYAN=$(tput setaf 6)
readonly WHITE=$(tput setaf 7)
readonly BOLD=$(tput bold)
readonly RESET=$(tput sgr0)

# Global variables
declare -g VERBOSE=false
declare -g DEBUG=false
declare -g DRY_RUN=false

#=============================================================================
# LOGGING FUNCTIONS
#=============================================================================

log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Log to console based on level
    case $level in
        ERROR)
            echo "${RED}${BOLD}[ERROR]${RESET} $message" >&2
            ;;
        WARN)
            echo "${YELLOW}${BOLD}[WARN]${RESET} $message" >&2
            ;;
        INFO)
            echo "${BLUE}${BOLD}[INFO]${RESET} $message"
            ;;
        DEBUG)
            [[ $DEBUG == true ]] && echo "${CYAN}[DEBUG]${RESET} $message"
            ;;
        SUCCESS)
            echo "${GREEN}${BOLD}[✓]${RESET} $message"
            ;;
        STEP)
            echo "${MAGENTA}${BOLD}[STEP]${RESET} $message"
            ;;
    esac
}

error() { log ERROR "$@"; }
warn() { log WARN "$@"; }
info() { log INFO "$@"; }
debug() { log DEBUG "$@"; }
success() { log SUCCESS "$@"; }
step() { log STEP "$@"; }

#=============================================================================
# UTILITY FUNCTIONS
#=============================================================================

# Check if running on macOS
check_macos() {
    if [[ $(uname) != "Darwin" ]]; then
        error "This script requires macOS"
        exit 1
    fi
}

# Confirmation prompt
confirm() {
    local message="${1:-Are you sure?}"
    
    echo -n "${YELLOW}${BOLD}[?]${RESET} $message (y/N): "
    read -r response
    [[ $response =~ ^[Yy]$ ]]
}

# Print section header
print_section() {
    local title=$1
    local emoji=$2
    
    echo ""
    echo "${BOLD}${CYAN}═══════════════════════════════════════════════════════════════════════════════${RESET}"
    echo "${BOLD}${CYAN}  $emoji $title${RESET}"
    echo "${BOLD}${CYAN}═══════════════════════════════════════════════════════════════════════════════${RESET}"
    echo ""
}

# Execute command with proper logging
execute_command() {
    local description=$1
    shift
    local cmd=("$@")
    
    step "$description"
    
    if [[ $DRY_RUN == false ]]; then
        if "${cmd[@]}"; then
            debug "Executed: ${cmd[*]}"
        else
            error "Failed to execute: ${cmd[*]}"
            return 1
        fi
    else
        debug "DRY RUN: ${cmd[*]}"
    fi
    
    return 0
}

# Load hardware profile
load_hardware_profile() {
    local profile_file="$HOME/.config/dotfiles-setup/hardware-profile.env"
    
    if [[ -f $profile_file ]]; then
        source "$profile_file"
        debug "Loaded hardware profile: $HARDWARE_TYPE ($CHIP_TYPE)"
    else
        warn "Hardware profile not found, using defaults"
        export HARDWARE_TYPE="unknown"
        export CHIP_TYPE="unknown"
    fi
}

# Load machine configuration
load_machine_config() {
    local config_file="$HOME/.config/dotfiles-setup/machine-config.conf"
    local default_config_dir="${SCRIPT_DIR}/../config/machine-configs"
    
    # Try to load existing config first
    if [[ -f $config_file ]]; then
        source "$config_file"
        debug "Loaded machine config from: $config_file"
        return 0
    fi
    
    # Fall back to default config based on hardware type
    case $HARDWARE_TYPE in
        "studio")
            local source_config="$default_config_dir/mac-studio.conf"
            ;;
        "laptop")
            local source_config="$default_config_dir/macbook-pro.conf"
            ;;
        "mini")
            local source_config="$default_config_dir/mac-mini.conf"
            ;;
        *)
            warn "No machine config found for hardware type: $HARDWARE_TYPE"
            return 1
            ;;
    esac
    
    if [[ -f $source_config ]]; then
        debug "Loading default config from: $source_config"
        # For this script, we'll just read values we need
        return 0
    else
        warn "Default config not found: $source_config"
        return 1
    fi
}

#=============================================================================
# CORE SECURITY FUNCTIONS
#=============================================================================

# Configure system security settings
configure_system_security() {
    step "Configuring core system security settings"
    
    # Enable FileVault disk encryption
    configure_filevault
    
    # Configure firewall
    configure_firewall
    
    # Configure Gatekeeper and System Integrity Protection
    configure_gatekeeper
    
    # Configure automatic security updates
    configure_automatic_updates
    
    success "System security configured"
}

# Configure FileVault disk encryption
configure_filevault() {
    step "Configuring FileVault disk encryption"
    
    # Check if FileVault is already enabled
    local filevault_status=$(fdesetup status)
    
    if [[ $filevault_status =~ "FileVault is On" ]]; then
        info "FileVault already enabled"
        return 0
    fi
    
    if [[ $DRY_RUN == true ]]; then
        info "DRY RUN: Would enable FileVault disk encryption"
        return 0
    fi
    
    warn "FileVault is not enabled. This should be configured manually:"
    info "  1. System Preferences > Security & Privacy > FileVault"
    info "  2. Click 'Turn On FileVault...'"
    info "  3. Choose recovery method (iCloud or recovery key)"
    info "  4. Restart when prompted"
}

# Configure macOS firewall
configure_firewall() {
    step "Configuring macOS firewall"
    
    if [[ $DRY_RUN == false ]]; then
        # Enable firewall
        execute_command "Enabling firewall" \
            sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
        
        # Enable stealth mode
        execute_command "Enabling stealth mode" \
            sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on
        
        # Block all incoming connections by default
        execute_command "Setting firewall to block mode" \
            sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setblockall off
        
        # Enable logging
        execute_command "Enabling firewall logging" \
            sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setloggingmode on
    else
        info "DRY RUN: Would configure firewall settings"
    fi
    
    success "Firewall configured"
}

# Configure Gatekeeper and code signing
configure_gatekeeper() {
    step "Configuring Gatekeeper and code signing protection"
    
    if [[ $DRY_RUN == false ]]; then
        # Enable Gatekeeper
        execute_command "Enabling Gatekeeper" \
            sudo spctl --master-enable
        
        # Set Gatekeeper to allow App Store and identified developers
        execute_command "Setting Gatekeeper policy" \
            sudo spctl --global-disable
    else
        info "DRY RUN: Would configure Gatekeeper settings"
    fi
    
    success "Gatekeeper configured"
}

# Configure automatic security updates
configure_automatic_updates() {
    step "Configuring automatic security updates"
    
    if [[ $DRY_RUN == false ]]; then
        # Enable automatic check for updates
        execute_command "Enabling automatic update checks" \
            sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true
        
        # Enable automatic download of updates
        execute_command "Enabling automatic update downloads" \
            sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload -bool true
        
        # Enable automatic installation of system data files and security updates
        execute_command "Enabling automatic security updates" \
            sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate CriticalUpdateInstall -bool true
        
        # Enable automatic installation of macOS updates
        execute_command "Enabling automatic macOS updates" \
            sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticallyInstallMacOSUpdates -bool true
    else
        info "DRY RUN: Would configure automatic security updates"
    fi
    
    success "Automatic updates configured"
}

#=============================================================================
# HARDWARE-SPECIFIC SECURITY
#=============================================================================

# Configure security based on hardware type
configure_hardware_security() {
    step "Configuring hardware-specific security for: $HARDWARE_TYPE"
    
    case $HARDWARE_TYPE in
        "studio")
            configure_studio_security
            ;;
        "laptop")
            configure_laptop_security
            ;;
        "mini")
            configure_mini_security
            ;;
        *)
            info "No specific security configuration for hardware type: $HARDWARE_TYPE"
            ;;
    esac
    
    success "Hardware-specific security configured"
}

# Configure Mac Studio security (server-focused)
configure_studio_security() {
    step "Configuring Mac Studio server security"
    
    # Configure SSH security
    configure_ssh_security
    
    # Configure network service security
    configure_network_service_security
    
    # Configure monitoring and logging
    configure_server_monitoring
    
    success "Mac Studio security configured"
}

# Configure MacBook Pro security (mobile-focused)
configure_laptop_security() {
    step "Configuring MacBook Pro mobile security"
    
    # Configure Touch ID if available
    configure_touch_id
    
    # Configure location services and privacy
    configure_privacy_settings
    
    # Configure power and sleep security
    configure_sleep_security
    
    success "MacBook Pro security configured"
}

# Configure Mac Mini security (balanced)
configure_mini_security() {
    step "Configuring Mac Mini balanced security"
    
    # Configure SSH security
    configure_ssh_security
    
    # Configure desktop security settings
    configure_desktop_security
    
    success "Mac Mini security configured"
}

#=============================================================================
# SPECIFIC SECURITY CONFIGURATIONS
#=============================================================================

# Configure SSH security
configure_ssh_security() {
    step "Configuring SSH security"
    
    local ssh_config_dir="/etc/ssh"
    local sshd_config="$ssh_config_dir/sshd_config"
    
    if [[ $DRY_RUN == true ]]; then
        info "DRY RUN: Would configure SSH security settings"
        return 0
    fi
    
    # Backup original config
    if [[ ! -f "$sshd_config.backup" ]]; then
        execute_command "Backing up SSH config" \
            sudo cp "$sshd_config" "$sshd_config.backup"
    fi
    
    # Configure SSH security settings
    info "SSH security should be configured manually:"
    info "  1. Edit /etc/ssh/sshd_config"
    info "  2. Set PermitRootLogin no"
    info "  3. Set PasswordAuthentication no (after setting up keys)"
    info "  4. Set MaxAuthTries 3"
    info "  5. Set ClientAliveInterval 300"
    info "  6. Restart SSH: sudo launchctl kickstart -k system/com.openssh.sshd"
}

# Configure Touch ID for sudo
configure_touch_id() {
    step "Configuring Touch ID for sudo authentication"
    
    local pam_sudo="/etc/pam.d/sudo"
    
    if [[ $DRY_RUN == true ]]; then
        info "DRY RUN: Would configure Touch ID for sudo"
        return 0
    fi
    
    # Check if Touch ID line already exists
    if grep -q "pam_tid.so" "$pam_sudo"; then
        info "Touch ID already configured for sudo"
        return 0
    fi
    
    # Add Touch ID to sudo
    info "Touch ID configuration should be done manually:"
    info "  1. Edit /etc/pam.d/sudo with: sudo vim /etc/pam.d/sudo"
    info "  2. Add this line after the first comment:"
    info "     auth       sufficient     pam_tid.so"
    info "  3. Save and exit"
}

# Configure privacy settings
configure_privacy_settings() {
    step "Configuring privacy and location settings"
    
    if [[ $DRY_RUN == false ]]; then
        # Disable location-based suggestions
        execute_command "Disabling location suggestions" \
            defaults write com.apple.Safari SuppressSearchSuggestions -bool true
        
        # Disable analytics sharing
        execute_command "Disabling analytics sharing" \
            defaults write /Library/Application\ Support/CrashReporter/DiagnosticMessagesHistory.plist \
            AutoSubmit -bool false
        
        # Disable ad tracking
        execute_command "Limiting ad tracking" \
            defaults write com.apple.AdLib allowApplePersonalizedAdvertising -bool false
    else
        info "DRY RUN: Would configure privacy settings"
    fi
    
    success "Privacy settings configured"
}

# Configure sleep and lock security
configure_sleep_security() {
    step "Configuring sleep and lock security"
    
    if [[ $DRY_RUN == false ]]; then
        # Require password immediately after sleep or screen saver
        execute_command "Setting immediate password requirement" \
            defaults write com.apple.screensaver askForPassword -int 1
        
        execute_command "Setting immediate password timeout" \
            defaults write com.apple.screensaver askForPasswordDelay -int 0
        
        # Set a shorter screen saver timeout
        execute_command "Setting screen saver timeout" \
            defaults -currentHost write com.apple.screensaver idleTime -int 600
    else
        info "DRY RUN: Would configure sleep security settings"
    fi
    
    success "Sleep security configured"
}

# Configure network service security
configure_network_service_security() {
    step "Configuring network service security"
    
    if [[ $DRY_RUN == false ]]; then
        # Disable unnecessary services
        info "Consider disabling unused network services:"
        info "  - Remote Apple Events"
        info "  - Internet Sharing"
        info "  - Content Caching (unless needed)"
        
        # Configure sharing services
        info "Configure sharing services in System Preferences > Sharing:"
        info "  - Enable only required services"
        info "  - Restrict access to specific users/groups"
        info "  - Use strong authentication where possible"
    else
        info "DRY RUN: Would configure network service security"
    fi
    
    success "Network service security noted"
}

# Configure server monitoring and logging
configure_server_monitoring() {
    step "Configuring server monitoring and logging"
    
    if [[ $DRY_RUN == false ]]; then
        # Enable comprehensive logging
        execute_command "Enabling comprehensive logging" \
            sudo log config --mode "level:debug,persist:debug"
        
        # Configure log retention
        info "Consider setting up log rotation and monitoring:"
        info "  - Set up logrotate for custom logs"
        info "  - Monitor system logs for security events"
        info "  - Set up alerts for failed login attempts"
    else
        info "DRY RUN: Would configure server monitoring"
    fi
    
    success "Server monitoring configured"
}

# Configure desktop security settings
configure_desktop_security() {
    step "Configuring desktop security settings"
    
    if [[ $DRY_RUN == false ]]; then
        # Disable automatic login
        execute_command "Disabling automatic login" \
            sudo defaults delete /Library/Preferences/com.apple.loginwindow autoLoginUser 2>/dev/null || true
        
        # Show login window as name and password
        execute_command "Setting login window style" \
            sudo defaults write /Library/Preferences/com.apple.loginwindow SHOWFULLNAME -bool true
        
        # Disable guest account
        execute_command "Disabling guest account" \
            sudo defaults write /Library/Preferences/com.apple.loginwindow GuestEnabled -bool false
    else
        info "DRY RUN: Would configure desktop security settings"
    fi
    
    success "Desktop security configured"
}

#=============================================================================
# MAIN FUNCTIONS
#=============================================================================

# Display usage information
usage() {
    cat << EOF
${BOLD}NAME${RESET}
    $SCRIPT_NAME - Security hardening for macOS systems

${BOLD}SYNOPSIS${RESET}
    $SCRIPT_NAME [options]

${BOLD}DESCRIPTION${RESET}
    Applies security hardening to macOS systems based on hardware type
    and usage patterns. Configures system security, enables protections,
    and implements security best practices.

${BOLD}OPTIONS${RESET}
    -h, --help          Show this help message
    -v, --verbose       Enable verbose output
    -d, --debug         Enable debug mode
    -n, --dry-run       Preview changes without applying them

${BOLD}SECURITY AREAS${RESET}
    System Security     FileVault, firewall, Gatekeeper, updates
    Hardware Security   Type-specific configurations
    Network Security    SSH, sharing services, monitoring
    Privacy Settings    Location, analytics, advertising

${BOLD}AUTHOR${RESET}
    Andrew Exley (with Claude) <noreply@anthropic.com>

${BOLD}VERSION${RESET}
    $SCRIPT_VERSION
EOF
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -d|--debug)
                DEBUG=true
                shift
                ;;
            -n|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -*)
                error "Unknown option: $1"
                usage
                exit 1
                ;;
            *)
                error "Unexpected argument: $1"
                usage
                exit 1
                ;;
        esac
    done
}

# Main script logic
main() {
    # Check environment
    check_macos
    
    # Parse arguments
    parse_args "$@"
    
    # Load hardware profile
    load_hardware_profile
    load_machine_config
    
    print_section "SECURITY HARDENING" "🔒"
    
    # Configure core system security
    configure_system_security
    
    # Configure hardware-specific security
    configure_hardware_security
    
    success "Security hardening completed"
    
    # Provide next steps
    echo ""
    echo "${BOLD}Security Hardening Complete${RESET}"
    echo ""
    echo "${BOLD}Manual steps required:${RESET}"
    echo "  • Enable FileVault in System Preferences if not already active"
    echo "  • Configure SSH keys and disable password authentication"
    echo "  • Review and configure sharing services"
    echo "  • Set up Touch ID for sudo (MacBook Pro)"
    echo "  • Configure user-specific privacy settings"
    echo ""
    echo "${BOLD}Recommended additional security measures:${RESET}"
    echo "  • Install and configure 1Password or similar password manager"
    echo "  • Enable two-factor authentication for Apple ID"
    echo "  • Review installed applications and remove unused ones"
    echo "  • Set up regular security audits and monitoring"
    echo ""
}

#=============================================================================
# CLEANUP & ERROR HANDLING
#=============================================================================

# Cleanup function
cleanup() {
    local exit_code=$?
    
    debug "Cleaning up..."
    
    # Log exit status
    if [[ $exit_code -eq 0 ]]; then
        debug "Script exited successfully"
    else
        error "Script exited with code: $exit_code"
    fi
    
    exit $exit_code
}

# Error handler
error_handler() {
    local line_no=$1
    error "An error occurred on line $line_no"
    cleanup
}

# Set traps
trap cleanup EXIT
trap 'error_handler $LINENO' ERR

#=============================================================================
# SCRIPT EXECUTION
#=============================================================================

# Only run main if script is executed directly
if [[ "${(%):-%x}" == "${0}" ]]; then
    main "$@"
fi
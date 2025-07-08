#!/usr/bin/env zsh
# -*- coding: utf-8 -*-

#=============================================================================
# SCRIPT: system-setup.zsh
# AUTHOR: Andrew Exley
# DATE: 2025-01-07
# VERSION: 1.0.0
#
# DESCRIPTION:
#   Initial macOS system setup script for new machines. Configures essential
#   system services, networking, and security settings that complement the
#   main dotfiles installation.
#
# USAGE:
#   sudo ./system-setup.zsh [options]
#
# OPTIONS:
#   -h, --help      Show this help message
#   -v, --verbose   Enable verbose output
#   -d, --debug     Enable debug mode
#   -n, --dry-run   Preview changes without applying them
#   -f, --force     Skip confirmation prompts
#   -s, --skip-ssh  Skip SSH setup
#   -c, --skip-sharing  Skip file sharing setup
#
# REQUIREMENTS:
#   - macOS 11.0+ (Big Sur)
#   - Zsh 5.8+
#   - Admin privileges (must run with sudo)
#
# NOTES:
#   - Run this script BEFORE running macos-defaults.zsh
#   - Creates SSH keys if they don't exist
#   - Configures system-level services
#   - Sets up basic security hardening
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
declare -g FORCE=false
declare -g SKIP_SSH=false
declare -g SKIP_SHARING=false
declare -g LOG_FILE="/var/log/system-setup.log"
declare -g CURRENT_USER=${SUDO_USER:-$(whoami)}
declare -g USER_HOME="/Users/$CURRENT_USER"

#=============================================================================
# LOGGING FUNCTIONS
#=============================================================================

log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Log to file
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    
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
        CHANGE)
            echo "${MAGENTA}${BOLD}[CHANGE]${RESET} $message"
            ;;
    esac
}

error() { log ERROR "$@"; }
warn() { log WARN "$@"; }
info() { log INFO "$@"; }
debug() { log DEBUG "$@"; }
success() { log SUCCESS "$@"; }
change() { log CHANGE "$@"; }

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

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root (use sudo)"
        exit 1
    fi
}

# Check if actual user is available
check_user() {
    if [[ -z $CURRENT_USER || $CURRENT_USER == "root" ]]; then
        error "Could not determine the actual user. Please run with sudo as a regular user."
        exit 1
    fi
    
    if [[ ! -d $USER_HOME ]]; then
        error "User home directory not found: $USER_HOME"
        exit 1
    fi
}

# Confirmation prompt
confirm() {
    local message="${1:-Are you sure?}"
    
    [[ $FORCE == true ]] && return 0
    
    echo -n "${YELLOW}${BOLD}[?]${RESET} $message (y/N): "
    read -r response
    [[ $response =~ ^[Yy]$ ]]
}

# Execute command with proper logging
execute_command() {
    local description=$1
    shift
    local cmd=("$@")
    
    change "$description"
    
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

# Display usage information
usage() {
    cat << EOF
${BOLD}NAME${RESET}
    $SCRIPT_NAME - Initial macOS system setup

${BOLD}SYNOPSIS${RESET}
    sudo $SCRIPT_NAME [options]

${BOLD}DESCRIPTION${RESET}
    Initial system setup script for new macOS machines. Configures essential
    system services, networking, and security settings. Must be run with sudo.

${BOLD}OPTIONS${RESET}
    -h, --help          Show this help message
    -v, --verbose       Enable verbose output
    -d, --debug         Enable debug mode
    -n, --dry-run       Preview changes without applying them
    -f, --force         Skip confirmation prompts
    -s, --skip-ssh      Skip SSH setup
    -c, --skip-sharing  Skip file sharing setup

${BOLD}EXAMPLES${RESET}
    # Full system setup
    sudo $SCRIPT_NAME

    # Preview changes without applying
    sudo $SCRIPT_NAME --dry-run

    # Skip SSH setup
    sudo $SCRIPT_NAME --skip-ssh

${BOLD}CONFIGURATION AREAS${RESET}
    • System Naming: Set computer name and hostname
    • SSH Setup: Configure remote login and SSH keys
    • File Sharing: Enable AFP, SMB, and SSH file sharing
    • Network Discovery: Configure Bonjour and network visibility
    • Security: Basic hardening and firewall setup
    • Time Sync: Configure NTP and timezone
    • Power Management: Optimise sleep and wake settings

${BOLD}AUTHOR${RESET}
    Andrew (with Claude) <noreply@anthropic.com>

${BOLD}VERSION${RESET}
    $SCRIPT_VERSION
EOF
}

#=============================================================================
# SYSTEM INFORMATION FUNCTIONS
#=============================================================================

# Get system information
get_system_info() {
    local -A info
    
    info[hostname]=$(scutil --get ComputerName 2>/dev/null || echo "Not set")
    info[local_hostname]=$(scutil --get LocalHostName 2>/dev/null || echo "Not set")
    info[model]=$(sysctl -n hw.model)
    info[serial]=$(system_profiler SPHardwareDataType | grep "Serial Number" | awk '{print $4}')
    info[macos]=$(sw_vers -productVersion)
    info[current_user]=$CURRENT_USER
    info[ip_address]=$(ipconfig getifaddr en0 2>/dev/null || echo "Not connected")
    
    echo "${BOLD}${CYAN}Current System Information:${RESET}"
    echo ""
    for key val in ${(kv)info}; do
        printf "  %-15s: %s\n" "$key" "$val"
    done
    echo ""
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

#=============================================================================
# SYSTEM NAMING CONFIGURATION
#=============================================================================

configure_system_naming() {
    print_section "SYSTEM NAMING CONFIGURATION" "🏷️"
    
    # Get current names
    local current_computer_name=$(scutil --get ComputerName 2>/dev/null || echo "")
    local current_local_hostname=$(scutil --get LocalHostName 2>/dev/null || echo "")
    local current_hostname=$(scutil --get HostName 2>/dev/null || echo "")
    
    info "Current computer name: ${current_computer_name:-Not set}"
    info "Current local hostname: ${current_local_hostname:-Not set}"
    info "Current hostname: ${current_hostname:-Not set}"
    
    echo ""
    echo "The computer name is the friendly name shown in Finder and network browsing."
    echo "The hostname is used for network identification and terminal prompts."
    echo ""
    
    # Prompt for new computer name
    echo -n "Enter new computer name (leave blank to keep current): "
    read -r new_computer_name
    
    if [[ -n $new_computer_name ]]; then
        # Set computer name
        execute_command "Setting computer name to '$new_computer_name'" \
            scutil --set ComputerName "$new_computer_name"
        
        # Generate hostname from computer name (lowercase, no spaces)
        local new_hostname="${new_computer_name// /-}"
        new_hostname="${new_hostname:l}"
        
        # Set local hostname
        execute_command "Setting local hostname to '$new_hostname'" \
            scutil --set LocalHostName "$new_hostname"
        
        # Set hostname
        execute_command "Setting hostname to '$new_hostname'" \
            scutil --set HostName "$new_hostname"
        
        # Update /etc/hosts
        execute_command "Updating /etc/hosts" \
            sh -c "echo '127.0.0.1 $new_hostname.local $new_hostname localhost' >> /etc/hosts"
        
        success "System naming configured successfully"
        info "Computer name: $new_computer_name"
        info "Hostname: $new_hostname"
        info "Local hostname: $new_hostname.local"
    else
        info "Keeping current system names"
    fi
}

#=============================================================================
# SSH CONFIGURATION
#=============================================================================

configure_ssh() {
    if [[ $SKIP_SSH == true ]]; then
        info "Skipping SSH configuration"
        return 0
    fi
    
    print_section "SSH CONFIGURATION" "🔐"
    
    # Check for existing SSH configuration
    local user_ssh_config="$USER_HOME/.ssh/config"
    local dotfiles_ssh_config="$USER_HOME/projects/personal/dotfiles/ssh/dot-ssh/config"
    local has_existing_config=false
    local has_1password_agent=false
    
    if [[ -f $user_ssh_config ]]; then
        has_existing_config=true
        if grep -q "1password" "$user_ssh_config" 2>/dev/null; then
            has_1password_agent=true
        fi
    fi
    
    # Display existing SSH configuration status
    if [[ $has_existing_config == true ]]; then
        info "Existing SSH configuration detected at ~/.ssh/config"
        if [[ $has_1password_agent == true ]]; then
            success "1Password SSH agent configuration found"
        fi
        
        # Check if it's symlinked to dotfiles
        if [[ -L $user_ssh_config ]]; then
            local link_target=$(readlink "$user_ssh_config")
            info "SSH config is symlinked to: $link_target"
        fi
    else
        warn "No SSH configuration found at ~/.ssh/config"
        
        # Offer to symlink dotfiles SSH config if it exists
        if [[ -f $dotfiles_ssh_config ]]; then
            if confirm "Symlink dotfiles SSH configuration to ~/.ssh/config?"; then
                execute_command "Creating .ssh directory" \
                    sudo -u "$CURRENT_USER" mkdir -p "$USER_HOME/.ssh"
                
                execute_command "Setting .ssh directory permissions" \
                    chmod 700 "$USER_HOME/.ssh"
                
                execute_command "Symlinking SSH config from dotfiles" \
                    sudo -u "$CURRENT_USER" ln -sf "$dotfiles_ssh_config" "$user_ssh_config"
                
                success "SSH config symlinked from dotfiles"
                has_existing_config=true
                has_1password_agent=true
            fi
        fi
    fi
    
    # Enable SSH (Remote Login)
    execute_command "Enabling SSH (Remote Login)" \
        systemsetup -setremotelogin on
    
    # Configure SSH daemon security
    local ssh_config="/etc/ssh/sshd_config"
    local ssh_config_backup="/etc/ssh/sshd_config.backup.$(date +%Y%m%d_%H%M%S)"
    
    if [[ -f $ssh_config ]]; then
        execute_command "Backing up SSH daemon configuration" \
            cp "$ssh_config" "$ssh_config_backup"
    fi
    
    # Create secure SSH daemon configuration
    cat > "/tmp/sshd_config_additions" << 'EOF'

# Security hardening additions
Protocol 2
PermitRootLogin no
PasswordAuthentication yes
PubkeyAuthentication yes
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding no
PrintMotd no
PrintLastLog yes
TCPKeepAlive yes
ClientAliveInterval 300
ClientAliveCountMax 2
MaxAuthTries 3
MaxSessions 10
EOF
    
    execute_command "Updating SSH daemon configuration" \
        sh -c "cat /tmp/sshd_config_additions >> $ssh_config"
    
    # Clean up
    rm -f "/tmp/sshd_config_additions"
    
    # Handle SSH keys based on existing configuration
    if [[ $has_1password_agent == true ]]; then
        success "Using 1Password SSH agent for key management"
        info "SSH keys are managed by 1Password - no local key generation needed"
    else
        # Only generate keys if no 1Password setup and no existing keys
        local ssh_key_path="$USER_HOME/.ssh/id_ed25519"
        
        if [[ ! -f $ssh_key_path ]]; then
            info "No SSH key found and no 1Password agent configured"
            
            if confirm "Generate a local SSH key? (Not recommended if using 1Password)"; then
                # Ensure .ssh directory exists with correct permissions
                execute_command "Creating SSH directory" \
                    sudo -u "$CURRENT_USER" mkdir -p "$USER_HOME/.ssh"
                
                execute_command "Setting SSH directory permissions" \
                    chmod 700 "$USER_HOME/.ssh"
                
                # Generate SSH key
                execute_command "Generating SSH key" \
                    sudo -u "$CURRENT_USER" ssh-keygen -t ed25519 -f "$ssh_key_path" -N "" -C "$CURRENT_USER@$(hostname)"
                
                # Set correct permissions
                execute_command "Setting SSH key permissions" \
                    chmod 600 "$ssh_key_path"
                
                execute_command "Setting SSH public key permissions" \
                    chmod 644 "$ssh_key_path.pub"
                
                success "SSH key generated: $ssh_key_path"
                
                # Display public key
                if [[ -f "$ssh_key_path.pub" ]]; then
                    echo ""
                    echo "${BOLD}Your SSH public key:${RESET}"
                    cat "$ssh_key_path.pub"
                    echo ""
                    echo "Add this key to remote servers for password-less authentication."
                fi
            else
                info "Skipping SSH key generation"
                info "Configure 1Password SSH agent or manually add keys as needed"
            fi
        else
            info "SSH key already exists: $ssh_key_path"
        fi
    fi
    
    # Restart SSH service
    execute_command "Restarting SSH service" \
        launchctl unload /System/Library/LaunchDaemons/ssh.plist 2>/dev/null || true
    
    execute_command "Starting SSH service" \
        launchctl load /System/Library/LaunchDaemons/ssh.plist
    
    success "SSH configuration completed"
    info "SSH remote login is now enabled"
    
    # Provide connection information
    local hostname=$(scutil --get LocalHostName 2>/dev/null || hostname -s)
    info "Connect using: ssh $CURRENT_USER@$hostname.local"
    
    if [[ $has_1password_agent == true ]]; then
        info "SSH authentication will use 1Password SSH agent"
    fi
}

#=============================================================================
# FILE SHARING CONFIGURATION
#=============================================================================

configure_file_sharing() {
    if [[ $SKIP_SHARING == true ]]; then
        info "Skipping file sharing configuration"
        return 0
    fi
    
    print_section "FILE SHARING CONFIGURATION" "📁"
    
    # Enable AFP (Apple File Protocol)
    if confirm "Enable AFP (Apple File Protocol) sharing?"; then
        execute_command "Enabling AFP sharing" \
            launchctl load -w /System/Library/LaunchDaemons/com.apple.AppleFileServer.plist
        
        success "AFP sharing enabled"
    fi
    
    # Enable SMB (Server Message Block)
    if confirm "Enable SMB (Windows File Sharing) sharing?"; then
        execute_command "Enabling SMB sharing" \
            launchctl load -w /System/Library/LaunchDaemons/com.apple.smbd.plist
        
        success "SMB sharing enabled"
    fi
    
    # Configure shared folders
    if confirm "Create and share a 'Shared' folder in user home?"; then
        local shared_folder="$USER_HOME/Shared"
        
        execute_command "Creating shared folder" \
            sudo -u "$CURRENT_USER" mkdir -p "$shared_folder"
        
        execute_command "Setting shared folder permissions" \
            chmod 755 "$shared_folder"
        
        # Add to sharing configuration
        execute_command "Adding folder to sharing" \
            sharing -a "$shared_folder" -S "Shared" -s 001 -g 000
        
        success "Shared folder created and configured: $shared_folder"
    fi
    
    # Show sharing status
    info "File sharing status:"
    sharing -l 2>/dev/null || echo "  No shares configured"
}

#=============================================================================
# NETWORK CONFIGURATION
#=============================================================================

configure_network() {
    print_section "NETWORK CONFIGURATION" "🌐"
    
    # Configure Bonjour/mDNS
    execute_command "Enabling Bonjour service" \
        launchctl load -w /System/Library/LaunchDaemons/com.apple.mDNSResponder.plist
    
    # Configure network discovery
    execute_command "Enabling network discovery" \
        defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "$(scutil --get LocalHostName 2>/dev/null || hostname -s)"
    
    # Set DNS servers (optional)
    if confirm "Configure DNS servers (Cloudflare: 1.1.1.1, 1.0.0.1)?"; then
        execute_command "Setting DNS servers" \
            networksetup -setdnsservers "Wi-Fi" 1.1.1.1 1.0.0.1 2>/dev/null || \
            networksetup -setdnsservers "Ethernet" 1.1.1.1 1.0.0.1 2>/dev/null || \
            warn "Could not set DNS servers automatically"
    fi
    
    success "Network configuration completed"
}

#=============================================================================
# SECURITY CONFIGURATION
#=============================================================================

configure_security() {
    print_section "SECURITY CONFIGURATION" "🔒"
    
    # Enable firewall
    execute_command "Enabling firewall" \
        defaults write /Library/Preferences/com.apple.alf globalstate -int 1
    
    # Enable stealth mode
    execute_command "Enabling firewall stealth mode" \
        defaults write /Library/Preferences/com.apple.alf stealthenabled -int 1
    
    # Enable automatic security updates
    execute_command "Enabling automatic security updates" \
        defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload -bool true
    
    execute_command "Enabling automatic security updates installation" \
        defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true
    
    # Configure login window
    execute_command "Disabling guest user account" \
        defaults write /Library/Preferences/com.apple.loginwindow GuestEnabled -bool false
    
    # Enable secure virtual memory
    execute_command "Enabling secure virtual memory" \
        defaults write /Library/Preferences/com.apple.virtualMemory DisableEncryptedSwap -bool false
    
    success "Security configuration completed"
}

#=============================================================================
# TIME AND DATE CONFIGURATION
#=============================================================================

configure_time() {
    print_section "TIME & DATE CONFIGURATION" "🕐"
    
    # Enable network time
    execute_command "Enabling network time sync" \
        systemsetup -setusingnetworktime on
    
    # Set time server
    execute_command "Setting time server" \
        systemsetup -setnetworktimeserver "time.apple.com"
    
    # Set timezone (prompt user)
    echo "Current timezone: $(systemsetup -gettimezone | cut -d' ' -f3-)"
    echo ""
    echo "Common Australian timezones:"
    echo "  Australia/Sydney (NSW, VIC, TAS, ACT)"
    echo "  Australia/Melbourne (VIC)"
    echo "  Australia/Brisbane (QLD)"
    echo "  Australia/Adelaide (SA)"
    echo "  Australia/Perth (WA)"
    echo "  Australia/Darwin (NT)"
    echo ""
    echo -n "Enter new timezone (leave blank to keep current): "
    read -r new_timezone
    
    if [[ -n $new_timezone ]]; then
        execute_command "Setting timezone to $new_timezone" \
            systemsetup -settimezone "$new_timezone"
    fi
    
    success "Time configuration completed"
}

#=============================================================================
# POWER MANAGEMENT CONFIGURATION
#=============================================================================

configure_power() {
    print_section "POWER MANAGEMENT CONFIGURATION" "🔋"
    
    # Get system type
    local system_type="desktop"
    if system_profiler SPHardwareDataType | grep -q "Book"; then
        system_type="laptop"
    fi
    
    info "Detected system type: $system_type"
    
    if [[ $system_type == "laptop" ]]; then
        # Laptop power settings
        execute_command "Setting laptop display sleep (battery)" \
            pmset -b displaysleep 5
        
        execute_command "Setting laptop display sleep (charger)" \
            pmset -c displaysleep 10
        
        execute_command "Setting laptop system sleep (battery)" \
            pmset -b sleep 10
        
        execute_command "Setting laptop system sleep (charger)" \
            pmset -c sleep 30
        
        execute_command "Enabling laptop lid wake" \
            pmset -a lidwake 1
        
        execute_command "Setting laptop hibernate mode" \
            pmset -a hibernatemode 3
    else
        # Desktop power settings
        execute_command "Setting desktop display sleep" \
            pmset -a displaysleep 20
        
        execute_command "Setting desktop system sleep" \
            pmset -a sleep 0
        
        execute_command "Enabling desktop wake on network access" \
            pmset -a womp 1
    fi
    
    # Common settings
    execute_command "Enabling automatic restart after power failure" \
        pmset -a autorestart 1
    
    execute_command "Setting disk sleep timer" \
        pmset -a disksleep 30
    
    success "Power management configured for $system_type"
}

#=============================================================================
# ADDITIONAL SYSTEM CONFIGURATION
#=============================================================================

configure_additional() {
    print_section "ADDITIONAL SYSTEM CONFIGURATION" "⚙️"
    
    # Configure login items cleanup
    execute_command "Cleaning up login items" \
        osascript -e 'tell application "System Events" to get the name of every login item' > /dev/null 2>&1 || true
    
    # Configure crash reporting
    execute_command "Enabling crash reporting" \
        defaults write com.apple.CrashReporter DialogType -string "crashreport"
    
    # Configure help viewer
    execute_command "Setting help viewer to use online help" \
        defaults write com.apple.helpviewer DevMode -bool true
    
    # Configure system log retention
    execute_command "Setting system log retention" \
        defaults write /Library/Preferences/com.apple.asl.conf ttl -int 7
    
    # Create useful directories
    execute_command "Creating Development directory" \
        sudo -u "$CURRENT_USER" mkdir -p "$USER_HOME/Development"
    
    execute_command "Creating Scripts directory" \
        sudo -u "$CURRENT_USER" mkdir -p "$USER_HOME/Scripts"
    
    execute_command "Creating Screenshots directory" \
        sudo -u "$CURRENT_USER" mkdir -p "$USER_HOME/Pictures/Screenshots"
    
    success "Additional system configuration completed"
}

#=============================================================================
# MAIN FUNCTIONS
#=============================================================================

# Parse command line arguments
parse_args() {
    local args=()
    
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
            -f|--force)
                FORCE=true
                shift
                ;;
            -s|--skip-ssh)
                SKIP_SSH=true
                shift
                ;;
            -c|--skip-sharing)
                SKIP_SHARING=true
                shift
                ;;
            -*)
                error "Unknown option: $1"
                usage
                exit 1
                ;;
            *)
                args+=("$1")
                shift
                ;;
        esac
    done
    
    # Store remaining arguments
    set -- "${args[@]}"
}

# Main script logic
main() {
    # Check environment
    check_macos
    check_root
    check_user
    
    # Parse arguments
    parse_args "$@"
    
    # Show header
    echo ""
    echo "${BOLD}${BLUE}🚀 macOS System Setup v$SCRIPT_VERSION${RESET}"
    echo "${BOLD}${BLUE}════════════════════════════════════════════════════════════════════════════════${RESET}"
    echo ""
    
    # Show system information
    get_system_info
    
    # Show mode indicators
    if [[ $DRY_RUN == true ]]; then
        warn "DRY RUN MODE: No changes will be applied"
    fi
    
    # Final confirmation
    if ! confirm "Proceed with system setup?"; then
        info "Setup cancelled"
        exit 0
    fi
    
    # Run configuration sections
    configure_system_naming
    configure_ssh
    configure_file_sharing
    configure_network
    configure_security
    configure_time
    configure_power
    configure_additional
    
    # Show completion message
    print_section "SYSTEM SETUP COMPLETE" "✅"
    
    if [[ $DRY_RUN == true ]]; then
        info "DRY RUN completed - no changes were applied"
        info "Run without --dry-run to apply changes"
    else
        success "Initial system setup completed successfully!"
        
        echo ""
        echo "${BOLD}📋 Summary of configuration:${RESET}"
        echo "   • System naming and hostname configured"
        echo "   • SSH remote login enabled with key authentication"
        echo "   • File sharing services configured"
        echo "   • Network discovery and Bonjour enabled"
        echo "   • Firewall and security settings hardened"
        echo "   • Time synchronisation configured"
        echo "   • Power management optimised"
        echo "   • Useful directories created"
        echo ""
        echo "${BOLD}🔄 Next steps:${RESET}"
        echo "   1. Run the main dotfiles installation script"
        echo "   2. Run scripts/macos-defaults.zsh for UI preferences"
        echo "   3. Install development tools and applications"
        echo "   4. Configure specific applications and services"
        echo ""
        echo "${BOLD}📚 Log file: $LOG_FILE${RESET}"
        echo ""
        
        # Show connection information
        local ip_address=$(ipconfig getifaddr en0 2>/dev/null || echo "Not available")
        local hostname=$(scutil --get LocalHostName 2>/dev/null || hostname -s)
        
        if [[ $ip_address != "Not available" ]]; then
            echo "${BOLD}🌐 Connection Information:${RESET}"
            echo "   SSH: ssh $CURRENT_USER@$ip_address"
            echo "   Bonjour: ssh $CURRENT_USER@$hostname.local"
            echo "   File sharing: afp://$ip_address or smb://$ip_address"
            echo ""
        fi
    fi
}

#=============================================================================
# CLEANUP & ERROR HANDLING
#=============================================================================

# Cleanup function
cleanup() {
    local exit_code=$?
    
    debug "Cleaning up..."
    
    # Remove temporary files
    rm -f /tmp/sshd_config_additions 2>/dev/null || true
    
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
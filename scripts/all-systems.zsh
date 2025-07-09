#!/usr/bin/env zsh
# ABOUTME: All-systems setup script for macOS - handles common setup tasks for all Mac systems
# ABOUTME: Installs essential tools, configures security, and sets up remote access

set -euo pipefail

# Script configuration
readonly SCRIPT_DIR="${0:A:h}"
readonly CONFIG_DIR="${SCRIPT_DIR}/config"
readonly MODULES_DIR="${SCRIPT_DIR}/../modules"
readonly BREWFILES_DIR="${SCRIPT_DIR}/../brewfiles"
readonly BASE_CONFIG="${CONFIG_DIR}/base.yml"

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

# Check if running as root
check_not_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "This script should not be run as root"
        exit 1
    fi
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

# Update macOS system
update_system() {
    log_info "Updating macOS system..."
    
    # Install available updates
    sudo softwareupdate -i -a --restart
    
    log_success "System updates installed"
}

# Install Xcode Command Line Tools
install_xcode_tools() {
    log_info "Installing Xcode Command Line Tools..."
    
    # Check if already installed
    if xcode-select -p &>/dev/null; then
        log_success "Xcode Command Line Tools already installed"
        return 0
    fi
    
    # Install Xcode Command Line Tools
    xcode-select --install
    
    # Wait for installation to complete
    log_info "Waiting for Xcode Command Line Tools installation..."
    until xcode-select -p &>/dev/null; do
        sleep 5
    done
    
    # Accept license
    sudo xcodebuild -license accept
    
    log_success "Xcode Command Line Tools installed"
}

# Install Homebrew
install_homebrew() {
    log_info "Installing Homebrew..."
    
    # Check if already installed
    if command -v brew &>/dev/null; then
        log_success "Homebrew already installed"
        return 0
    fi
    
    # Install Homebrew
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH
    if [[ -f /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    fi
    
    # Disable analytics
    brew analytics off
    
    log_success "Homebrew installed"
}

# Install essential applications
install_essential_apps() {
    log_info "Installing essential applications..."
    
    # Install base packages
    if [[ -f "${BREWFILES_DIR}/base.brewfile" ]]; then
        log_info "Installing base packages from Brewfile..."
        brew bundle --file="${BREWFILES_DIR}/base.brewfile"
    fi
    
    # Install specific essential apps
    log_info "Installing 1Password..."
    brew install --cask 1password
    brew install 1password-cli
    
    log_info "Installing Karabiner Elements..."
    brew install --cask karabiner-elements
    
    log_success "Essential applications installed"
}

# Configure remote access
configure_remote_access() {
    log_info "Configuring remote access..."
    
    # Enable SSH
    log_info "Enabling SSH..."
    sudo systemsetup -setremotelogin on
    
    # Configure SSH
    if [[ -f "${MODULES_DIR}/security.zsh" ]]; then
        source "${MODULES_DIR}/security.zsh"
        configure_ssh "$BASE_CONFIG"
    fi
    
    log_success "Remote access configured"
}

# Configure file sharing
configure_file_sharing() {
    log_info "Configuring file sharing..."
    
    # Enable SMB
    log_info "Enabling SMB file sharing..."
    sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.smbd.plist
    
    # Enable SSH
    log_info "Enabling SSH access..."
    sudo systemsetup -setremotelogin on
    
    log_success "File sharing configured"
}

# Configure network discovery
configure_network_discovery() {
    log_info "Configuring network discovery..."
    
    # Enable Bonjour
    log_info "Enabling Bonjour..."
    sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.mDNSResponder.plist
    
    # Configure network visibility
    log_info "Configuring network visibility..."
    # Network visibility is typically handled by Bonjour
    
    log_success "Network discovery configured"
}

# Configure security
configure_security() {
    log_info "Configuring security..."
    
    # Enable firewall
    log_info "Enabling firewall..."
    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on
    
    # Configure FileVault
    log_info "Checking FileVault status..."
    if ! fdesetup status | grep -q "FileVault is On"; then
        log_warn "FileVault is not enabled. Please enable it manually:"
        log_warn "  System Settings > Privacy & Security > FileVault"
    else
        log_success "FileVault is enabled"
    fi
    
    log_success "Security configured"
}

# Configure time sync
configure_time_sync() {
    log_info "Configuring time synchronization..."
    
    # Set timezone to Adelaide, Australia
    log_info "Setting timezone to Australia/Adelaide..."
    sudo systemsetup -settimezone Australia/Adelaide
    
    # Enable network time
    log_info "Enabling network time synchronization..."
    sudo systemsetup -setusingnetworktime on
    
    # Set NTP server
    log_info "Setting NTP server..."
    sudo systemsetup -setnetworktimeserver time.apple.com
    
    log_success "Time synchronization configured"
}

# Configure system preferences
configure_system_preferences() {
    log_info "Configuring system preferences..."
    
    # Review and apply macOS defaults
    log_info "Applying macOS defaults..."
    
    # Dock settings
    defaults write com.apple.dock show-recents -bool false
    defaults write com.apple.dock minimize-to-application -bool true
    
    # Finder settings
    defaults write com.apple.finder ShowPathbar -bool true
    defaults write com.apple.finder ShowStatusBar -bool true
    defaults write com.apple.finder FXPreferredViewStyle -string "clmv"
    
    # Screenshots
    mkdir -p ~/Screenshots
    defaults write com.apple.screencapture location -string "~/Screenshots"
    defaults write com.apple.screencapture disable-shadow -bool true
    
    # Keyboard
    defaults write NSGlobalDomain KeyRepeat -int 2
    defaults write NSGlobalDomain InitialKeyRepeat -int 15
    
    # Restart affected applications
    killall Dock &>/dev/null || true
    killall Finder &>/dev/null || true
    
    log_success "System preferences configured"
}

# Disable telemetry
disable_telemetry() {
    log_info "Disabling telemetry and analytics..."
    
    # Disable analytics
    brew analytics off
    
    # Disable diagnostic data
    sudo defaults write /Library/Application\ Support/CrashReporter/DiagnosticMessagesHistory.plist AutoSubmit -bool false
    
    # Disable Siri data collection
    defaults write com.apple.assistant.support "Siri Data Sharing Opt-In Status" -int 2
    
    log_success "Telemetry disabled"
}

# Main setup function
main() {
    log_info "Starting macOS all-systems setup..."
    
    # Initial checks
    check_not_root
    request_sudo
    
    # System updates
    log_info "=== System Updates ==="
    update_system
    
    # Install essential tools
    log_info "=== Installing Essential Tools ==="
    install_xcode_tools
    install_homebrew
    install_essential_apps
    
    # Configure remote access
    log_info "=== Configuring Remote Access ==="
    configure_remote_access
    
    # Configure file sharing
    log_info "=== Configuring File Sharing ==="
    configure_file_sharing
    
    # Configure network discovery
    log_info "=== Configuring Network Discovery ==="
    configure_network_discovery
    
    # Configure security
    log_info "=== Configuring Security ==="
    configure_security
    
    # Configure time sync
    log_info "=== Configuring Time Synchronization ==="
    configure_time_sync
    
    # Configure system preferences
    log_info "=== Configuring System Preferences ==="
    configure_system_preferences
    
    # Disable telemetry
    log_info "=== Disabling Telemetry ==="
    disable_telemetry
    
    log_success "All-systems setup complete!"
    
    # Final instructions
    echo
    log_info "Next steps:"
    echo "1. Run the system-specific setup script for your Mac model"
    echo "2. Install additional applications using the categorized Brewfiles"
    echo "3. Configure dotfiles and personal settings"
    echo "4. Enable FileVault if not already enabled"
    echo
    log_info "Available system-specific scripts:"
    echo "  - mac-studio.zsh"
    echo "  - macbook-pro.zsh"
    echo "  - mac-mini.zsh"
}

# Run main function
main "$@"
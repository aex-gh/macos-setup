#!/usr/bin/env zsh
# ABOUTME: Enhanced macOS Setup Script v4.0 - Hybrid system configuration with comprehensive power and security management

# Ensure PATH includes standard Unix command locations FIRST
# Include Xcode Command Line Tools path for git and other development tools
# Include Homebrew paths for stow and other essential tools
export PATH="/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/Library/Developer/CommandLineTools/usr/bin:/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"

# macOS Setup Script v4.0 - Best of Both Worlds
# Hybrid approach: System-level configs + External dotfiles via Stow
# Author: System Administrator
# Version: 4.0
# Shell: zsh (macOS default)
# Compatible with: macOS 14+ on Apple Silicon
# Architecture: Hybrid (System configs + External dotfiles management)

# Enable modern zsh features
setopt EXTENDED_GLOB NULL_GLOB HIST_VERIFY PROMPT_SUBST
autoload -U colors && colors
autoload -U add-zsh-hook

# Strict error handling (moved after PATH is set)
set -euo pipefail

# =============================================================================
# SCRIPT METADATA AND GLOBAL CONFIGURATION
# =============================================================================

readonly SCRIPT_NAME="${0:t}"
readonly SCRIPT_DIR="${0:A:h}"
readonly SCRIPT_VERSION="4.0"
readonly REQUIRED_MACOS_VERSION="14.0"

# Timing and logging
typeset -g SETUP_START_TIME=$(/bin/date +%s)
typeset -g LOG_FILE="/tmp/${SCRIPT_NAME%.zsh}-$(/bin/date +%Y%m%d-%H%M%S).log"
typeset -g BACKUP_DIR="$HOME/.config-backup-$(/bin/date +%Y%m%d-%H%M%S)"
typeset -g TEMP_DIR=$(mktemp -d)

# Configuration flags with defaults
typeset -g VERBOSE=false
typeset -g INTERACTIVE=true
typeset -g DRY_RUN=false
typeset -g SKIP_SECURITY=false
typeset -g DOTFILES_REPO=""

# =============================================================================
# MODULE TOGGLE CONFIGURATION
# =============================================================================
# Enable/disable specific modules by changing these values to true/false
# This allows you to customise the setup process for different use cases

# Network and system basics (DNS, timezone, system preferences)
typeset -g ENABLE_NETWORK_CONFIG=true

# Hardware-specific power management optimisations
typeset -g ENABLE_POWER_MANAGEMENT=true

# Comprehensive security configuration (firewall, FileVault, etc.)
typeset -g ENABLE_SECURITY_CONFIG=true

# Sharing services (SSH, Screen Sharing) based on Mac type
typeset -g ENABLE_SHARING_SERVICES=true

# Mail and Calendar app configuration
typeset -g ENABLE_MAIL_CALENDAR=true

# System dependencies (Xcode CLI, Homebrew, GNU Stow)
typeset -g ENABLE_SYSTEM_DEPENDENCIES=true

# Dotfiles management (backup, clone, stow application)
typeset -g ENABLE_DOTFILES_MANAGEMENT=true

# =============================================================================
# MODULE VALIDATION AND DEPENDENCIES
# =============================================================================

validate_module_configuration() {
    info "Validating module configuration..."

    local warnings=()
    local errors=()

    # Check for dependency conflicts
    if [[ $ENABLE_DOTFILES_MANAGEMENT == true && $ENABLE_SYSTEM_DEPENDENCIES == false ]]; then
        warnings+=("Dotfiles management requires system dependencies (GNU Stow)")
    fi

    # Check for security conflicts
    if [[ $SKIP_SECURITY == true && $ENABLE_SECURITY_CONFIG == true ]]; then
        warnings+=("--skip-security flag conflicts with ENABLE_SECURITY_CONFIG=true")
    fi

    # Logical consistency checks
    if [[ $ENABLE_SECURITY_CONFIG == false && $ENABLE_SHARING_SERVICES == true ]]; then
        warnings+=("Enabling sharing services without security configuration may be unsafe")
    fi

    # Check if all modules are disabled
    if [[ $ENABLE_NETWORK_CONFIG == false && $ENABLE_POWER_MANAGEMENT == false &&
          $ENABLE_SECURITY_CONFIG == false && $ENABLE_SHARING_SERVICES == false &&
          $ENABLE_MAIL_CALENDAR == false && $ENABLE_SYSTEM_DEPENDENCIES == false &&
          $ENABLE_DOTFILES_MANAGEMENT == false ]]; then
        errors+=("All modules are disabled - nothing to do")
    fi

    # Report warnings
    if [[ ${#warnings[@]} -gt 0 ]]; then
        warn "Configuration warnings detected:"
        for warning in "${warnings[@]}"; do
            warn "  • $warning"
        done
        echo
    fi

    # Report errors
    if [[ ${#errors[@]} -gt 0 ]]; then
        error "Configuration errors detected:"
        for err in "${errors[@]}"; do
            error "  • $err"
        done
        echo
        return 1
    fi

    # Show enabled modules summary
    info "Enabled modules:"
    [[ $ENABLE_NETWORK_CONFIG == true ]] && info "  ✓ Network and system basics"
    [[ $ENABLE_POWER_MANAGEMENT == true ]] && info "  ✓ Power management"
    [[ $ENABLE_SECURITY_CONFIG == true ]] && info "  ✓ Security configuration"
    [[ $ENABLE_SHARING_SERVICES == true ]] && info "  ✓ Sharing services"
    [[ $ENABLE_MAIL_CALENDAR == true ]] && info "  ✓ Mail and Calendar"
    [[ $ENABLE_SYSTEM_DEPENDENCIES == true ]] && info "  ✓ System dependencies"
    [[ $ENABLE_DOTFILES_MANAGEMENT == true ]] && info "  ✓ Dotfiles management"

    success "Module configuration validated"
    return 0
}

# =============================================================================
# ENHANCED LOGGING SYSTEM
# =============================================================================

# Colour definitions using tput for compatibility
readonly RED=$(tput setaf 1)
readonly GREEN=$(tput setaf 2)
readonly YELLOW=$(tput setaf 3)
readonly BLUE=$(tput setaf 4)
readonly MAGENTA=$(tput setaf 5)
readonly CYAN=$(tput setaf 6)
readonly WHITE=$(tput setaf 7)
readonly BOLD=$(tput bold)
readonly RESET=$(tput sgr0)

# Enhanced logging with file output
log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(/bin/date '+%Y-%m-%d %H:%M:%S')

    # Always log to file
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"

    # Console output based on level
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
        SUCCESS)
            echo "${GREEN}${BOLD}[✓]${RESET} $message"
            ;;
        DEBUG)
            [[ $VERBOSE == true ]] && echo "${CYAN}[DEBUG]${RESET} $message"
            ;;
    esac
}

error() { log ERROR "$@"; }
warn() { log WARN "$@"; }
info() { log INFO "$@"; }
success() { log SUCCESS "$@"; }
debug() { log DEBUG "$@"; }

# =============================================================================
# ERROR HANDLING AND CLEANUP SYSTEM
# =============================================================================

# Background process tracking
typeset -a BACKGROUND_PIDS=()

# Enhanced cleanup function
cleanup() {
    local exit_code=$?

    debug "Performing final cleanup (exit code: $exit_code)..."

    # Only kill background processes on script exit, not during normal execution
    if [[ $exit_code -ne 0 ]] || [[ ${SCRIPT_EXITING:-false} == true ]]; then
        debug "Script is exiting, killing background processes..."
        
        # Kill background processes
        for pid in $BACKGROUND_PIDS; do
            if kill -0 "$pid" 2>/dev/null; then
                debug "Killing background process: $pid"
                kill "$pid" 2>/dev/null || true
            fi
        done

        # Kill sudo keep-alive if running
        jobs -p | xargs -r kill 2>/dev/null || true
    else
        debug "Script continuing normally, preserving background processes"
    fi

    # Remove temporary files
    [[ -d $TEMP_DIR ]] && /bin/rm -rf "$TEMP_DIR"

    # Log completion
    local total_time=$(($(/bin/date +%s) - SETUP_START_TIME))
    local minutes=$((total_time / 60))
    local seconds=$((total_time % 60))

    if [[ $exit_code -eq 0 ]]; then
        success "Setup completed in ${minutes}m ${seconds}s"
        info "Log file: $LOG_FILE"
    else
        error "Setup failed after ${minutes}m ${seconds}s (exit code: $exit_code)"
        error "Check log file: $LOG_FILE"
    fi

    exit $exit_code
}

# Error handler with context
error_handler() {
    local exit_code=$?
    local line_number=$1

    error "An error occurred on line $line_number (exit code: $exit_code)"

    if [[ $VERBOSE == true ]]; then
        error "Function stack: ${funcstack[*]}"
    fi

    cleanup
}

# Set up traps
trap cleanup EXIT
trap 'error_handler $LINENO' ERR

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

command_exists() { command -v "$1" &> /dev/null; }

# Ensure sudo credentials are fresh
refresh_sudo() {
    if [[ $DRY_RUN == true ]]; then
        return 0
    fi
    
    # Check if sudo credentials are still valid
    if ! sudo -n true 2>/dev/null; then
        info "Refreshing administrative credentials..."
        sudo -v
    else
        debug "Sudo credentials still valid"
    fi
}

# Bulletproof sudo wrapper function
safe_sudo() {
    if [[ $DRY_RUN == true ]]; then
        info "[DRY RUN] Would execute: sudo $*"
        return 0
    fi
    
    # Always refresh credentials before any sudo command to be absolutely sure
    if ! sudo -n true 2>/dev/null; then
        info "Administrative credentials needed for: $1"
    else
        debug "Sudo credentials still valid for: $1"
    fi
    sudo -v
    
    local max_attempts=3
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        debug "Executing sudo command (attempt $attempt/$max_attempts): $*"
        
        # Execute the command
        if sudo "$@"; then
            debug "Sudo command succeeded: $*"
            return 0
        else
            local exit_code=$?
            warn "Sudo command failed (attempt $attempt/$max_attempts): $* (exit code: $exit_code)"
            
            if [[ $attempt -lt $max_attempts ]]; then
                debug "Refreshing credentials and retrying in 2 seconds..."
                sudo -v
                sleep 2
            fi
            
            ((attempt++))
        fi
    done
    
    error "Sudo command failed after $max_attempts attempts: $*"
    return 1
}

# Version comparison utility
is_version_gte() {
    [ "$1" = "$(echo -e "$1\\n$2" | sort -V | tail -n1)" ]
}

# Confirmation prompt
confirm() {
    local prompt=${1:-"Continue?"}
    if [[ $INTERACTIVE == false ]]; then
        return 0
    fi
    read -q "REPLY?$prompt (y/N): "
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

# =============================================================================
# MAC MODEL DETECTION
# =============================================================================

# Mac model variables
typeset -g MAC_TYPE=""
typeset -g MAC_MODEL=""
typeset -g IS_PORTABLE=false
typeset -g IS_SERVER_CLASS=false

detect_mac_model() {
    info "Detecting Mac model and capabilities..."

    local product_name=$(system_profiler SPHardwareDataType | awk '/Model Name/ {print substr($0, index($0,$3))}')
    debug "Product name: $product_name"

    case "$product_name" in
        *"Mac Studio"*)
            MAC_TYPE="studio"
            MAC_MODEL="Mac-Studio"
            IS_PORTABLE=false
            IS_SERVER_CLASS=true
            ;;
        *"Mac mini"*)
            MAC_TYPE="mini"
            MAC_MODEL="Mac-Mini"
            IS_PORTABLE=false
            IS_SERVER_CLASS=true
            ;;
        *"MacBook Pro"*"14"*)
            MAC_TYPE="macbook_pro_14"
            MAC_MODEL="MacBook-Pro-14"
            IS_PORTABLE=true
            IS_SERVER_CLASS=false
            ;;
        *"MacBook Pro"*"16"*)
            MAC_TYPE="macbook_pro_16"
            MAC_MODEL="MacBook-Pro-16"
            IS_PORTABLE=true
            IS_SERVER_CLASS=false
            ;;
        *"MacBook Pro"*)
            # Generic MacBook Pro fallback
            MAC_TYPE="macbook_pro_generic"
            MAC_MODEL="MacBook-Pro"
            IS_PORTABLE=true
            IS_SERVER_CLASS=false
            ;;
        *"iMac"*"24"*)
            MAC_TYPE="imac_24"
            MAC_MODEL="iMac-24"
            IS_PORTABLE=false
            IS_SERVER_CLASS=false
            ;;
        *"Mac Pro"*)
            MAC_TYPE="mac_pro"
            MAC_MODEL="Mac-Pro"
            IS_PORTABLE=false
            IS_SERVER_CLASS=true
            ;;
        *)
            error "Unsupported Mac model: $product_name"
            exit 1
            ;;
    esac

    success "Detected: $product_name (Type: $MAC_TYPE)"
    debug "Characteristics: Portable=$IS_PORTABLE, Server-class=$IS_SERVER_CLASS"
}

# =============================================================================
# SYSTEM VALIDATION
# =============================================================================

validate_system_requirements() {
    info "Validating system requirements..."

    # Check macOS version
    local macos_version=$(sw_vers -productVersion)
    if ! is_version_gte "$macos_version" "$REQUIRED_MACOS_VERSION"; then
        error "macOS $REQUIRED_MACOS_VERSION or later required (current: $macos_version)"
        exit 1
    fi

    # Check Apple Silicon
    if [[ $(uname -m) != "arm64" ]]; then
        error "This script requires Apple Silicon (ARM64) architecture"
        exit 1
    fi

    # Check not running as root
    if [[ $EUID -eq 0 ]]; then
        error "Do not run this script as root"
        exit 1
    fi

    # Check sudo capability (skip in dry-run mode)
    if [[ $DRY_RUN == false ]]; then
        if ! sudo -n true 2>/dev/null; then
            info "Administrative privileges required for system configuration"
            sudo -v || { error "Cannot obtain administrative privileges"; exit 1; }
        fi
    else
        debug "Skipping sudo check in dry-run mode"
    fi

    # Check disk space (require at least 5GB free)
    local free_space=$(df -g / | awk 'NR==2 {print $4}')
    if [[ $free_space -lt 5 ]]; then
        warn "Low disk space: ${free_space}GB free (5GB recommended)"
    fi

    success "System requirements validated"
}

# =============================================================================
# ENHANCED POWER MANAGEMENT
# =============================================================================

configure_enhanced_power_management() {
    info "Configuring optimised power management for $MAC_TYPE..."

    if [[ $DRY_RUN == true ]]; then
        info "[DRY RUN] Would configure power management for $MAC_TYPE"
        return 0
    fi

    case $MAC_TYPE in
        studio|mac_pro)
            # High-performance workstation settings
            info "Applying workstation power profile..."

            # Never sleep, optimise for performance
            sudo pmset sleep 0
            sudo pmset displaysleep 30
            sudo pmset disksleep 0
            sudo pmset womp 1          # Wake on network access
            sudo pmset autorestart 1   # Auto-restart after power failure
            sudo pmset powernap 1      # Enable Power Nap

            # Thermal management for sustained performance
            sudo pmset -a ttyskeepawake 1  # Prevent sleep when SSH connected

            success "Workstation power profile applied"
            ;;

        mini)
            # Server/headless optimised settings
            info "Applying server power profile..."

            sudo pmset sleep 0
            sudo pmset displaysleep 10    # Quick display sleep for headless
            sudo pmset disksleep 0
            sudo pmset womp 1
            sudo pmset autorestart 1
            sudo pmset powernap 1
            sudo pmset -a ttyskeepawake 1

            # Enable auto-login for headless operation if requested
            if confirm "Enable auto-login for headless operation?"; then
                defaults write com.apple.loginwindow autoLoginUser -string "$(whoami)"
                success "Auto-login enabled"
            fi

            success "Server power profile applied"
            ;;

        macbook_pro_14|macbook_pro_16|macbook_pro_generic)
            # Battery-optimised settings with AC/battery profiles
            info "Applying laptop power profile with battery optimisation..."

            # AC power settings (performance)
            sudo pmset -c sleep 0
            sudo pmset -c displaysleep 15
            sudo pmset -c disksleep 10
            sudo pmset -c powernap 1

            # Battery settings (efficiency)
            sudo pmset -b sleep 10
            sudo pmset -b displaysleep 5
            sudo pmset -b disksleep 5
            sudo pmset -b powernap 0      # Disable Power Nap on battery
            sudo pmset -b lessbright 1    # Reduce brightness on battery

            # Enable automatic graphics switching for better battery life
            sudo pmset -a gpuswitch 2

            # Low power mode threshold
            sudo pmset -b lowpowermode 1

            success "Laptop power profile applied"
            ;;

        imac_24)
            # Desktop settings balanced for user experience
            info "Applying desktop power profile..."

            sudo pmset sleep 0
            sudo pmset displaysleep 20
            sudo pmset disksleep 10
            sudo pmset womp 1
            sudo pmset powernap 1

            success "Desktop power profile applied"
            ;;
    esac

    # Verify power settings
    debug "Current power settings:"
    pmset -g | head -20 | while read line; do debug "  $line"; done
}

# =============================================================================
# COMPREHENSIVE SECURITY CONFIGURATION
# =============================================================================

configure_comprehensive_security() {
    if [[ $SKIP_SECURITY == true ]]; then
        info "Skipping security configuration (--skip-security specified)"
        return 0
    fi

    info "Configuring comprehensive security settings..."

    if [[ $DRY_RUN == true ]]; then
        info "[DRY RUN] Would configure comprehensive security settings"
        return 0
    fi

    # Enhanced Application Firewall
    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on
    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setallowsigned on
    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setallowsignedapp on

    # Gatekeeper configuration
    sudo spctl --master-enable

    # FileVault encryption
    if confirm "Enable FileVault disk encryption? (Recommended)"; then
        if ! fdesetup status | grep -q "FileVault is On"; then
            info "Enabling FileVault disk encryption..."
            sudo fdesetup enable -user "$(whoami)"
            success "FileVault enabled - save your recovery key!"
        else
            info "FileVault already enabled"
        fi
    fi

    # Screen saver security
    defaults write com.apple.screensaver askForPassword -int 1
    defaults write com.apple.screensaver askForPasswordDelay -int 5

    # Disable guest account
    sudo defaults write /Library/Preferences/com.apple.loginwindow GuestEnabled -bool false

    # Secure Safari defaults
    defaults write com.apple.Safari IncludeDevelopMenu -bool true
    defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
    defaults write com.apple.Safari WebKitJavaScriptCanOpenWindowsAutomatically -bool false

    # Privacy settings
    defaults write com.apple.AdLib allowApplePersonalizedAdvertising -bool false

    # Touch ID for sudo (portable Macs only)
    if [[ $IS_PORTABLE == true ]]; then
        if grep -q "pam_tid.so" /etc/pam.d/sudo; then
            info "Touch ID for sudo already configured"
        else
            if confirm "Enable Touch ID for sudo commands?"; then
                sudo sed -i '' '2i\
auth       sufficient     pam_tid.so\
' /etc/pam.d/sudo
                success "Touch ID enabled for sudo"
            fi
        fi
    fi

    success "Comprehensive security configuration completed"
}

# =============================================================================
# NETWORK AND BASIC SYSTEM CONFIGURATION
# =============================================================================

configure_network_and_system_basics() {
    info "Configuring network and system basics..."

    if [[ $DRY_RUN == true ]]; then
        info "[DRY RUN] Would configure network and system settings"
        return 0
    fi

    # Set DNS to Cloudflare + Google
    local primary_service=$(networksetup -listnetworkserviceorder | awk -F') ' '/\\(1\\)/ {print $2}')
    if [[ -n $primary_service ]]; then
        if sudo networksetup -setdnsservers "$primary_service" 1.1.1.1 8.8.8.8; then
            success "DNS servers configured"
        else
            warn "Failed to configure DNS servers"
        fi
    else
        warn "Could not determine primary network service for DNS configuration"
    fi

    # Set timezone with error handling
    configure_timezone_safely

    success "Network and system basics configured"
}

# Safely configure timezone with fallbacks and error handling
configure_timezone_safely() {
    local target_timezone="Australia/Adelaide"
    
    info "Configuring timezone to $target_timezone..."
    
    # Check current timezone
    local current_timezone=$(sudo systemsetup -gettimezone 2>/dev/null | awk -F': ' '{print $2}')
    if [[ "$current_timezone" == "$target_timezone" ]]; then
        info "Timezone already set to $target_timezone"
        return 0
    fi
    
    # Try primary method: systemsetup
    if configure_timezone_systemsetup "$target_timezone"; then
        success "Timezone configured using systemsetup"
        return 0
    fi
    
    # Try fallback method: user defaults
    if configure_timezone_defaults "$target_timezone"; then
        success "Timezone configured using user defaults"
        return 0
    fi
    
    # If all methods fail, provide manual instructions
    warn "Automatic timezone configuration failed"
    info "Please set timezone manually:"
    info "  System Preferences → General → Date & Time → Set time zone automatically"
    info "  Or manually select: $target_timezone"
    
    return 1
}

# Primary timezone configuration method
configure_timezone_systemsetup() {
    local timezone=$1
    
    debug "Attempting timezone configuration with systemsetup..."
    
    # First, verify the timezone is valid
    if ! sudo systemsetup -listtimezones 2>/dev/null | grep -q "^$timezone$"; then
        warn "Timezone '$timezone' not found in system timezone list"
        return 1
    fi
    
    # Try to set timezone with timeout to prevent hanging
    local temp_output=$(mktemp)
    
    # Set timezone (suppress stderr to avoid cluttering output with internal errors)
    if timeout 30 sudo systemsetup -settimezone "$timezone" 2>"$temp_output"; then
        debug "Timezone set successfully"
        
        # Try to enable network time
        if timeout 30 sudo systemsetup -setusingnetworktime on 2>/dev/null; then
            debug "Network time enabled"
        else
            warn "Could not enable network time synchronization"
        fi
        
        rm -f "$temp_output"
        return 0
    else
        local exit_code=$?
        debug "systemsetup failed with exit code: $exit_code"
        
        # Check if the error output contains specific error information
        if [[ -s "$temp_output" ]]; then
            debug "systemsetup error output: $(cat "$temp_output")"
        fi
        
        rm -f "$temp_output"
        return 1
    fi
}

# Fallback timezone configuration method using user defaults
configure_timezone_defaults() {
    local timezone=$1
    
    debug "Attempting timezone configuration with user defaults..."
    
    # Set timezone for the current user
    if defaults write NSGlobalDomain AppleICUDateFormatStrings -dict-add "1" "$timezone" 2>/dev/null; then
        debug "User timezone preference set"
        
        # Try to set system timezone via launchctl if available
        if sudo launchctl setenv TZ "$timezone" 2>/dev/null; then
            debug "System timezone environment variable set"
        fi
        
        return 0
    else
        debug "User defaults timezone configuration failed"
        return 1
    fi
}

# =============================================================================
# SHARING SERVICES WITH MODEL-SPECIFIC LOGIC
# =============================================================================

configure_sharing_services() {
    info "Configuring sharing services based on Mac type..."

    if [[ $DRY_RUN == true ]]; then
        info "[DRY RUN] Would configure sharing services for $MAC_TYPE"
        return 0
    fi

    # Default sharing settings based on Mac characteristics
    local enable_ssh=$IS_SERVER_CLASS
    local enable_screen_sharing=$IS_SERVER_CLASS

    # Interactive override if desired
    echo "\\nRecommended sharing settings for $MAC_TYPE:"
    echo "  SSH: $(($enable_ssh && echo \"Enabled\") || echo \"Disabled\")"
    echo "  Screen Sharing: $(($enable_screen_sharing && echo \"Enabled\") || echo \"Disabled\")"

    if ! confirm "Use recommended settings?"; then
        read -q "enable_ssh?Enable SSH? (y/N): "; echo
        read -q "enable_screen_sharing?Enable Screen Sharing? (y/N): "; echo
    fi

    # Apply SSH settings
    if [[ $enable_ssh == true ]]; then
        sudo systemsetup -setremotelogin on
        success "SSH enabled"
    else
        sudo systemsetup -setremotelogin off
        info "SSH disabled"
    fi

    # Apply Screen Sharing
    if [[ $enable_screen_sharing == true ]]; then
        sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart \
            -activate -configure -access -on -restart -agent -privs -all
        success "Screen Sharing enabled"
    fi
}

# =============================================================================
# SYSTEM DEPENDENCIES INSTALLATION
# =============================================================================

install_system_dependencies() {
    info "Installing system dependencies..."

    if [[ $DRY_RUN == true ]]; then
        info "[DRY RUN] Would install Xcode CLI Tools, Homebrew, and GNU Stow"
        return 0
    fi

    # Xcode Command Line Tools
    if ! xcode-select -p &> /dev/null; then
        info "Installing Xcode Command Line Tools..."
        xcode-select --install

        # Wait for installation with progress
        info "Waiting for Xcode CLI tools installation..."
        while ! xcode-select -p &> /dev/null; do
            printf "."
            sleep 30
        done
        echo

        # Accept Xcode license with safe sudo wrapper
        safe_sudo xcodebuild -license accept
        success "Xcode Command Line Tools installed"
    else
        info "Xcode Command Line Tools already installed"
    fi

    # Homebrew
    if ! command_exists brew; then
        info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # Add to PATH
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
        success "Homebrew installed"
    else
        info "Homebrew already installed, updating..."
        brew update
    fi

    # GNU Stow (required for dotfiles management)
    if ! command_exists stow; then
        info "Installing GNU Stow (required for dotfiles)..."
        brew install stow
        success "GNU Stow installed"
    else
        info "GNU Stow already available"
    fi

    success "System dependencies installed"
}

# =============================================================================
# MAIL AND CALENDAR CONFIGURATION
# =============================================================================

configure_mail_calendar() {
    info "Configuring Mail and Calendar..."

    if [[ $DRY_RUN == true ]]; then
        info "[DRY RUN] Would configure Mail and Calendar settings"
        return 0
    fi

    # Mail.app configurations
    configure_mail_settings

    # Calendar.app configurations
    configure_calendar_settings

    success "Mail and Calendar configuration completed"
}

configure_mail_settings() {
    info "Configuring Mail.app settings..."

    # Helper function to safely write defaults (reuse from contacts)
    safe_defaults_write() {
        local domain=$1
        local key=$2
        local type=$3
        local value=$4

        if defaults write "$domain" "$key" "$type" "$value" 2>/dev/null; then
            debug "Set $domain $key = $value"
        else
            debug "Could not set $domain $key (may be restricted in this macOS version)"
        fi
    }

    # General Mail preferences
    safe_defaults_write com.apple.mail MailThreadingEnabled -bool true
    safe_defaults_write com.apple.mail ConversationViewSortDescending -bool true
    safe_defaults_write com.apple.mail DisableReplyAnimations -bool true
    safe_defaults_write com.apple.mail DisableSendAnimations -bool true
    safe_defaults_write com.apple.mail DisableInlineAttachmentViewing -bool true

    # Privacy and security
    safe_defaults_write com.apple.mail DisableURLLoading -bool true
    safe_defaults_write com.apple.mail OptionallyLoadURLsInMessages -bool false
    safe_defaults_write com.apple.mail MessageViewerWebKitLoadExternalImagesAutomatically -bool false

    # Threading and organisation
    safe_defaults_write com.apple.mail NumberOfSnippetLines -int 0
    safe_defaults_write com.apple.mail ConversationViewSpansMailboxes -bool true
    safe_defaults_write com.apple.mail ConversationViewMarkAllAsRead -bool true

    # Performance optimisations
    safe_defaults_write com.apple.mail IndexDecryptedMessages -bool true
    safe_defaults_write com.apple.mail SuppressDeliveryFailure -bool false

    # Notification settings
    safe_defaults_write com.apple.mail MailSound -string ""
    safe_defaults_write com.apple.mail PlayMailSounds -bool false

    # Account setup prompts and suggestions
    if confirm "Configure common mail provider settings?"; then
        configure_mail_provider_optimisations
    fi

    success "Mail.app settings configured (some settings may be restricted by macOS)"
}

configure_mail_provider_optimisations() {
    info "Configuring optimisations for common mail providers..."

    # Helper function to safely write defaults (reuse from above)
    safe_defaults_write() {
        local domain=$1
        local key=$2
        local type=$3
        local value=$4

        if defaults write "$domain" "$key" "$type" "$value" 2>/dev/null; then
            debug "Set $domain $key = $value"
        else
            debug "Could not set $domain $key (may be restricted in this macOS version)"
        fi
    }

    # Gmail optimisations
    info "Setting Gmail-friendly defaults..."
    safe_defaults_write com.apple.mail GMAccountUseGmailLabels -bool true
    safe_defaults_write com.apple.mail GMAccountShowGmailLabels -bool false

    # Exchange/Outlook optimisations
    info "Setting Exchange/Outlook-friendly defaults..."
    safe_defaults_write com.apple.mail ExchangeAccountPushChanges -bool true
    safe_defaults_write com.apple.mail ExchangeAccountSyncCalendars -bool true
    safe_defaults_write com.apple.mail ExchangeAccountSyncContacts -bool true

    # IMAP optimisations for common providers
    safe_defaults_write com.apple.mail IMAPSSLEnabled -bool true
    safe_defaults_write com.apple.mail SMTPSSLEnabled -bool true
    safe_defaults_write com.apple.mail POP3SSLEnabled -bool true

    # Server timeouts
    safe_defaults_write com.apple.mail IMAPServerTimeout -int 30
    safe_defaults_write com.apple.mail SMTPServerTimeout -int 30

    debug "Mail provider optimisations applied"
}

configure_calendar_settings() {
    info "Configuring Calendar.app settings..."

    # Helper function to safely write defaults (reuse from above)
    safe_defaults_write() {
        local domain=$1
        local key=$2
        local type=$3
        local value=$4

        if defaults write "$domain" "$key" "$type" "$value" 2>/dev/null; then
            debug "Set $domain $key = $value"
        else
            debug "Could not set $domain $key (may be restricted in this macOS version)"
        fi
    }

    # General calendar preferences
    safe_defaults_write com.apple.iCal "first day of week" -int 1
    safe_defaults_write com.apple.iCal "n days of week" -int 7
    safe_defaults_write com.apple.iCal "number of hours displayed" -int 12
    safe_defaults_write com.apple.iCal "first minute of work hours" -int 540
    safe_defaults_write com.apple.iCal "last minute of work hours" -int 1080

    # Default calendar and time zone
    safe_defaults_write com.apple.iCal "TimeZone support enabled" -bool true
    safe_defaults_write com.apple.iCal "Show time in month view" -bool true
    safe_defaults_write com.apple.iCal "Show heat map in month view" -bool true

    # Event defaults
    safe_defaults_write com.apple.iCal "Default duration in minutes for new event" -int 60
    safe_defaults_write com.apple.iCal "Default alert times" -array 15

    # Privacy and sharing
    safe_defaults_write com.apple.iCal "Show shared calendar messages in notification center" -bool false
    safe_defaults_write com.apple.iCal "Shared calendar messages in notification center" -bool false

    # Sync and accounts
    safe_defaults_write com.apple.iCal "CalDAV sharing enabled" -bool true
    safe_defaults_write com.apple.iCal "Enable CalDAV sharing invitations" -bool true

    # Australian locale-specific settings
    safe_defaults_write com.apple.iCal "Show week numbers" -bool true
    safe_defaults_write com.apple.iCal "Imperial measurement units" -bool false

    # Integration with other apps
    safe_defaults_write com.apple.iCal "Add automatically detected events" -bool false
    safe_defaults_write com.apple.iCal "Add automatically detected events from Mail" -bool false

    success "Calendar.app settings configured (some settings may be restricted by macOS)"
}


# =============================================================================
# DOTFILES MANAGEMENT (FROM OPT4)
# =============================================================================

# Verify tools are available for dotfiles management
verify_dotfiles_tools() {
    info "Verifying dotfiles management tools..."

    # Refresh PATH to include newly installed tools
    if [[ -d /opt/homebrew/bin ]]; then
        export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
    fi

    # Check for git with multiple fallbacks (prefer absolute paths)
    local git_cmd=""
    if [[ -x "/opt/homebrew/bin/git" ]]; then
        git_cmd="/opt/homebrew/bin/git"
    elif [[ -x "/Library/Developer/CommandLineTools/usr/bin/git" ]]; then
        git_cmd="/Library/Developer/CommandLineTools/usr/bin/git"
    elif [[ -x "/usr/bin/git" ]]; then
        git_cmd="/usr/bin/git"
    elif command_exists git; then
        git_cmd="git"
    else
        error "Git is not available. Please install Xcode Command Line Tools and run the script again."
        return 1
    fi

    # Verify git is functional
    if ! "$git_cmd" --version &>/dev/null; then
        error "Git is installed but not functional: $git_cmd"
        return 1
    fi

    # Check for stow with multiple fallbacks (prefer absolute paths)
    local stow_cmd=""
    if [[ -x "/opt/homebrew/bin/stow" ]]; then
        stow_cmd="/opt/homebrew/bin/stow"
    elif command_exists stow; then
        stow_cmd="stow"
    else
        error "GNU Stow is not available. Please install it with: brew install stow"
        return 1
    fi

    # Verify stow is functional
    if ! "$stow_cmd" --version &>/dev/null; then
        error "GNU Stow is installed but not functional: $stow_cmd"
        return 1
    fi

    # Store verified commands for use in other functions
    export VERIFIED_GIT_CMD="$git_cmd"
    export VERIFIED_STOW_CMD="$stow_cmd"

    success "Dotfiles tools verified: git ($git_cmd), stow ($stow_cmd)"
    return 0
}

# Application configuration paths
typeset -A APP_CONFIG_PATHS=(
    [karabiner]="$HOME/.config/karabiner"
    [zed]="$HOME/.config/zed"
    [ghostty]="$HOME/.config/ghostty"
    [git]="$HOME/.gitconfig"
    [ssh]="$HOME/.ssh/config"
    [vim]="$HOME/.vimrc"
    [tmux]="$HOME/.tmux.conf"
)

# Stow packages to install
typeset -a STOW_PACKAGES=(
    "zsh"           # .zshrc, .zshenv, .zprofile
    "git"           # .gitconfig, .gitignore_global
    "ssh"           # .ssh/config
    "karabiner"     # karabiner config
    "zed"           # zed editor config
    "ghostty"       # ghostty terminal config
    "vim"           # .vimrc, .vim/
    "tmux"          # .tmux.conf
)

# Dotfiles configuration
typeset -g DOTFILES_DIR="$HOME/.dotfiles"

backup_existing_configs() {
    info "Backing up existing configuration files..."

    if [[ $DRY_RUN == true ]]; then
        info "[DRY RUN] Would backup existing configurations to $BACKUP_DIR"
        return 0
    fi

    mkdir -p "$BACKUP_DIR"

    # Backup existing dotfiles that might conflict
    local -a files_to_backup=(
        "$HOME/.zshrc"
        "$HOME/.zshenv"
        "$HOME/.zprofile"
        "$HOME/.gitconfig"
        "$HOME/.vimrc"
        "$HOME/.tmux.conf"
    )

    for file in $files_to_backup; do
        if [[ -f "$file" && ! -L "$file" ]]; then
            cp "$file" "$BACKUP_DIR/" 2>/dev/null || true
            debug "Backed up: $(/usr/bin/basename $file)"
        fi
    done

    # Backup application config directories
    for app_name path in ${(kv)APP_CONFIG_PATHS}; do
        if [[ -d "$path" && ! -L "$path" ]]; then
            cp -r "$path" "$BACKUP_DIR/$(/usr/bin/basename $path)-$app_name" 2>/dev/null || true
            debug "Backed up: $app_name config directory"
        fi
    done

    success "Configuration backup completed: $BACKUP_DIR"
}

clone_or_update_dotfiles() {
    info "Managing dotfiles repository..."

    # Use verified git command with fallback
    local git_cmd="${VERIFIED_GIT_CMD:-}"
    if [[ -z "$git_cmd" ]]; then
        # Fallback verification if environment variable is not set
        if [[ -x "/opt/homebrew/bin/git" ]]; then
            git_cmd="/opt/homebrew/bin/git"
        elif [[ -x "/Library/Developer/CommandLineTools/usr/bin/git" ]]; then
            git_cmd="/Library/Developer/CommandLineTools/usr/bin/git"
        elif [[ -x "/usr/bin/git" ]]; then
            git_cmd="/usr/bin/git"
        elif command_exists git; then
            git_cmd="git"
        else
            error "Git command not found. Please install Xcode Command Line Tools."
            return 1
        fi
    fi
    debug "Using verified git command: $git_cmd"

    # Use provided repo or prompt for one
    if [[ -z $DOTFILES_REPO ]]; then
        if [[ $INTERACTIVE == true && $DRY_RUN == false ]]; then
            echo -n "Enter your dotfiles repository URL (or press Enter to skip): "
            read DOTFILES_REPO
        fi

        if [[ -z $DOTFILES_REPO ]]; then
            warn "No dotfiles repository specified, skipping dotfiles setup"
            return 0
        fi
    fi

    if [[ $DRY_RUN == true ]]; then
        info "[DRY RUN] Would clone/update dotfiles from: $DOTFILES_REPO"
        return 0
    fi

    if [[ -d "$DOTFILES_DIR" ]]; then
        info "Dotfiles directory exists, updating..."
        cd "$DOTFILES_DIR"
        "$git_cmd" pull origin main || "$git_cmd" pull origin master || warn "Could not update dotfiles"
    else
        info "Cloning dotfiles repository..."
        debug "Executing: $git_cmd clone $DOTFILES_REPO $DOTFILES_DIR"
        if ! "$git_cmd" clone "$DOTFILES_REPO" "$DOTFILES_DIR"; then
            error "Failed to clone dotfiles repository"
            return 1
        fi
        cd "$DOTFILES_DIR"
    fi

    success "Dotfiles repository ready: $DOTFILES_DIR"
}

apply_dotfiles_with_stow() {
    if [[ ! -d "$DOTFILES_DIR" ]]; then
        warn "No dotfiles directory found, skipping stow application"
        return 0
    fi

    info "Applying dotfiles with GNU Stow..."

    if [[ $DRY_RUN == true ]]; then
        info "[DRY RUN] Would apply dotfiles with stow"
        return 0
    fi

    # Use verified stow command with fallback
    local stow_cmd="${VERIFIED_STOW_CMD:-}"
    if [[ -z "$stow_cmd" ]]; then
        # Fallback verification if environment variable is not set
        if [[ -x "/opt/homebrew/bin/stow" ]]; then
            stow_cmd="/opt/homebrew/bin/stow"
        elif command_exists stow; then
            stow_cmd="stow"
        else
            error "Stow command not found. Please ensure GNU Stow is installed."
            return 1
        fi
    fi
    debug "Using verified stow command: $stow_cmd"

    cd "$DOTFILES_DIR"

    # Show repository structure
    debug "Dotfiles repository structure:"
    /usr/bin/find . -maxdepth 2 -type d | /usr/bin/head -10 | while read dir; do
        debug "  $dir"
    done

    # Apply each stow package
    local applied_packages=()
    local failed_packages=()

    for package in $STOW_PACKAGES; do
        if [[ -d "$package" ]]; then
            info "Stowing package: $package"

            # Remove conflicting files first
            case $package in
                zsh)
                    [[ -f "$HOME/.zshrc" && ! -L "$HOME/.zshrc" ]] && rm "$HOME/.zshrc"
                    [[ -f "$HOME/.zshenv" && ! -L "$HOME/.zshenv" ]] && rm "$HOME/.zshenv"
                    [[ -f "$HOME/.zprofile" && ! -L "$HOME/.zprofile" ]] && rm "$HOME/.zprofile"
                    ;;
                git)
                    [[ -f "$HOME/.gitconfig" && ! -L "$HOME/.gitconfig" ]] && rm "$HOME/.gitconfig"
                    ;;
                vim)
                    [[ -f "$HOME/.vimrc" && ! -L "$HOME/.vimrc" ]] && rm "$HOME/.vimrc"
                    ;;
                tmux)
                    [[ -f "$HOME/.tmux.conf" && ! -L "$HOME/.tmux.conf" ]] && rm "$HOME/.tmux.conf"
                    ;;
            esac

            # Apply stow package with explicit target directory
            if "$stow_cmd" -v --target="$HOME" "$package" 2>&1; then
                success "Applied: $package"
                applied_packages+=("$package")
            else
                local exit_code=$?
                warn "Failed to apply: $package (exit code: $exit_code)"
                failed_packages+=("$package")
            fi
        else
            debug "Package directory not found: $package"
        fi
    done

    # Report results
    if [[ ${#applied_packages[@]} -gt 0 ]]; then
        info "Successfully applied packages: ${applied_packages[*]}"
    fi
    if [[ ${#failed_packages[@]} -gt 0 ]]; then
        warn "Failed to apply packages: ${failed_packages[*]}"
    fi

    success "Dotfiles stow process completed"
}

verify_application_configs() {
    info "Verifying application configurations..."

    # Check that application config files were properly linked
    for app_name path in ${(kv)APP_CONFIG_PATHS}; do
        if [[ -e "$path" ]]; then
            if [[ -L "$path" ]]; then
                local target=$(/usr/bin/readlink "$path")
                success "$app_name config linked: $path -> $target"
            else
                info "$app_name config exists (not symlinked): $path"
            fi
        else
            debug "$app_name config not found: $path"
        fi
    done
}

setup_shell_integration() {
    info "Setting up shell integration..."

    if [[ $DRY_RUN == true ]]; then
        info "[DRY RUN] Would set up shell integration"
        return 0
    fi

    # Ensure zsh is the default shell
    if [[ "$SHELL" != "/bin/zsh" ]]; then
        info "Setting zsh as default shell..."
        chsh -s /bin/zsh
        success "Default shell changed to zsh"
    fi

    # Verify Homebrew is available before sourcing configs
    local homebrew_before=false
    if command -v brew &>/dev/null; then
        homebrew_before=true
        debug "Homebrew available before sourcing configs: $(command -v brew)"
    else
        debug "Homebrew not available before sourcing configs"
    fi

    # Source the new configuration in current session
    local configs_sourced=()
    local configs_failed=()

    # Try to source each configuration file
    for config_file in "$HOME/.zshenv" "$HOME/.zprofile" "$HOME/.zshrc"; do
        if [[ -f "$config_file" ]]; then
            debug "Sourcing: $config_file"
            if source "$config_file" 2>/dev/null; then
                configs_sourced+=("$(basename "$config_file")")
            else
                configs_failed+=("$(basename "$config_file")")
                warn "Failed to source: $config_file"
            fi
        fi
    done

    # Verify shell configuration
    if [[ ${#configs_sourced[@]} -gt 0 ]]; then
        info "Successfully sourced: ${configs_sourced[*]}"
    fi
    if [[ ${#configs_failed[@]} -gt 0 ]]; then
        warn "Failed to source: ${configs_failed[*]}"
    fi

    # Verify Homebrew is available after sourcing configs
    local homebrew_after=false
    if command -v brew &>/dev/null; then
        homebrew_after=true
        debug "Homebrew available after sourcing configs: $(command -v brew)"
    else
        debug "Homebrew not available after sourcing configs"
    fi

    # Handle Homebrew PATH issues
    if [[ $homebrew_before == true && $homebrew_after == false ]]; then
        warn "Homebrew was available before but not after sourcing configs - dotfiles may have overridden PATH"
        ensure_homebrew_path
    elif [[ $homebrew_before == false && $homebrew_after == false ]]; then
        warn "Homebrew not available in shell environment"
        ensure_homebrew_path
    elif [[ $homebrew_after == true ]]; then
        debug "Homebrew is available in shell"
    fi

    success "Shell integration completed"
}

# Ensure Homebrew PATH is available in the current shell
ensure_homebrew_path() {
    info "Ensuring Homebrew PATH is available..."

    # Check if Homebrew is installed
    if [[ -x "/opt/homebrew/bin/brew" ]]; then
        info "Homebrew found at /opt/homebrew/bin/brew, adding to PATH"
        
        # Add Homebrew to current session PATH
        export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
        
        # Load Homebrew environment
        eval "$(/opt/homebrew/bin/brew shellenv)"
        
        # Verify it's now available
        if command -v brew &>/dev/null; then
            success "Homebrew PATH restored: $(command -v brew)"
            
            # Provide guidance for permanent fix
            info "To fix this permanently, ensure your dotfiles include Homebrew PATH setup:"
            info "  Add to ~/.zprofile: eval \"\$(/opt/homebrew/bin/brew shellenv)\""
        else
            warn "Failed to restore Homebrew PATH"
            debug_path_information
        fi
    else
        warn "Homebrew not found at expected location: /opt/homebrew/bin/brew"
        debug_path_information
    fi
}

# Debug PATH information for troubleshooting
debug_path_information() {
    debug "PATH debugging information:"
    debug "  Current PATH: $PATH"
    debug "  Homebrew locations checked:"
    for location in "/opt/homebrew/bin/brew" "/usr/local/bin/brew"; do
        if [[ -x "$location" ]]; then
            debug "    ✓ Found: $location"
        else
            debug "    ✗ Not found: $location"
        fi
    done
    debug "  PATH contains Homebrew directories:"
    if [[ "$PATH" == *"/opt/homebrew/bin"* ]]; then
        debug "    ✓ /opt/homebrew/bin is in PATH"
    else
        debug "    ✗ /opt/homebrew/bin is NOT in PATH"
    fi
    if [[ "$PATH" == *"/usr/local/bin"* ]]; then
        debug "    ✓ /usr/local/bin is in PATH"
    else
        debug "    ✗ /usr/local/bin is NOT in PATH"
    fi
}

# Comprehensive verification of final dotfiles state
verify_final_dotfiles_state() {
    info "Performing final verification of dotfiles setup..."

    if [[ $DRY_RUN == true ]]; then
        info "[DRY RUN] Would verify final dotfiles state"
        return 0
    fi

    local verification_passed=true

    # Verify dotfiles repository exists and is accessible
    if [[ -d "$DOTFILES_DIR" ]]; then
        info "✓ Dotfiles repository exists: $DOTFILES_DIR"
        
        # Verify it's a git repository
        if [[ -d "$DOTFILES_DIR/.git" ]]; then
            info "✓ Dotfiles repository is a git repository"
        else
            warn "⚠ Dotfiles directory is not a git repository"
            verification_passed=false
        fi
    else
        warn "⚠ Dotfiles repository not found at: $DOTFILES_DIR"
        verification_passed=false
    fi

    # Verify key symlinks are created
    local expected_symlinks=(
        "$HOME/.zshrc"
        "$HOME/.zshenv"
        "$HOME/.gitconfig"
    )

    for symlink in "${expected_symlinks[@]}"; do
        if [[ -L "$symlink" ]]; then
            local target=$(readlink "$symlink")
            info "✓ Symlink exists: $symlink -> $target"
        elif [[ -f "$symlink" ]]; then
            warn "⚠ File exists but is not a symlink: $symlink"
        else
            debug "File not found (may be optional): $symlink"
        fi
    done

    # Verify application config directories
    local verified_apps=()
    local missing_apps=()

    for app_name path in ${(kv)APP_CONFIG_PATHS}; do
        if [[ -e "$path" ]]; then
            verified_apps+=("$app_name")
        else
            missing_apps+=("$app_name")
        fi
    done

    if [[ ${#verified_apps[@]} -gt 0 ]]; then
        info "✓ Application configs found: ${verified_apps[*]}"
    fi
    if [[ ${#missing_apps[@]} -gt 0 ]]; then
        debug "Application configs not found (may be optional): ${missing_apps[*]}"
    fi

    # Verify shell integration
    if [[ "$SHELL" == "/bin/zsh" ]]; then
        info "✓ Default shell is zsh"
    else
        warn "⚠ Default shell is not zsh: $SHELL"
        verification_passed=false
    fi

    # Verify tools are still available
    if command -v "${VERIFIED_GIT_CMD:-git}" &>/dev/null; then
        info "✓ Git is available: ${VERIFIED_GIT_CMD:-git}"
    else
        warn "⚠ Git is not available in current environment"
        verification_passed=false
    fi

    if command -v "${VERIFIED_STOW_CMD:-stow}" &>/dev/null; then
        info "✓ Stow is available: ${VERIFIED_STOW_CMD:-stow}"
    else
        warn "⚠ Stow is not available in current environment"
        verification_passed=false
    fi

    # Overall verification result
    if [[ $verification_passed == true ]]; then
        success "Final dotfiles verification passed"
        return 0
    else
        warn "Final dotfiles verification completed with warnings"
        return 0  # Don't fail the entire script for verification warnings
    fi
}

# =============================================================================
# COMMAND-LINE ARGUMENT PARSING
# =============================================================================

usage() {
    /bin/cat << EOF
${BOLD}macOS Setup Script v${SCRIPT_VERSION}${RESET}

${BOLD}USAGE${RESET}
    $SCRIPT_NAME [options]

${BOLD}OPTIONS${RESET}
    -v, --verbose           Enable verbose output and debug logging
    --non-interactive       Run without user prompts (use defaults)
    --dry-run              Show what would be done without making changes
    --skip-security        Skip security configuration (for testing)
    --dotfiles-repo URL    Specify dotfiles repository URL
    -h, --help             Show this help message

${BOLD}MODULE CONFIGURATION${RESET}
    You can enable/disable specific modules by editing the script:

    ENABLE_NETWORK_CONFIG      - Network and system basics (DNS, timezone)
    ENABLE_POWER_MANAGEMENT    - Hardware-specific power optimisations
    ENABLE_SECURITY_CONFIG     - Comprehensive security (firewall, FileVault)
    ENABLE_SHARING_SERVICES    - SSH, Screen Sharing based on Mac type
    ENABLE_MAIL_CALENDAR       - Mail and Calendar configuration
    ENABLE_SYSTEM_DEPENDENCIES - Xcode CLI, Homebrew, GNU Stow
    ENABLE_DOTFILES_MANAGEMENT - Backup, clone, stow dotfiles

    Set any to 'false' to disable that module.

${BOLD}EXAMPLES${RESET}
    # Interactive setup
    $SCRIPT_NAME

    # Automated setup with defaults
    $SCRIPT_NAME --non-interactive

    # Dry run to see what would be done
    $SCRIPT_NAME --dry-run --verbose

    # With custom dotfiles repository
    $SCRIPT_NAME --dotfiles-repo https://github.com/user/dotfiles.git

${BOLD}COMMON CONFIGURATIONS${RESET}
    # Basic system setup (no dotfiles)
    Set ENABLE_DOTFILES_MANAGEMENT=false

    # Security-focused setup
    Set ENABLE_MAIL_CALENDAR=false, ENABLE_SHARING_SERVICES=false

    # Development machine (all modules)
    Use default settings (all enabled)

    # Server setup
    Set ENABLE_MAIL_CALENDAR=false, keep ENABLE_SHARING_SERVICES=true

${BOLD}ARCHITECTURE${RESET}
    This script uses a hybrid approach:
    • System-level configs (power, security, networking)
    • External dotfiles management via GNU Stow
    • Minimal package installation (system dependencies only)
    • Application packages managed via Brewfile in dotfiles

${BOLD}VERSION${RESET}
    $SCRIPT_VERSION
EOF
}

parse_command_line_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -v|--verbose)
                VERBOSE=true
                debug "Verbose mode enabled"
                ;;
            --non-interactive)
                INTERACTIVE=false
                info "Non-interactive mode enabled"
                ;;
            --dry-run)
                DRY_RUN=true
                warn "Dry run mode enabled - no changes will be made"
                ;;
            --skip-security)
                SKIP_SECURITY=true
                warn "Security configuration will be skipped"
                ;;
            --dotfiles-repo)
                DOTFILES_REPO="$2"
                info "Using dotfiles repository: $DOTFILES_REPO"
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                warn "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
        shift
    done
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

print_setup_header() {
    /bin/cat << 'EOF'

╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║     Enhanced Apple Silicon macOS Setup Script v4.0              ║
║     Hybrid System Configuration + Dotfiles Management           ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝

EOF
}

print_architecture_summary() {
    /bin/cat << EOF

${CYAN}╔══════════════════════════════════════════════════════════════════╗
║                    ARCHITECTURE DECISIONS                       ║
╚══════════════════════════════════════════════════════════════════╝${RESET}

${BOLD}SYSTEM SCRIPT (This File):${RESET}
  • System-level configurations (power, security, networking)
  • Mail, Calendar, and Contacts app configurations
  • Hardware-specific optimisations
  • Essential dependencies (Xcode CLI, Homebrew, GNU Stow)
  • Dotfiles repository management and stow application

${BOLD}DOTFILES REPOSITORY (External):${RESET}
  • Application configurations (Karabiner, Zed, Ghostty, etc.)
  • User preferences and customisations
  • Package management via Brewfile
  • Development environment setup scripts

${BOLD}NEXT STEPS AFTER SETUP:${RESET}
  1. Open new terminal to load dotfiles
  2. Run: brew bundle --file ~/.dotfiles/Brewfile
  3. Run: ~/.dotfiles/scripts/install-apps.sh (if exists)

EOF
}

main() {
    # Parse command line arguments
    parse_command_line_arguments "$@"

    # Display header
    print_setup_header

    # System validation
    validate_system_requirements
    detect_mac_model

    # Validate module configuration
    validate_module_configuration || exit 1

    # Show architecture summary
    print_architecture_summary

    # Confirmation prompt
    if [[ $DRY_RUN == false ]]; then
        echo "${YELLOW}This script will configure your $MAC_TYPE with optimised settings.${RESET}"
        if ! confirm "Continue with setup?"; then
            info "Setup cancelled by user"
            exit 0
        fi
    fi

    # Request sudo and keep alive
    if [[ $DRY_RUN == false ]]; then
        info "Requesting administrative privileges for the duration of the script..."
        sudo -v
        
        # Try to extend sudo timeout for this session
        # Note: This requires the timestamp_timeout setting in /etc/sudoers
        # If this fails, fall back to the keep-alive mechanism
        local current_timeout=$(sudo -l 2>/dev/null | grep "timestamp_timeout" | awk '{print $NF}' || echo "")
        if [[ -n "$current_timeout" ]]; then
            debug "Current sudo timeout: $current_timeout minutes"
        fi
        
        # Create a more persistent sudo session by running a harmless command
        # This helps establish a longer-lasting credential cache
        sudo -v && sudo true
        
        # Aggressive keep-alive that actively refreshes credentials
        (
            # Wait a moment for the main script to get started
            sleep 5
            
            local keepalive_count=0
            while true; do
                sleep 10  # Check every 10 seconds for more aggressive refresh
                ((keepalive_count++))
                
                # Always try to refresh credentials, not just check them
                if sudo -n true 2>/dev/null; then
                    debug "Sudo keep-alive: cycle $keepalive_count - credentials valid"
                    # Proactively refresh even if valid to extend timeout
                    sudo -n -v 2>/dev/null || true
                else
                    debug "Sudo keep-alive: credentials expired after $keepalive_count cycles, attempting refresh"
                    # Try to refresh without prompting (will fail silently if not possible)
                    if ! sudo -n -v 2>/dev/null; then
                        debug "Sudo keep-alive: unable to refresh credentials non-interactively"
                        break
                    else
                        debug "Sudo keep-alive: credentials refreshed successfully"
                    fi
                fi
            done
            debug "Sudo keep-alive process exiting"
        ) &
        BACKGROUND_PIDS+=($!)
        
        debug "Sudo keep-alive process started (PID: $!)"
    fi

    info "Starting configuration process..."

    # Phase 1: System Configuration
    if [[ $ENABLE_NETWORK_CONFIG == true ]]; then
        configure_network_and_system_basics
    else
        info "Skipping network and system basics configuration (disabled)"
    fi

    if [[ $ENABLE_POWER_MANAGEMENT == true ]]; then
        configure_enhanced_power_management
    else
        info "Skipping power management configuration (disabled)"
    fi

    if [[ $ENABLE_SECURITY_CONFIG == true ]]; then
        # Refresh sudo credentials before security operations
        refresh_sudo
        configure_comprehensive_security
    else
        info "Skipping security configuration (disabled)"
    fi

    if [[ $ENABLE_SHARING_SERVICES == true ]]; then
        # Refresh sudo credentials before sharing services
        refresh_sudo
        configure_sharing_services
    else
        info "Skipping sharing services configuration (disabled)"
    fi

    if [[ $ENABLE_MAIL_CALENDAR == true ]]; then
        configure_mail_calendar
    else
        info "Skipping Mail and Calendar configuration (disabled)"
    fi

    # Phase 2: Dependencies and Tools
    if [[ $ENABLE_SYSTEM_DEPENDENCIES == true ]]; then
        # Refresh sudo credentials before system dependencies installation
        refresh_sudo
        install_system_dependencies
    else
        info "Skipping system dependencies installation (disabled)"
    fi

    # Final cleanup
    if [[ $DRY_RUN == false ]]; then
        # DNS cache flush is not critical, so don't fail the script if it fails
        if ! safe_sudo dscacheutil -flushcache; then
            warn "DNS cache flush failed, but continuing..."
        fi
    fi

    # Phase 3: Dotfiles Management (moved to end to ensure all dependencies are available)
    if [[ $ENABLE_DOTFILES_MANAGEMENT == true ]]; then
        # Check dependency
        if [[ $ENABLE_SYSTEM_DEPENDENCIES == false ]]; then
            warn "Dotfiles management requires system dependencies - GNU Stow may not be available"
            if [[ $INTERACTIVE == true ]]; then
                if ! confirm "Continue with dotfiles setup anyway?"; then
                    info "Skipping dotfiles management"
                    return 0
                fi
            fi
        fi

        # Refresh sudo credentials before dotfiles operations
        refresh_sudo

        # Verify tools are available after dependency installation
        verify_dotfiles_tools || return 1

        backup_existing_configs
        clone_or_update_dotfiles
        apply_dotfiles_with_stow
        verify_application_configs
        setup_shell_integration
        verify_final_dotfiles_state
    else
        info "Skipping dotfiles management (disabled)"
    fi

    # Success message
    /bin/cat << EOF

${GREEN}╔══════════════════════════════════════════════════════════════════╗
║                        SETUP COMPLETED!                         ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                  ║
║  ✅ System configuration applied for $MAC_TYPE
║  ✅ Enhanced power and security settings configured             ║
║  ✅ Mail and Calendar configured                                ║
║  ✅ System dependencies installed                               ║
║  ✅ Dotfiles applied with GNU Stow                              ║
║                                                                  ║
║  📁 Backup created: $BACKUP_DIR
║  📋 Log file: $LOG_FILE
║                                                                  ║
║  🔄 NEXT STEPS:                                                  ║
║     1. Open new terminal to load dotfiles                       ║
║     2. Run: brew bundle --file ~/.dotfiles/Brewfile             ║
║     3. Run any additional setup scripts in dotfiles             ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝${RESET}

EOF

    if [[ $DRY_RUN == false && $INTERACTIVE == true ]]; then
        if confirm "Restart now to complete setup?"; then
            info "Restarting system..."
            SCRIPT_EXITING=true
            safe_sudo shutdown -r now
        else
            info "Setup complete. Please restart when convenient."
        fi
    fi
    
    # Mark script as exiting for cleanup function
    SCRIPT_EXITING=true
}

# Execute main function if script is run directly
if [[ "${(%):-%x}" == "${0}" ]]; then
    main "$@"
fi

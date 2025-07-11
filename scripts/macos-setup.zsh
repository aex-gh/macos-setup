#!/usr/bin/env zsh
# ABOUTME: Enhanced macOS Setup Script v4.0 - Hybrid system configuration with comprehensive power and security management
# ABOUTME: Combines opt4's clean architecture with v3's advanced power management and security features

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

# Strict error handling
set -euo pipefail

# =============================================================================
# SCRIPT METADATA AND GLOBAL CONFIGURATION
# =============================================================================

readonly SCRIPT_NAME="${0:t}"
readonly SCRIPT_DIR="${0:A:h}"
readonly SCRIPT_VERSION="4.0"
readonly REQUIRED_MACOS_VERSION="14.0"

# Timing and logging
typeset -g SETUP_START_TIME=$(date +%s)
typeset -g LOG_FILE="/tmp/${SCRIPT_NAME%.zsh}-$(date +%Y%m%d-%H%M%S).log"
typeset -g BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"
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

# Mail, Calendar, and Contacts app configuration
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
    [[ $ENABLE_MAIL_CALENDAR == true ]] && info "  ✓ Mail, Calendar, Contacts"
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
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
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
    
    debug "Performing cleanup..."
    
    # Kill background processes
    for pid in $BACKGROUND_PIDS; do
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid" 2>/dev/null || true
        fi
    done
    
    # Kill sudo keep-alive if running
    jobs -p | xargs -r kill 2>/dev/null || true
    
    # Remove temporary files
    [[ -d $TEMP_DIR ]] && rm -rf "$TEMP_DIR"
    
    # Log completion
    local total_time=$(($(date +%s) - SETUP_START_TIME))
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
# ENHANCED POWER MANAGEMENT (FROM V3)
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
# COMPREHENSIVE SECURITY CONFIGURATION (FROM V3)
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
        sudo networksetup -setdnsservers "$primary_service" 1.1.1.1 8.8.8.8
        success "DNS servers configured"
    fi
    
    # Set timezone
    sudo systemsetup -settimezone "Australia/Adelaide"
    sudo systemsetup -setusingnetworktime on
    
    success "Network and system basics configured"
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
        
        sudo xcodebuild -license accept
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
# MAIL, CALENDAR AND CONTACTS CONFIGURATION
# =============================================================================

configure_mail_calendar_contacts() {
    info "Configuring Mail, Calendar, and Contacts..."
    
    if [[ $DRY_RUN == true ]]; then
        info "[DRY RUN] Would configure Mail, Calendar, and Contacts settings"
        return 0
    fi
    
    # Mail.app configurations
    configure_mail_settings
    
    # Calendar.app configurations  
    configure_calendar_settings
    
    # Contacts.app configurations
    configure_contacts_settings
    
    success "Mail, Calendar, and Contacts configuration completed"
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

configure_contacts_settings() {
    info "Configuring Contacts.app settings..."
    
    # Helper function to safely write defaults
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
    
    # Display preferences (attempt to set, but don't fail if restricted)
    safe_defaults_write com.apple.AddressBook ABNameDisplay -int 1
    safe_defaults_write com.apple.AddressBook ABNameSorting -int 1
    safe_defaults_write com.apple.AddressBook ABShortNameFormat -int 0
    
    # Address format (Australian)
    safe_defaults_write com.apple.AddressBook ABDefaultAddressCountryCode -string "au"
    safe_defaults_write com.apple.AddressBook ABAutomaticFormatting -bool true
    
    # Privacy settings
    safe_defaults_write com.apple.AddressBook ABShowDebugMenu -bool false
    safe_defaults_write com.apple.AddressBook ABBirthDayVisible -bool true
    
    # Sync and export
    safe_defaults_write com.apple.AddressBook ABGroupWindowShown -bool true
    safe_defaults_write com.apple.AddressBook ABMultiValueEditingEnabled -bool true
    
    # Integration settings
    safe_defaults_write com.apple.AddressBook ABMapIntegrationEnabled -bool true
    safe_defaults_write com.apple.AddressBook ABPhoneFormatting -bool true
    
    # CardDAV and account settings
    safe_defaults_write com.apple.AddressBook ABCardDAVSyncingEnabled -bool true
    safe_defaults_write com.apple.AddressBook ABCardDAVAccountsEnabled -bool true
    
    # Search and matching
    safe_defaults_write com.apple.AddressBook ABSearchIncludesNotes -bool true
    safe_defaults_write com.apple.AddressBook ABFuzzySearchEnabled -bool true
    
    success "Contacts.app settings configured (some settings may be restricted by macOS)"
}

# =============================================================================
# DOTFILES MANAGEMENT (FROM OPT4)
# =============================================================================

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
            debug "Backed up: $(basename $file)"
        fi
    done
    
    # Backup application config directories
    for app_name path in ${(kv)APP_CONFIG_PATHS}; do
        if [[ -d "$path" && ! -L "$path" ]]; then
            cp -r "$path" "$BACKUP_DIR/$(basename $path)-$app_name" 2>/dev/null || true
            debug "Backed up: $app_name config directory"
        fi
    done
    
    success "Configuration backup completed: $BACKUP_DIR"
}

clone_or_update_dotfiles() {
    info "Managing dotfiles repository..."
    
    # Use provided repo or prompt for one
    if [[ -z $DOTFILES_REPO ]]; then
        if [[ $INTERACTIVE == true ]]; then
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
        git pull origin main || git pull origin master || warn "Could not update dotfiles"
    else
        info "Cloning dotfiles repository..."
        git clone "$DOTFILES_REPO" "$DOTFILES_DIR" || {
            error "Failed to clone dotfiles repository"
            return 1
        }
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
    
    cd "$DOTFILES_DIR"
    
    # Show repository structure
    debug "Dotfiles repository structure:"
    find . -maxdepth 2 -type d | head -10 | while read dir; do
        debug "  $dir"
    done
    
    # Apply each stow package
    for package in $STOW_PACKAGES; do
        if [[ -d "$package" ]]; then
            info "Stowing package: $package"
            
            # Remove conflicting files first
            case $package in
                zsh)
                    [[ -f "$HOME/.zshrc" ]] && rm "$HOME/.zshrc"
                    [[ -f "$HOME/.zshenv" ]] && rm "$HOME/.zshenv"
                    [[ -f "$HOME/.zprofile" ]] && rm "$HOME/.zprofile"
                    ;;
                git)
                    [[ -f "$HOME/.gitconfig" ]] && rm "$HOME/.gitconfig"
                    ;;
                vim)
                    [[ -f "$HOME/.vimrc" ]] && rm "$HOME/.vimrc"
                    ;;
                tmux)
                    [[ -f "$HOME/.tmux.conf" ]] && rm "$HOME/.tmux.conf"
                    ;;
            esac
            
            # Apply stow package
            if stow -v "$package" 2>&1; then
                success "Applied: $package"
            else
                warn "Failed to apply: $package"
            fi
        else
            debug "Package directory not found: $package"
        fi
    done
    
    success "Dotfiles applied with stow"
}

verify_application_configs() {
    info "Verifying application configurations..."
    
    # Check that application config files were properly linked
    for app_name path in ${(kv)APP_CONFIG_PATHS}; do
        if [[ -e "$path" ]]; then
            if [[ -L "$path" ]]; then
                local target=$(readlink "$path")
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
    
    # Source the new configuration in current session
    if [[ -f "$HOME/.zshenv" ]]; then
        debug "Sourcing new zsh environment..."
        source "$HOME/.zshenv" 2>/dev/null || true
    fi
    
    success "Shell integration completed"
}

# =============================================================================
# COMMAND-LINE ARGUMENT PARSING
# =============================================================================

usage() {
    cat << EOF
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
    ENABLE_MAIL_CALENDAR       - Mail, Calendar, Contacts configuration
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
    cat << 'EOF'

╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║     Enhanced Apple Silicon macOS Setup Script v4.0              ║
║     Hybrid System Configuration + Dotfiles Management           ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝

EOF
}

print_architecture_summary() {
    cat << EOF

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
        sudo -v
        # Keep sudo alive in background
        while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
        BACKGROUND_PIDS+=($!)
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
        configure_comprehensive_security
    else
        info "Skipping security configuration (disabled)"
    fi
    
    if [[ $ENABLE_SHARING_SERVICES == true ]]; then
        configure_sharing_services
    else
        info "Skipping sharing services configuration (disabled)"
    fi
    
    if [[ $ENABLE_MAIL_CALENDAR == true ]]; then
        configure_mail_calendar_contacts
    else
        info "Skipping Mail, Calendar, and Contacts configuration (disabled)"
    fi
    
    # Phase 2: Dependencies and Tools
    if [[ $ENABLE_SYSTEM_DEPENDENCIES == true ]]; then
        install_system_dependencies
    else
        info "Skipping system dependencies installation (disabled)"
    fi
    
    # Phase 3: Dotfiles Management
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
        
        backup_existing_configs
        clone_or_update_dotfiles
        apply_dotfiles_with_stow
        verify_application_configs
        setup_shell_integration
    else
        info "Skipping dotfiles management (disabled)"
    fi
    
    # Final cleanup
    if [[ $DRY_RUN == false ]]; then
        sudo dscacheutil -flushcache
    fi
    
    # Success message
    cat << EOF

${GREEN}╔══════════════════════════════════════════════════════════════════╗
║                        SETUP COMPLETED!                         ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                  ║
║  ✅ System configuration applied for $MAC_TYPE
║  ✅ Enhanced power and security settings configured             ║
║  ✅ Mail, Calendar, and Contacts configured                     ║
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
            sudo shutdown -r now
        else
            info "Setup complete. Please restart when convenient."
        fi
    fi
}

# Execute main function if script is run directly
if [[ "${(%):-%x}" == "${0}" ]]; then
    main "$@"
fi
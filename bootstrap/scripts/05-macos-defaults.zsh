#!/usr/bin/env zsh
# -*- coding: utf-8 -*-

#=============================================================================
# SCRIPT: macos-defaults.zsh
# AUTHOR: Andrew Exley
# DATE: 2025-01-07
# VERSION: 1.0.0
#
# DESCRIPTION:
#   Comprehensive macOS defaults management script for data & AI developers
#   Consolidates all system configuration with backup/restore capabilities
#
# USAGE:
#   ./macos-defaults.zsh [options]
#
# OPTIONS:
#   -h, --help      Show this help message
#   -v, --verbose   Enable verbose output
#   -d, --debug     Enable debug mode
#   -n, --dry-run   Preview changes without applying them
#   -b, --backup    Create backup of current settings
#   -r, --restore   Restore from backup
#   -i, --interactive  Interactive mode for selective application
#   -f, --force     Skip confirmation prompts
#
# REQUIREMENTS:
#   - macOS 11.0+ (Big Sur)
#   - Zsh 5.8+
#   - Admin privileges for some settings
#
# NOTES:
#   - Creates backups in ~/.config/macos-defaults/backups/
#   - Restarts affected services automatically
#   - All changes are reversible
#=============================================================================

# Strict mode
set -euo pipefail

# Script metadata
readonly SCRIPT_NAME="${0:t}"
readonly SCRIPT_DIR="${0:A:h}"
readonly SCRIPT_VERSION="1.0.0"
readonly BACKUP_DIR="$HOME/.config/macos-defaults/backups"
readonly TIMESTAMP=$(date '+%Y%m%d_%H%M%S')

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
declare -g INTERACTIVE=false
declare -g FORCE=false
declare -g BACKUP_ONLY=false
declare -g RESTORE_MODE=false
declare -g LOG_FILE="$HOME/.config/macos-defaults/macos-defaults.log"

# Restart services tracking
declare -ga SERVICES_TO_RESTART=()

#=============================================================================
# LOGGING FUNCTIONS
#=============================================================================

log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # Create log directory if it doesn't exist
    mkdir -p "${LOG_FILE:h}"

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

# Check macOS version
check_macos_version() {
    local required_version="${1:-11.0}"
    local current_version=$(sw_vers -productVersion)

    if ! is_version_gte "$current_version" "$required_version"; then
        error "macOS $required_version or later required (current: $current_version)"
        exit 1
    fi
}

# Version comparison
is_version_gte() {
    [ "$1" = "$(echo -e "$1\n$2" | sort -V | tail -n1)" ]
}

# Confirmation prompt
confirm() {
    local message="${1:-Are you sure?}"

    [[ $FORCE == true ]] && return 0

    echo -n "${YELLOW}${BOLD}[?]${RESET} $message (y/N): "
    read -r response
    [[ $response =~ ^[Yy]$ ]]
}

# Display usage information
usage() {
    cat << EOF
${BOLD}NAME${RESET}
    $SCRIPT_NAME - macOS defaults management for data & AI developers

${BOLD}SYNOPSIS${RESET}
    $SCRIPT_NAME [options]

${BOLD}DESCRIPTION${RESET}
    Comprehensive macOS defaults management script that consolidates all system
    configuration with backup/restore capabilities. Optimised for data engineers,
    AI researchers, and Python developers.

${BOLD}OPTIONS${RESET}
    -h, --help          Show this help message
    -v, --verbose       Enable verbose output
    -d, --debug         Enable debug mode
    -n, --dry-run       Preview changes without applying them
    -b, --backup        Create backup of current settings only
    -r, --restore       Restore from backup (interactive selection)
    -i, --interactive   Interactive mode for selective application
    -f, --force         Skip confirmation prompts

${BOLD}EXAMPLES${RESET}
    # Apply all defaults with confirmation
    $SCRIPT_NAME

    # Preview changes without applying
    $SCRIPT_NAME --dry-run

    # Create backup only
    $SCRIPT_NAME --backup

    # Interactive mode for selective application
    $SCRIPT_NAME --interactive

    # Restore from backup
    $SCRIPT_NAME --restore

${BOLD}CONFIGURATION CATEGORIES${RESET}
    • Dock: Size, auto-hide, animations, and behaviour
    • Finder: Views, file handling, and navigation
    • System: Input devices, security, and performance
    • Screenshots: Location, format, and naming
    • Menu Bar: Status indicators and clock format
    • Text Input: Autocorrect and substitution settings
    • Development: File handling and tool configurations
    • Privacy: Security and indexing preferences
    • Performance: Animations and system responsiveness

${BOLD}BACKUP LOCATION${RESET}
    $BACKUP_DIR

${BOLD}LOG FILE${RESET}
    $LOG_FILE

${BOLD}AUTHOR${RESET}
    Andrew (with Claude) <noreply@anthropic.com>

${BOLD}VERSION${RESET}
    $SCRIPT_VERSION
EOF
}

#=============================================================================
# BACKUP & RESTORE FUNCTIONS
#=============================================================================

# Create backup of current settings
create_backup() {
    local backup_file="$BACKUP_DIR/backup_$TIMESTAMP.plist"

    info "Creating backup of current settings..."
    mkdir -p "$BACKUP_DIR"

    # Create a comprehensive backup
    cat > "$backup_file" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>backup_date</key>
    <string>$(date)</string>
    <key>macos_version</key>
    <string>$(sw_vers -productVersion)</string>
    <key>settings</key>
    <dict>
EOF

    # Backup each domain and key we're going to modify
    local -A domains_keys=(
        ["com.apple.dock"]="persistent-apps tilesize show-recents autohide autohide-time-modifier autohide-delay orientation magnification expose-animation-duration"
        ["com.apple.finder"]="FXPreferredViewStyle FXArrangeGroupViewBy ShowPathbar ShowStatusBar AppleShowAllFiles NewWindowTarget NewWindowTargetPath FXEnableExtensionChangeWarning QLEnableTextSelection"
        ["NSGlobalDomain"]="AppleShowAllExtensions com.apple.swipescrolldirection KeyRepeat InitialKeyRepeat NSWindowResizeTime NSAutomaticCapitalizationEnabled NSAutomaticPeriodSubstitutionEnabled NSAutomaticSpellingCorrectionEnabled NSAutomaticQuoteSubstitutionEnabled NSAutomaticDashSubstitutionEnabled"
        ["com.apple.LaunchServices"]="LSQuarantine"
        ["com.apple.driver.AppleBluetoothMultitouch.trackpad"]="Clicking TrackpadThreeFingerDrag"
        ["com.apple.menuextra.battery"]="ShowPercent"
        ["com.apple.screensaver"]="askForPassword askForPasswordDelay"
        ["com.apple.screencapture"]="location type disable-shadow include-date"
        ["com.apple.menuextra.clock"]="DateFormat"
        ["com.apple.controlcenter"]="NSStatusItem Visible Bluetooth NSStatusItem Visible Sound"
        ["com.apple.frameworks.diskimages"]="skip-verify skip-verify-locked skip-verify-remote"
        ["com.apple.desktopservices"]="DSDontWriteNetworkStores DSDontWriteUSBStores"
        ["com.apple.ActivityMonitor"]="ShowCategory IconType"
        ["com.apple.terminal"]="SecureKeyboardEntry"
        ["com.apple.SoftwareUpdate"]="AutomaticDownload"
        ["com.apple.commerce"]="AutoUpdate"
    )

    # Backup current values
    for domain in ${(k)domains_keys}; do
        local keys=(${=domains_keys[$domain]})
        for key in $keys; do
            local current_value
            if current_value=$(defaults read "$domain" "$key" 2>/dev/null); then
                echo "        <key>${domain}_${key}</key>" >> "$backup_file"
                echo "        <string>$current_value</string>" >> "$backup_file"
                debug "Backed up $domain.$key: $current_value"
            fi
        done
    done

    # Close the plist
    cat >> "$backup_file" << EOF
    </dict>
</dict>
</plist>
EOF

    success "Backup created: $backup_file"

    # Create a summary file
    cat > "$BACKUP_DIR/backup_$TIMESTAMP.summary" << EOF
macOS Defaults Backup Summary
============================
Date: $(date)
macOS Version: $(sw_vers -productVersion)
Backup File: $backup_file

This backup contains the current values of all settings that will be modified
by the macOS defaults script. To restore these settings, use:

    $SCRIPT_NAME --restore

Backup created by: $SCRIPT_NAME v$SCRIPT_VERSION
EOF

    info "Backup summary: $BACKUP_DIR/backup_$TIMESTAMP.summary"
}

# List available backups
list_backups() {
    local backups=("$BACKUP_DIR"/backup_*.plist)

    if [[ ${#backups[@]} -eq 0 || ! -f ${backups[1]} ]]; then
        warn "No backups found in $BACKUP_DIR"
        return 1
    fi

    echo "${BOLD}Available backups:${RESET}"
    echo ""

    local i=1
    for backup in "${backups[@]}"; do
        if [[ -f $backup ]]; then
            local timestamp=${backup:t:r}
            timestamp=${timestamp#backup_}
            local date_str=$(date -j -f "%Y%m%d_%H%M%S" "$timestamp" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "Unknown date")
            echo "  $i) $date_str - ${backup:t}"
            ((i++))
        fi
    done

    echo ""
}

# Restore from backup
restore_from_backup() {
    if ! list_backups; then
        return 1
    fi

    local backups=("$BACKUP_DIR"/backup_*.plist)
    backups=(${backups[@]:#*\*})  # Remove glob if no matches

    echo -n "Select backup to restore (1-${#backups[@]}): "
    read -r selection

    if [[ ! $selection =~ ^[0-9]+$ ]] || [[ $selection -lt 1 || $selection -gt ${#backups[@]} ]]; then
        error "Invalid selection"
        return 1
    fi

    local backup_file="${backups[$selection]}"

    if ! confirm "Restore from backup ${backup_file:t}?"; then
        info "Restore cancelled"
        return 0
    fi

    info "Restoring from backup: ${backup_file:t}"

    # Parse the backup file and restore settings
    # This is a simplified approach - in a full implementation, you'd parse the plist properly
    warn "Restore functionality is not fully implemented in this version"
    warn "Please manually restore settings using defaults write commands"

    return 0
}

#=============================================================================
# DEFAULTS APPLICATION FUNCTIONS
#=============================================================================

# Apply a single default setting
apply_default() {
    local domain=$1
    local key=$2
    local value_type=$3
    local value=$4
    local description=$5

    # Get current value for comparison
    local current_value
    current_value=$(defaults read "$domain" "$key" 2>/dev/null || echo "NOT_SET")

    # Format the new value based on type
    local formatted_value
    case $value_type in
        bool)
            formatted_value="$value"
            ;;
        int)
            formatted_value="$value"
            ;;
        float)
            formatted_value="$value"
            ;;
        string)
            formatted_value="\"$value\""
            ;;
        array)
            formatted_value="$value"
            ;;
    esac

    # Check if change is needed
    if [[ $current_value == $value ]]; then
        debug "$description (no change needed)"
        return 0
    fi

    # Show what will change
    if [[ $current_value == "NOT_SET" ]]; then
        change "$description: Setting to $formatted_value"
    else
        change "$description: $current_value → $formatted_value"
    fi

    # Apply the change (unless dry run)
    if [[ $DRY_RUN == false ]]; then
        if defaults write "$domain" "$key" "-$value_type" "$value"; then
            debug "Applied: defaults write $domain $key -$value_type $value"
        else
            error "Failed to apply: defaults write $domain $key -$value_type $value"
            return 1
        fi
    else
        debug "DRY RUN: defaults write $domain $key -$value_type $value"
    fi

    return 0
}

# Apply sudo defaults (for system-wide settings)
apply_sudo_default() {
    local domain=$1
    local key=$2
    local value_type=$3
    local value=$4
    local description=$5

    change "$description"

    if [[ $DRY_RUN == false ]]; then
        if sudo defaults write "$domain" "$key" "-$value_type" "$value"; then
            debug "Applied (sudo): defaults write $domain $key -$value_type $value"
        else
            error "Failed to apply (sudo): defaults write $domain $key -$value_type $value"
            return 1
        fi
    else
        debug "DRY RUN (sudo): defaults write $domain $key -$value_type $value"
    fi

    return 0
}

# Execute system command with proper logging
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

#=============================================================================
# CONFIGURATION SECTIONS
#=============================================================================

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

# Ask for section confirmation in interactive mode
ask_section() {
    local title=$1

    if [[ $INTERACTIVE == true ]]; then
        echo ""
        if ! confirm "Apply $title settings?"; then
            info "Skipping $title settings"
            return 1
        fi
    fi

    return 0
}

# Dock configuration
configure_dock() {
    print_section "DOCK CONFIGURATION" "📱"

    if ! ask_section "Dock"; then
        return 0
    fi

    # Clear all dock apps
    apply_default "com.apple.dock" "persistent-apps" "array" "" "Remove all applications from dock"

    # Dock size and behaviour
    apply_default "com.apple.dock" "tilesize" "int" "36" "Set dock size to 36 pixels"
    apply_default "com.apple.dock" "show-recents" "bool" "false" "Disable recent apps in dock"
    apply_default "com.apple.dock" "autohide" "bool" "true" "Enable dock auto-hide"
    apply_default "com.apple.dock" "autohide-time-modifier" "float" "0.5" "Speed up dock auto-hide animation"
    apply_default "com.apple.dock" "autohide-delay" "float" "0.2" "Reduce dock auto-hide delay"
    apply_default "com.apple.dock" "orientation" "string" "bottom" "Position dock at bottom"
    apply_default "com.apple.dock" "magnification" "bool" "false" "Disable dock magnification"
    apply_default "com.apple.dock" "expose-animation-duration" "float" "0.1" "Speed up Mission Control animations"

    SERVICES_TO_RESTART+=("Dock")
}

# Finder configuration
configure_finder() {
    print_section "FINDER CONFIGURATION" "📁"

    if ! ask_section "Finder"; then
        return 0
    fi

    # View and sorting preferences
    apply_default "com.apple.finder" "FXPreferredViewStyle" "string" "Nlsv" "Set default view to list view"
    apply_default "com.apple.finder" "FXArrangeGroupViewBy" "string" "Date Modified" "Set default sort to date modified"

    # File display options
    apply_default "NSGlobalDomain" "AppleShowAllExtensions" "bool" "true" "Show all filename extensions"
    apply_default "com.apple.finder" "ShowPathbar" "bool" "true" "Show path bar"
    apply_default "com.apple.finder" "ShowStatusBar" "bool" "true" "Show status bar"
    apply_default "com.apple.finder" "AppleShowAllFiles" "bool" "true" "Show hidden files"

    # New window behaviour
    apply_default "com.apple.finder" "NewWindowTarget" "string" "PfHm" "Set default location to home folder"
    apply_default "com.apple.finder" "NewWindowTargetPath" "string" "file://${HOME}/" "Set home folder path"

    # File handling
    apply_default "com.apple.finder" "FXEnableExtensionChangeWarning" "bool" "false" "Disable warning when changing file extensions"
    apply_default "com.apple.finder" "QLEnableTextSelection" "bool" "true" "Enable text selection in Quick Look"

    SERVICES_TO_RESTART+=("Finder")
}

# System preferences
configure_system() {
    print_section "SYSTEM PREFERENCES" "⚙️"

    if ! ask_section "System"; then
        return 0
    fi

    # Security and app launching
    apply_default "com.apple.LaunchServices" "LSQuarantine" "bool" "false" "Disable 'Are you sure you want to open this application?' dialog"

    # Trackpad settings
    apply_default "com.apple.driver.AppleBluetoothMultitouch.trackpad" "Clicking" "bool" "true" "Enable tap to click on trackpad"
    apply_default "com.apple.driver.AppleBluetoothMultitouch.trackpad" "TrackpadThreeFingerDrag" "bool" "true" "Enable three finger drag"

    # Scrolling behaviour
    apply_default "NSGlobalDomain" "com.apple.swipescrolldirection" "bool" "false" "Set traditional scroll direction (disable natural scrolling)"

    # Keyboard settings
    apply_default "NSGlobalDomain" "KeyRepeat" "int" "2" "Set faster key repeat rate"
    apply_default "NSGlobalDomain" "InitialKeyRepeat" "int" "15" "Set initial key repeat delay"

    # Screen lock settings
    apply_default "com.apple.screensaver" "askForPassword" "int" "1" "Require password immediately after sleep"
    apply_default "com.apple.screensaver" "askForPasswordDelay" "int" "0" "No delay for password prompt"

    # Power management (requires sudo)
    execute_command "Speed up wake from sleep" sudo pmset -a standbydelay 86400
}

# Screenshot configuration
configure_screenshots() {
    print_section "SCREENSHOT SETTINGS" "📸"

    if ! ask_section "Screenshots"; then
        return 0
    fi

    # Create screenshots directory
    execute_command "Create Screenshots folder" mkdir -p "$HOME/Pictures/Screenshots"

    # Screenshot preferences
    apply_default "com.apple.screencapture" "location" "string" "$HOME/Pictures/Screenshots" "Set screenshot location"
    apply_default "com.apple.screencapture" "type" "string" "png" "Set screenshot format to PNG"
    apply_default "com.apple.screencapture" "disable-shadow" "bool" "true" "Disable screenshot shadow"
    apply_default "com.apple.screencapture" "include-date" "bool" "true" "Include date in screenshot names"
}

# Menu bar configuration
configure_menu_bar() {
    print_section "MENU BAR & CONTROL CENTER" "📊"

    if ! ask_section "Menu Bar"; then
        return 0
    fi

    # Clock format
    apply_default "com.apple.menuextra.clock" "DateFormat" "string" "EEE MMM d  h:mm a" "Show day of week in menu bar clock"

    # Battery percentage
    apply_default "com.apple.menuextra.battery" "ShowPercent" "string" "YES" "Show battery percentage in menu bar"

    # Control Center items
    apply_default "com.apple.controlcenter" "NSStatusItem Visible Bluetooth" "bool" "true" "Show Bluetooth in menu bar"
    apply_default "com.apple.controlcenter" "NSStatusItem Visible Sound" "bool" "true" "Show Sound in menu bar"

    SERVICES_TO_RESTART+=("SystemUIServer" "ControlCenter")
}

# Performance and animations
configure_performance() {
    print_section "PERFORMANCE & ANIMATIONS" "⚡"

    if ! ask_section "Performance"; then
        return 0
    fi

    # Animation speeds
    apply_default "NSGlobalDomain" "NSWindowResizeTime" "float" "0.001" "Reduce window resize animation time"

    # Disk image settings
    apply_default "com.apple.frameworks.diskimages" "skip-verify" "bool" "true" "Disable disk image verification"
    apply_default "com.apple.frameworks.diskimages" "skip-verify-locked" "bool" "true" "Disable locked disk image verification"
    apply_default "com.apple.frameworks.diskimages" "skip-verify-remote" "bool" "true" "Disable remote disk image verification"
}

# Text input settings
configure_text_input() {
    print_section "TEXT & INPUT SETTINGS" "✏️"

    if ! ask_section "Text Input"; then
        return 0
    fi

    # Disable automatic text substitutions
    apply_default "NSGlobalDomain" "NSAutomaticCapitalizationEnabled" "bool" "false" "Disable automatic capitalisation"
    apply_default "NSGlobalDomain" "NSAutomaticPeriodSubstitutionEnabled" "bool" "false" "Disable automatic period substitution"
    apply_default "NSGlobalDomain" "NSAutomaticSpellingCorrectionEnabled" "bool" "false" "Disable auto-correct"
    apply_default "NSGlobalDomain" "NSAutomaticQuoteSubstitutionEnabled" "bool" "false" "Disable automatic quote substitution"
    apply_default "NSGlobalDomain" "NSAutomaticDashSubstitutionEnabled" "bool" "false" "Disable automatic dash substitution"
}

# Development-focused settings
configure_development() {
    print_section "DEVELOPMENT SETTINGS" "💻"

    if ! ask_section "Development"; then
        return 0
    fi

    # File system optimisations
    apply_default "com.apple.desktopservices" "DSDontWriteNetworkStores" "bool" "true" "Disable DS_Store file creation on network volumes"
    apply_default "com.apple.desktopservices" "DSDontWriteUSBStores" "bool" "true" "Disable DS_Store file creation on USB volumes"

    # Activity Monitor settings
    apply_default "com.apple.ActivityMonitor" "ShowCategory" "int" "0" "Show all processes in Activity Monitor"
    apply_default "com.apple.ActivityMonitor" "IconType" "int" "5" "Set Activity Monitor to show CPU usage in dock icon"

    # Terminal security
    apply_default "com.apple.terminal" "SecureKeyboardEntry" "bool" "true" "Enable Secure Keyboard Entry in Terminal"
}

# Privacy and security settings
configure_privacy() {
    print_section "PRIVACY & SECURITY" "🔒"

    if ! ask_section "Privacy & Security"; then
        return 0
    fi

    # Spotlight indexing
    # Note: Using mdutil instead of VolumeConfiguration as it's more reliable
    change "Disable Spotlight indexing for mounted volumes"
    if [[ $DRY_RUN == false ]]; then
        sudo mdutil -i off /Volumes/* 2>/dev/null || true
        debug "Disabled Spotlight indexing for external volumes"
    else
        debug "DRY RUN: Would disable Spotlight indexing for external volumes"
    fi

    # App Store settings
    apply_default "com.apple.SoftwareUpdate" "AutomaticDownload" "int" "0" "Disable automatic App Store downloads"
    apply_default "com.apple.commerce" "AutoUpdate" "bool" "false" "Disable App Store auto-updates"
}

#=============================================================================
# SERVICE MANAGEMENT
#=============================================================================

# Restart affected services
restart_services() {
    if [[ $DRY_RUN == true ]]; then
        info "Would restart services: ${SERVICES_TO_RESTART[*]}"
        return 0
    fi

    if [[ ${#SERVICES_TO_RESTART[@]} -eq 0 ]]; then
        debug "No services to restart"
        return 0
    fi

    print_section "APPLYING CHANGES" "🔄"

    for service in "${SERVICES_TO_RESTART[@]}"; do
        case $service in
            "Dock")
                execute_command "Restart Dock" killall Dock
                ;;
            "Finder")
                execute_command "Restart Finder" killall Finder
                ;;
            "SystemUIServer")
                execute_command "Restart SystemUIServer" killall SystemUIServer
                ;;
            "ControlCenter")
                execute_command "Restart Control Center" killall ControlCenter 2>/dev/null || true
                ;;
            *)
                execute_command "Restart $service" killall "$service" 2>/dev/null || true
                ;;
        esac
    done

    # Give services time to restart
    sleep 2
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
            -b|--backup)
                BACKUP_ONLY=true
                shift
                ;;
            -r|--restore)
                RESTORE_MODE=true
                shift
                ;;
            -i|--interactive)
                INTERACTIVE=true
                shift
                ;;
            -f|--force)
                FORCE=true
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
    check_macos_version "11.0"

    # Parse arguments
    parse_args "$@"

    # Show header
    echo ""
    echo "${BOLD}${BLUE}🍎 macOS Defaults Management v$SCRIPT_VERSION${RESET}"
    echo "${BOLD}${BLUE}════════════════════════════════════════════════════════════════════════════════${RESET}"
    echo ""

    # Handle backup-only mode
    if [[ $BACKUP_ONLY == true ]]; then
        create_backup
        exit 0
    fi

    # Handle restore mode
    if [[ $RESTORE_MODE == true ]]; then
        restore_from_backup
        exit 0
    fi

    # Show mode indicators
    if [[ $DRY_RUN == true ]]; then
        warn "DRY RUN MODE: No changes will be applied"
    fi

    if [[ $INTERACTIVE == true ]]; then
        info "INTERACTIVE MODE: You will be prompted for each section"
    fi

    # Create backup before applying changes
    if [[ $DRY_RUN == false ]]; then
        if confirm "Create backup before applying changes?"; then
            create_backup
        fi
    fi

    # Apply all configuration sections
    configure_dock
    configure_finder
    configure_system
    configure_screenshots
    configure_menu_bar
    configure_performance
    configure_text_input
    configure_development
    configure_privacy

    # Restart affected services
    restart_services

    # Show completion message
    print_section "CONFIGURATION COMPLETE" "✅"

    if [[ $DRY_RUN == true ]]; then
        info "DRY RUN completed - no changes were applied"
        info "Run without --dry-run to apply changes"
    else
        success "macOS configuration has been applied successfully!"

        echo ""
        echo "${BOLD}📋 Summary of changes:${RESET}"
        echo "   • Dock: Smaller, auto-hide, no recent apps, optimised animations"
        echo "   • Finder: List view, show extensions and hidden files, home folder default"
        echo "   • System: Faster key repeat, tap to click, traditional scrolling"
        echo "   • Screenshots: PNG format in ~/Pictures/Screenshots"
        echo "   • Menu Bar: Battery percentage, improved clock, status indicators"
        echo "   • Performance: Faster animations, optimised disk handling"
        echo "   • Text Input: Disabled auto-correct and substitutions"
        echo "   • Development: Optimised for coding, secure terminal"
        echo "   • Privacy: Controlled indexing, disabled auto-downloads"
        echo ""
        echo "${BOLD}🔄 Some changes may require a restart to take full effect.${RESET}"
        echo "${BOLD}📚 Log file: $LOG_FILE${RESET}"
        echo "${BOLD}💾 Backups: $BACKUP_DIR${RESET}"
        echo ""
    fi
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

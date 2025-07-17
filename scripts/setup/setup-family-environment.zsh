#!/usr/bin/env zsh

# Script metadata
readonly SCRIPT_NAME="${0:t}"
readonly SCRIPT_DIR="${0:A:h}"

# Load common library
source "${SCRIPT_DIR}/../lib/common.zsh"

# Configuration
readonly DEVICE_TYPE="${1:-$(detect_device_type)}"
readonly SHARED_BASE="/Users/Shared/Family"
readonly TIME_MACHINE_BASE="/Users/Shared/TimeMachine"

# Family member definitions
readonly FAMILY_USERS=(
    "ali:Ali Exley:standard"
    "amelia:Amelia Exley:standard" 
    "annabelle:Annabelle Exley:standard"
)

# Check if user exists
user_exists() {
    id "$1" &>/dev/null
}

# Ensure family users exist
ensure_family_users() {
    info "Checking family users..."
    
    local missing_users=()
    for user_spec in "${FAMILY_USERS[@]}"; do
        local username="${user_spec%%:*}"
        if user_exists "$username"; then
            success "✓ User $username exists"
        else
            missing_users+=("$username")
        fi
    done
    
    if [[ ${#missing_users[@]} -gt 0 ]]; then
        error "Missing users: ${missing_users[*]}"
        info "Run setup-users.zsh first to create family user accounts"
        return 1
    fi
    
    success "All family users exist"
}

# Setup shared directories
setup_shared_directories() {
    info "Setting up shared directories..."
    
    local shared_dirs=(
        "$SHARED_BASE"
        "$SHARED_BASE/Documents"
        "$SHARED_BASE/Media/Photos"
        "$SHARED_BASE/Media/Videos"
        "$SHARED_BASE/Media/Music"
        "$SHARED_BASE/Software"
        "$SHARED_BASE/Templates"
        "$SHARED_BASE/Projects"
        "$SHARED_BASE/Resources"
        "$SHARED_BASE/Backups"
    )
    
    create_directories "${shared_dirs[@]}" || return 1
    
    # Set proper permissions for shared directories
    for dir in "${shared_dirs[@]}"; do
        sudo chown root:staff "$dir"
        sudo chmod 755 "$dir"
    done
    
    success "Shared directories configured"
}

# Configure Time Machine for family
setup_time_machine() {
    info "Setting up Time Machine for family..."
    
    # Only configure on Mac Studio (central backup server)
    if [[ "$DEVICE_TYPE" != "mac-studio" ]]; then
        info "Time Machine backup server only configured on Mac Studio"
        return 0
    fi
    
    local tm_dirs=(
        "$TIME_MACHINE_BASE"
        "$TIME_MACHINE_BASE/andrew"
        "$TIME_MACHINE_BASE/ali"
        "$TIME_MACHINE_BASE/amelia"
        "$TIME_MACHINE_BASE/annabelle"
    )
    
    create_directories "${tm_dirs[@]}" || return 1
    
    # Set Time Machine permissions
    for dir in "${tm_dirs[@]}"; do
        sudo chown root:staff "$dir"
        sudo chmod 755 "$dir"
    done
    
    success "Time Machine directories configured"
}

# Configure family-specific system defaults
configure_family_defaults() {
    info "Configuring family-specific system defaults..."
    
    # Configure Dock for family use
    defaults write com.apple.dock persistent-apps -array
    defaults write com.apple.dock tilesize -int 48
    defaults write com.apple.dock show-recents -bool false
    
    # Configure Finder for family use
    defaults write com.apple.finder ShowPathbar -bool true
    defaults write com.apple.finder ShowStatusBar -bool true
    defaults write com.apple.finder FXPreferredViewStyle -string "clmv"
    
    # Configure Screenshots
    defaults write com.apple.screencapture location -string "$SHARED_BASE/Media/Screenshots"
    
    # Configure Guest User (disable for security)
    sudo defaults write /Library/Preferences/com.apple.AppleFileServer guestAccess -bool false
    
    success "Family-specific system defaults configured"
}

# Configure user access permissions
configure_user_permissions() {
    info "Configuring user access permissions..."
    
    # Add family users to staff group for shared access
    for user_spec in "${FAMILY_USERS[@]}"; do
        local username="${user_spec%%:*}"
        if user_exists "$username"; then
            sudo dseditgroup -o edit -a "$username" -t user staff
            success "✓ Added $username to staff group"
        fi
    done
    
    # Configure shared folder permissions
    if [[ -d "$SHARED_BASE" ]]; then
        sudo chmod -R g+w "$SHARED_BASE"
        success "✓ Shared folders configured for group write access"
    fi
}

# Help function
usage() {
    cat << EOF
$SCRIPT_NAME - Setup Family Environment

USAGE:
    $SCRIPT_NAME [OPTIONS] [DEVICE_TYPE]

DESCRIPTION:
    Sets up a comprehensive family environment with shared directories,
    user permissions, and device-specific configurations.

OPTIONS:
    -h, --help           Show this help message

DEVICE_TYPE:
    Auto-detected if not specified. Valid types:
    macbook-pro, mac-studio, mac-mini

EXAMPLES:
    $SCRIPT_NAME                    # Auto-detect device type
    $SCRIPT_NAME mac-studio         # Configure for Mac Studio

EOF
}

# Main execution
main() {
    local device_type="${1:-$(detect_device_type)}"
    
    header "Family Environment Setup for $device_type"
    
    # Check prerequisites
    check_macos
    
    # Ensure family users exist
    ensure_family_users || return 1
    
    # Setup shared directories
    setup_shared_directories || return 1
    
    # Setup Time Machine (Mac Studio only)
    setup_time_machine || return 1
    
    # Configure family-specific defaults
    configure_family_defaults
    
    # Configure user permissions
    configure_user_permissions
    
    # Restart affected services
    killall Dock Finder SystemUIServer &>/dev/null || true
    
    success "Family environment setup completed successfully!"
    info "Shared directories available at: $SHARED_BASE"
    [[ "$device_type" == "mac-studio" ]] && info "Time Machine backup server configured"
    
    return 0
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            exit 0
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

# Run main function
main "$DEVICE_TYPE"
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

# Family member definitions
readonly FAMILY_USERS=(
    "ali:Ali Exley:standard"
    "amelia:Amelia Exley:standard" 
    "annabelle:Annabelle Exley:standard"
)

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

# Check if user already exists
user_exists() {
    local username="$1"
    if id "$username" &>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Get next available UID
get_next_uid() {
    local max_uid=500
    local existing_uids
    existing_uids=$(dscl . -list /Users UniqueID | awk '{print $2}' | sort -n)
    
    for uid in $existing_uids; do
        if [[ $uid -ge $max_uid ]]; then
            max_uid=$((uid + 1))
        fi
    done
    
    echo $max_uid
}

# Create user account
create_user() {
    local username="$1"
    local full_name="$2"
    local account_type="$3"
    
    if user_exists "$username"; then
        success "✓ User $username already exists"
        return 0
    fi
    
    info "Creating user: $username ($full_name)"
    
    # Get next available UID
    local uid
    uid=$(get_next_uid)
    
    # Create user account
    if sudo dscl . -create "/Users/$username"; then
        success "✓ User record created for $username"
    else
        error "Failed to create user record for $username"
        return 1
    fi
    
    # Set user properties
    sudo dscl . -create "/Users/$username" UserShell /bin/zsh
    sudo dscl . -create "/Users/$username" RealName "$full_name"
    sudo dscl . -create "/Users/$username" UniqueID "$uid"
    sudo dscl . -create "/Users/$username" PrimaryGroupID 20  # staff group
    sudo dscl . -create "/Users/$username" NFSHomeDirectory "/Users/$username"
    
    # Set account type
    if [[ "$account_type" == "admin" ]]; then
        sudo dscl . -append /Groups/admin GroupMembership "$username"
        info "✓ Added $username to admin group"
    fi
    
    # Create home directory
    if sudo createhomedir -c -u "$username" &>/dev/null; then
        success "✓ Home directory created for $username"
    else
        warn "Could not create home directory for $username"
    fi
    
    # Set up basic shell configuration
    setup_user_shell "$username"
    
    success "✓ User $username created successfully"
    return 0
}

# Set up basic shell configuration for user
setup_user_shell() {
    local username="$1"
    local user_home="/Users/$username"
    
    if [[ ! -d "$user_home" ]]; then
        warn "Home directory does not exist for $username"
        return 1
    fi
    
    # Create basic .zshrc if it doesn't exist
    local zshrc="$user_home/.zshrc"
    if [[ ! -f "$zshrc" ]]; then
        sudo -u "$username" tee "$zshrc" > /dev/null << 'EOF'
# Basic zsh configuration for macOS Setup Automation

# Set PATH to include Homebrew
if [[ -d "/opt/homebrew/bin" ]]; then
    export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
elif [[ -d "/usr/local/bin" ]]; then
    export PATH="/usr/local/bin:/usr/local/sbin:$PATH"
fi

# Basic aliases
alias ll='ls -la'
alias la='ls -A'
alias l='ls -CF'

# Set Australian locale
export LANG=en_AU.UTF-8
export LC_ALL=en_AU.UTF-8

# Enable colour support
export CLICOLOR=1
export LSCOLORS=ExFxBxDxCxegedabagacad

# History settings
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY
setopt HIST_VERIFY
setopt HIST_IGNORE_ALL_DUPS

# Basic prompt
PS1='%n@%m:%~$ '
EOF
        
        sudo chown "$username:staff" "$zshrc"
        success "✓ Created basic .zshrc for $username"
    fi
    
    # Create basic .zprofile for PATH
    local zprofile="$user_home/.zprofile" 
    if [[ ! -f "$zprofile" ]]; then
        sudo -u "$username" tee "$zprofile" > /dev/null << 'EOF'
# Homebrew PATH configuration
if [[ -d "/opt/homebrew/bin" ]]; then
    export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
elif [[ -d "/usr/local/bin" ]]; then
    export PATH="/usr/local/bin:/usr/local/sbin:$PATH"
fi
EOF
        
        sudo chown "$username:staff" "$zprofile"
        success "✓ Created .zprofile for $username"
    fi
}

# Set basic user-specific preferences (minimal configuration)
configure_basic_user_preferences() {
    local username="$1"
    
    info "Configuring basic preferences for user: $username"
    
    # Only set essential Australian locale settings
    sudo -u "$username" defaults write NSGlobalDomain "AppleLanguages" "(en-AU)"
    sudo -u "$username" defaults write NSGlobalDomain "AppleLocale" "en_AU@currency=AUD"
    sudo -u "$username" defaults write NSGlobalDomain "AppleMeasurementUnits" "Centimeters"
    sudo -u "$username" defaults write NSGlobalDomain "AppleMetricUnits" -bool true
    
    success "✓ Basic preferences configured for $username"
}

# Main user setup process
setup_family_users() {
    info "Setting up family user accounts..."
    
    local created_users=0
    
    for user_spec in "${FAMILY_USERS[@]}"; do
        IFS=':' read -r username full_name account_type <<< "$user_spec"
        
        info "Processing user: $username"
        
        if create_user "$username" "$full_name" "$account_type"; then
            configure_basic_user_preferences "$username"
            ((created_users++))
        else
            error "Failed to create user: $username"
        fi
        
        echo
    done
    
    if [[ $created_users -gt 0 ]]; then
        success "Created $created_users new user accounts"
    else
        info "No new user accounts were created"
    fi
    
    return 0
}

# Help function
usage() {
    cat << EOF
$SCRIPT_NAME - Multi-User Family Environment Setup

USAGE:
    $SCRIPT_NAME [DEVICE_TYPE]

DESCRIPTION:
    Creates family user accounts with basic configuration. This script
    focuses solely on user account creation and basic shell setup.

DEVICE_TYPE:
    macbook-pro    Portable development workstation
    mac-studio     Headless server infrastructure  
    mac-mini       Lightweight development + multimedia
    
    Default: macbook-pro

FAMILY USERS:
    • Ali Exley (ali) - Standard user
    • Amelia Exley (amelia) - Standard user
    • Annabelle Exley (annabelle) - Standard user

CONFIGURATION:
    • Creates user accounts with Australian English locale
    • Sets up basic shell configuration (zsh)
    • Configures basic user preferences

EXAMPLES:
    $SCRIPT_NAME                    # Setup for MacBook Pro
    $SCRIPT_NAME mac-studio         # Setup for Mac Studio
    
NOTES:
    • Requires administrator privileges
    • Users are created as standard (non-admin) accounts
    • Only handles core user creation - no shared directories
    • Run setup-family-environment.zsh for family features

EOF
}

# Main execution
main() {
    info "Multi-User Family Environment Setup"
    info "=================================="
    info "Device type: $DEVICE_TYPE"
    info "Family users: ${#FAMILY_USERS[@]} accounts"
    echo
    
    # Check if running as admin
    if [[ $EUID -ne 0 ]]; then
        info "This script requires administrator privileges for user creation"
        info "You may be prompted for your password"
        echo
    fi
    
    # Set up family user accounts
    setup_family_users
    echo
    
    success "=========================================="
    success "User account setup completed successfully!"
    success "=========================================="
    info "Family users configured for: $DEVICE_TYPE"
    info "Note: Run setup-family-environment.zsh to configure shared directories and family features"
    
    return 0
}

# Parse command line arguments
case "${1:-}" in
    -h|--help)
        usage
        exit 0
        ;;
    macbook-pro|mac-studio|mac-mini)
        DEVICE_TYPE="$1"
        ;;
    "")
        # Use default
        ;;
    *)
        error "Invalid device type: $1"
        usage
        exit 1
        ;;
esac

# Run main function
main
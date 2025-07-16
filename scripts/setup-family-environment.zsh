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

# Family environment paths
readonly SHARED_BASE="/Users/Shared/Family"
readonly TIME_MACHINE_BASE="/Users/Shared/TimeMachine"

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

# Create comprehensive shared directory structure
setup_shared_directories() {
    info "Setting up comprehensive shared directory structure..."
    
    # Main shared directories
    local shared_dirs=(
        "$SHARED_BASE"
        "$SHARED_BASE/Documents"
        "$SHARED_BASE/Media"
        "$SHARED_BASE/Media/Photos"
        "$SHARED_BASE/Media/Videos"
        "$SHARED_BASE/Media/Music"
        "$SHARED_BASE/Software"
        "$SHARED_BASE/Templates"
        "$SHARED_BASE/Projects"
        "$SHARED_BASE/Resources"
        "$SHARED_BASE/Backups"
    )
    
    for dir in "${shared_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            sudo mkdir -p "$dir"
            sudo chown root:staff "$dir"
            sudo chmod 775 "$dir"
            success "✓ Created shared directory: $dir"
        else
            success "✓ Shared directory exists: $dir"
        fi
    done
    
    # Create device-specific directories
    case "$DEVICE_TYPE" in
        "mac-studio")
            # Server-specific shared directories
            local server_dirs=(
                "$SHARED_BASE/Server"
                "$SHARED_BASE/Server/Logs"
                "$SHARED_BASE/Server/Config"
                "$SHARED_BASE/Server/Scripts"
                "$TIME_MACHINE_BASE"
                "$TIME_MACHINE_BASE/MacBook-Pro"
                "$TIME_MACHINE_BASE/Mac-Mini"
            )
            
            for dir in "${server_dirs[@]}"; do
                if [[ ! -d "$dir" ]]; then
                    sudo mkdir -p "$dir"
                    sudo chown root:staff "$dir"
                    sudo chmod 775 "$dir"
                    success "✓ Created server directory: $dir"
                fi
            done
            ;;
    esac
    
    # Set up proper ACLs for family access
    setup_directory_permissions
}

# Configure advanced directory permissions and ACLs
setup_directory_permissions() {
    info "Configuring directory permissions and ACLs..."
    
    # Set up inheritance for shared directories
    if [[ -d "$SHARED_BASE" ]]; then
        # Allow all staff group members to read/write
        sudo chmod +a "group:staff allow read,write,execute,delete,add_file,add_subdirectory,file_inherit,directory_inherit" "$SHARED_BASE" 2>/dev/null || warn "Could not set ACL on $SHARED_BASE"
        
        # Ensure new files are group writable
        sudo chmod g+s "$SHARED_BASE"
        
        success "✓ Advanced permissions configured for shared directories"
    fi
    
    # Create directory usage guidelines
    create_directory_guidelines
}

# Create directory usage guidelines
create_directory_guidelines() {
    local guidelines_file="$SHARED_BASE/README_Directory_Usage.md"
    
    if [[ ! -f "$guidelines_file" ]]; then
        sudo tee "$guidelines_file" > /dev/null << 'EOF'
# Family Shared Directory Usage Guidelines

## Directory Structure

### `/Users/Shared/Family/`
Main family shared space with appropriate permissions for all family members.

#### Documents
- Shared family documents
- Important papers and forms
- Reference materials

#### Media
- **Photos**: Family photos and shared images
- **Videos**: Home videos and shared video content
- **Music**: Shared music library and playlists

#### Software
- Family software licenses and installers
- Shared applications and utilities
- Installation guides

#### Templates
- Document templates for family use
- Project templates
- Standard forms and letterheads

#### Projects
- Collaborative family projects
- School and work projects
- Creative endeavours

#### Resources
- Learning materials and tutorials
- Reference documents
- Shared bookmarks and links

#### Backups
- Local backup storage
- Archive of important files
- Version history for critical documents

## Usage Guidelines

### File Naming Conventions
- Use descriptive names: `2024-01-15_Family_Holiday_Photos`
- Avoid spaces in filenames (use underscores or hyphens)
- Include dates for time-sensitive content
- Use consistent capitalisation

### Organisation Principles
- Keep directories organised and clean
- Delete unnecessary files regularly
- Use subdirectories for logical grouping
- Archive old content to Backups folder

### Security Considerations
- Never store passwords or sensitive data in shared folders
- Use 1Password for credential sharing
- Be mindful of personal information in shared documents
- Regularly review and clean shared content

### Backup Strategy
- Important shared files are backed up via Time Machine
- Critical documents should also be stored in cloud backup
- Test restore procedures periodically
- Maintain offline backups for essential data

## Device-Specific Notes

### Mac Studio (Server)
- Provides central file server for family
- Hosts Time Machine backup destinations
- Maintains archive and backup storage

### MacBook Pro (Portable)
- Sync important shared files for offline access
- Contribute content when connected to home network
- Backup personal work to shared Projects folder

### Mac Mini (Multimedia)
- Manage shared media libraries
- Process and organise family photos/videos
- Maintain entertainment content

## Maintenance Schedule

### Weekly
- Clean up temporary files
- Organise new content into appropriate folders
- Check backup status

### Monthly
- Review and archive old content
- Update shared templates and resources
- Verify directory permissions

### Quarterly
- Full backup verification
- Directory structure review
- Update usage guidelines as needed

---
Created by macOS Setup Automation
Last updated: $(date +"%Y-%m-%d")
EOF
        
        sudo chown root:staff "$guidelines_file"
        sudo chmod 664 "$guidelines_file"
        success "✓ Created directory usage guidelines"
    fi
}

# Configure Time Machine for family environment
setup_time_machine() {
    info "Configuring Time Machine for family environment..."
    
    case "$DEVICE_TYPE" in
        "mac-studio")
            info "Configuring Mac Studio as Time Machine server..."
            
            # Create Time Machine destination folders
            if [[ ! -d "$TIME_MACHINE_BASE" ]]; then
                sudo mkdir -p "$TIME_MACHINE_BASE"
                sudo chown root:admin "$TIME_MACHINE_BASE"
                sudo chmod 755 "$TIME_MACHINE_BASE"
                success "✓ Created Time Machine base directory"
            fi
            
            # Enable Time Machine server capability
            setup_time_machine_server
            ;;
            
        "macbook-pro"|"mac-mini")
            info "Configuring Time Machine client for backup to Mac Studio..."
            
            # Configure client to use Mac Studio as backup destination
            setup_time_machine_client
            ;;
    esac
}

# Set up Time Machine server on Mac Studio
setup_time_machine_server() {
    info "Setting up Time Machine server functionality..."
    
    # Check if File Sharing is enabled
    if ! sudo launchctl list | grep -q "com.apple.smbd"; then
        warn "File Sharing is not enabled"
        warn "Please enable File Sharing in System Preferences > Sharing"
        warn "Then configure Time Machine sharing for the backup folders"
    else
        success "✓ File Sharing is enabled"
    fi
    
    # Create individual backup destinations for each family Mac
    local client_machines=("MacBook-Pro" "Mac-Mini")
    
    for machine in "${client_machines[@]}"; do
        local backup_path="$TIME_MACHINE_BASE/$machine"
        if [[ ! -d "$backup_path" ]]; then
            sudo mkdir -p "$backup_path"
            sudo chown root:admin "$backup_path"
            sudo chmod 755 "$backup_path"
            success "✓ Created Time Machine destination for $machine"
        fi
    done
    
    info "Time Machine server setup guidance:"
    info "1. Go to System Preferences > Sharing"
    info "2. Enable File Sharing if not already enabled"
    info "3. Add Time Machine backup folders as shared folders"
    info "4. Configure appropriate user access for each backup destination"
    info "5. Enable Time Machine option for shared folders"
}

# Set up Time Machine client configuration
setup_time_machine_client() {
    info "Setting up Time Machine client configuration..."
    
    # Check current Time Machine status
    local tm_status
    tm_status=$(tmutil destinationinfo 2>/dev/null || echo "No destinations configured")
    
    info "Current Time Machine status: $tm_status"
    
    if [[ "$tm_status" == "No destinations configured" ]]; then
        warn "Time Machine backup is not configured"
        info "Time Machine client setup guidance:"
        info "1. Go to System Preferences > Time Machine"
        info "2. Click 'Select Backup Disk'"
        info "3. Choose the shared folder on Mac Studio (should appear automatically)"
        info "4. Enter credentials when prompted"
        info "5. Enable automatic backups"
        
        # Suggest backup exclusions for better performance
        suggest_backup_exclusions
    else
        success "✓ Time Machine backup is already configured"
    fi
}

# Suggest backup exclusions for optimal performance
suggest_backup_exclusions() {
    info "Recommended Time Machine exclusions for optimal performance:"
    
    local exclusion_paths=(
        "/Users/*/Downloads"
        "/Users/*/Library/Caches"
        "/Users/*/Library/Application Support/Spotify"
        "/Users/*/Movies" # Large media files
        "/Users/*/VirtualBox VMs"
        "/Users/*/Parallels"
        "/opt/homebrew/var" # Homebrew temporary files
        "/tmp"
        "/var/tmp"
    )
    
    info "Consider excluding these paths from Time Machine backups:"
    for path in "${exclusion_paths[@]}"; do
        info "  • $path"
    done
    
    info "Add exclusions with: sudo tmutil addexclusion -p <path>"
}

# Configure user-specific preferences for family environment
configure_family_user_preferences() {
    info "Configuring family-friendly user preferences..."
    
    # Configure Finder for family use
    info "Setting up Finder preferences..."
    
    # Show file extensions for safety
    defaults write NSGlobalDomain AppleShowAllExtensions -bool true
    
    # Show hidden files (for technical users)
    defaults write com.apple.finder AppleShowAllFiles -bool true
    
    # Use list view by default (easier for families)
    defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
    
    # Show path bar
    defaults write com.apple.finder ShowPathbar -bool true
    
    # Show status bar
    defaults write com.apple.finder ShowStatusBar -bool true
    
    success "✓ Finder configured for family use"
    
    # Configure Dock for family environment
    info "Setting up Dock preferences..."
    
    # Set reasonable icon size
    defaults write com.apple.dock tilesize -int 48
    
    # Enable magnification for easier clicking
    defaults write com.apple.dock magnification -bool true
    defaults write com.apple.dock largesize -int 64
    
    # Show indicators for open apps
    defaults write com.apple.dock show-process-indicators -bool true
    
    # Don't automatically rearrange Spaces
    defaults write com.apple.dock mru-spaces -bool false
    
    success "✓ Dock configured for family use"
    
    # Configure energy settings per device type
    configure_family_energy_settings
}

# Configure energy settings for family environment
configure_family_energy_settings() {
    info "Configuring energy settings for family use..."
    
    case "$DEVICE_TYPE" in
        "macbook-pro")
            # Balanced power settings for portable use
            sudo pmset -b displaysleep 5 sleep 10 2>/dev/null || warn "Could not set battery power settings"
            sudo pmset -c displaysleep 15 sleep 0 2>/dev/null || warn "Could not set AC power settings"
            success "✓ MacBook Pro energy settings configured for portable use"
            ;;
            
        "mac-studio")
            # Server-optimised power settings
            sudo pmset -a displaysleep 30 sleep 0 2>/dev/null || warn "Could not set power settings"
            sudo pmset -a womp 1 2>/dev/null || warn "Could not enable wake on network"
            sudo pmset -a autorestart 1 2>/dev/null || warn "Could not enable auto restart"
            success "✓ Mac Studio energy settings configured for server use"
            ;;
            
        "mac-mini")
            # Multimedia-optimised power settings
            sudo pmset -a displaysleep 20 sleep 0 2>/dev/null || warn "Could not set power settings"
            sudo pmset -a womp 1 2>/dev/null || warn "Could not enable wake on network"
            success "✓ Mac Mini energy settings configured for multimedia use"
            ;;
    esac
}

# Set up family automation and convenience features
setup_family_automation() {
    info "Setting up family automation and convenience features..."
    
    # Create family utility scripts directory
    local scripts_dir="$SHARED_BASE/Scripts"
    if [[ ! -d "$scripts_dir" ]]; then
        sudo mkdir -p "$scripts_dir"
        sudo chown root:staff "$scripts_dir"
        sudo chmod 775 "$scripts_dir"
        success "✓ Created family scripts directory"
    fi
    
    # Create helpful family scripts
    create_family_utility_scripts "$scripts_dir"
    
    # Set up regular maintenance tasks
    setup_maintenance_tasks
}

# Create utility scripts for family use
create_family_utility_scripts() {
    local scripts_dir="$1"
    
    # Family backup check script
    local backup_check_script="$scripts_dir/check_family_backups.zsh"
    sudo tee "$backup_check_script" > /dev/null << 'EOF'
#!/usr/bin/env zsh
# Family Backup Check Script

echo "🔍 Checking Family Backup Status..."
echo "=================================="

# Check Time Machine status
echo "\n📦 Time Machine Status:"
tmutil status | grep -E "(Running|BackupPhase)" || echo "No backup currently running"

# Check last backup date
echo "\n📅 Last Backup:"
tmutil latestbackup 2>/dev/null || echo "No backup history found"

# Check available space on backup drive
echo "\n💾 Backup Drive Space:"
df -h $(tmutil destinationinfo 2>/dev/null | grep "URL" | awk '{print $2}' | head -1) 2>/dev/null || echo "Backup destination not found"

# Check shared directory usage
echo "\n📁 Shared Directory Usage:"
du -sh /Users/Shared/Family/* 2>/dev/null || echo "No shared directories found"

echo "\n✅ Backup check completed"
EOF
    
    sudo chmod 755 "$backup_check_script"
    success "✓ Created family backup check script"
    
    # Family disk cleanup script
    local cleanup_script="$scripts_dir/family_cleanup.zsh"
    sudo tee "$cleanup_script" > /dev/null << 'EOF'
#!/usr/bin/env zsh
# Family Disk Cleanup Script

echo "🧹 Family Disk Cleanup Utility"
echo "==============================="

echo "\n🗑️  Emptying Trash for all users..."
sudo rm -rf /Users/*/.Trash/* 2>/dev/null || echo "Trash already empty"

echo "\n🧽 Cleaning system caches..."
sudo rm -rf /var/folders/*/*/*/Cache/* 2>/dev/null || echo "System caches already clean"

echo "\n📱 Cleaning iOS device backups older than 30 days..."
find ~/Library/Application\ Support/MobileSync/Backup -type d -mtime +30 -exec rm -rf {} \; 2>/dev/null || echo "No old iOS backups found"

echo "\n🌐 Cleaning browser caches..."
rm -rf ~/Library/Caches/com.apple.Safari/* 2>/dev/null || echo "Safari cache already clean"
rm -rf ~/Library/Caches/Google/Chrome/* 2>/dev/null || echo "Chrome cache already clean"

echo "\n📊 Disk space summary:"
df -h / | grep -E "(Filesystem|disk)"

echo "\n✅ Cleanup completed"
EOF
    
    sudo chmod 755 "$cleanup_script"
    success "✓ Created family cleanup script"
}

# Set up maintenance tasks
setup_maintenance_tasks() {
    info "Setting up automated maintenance tasks..."
    
    # Create maintenance script
    local maintenance_script="$HOME/.family_maintenance"
    cat > "$maintenance_script" << 'EOF'
#!/usr/bin/env zsh
# Family Environment Maintenance Tasks

# Log maintenance run
echo "$(date): Running family maintenance tasks" >> ~/.family_maintenance.log

# Update Homebrew
if command -v brew &>/dev/null; then
    brew update --quiet && brew upgrade --quiet 2>/dev/null || true
fi

# Clean up shared directories
find /Users/Shared/Family -name ".DS_Store" -delete 2>/dev/null || true
find /Users/Shared/Family -name "._*" -delete 2>/dev/null || true

# Check backup status
if command -v tmutil &>/dev/null; then
    tmutil status | grep -q "Running" || echo "$(date): No Time Machine backup running" >> ~/.family_maintenance.log
fi

echo "$(date): Family maintenance completed" >> ~/.family_maintenance.log
EOF
    
    chmod 755 "$maintenance_script"
    success "✓ Created maintenance script"
    
    # Add to user's crontab if not already present
    if ! crontab -l 2>/dev/null | grep -q "family_maintenance"; then
        (crontab -l 2>/dev/null; echo "0 2 * * 0 $maintenance_script") | crontab -
        success "✓ Scheduled weekly maintenance tasks"
    fi
}

# Help function
usage() {
    cat << EOF
$SCRIPT_NAME - Family Environment Configuration

USAGE:
    $SCRIPT_NAME [OPTIONS] [DEVICE_TYPE]

DESCRIPTION:
    Configures comprehensive family environment settings including
    shared directories, Time Machine backup, user preferences,
    and family-friendly automation features.

OPTIONS:
    -h, --help           Show this help message

DEVICE_TYPE:
    macbook-pro    Portable family member device
    mac-studio     Central family server and backup hub
    mac-mini       Shared family multimedia and development system
    
    Default: macbook-pro

FAMILY FEATURES:
    • Comprehensive shared directory structure
    • Advanced directory permissions and ACLs
    • Time Machine server/client configuration
    • Family-friendly user preferences
    • Automated maintenance and utility scripts
    • Usage guidelines and documentation

EXAMPLES:
    $SCRIPT_NAME                    # Setup family environment for MacBook Pro
    $SCRIPT_NAME mac-studio         # Setup family server features
    $SCRIPT_NAME mac-mini           # Setup shared multimedia system

SHARED DIRECTORY STRUCTURE:
    /Users/Shared/Family/
    ├── Documents/          Shared family documents
    ├── Media/             Photos, videos, music
    ├── Software/          Family software and licenses
    ├── Templates/         Document and project templates
    ├── Projects/          Collaborative family projects
    ├── Resources/         Learning materials and references
    ├── Backups/           Local backup storage
    └── Scripts/           Family utility scripts

DEVICE-SPECIFIC FEATURES:
    Mac Studio    Time Machine server, central file sharing
    MacBook Pro   Optimised for portable family use
    Mac Mini      Multimedia and shared development environment

EOF
}

# Main execution
main() {
    info "Family Environment Configuration"
    info "==============================="
    info "Device type: $DEVICE_TYPE"
    echo
    
    # Set up shared directories
    setup_shared_directories
    echo
    
    # Configure Time Machine
    setup_time_machine
    echo
    
    # Configure user preferences
    configure_family_user_preferences
    echo
    
    # Set up family automation
    setup_family_automation
    echo
    
    success "=========================================="
    success "Family environment setup completed!"
    success "=========================================="
    success "Your $DEVICE_TYPE is now configured for optimal family use"
    
    info "Family features configured:"
    info "• Shared directory structure with proper permissions"
    info "• Time Machine backup configuration"
    info "• Family-friendly user preferences"
    info "• Automated maintenance and utility scripts"
    
    echo
    info "Next steps:"
    info "• Review shared directory guidelines in $SHARED_BASE/README_Directory_Usage.md"
    info "• Configure Time Machine backup destinations in System Preferences"
    info "• Test shared directory access from all family user accounts"
    info "• Run family utility scripts from $SHARED_BASE/Scripts/"
    
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
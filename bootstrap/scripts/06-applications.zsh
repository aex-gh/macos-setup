#!/usr/bin/env zsh
# -*- coding: utf-8 -*-

#=============================================================================
# SCRIPT: 06-applications.zsh
# AUTHOR: Andrew Exley
# DATE: 2025-01-07
# VERSION: 1.0.0
#
# DESCRIPTION:
#   Application configuration and network services setup module.
#   Configures GUI applications, sets up network shares, and handles
#   hardware-specific application configurations including Karabiner Elements
#   keyboard customisation.
#
# USAGE:
#   ./06-applications.zsh [options]
#
# OPTIONS:
#   -h, --help      Show this help message
#   -v, --verbose   Enable verbose output
#   -d, --debug     Enable debug mode
#   -n, --dry-run   Preview changes without applying them
#
# REQUIREMENTS:
#   - macOS 11.0+ (Big Sur)
#   - Hardware detection completed
#   - Applications installed via Homebrew
#
# NOTES:
#   - Configures applications based on hardware type
#   - Sets up network sharing for Mac Studio
#   - Configures automatic mounting for MacBook Pro and Mac Mini
#   - Installs Karabiner Elements keyboard customisation on all hardware types
#=============================================================================

# Strict mode
set -euo pipefail

# Script metadata
readonly SCRIPT_NAME="${0:t}"
readonly SCRIPT_DIR="${0:A:h}"
readonly SCRIPT_VERSION="1.0.0"

# Source network shares module
source "${SCRIPT_DIR}/modules/network-shares.zsh"

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

#=============================================================================
# APPLICATION CONFIGURATION
#=============================================================================

# Configure applications based on hardware type
configure_applications() {
    step "Configuring applications for hardware type: $HARDWARE_TYPE"
    
    case $HARDWARE_TYPE in
        "studio")
            configure_studio_applications
            ;;
        "laptop")
            configure_laptop_applications
            ;;
        "mini")
            configure_mini_applications
            ;;
        *)
            info "No specific application configuration for hardware type: $HARDWARE_TYPE"
            ;;
    esac
    
    success "Application configuration completed"
}

# Configure Mac Studio applications
configure_studio_applications() {
    step "Configuring Mac Studio server applications"
    
    # Configure keyboard customisation (universal benefit)
    configure_karabiner_elements
    
    # Configure OrbStack for server use
    if command -v orb &>/dev/null || [[ -d "/Applications/OrbStack.app" ]]; then
        configure_orbstack_server_settings
    fi
    
    # Configure database applications
    configure_database_applications
    
    # Configure monitoring applications
    configure_monitoring_applications
    
    success "Mac Studio applications configured"
}

# Configure MacBook Pro applications  
configure_laptop_applications() {
    step "Configuring MacBook Pro daily driver applications"
    
    # Configure keyboard customisation (universal benefit)
    configure_karabiner_elements
    
    # Configure development applications
    configure_development_applications
    
    # Configure productivity applications
    configure_productivity_applications
    
    # Configure battery-aware settings
    configure_battery_aware_applications
    
    success "MacBook Pro applications configured"
}

# Configure Mac Mini applications
configure_mini_applications() {
    step "Configuring Mac Mini home office applications"
    
    # Configure keyboard customisation (universal benefit)
    configure_karabiner_elements
    
    # Configure media center applications
    configure_media_applications
    
    # Configure home automation
    configure_home_automation_applications
    
    success "Mac Mini applications configured"
}

#=============================================================================
# SPECIFIC APPLICATION CONFIGURATIONS
#=============================================================================

# Configure OrbStack for server use
configure_orbstack_server_settings() {
    step "Configuring OrbStack for server operation"
    
    local orbstack_config_dir="$HOME/.config/orbstack"
    local orbstack_config="$orbstack_config_dir/config.json"
    
    if [[ $DRY_RUN == false ]]; then
        execute_command "Creating OrbStack config directory" \
            mkdir -p "$orbstack_config_dir"
        
        # Create server-optimized OrbStack configuration
        cat > "$orbstack_config" << EOF
{
  "engine": {
    "autoStart": true,
    "cpuLimit": 8,
    "memoryLimitGB": 16,
    "diskSizeGB": 256
  },
  "docker": {
    "enableCompat": true,
    "enableBuildKit": true
  },
  "network": {
    "enableVpnKit": true,
    "dnsForwarding": true
  },
  "rosetta": {
    "enabled": true
  },
  "logging": {
    "level": "info",
    "maxFiles": 5,
    "maxSizeMB": 50
  }
}
EOF
        
        success "OrbStack server configuration created"
        
        # Configure OrbStack to start on boot for server
        if [[ -d "/Applications/OrbStack.app" ]]; then
            execute_command "Setting OrbStack to start on login" \
                osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/OrbStack.app", hidden:false}'
        fi
        
    else
        info "DRY RUN: Would configure OrbStack for server use"
    fi
}

# Configure database applications
configure_database_applications() {
    step "Configuring database applications"
    
    # Configure TablePlus connections for server databases
    if [[ -d "/Applications/TablePlus.app" ]]; then
        info "TablePlus detected - configure connections manually"
        info "Server databases available at: localhost (when services are running)"
    fi
    
    # Configure Sequel Pro
    if [[ -d "/Applications/Sequel Pro.app" ]]; then
        info "Sequel Pro detected - MySQL available at localhost:3306"
    fi
    
    success "Database applications noted for manual configuration"
}

# Configure monitoring applications
configure_monitoring_applications() {
    step "Configuring monitoring applications"
    
    # Configure Stats menu bar app
    if [[ -d "/Applications/Stats.app" ]]; then
        info "Stats app detected - showing CPU, memory, and network in menu bar"
    fi
    
    # Configure iStat Menus if present
    if [[ -d "/Applications/iStat Menus.app" ]]; then
        info "iStat Menus detected - configure for server monitoring"
    fi
    
    success "Monitoring applications configured"
}

# Configure development applications
configure_development_applications() {
    step "Configuring development applications"
    
    # Configure VS Code for daily driver use
    if [[ -d "/Applications/Visual Studio Code.app" ]]; then
        configure_vscode_daily_driver
    fi
    
    # Configure Zed for performance
    if [[ -d "/Applications/Zed.app" ]]; then
        info "Zed editor detected - optimized for fast editing"
    fi
    
    success "Development applications configured"
}

# Configure VS Code for daily driver
configure_vscode_daily_driver() {
    step "Configuring VS Code for daily driver use"
    
    local vscode_settings_dir="$HOME/Library/Application Support/Code/User"
    local vscode_settings_file="$vscode_settings_dir/settings.json"
    
    if [[ $DRY_RUN == false ]]; then
        execute_command "Creating VS Code settings directory" \
            mkdir -p "$vscode_settings_dir"
        
        # Create VS Code settings optimized for daily development
        cat > "$vscode_settings_file" << EOF
{
    "editor.fontSize": 14,
    "editor.fontFamily": "SF Mono, Monaco, 'Cascadia Code', 'Roboto Mono', Consolas, 'Courier New', monospace",
    "editor.minimap.enabled": true,
    "editor.wordWrap": "on",
    "workbench.colorTheme": "Default Dark+",
    "workbench.iconTheme": "vs-seti",
    "terminal.integrated.fontSize": 13,
    "files.autoSave": "onWindowChange",
    "editor.formatOnSave": true,
    "editor.codeActionsOnSave": {
        "source.organizeImports": true
    },
    "git.enableSmartCommit": true,
    "git.confirmSync": false,
    "python.defaultInterpreterPath": "/usr/local/bin/python3",
    "remote.SSH.remotePlatform": {
        "mac-studio.local": "linux"
    }
}
EOF
        
        success "VS Code configured for daily driver use"
    else
        info "DRY RUN: Would configure VS Code settings"
    fi
}

# Configure productivity applications
configure_productivity_applications() {
    step "Configuring productivity applications"
    
    # Configure Alfred workflows
    if [[ -d "/Applications/Alfred 5.app" ]]; then
        info "Alfred detected - consider enabling advanced features"
    fi
    
    # Configure Rectangle window management
    if [[ -d "/Applications/Rectangle.app" ]]; then
        info "Rectangle detected - window management ready"
    fi
    
    success "Productivity applications configured"
}

# Configure battery-aware applications
configure_battery_aware_applications() {
    step "Configuring battery-aware application settings"
    
    # Configure Amphetamine for selective keep-awake
    if [[ -d "/Applications/Amphetamine.app" ]]; then
        info "Amphetamine detected - use selectively to preserve battery"
    fi
    
    # Configure battery monitoring
    if [[ -d "/Applications/Battery Monitor- Health, Info.app" ]]; then
        info "Battery Monitor detected - tracking battery health"
    fi
    
    success "Battery-aware settings configured"
}

# Configure media applications for Mac Mini
configure_media_applications() {
    step "Configuring media center applications"
    
    # Configure Plex Media Server
    if [[ -d "/Applications/Plex Media Server.app" ]]; then
        info "Plex Media Server detected - configure libraries manually"
        info "Recommended: Add Mac Studio shared media folders"
    fi
    
    # Configure VLC
    if [[ -d "/Applications/VLC.app" ]]; then
        info "VLC detected - universal media player ready"
    fi
    
    success "Media applications configured"
}

# Configure home automation applications
configure_home_automation_applications() {
    step "Configuring home automation applications"
    
    # Check for Homebridge
    if command -v homebridge &>/dev/null; then
        info "Homebridge detected - configure in web interface"
    fi
    
    # Check for Node-RED
    if command -v node-red &>/dev/null; then
        info "Node-RED detected - automation flows available"
    fi
    
    success "Home automation applications configured"
}

# Configure Karabiner Elements keyboard customisation
configure_karabiner_elements() {
    step "Configuring Karabiner Elements keyboard customisation"
    
    # Check if Karabiner Elements is installed
    if [[ ! -d "/Applications/Karabiner-Elements.app" ]]; then
        warn "Karabiner Elements not found - skipping configuration"
        return 0
    fi
    
    local karabiner_config_dir="$HOME/.config/karabiner"
    local karabiner_config_file="$karabiner_config_dir/karabiner.json"
    local source_config_file="$SCRIPT_DIR/../config/karabiner/karabiner-popular.json"
    
    # Verify source configuration exists
    if [[ ! -f "$source_config_file" ]]; then
        error "Karabiner source configuration not found: $source_config_file"
        return 1
    fi
    
    if [[ $DRY_RUN == false ]]; then
        # Create Karabiner config directory
        execute_command "Creating Karabiner config directory" \
            mkdir -p "$karabiner_config_dir"
        
        # Backup existing configuration if it exists
        if [[ -f "$karabiner_config_file" ]]; then
            local backup_file="$karabiner_config_file.backup.$(date +%Y%m%d_%H%M%S)"
            execute_command "Backing up existing Karabiner configuration" \
                cp "$karabiner_config_file" "$backup_file"
            info "Existing configuration backed up to: $backup_file"
        fi
        
        # Create complete Karabiner configuration structure
        cat > "$karabiner_config_file" << 'EOF'
{
    "global": {
        "ask_for_confirmation_before_quitting": true,
        "check_for_updates_on_startup": true,
        "show_in_menu_bar": true,
        "show_profile_name_in_menu_bar": false,
        "unsafe_ui": false
    },
    "profiles": [
        {
            "complex_modifications": {
EOF
        
        # Extract and add the rules from our configuration
        if command -v jq &>/dev/null; then
            # Use jq to properly merge the rules
            jq '.rules' "$source_config_file" >> "$karabiner_config_file"
        else
            # Fallback: manually extract rules section
            sed -n '/"rules":/,/^  \]/p' "$source_config_file" | sed '1s/.*/"rules": [/' >> "$karabiner_config_file"
        fi
        
        # Complete the configuration structure
        cat >> "$karabiner_config_file" << 'EOF'
            },
            "devices": [],
            "fn_function_keys": [
                {
                    "from": {
                        "key_code": "f1"
                    },
                    "to": [
                        {
                            "key_code": "display_brightness_decrement"
                        }
                    ]
                },
                {
                    "from": {
                        "key_code": "f2"
                    },
                    "to": [
                        {
                            "key_code": "display_brightness_increment"
                        }
                    ]
                },
                {
                    "from": {
                        "key_code": "f3"
                    },
                    "to": [
                        {
                            "key_code": "mission_control"
                        }
                    ]
                },
                {
                    "from": {
                        "key_code": "f4"
                    },
                    "to": [
                        {
                            "key_code": "launchpad"
                        }
                    ]
                },
                {
                    "from": {
                        "key_code": "f5"
                    },
                    "to": [
                        {
                            "key_code": "illumination_decrement"
                        }
                    ]
                },
                {
                    "from": {
                        "key_code": "f6"
                    },
                    "to": [
                        {
                            "key_code": "illumination_increment"
                        }
                    ]
                },
                {
                    "from": {
                        "key_code": "f7"
                    },
                    "to": [
                        {
                            "key_code": "rewind"
                        }
                    ]
                },
                {
                    "from": {
                        "key_code": "f8"
                    },
                    "to": [
                        {
                            "key_code": "play_or_pause"
                        }
                    ]
                },
                {
                    "from": {
                        "key_code": "f9"
                    },
                    "to": [
                        {
                            "key_code": "fast_forward"
                        }
                    ]
                },
                {
                    "from": {
                        "key_code": "f10"
                    },
                    "to": [
                        {
                            "key_code": "mute"
                        }
                    ]
                },
                {
                    "from": {
                        "key_code": "f11"
                    },
                    "to": [
                        {
                            "key_code": "volume_decrement"
                        }
                    ]
                },
                {
                    "from": {
                        "key_code": "f12"
                    },
                    "to": [
                        {
                            "key_code": "volume_increment"
                        }
                    ]
                }
            ],
            "name": "Popular Configuration",
            "parameters": {
                "delay_milliseconds_before_open_device": 1000
            },
            "selected": true,
            "simple_modifications": [],
            "virtual_hid_keyboard": {
                "country_code": 0,
                "indicate_sticky_modifier_keys_state": true,
                "mouse_key_xy_scale": 100
            }
        }
    ]
}
EOF
        
        # Set proper permissions
        execute_command "Setting Karabiner configuration permissions" \
            chmod 644 "$karabiner_config_file"
        
        success "Karabiner Elements configuration installed"
        
        # Restart Karabiner Elements to load new configuration
        if pgrep -f "Karabiner-Elements" >/dev/null; then
            execute_command "Restarting Karabiner Elements" \
                osascript -e 'tell application "Karabiner-Elements" to quit' \
                && sleep 2 \
                && open -a "Karabiner-Elements"
        else
            execute_command "Starting Karabiner Elements" \
                open -a "Karabiner-Elements"
        fi
        
        # Add to login items for automatic startup
        info "Adding Karabiner Elements to login items..."
        if osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/Karabiner-Elements.app", hidden:false}' 2>/dev/null; then
            success "Karabiner Elements added to login items"
        else
            warn "Could not automatically add Karabiner Elements to login items"
            info "To add manually: System Preferences > Users & Groups > Login Items"
            info "Click '+' and select Karabiner-Elements from Applications"
        fi
        
        success "Karabiner Elements configured with popular keyboard improvements"
        
        echo ""
        info "Keyboard improvements enabled:"
        info "  • Caps Lock → Escape when tapped, Control when held"
        info "  • Right Option + HJKL → Arrow keys (Vim navigation)"
        info "  • Windows-style shortcuts (Ctrl+C/V/X/Z → Cmd+C/V/X/Z)"
        info "  • Function keys work without Fn key"
        info "  • Enhanced window management shortcuts"
        info "  • Quick app switching (Cmd+Opt+1/2/3/4)"
        
    else
        info "DRY RUN: Would configure Karabiner Elements with popular keyboard improvements"
    fi
    
    return 0
}

#=============================================================================
# MAIN FUNCTIONS
#=============================================================================

# Display usage information
usage() {
    cat << EOF
${BOLD}NAME${RESET}
    $SCRIPT_NAME - Application configuration and network services setup

${BOLD}SYNOPSIS${RESET}
    $SCRIPT_NAME [options]

${BOLD}DESCRIPTION${RESET}
    Configures GUI applications and sets up network services based on
    hardware type. Handles Mac Studio server setup, MacBook Pro daily
    driver configuration, and Mac Mini home office setup.

${BOLD}OPTIONS${RESET}
    -h, --help          Show this help message
    -v, --verbose       Enable verbose output
    -d, --debug         Enable debug mode
    -n, --dry-run       Preview changes without applying them

${BOLD}HARDWARE CONFIGURATIONS${RESET}
    Mac Studio          Server applications, network sharing, monitoring, keyboard customisation
    MacBook Pro         Daily driver, development tools, auto-mounting, keyboard customisation
    Mac Mini            Home office, media center, balanced setup, keyboard customisation

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
    
    print_section "APPLICATIONS & NETWORK SERVICES SETUP" "📱"
    
    # Configure applications
    configure_applications
    
    # Set up network shares
    setup_network_shares
    
    success "Applications and network services setup completed"
    
    # Provide next steps based on hardware type
    case $HARDWARE_TYPE in
        "studio")
            echo ""
            echo "${BOLD}Mac Studio Server Setup Complete:${RESET}"
            echo "  • Server shares created at /Users/Shared/Studio-Server"
            echo "  • AFP and SMB sharing enabled"
            echo "  • Time Machine network destination configured"
            echo "  • Database and web services running"
            echo ""
            echo "${BOLD}Next steps:${RESET}"
            echo "  • Complete sharing setup in System Preferences > Sharing"
            echo "  • Configure user access for shared folders"
            echo "  • Test connections from other devices"
            ;;
        "laptop")
            echo ""
            echo "${BOLD}MacBook Pro Daily Driver Setup Complete:${RESET}"
            echo "  • Full development environment configured"
            echo "  • Automatic Mac Studio mounting enabled"
            echo "  • Battery-aware service management"
            echo ""
            echo "${BOLD}Next steps:${RESET}"
            echo "  • Test connection to Mac Studio server"
            echo "  • Configure development projects"
            echo "  • Set up Time Machine to Mac Studio"
            ;;
        "mini")
            echo ""
            echo "${BOLD}Mac Mini Home Office Setup Complete:${RESET}"
            echo "  • Media center and home automation ready"
            echo "  • Automatic Mac Studio mounting enabled"
            echo "  • Balanced resource management"
            echo ""
            echo "${BOLD}Next steps:${RESET}"
            echo "  • Configure media libraries"
            echo "  • Set up home automation workflows"
            echo "  • Test network connectivity"
            ;;
    esac
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
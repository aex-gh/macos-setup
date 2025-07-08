#!/usr/bin/env zsh
# -*- coding: utf-8 -*-

#=============================================================================
# SCRIPT: dry-run-utils.zsh
# AUTHOR: Andrew Exley (with Claude)
# DATE: 2025-01-07
# VERSION: 1.0.0
#
# DESCRIPTION:
#   Comprehensive dry run utility library for macOS dotfiles setup.
#   Provides standardised functions for previewing changes across all modules
#   without actually applying them to the system.
#
# USAGE:
#   source "${SCRIPT_DIR}/lib/dry-run-utils.zsh"
#
# FEATURES:
#   - Standardised dry run execution patterns
#   - System state capture and conflict detection
#   - Detailed change preview reporting
#   - Package installation simulation
#   - File system change preview
#   - Service management simulation
#   - macOS defaults preview
#
# REQUIREMENTS:
#   - macOS 11.0+ (Big Sur)
#   - Zsh 5.8+
#   - jq (for JSON processing)
#   - Standard Unix utilities
#
# NOTES:
#   - All functions respect the global DRY_RUN variable
#   - Provides both preview and execution modes
#   - Captures detailed change information for reporting
#=============================================================================

# Ensure we're in a zsh environment
if [[ -z "$ZSH_VERSION" ]]; then
    echo "Error: This script requires Zsh" >&2
    exit 1
fi

# Global dry run state
declare -g DRY_RUN_ENABLED=${DRY_RUN_ENABLED:-${DRY_RUN:-false}}
declare -g DRY_RUN_REPORT_FILE="${DRY_RUN_REPORT_FILE:-$HOME/.config/dotfiles-setup/dry-run-report.json}"
declare -g DRY_RUN_CHANGES_COUNT=0

# Colour codes for consistent output
declare -g DR_RED=$(tput setaf 1)
declare -g DR_GREEN=$(tput setaf 2)
declare -g DR_YELLOW=$(tput setaf 3)
declare -g DR_BLUE=$(tput setaf 4)
declare -g DR_MAGENTA=$(tput setaf 5)
declare -g DR_CYAN=$(tput setaf 6)
declare -g DR_BOLD=$(tput bold)
declare -g DR_RESET=$(tput sgr0)

# Change tracking arrays
declare -ga DRY_RUN_FILE_CHANGES=()
declare -ga DRY_RUN_PACKAGE_INSTALLS=()
declare -ga DRY_RUN_SERVICE_CHANGES=()
declare -ga DRY_RUN_DEFAULTS_CHANGES=()
declare -ga DRY_RUN_COMMAND_EXECUTIONS=()
declare -ga DRY_RUN_SYMLINK_CHANGES=()

#=============================================================================
# CORE DRY RUN FUNCTIONS
#=============================================================================

# Initialize dry run reporting
dr_init() {
    local module_name="${1:-unknown}"
    
    if [[ $DRY_RUN_ENABLED == true ]]; then
        # Create report directory
        mkdir -p "${DRY_RUN_REPORT_FILE:h}"
        
        # Initialize report file if it doesn't exist
        if [[ ! -f $DRY_RUN_REPORT_FILE ]]; then
            cat > "$DRY_RUN_REPORT_FILE" << EOF
{
  "dry_run_started": "$(date -Iseconds)",
  "modules": {},
  "summary": {
    "total_changes": 0,
    "file_changes": 0,
    "package_installs": 0,
    "service_changes": 0,
    "defaults_changes": 0,
    "command_executions": 0,
    "symlink_changes": 0
  }
}
EOF
        fi
        
        # Add module to report
        local temp_file=$(mktemp)
        jq ".modules[\"$module_name\"] = {
            \"started\": \"$(date -Iseconds)\",
            \"changes\": []
        }" "$DRY_RUN_REPORT_FILE" > "$temp_file"
        mv "$temp_file" "$DRY_RUN_REPORT_FILE"
    fi
}

# Add change to dry run report
dr_add_change() {
    local module_name=$1
    local change_type=$2
    local description=$3
    local details=${4:-"{}"}
    
    if [[ $DRY_RUN_ENABLED == true ]]; then
        ((DRY_RUN_CHANGES_COUNT++))
        
        local change_entry=$(cat << EOF
{
    "type": "$change_type",
    "description": "$description",
    "timestamp": "$(date -Iseconds)",
    "details": $details
}
EOF
)
        
        local temp_file=$(mktemp)
        jq ".modules[\"$module_name\"].changes += [$change_entry] |
            .summary.total_changes += 1 |
            .summary.${change_type}_changes += 1" \
            "$DRY_RUN_REPORT_FILE" > "$temp_file"
        mv "$temp_file" "$DRY_RUN_REPORT_FILE"
    fi
}

# Finalize dry run report for a module
dr_finalize_module() {
    local module_name="${1:-unknown}"
    
    if [[ $DRY_RUN_ENABLED == true ]]; then
        local temp_file=$(mktemp)
        jq ".modules[\"$module_name\"].completed = \"$(date -Iseconds)\"" \
            "$DRY_RUN_REPORT_FILE" > "$temp_file"
        mv "$temp_file" "$DRY_RUN_REPORT_FILE"
    fi
}

#=============================================================================
# COMMAND EXECUTION WITH DRY RUN
#=============================================================================

# Execute command with dry run support
dr_execute() {
    local description=$1
    shift
    local cmd=("$@")
    local module_name="${DR_MODULE_NAME:-unknown}"
    
    if [[ $DRY_RUN_ENABLED == true ]]; then
        echo "${DR_CYAN}[DRY RUN]${DR_RESET} $description"
        echo "${DR_BLUE}         Command:${DR_RESET} ${cmd[*]}"
        
        # Add to report
        local details=$(jq -n \
            --arg cmd "${cmd[*]}" \
            '{"command": $cmd}')
        dr_add_change "$module_name" "command" "$description" "$details"
        
        DRY_RUN_COMMAND_EXECUTIONS+=("$description: ${cmd[*]}")
        return 0
    else
        echo "${DR_MAGENTA}[EXEC]${DR_RESET} $description"
        if "${cmd[@]}"; then
            echo "${DR_GREEN}[✓]${DR_RESET} Completed: $description"
            return 0
        else
            echo "${DR_RED}[✗]${DR_RESET} Failed: $description"
            return 1
        fi
    fi
}

# Execute command silently with dry run support
dr_execute_silent() {
    local description=$1
    shift
    local cmd=("$@")
    local module_name="${DR_MODULE_NAME:-unknown}"
    
    if [[ $DRY_RUN_ENABLED == true ]]; then
        echo "${DR_CYAN}[DRY RUN]${DR_RESET} $description"
        
        # Add to report
        local details=$(jq -n \
            --arg cmd "${cmd[*]}" \
            '{"command": $cmd, "silent": true}')
        dr_add_change "$module_name" "command" "$description" "$details"
        
        return 0
    else
        "${cmd[@]}"
    fi
}

# Execute with sudo and dry run support
dr_sudo() {
    local description=$1
    shift
    local cmd=("$@")
    local module_name="${DR_MODULE_NAME:-unknown}"
    
    if [[ $DRY_RUN_ENABLED == true ]]; then
        echo "${DR_CYAN}[DRY RUN]${DR_RESET} $description"
        echo "${DR_YELLOW}         Sudo Command:${DR_RESET} sudo ${cmd[*]}"
        
        # Add to report
        local details=$(jq -n \
            --arg cmd "sudo ${cmd[*]}" \
            '{"command": $cmd, "requires_sudo": true}')
        dr_add_change "$module_name" "command" "$description" "$details"
        
        return 0
    else
        echo "${DR_MAGENTA}[SUDO]${DR_RESET} $description"
        if sudo "${cmd[@]}"; then
            echo "${DR_GREEN}[✓]${DR_RESET} Completed: $description"
            return 0
        else
            echo "${DR_RED}[✗]${DR_RESET} Failed: $description"
            return 1
        fi
    fi
}

#=============================================================================
# FILE SYSTEM OPERATIONS
#=============================================================================

# Create directory with dry run support
dr_mkdir() {
    local description=$1
    local dir_path=$2
    local permissions=${3:-755}
    local module_name="${DR_MODULE_NAME:-unknown}"
    
    if [[ $DRY_RUN_ENABLED == true ]]; then
        echo "${DR_CYAN}[DRY RUN]${DR_RESET} $description"
        echo "${DR_BLUE}         Create directory:${DR_RESET} $dir_path (mode: $permissions)"
        
        # Check if directory already exists
        if [[ -d $dir_path ]]; then
            echo "${DR_YELLOW}         Status:${DR_RESET} Directory already exists"
        else
            echo "${DR_GREEN}         Status:${DR_RESET} Would create new directory"
        fi
        
        # Add to report
        local details=$(jq -n \
            --arg path "$dir_path" \
            --arg perms "$permissions" \
            --argjson exists "$([[ -d $dir_path ]] && echo true || echo false)" \
            '{"path": $path, "permissions": $perms, "already_exists": $exists}')
        dr_add_change "$module_name" "file" "$description" "$details"
        
        DRY_RUN_FILE_CHANGES+=("CREATE DIR: $dir_path")
        return 0
    else
        mkdir -p "$dir_path"
        chmod "$permissions" "$dir_path"
    fi
}

# Create symlink with dry run support
dr_symlink() {
    local description=$1
    local source_path=$2
    local target_path=$3
    local module_name="${DR_MODULE_NAME:-unknown}"
    
    if [[ $DRY_RUN_ENABLED == true ]]; then
        echo "${DR_CYAN}[DRY RUN]${DR_RESET} $description"
        echo "${DR_BLUE}         Symlink:${DR_RESET} $source_path → $target_path"
        
        # Check current state
        local status=""
        if [[ -L $target_path ]]; then
            local current_target=$(readlink "$target_path")
            if [[ $current_target == $source_path ]]; then
                status="Symlink already correct"
            else
                status="Would replace existing symlink (currently points to: $current_target)"
            fi
        elif [[ -e $target_path ]]; then
            status="Would replace existing file/directory"
        else
            status="Would create new symlink"
        fi
        
        echo "${DR_YELLOW}         Status:${DR_RESET} $status"
        
        # Add to report
        local details=$(jq -n \
            --arg source "$source_path" \
            --arg target "$target_path" \
            --arg status "$status" \
            '{"source": $source, "target": $target, "status": $status}')
        dr_add_change "$module_name" "symlink" "$description" "$details"
        
        DRY_RUN_SYMLINK_CHANGES+=("$source_path → $target_path")
        return 0
    else
        # Remove existing file/symlink if it exists
        [[ -e $target_path || -L $target_path ]] && rm -rf "$target_path"
        ln -sf "$source_path" "$target_path"
    fi
}

# Write file with dry run support
dr_write_file() {
    local description=$1
    local file_path=$2
    local content=$3
    local permissions=${4:-644}
    local module_name="${DR_MODULE_NAME:-unknown}"
    
    if [[ $DRY_RUN_ENABLED == true ]]; then
        echo "${DR_CYAN}[DRY RUN]${DR_RESET} $description"
        echo "${DR_BLUE}         Write file:${DR_RESET} $file_path (mode: $permissions)"
        echo "${DR_BLUE}         Content size:${DR_RESET} $(echo -n "$content" | wc -c) bytes"
        
        # Check if file already exists and compare content
        local status=""
        if [[ -f $file_path ]]; then
            if [[ $(<"$file_path") == $content ]]; then
                status="File already has correct content"
            else
                status="Would update existing file"
            fi
        else
            status="Would create new file"
        fi
        
        echo "${DR_YELLOW}         Status:${DR_RESET} $status"
        
        # Add to report
        local details=$(jq -n \
            --arg path "$file_path" \
            --arg size "$(echo -n "$content" | wc -c)" \
            --arg perms "$permissions" \
            --arg status "$status" \
            '{"path": $path, "size": $size, "permissions": $perms, "status": $status}')
        dr_add_change "$module_name" "file" "$description" "$details"
        
        DRY_RUN_FILE_CHANGES+=("WRITE: $file_path")
        return 0
    else
        echo "$content" > "$file_path"
        chmod "$permissions" "$file_path"
    fi
}

#=============================================================================
# PACKAGE MANAGEMENT
#=============================================================================

# Homebrew package installation with dry run support
dr_brew_install() {
    local description=$1
    shift
    local packages=("$@")
    local module_name="${DR_MODULE_NAME:-unknown}"
    
    if [[ $DRY_RUN_ENABLED == true ]]; then
        echo "${DR_CYAN}[DRY RUN]${DR_RESET} $description"
        echo "${DR_BLUE}         Packages to install:${DR_RESET} ${packages[*]}"
        
        # Check which packages are already installed
        local installed=()
        local not_installed=()
        
        for package in "${packages[@]}"; do
            if brew list --formula | grep -q "^$package$" || brew list --cask | grep -q "^$package$"; then
                installed+=("$package")
            else
                not_installed+=("$package")
            fi
        done
        
        if [[ ${#installed[@]} -gt 0 ]]; then
            echo "${DR_GREEN}         Already installed:${DR_RESET} ${installed[*]}"
        fi
        
        if [[ ${#not_installed[@]} -gt 0 ]]; then
            echo "${DR_YELLOW}         Would install:${DR_RESET} ${not_installed[*]}"
        fi
        
        # Add to report
        local details=$(jq -n \
            --argjson packages "$(printf '%s\n' "${packages[@]}" | jq -R . | jq -s .)" \
            --argjson installed "$(printf '%s\n' "${installed[@]}" | jq -R . | jq -s .)" \
            --argjson not_installed "$(printf '%s\n' "${not_installed[@]}" | jq -R . | jq -s .)" \
            '{"packages": $packages, "already_installed": $installed, "would_install": $not_installed}')
        dr_add_change "$module_name" "package" "$description" "$details"
        
        DRY_RUN_PACKAGE_INSTALLS+=("${packages[*]}")
        return 0
    else
        brew install "${packages[@]}"
    fi
}

# Homebrew bundle with dry run support
dr_brew_bundle() {
    local description=$1
    local brewfile_path=$2
    local module_name="${DR_MODULE_NAME:-unknown}"
    
    if [[ $DRY_RUN_ENABLED == true ]]; then
        echo "${DR_CYAN}[DRY RUN]${DR_RESET} $description"
        echo "${DR_BLUE}         Brewfile:${DR_RESET} $brewfile_path"
        
        if [[ -f $brewfile_path ]]; then
            echo "${DR_YELLOW}         Would install packages from:${DR_RESET}"
            
            # Parse and display Brewfile contents
            local taps=($(grep "^tap " "$brewfile_path" | cut -d'"' -f2))
            local brews=($(grep "^brew " "$brewfile_path" | cut -d'"' -f2))
            local casks=($(grep "^cask " "$brewfile_path" | cut -d'"' -f2))
            local mas_apps=($(grep "^mas " "$brewfile_path" | cut -d'"' -f2))
            
            [[ ${#taps[@]} -gt 0 ]] && echo "           Taps: ${taps[*]}"
            [[ ${#brews[@]} -gt 0 ]] && echo "           Formulae: ${brews[*]}"
            [[ ${#casks[@]} -gt 0 ]] && echo "           Casks: ${casks[*]}"
            [[ ${#mas_apps[@]} -gt 0 ]] && echo "           Mac App Store: ${mas_apps[*]}"
            
            # Add to report
            local details=$(jq -n \
                --arg brewfile "$brewfile_path" \
                --argjson taps "$(printf '%s\n' "${taps[@]}" | jq -R . | jq -s .)" \
                --argjson brews "$(printf '%s\n' "${brews[@]}" | jq -R . | jq -s .)" \
                --argjson casks "$(printf '%s\n' "${casks[@]}" | jq -R . | jq -s .)" \
                --argjson mas "$(printf '%s\n' "${mas_apps[@]}" | jq -R . | jq -s .)" \
                '{"brewfile": $brewfile, "taps": $taps, "formulae": $brews, "casks": $casks, "mas_apps": $mas}')
            dr_add_change "$module_name" "package" "$description" "$details"
        else
            echo "${DR_RED}         Error:${DR_RESET} Brewfile not found"
        fi
        
        return 0
    else
        brew bundle --file="$brewfile_path"
    fi
}

#=============================================================================
# SYSTEM CONFIGURATION
#=============================================================================

# macOS defaults with dry run support
dr_defaults_write() {
    local description=$1
    local domain=$2
    local key=$3
    local value_type=$4
    local value=$5
    local module_name="${DR_MODULE_NAME:-unknown}"
    
    if [[ $DRY_RUN_ENABLED == true ]]; then
        echo "${DR_CYAN}[DRY RUN]${DR_RESET} $description"
        echo "${DR_BLUE}         Domain:${DR_RESET} $domain"
        echo "${DR_BLUE}         Key:${DR_RESET} $key"
        echo "${DR_BLUE}         Value:${DR_RESET} $value ($value_type)"
        
        # Check current value
        local current_value=""
        if current_value=$(defaults read "$domain" "$key" 2>/dev/null); then
            echo "${DR_YELLOW}         Current:${DR_RESET} $current_value"
            if [[ $current_value == $value ]]; then
                echo "${DR_GREEN}         Status:${DR_RESET} Already set correctly"
            else
                echo "${DR_YELLOW}         Status:${DR_RESET} Would change value"
            fi
        else
            echo "${DR_YELLOW}         Status:${DR_RESET} Would set new value"
        fi
        
        # Add to report
        local details=$(jq -n \
            --arg domain "$domain" \
            --arg key "$key" \
            --arg value "$value" \
            --arg type "$value_type" \
            --arg current "${current_value:-null}" \
            '{"domain": $domain, "key": $key, "new_value": $value, "value_type": $type, "current_value": $current}')
        dr_add_change "$module_name" "defaults" "$description" "$details"
        
        DRY_RUN_DEFAULTS_CHANGES+=("$domain.$key = $value")
        return 0
    else
        defaults write "$domain" "$key" "-$value_type" "$value"
    fi
}

# Service management with dry run support
dr_service() {
    local description=$1
    local action=$2  # start, stop, restart, enable, disable
    local service_name=$3
    local module_name="${DR_MODULE_NAME:-unknown}"
    
    if [[ $DRY_RUN_ENABLED == true ]]; then
        echo "${DR_CYAN}[DRY RUN]${DR_RESET} $description"
        echo "${DR_BLUE}         Service:${DR_RESET} $service_name"
        echo "${DR_BLUE}         Action:${DR_RESET} $action"
        
        # Check current service status
        local status=""
        if launchctl list | grep -q "$service_name"; then
            status="Service is currently loaded"
        else
            status="Service is not currently loaded"
        fi
        
        echo "${DR_YELLOW}         Current status:${DR_RESET} $status"
        
        # Add to report
        local details=$(jq -n \
            --arg service "$service_name" \
            --arg action "$action" \
            --arg status "$status" \
            '{"service": $service, "action": $action, "current_status": $status}')
        dr_add_change "$module_name" "service" "$description" "$details"
        
        DRY_RUN_SERVICE_CHANGES+=("$action: $service_name")
        return 0
    else
        case $action in
            start)
                launchctl load -w "$service_name"
                ;;
            stop)
                launchctl unload -w "$service_name"
                ;;
            restart)
                launchctl unload -w "$service_name" 2>/dev/null || true
                launchctl load -w "$service_name"
                ;;
            enable)
                launchctl enable "$service_name"
                ;;
            disable)
                launchctl disable "$service_name"
                ;;
        esac
    fi
}

#=============================================================================
# SYSTEM STATE CAPTURE
#=============================================================================

# Capture current system state before changes
dr_capture_system_state() {
    local module_name="${1:-unknown}"
    local state_file="$HOME/.config/dotfiles-setup/system-state-$module_name.json"
    
    if [[ $DRY_RUN_ENABLED == true ]]; then
        echo "${DR_CYAN}[DRY RUN]${DR_RESET} Capturing system state for conflict detection"
        
        # Create state directory
        mkdir -p "${state_file:h}"
        
        # Capture various system aspects
        local system_state=$(cat << EOF
{
    "timestamp": "$(date -Iseconds)",
    "module": "$module_name",
    "system_info": {
        "macos_version": "$(sw_vers -productVersion)",
        "build_version": "$(sw_vers -buildVersion)",
        "hostname": "$(hostname)",
        "hardware_model": "$(sysctl -n hw.model)"
    },
    "disk_space": {
        "available_gb": $(df -g / | awk 'NR==2 {print $4}'),
        "used_gb": $(df -g / | awk 'NR==2 {print $3}')
    },
    "homebrew": {
        "installed": $(command -v brew &>/dev/null && echo true || echo false),
        "prefix": "${HOMEBREW_PREFIX:-unknown}",
        "formula_count": $(brew list --formula 2>/dev/null | wc -l | xargs),
        "cask_count": $(brew list --cask 2>/dev/null | wc -l | xargs)
    },
    "shell_environment": {
        "shell": "$SHELL",
        "zsh_version": "$ZSH_VERSION",
        "path_entries": $(echo "$PATH" | tr ':' '\n' | jq -R . | jq -s .)
    }
}
EOF
)
        
        echo "$system_state" > "$state_file"
        echo "${DR_GREEN}         State captured:${DR_RESET} $state_file"
    fi
}

# Check for potential conflicts
dr_check_conflicts() {
    local module_name="${1:-unknown}"
    
    if [[ $DRY_RUN_ENABLED == true ]]; then
        echo "${DR_CYAN}[DRY RUN]${DR_RESET} Checking for potential conflicts"
        
        # Check disk space
        local free_space=$(df -g / | awk 'NR==2 {print $4}')
        if [[ $free_space -lt 5 ]]; then
            echo "${DR_RED}         WARNING:${DR_RESET} Low disk space: ${free_space}GB available"
        fi
        
        # Check for conflicting processes
        local conflicting_processes=()
        if pgrep -f "softwareupdate" >/dev/null; then
            conflicting_processes+=("Software Update in progress")
        fi
        
        if pgrep -f "installer" >/dev/null; then
            conflicting_processes+=("Installer process running")
        fi
        
        if [[ ${#conflicting_processes[@]} -gt 0 ]]; then
            echo "${DR_YELLOW}         CONFLICTS:${DR_RESET}"
            for conflict in "${conflicting_processes[@]}"; do
                echo "           - $conflict"
            done
        fi
        
        # Check permissions for common directories
        local permission_issues=()
        [[ ! -w "$HOME" ]] && permission_issues+=("Home directory not writable")
        [[ ! -w "/usr/local" && -d "/usr/local" ]] && permission_issues+=("/usr/local not writable")
        
        if [[ ${#permission_issues[@]} -gt 0 ]]; then
            echo "${DR_YELLOW}         PERMISSION ISSUES:${DR_RESET}"
            for issue in "${permission_issues[@]}"; do
                echo "           - $issue"
            done
        fi
    fi
}

#=============================================================================
# REPORTING FUNCTIONS
#=============================================================================

# Generate summary report
dr_generate_summary() {
    if [[ $DRY_RUN_ENABLED == true ]]; then
        echo ""
        echo "${DR_BOLD}${DR_CYAN}═══════════════════════════════════════════════════════════════════════════════${DR_RESET}"
        echo "${DR_BOLD}${DR_CYAN}  📋 DRY RUN SUMMARY${DR_RESET}"
        echo "${DR_BOLD}${DR_CYAN}═══════════════════════════════════════════════════════════════════════════════${DR_RESET}"
        echo ""
        
        echo "${DR_BOLD}Total Changes Detected: $DRY_RUN_CHANGES_COUNT${DR_RESET}"
        echo ""
        
        # File system changes
        if [[ ${#DRY_RUN_FILE_CHANGES[@]} -gt 0 ]]; then
            echo "${DR_BOLD}📁 File System Changes (${#DRY_RUN_FILE_CHANGES[@]}):${DR_RESET}"
            for change in "${DRY_RUN_FILE_CHANGES[@]}"; do
                echo "   $change"
            done
            echo ""
        fi
        
        # Package installations
        if [[ ${#DRY_RUN_PACKAGE_INSTALLS[@]} -gt 0 ]]; then
            echo "${DR_BOLD}📦 Package Installations (${#DRY_RUN_PACKAGE_INSTALLS[@]}):${DR_RESET}"
            for packages in "${DRY_RUN_PACKAGE_INSTALLS[@]}"; do
                echo "   $packages"
            done
            echo ""
        fi
        
        # Service changes
        if [[ ${#DRY_RUN_SERVICE_CHANGES[@]} -gt 0 ]]; then
            echo "${DR_BOLD}⚙️  Service Changes (${#DRY_RUN_SERVICE_CHANGES[@]}):${DR_RESET}"
            for change in "${DRY_RUN_SERVICE_CHANGES[@]}"; do
                echo "   $change"
            done
            echo ""
        fi
        
        # macOS defaults
        if [[ ${#DRY_RUN_DEFAULTS_CHANGES[@]} -gt 0 ]]; then
            echo "${DR_BOLD}🍎 macOS Defaults (${#DRY_RUN_DEFAULTS_CHANGES[@]}):${DR_RESET}"
            for change in "${DRY_RUN_DEFAULTS_CHANGES[@]}"; do
                echo "   $change"
            done
            echo ""
        fi
        
        # Symlinks
        if [[ ${#DRY_RUN_SYMLINK_CHANGES[@]} -gt 0 ]]; then
            echo "${DR_BOLD}🔗 Symbolic Links (${#DRY_RUN_SYMLINK_CHANGES[@]}):${DR_RESET}"
            for change in "${DRY_RUN_SYMLINK_CHANGES[@]}"; do
                echo "   $change"
            done
            echo ""
        fi
        
        # Commands
        if [[ ${#DRY_RUN_COMMAND_EXECUTIONS[@]} -gt 0 ]]; then
            echo "${DR_BOLD}💻 Command Executions (${#DRY_RUN_COMMAND_EXECUTIONS[@]}):${DR_RESET}"
            for command in "${DRY_RUN_COMMAND_EXECUTIONS[@]}"; do
                echo "   $command"
            done
            echo ""
        fi
        
        echo "${DR_BOLD}Detailed Report:${DR_RESET} $DRY_RUN_REPORT_FILE"
        echo ""
        echo "${DR_YELLOW}To apply these changes, run the same command without --dry-run${DR_RESET}"
        echo ""
    fi
}

# Set module name for reporting context
dr_set_module() {
    export DR_MODULE_NAME="$1"
}

# Check if dry run is enabled
dr_is_enabled() {
    [[ $DRY_RUN_ENABLED == true ]]
}

# Auto-detect DRY_RUN state if not explicitly set
if [[ -n ${DRY_RUN:-} && $DRY_RUN == true ]]; then
    DRY_RUN_ENABLED=true
fi

# Print initialization message if being sourced
if [[ ${(%):-%x} != ${0} ]]; then
    if [[ $DRY_RUN_ENABLED == true ]]; then
        echo "${DR_CYAN}[DRY RUN UTILS]${DR_RESET} Dry run mode enabled - no changes will be applied"
    fi
fi
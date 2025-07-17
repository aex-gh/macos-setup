#!/usr/bin/env zsh
set -euo pipefail

# Script metadata
readonly SCRIPT_NAME="${0:t}"
readonly SCRIPT_DIR="${0:A:h}"

# Load common library
source "${SCRIPT_DIR}/../lib/common.zsh"

# Note: Cleanup is handled by common library

update_homebrew() {
    info "Updating Homebrew packages..."
    
    if ! command -v brew >/dev/null 2>&1; then
        warn "Homebrew not installed. Skipping Homebrew updates."
        return 0
    fi
    
    # Update Homebrew itself
    info "Updating Homebrew formulae database..."
    if brew update; then
        success "Homebrew database updated"
    else
        error "Failed to update Homebrew database"
        return 1
    fi
    
    # List outdated packages
    local outdated_formulae outdated_casks
    outdated_formulae=$(brew outdated --formula --quiet)
    outdated_casks=$(brew outdated --cask --quiet)
    
    if [[ -n "${outdated_formulae}" ]]; then
        info "Outdated formulae: ${outdated_formulae}"
        info "Upgrading formulae..."
        if brew upgrade --formula; then
            success "Formulae upgraded successfully"
        else
            warn "Some formulae failed to upgrade"
        fi
    else
        info "All formulae are up to date"
    fi
    
    if [[ -n "${outdated_casks}" ]]; then
        info "Outdated casks: ${outdated_casks}"
        info "Upgrading casks..."
        if brew upgrade --cask; then
            success "Casks upgraded successfully"
        else
            warn "Some casks failed to upgrade"
        fi
    else
        info "All casks are up to date"
    fi
    
    # Clean up old versions
    info "Cleaning up old Homebrew files..."
    if brew cleanup --prune=all; then
        success "Homebrew cleanup completed"
    else
        warn "Homebrew cleanup encountered issues"
    fi
    
    # Run doctor to check for issues
    info "Running Homebrew doctor..."
    if brew doctor; then
        success "Homebrew doctor found no issues"
    else
        warn "Homebrew doctor found potential issues"
    fi
}

update_mac_app_store() {
    info "Updating Mac App Store applications..."
    
    # Check for available updates
    local available_updates
    available_updates=$(softwareupdate -l 2>/dev/null | grep -c "Software Update found" || echo "0")
    
    if [[ "${available_updates}" -gt 0 ]]; then
        info "Found ${available_updates} software updates"
        
        # Install all available updates
        info "Installing software updates..."
        if sudo softwareupdate -i -a; then
            success "Software updates installed successfully"
        else
            warn "Some software updates failed to install"
        fi
    else
        info "No software updates available"
    fi
    
    # Update Mac App Store apps via mas if available
    if command -v mas >/dev/null 2>&1; then
        info "Updating Mac App Store apps via mas..."
        if mas upgrade; then
            success "Mac App Store apps updated"
        else
            warn "Some Mac App Store apps failed to update"
        fi
    else
        warn "mas not installed. Install with: brew install mas"
    fi
}

update_node_packages() {
    info "Updating Node.js packages..."
    
    if ! command -v npm >/dev/null 2>&1; then
        warn "npm not installed. Skipping Node.js package updates."
        return 0
    fi
    
    # Update npm itself
    info "Updating npm..."
    if npm install -g npm@latest; then
        success "npm updated to latest version"
    else
        warn "Failed to update npm"
    fi
    
    # Update global packages
    info "Updating global npm packages..."
    if npm update -g; then
        success "Global npm packages updated"
    else
        warn "Some global npm packages failed to update"
    fi
    
    # Check for security vulnerabilities
    info "Checking for security vulnerabilities..."
    if npm audit -g; then
        success "No security vulnerabilities found in global packages"
    else
        warn "Security vulnerabilities found in global packages"
        info "Run 'npm audit fix -g' to attempt automatic fixes"
    fi
}

update_python_packages() {
    info "Updating Python packages..."
    
    # Update uv if available
    if command -v uv >/dev/null 2>&1; then
        info "Updating uv..."
        if uv self update; then
            success "uv updated successfully"
        else
            warn "Failed to update uv"
        fi
        
        # Update global tools installed via uv
        info "Updating uv tools..."
        if uv tool upgrade --all 2>/dev/null; then
            success "uv tools updated"
        else
            warn "Some uv tools failed to update or no tools installed"
        fi
    else
        warn "uv not installed. Consider installing for better Python package management."
    fi
    
    # Update pip and setuptools if using system Python
    if command -v pip3 >/dev/null 2>&1; then
        info "Updating pip..."
        if pip3 install --upgrade pip setuptools wheel; then
            success "pip updated successfully"
        else
            warn "Failed to update pip"
        fi
    fi
}

update_ruby_gems() {
    info "Updating Ruby gems..."
    
    if ! command -v gem >/dev/null 2>&1; then
        warn "Ruby/gem not installed. Skipping gem updates."
        return 0
    fi
    
    # Update RubyGems system
    info "Updating RubyGems system..."
    if gem update --system; then
        success "RubyGems system updated"
    else
        warn "Failed to update RubyGems system"
    fi
    
    # Update all gems
    info "Updating all gems..."
    if gem update; then
        success "Gems updated successfully"
    else
        warn "Some gems failed to update"
    fi
    
    # Clean up old gem versions
    info "Cleaning up old gem versions..."
    if gem cleanup; then
        success "Old gem versions cleaned up"
    else
        warn "Gem cleanup encountered issues"
    fi
}

clean_system_caches() {
    info "Cleaning system caches..."
    
    # Clear user caches
    local cache_dirs=(
        "${HOME}/Library/Caches"
        "${HOME}/Library/Logs"
        "/tmp"
    )
    
    for cache_dir in "${cache_dirs[@]}"; do
        if [[ -d "${cache_dir}" ]]; then
            info "Cleaning ${cache_dir}..."
            find "${cache_dir}" -type f -atime +7 -delete 2>/dev/null || true
            find "${cache_dir}" -type d -empty -delete 2>/dev/null || true
        fi
    done
    
    # Clear Safari cache
    if [[ -d "${HOME}/Library/Caches/com.apple.Safari" ]]; then
        info "Clearing Safari cache..."
        rm -rf "${HOME}/Library/Caches/com.apple.Safari/WebKitCache"/* 2>/dev/null || true
    fi
    
    # Clear Chrome cache
    if [[ -d "${HOME}/Library/Caches/Google/Chrome" ]]; then
        info "Clearing Chrome cache..."
        rm -rf "${HOME}/Library/Caches/Google/Chrome/Default/Cache"/* 2>/dev/null || true
    fi
    
    # Run periodic maintenance
    info "Running periodic maintenance..."
    sudo periodic daily weekly monthly
    
    success "System caches cleaned"
}

check_disk_space() {
    info "Checking disk space..."
    
    # Get disk usage information
    local disk_usage
    disk_usage=$(df -h / | tail -1)
    local used_percentage
    used_percentage=$(echo "${disk_usage}" | awk '{print $5}' | sed 's/%//')
    
    info "Disk usage: ${disk_usage}"
    
    if [[ ${used_percentage} -gt 90 ]]; then
        error "Disk space critically low (${used_percentage}% used)"
        warn "Consider cleaning up files or expanding storage"
    elif [[ ${used_percentage} -gt 80 ]]; then
        warn "Disk space getting low (${used_percentage}% used)"
    else
        success "Disk space is adequate (${used_percentage}% used)"
    fi
    
    # Check for large files in common locations
    info "Checking for large files..."
    local large_files
    large_files=$(find "${HOME}/Downloads" -type f -size +100M 2>/dev/null | head -5)
    if [[ -n "${large_files}" ]]; then
        warn "Large files found in Downloads:"
        echo "${large_files}"
    fi
}

update_mcp_servers() {
    info "Updating MCP servers..."
    
    if command -v mcp-manager >/dev/null 2>&1; then
        # Update npm-based MCP servers
        local npm_servers=(
            "@modelcontextprotocol/server-filesystem"
            "@modelcontextprotocol/server-github"
            "@microsoft/markitdown-mcp"
        )
        
        for server in "${npm_servers[@]}"; do
            if npm list -g "${server}" >/dev/null 2>&1; then
                info "Updating ${server}..."
                if npm update -g "${server}"; then
                    success "Updated ${server}"
                else
                    warn "Failed to update ${server}"
                fi
            fi
        done
        
        success "MCP server updates completed"
    else
        warn "MCP manager not available. Skipping MCP server updates."
    fi
}

generate_maintenance_report() {
    info "Generating maintenance report..."
    
    local report_file="${HOME}/Library/Logs/system-maintenance-$(date +%Y%m%d-%H%M%S).log"
    
    {
        echo "System Maintenance Report"
        echo "Generated: $(date)"
        echo "========================"
        echo
        
        echo "System Information:"
        echo "- macOS Version: $(sw_vers -productVersion)"
        echo "- Build: $(sw_vers -buildVersion)"
        echo "- Hostname: $(hostname)"
        echo "- Uptime: $(uptime)"
        echo
        
        echo "Disk Usage:"
        df -h
        echo
        
        echo "Memory Usage:"
        vm_stat | head -10
        echo
        
        echo "Homebrew Status:"
        if command -v brew >/dev/null 2>&1; then
            brew --version
            echo "Installed formulae: $(brew list --formula | wc -l)"
            echo "Installed casks: $(brew list --cask | wc -l)"
        else
            echo "Homebrew not installed"
        fi
        echo
        
        echo "Development Tools:"
        echo "- Node.js: $(node --version 2>/dev/null || echo 'Not installed')"
        echo "- npm: $(npm --version 2>/dev/null || echo 'Not installed')"
        echo "- Python: $(python3 --version 2>/dev/null || echo 'Not installed')"
        echo "- Ruby: $(ruby --version 2>/dev/null || echo 'Not installed')"
        echo "- Git: $(git --version 2>/dev/null || echo 'Not installed')"
        echo
        
        echo "Recent System Changes:"
        echo "Last 10 software installations/updates:"
        ls -lt /var/log/install.log* | head -10 2>/dev/null || echo "Install logs not accessible"
        
    } > "${report_file}"
    
    success "Maintenance report saved to ${report_file}"
    
    # Also display summary
    info "Maintenance Summary:"
    echo "- Report saved to: ${report_file}"
    echo "- System uptime: $(uptime | awk -F'up ' '{print $2}' | awk -F', load' '{print $1}')"
    echo "- Disk usage: $(df -h / | tail -1 | awk '{print $5}')"
}

create_maintenance_schedule() {
    info "Setting up maintenance schedule..."
    
    local plist_dir="${HOME}/Library/LaunchAgents"
    local plist_file="${plist_dir}/net.exley.system-maintenance.plist"
    
    mkdir -p "${plist_dir}"
    
    cat > "${plist_file}" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>net.exley.system-maintenance</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Users/andrew/projects/macos-setupv2/scripts/system-maintenance.zsh</string>
        <string>--automated</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Weekday</key>
        <integer>0</integer>
        <key>Hour</key>
        <integer>9</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
    <key>RunAtLoad</key>
    <false/>
    <key>StandardOutPath</key>
    <string>/tmp/system-maintenance.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/system-maintenance.error.log</string>
</dict>
</plist>
EOF
    
    # Load the launch agent
    launchctl load "${plist_file}" 2>/dev/null || true
    
    success "Scheduled weekly maintenance (Sundays at 9 AM)"
    info "Logs will be written to /tmp/system-maintenance.log"
}

main() {
    local automated_mode=false
    
    # Check if running in automated mode
    if [[ "${1:-}" == "--automated" ]]; then
        automated_mode=true
        info "Running in automated mode"
    fi
    
    info "Starting system maintenance..."
    echo
    
    # Core updates
    update_homebrew
    echo
    
    update_mac_app_store
    echo
    
    # Development tool updates
    update_node_packages
    echo
    
    update_python_packages
    echo
    
    update_ruby_gems
    echo
    
    update_mcp_servers
    echo
    
    # System cleanup
    clean_system_caches
    echo
    
    check_disk_space
    echo
    
    # Generate report
    generate_maintenance_report
    echo
    
    # Set up schedule if not automated
    if [[ "${automated_mode}" == "false" ]]; then
        create_maintenance_schedule
        echo
    fi
    
    success "System maintenance completed successfully!"
    
    if [[ "${automated_mode}" == "false" ]]; then
        info "Future maintenance will run automatically every Sunday at 9 AM"
        info "Run 'system-maintenance.zsh --automated' to run maintenance manually"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
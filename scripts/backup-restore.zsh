#!/usr/bin/env zsh
set -euo pipefail

readonly SCRIPT_NAME="${0:t}"
readonly RED=$(tput setaf 1)
readonly GREEN=$(tput setaf 2)
readonly YELLOW=$(tput setaf 3)
readonly BLUE=$(tput setaf 4)
readonly RESET=$(tput sgr0)

info() {
    echo "${BLUE}[INFO]${RESET} $*"
}

success() {
    echo "${GREEN}[SUCCESS]${RESET} $*"
}

warn() {
    echo "${YELLOW}[WARN]${RESET} $*"
}

error() {
    echo "${RED}[ERROR]${RESET} $*" >&2
}

cleanup() {
    local exit_code=$?
    if [[ ${exit_code} -ne 0 ]]; then
        error "Script failed with exit code ${exit_code}"
    fi
    exit ${exit_code}
}

trap cleanup EXIT INT TERM

# Configuration
readonly BACKUP_BASE_DIR="${HOME}/Backups"
readonly CONFIG_BACKUP_DIR="${BACKUP_BASE_DIR}/Configurations"
readonly APP_BACKUP_DIR="${BACKUP_BASE_DIR}/Applications"
readonly SETTINGS_BACKUP_DIR="${BACKUP_BASE_DIR}/Settings"

create_backup_structure() {
    info "Creating backup directory structure..."
    
    local dirs=(
        "${BACKUP_BASE_DIR}"
        "${CONFIG_BACKUP_DIR}"
        "${APP_BACKUP_DIR}"
        "${SETTINGS_BACKUP_DIR}"
        "${BACKUP_BASE_DIR}/Scripts"
        "${BACKUP_BASE_DIR}/Logs"
    )
    
    for dir in "${dirs[@]}"; do
        mkdir -p "${dir}"
    done
    
    success "Backup directory structure created"
}

backup_homebrew_packages() {
    info "Backing up Homebrew packages..."
    
    if ! command -v brew >/dev/null 2>&1; then
        warn "Homebrew not installed. Skipping Homebrew backup."
        return 0
    fi
    
    local timestamp
    timestamp=$(date +%Y%m%d-%H%M%S)
    local backup_file="${CONFIG_BACKUP_DIR}/Brewfile-${timestamp}"
    
    # Generate Brewfile
    cd "${BACKUP_BASE_DIR}"
    if brew bundle dump --file="${backup_file}"; then
        success "Homebrew packages backed up to ${backup_file}"
        
        # Create symlink to latest
        ln -sf "$(basename "${backup_file}")" "${CONFIG_BACKUP_DIR}/Brewfile-latest"
        
        # Show package counts
        local formula_count cask_count
        formula_count=$(grep -c '^brew ' "${backup_file}" || echo 0)
        cask_count=$(grep -c '^cask ' "${backup_file}" || echo 0)
        info "Backed up ${formula_count} formulae and ${cask_count} casks"
    else
        error "Failed to backup Homebrew packages"
        return 1
    fi
}

backup_system_preferences() {
    info "Backing up system preferences..."
    
    local timestamp
    timestamp=$(date +%Y%m%d-%H%M%S)
    local prefs_dir="${SETTINGS_BACKUP_DIR}/SystemPreferences-${timestamp}"
    
    mkdir -p "${prefs_dir}"
    
    # Backup key preference files
    local pref_files=(
        "${HOME}/Library/Preferences/com.apple.dock.plist"
        "${HOME}/Library/Preferences/com.apple.finder.plist"
        "${HOME}/Library/Preferences/com.apple.Terminal.plist"
        "${HOME}/Library/Preferences/com.apple.menuextra.clock.plist"
        "${HOME}/Library/Preferences/com.apple.screensaver.plist"
        "${HOME}/Library/Preferences/com.apple.systempreferences.plist"
        "${HOME}/Library/Preferences/.GlobalPreferences.plist"
        "${HOME}/Library/Preferences/loginwindow.plist"
    )
    
    local backed_up_count=0
    for pref_file in "${pref_files[@]}"; do
        if [[ -f "${pref_file}" ]]; then
            if cp "${pref_file}" "${prefs_dir}/"; then
                ((backed_up_count++))
            fi
        fi
    done
    
    # Backup defaults using defaults export
    local domains=(
        "com.apple.dock"
        "com.apple.finder"
        "com.apple.Terminal"
        "NSGlobalDomain"
        "com.apple.screensaver"
    )
    
    for domain in "${domains[@]}"; do
        defaults export "${domain}" "${prefs_dir}/${domain}.plist" 2>/dev/null || true
    done
    
    # Create symlink to latest
    ln -sf "$(basename "${prefs_dir}")" "${SETTINGS_BACKUP_DIR}/SystemPreferences-latest"
    
    success "System preferences backed up (${backed_up_count} files)"
}

backup_dotfiles() {
    info "Backing up dotfiles..."
    
    local timestamp
    timestamp=$(date +%Y%m%d-%H%M%S)
    local dotfiles_dir="${CONFIG_BACKUP_DIR}/Dotfiles-${timestamp}"
    
    mkdir -p "${dotfiles_dir}"
    
    # Backup key dotfiles
    local dotfiles=(
        ".zshrc"
        ".bashrc"
        ".gitconfig"
        ".gitignore_global"
        ".vimrc"
        ".tmux.conf"
        ".ssh/config"
        ".ssh/known_hosts"
    )
    
    local backed_up_count=0
    for dotfile in "${dotfiles[@]}"; do
        local full_path="${HOME}/${dotfile}"
        if [[ -f "${full_path}" ]]; then
            local dest_dir="${dotfiles_dir}/$(dirname "${dotfile}")"
            mkdir -p "${dest_dir}"
            if cp "${full_path}" "${dest_dir}/"; then
                ((backed_up_count++))
            fi
        fi
    done
    
    # Backup entire config directories
    local config_dirs=(
        ".config/zed"
        ".config/git"
        ".config/mcp"
        ".config/linuxify"
    )
    
    for config_dir in "${config_dirs[@]}"; do
        local full_path="${HOME}/${config_dir}"
        if [[ -d "${full_path}" ]]; then
            local dest_dir="${dotfiles_dir}/$(dirname "${config_dir}")"
            mkdir -p "${dest_dir}"
            if cp -r "${full_path}" "${dest_dir}/"; then
                ((backed_up_count++))
            fi
        fi
    done
    
    # If chezmoi is being used, backup the source directory
    if command -v chezmoi >/dev/null 2>&1; then
        local chezmoi_source
        chezmoi_source=$(chezmoi source-path 2>/dev/null || echo "")
        if [[ -n "${chezmoi_source}" ]] && [[ -d "${chezmoi_source}" ]]; then
            info "Backing up chezmoi source directory..."
            cp -r "${chezmoi_source}" "${dotfiles_dir}/chezmoi-source"
            ((backed_up_count++))
        fi
    fi
    
    # Create symlink to latest
    ln -sf "$(basename "${dotfiles_dir}")" "${CONFIG_BACKUP_DIR}/Dotfiles-latest"
    
    success "Dotfiles backed up (${backed_up_count} items)"
}

backup_application_settings() {
    info "Backing up application settings..."
    
    local timestamp
    timestamp=$(date +%Y%m%d-%H%M%S)
    local app_settings_dir="${APP_BACKUP_DIR}/AppSettings-${timestamp}"
    
    mkdir -p "${app_settings_dir}"
    
    # Application-specific backup paths
    local app_configs=(
        "Zed:${HOME}/.config/zed"
        "1Password:${HOME}/Library/Group Containers/2BUA8C4S2C.com.1password"
        "Raycast:${HOME}/Library/Application Support/com.raycast.macos"
        "Karabiner:${HOME}/.config/karabiner"
        "SSH:${HOME}/.ssh"
        "GPG:${HOME}/.gnupg"
    )
    
    local backed_up_count=0
    for app_config in "${app_configs[@]}"; do
        local app_name="${app_config%%:*}"
        local config_path="${app_config##*:}"
        
        if [[ -d "${config_path}" ]]; then
            info "Backing up ${app_name} settings..."
            local dest_dir="${app_settings_dir}/${app_name}"
            mkdir -p "${dest_dir}"
            if cp -r "${config_path}"/* "${dest_dir}/" 2>/dev/null; then
                ((backed_up_count++))
                success "Backed up ${app_name}"
            else
                warn "Failed to backup ${app_name} (may be permissions issue)"
            fi
        fi
    done
    
    # Create symlink to latest
    ln -sf "$(basename "${app_settings_dir}")" "${APP_BACKUP_DIR}/AppSettings-latest"
    
    success "Application settings backed up (${backed_up_count} applications)"
}

backup_development_environment() {
    info "Backing up development environment..."
    
    local timestamp
    timestamp=$(date +%Y%m%d-%H%M%S)
    local dev_backup_dir="${CONFIG_BACKUP_DIR}/Development-${timestamp}"
    
    mkdir -p "${dev_backup_dir}"
    
    # Backup package manager configurations
    local package_configs=(
        "npm:${HOME}/.npmrc"
        "pip:${HOME}/.pip/pip.conf"
        "gem:${HOME}/.gemrc"
        "cargo:${HOME}/.cargo/config.toml"
    )
    
    for config in "${package_configs[@]}"; do
        local manager="${config%%:*}"
        local config_file="${config##*:}"
        
        if [[ -f "${config_file}" ]]; then
            cp "${config_file}" "${dev_backup_dir}/${manager}-config"
        fi
    done
    
    # Backup global package lists
    if command -v npm >/dev/null 2>&1; then
        npm list -g --depth=0 --json > "${dev_backup_dir}/npm-global-packages.json" 2>/dev/null || true
    fi
    
    if command -v pip3 >/dev/null 2>&1; then
        pip3 list --format=json > "${dev_backup_dir}/pip-packages.json" 2>/dev/null || true
    fi
    
    if command -v gem >/dev/null 2>&1; then
        gem list > "${dev_backup_dir}/gem-packages.txt" 2>/dev/null || true
    fi
    
    if command -v uv >/dev/null 2>&1; then
        uv tool list > "${dev_backup_dir}/uv-tools.txt" 2>/dev/null || true
    fi
    
    # Create symlink to latest
    ln -sf "$(basename "${dev_backup_dir}")" "${CONFIG_BACKUP_DIR}/Development-latest"
    
    success "Development environment backed up"
}

create_backup_manifest() {
    info "Creating backup manifest..."
    
    local timestamp
    timestamp=$(date +%Y%m%d-%H%M%S)
    local manifest_file="${BACKUP_BASE_DIR}/backup-manifest-${timestamp}.txt"
    
    {
        echo "Backup Manifest"
        echo "Generated: $(date)"
        echo "Hostname: $(hostname)"
        echo "macOS Version: $(sw_vers -productVersion)"
        echo "================================"
        echo
        
        echo "Backup Contents:"
        echo "---------------"
        find "${BACKUP_BASE_DIR}" -type f -newer "${BACKUP_BASE_DIR}" 2>/dev/null | while read -r file; do
            local size
            size=$(stat -f%z "${file}" 2>/dev/null || echo "unknown")
            local rel_path="${file#${BACKUP_BASE_DIR}/}"
            printf "%-50s %10s bytes\n" "${rel_path}" "${size}"
        done
        
        echo
        echo "System Information:"
        echo "------------------"
        echo "Uptime: $(uptime)"
        echo "Disk Usage: $(df -h / | tail -1)"
        echo "Memory: $(vm_stat | head -5)"
        
        echo
        echo "Installed Software:"
        echo "------------------"
        if command -v brew >/dev/null 2>&1; then
            echo "Homebrew packages: $(brew list | wc -l)"
        fi
        
        if command -v npm >/dev/null 2>&1; then
            echo "Global npm packages: $(npm list -g --depth=0 2>/dev/null | grep -c '├──\\|└──' || echo 0)"
        fi
        
        echo "Applications in /Applications: $(ls /Applications | wc -l)"
        
    } > "${manifest_file}"
    
    # Create symlink to latest
    ln -sf "$(basename "${manifest_file}")" "${BACKUP_BASE_DIR}/backup-manifest-latest.txt"
    
    success "Backup manifest created: ${manifest_file}"
}

compress_backup() {
    info "Compressing backup..."
    
    local timestamp
    timestamp=$(date +%Y%m%d-%H%M%S)
    local archive_name="macos-setup-backup-${timestamp}.tar.gz"
    local archive_path="${BACKUP_BASE_DIR}/${archive_name}"
    
    cd "${BACKUP_BASE_DIR}"
    
    if tar -czf "${archive_name}" \
        --exclude="${archive_name}" \
        --exclude="*.tar.gz" \
        .; then
        
        local archive_size
        archive_size=$(stat -f%z "${archive_path}" 2>/dev/null | numfmt --to=iec)
        success "Backup compressed to ${archive_name} (${archive_size})"
        
        # Create symlink to latest
        ln -sf "${archive_name}" "macos-setup-backup-latest.tar.gz"
        
        return 0
    else
        error "Failed to compress backup"
        return 1
    fi
}

restore_homebrew_packages() {
    local brewfile="$1"
    
    info "Restoring Homebrew packages from ${brewfile}..."
    
    if [[ ! -f "${brewfile}" ]]; then
        error "Brewfile not found: ${brewfile}"
        return 1
    fi
    
    if ! command -v brew >/dev/null 2>&1; then
        error "Homebrew not installed. Please install Homebrew first."
        return 1
    fi
    
    cd "$(dirname "${brewfile}")"
    if brew bundle --file="${brewfile}"; then
        success "Homebrew packages restored successfully"
    else
        error "Some Homebrew packages failed to restore"
        return 1
    fi
}

restore_system_preferences() {
    local prefs_dir="$1"
    
    info "Restoring system preferences from ${prefs_dir}..."
    
    if [[ ! -d "${prefs_dir}" ]]; then
        error "Preferences directory not found: ${prefs_dir}"
        return 1
    fi
    
    # Restore preference files
    local restored_count=0
    for pref_file in "${prefs_dir}"/*.plist; do
        if [[ -f "${pref_file}" ]]; then
            local filename
            filename=$(basename "${pref_file}")
            local dest_path="${HOME}/Library/Preferences/${filename}"
            
            if cp "${pref_file}" "${dest_path}"; then
                ((restored_count++))
            fi
        fi
    done
    
    # Restart affected applications
    local apps_to_restart=(
        "Dock"
        "Finder"
        "SystemUIServer"
    )
    
    for app in "${apps_to_restart[@]}"; do
        if pgrep -x "${app}" >/dev/null; then
            killall "${app}" 2>/dev/null || true
        fi
    done
    
    success "System preferences restored (${restored_count} files)"
}

restore_dotfiles() {
    local dotfiles_dir="$1"
    
    info "Restoring dotfiles from ${dotfiles_dir}..."
    
    if [[ ! -d "${dotfiles_dir}" ]]; then
        error "Dotfiles directory not found: ${dotfiles_dir}"
        return 1
    fi
    
    # Restore dotfiles
    local restored_count=0
    find "${dotfiles_dir}" -type f | while read -r file; do
        local rel_path="${file#${dotfiles_dir}/}"
        local dest_path="${HOME}/${rel_path}"
        local dest_dir
        dest_dir=$(dirname "${dest_path}")
        
        mkdir -p "${dest_dir}"
        if cp "${file}" "${dest_path}"; then
            ((restored_count++))
        fi
    done
    
    success "Dotfiles restored"
}

list_backups() {
    info "Available backups:"
    echo
    
    if [[ ! -d "${BACKUP_BASE_DIR}" ]]; then
        warn "No backup directory found at ${BACKUP_BASE_DIR}"
        return 0
    fi
    
    # List compressed backups
    if ls "${BACKUP_BASE_DIR}"/*.tar.gz >/dev/null 2>&1; then
        echo "Compressed Backups:"
        ls -lh "${BACKUP_BASE_DIR}"/*.tar.gz
        echo
    fi
    
    # List configuration backups
    if [[ -d "${CONFIG_BACKUP_DIR}" ]]; then
        echo "Configuration Backups:"
        ls -la "${CONFIG_BACKUP_DIR}" | grep -E "(Brewfile|Dotfiles|Development)"
        echo
    fi
    
    # List settings backups
    if [[ -d "${SETTINGS_BACKUP_DIR}" ]]; then
        echo "Settings Backups:"
        ls -la "${SETTINGS_BACKUP_DIR}"
        echo
    fi
}

show_help() {
    cat << EOF
macOS Setup Backup and Restore Tool

Usage: ${SCRIPT_NAME} <command> [options]

Commands:
  backup              - Create full backup of system configuration
  backup-homebrew     - Backup only Homebrew packages
  backup-dotfiles     - Backup only dotfiles
  backup-prefs        - Backup only system preferences
  
  restore-homebrew <brewfile>     - Restore Homebrew packages from Brewfile
  restore-prefs <prefs_dir>       - Restore system preferences
  restore-dotfiles <dotfiles_dir> - Restore dotfiles
  
  list                - List available backups
  compress            - Compress current backup directory
  
  help                - Show this help message

Examples:
  ${SCRIPT_NAME} backup                    # Create full backup
  ${SCRIPT_NAME} restore-homebrew /path/to/Brewfile
  ${SCRIPT_NAME} list                      # Show available backups

Backup Location: ${BACKUP_BASE_DIR}
EOF
}

main() {
    local command="${1:-help}"
    
    case "${command}" in
        "backup")
            info "Creating full system backup..."
            create_backup_structure
            backup_homebrew_packages
            backup_system_preferences
            backup_dotfiles
            backup_application_settings
            backup_development_environment
            create_backup_manifest
            success "Full backup completed successfully!"
            info "Backup location: ${BACKUP_BASE_DIR}"
            ;;
            
        "backup-homebrew")
            create_backup_structure
            backup_homebrew_packages
            ;;
            
        "backup-dotfiles")
            create_backup_structure
            backup_dotfiles
            ;;
            
        "backup-prefs")
            create_backup_structure
            backup_system_preferences
            ;;
            
        "restore-homebrew")
            if [[ -n "${2:-}" ]]; then
                restore_homebrew_packages "$2"
            else
                error "Please specify Brewfile path"
                echo "Usage: ${SCRIPT_NAME} restore-homebrew <brewfile>"
                exit 1
            fi
            ;;
            
        "restore-prefs")
            if [[ -n "${2:-}" ]]; then
                restore_system_preferences "$2"
            else
                error "Please specify preferences directory"
                echo "Usage: ${SCRIPT_NAME} restore-prefs <prefs_dir>"
                exit 1
            fi
            ;;
            
        "restore-dotfiles")
            if [[ -n "${2:-}" ]]; then
                restore_dotfiles "$2"
            else
                error "Please specify dotfiles directory"
                echo "Usage: ${SCRIPT_NAME} restore-dotfiles <dotfiles_dir>"
                exit 1
            fi
            ;;
            
        "compress")
            compress_backup
            ;;
            
        "list")
            list_backups
            ;;
            
        "help"|"-h"|"--help")
            show_help
            ;;
            
        *)
            error "Unknown command: ${command}"
            echo "Run '${SCRIPT_NAME} help' for usage information"
            exit 1
            ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
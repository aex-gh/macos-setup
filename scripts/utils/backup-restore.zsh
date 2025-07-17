#!/usr/bin/env zsh

readonly SCRIPT_NAME="${0:t}"
readonly SCRIPT_DIR="${0:A:h}"

# Load common library
source "${SCRIPT_DIR}/../lib/common.zsh"

# Configuration
readonly BACKUP_BASE_DIR="${HOME}/Backups"
readonly CONFIG_BACKUP_DIR="${BACKUP_BASE_DIR}/Configurations"
readonly APP_BACKUP_DIR="${BACKUP_BASE_DIR}/Applications"
readonly SETTINGS_BACKUP_DIR="${BACKUP_BASE_DIR}/Settings"

get_timestamp() {
    date +%Y%m%d-%H%M%S
}

create_backup_structure() {
    info "Creating backup directory structure..."
    local dirs=(
        "${BACKUP_BASE_DIR}" "${CONFIG_BACKUP_DIR}" "${APP_BACKUP_DIR}"
        "${SETTINGS_BACKUP_DIR}" "${BACKUP_BASE_DIR}/Scripts" "${BACKUP_BASE_DIR}/Logs"
    )
    for dir in "${dirs[@]}"; do mkdir -p "${dir}"; done
    success "Backup directory structure created"
}

backup_homebrew_packages() {
    info "Backing up Homebrew packages..."
    check_homebrew || { warn "Homebrew not installed. Skipping backup."; return 0; }
    
    local timestamp=$(get_timestamp)
    local backup_file="${CONFIG_BACKUP_DIR}/Brewfile-${timestamp}"
    
    cd "${BACKUP_BASE_DIR}"
    if brew bundle dump --file="${backup_file}"; then
        ln -sf "$(basename "${backup_file}")" "${CONFIG_BACKUP_DIR}/Brewfile-latest"
        local formula_count=$(grep -c '^brew ' "${backup_file}" || echo 0)
        local cask_count=$(grep -c '^cask ' "${backup_file}" || echo 0)
        success "Homebrew packages backed up (${formula_count} formulae, ${cask_count} casks)"
    else
        error "Failed to backup Homebrew packages"; return 1
    fi
}

# Generic backup function for files and directories
backup_items() {
    local backup_type="$1"
    local backup_dir="$2"
    local timestamp=$(get_timestamp)
    local dest_dir="${backup_dir}/${backup_type}-${timestamp}"
    shift 2
    local items=("$@")
    
    mkdir -p "${dest_dir}"
    local count=0
    
    for item in "${items[@]}"; do
        [[ -e "${item}" ]] && cp -r "${item}" "${dest_dir}/" 2>/dev/null && ((count++))
    done
    
    ln -sf "$(basename "${dest_dir}")" "${backup_dir}/${backup_type}-latest"
    echo "${count}"
}

backup_system_preferences() {
    info "Backing up system preferences..."
    local prefs_dir="${SETTINGS_BACKUP_DIR}/SystemPreferences-$(get_timestamp)"
    mkdir -p "${prefs_dir}"
    
    local pref_files=(
        "${HOME}/Library/Preferences/com.apple.dock.plist"
        "${HOME}/Library/Preferences/com.apple.finder.plist"
        "${HOME}/Library/Preferences/com.apple.Terminal.plist"
        "${HOME}/Library/Preferences/.GlobalPreferences.plist"
    )
    
    local count=$(backup_items "SystemPreferences" "${SETTINGS_BACKUP_DIR}" "${pref_files[@]}")
    
    # Export key domains
    for domain in "com.apple.dock" "com.apple.finder" "NSGlobalDomain"; do
        defaults export "${domain}" "${prefs_dir}/${domain}.plist" 2>/dev/null || true
    done
    
    success "System preferences backed up (${count} files)"
}

backup_dotfiles() {
    info "Backing up dotfiles..."
    
    local dotfiles=(
        "${HOME}/.zshrc" "${HOME}/.bashrc" "${HOME}/.gitconfig" "${HOME}/.vimrc"
        "${HOME}/.config/zed" "${HOME}/.config/git" "${HOME}/.ssh/config"
    )
    
    local count=$(backup_items "Dotfiles" "${CONFIG_BACKUP_DIR}" "${dotfiles[@]}")
    
    # Backup chezmoi source if available
    if command_exists chezmoi; then
        local chezmoi_source=$(chezmoi source-path 2>/dev/null || echo "")
        if [[ -n "${chezmoi_source}" && -d "${chezmoi_source}" ]]; then
            local dotfiles_dir="${CONFIG_BACKUP_DIR}/Dotfiles-latest"
            cp -r "${chezmoi_source}" "${dotfiles_dir}/chezmoi-source" 2>/dev/null && ((count++))
        fi
    fi
    
    success "Dotfiles backed up (${count} items)"
}

backup_application_settings() {
    info "Backing up application settings..."
    
    local app_dirs=(
        "${HOME}/.config/zed"
        "${HOME}/Library/Application Support/com.raycast.macos"
        "${HOME}/.config/karabiner"
        "${HOME}/.ssh"
        "${HOME}/.gnupg"
    )
    
    local count=$(backup_items "AppSettings" "${APP_BACKUP_DIR}" "${app_dirs[@]}")
    success "Application settings backed up (${count} applications)"
}

backup_development_environment() {
    info "Backing up development environment..."
    local dev_backup_dir="${CONFIG_BACKUP_DIR}/Development-$(get_timestamp)"
    mkdir -p "${dev_backup_dir}"
    
    # Backup config files
    for config in "${HOME}/.npmrc" "${HOME}/.gemrc" "${HOME}/.cargo/config.toml"; do
        [[ -f "${config}" ]] && cp "${config}" "${dev_backup_dir}/" 2>/dev/null
    done
    
    # Backup package lists
    command_exists npm && npm list -g --depth=0 --json > "${dev_backup_dir}/npm-packages.json" 2>/dev/null
    command_exists pip3 && pip3 list --format=json > "${dev_backup_dir}/pip-packages.json" 2>/dev/null
    command_exists gem && gem list > "${dev_backup_dir}/gem-packages.txt" 2>/dev/null
    command_exists uv && uv tool list > "${dev_backup_dir}/uv-tools.txt" 2>/dev/null
    
    ln -sf "$(basename "${dev_backup_dir}")" "${CONFIG_BACKUP_DIR}/Development-latest"
    success "Development environment backed up"
}

create_backup_manifest() {
    info "Creating backup manifest..."
    local manifest_file="${BACKUP_BASE_DIR}/backup-manifest-$(get_timestamp).txt"
    
    {
        echo "Backup Manifest - Generated: $(date)"
        echo "Hostname: $(hostname) | macOS: $(sw_vers -productVersion)"
        echo "======================================================="
        echo "Backup Contents:"
        find "${BACKUP_BASE_DIR}" -type f -newer "${BACKUP_BASE_DIR}" 2>/dev/null | while read -r file; do
            printf "%-50s %10s bytes\n" "${file#${BACKUP_BASE_DIR}/}" "$(stat -f%z "${file}" 2>/dev/null || echo "unknown")"
        done
        echo "System: $(uptime | cut -d' ' -f1,3-5)"
        echo "Disk: $(df -h / | tail -1 | awk '{print $4" available"}')"
        command_exists brew && echo "Homebrew packages: $(brew list | wc -l)"
        command_exists npm && echo "NPM packages: $(npm list -g --depth=0 2>/dev/null | grep -c '├──\\|└──' || echo 0)"
        echo "Applications: $(ls /Applications | wc -l)"
    } > "${manifest_file}"
    
    ln -sf "$(basename "${manifest_file}")" "${BACKUP_BASE_DIR}/backup-manifest-latest.txt"
    success "Backup manifest created"
}

compress_backup() {
    info "Compressing backup..."
    local archive_name="macos-setup-backup-$(get_timestamp).tar.gz"
    
    cd "${BACKUP_BASE_DIR}"
    if tar -czf "${archive_name}" --exclude="*.tar.gz" .; then
        local size=$(stat -f%z "${BACKUP_BASE_DIR}/${archive_name}" 2>/dev/null | numfmt --to=iec 2>/dev/null || echo "unknown")
        ln -sf "${archive_name}" "macos-setup-backup-latest.tar.gz"
        success "Backup compressed to ${archive_name} (${size})"
    else
        error "Failed to compress backup"; return 1
    fi
}

# Generic restore function
restore_files() {
    local source_dir="$1"
    local dest_base="${2:-${HOME}}"
    [[ ! -d "${source_dir}" ]] && { error "Source directory not found: ${source_dir}"; return 1; }
    
    local count=0
    find "${source_dir}" -type f | while read -r file; do
        local rel_path="${file#${source_dir}/}"
        local dest_path="${dest_base}/${rel_path}"
        mkdir -p "$(dirname "${dest_path}")"
        cp "${file}" "${dest_path}" 2>/dev/null && ((count++))
    done
    echo "${count}"
}

restore_homebrew_packages() {
    local brewfile="$1"
    info "Restoring Homebrew packages from ${brewfile}..."
    [[ ! -f "${brewfile}" ]] && { error "Brewfile not found: ${brewfile}"; return 1; }
    check_homebrew || { error "Homebrew not installed"; return 1; }
    
    cd "$(dirname "${brewfile}")"
    if brew bundle --file="${brewfile}"; then
        success "Homebrew packages restored"
    else
        error "Some packages failed to restore"; return 1
    fi
}

restore_system_preferences() {
    local prefs_dir="$1"
    info "Restoring system preferences from ${prefs_dir}..."
    
    local count=$(restore_files "${prefs_dir}" "${HOME}/Library/Preferences")
    
    # Restart system apps
    for app in "Dock" "Finder" "SystemUIServer"; do
        pgrep -x "${app}" >/dev/null && killall "${app}" 2>/dev/null || true
    done
    
    success "System preferences restored (${count} files)"
}

restore_dotfiles() {
    local dotfiles_dir="$1"
    info "Restoring dotfiles from ${dotfiles_dir}..."
    local count=$(restore_files "${dotfiles_dir}")
    success "Dotfiles restored (${count} files)"
}

list_backups() {
    info "Available backups:"
    [[ ! -d "${BACKUP_BASE_DIR}" ]] && { warn "No backup directory found"; return 0; }
    
    echo "\nCompressed Backups:"
    ls -lh "${BACKUP_BASE_DIR}"/*.tar.gz 2>/dev/null || echo "None found"
    
    echo "\nConfiguration Backups:"
    [[ -d "${CONFIG_BACKUP_DIR}" ]] && ls -la "${CONFIG_BACKUP_DIR}" | grep -E "(Brewfile|Dotfiles|Development)" || echo "None found"
    
    echo "\nSettings Backups:"
    [[ -d "${SETTINGS_BACKUP_DIR}" ]] && ls -la "${SETTINGS_BACKUP_DIR}" || echo "None found"
}

show_help() {
    cat << EOF
macOS Backup and Restore Tool

Usage: ${SCRIPT_NAME} <command> [args]

Commands:
  backup                          - Full system backup
  backup-homebrew|backup-dotfiles|backup-prefs - Partial backups
  restore-homebrew <brewfile>     - Restore Homebrew packages
  restore-prefs <dir>             - Restore system preferences  
  restore-dotfiles <dir>          - Restore dotfiles
  list                            - List available backups
  compress                        - Compress backup directory

Backup Location: ${BACKUP_BASE_DIR}
EOF
}

main() {
    local command="${1:-help}"
    
    case "${command}" in
        backup)
            header "Creating full system backup..."
            create_backup_structure
            backup_homebrew_packages
            backup_system_preferences
            backup_dotfiles
            backup_application_settings
            backup_development_environment
            create_backup_manifest
            success "Full backup completed! Location: ${BACKUP_BASE_DIR}"
            ;;
        backup-homebrew) create_backup_structure; backup_homebrew_packages ;;
        backup-dotfiles) create_backup_structure; backup_dotfiles ;;
        backup-prefs) create_backup_structure; backup_system_preferences ;;
        restore-homebrew) [[ -n "${2:-}" ]] && restore_homebrew_packages "$2" || { error "Specify Brewfile path"; exit 1; } ;;
        restore-prefs) [[ -n "${2:-}" ]] && restore_system_preferences "$2" || { error "Specify preferences directory"; exit 1; } ;;
        restore-dotfiles) [[ -n "${2:-}" ]] && restore_dotfiles "$2" || { error "Specify dotfiles directory"; exit 1; } ;;
        compress) compress_backup ;;
        list) list_backups ;;
        help|-h|--help) show_help ;;
        *) error "Unknown command: ${command}"; echo "Run '${SCRIPT_NAME} help' for usage"; exit 1 ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
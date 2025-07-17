#!/usr/bin/env zsh
set -euo pipefail

# Script metadata
readonly SCRIPT_NAME="${0:t}"
readonly SCRIPT_DIR="${0:A:h}"

# Load common library
source "${SCRIPT_DIR}/../lib/common.zsh"

# Note: Cleanup is handled by common library

check_prerequisites() {
    info "Checking prerequisites..."

    if ! command -v chezmoi >/dev/null 2>&1; then
        error "chezmoi is not installed. Please install it first with: brew install chezmoi"
        exit 1
    fi

    if ! command -v git >/dev/null 2>&1; then
        error "git is not installed. Please install it first."
        exit 1
    fi

    success "Prerequisites check passed"
}

initialise_chezmoi() {
    info "Initialising chezmoi..."

    local dotfiles_repo="https://github.com/andrewjamesexley/dotfiles.git"
    local source_dir="${PWD}/dotfiles"

    # Check if chezmoi is already initialised
    if chezmoi source-path >/dev/null 2>&1; then
        warn "chezmoi is already initialised"
        local current_source
        current_source=$(chezmoi source-path)
        info "Current source directory: ${current_source}"
        return 0
    fi

    # Use local dotfiles directory if it exists, otherwise clone from repo
    if [[ -d "${source_dir}" ]]; then
        info "Using local dotfiles directory: ${source_dir}"
        chezmoi init --source="${source_dir}"
    else
        # For now, init with local directory - in future this could be a repo
        warn "No dotfiles directory found. Creating minimal setup..."
        chezmoi init

        # Copy our dotfiles to chezmoi source
        local chezmoi_source
        chezmoi_source=$(chezmoi source-path)
        if [[ -d "${source_dir}" ]]; then
            cp -r "${source_dir}"/* "${chezmoi_source}/"
            info "Copied local dotfiles to chezmoi source"
        fi
    fi

    success "chezmoi initialised successfully"
}

setup_git_repo() {
    info "Setting up dotfiles git repository..."

    local source_path
    source_path=$(chezmoi source-path)

    if [[ ! -d "${source_path}" ]]; then
        error "chezmoi source path not found: ${source_path}"
        exit 1
    fi

    cd "${source_path}"

    # Initialise git repo if not already done
    if [[ ! -d ".git" ]]; then
        git init
        git branch -M main
        success "Initialised git repository in dotfiles"
    fi

    # Add all files
    git add .

    # Commit if there are changes
    if ! git diff --staged --quiet; then
        git commit -m "Initial dotfiles setup

- chezmoi configuration templates
- Device-specific zsh and git configs
- Zed editor configuration
- Gruvbox theme integration
- Australian locale settings

"
        success "Committed dotfiles changes"
    else
        info "No changes to commit"
    fi

    cd - >/dev/null
}

configure_auto_sync() {
    info "Configuring automatic dotfiles synchronisation..."

    # Create launchd plist for automatic sync
    local plist_dir="${HOME}/Library/LaunchAgents"
    local plist_file="${plist_dir}/net.exley.chezmoi-sync.plist"

    mkdir -p "${plist_dir}"

    cat > "${plist_file}" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>net.exley.chezmoi-sync</string>
    <key>ProgramArguments</key>
    <array>
        <string>/opt/homebrew/bin/chezmoi</string>
        <string>apply</string>
        <string>--force</string>
    </array>
    <key>StartInterval</key>
    <integer>3600</integer>
    <key>RunAtLoad</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/chezmoi-sync.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/chezmoi-sync.error.log</string>
</dict>
</plist>
EOF

    # Load the launch agent
    launchctl load "${plist_file}" 2>/dev/null || true

    success "Configured automatic chezmoi sync (hourly)"
    info "Logs will be written to /tmp/chezmoi-sync.log"
}

apply_dotfiles() {
    info "Applying dotfiles..."

    # Apply dotfiles with chezmoi
    if chezmoi apply --dry-run; then
        chezmoi apply
        success "Dotfiles applied successfully"
    else
        error "Dry run failed. Please check your dotfiles for errors."
        exit 1
    fi
}

main() {
    info "Starting dotfiles setup..."

    check_prerequisites
    initialise_chezmoi
    setup_git_repo
    configure_auto_sync
    apply_dotfiles

    success "Dotfiles setup complete!"
    info "Your dotfiles are now managed by chezmoi"
    info "Use 'chezmoi edit <file>' to modify dotfiles"
    info "Use 'chezmoi apply' to apply changes"
    info "Use 'chezmoi status' to see what would change"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

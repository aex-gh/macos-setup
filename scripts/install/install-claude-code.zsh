#!/usr/bin/env zsh

readonly SCRIPT_NAME="${0:t}"
readonly SCRIPT_DIR="${0:A:h}"

source "${SCRIPT_DIR}/../lib/common.zsh"

check_prerequisites() {
    info "Checking prerequisites for Claude Code installation..."
    check_requirements npm node
    local node_version
    node_version=$(node --version | sed 's/v//')
    local required_version="18.0.0"
    if ! is_version_gte "$node_version" "$required_version"; then
        error "Node.js version ${required_version} or higher is required. Current version: ${node_version}"
        return 1
    fi
    success "Prerequisites check passed"
}

install_claude_code() {
    info "Installing Claude Code CLI..."
    if command_exists claude-code; then
        local current_version
        current_version=$(claude-code --version 2>/dev/null || echo "unknown")
        info "Claude Code is already installed (version: ${current_version})"
        read -q "REPLY?Update Claude Code to latest version? (y/n): "
        echo
        [[ "${REPLY}" != "y" ]] && return 0
    fi
    info "Installing Claude Code globally via npm..."
    if npm install -g @anthropic/claude-code; then
        success "Claude Code installed successfully"
    else
        warn "npm installation failed. Attempting direct download..."
        install_claude_code_direct
    fi
}

install_claude_code_direct() {
    info "Installing Claude Code using direct download..."
    local install_dir="${HOME}/.local/bin"
    local claude_binary="${install_dir}/claude-code"
    mkdir -p "${install_dir}"
    local arch
    arch=$(uname -m)
    case "${arch}" in
        arm64|aarch64) arch="arm64" ;;
        x86_64) arch="x64" ;;
        *) error "Unsupported architecture: ${arch}"; return 1 ;;
    esac
    local download_url="https://github.com/anthropics/claude-code/releases/latest/download/claude-code-macos-${arch}"
    info "Downloading Claude Code for macOS ${arch}..."
    if curl -L -o "${claude_binary}" "${download_url}"; then
        chmod +x "${claude_binary}"
        success "Claude Code installed to ${claude_binary}"
        if [[ ":${PATH}:" != *":${install_dir}:"* ]]; then
            echo "export PATH=\"${install_dir}:\${PATH}\"" >> "${HOME}/.zshrc"
            export PATH="${install_dir}:${PATH}"
        fi
    else
        error "Failed to download Claude Code binary"
        return 1
    fi
}

configure_claude_code() {
    info "Configuring Claude Code..."
    local config_dir="${HOME}/.config/claude-code"
    local config_file="${config_dir}/config.json"
    mkdir -p "${config_dir}"
    cat > "${config_file}" << 'EOF'
{
  "apiKey": "",
  "defaultModel": "claude-3-5-sonnet-20241022",
  "maxTokens": 4096,
  "temperature": 0.7,
  "editor": "zed",
  "theme": "gruvbox-dark",
  "features": { "mcp": true, "codeExecution": true, "fileOperations": true },
  "mcp": { "servers": {} },
  "workspace": {
    "autoSave": true,
    "excludePatterns": ["node_modules/**", ".git/**", "*.log", ".DS_Store"]
  }
}
EOF
    success "Created Claude Code configuration at ${config_file}"
    setup_api_key
}

setup_api_key() {
    info "Setting up Anthropic API key..."
    if command_exists op; then
        local api_key
        if api_key=$(op read "op://Personal/Anthropic-API-Key/credential" 2>/dev/null); then
            local config_file="${HOME}/.config/claude-code/config.json"
            if [[ -f "${config_file}" ]] && command_exists jq; then
                jq --arg key "${api_key}" '.apiKey = $key' "${config_file}" > "${config_file}.tmp" && mv "${config_file}.tmp" "${config_file}"
                success "API key configured from 1Password"
            else
                warn "jq not available. Please manually add API key to ${config_file}"
            fi
        else
            warn "Could not retrieve API key from 1Password"
        fi
    else
        warn "1Password CLI not available"
        info "Please manually configure your API key in ${HOME}/.config/claude-code/config.json"
    fi
}

create_claude_code_wrapper() {
    info "Creating Claude Code wrapper script..."
    local wrapper_script="${HOME}/.local/bin/claude"
    cat > "${wrapper_script}" << 'EOF'
#!/usr/bin/env zsh
set -euo pipefail
export LANG="en_AU.UTF-8"
export LC_ALL="en_AU.UTF-8"
export TZ="Australia/Adelaide"
command -v claude-code >/dev/null 2>&1 || { echo "Error: claude-code not found in PATH" >&2; exit 1; }
case "${1:-}" in
    "chat"|"c") shift; exec claude-code chat "$@" ;;
    "code"|"edit") shift; exec claude-code edit "$@" ;;
    "config"|"cfg") shift; exec claude-code config "$@" ;;
    "help"|"h"|"-h"|"--help")
        echo "Claude Code Wrapper - Shortcuts:"
        echo "  claude chat|c    - Start interactive chat"
        echo "  claude code|edit - Edit files with Claude"
        echo "  claude config|cfg - Manage configuration"
        echo "  claude help|h    - Show this help"
        echo ""
        exec claude-code --help
        ;;
    *) exec claude-code "$@" ;;
esac
EOF
    chmod +x "${wrapper_script}"
    success "Created Claude Code wrapper at ${wrapper_script}"
}

verify_installation() {
    info "Verifying Claude Code installation..."
    if command_exists claude-code; then
        local version
        version=$(claude-code --version 2>/dev/null || echo "unknown")
        success "Claude Code is installed and accessible (version: ${version})"
    else
        error "Claude Code is not accessible via PATH"
        return 1
    fi
    local config_file="${HOME}/.config/claude-code/config.json"
    if file_readable "${config_file}"; then
        success "Configuration file exists: ${config_file}"
    else
        warn "Configuration file not found: ${config_file}"
    fi
    if command_exists claude; then
        success "Claude wrapper script is accessible"
    else
        warn "Claude wrapper script is not in PATH"
    fi
}

main() {
    header "Starting Claude Code installation..."
    check_prerequisites
    install_claude_code
    configure_claude_code
    create_claude_code_wrapper
    verify_installation
    success "Claude Code installation complete!"
    info "You can now use 'claude-code' or the 'claude' wrapper"
    info "Configuration: ${HOME}/.config/claude-code/config.json"
    info "Run 'claude help' for usage information"
    local config_file="${HOME}/.config/claude-code/config.json"
    if [[ ! -f "${config_file}" ]] || ! grep -q '"apiKey": "[^"]' "${config_file}"; then
        warn "Remember to configure your Anthropic API key before using Claude Code"
    fi
    notify "Claude Code Installation" "Installation completed successfully"
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && main "$@"
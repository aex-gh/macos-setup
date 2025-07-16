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

check_prerequisites() {
    info "Checking prerequisites for Claude Code installation..."
    
    # Check for npm/node
    if ! command -v npm >/dev/null 2>&1; then
        error "npm is required for Claude Code installation. Please install Node.js first."
        exit 1
    fi
    
    # Check Node.js version
    local node_version
    node_version=$(node --version | sed 's/v//')
    local required_version="18.0.0"
    
    if ! printf '%s\n%s\n' "${required_version}" "${node_version}" | sort -V -C; then
        error "Node.js version ${required_version} or higher is required. Current version: ${node_version}"
        exit 1
    fi
    
    success "Prerequisites check passed"
}

install_claude_code() {
    info "Installing Claude Code CLI..."
    
    # Check if Claude Code is already installed
    if command -v claude-code >/dev/null 2>&1; then
        local current_version
        current_version=$(claude-code --version 2>/dev/null || echo "unknown")
        info "Claude Code is already installed (version: ${current_version})"
        
        # Ask if user wants to update
        read -q "REPLY?Update Claude Code to latest version? (y/n): "
        echo
        if [[ "${REPLY}" != "y" ]]; then
            info "Skipping Claude Code installation"
            return 0
        fi
    fi
    
    # Install via npm
    info "Installing Claude Code globally via npm..."
    if npm install -g @anthropic/claude-code; then
        success "Claude Code installed successfully"
    else
        error "Failed to install Claude Code via npm"
        
        # Try alternative installation method using curl
        warn "Attempting alternative installation method..."
        install_claude_code_direct
    fi
}

install_claude_code_direct() {
    info "Installing Claude Code using direct download..."
    
    local install_dir="${HOME}/.local/bin"
    local claude_binary="${install_dir}/claude-code"
    
    # Create installation directory
    mkdir -p "${install_dir}"
    
    # Determine architecture
    local arch
    arch=$(uname -m)
    case "${arch}" in
        arm64|aarch64)
            arch="arm64"
            ;;
        x86_64)
            arch="x64"
            ;;
        *)
            error "Unsupported architecture: ${arch}"
            exit 1
            ;;
    esac
    
    # Download Claude Code binary
    local download_url="https://github.com/anthropics/claude-code/releases/latest/download/claude-code-macos-${arch}"
    
    info "Downloading Claude Code for macOS ${arch}..."
    if curl -L -o "${claude_binary}" "${download_url}"; then
        chmod +x "${claude_binary}"
        success "Claude Code installed to ${claude_binary}"
        
        # Add to PATH if not already there
        if [[ ":${PATH}:" != *":${install_dir}:"* ]]; then
            info "Adding ${install_dir} to PATH in shell configuration"
            echo "export PATH=\"${install_dir}:\${PATH}\"" >> "${HOME}/.zshrc"
            export PATH="${install_dir}:${PATH}"
        fi
    else
        error "Failed to download Claude Code binary"
        exit 1
    fi
}

configure_claude_code() {
    info "Configuring Claude Code..."
    
    local config_dir="${HOME}/.config/claude-code"
    local config_file="${config_dir}/config.json"
    
    # Create config directory
    mkdir -p "${config_dir}"
    
    # Create default configuration
    cat > "${config_file}" << 'EOF'
{
  "apiKey": "",
  "defaultModel": "claude-3-5-sonnet-20241022",
  "maxTokens": 4096,
  "temperature": 0.7,
  "editor": "zed",
  "theme": "gruvbox-dark",
  "features": {
    "mcp": true,
    "codeExecution": true,
    "fileOperations": true
  },
  "mcp": {
    "servers": {}
  },
  "workspace": {
    "autoSave": true,
    "excludePatterns": [
      "node_modules/**",
      ".git/**",
      "*.log",
      ".DS_Store"
    ]
  }
}
EOF
    
    success "Created Claude Code configuration"
    info "Configuration file: ${config_file}"
    
    # Set up API key from 1Password if available
    setup_api_key
}

setup_api_key() {
    info "Setting up Anthropic API key..."
    
    if command -v op >/dev/null 2>&1; then
        # Try to get API key from 1Password
        local api_key
        if api_key=$(op read "op://Personal/Anthropic-API-Key/credential" 2>/dev/null); then
            # Update config with API key
            local config_file="${HOME}/.config/claude-code/config.json"
            if [[ -f "${config_file}" ]]; then
                # Use jq to update the API key if available
                if command -v jq >/dev/null 2>&1; then
                    jq --arg key "${api_key}" '.apiKey = $key' "${config_file}" > "${config_file}.tmp" && mv "${config_file}.tmp" "${config_file}"
                    success "API key configured from 1Password"
                else
                    warn "jq not available. Please manually add API key to ${config_file}"
                fi
            fi
        else
            warn "Could not retrieve API key from 1Password"
            info "Please store your Anthropic API key in 1Password as 'Anthropic-API-Key'"
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
# Claude Code wrapper script
# Provides shortcuts and Australian locale settings

set -euo pipefail

# Set Australian locale
export LANG="en_AU.UTF-8"
export LC_ALL="en_AU.UTF-8"
export TZ="Australia/Adelaide"

# Check if claude-code is available
if ! command -v claude-code >/dev/null 2>&1; then
    echo "Error: claude-code not found in PATH" >&2
    exit 1
fi

# Common shortcuts
case "${1:-}" in
    "chat"|"c")
        shift
        exec claude-code chat "$@"
        ;;
    "code"|"edit")
        shift
        exec claude-code edit "$@"
        ;;
    "config"|"cfg")
        shift
        exec claude-code config "$@"
        ;;
    "help"|"h"|"-h"|"--help")
        echo "Claude Code Wrapper"
        echo "Shortcuts:"
        echo "  claude chat|c    - Start interactive chat"
        echo "  claude code|edit - Edit files with Claude"
        echo "  claude config|cfg - Manage configuration"
        echo "  claude help|h    - Show this help"
        echo ""
        echo "Full claude-code help:"
        exec claude-code --help
        ;;
    *)
        # Pass through to claude-code
        exec claude-code "$@"
        ;;
esac
EOF
    
    chmod +x "${wrapper_script}"
    success "Created Claude Code wrapper at ${wrapper_script}"
}

verify_installation() {
    info "Verifying Claude Code installation..."
    
    # Check if claude-code is available
    if command -v claude-code >/dev/null 2>&1; then
        local version
        version=$(claude-code --version 2>/dev/null || echo "unknown")
        success "Claude Code is installed and accessible (version: ${version})"
    else
        error "Claude Code is not accessible via PATH"
        return 1
    fi
    
    # Check configuration
    local config_file="${HOME}/.config/claude-code/config.json"
    if [[ -f "${config_file}" ]]; then
        success "Configuration file exists: ${config_file}"
    else
        warn "Configuration file not found: ${config_file}"
    fi
    
    # Check wrapper script
    if command -v claude >/dev/null 2>&1; then
        success "Claude wrapper script is accessible"
    else
        warn "Claude wrapper script is not in PATH"
    fi
}

main() {
    info "Starting Claude Code installation..."
    
    check_prerequisites
    install_claude_code
    configure_claude_code
    create_claude_code_wrapper
    verify_installation
    
    success "Claude Code installation complete!"
    info "You can now use 'claude-code' or the 'claude' wrapper"
    info "Configuration: ${HOME}/.config/claude-code/config.json"
    info "Run 'claude help' for usage information"
    
    if [[ ! -f "${HOME}/.config/claude-code/config.json" ]] || ! grep -q '"apiKey": "[^"]' "${HOME}/.config/claude-code/config.json"; then
        warn "Remember to configure your Anthropic API key before using Claude Code"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
#!/usr/bin/env zsh

# Script metadata
readonly SCRIPT_NAME="${0:t}"
readonly SCRIPT_DIR="${0:A:h}"

# Load common library
source "${SCRIPT_DIR}/../lib/common.zsh"

check_prerequisites() {
    info "Checking prerequisites for MCP server setup..."
    
    # Check for npm/node
    if ! command_exists npm; then
        error "npm is required for MCP server installation. Please install Node.js first."
        exit 1
    fi
    
    # Check for Python (required for some MCP servers)
    if ! command_exists python3; then
        error "Python 3 is required for some MCP servers. Please install Python first."
        exit 1
    fi
    
    # Check for uv (Python package manager)
    if ! command_exists uv; then
        warn "uv not found. Some Python MCP servers may not install correctly."
    fi
    
    success "Prerequisites check passed"
}

create_mcp_config_directory() {
    info "Creating MCP configuration directory..."
    
    local mcp_dir="${HOME}/.config/mcp"
    create_directory "${mcp_dir}/servers" 755
    
    # Create global MCP configuration
    cat > "${mcp_dir}/config.json" << 'EOF'
{
  "mcpServers": {},
  "globalSettings": {
    "timeout": 30000,
    "retryAttempts": 3,
    "logLevel": "info",
    "logFile": "~/.config/mcp/mcp.log"
  }
}
EOF
    
    success "MCP configuration directory created at ${mcp_dir}"
}

install_filesystem_server() {
    info "Installing filesystem MCP server..."
    
    local server_name="filesystem"
    local package_name="@modelcontextprotocol/server-filesystem"
    
    # Install via npm
    if npm install -g "${package_name}"; then
        success "Filesystem server installed"
        
        # Add to MCP configuration
        add_server_to_config "${server_name}" "node" "$(npm root -g)/${package_name}/dist/index.js" '{
            "allowedDirectories": [
                "~/Documents",
                "~/Projects",
                "~/Desktop",
                "/Users/Shared"
            ]
        }'
    else
        error "Failed to install filesystem server"
    fi
}

install_github_server() {
    info "Installing GitHub MCP server..."
    
    local server_name="github"
    local package_name="@modelcontextprotocol/server-github"
    
    # Install via npm
    if npm install -g "${package_name}"; then
        success "GitHub server installed"
        
        # Add to MCP configuration
        add_server_to_config "${server_name}" "node" "$(npm root -g)/${package_name}/dist/index.js" '{
            "personalAccessToken": "",
            "githubApiUrl": "https://api.github.com"
        }'
        
        warn "Remember to configure your GitHub personal access token"
    else
        error "Failed to install GitHub server"
    fi
}

install_markitdown_server() {
    info "Installing MarkItDown MCP server..."
    
    local server_name="markitdown"
    local package_name="@microsoft/markitdown-mcp"
    
    # Try npm installation first
    if npm install -g "${package_name}" 2>/dev/null; then
        success "MarkItDown server installed via npm"
        add_server_to_config "${server_name}" "node" "$(npm root -g)/${package_name}/dist/index.js" '{}'
    else
        warn "npm installation failed, trying alternative method..."
        
        # Alternative: install via uv if available
        if command_exists uv; then
            if uv tool install markitdown; then
                success "MarkItDown installed via uv"
                add_server_to_config "${server_name}" "uv" "tool" "run markitdown-mcp" '{}'
            else
                error "Failed to install MarkItDown server"
            fi
        else
            error "Could not install MarkItDown server (npm and uv both failed)"
        fi
    fi
}

install_context7_server() {
    info "Installing Context7 MCP server..."
    
    local server_name="context7"
    local package_name="@upstash/context7-mcp"
    
    # Install via npm
    if npm install -g "${package_name}"; then
        success "Context7 server installed"
        
        # Add to MCP configuration
        add_server_to_config "${server_name}" "node" "$(npm root -g)/${package_name}/dist/index.js" '{
            "upstashRedisUrl": "",
            "upstashRedisToken": "",
            "contextSize": 10000
        }'
        
        warn "Remember to configure your Upstash Redis credentials"
    else
        warn "Context7 server installation failed (may not be publicly available yet)"
    fi
}

install_memory_bank_server() {
    info "Installing Memory Bank MCP server..."
    
    local server_name="memory-bank"
    local package_name="@alioshr/memory-bank-mcp"
    
    # Install via npm
    if npm install -g "${package_name}"; then
        success "Memory Bank server installed"
        
        # Add to MCP configuration
        add_server_to_config "${server_name}" "node" "$(npm root -g)/${package_name}/dist/index.js" '{
            "storageDirectory": "~/.config/mcp/memory-bank",
            "maxMemories": 1000
        }'
    else
        warn "Memory Bank server installation failed (may not be publicly available yet)"
    fi
}

install_desktop_commander_server() {
    info "Installing Desktop Commander MCP server..."
    
    local server_name="desktop-commander"
    local package_name="@wonderwhy-er/desktop-commander-mcp"
    
    # Install via npm
    if npm install -g "${package_name}"; then
        success "Desktop Commander server installed"
        
        # Add to MCP configuration
        add_server_to_config "${server_name}" "node" "$(npm root -g)/${package_name}/dist/index.js" '{
            "allowedApplications": [
                "Finder",
                "Terminal",
                "Zed",
                "Safari"
            ],
            "safeMode": true
        }'
    else
        warn "Desktop Commander server installation failed (may not be publicly available yet)"
    fi
}

add_server_to_config() {
    local name="$1"
    local command="$2"
    local script_path="$3"
    local env_config="$4"
    
    local config_file="${HOME}/.config/mcp/config.json"
    
    # Create server configuration
    local server_config
    if [[ "${command}" == "uv" ]]; then
        server_config=$(cat << EOF
{
  "command": "uv",
  "args": ["${script_path}"],
  "env": ${env_config}
}
EOF
)
    else
        server_config=$(cat << EOF
{
  "command": "node",
  "args": ["${script_path}"],
  "env": ${env_config}
}
EOF
)
    fi
    
    # Use jq to add server if available, otherwise manual JSON manipulation
    if command_exists jq; then
        local temp_config
        temp_config=$(mktemp)
        jq --arg name "${name}" --argjson config "${server_config}" \
           '.mcpServers[$name] = $config' "${config_file}" > "${temp_config}"
        mv "${temp_config}" "${config_file}"
        info "Added ${name} server to MCP configuration"
    else
        warn "jq not available. Please manually add ${name} server to ${config_file}"
    fi
}

configure_claude_code_mcp() {
    info "Configuring Claude Code MCP integration..."
    
    local claude_config="${HOME}/.config/claude-code/config.json"
    local mcp_config="${HOME}/.config/mcp/config.json"
    
    if [[ ! -f "${claude_config}" ]]; then
        warn "Claude Code config not found. Please run install-claude-code.zsh first."
        return 1
    fi
    
    if [[ ! -f "${mcp_config}" ]]; then
        error "MCP config not found"
        return 1
    fi
    
    # Use jq to merge MCP servers into Claude Code config
    if command_exists jq; then
        local mcp_servers
        mcp_servers=$(jq '.mcpServers' "${mcp_config}")
        
        local temp_config
        temp_config=$(mktemp)
        jq --argjson servers "${mcp_servers}" '.mcp.servers = $servers' "${claude_config}" > "${temp_config}"
        mv "${temp_config}" "${claude_config}"
        
        success "MCP servers configured in Claude Code"
    else
        warn "jq not available. Please manually merge MCP configuration"
    fi
}

create_mcp_management_script() {
    info "Creating MCP management script..."
    
    local script_path="${HOME}/.local/bin/mcp-manager"
    
    cat > "${script_path}" << 'EOF'
#!/usr/bin/env zsh
# MCP Server Management Script

# Load common library
readonly SCRIPT_DIR="${0:A:h}/.."
source "${SCRIPT_DIR}/scripts/lib/common.zsh"

CONFIG_FILE="${HOME}/.config/mcp/config.json"

list_servers() {
    info "Configured MCP servers:"
    if [[ -f "${CONFIG_FILE}" ]] && command_exists jq; then
        jq -r '.mcpServers | keys[]' "${CONFIG_FILE}" 2>/dev/null || echo "No servers configured"
    else
        warn "Cannot list servers (config file or jq missing)"
    fi
}

test_server() {
    local server_name="$1"
    info "Testing MCP server: ${server_name}"
    
    if [[ -f "${CONFIG_FILE}" ]] && command_exists jq; then
        local server_config
        server_config=$(jq -r ".mcpServers[\"${server_name}\"]" "${CONFIG_FILE}")
        
        if [[ "${server_config}" == "null" ]]; then
            error "Server ${server_name} not found in configuration"
            return 1
        fi
        
        local command
        command=$(echo "${server_config}" | jq -r '.command')
        local args
        args=$(echo "${server_config}" | jq -r '.args[]')
        
        info "Testing: ${command} ${args}"
        if "${command}" ${args} --version 2>/dev/null || "${command}" ${args} --help 2>/dev/null; then
            success "Server ${server_name} appears to be working"
        else
            error "Server ${server_name} test failed"
        fi
    else
        error "Cannot test server (config file or jq missing)"
    fi
}

show_config() {
    if [[ -f "${CONFIG_FILE}" ]]; then
        info "MCP configuration:"
        cat "${CONFIG_FILE}"
    else
        error "Configuration file not found: ${CONFIG_FILE}"
    fi
}

case "${1:-}" in
    "list"|"ls")
        list_servers
        ;;
    "test")
        if [[ -n "${2:-}" ]]; then
            test_server "$2"
        else
            error "Usage: mcp-manager test <server-name>"
        fi
        ;;
    "config"|"show")
        show_config
        ;;
    "help"|"-h"|"--help")
        echo "MCP Server Manager"
        echo "Usage: mcp-manager <command> [args]"
        echo ""
        echo "Commands:"
        echo "  list, ls          - List configured servers"
        echo "  test <server>     - Test a specific server"
        echo "  config, show      - Show current configuration"
        echo "  help              - Show this help"
        ;;
    *)
        error "Unknown command: ${1:-}"
        echo "Run 'mcp-manager help' for usage information"
        exit 1
        ;;
esac
EOF
    
    chmod +x "${script_path}"
    success "Created MCP management script at ${script_path}"
}

verify_installation() {
    info "Verifying MCP server installation..."
    
    local config_file="${HOME}/.config/mcp/config.json"
    if [[ -f "${config_file}" ]]; then
        success "MCP configuration file exists"
        
        if command_exists jq; then
            local server_count
            server_count=$(jq '.mcpServers | length' "${config_file}")
            info "Configured servers: ${server_count}"
            
            if [[ ${server_count} -gt 0 ]]; then
                success "MCP servers are configured"
            else
                warn "No MCP servers configured"
            fi
        fi
    else
        error "MCP configuration file not found"
    fi
    
    # Check if mcp-manager is available
    if command_exists mcp-manager; then
        success "MCP manager script is accessible"
    else
        warn "MCP manager script not in PATH"
    fi
}

main() {
    info "Starting MCP server setup..."
    
    check_prerequisites
    create_mcp_config_directory
    
    # Install available MCP servers
    install_filesystem_server
    install_github_server
    install_markitdown_server
    install_context7_server
    install_memory_bank_server
    install_desktop_commander_server
    
    configure_claude_code_mcp
    create_mcp_management_script
    verify_installation
    
    success "MCP server setup complete!"
    info "Use 'mcp-manager list' to see configured servers"
    info "Configuration: ${HOME}/.config/mcp/config.json"
    
    warn "Remember to configure API tokens and credentials for servers that require them"
    info "Check the configuration file for servers marked with empty credentials"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
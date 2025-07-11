#!/usr/bin/env zsh
# ABOUTME: Standalone Claude Code installation script for macOS systems
# ABOUTME: Installs Claude Code with all dependencies and configures dotfiles integration

set -euo pipefail

# Script configuration
readonly SCRIPT_NAME="${0:t}"
readonly SCRIPT_DIR="${0:A:h}"
readonly SCRIPT_VERSION="1.0.0"
readonly DOTFILES_DIR="${SCRIPT_DIR}/../dotfiles"

# Required Node.js version
readonly NODE_MIN_VERSION="18"

# MCP server configuration
readonly MCP_CONFIG_DIR="$HOME/.claude"
readonly MCP_CONFIG_FILE="$MCP_CONFIG_DIR/claude_desktop_config.json"
readonly MCP_SERVERS_CONFIG="${SCRIPT_DIR}/../configs/claude/mcp-servers.json"
readonly MCP_TEMPLATE_FILE="${SCRIPT_DIR}/../configs/claude/claude_desktop_config.json.template"

# Colour codes
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly BOLD='\033[1m'
readonly RESET='\033[0m'

# Global variables
declare -g VERBOSE=false
declare -g SKIP_DOTFILES=false
declare -g FORCE_REINSTALL=false
declare -g SKIP_MCP=false
declare -g INSTALL_OPTIONAL_MCP=false

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${RESET} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${RESET} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARNING]${RESET} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${RESET} $*"
}

log_debug() {
    [[ $VERBOSE == true ]] && echo -e "${BLUE}[DEBUG]${RESET} $*"
}

# Display usage information
usage() {
    cat << EOF
${BOLD}NAME${RESET}
    $SCRIPT_NAME - Install Claude Code on macOS

${BOLD}SYNOPSIS${RESET}
    $SCRIPT_NAME [options]

${BOLD}DESCRIPTION${RESET}
    Installs Claude Code (Anthropic's AI coding assistant) with all required
    dependencies. Includes Node.js installation if needed and optional dotfiles
    configuration.

${BOLD}OPTIONS${RESET}
    -h, --help          Show this help message
    -v, --verbose       Enable verbose output
    -f, --force         Force reinstall even if already installed
    -s, --skip-dotfiles Skip dotfiles configuration
    -m, --skip-mcp      Skip MCP server configuration
    -o, --optional-mcp  Install optional MCP servers (requires API keys)
    -V, --version       Show version information

${BOLD}EXAMPLES${RESET}
    # Basic installation
    $SCRIPT_NAME

    # Force reinstall with verbose output
    $SCRIPT_NAME -f -v

    # Install without dotfiles configuration
    $SCRIPT_NAME --skip-dotfiles

    # Install with optional MCP servers
    $SCRIPT_NAME --optional-mcp

    # Install Claude Code only (no MCP servers)
    $SCRIPT_NAME --skip-mcp

${BOLD}REQUIREMENTS${RESET}
    - macOS 11.0+ (Big Sur)
    - Administrator privileges for Homebrew installation
    - Internet connection for downloading packages

${BOLD}AUTHOR${RESET}
    Andrew Exley <andrew@exley.com.au>

${BOLD}VERSION${RESET}
    $SCRIPT_VERSION
EOF
}

# Show version information
show_version() {
    echo "$SCRIPT_NAME version $SCRIPT_VERSION"
}

# Check if running on macOS
check_macos() {
    if [[ $(uname) != "Darwin" ]]; then
        log_error "This script requires macOS"
        exit 1
    fi
}

# Check macOS version
check_macos_version() {
    local required_version="11.0"
    local current_version=$(sw_vers -productVersion)
    
    if ! is_version_gte "$current_version" "$required_version"; then
        log_error "macOS $required_version or later required (current: $current_version)"
        exit 1
    fi
}

# Version comparison
is_version_gte() {
    [ "$1" = "$(echo -e "$1\n$2" | sort -V | tail -n1)" ]
}

# Check if Claude Code is already installed
check_claude_installed() {
    if command -v claude &> /dev/null; then
        local claude_version=$(claude --version 2>&1 | head -1 || echo "version unknown")
        log_info "Claude Code is already installed: $claude_version"
        
        if [[ $FORCE_REINSTALL == true ]]; then
            log_info "Force reinstall requested, continuing..."
            return 1
        else
            log_success "Claude Code installation verified"
            return 0
        fi
    fi
    
    return 1
}

# Install Homebrew if not present
install_homebrew() {
    log_info "Checking Homebrew installation..."
    
    if command -v brew &> /dev/null; then
        log_debug "Homebrew already installed"
        return 0
    fi
    
    log_info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH
    if [[ -f /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    fi
    
    # Disable analytics
    brew analytics off
    
    log_success "Homebrew installed successfully"
}

# Check Node.js version
check_node_version() {
    local version=$1
    local major_version=${version#v}
    major_version=${major_version%%.*}
    
    if [[ $major_version -ge $NODE_MIN_VERSION ]]; then
        return 0
    else
        return 1
    fi
}

# Install Node.js
install_nodejs() {
    log_info "Checking Node.js installation..."
    
    if command -v node &> /dev/null; then
        local node_version=$(node --version)
        log_debug "Found Node.js version: $node_version"
        
        if check_node_version "$node_version"; then
            log_success "Node.js $node_version is compatible (requires $NODE_MIN_VERSION+)"
            return 0
        else
            log_warn "Node.js $node_version found but Claude Code requires $NODE_MIN_VERSION+"
            log_info "Upgrading Node.js via Homebrew..."
        fi
    else
        log_info "Node.js not found, installing via Homebrew..."
    fi
    
    # Install latest Node.js via Homebrew
    log_info "Installing Node.js..."
    brew install node
    
    # Verify installation
    if command -v node &> /dev/null; then
        local node_version=$(node --version)
        log_success "Node.js $node_version installed successfully"
        
        # Verify npm is available
        if command -v npm &> /dev/null; then
            local npm_version=$(npm --version)
            log_success "npm $npm_version is available"
        else
            log_error "npm not found after Node.js installation"
            exit 1
        fi
    else
        log_error "Node.js installation failed"
        exit 1
    fi
}

# Install Claude Code
install_claude_code() {
    log_info "Installing Claude Code..."
    
    # Install Claude Code globally via npm
    if npm install -g @anthropic-ai/claude-code; then
        log_success "Claude Code installed successfully"
    else
        log_error "Failed to install Claude Code"
        exit 1
    fi
    
    # Verify installation
    if command -v claude &> /dev/null; then
        local claude_version=$(claude --version 2>&1 | head -1 || echo "version unknown")
        log_success "Claude Code verification: $claude_version"
    else
        log_error "Claude Code installation verification failed"
        exit 1
    fi
}

# Configure dotfiles
configure_dotfiles() {
    if [[ $SKIP_DOTFILES == true ]]; then
        log_info "Skipping dotfiles configuration"
        return 0
    fi
    
    log_info "Configuring Claude Code dotfiles..."
    
    # Check if stow is available
    if ! command -v stow &> /dev/null; then
        log_warn "GNU Stow not found, skipping dotfiles configuration"
        log_info "Install stow with: brew install stow"
        return 0
    fi
    
    # Check if claude dotfiles directory exists
    if [[ ! -d "$DOTFILES_DIR/claude" ]]; then
        log_warn "Claude dotfiles directory not found at $DOTFILES_DIR/claude"
        return 0
    fi
    
    # Navigate to dotfiles directory and stow claude package
    log_info "Applying Claude dotfiles with stow..."
    if (cd "$DOTFILES_DIR" && stow claude); then
        log_success "Claude dotfiles configured successfully"
    else
        log_warn "Failed to configure Claude dotfiles"
    fi
}

# Check if jq is available for JSON processing
check_jq() {
    if ! command -v jq &> /dev/null; then
        log_info "Installing jq for JSON processing..."
        brew install jq
    fi
}

# Read API key from user input
read_api_key() {
    local service=$1
    local var_name=$2
    local description=$3
    
    echo
    log_info "Setting up $service integration..."
    echo -e "${YELLOW}$description${RESET}"
    echo -n "Enter your $service API key (or press Enter to skip): "
    read -rs api_key
    echo
    
    if [[ -n $api_key ]]; then
        export "$var_name"="$api_key"
        log_success "$service API key configured"
        return 0
    else
        log_warn "Skipping $service integration"
        return 1
    fi
}

# Install individual MCP server
install_mcp_server() {
    local server_name=$1
    local package_name=$2
    local description=$3
    local required=$4
    
    log_info "Installing MCP server: $server_name"
    log_debug "Package: $package_name"
    log_debug "Description: $description"
    
    # Install the package globally
    if npm install -g "$package_name"; then
        log_success "✓ $server_name MCP server installed"
        return 0
    else
        if [[ $required == true ]]; then
            log_error "Failed to install required MCP server: $server_name"
            return 1
        else
            log_warn "Failed to install optional MCP server: $server_name"
            return 0
        fi
    fi
}

# Setup environment variables for MCP servers
setup_mcp_env_vars() {
    local env_file="$HOME/.zshrc"
    local temp_env_file="/tmp/mcp_env_vars.tmp"
    
    log_info "Setting up MCP environment variables..."
    
    # Create temporary file for environment variables
    cat > "$temp_env_file" << 'EOF'

# =============================================================================
# Claude Code MCP Server Environment Variables
# =============================================================================

EOF
    
    # Set up memory bank directory
    local memory_bank_dir="$HOME/.claude/memory-bank"
    mkdir -p "$memory_bank_dir"
    echo "export MEMORY_BANK_ROOT=\"$memory_bank_dir\"" >> "$temp_env_file"
    
    # Check for optional API keys if requested
    if [[ $INSTALL_OPTIONAL_MCP == true ]]; then
        # GitHub Token
        if read_api_key "GitHub" "GITHUB_TOKEN" "Get your GitHub token from: https://github.com/settings/tokens"; then
            echo "export GITHUB_TOKEN=\"$GITHUB_TOKEN\"" >> "$temp_env_file"
        fi
        
        # Brave Search API Key
        if read_api_key "Brave Search" "BRAVE_API_KEY" "Get your Brave Search API key from: https://api.search.brave.com/"; then
            echo "export BRAVE_API_KEY=\"$BRAVE_API_KEY\"" >> "$temp_env_file"
        fi
        
        # PostgreSQL Database URL
        echo
        log_info "Setting up PostgreSQL integration..."
        echo -e "${YELLOW}Enter your PostgreSQL connection string (e.g., postgresql://user:password@localhost:5432/dbname)${RESET}"
        echo -n "Database URL (or press Enter to skip): "
        read -r database_url
        if [[ -n $database_url ]]; then
            echo "export DATABASE_URL=\"$database_url\"" >> "$temp_env_file"
            log_success "PostgreSQL connection configured"
        else
            log_warn "Skipping PostgreSQL integration"
        fi
    fi
    
    # Add closing comment
    echo >> "$temp_env_file"
    echo "# End Claude Code MCP Environment Variables" >> "$temp_env_file"
    echo "# =============================================================================" >> "$temp_env_file"
    
    # Append to .zshrc if not already present
    if ! grep -q "Claude Code MCP Server Environment Variables" "$env_file" 2>/dev/null; then
        cat "$temp_env_file" >> "$env_file"
        log_success "Environment variables added to $env_file"
    else
        log_info "MCP environment variables already present in $env_file"
    fi
    
    # Clean up temporary file
    rm -f "$temp_env_file"
    
    # Source the environment variables for current session
    source "$env_file"
}

# Generate MCP configuration file
generate_mcp_config() {
    log_info "Generating MCP server configuration..."
    
    # Create MCP config directory
    mkdir -p "$MCP_CONFIG_DIR"
    
    # Check if template exists
    if [[ ! -f "$MCP_TEMPLATE_FILE" ]]; then
        log_error "MCP template file not found at $MCP_TEMPLATE_FILE"
        return 1
    fi
    
    # Read template and substitute variables
    local config_content=$(cat "$MCP_TEMPLATE_FILE")
    
    # Replace template variables
    config_content=${config_content//\{\{HOME\}\}/$HOME}
    config_content=${config_content//\{\{GITHUB_TOKEN\}\}/$GITHUB_TOKEN}
    config_content=${config_content//\{\{BRAVE_API_KEY\}\}/$BRAVE_API_KEY}
    config_content=${config_content//\{\{DATABASE_URL\}\}/$DATABASE_URL}
    
    # Filter out servers without required environment variables
    local final_config="{"
    final_config+='"mcpServers": {'
    
    local servers_added=false
    
    # Always include core servers
    final_config+='"filesystem": {"command": "npx", "args": ["-y", "@modelcontextprotocol/server-filesystem", "'$HOME'/Documents", "'$HOME'/Desktop", "'$HOME'/Downloads", "'$HOME'/Projects", "'$HOME'/Developer"]},'
    final_config+='"sequential-thinking": {"command": "npx", "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"]},'
    final_config+='"context7": {"command": "npx", "args": ["-y", "@upstash/context7-mcp"]},'
    final_config+='"memory-bank": {"command": "npx", "args": ["-y", "@alioshr/memory-bank-mcp"], "env": {"MEMORY_BANK_ROOT": "'$HOME'/.claude/memory-bank"}},'
    final_config+='"markitdown": {"command": "npx", "args": ["-y", "@microsoft/markitdown-mcp"]},'
    final_config+='"puppeteer": {"command": "npx", "args": ["-y", "@modelcontextprotocol/server-puppeteer"]},'
    final_config+='"desktop-commander": {"command": "npx", "args": ["-y", "@wonderwhy-er/desktop-commander-mcp"]}'
    
    # Add optional servers if environment variables are set
    if [[ -n $GITHUB_TOKEN ]]; then
        final_config+=', "github": {"command": "npx", "args": ["-y", "@modelcontextprotocol/server-github"], "env": {"GITHUB_TOKEN": "'$GITHUB_TOKEN'"}}'
    fi
    
    if [[ -n $BRAVE_API_KEY ]]; then
        final_config+=', "brave-search": {"command": "npx", "args": ["-y", "@modelcontextprotocol/server-brave-search"], "env": {"BRAVE_API_KEY": "'$BRAVE_API_KEY'"}}'
    fi
    
    if [[ -n $DATABASE_URL ]]; then
        final_config+=', "postgres": {"command": "npx", "args": ["-y", "@modelcontextprotocol/server-postgres"], "env": {"DATABASE_URL": "'$DATABASE_URL'"}}'
    fi
    
    final_config+="}}"
    
    # Write configuration file
    echo "$final_config" | jq '.' > "$MCP_CONFIG_FILE"
    
    if [[ $? -eq 0 ]]; then
        log_success "MCP configuration file created at $MCP_CONFIG_FILE"
        return 0
    else
        log_error "Failed to create MCP configuration file"
        return 1
    fi
}

# Install MCP servers
install_mcp_servers() {
    if [[ $SKIP_MCP == true ]]; then
        log_info "Skipping MCP server installation"
        return 0
    fi
    
    log_info "Installing Claude Code MCP servers..."
    
    # Check dependencies
    check_jq
    
    # Setup environment variables
    setup_mcp_env_vars
    
    # Check if MCP servers config exists
    if [[ ! -f "$MCP_SERVERS_CONFIG" ]]; then
        log_warn "MCP servers configuration file not found at $MCP_SERVERS_CONFIG"
        log_info "Installing basic MCP servers..."
        
        # Install basic servers manually
        install_mcp_server "filesystem" "@modelcontextprotocol/server-filesystem" "Local file system access" true
        install_mcp_server "sequential-thinking" "@modelcontextprotocol/server-sequential-thinking" "Dynamic problem-solving" true
        install_mcp_server "context7" "@upstash/context7-mcp" "Up-to-date documentation" true
        install_mcp_server "memory-bank" "@alioshr/memory-bank-mcp" "Persistent memory management" true
        install_mcp_server "markitdown" "@microsoft/markitdown-mcp" "Document conversion" true
        install_mcp_server "puppeteer" "@modelcontextprotocol/server-puppeteer" "Web automation" true
        install_mcp_server "desktop-commander" "@wonderwhy-er/desktop-commander-mcp" "Terminal control" true
        
        # Install optional servers if requested
        if [[ $INSTALL_OPTIONAL_MCP == true ]]; then
            install_mcp_server "github" "@modelcontextprotocol/server-github" "GitHub integration" false
            install_mcp_server "brave-search" "@modelcontextprotocol/server-brave-search" "Web search" false
            install_mcp_server "postgres" "@modelcontextprotocol/server-postgres" "PostgreSQL database" false
        fi
    else
        # Install servers from configuration file
        log_info "Installing MCP servers from configuration..."
        
        # Install core servers
        local core_servers=$(jq -r '.servers.core[] | .name + " " + .package + " \"" + .description + "\" " + (.required | tostring)' "$MCP_SERVERS_CONFIG")
        
        while IFS= read -r server_line; do
            if [[ -n $server_line ]]; then
                local server_info=($server_line)
                local name=${server_info[0]}
                local package=${server_info[1]}
                local description=${server_info[2]}
                local required=${server_info[3]}
                
                install_mcp_server "$name" "$package" "$description" "$required"
            fi
        done <<< "$core_servers"
        
        # Install optional servers if requested
        if [[ $INSTALL_OPTIONAL_MCP == true ]]; then
            local optional_servers=$(jq -r '.servers.optional[] | .name + " " + .package + " \"" + .description + "\" " + (.required | tostring)' "$MCP_SERVERS_CONFIG")
            
            while IFS= read -r server_line; do
                if [[ -n $server_line ]]; then
                    local server_info=($server_line)
                    local name=${server_info[0]}
                    local package=${server_info[1]}
                    local description=${server_info[2]}
                    local required=${server_info[3]}
                    
                    install_mcp_server "$name" "$package" "$description" "$required"
                fi
            done <<< "$optional_servers"
        fi
    fi
    
    # Generate MCP configuration file
    generate_mcp_config
    
    log_success "MCP servers installation completed"
}

# Verify MCP installation
verify_mcp_installation() {
    if [[ $SKIP_MCP == true ]]; then
        return 0
    fi
    
    log_info "Verifying MCP installation..."
    
    # Check if configuration file exists
    if [[ -f "$MCP_CONFIG_FILE" ]]; then
        log_success "✓ MCP configuration file found"
        
        # Count configured servers
        local server_count=$(jq '.mcpServers | length' "$MCP_CONFIG_FILE" 2>/dev/null || echo "0")
        log_info "Configured MCP servers: $server_count"
        
        # List configured servers
        if [[ $VERBOSE == true ]]; then
            log_info "Configured MCP servers:"
            jq -r '.mcpServers | keys[]' "$MCP_CONFIG_FILE" 2>/dev/null | while read -r server; do
                log_info "  - $server"
            done
        fi
    else
        log_warn "MCP configuration file not found"
    fi
    
    # Check if memory bank directory exists
    if [[ -d "$HOME/.claude/memory-bank" ]]; then
        log_success "✓ Memory bank directory created"
    fi
    
    log_success "MCP installation verification completed"
}

# Display post-installation instructions
show_instructions() {
    cat << EOF

${GREEN}${BOLD}✓ Claude Code Installation Complete!${RESET}

${BOLD}Quick Start:${RESET}
  1. Navigate to any project directory
  2. Run: ${BLUE}claude${RESET}
  3. Start an interactive coding session with Claude

${BOLD}Key Features:${RESET}
  • Context-aware code generation and refactoring
  • Integrated with your project files and codebase
  • Supports multiple programming languages
  • Interactive coding conversations
  • MCP server integrations for enhanced capabilities

${BOLD}Configuration:${RESET}
  • Global config: ${BLUE}~/.claude/CLAUDE.md${RESET}
  • Project config: Create ${BLUE}CLAUDE.md${RESET} in your project root
  • MCP config: ${BLUE}~/.claude/claude_desktop_config.json${RESET}
  • Customise Claude behaviour for specific projects

EOF

    # Show MCP information if not skipped
    if [[ $SKIP_MCP != true ]]; then
        cat << EOF
${BOLD}MCP Servers Installed:${RESET}
  • ${BLUE}FileSystem${RESET}: Local file access and management
  • ${BLUE}Sequential Thinking${RESET}: Dynamic problem-solving
  • ${BLUE}Context7${RESET}: Up-to-date documentation
  • ${BLUE}Memory Bank${RESET}: Persistent memory management
  • ${BLUE}MarkItDown${RESET}: Document conversion to Markdown
  • ${BLUE}Puppeteer${RESET}: Web automation and browser control
  • ${BLUE}Desktop Commander${RESET}: Terminal control and file operations

EOF
        
        # Show optional MCP servers if installed
        if [[ $INSTALL_OPTIONAL_MCP == true ]]; then
            cat << EOF
${BOLD}Optional MCP Servers (if API keys provided):${RESET}
  • ${BLUE}GitHub${RESET}: Repository integration and management
  • ${BLUE}Brave Search${RESET}: Web search capabilities
  • ${BLUE}PostgreSQL${RESET}: Database queries and management

EOF
        fi
        
        cat << EOF
${BOLD}MCP Management:${RESET}
  • List MCP servers: ${BLUE}claude mcp list${RESET}
  • Check MCP status: ${BLUE}/mcp${RESET} (within Claude session)
  • Configure permissions: ${BLUE}/permissions${RESET} (within Claude session)
  • MCP config file: ${BLUE}~/.claude/claude_desktop_config.json${RESET}

EOF
    fi
    
    cat << EOF
${BOLD}Documentation:${RESET}
  • Official docs: ${BLUE}https://docs.anthropic.com/en/docs/claude-code${RESET}
  • MCP documentation: ${BLUE}https://docs.anthropic.com/en/docs/claude-code/mcp${RESET}
  • Help command: ${BLUE}claude --help${RESET}
  • Version info: ${BLUE}claude --version${RESET}

${BOLD}Next Steps:${RESET}
  • Try running ${BLUE}claude${RESET} in one of your projects
  • Create project-specific CLAUDE.md files for better context
  • Explore the MCP server capabilities and permissions
  • Set up additional API keys for optional MCP servers

EOF

    # Show environment restart notice
    if [[ $SKIP_MCP != true ]]; then
        cat << EOF
${YELLOW}${BOLD}⚠️  Important:${RESET} Please restart your terminal or run ${BLUE}source ~/.zshrc${RESET} to load new environment variables.

EOF
    fi
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
            -f|--force)
                FORCE_REINSTALL=true
                shift
                ;;
            -s|--skip-dotfiles)
                SKIP_DOTFILES=true
                shift
                ;;
            -m|--skip-mcp)
                SKIP_MCP=true
                shift
                ;;
            -o|--optional-mcp)
                INSTALL_OPTIONAL_MCP=true
                shift
                ;;
            -V|--version)
                show_version
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
}

# Main installation function
main() {
    log_info "Starting Claude Code installation..."
    
    # Parse command line arguments
    parse_args "$@"
    
    # System checks
    check_macos
    check_macos_version
    
    # Check if already installed
    if check_claude_installed; then
        show_instructions
        exit 0
    fi
    
    # Install dependencies
    install_homebrew
    install_nodejs
    
    # Install Claude Code
    install_claude_code
    
    # Configure dotfiles
    configure_dotfiles
    
    # Install MCP servers
    install_mcp_servers
    
    # Verify MCP installation
    verify_mcp_installation
    
    # Show completion message
    log_success "Claude Code installation completed successfully!"
    show_instructions
}

# Run main function if script is executed directly
if [[ "${(%):-%x}" == "${0}" ]]; then
    main "$@"
fi
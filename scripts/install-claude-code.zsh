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
    -V, --version       Show version information

${BOLD}EXAMPLES${RESET}
    # Basic installation
    $SCRIPT_NAME

    # Force reinstall with verbose output
    $SCRIPT_NAME -f -v

    # Install without dotfiles configuration
    $SCRIPT_NAME --skip-dotfiles

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

${BOLD}Configuration:${RESET}
  • Global config: ${BLUE}~/.claude/CLAUDE.md${RESET}
  • Project config: Create ${BLUE}CLAUDE.md${RESET} in your project root
  • Customise Claude behaviour for specific projects

${BOLD}Documentation:${RESET}
  • Official docs: ${BLUE}https://docs.anthropic.com/en/docs/claude-code${RESET}
  • Help command: ${BLUE}claude --help${RESET}
  • Version info: ${BLUE}claude --version${RESET}

${BOLD}Next Steps:${RESET}
  • Try running ${BLUE}claude${RESET} in one of your projects
  • Create project-specific CLAUDE.md files for better context
  • Explore the interactive features and code generation capabilities

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
            -f|--force)
                FORCE_REINSTALL=true
                shift
                ;;
            -s|--skip-dotfiles)
                SKIP_DOTFILES=true
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
    
    # Show completion message
    log_success "Claude Code installation completed successfully!"
    show_instructions
}

# Run main function if script is executed directly
if [[ "${(%):-%x}" == "${0}" ]]; then
    main "$@"
fi
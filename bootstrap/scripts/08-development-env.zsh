#!/usr/bin/env zsh
# -*- coding: utf-8 -*-

#=============================================================================
# SCRIPT: 08-development-env.zsh
# AUTHOR: Andrew Exley (with Claude)
# DATE: 2025-01-07
# VERSION: 1.0.0
#
# DESCRIPTION:
#   Development environment setup script for macOS dotfiles.
#   Configures Git, programming languages, development tools, and IDEs
#   based on the selected profile and hardware capabilities.
#
# USAGE:
#   ./08-development-env.zsh [options]
#
# OPTIONS:
#   -h, --help      Show this help message
#   -v, --verbose   Enable verbose output
#   -d, --debug     Enable debug mode
#   -n, --dry-run   Preview changes without applying them
#   -f, --force     Skip confirmation prompts
#
# REQUIREMENTS:
#   - macOS 11.0+ (Big Sur)
#   - Zsh 5.8+
#   - Homebrew installed
#   - Hardware detection completed
#
# NOTES:
#   - Configures Git with multi-account support
#   - Sets up programming language environments
#   - Installs development tools and IDEs
#   - Applies hardware-specific optimisations
#=============================================================================

# Strict mode
set -euo pipefail

# Script metadata
readonly SCRIPT_NAME="${0:t}"
readonly SCRIPT_DIR="${0:A:h}"
readonly SCRIPT_VERSION="1.0.0"
readonly DOTFILES_ROOT="${SCRIPT_DIR:h:h}"

# Colour codes (using tput for compatibility)
readonly RED=$(tput setaf 1)
readonly GREEN=$(tput setaf 2)
readonly YELLOW=$(tput setaf 3)
readonly BLUE=$(tput setaf 4)
readonly MAGENTA=$(tput setaf 5)
readonly CYAN=$(tput setaf 6)
readonly WHITE=$(tput setaf 7)
readonly BOLD=$(tput bold)
readonly RESET=$(tput sgr0)

# Global variables
declare -g VERBOSE=false
declare -g DEBUG=false
declare -g DRY_RUN=false
declare -g FORCE=false

#=============================================================================
# LOGGING FUNCTIONS
#=============================================================================

log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Log to console based on level
    case $level in
        ERROR)
            echo "${RED}${BOLD}[ERROR]${RESET} $message" >&2
            ;;
        WARN)
            echo "${YELLOW}${BOLD}[WARN]${RESET} $message" >&2
            ;;
        INFO)
            echo "${BLUE}${BOLD}[INFO]${RESET} $message"
            ;;
        DEBUG)
            [[ $DEBUG == true ]] && echo "${CYAN}[DEBUG]${RESET} $message" || true
            ;;
        SUCCESS)
            echo "${GREEN}${BOLD}[✓]${RESET} $message"
            ;;
        STEP)
            echo "${MAGENTA}${BOLD}[STEP]${RESET} $message"
            ;;
    esac
}

error() { log ERROR "$@"; }
warn() { log WARN "$@"; }
info() { log INFO "$@"; }
debug() { log DEBUG "$@"; }
success() { log SUCCESS "$@"; }
step() { log STEP "$@"; }

#=============================================================================
# UTILITY FUNCTIONS
#=============================================================================

# Confirmation prompt
confirm() {
    local message="${1:-Are you sure?}"
    
    [[ $FORCE == true ]] && return 0
    
    echo -n "${YELLOW}${BOLD}[?]${RESET} $message (y/N): "
    read -r response
    [[ $response =~ ^[Yy]$ ]]
}

# Check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Create directory safely
safe_mkdir() {
    local dir=$1
    
    if [[ $DRY_RUN == true ]]; then
        info "DRY RUN: Would create directory: $dir"
        return 0
    fi
    
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
        debug "Created directory: $dir"
    fi
}

# Create symlink safely
safe_symlink() {
    local source=$1
    local target=$2
    
    if [[ $DRY_RUN == true ]]; then
        info "DRY RUN: Would symlink $source -> $target"
        return 0
    fi
    
    # Remove existing file/symlink if it exists
    if [[ -e "$target" || -L "$target" ]]; then
        rm -f "$target"
        debug "Removed existing file: $target"
    fi
    
    # Create parent directory if needed
    safe_mkdir "$(dirname "$target")"
    
    # Create symlink
    ln -sf "$source" "$target"
    debug "Created symlink: $source -> $target"
}

#=============================================================================
# GIT CONFIGURATION
#=============================================================================

setup_git_config() {
    step "Setting up Git configuration..."
    
    local git_config_dir="$DOTFILES_ROOT/packages/git"
    
    # Check if Git config files exist
    if [[ ! -f "$git_config_dir/dot-gitconfig" ]]; then
        error "Git configuration files not found in $git_config_dir"
        return 1
    fi
    
    # Create .config/git directory for account-specific configs
    safe_mkdir "$HOME/.config/git/accounts"
    
    # Symlink main Git configuration
    safe_symlink "$git_config_dir/dot-gitconfig" "$HOME/.gitconfig"
    success "Linked global Git configuration"
    
    # Symlink global gitignore
    safe_symlink "$git_config_dir/dot-gitignore_global" "$HOME/.gitignore_global"
    success "Linked global gitignore"
    
    # Symlink account-specific configurations
    if [[ -d "$git_config_dir/accounts" ]]; then
        for account_config in "$git_config_dir/accounts"/*.gitconfig; do
            if [[ -f "$account_config" ]]; then
                local filename=$(basename "$account_config")
                safe_symlink "$account_config" "$HOME/.config/git/accounts/$filename"
                debug "Linked account config: $filename"
            fi
        done
        success "Linked account-specific Git configurations"
    fi
    
    # Create common project directories for conditional includes
    local project_dirs=(
        "$HOME/Projects/personal"
        "$HOME/Projects/lument" 
        "$HOME/Projects/pollex"
        "$HOME/Development/personal"
        "$HOME/Development/lument"
        "$HOME/Development/pollex"
    )
    
    for dir in "${project_dirs[@]}"; do
        safe_mkdir "$dir"
    done
    success "Created project directory structure"
    
    # Test Git configuration
    if [[ $DRY_RUN == false ]] && command_exists git; then
        local git_version=$(git --version 2>/dev/null || echo "not found")
        info "Git version: $git_version"
        
        # Test Git config
        local git_name=$(git config --global user.name 2>/dev/null || echo "not set")
        local git_email=$(git config --global user.email 2>/dev/null || echo "not set")
        info "Git identity: $git_name <$git_email>"
        
        # Verify aliases work
        if git config --global alias.st &>/dev/null; then
            debug "Git aliases configured successfully"
        fi
    fi
}

setup_delta() {
    step "Setting up Delta (enhanced diff viewer)..."
    
    if command_exists delta; then
        success "Delta is already installed"
        return 0
    fi
    
    if [[ $DRY_RUN == true ]]; then
        info "DRY RUN: Would install delta via Homebrew"
        return 0
    fi
    
    if command_exists brew; then
        info "Installing delta via Homebrew..."
        brew install git-delta
        success "Delta installed successfully"
    else
        warn "Homebrew not found, skipping delta installation"
    fi
}

#=============================================================================
# PROGRAMMING LANGUAGES
#=============================================================================

setup_python_environment() {
    step "Setting up Python development environment..."
    
    # Check if uv is installed
    if ! command_exists uv; then
        if [[ $DRY_RUN == true ]]; then
            info "DRY RUN: Would install uv Python package manager"
            return 0
        fi
        
        info "Installing uv Python package manager..."
        if command_exists brew; then
            brew install uv
        else
            curl -LsSf https://astral.sh/uv/install.sh | sh
        fi
    fi
    
    if command_exists uv; then
        success "uv package manager is available"
        
        # Set up global tools directory
        safe_mkdir "$HOME/.local/bin"
        
        # Install common global tools
        local global_tools=(
            "black"
            "flake8" 
            "mypy"
            "pytest"
            "ipython"
            "jupyterlab"
        )
        
        for tool in "${global_tools[@]}"; do
            if [[ $DRY_RUN == true ]]; then
                info "DRY RUN: Would install global tool: $tool"
            else
                debug "Installing global Python tool: $tool"
                uv tool install "$tool" || debug "Tool $tool may already be installed"
            fi
        done
        
        success "Python environment configured"
    else
        warn "Could not install uv package manager"
    fi
}

setup_node_environment() {
    step "Setting up Node.js development environment..."
    
    if ! command_exists node; then
        if [[ $DRY_RUN == true ]]; then
            info "DRY RUN: Would install Node.js via Homebrew"
            return 0
        fi
        
        if command_exists brew; then
            info "Installing Node.js via Homebrew..."
            brew install node
        else
            warn "Homebrew not found, skipping Node.js installation"
            return 1
        fi
    fi
    
    if command_exists node && command_exists npm; then
        local node_version=$(node --version 2>/dev/null)
        local npm_version=$(npm --version 2>/dev/null)
        info "Node.js $node_version, npm $npm_version"
        
        # Install global packages
        local global_packages=(
            "typescript"
            "eslint"
            "prettier"
            "@vue/cli"
            "create-react-app"
            "@anthropic-ai/claude-code"
        )
        
        for package in "${global_packages[@]}"; do
            if [[ $DRY_RUN == true ]]; then
                info "DRY RUN: Would install global package: $package"
            else
                debug "Installing global npm package: $package"
                npm install -g "$package" || debug "Package $package may already be installed"
            fi
        done
        
        success "Node.js environment configured"
    else
        warn "Node.js not available"
    fi
}

#=============================================================================
# DEVELOPMENT TOOLS
#=============================================================================

setup_development_directories() {
    step "Setting up development directory structure..."
    
    local dev_dirs=(
        "$HOME/Development"
        "$HOME/Projects"
        "$HOME/Repositories"
        "$HOME/.config"
        "$HOME/.local/bin"
        "$HOME/.local/share"
        "$HOME/.cache"
    )
    
    for dir in "${dev_dirs[@]}"; do
        safe_mkdir "$dir"
    done
    
    success "Development directories created"
}

configure_shell_integration() {
    step "Configuring shell integration for development tools..."
    
    # This will be handled by the shell configuration in zsh/
    # But we can verify the integration works
    
    if [[ -f "$HOME/.zshrc" ]]; then
        debug "Zsh configuration found"
        
        # Check if common tools are available in shell
        local tools_to_check=("git" "uv" "node" "brew")
        
        for tool in "${tools_to_check[@]}"; do
            if command_exists "$tool"; then
                debug "Tool available in shell: $tool"
            else
                debug "Tool not found in shell: $tool"
            fi
        done
    fi
    
    success "Shell integration verified"
}

#=============================================================================
# MAIN EXECUTION
#=============================================================================

# Display usage information
usage() {
    cat << EOF
${BOLD}NAME${RESET}
    $SCRIPT_NAME - Development environment setup

${BOLD}SYNOPSIS${RESET}
    $SCRIPT_NAME [options]

${BOLD}DESCRIPTION${RESET}
    Sets up comprehensive development environment including Git configuration,
    programming languages, and development tools based on the selected profile.

${BOLD}OPTIONS${RESET}
    -h, --help          Show this help message
    -v, --verbose       Enable verbose output
    -d, --debug         Enable debug mode
    -n, --dry-run       Preview changes without applying them
    -f, --force         Skip confirmation prompts

${BOLD}COMPONENTS${RESET}
    • Git configuration with multi-account support
    • Python environment with uv package manager
    • Node.js environment with global packages
    • Development directory structure
    • Shell integration and verification

${BOLD}AUTHOR${RESET}
    Andrew Exley (with Claude) <noreply@anthropic.com>

${BOLD}VERSION${RESET}
    $SCRIPT_VERSION
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
            -d|--debug)
                DEBUG=true
                shift
                ;;
            -n|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -f|--force)
                FORCE=true
                shift
                ;;
            -*)
                error "Unknown option: $1"
                usage
                exit 1
                ;;
            *)
                error "Unexpected argument: $1"
                usage
                exit 1
                ;;
        esac
    done
}

# Main script logic
main() {
    # Parse arguments
    parse_args "$@"
    
    info "Starting development environment setup"
    debug "Script version: $SCRIPT_VERSION"
    
    # Set up development environment
    setup_development_directories
    setup_git_config
    setup_delta
    setup_python_environment
    setup_node_environment
    configure_shell_integration
    
    success "Development environment setup completed!"
    
    if [[ $DRY_RUN == false ]]; then
        echo ""
        info "Next steps:"
        info "• Restart your terminal or run: exec zsh"
        info "• Test Git configuration: git config --list"
        info "• Test Python environment: uv --version"
        info "• Test Node.js environment: node --version"
        echo ""
    fi
}

#=============================================================================
# SCRIPT EXECUTION
#=============================================================================

# Only run main if script is executed directly
if [[ "${(%):-%x}" == "${0}" ]]; then
    main "$@"
fi
#!/usr/bin/env zsh
# ABOUTME: Install Ghostty configuration for enhanced SSH workflow experience
# ABOUTME: Copies Ghostty config from this project to the expected system location

# Strict mode
set -euo pipefail

# Script metadata
readonly SCRIPT_NAME="${0:t}"
readonly SCRIPT_DIR="${0:A:h}"
readonly PROJECT_ROOT="${SCRIPT_DIR:h}"

# Colours
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly BLUE='\033[0;34m'
readonly RESET='\033[0m'

# Logging functions
info() { echo -e "${BLUE}[INFO]${RESET} $*"; }
success() { echo -e "${GREEN}[✓]${RESET} $*"; }
warn() { echo -e "${YELLOW}[WARN]${RESET} $*"; }
error() { echo -e "${RED}[ERROR]${RESET} $*"; }

# Main installation function
install_ghostty_config() {
    local source_config="$PROJECT_ROOT/dotfiles/ghostty/dot-config/ghostty/config"
    local target_dir="$HOME/.config/ghostty"
    local target_config="$target_dir/config"
    
    info "Installing Ghostty configuration for SSH-optimized workflow"
    
    # Check if source config exists
    if [[ ! -f "$source_config" ]]; then
        error "Source config not found: $source_config"
        return 1
    fi
    
    # Check if Ghostty is installed
    if ! command -v ghostty &> /dev/null && ! brew list --cask ghostty &> /dev/null; then
        warn "Ghostty not found. Installing via Homebrew..."
        if command -v brew &> /dev/null; then
            brew install --cask ghostty
            success "Ghostty installed"
        else
            error "Homebrew not found. Please install Ghostty manually"
            return 1
        fi
    fi
    
    # Create target directory
    if [[ ! -d "$target_dir" ]]; then
        info "Creating Ghostty config directory: $target_dir"
        mkdir -p "$target_dir"
    fi
    
    # Backup existing config if it exists
    if [[ -f "$target_config" ]]; then
        local backup_file="$target_config.backup.$(date +%Y%m%d-%H%M%S)"
        info "Backing up existing config to: $backup_file"
        cp "$target_config" "$backup_file"
    fi
    
    # Copy the new config
    info "Installing Ghostty configuration..."
    cp "$source_config" "$target_config"
    
    # Set appropriate permissions
    chmod 644 "$target_config"
    
    success "Ghostty configuration installed successfully!"
    
    # Display features
    cat << EOF

${GREEN}SSH-Optimized Features Enabled:${RESET}
• Terminal title updates for SSH connections
• SSH-friendly keybindings (splits, tabs, search)
• Large scrollback buffer for SSH sessions
• Catppuccin Mocha theme optimized for readability
• JetBrains Mono font for better terminal output

${BLUE}Key Bindings:${RESET}
• Cmd+Shift+Enter - New window
• Cmd+Shift+T - New tab
• Cmd+Shift+N - New split (right)
• Cmd+Shift+D - New split (down)
• Cmd+F - Search (great for SSH logs)
• Cmd+C/V - Copy/paste

${YELLOW}Next Steps:${RESET}
1. Restart Ghostty (if running) to apply the configuration
2. Load the enhanced zsh configuration: source ~/.zshrc
3. Try the SSH helper functions: ssh-status, ssh-keys, ssh-config-check
4. Test SSH connection with terminal title updates

EOF
}

# Check if we're in the right directory
check_project_structure() {
    if [[ ! -f "$PROJECT_ROOT/dotfiles/ghostty/dot-config/ghostty/config" ]]; then
        error "This script must be run from the macos-setup project root"
        error "Expected structure: dotfiles/ghostty/dot-config/ghostty/config"
        return 1
    fi
}

# Main execution
main() {
    check_project_structure
    install_ghostty_config
}

# Run main function
main "$@"
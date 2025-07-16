#!/usr/bin/env zsh
set -euo pipefail

# Script metadata and colour codes
readonly SCRIPT_NAME="${0:t}"
readonly RED=$(tput setaf 1)
readonly GREEN=$(tput setaf 2)
readonly YELLOW=$(tput setaf 3)
readonly BLUE=$(tput setaf 4)
readonly RESET=$(tput sgr0)

# Required tools from base Brewfile
readonly REQUIRED_TOOLS=(
    "git"
    "gh"
    "jq"
    "curl"
    "wget"
    "rg"          # ripgrep
    "bat"
    "eza"
    "fzf"
    "fd"
    "htop"
    "tree"
    "python3"
    "node"
    "ruby"
    "uv"
    "pipx"
    "chezmoi"
    "bats"        # bats-core
    "mas"
    "mackup"
    "duti"
    "brew"
)

# Logging functions
error() {
    echo "${RED}[ERROR]${RESET} $*" >&2
}

warn() {
    echo "${YELLOW}[WARN]${RESET} $*" >&2
}

info() {
    echo "${BLUE}[INFO]${RESET} $*"
}

success() {
    echo "${GREEN}[SUCCESS]${RESET} $*"
}

debug() {
    if [[ "${DEBUG:-}" == "1" ]]; then
        echo "${BLUE}[DEBUG]${RESET} $*" >&2
    fi
}

# Check if a tool is available in PATH
check_tool() {
    local tool="$1"
    local version_cmd="$2"
    local required="${3:-true}"
    
    if command -v "$tool" &>/dev/null; then
        local version=""
        if [[ -n "$version_cmd" ]]; then
            version=$($version_cmd 2>/dev/null | head -1 || echo "unknown")
        fi
        success "✓ $tool found${version:+ ($version)}"
        return 0
    else
        if [[ "$required" == "true" ]]; then
            error "✗ $tool not found in PATH"
            return 1
        else
            warn "⚠ $tool not found (optional)"
            return 0
        fi
    fi
}

# Check Homebrew specific tools
check_homebrew_status() {
    info "Checking Homebrew installation..."
    
    if ! command -v brew &>/dev/null; then
        error "Homebrew is not installed"
        error "Install with: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        return 1
    fi
    
    local brew_prefix
    brew_prefix=$(brew --prefix)
    success "✓ Homebrew installed at: $brew_prefix"
    
    # Check if Homebrew's bin is in PATH
    if [[ ":$PATH:" == *":$brew_prefix/bin:"* ]]; then
        success "✓ Homebrew bin directory is in PATH"
    else
        warn "⚠ Homebrew bin directory ($brew_prefix/bin) not in PATH"
        warn "Add to your shell profile: export PATH=\"$brew_prefix/bin:\$PATH\""
    fi
    
    # Check Homebrew status
    info "Homebrew status:"
    brew --version | head -1
    
    return 0
}

# Check shell configuration
check_shell_config() {
    info "Checking shell configuration..."
    
    local current_shell
    current_shell=$(basename "$SHELL")
    success "✓ Current shell: $current_shell"
    
    if [[ "$current_shell" != "zsh" ]]; then
        warn "⚠ Current shell is not zsh. This project is optimised for zsh."
    fi
    
    # Check for common shell configuration files
    local config_files=(
        "$HOME/.zshrc"
        "$HOME/.zprofile"
        "$HOME/.bashrc"
        "$HOME/.bash_profile"
    )
    
    for config_file in "${config_files[@]}"; do
        if [[ -f "$config_file" ]]; then
            success "✓ Found shell config: $config_file"
        fi
    done
    
    return 0
}

# Check development environment
check_dev_environment() {
    info "Checking development environment..."
    
    # Check Python environment
    if command -v python3 &>/dev/null; then
        local python_version
        python_version=$(python3 --version 2>&1)
        success "✓ Python: $python_version"
        
        # Check pip
        if command -v pip3 &>/dev/null; then
            success "✓ pip3 available"
        else
            warn "⚠ pip3 not found"
        fi
    fi
    
    # Check Node.js environment
    if command -v node &>/dev/null; then
        local node_version
        node_version=$(node --version)
        success "✓ Node.js: $node_version"
        
        # Check npm
        if command -v npm &>/dev/null; then
            local npm_version
            npm_version=$(npm --version)
            success "✓ npm: $npm_version"
        else
            warn "⚠ npm not found"
        fi
    fi
    
    # Check Ruby environment
    if command -v ruby &>/dev/null; then
        local ruby_version
        ruby_version=$(ruby --version)
        success "✓ Ruby: $ruby_version"
        
        # Check gem
        if command -v gem &>/dev/null; then
            success "✓ gem available"
        else
            warn "⚠ gem not found"
        fi
    fi
    
    return 0
}

# Main verification function
verify_tools() {
    local missing_tools=0
    local total_tools=${#REQUIRED_TOOLS[@]}
    
    info "Verifying $total_tools required tools..."
    echo
    
    for tool in "${REQUIRED_TOOLS[@]}"; do
        local version_cmd=""
        
        # Set appropriate version commands for different tools
        case "$tool" in
            "git") version_cmd="git --version" ;;
            "gh") version_cmd="gh --version" ;;
            "jq") version_cmd="jq --version" ;;
            "curl") version_cmd="curl --version" ;;
            "rg") version_cmd="rg --version" ;;
            "bat") version_cmd="bat --version" ;;
            "eza") version_cmd="eza --version" ;;
            "python3") version_cmd="python3 --version" ;;
            "node") version_cmd="node --version" ;;
            "ruby") version_cmd="ruby --version" ;;
            "chezmoi") version_cmd="chezmoi --version" ;;
            "brew") version_cmd="brew --version" ;;
            *) version_cmd="" ;;
        esac
        
        if ! check_tool "$tool" "$version_cmd"; then
            ((missing_tools++))
        fi
    done
    
    echo
    info "Tool verification summary:"
    local found_tools=$((total_tools - missing_tools))
    info "Found: $found_tools/$total_tools tools"
    
    if [[ $missing_tools -eq 0 ]]; then
        success "All required tools are available!"
        return 0
    else
        error "$missing_tools required tools are missing"
        return 1
    fi
}

# Help function
usage() {
    cat << EOF
$SCRIPT_NAME - Verify Required Tools Installation

USAGE:
    $SCRIPT_NAME [OPTIONS]

DESCRIPTION:
    Verifies that all required tools from the base Brewfile are installed
    and accessible in the current PATH. Provides diagnostic information
    about the development environment setup.

OPTIONS:
    -h, --help       Show this help message
    -v, --verbose    Enable verbose debugging output

EXAMPLES:
    $SCRIPT_NAME                    # Basic tool verification
    $SCRIPT_NAME --verbose          # Detailed verification with debug info

NOTES:
    - Checks for tools defined in configs/common/Brewfile
    - Verifies Homebrew installation and PATH configuration
    - Provides shell and development environment diagnostics

EOF
}

# Main execution
main() {
    info "macOS Setup Automation - Tool Verification"
    info "=========================================="
    
    # Check Homebrew first
    check_homebrew_status || return 1
    echo
    
    # Check shell configuration
    check_shell_config
    echo
    
    # Verify required tools
    verify_tools || return 1
    echo
    
    # Check development environment
    check_dev_environment
    echo
    
    success "Tool verification completed successfully!"
    info "All required tools are properly installed and configured."
    
    return 0
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            exit 0
            ;;
        -v|--verbose)
            export DEBUG=1
            shift
            ;;
        *)
            error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Run main function
main "$@"
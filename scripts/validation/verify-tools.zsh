#!/usr/bin/env zsh

# Script metadata
readonly SCRIPT_NAME="${0:t}"
readonly SCRIPT_DIR="${0:A:h}"

# Load common library
source "${SCRIPT_DIR}/../lib/common.zsh"

# Essential tools to verify
readonly REQUIRED_TOOLS=(
    "git" "gh" "jq" "curl" "wget" "rg" "bat" "eza" "fzf" "fd"
    "htop" "tree" "python3" "node" "ruby" "uv" "pipx" "chezmoi"
    "bats" "mas" "mackup" "duti" "brew"
)

# Check tool with version
check_tool() {
    local tool="$1"
    local required="${2:-true}"
    
    if command_exists "$tool"; then
        local version=""
        case "$tool" in
            "git") version=$(git --version 2>/dev/null | head -1) ;;
            "gh") version=$(gh --version 2>/dev/null | head -1) ;;
            "jq") version=$(jq --version 2>/dev/null) ;;
            "python3") version=$(python3 --version 2>/dev/null) ;;
            "node") version=$(node --version 2>/dev/null) ;;
            "ruby") version=$(ruby --version 2>/dev/null) ;;
            "brew") version=$(brew --version 2>/dev/null | head -1) ;;
            *) version="" ;;
        esac
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

# Verify all required tools
verify_tools() {
    local missing_tools=0
    local total_tools=${#REQUIRED_TOOLS[@]}
    
    info "Verifying $total_tools required tools..."
    echo
    
    for tool in "${REQUIRED_TOOLS[@]}"; do
        if ! check_tool "$tool"; then
            ((missing_tools++))
        fi
    done
    
    echo
    local found_tools=$((total_tools - missing_tools))
    info "Tool verification summary: $found_tools/$total_tools tools found"
    
    if [[ $missing_tools -eq 0 ]]; then
        success "All required tools are available!"
        return 0
    else
        error "$missing_tools required tools are missing"
        return 1
    fi
}

# Check development environment
check_dev_environment() {
    info "Checking development environment..."
    
    # Check Python
    if command_exists python3; then
        command_exists pip3 && success "✓ Python environment ready" || warn "⚠ pip3 not found"
    fi
    
    # Check Node.js
    if command_exists node; then
        command_exists npm && success "✓ Node.js environment ready" || warn "⚠ npm not found"
    fi
    
    # Check Ruby
    if command_exists ruby; then
        command_exists gem && success "✓ Ruby environment ready" || warn "⚠ gem not found"
    fi
    
    return 0
}

# Help function
usage() {
    cat << EOF
$SCRIPT_NAME - Verify Required Tools Installation

USAGE:
    $SCRIPT_NAME [OPTIONS]

DESCRIPTION:
    Verifies that all required tools are installed and accessible.
    Provides diagnostic information about the development environment.

OPTIONS:
    -h, --help       Show this help message
    -v, --verbose    Enable verbose debugging output

EXAMPLES:
    $SCRIPT_NAME                    # Basic tool verification
    $SCRIPT_NAME --verbose          # Detailed verification

EOF
}

# Main execution
main() {
    header "Tool Verification"
    
    # Check prerequisites
    check_macos
    check_homebrew || {
        error "Homebrew is required but not installed"
        return 1
    }
    
    # Check shell
    local current_shell=$(basename "$SHELL")
    info "Current shell: $current_shell"
    [[ "$current_shell" != "zsh" ]] && warn "This project is optimised for zsh"
    
    # Verify required tools
    verify_tools || return 1
    
    # Check development environment
    check_dev_environment
    
    success "Tool verification completed successfully!"
    info "All required tools are properly installed and configured"
    
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
            DEBUG=true
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
#!/usr/bin/env zsh
set -euo pipefail

# Script metadata and colour codes
readonly SCRIPT_NAME="${0:t}"
readonly SCRIPT_DIR="${0:A:h}"
readonly PROJECT_ROOT="${SCRIPT_DIR}/.."
readonly RED=$(tput setaf 1)
readonly GREEN=$(tput setaf 2)
readonly YELLOW=$(tput setaf 3)
readonly BLUE=$(tput setaf 4)
readonly CYAN=$(tput setaf 6)
readonly RESET=$(tput sgr0)

# Device type from command line
DEVICE_TYPE="${1:-macbook-pro}"

# Validation results
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNING_CHECKS=0

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
    echo "${CYAN}[DEBUG]${RESET} $*" >&2
}

# Validation result tracking
check_passed() {
    ((TOTAL_CHECKS++))
    ((PASSED_CHECKS++))
    success "✓ $*"
}

check_failed() {
    ((TOTAL_CHECKS++))
    ((FAILED_CHECKS++))
    error "✗ $*"
}

check_warning() {
    ((TOTAL_CHECKS++))
    ((WARNING_CHECKS++))
    warn "⚠ $*"
}

# Validate Homebrew installation
validate_homebrew() {
    info "Validating Homebrew installation..."
    
    if command -v brew &>/dev/null; then
        check_passed "Homebrew is installed and accessible"
        
        # Check Homebrew health
        if brew doctor &>/dev/null; then
            check_passed "Homebrew doctor check passed"
        else
            check_warning "Homebrew doctor found issues (run 'brew doctor' for details)"
        fi
        
        # Check Homebrew version
        local brew_version
        brew_version=$(brew --version | head -1)
        check_passed "Homebrew version: $brew_version"
        
        # Check package counts
        local formula_count cask_count
        formula_count=$(brew list --formula 2>/dev/null | wc -l | xargs)
        cask_count=$(brew list --cask 2>/dev/null | wc -l | xargs)
        
        if [[ $formula_count -gt 0 ]]; then
            check_passed "$formula_count Homebrew formulae installed"
        else
            check_warning "No Homebrew formulae installed"
        fi
        
        if [[ $cask_count -gt 0 ]]; then
            check_passed "$cask_count Homebrew casks installed"
        else
            check_warning "No Homebrew casks installed"
        fi
        
    else
        check_failed "Homebrew is not installed or not in PATH"
    fi
}

# Validate essential tools
validate_essential_tools() {
    info "Validating essential tools..."
    
    local essential_tools=(
        "git:Version control system"
        "zsh:Z shell"
        "curl:Data transfer tool"
        "jq:JSON processor"
        "rg:Ripgrep search tool"
        "bat:Better cat with syntax highlighting"
        "eza:Modern ls replacement"
        "fzf:Fuzzy finder"
    )
    
    for tool_spec in "${essential_tools[@]}"; do
        local tool="${tool_spec%%:*}"
        local description="${tool_spec##*:}"
        
        if command -v "$tool" &>/dev/null; then
            check_passed "$tool ($description) is available"
        else
            check_failed "$tool ($description) is missing"
        fi
    done
}

# Validate development environment
validate_development_environment() {
    info "Validating development environment..."
    
    # Python
    if command -v python3 &>/dev/null; then
        local python_version
        python_version=$(python3 --version 2>&1)
        check_passed "Python: $python_version"
        
        if command -v pip3 &>/dev/null; then
            check_passed "pip3 is available"
        else
            check_warning "pip3 is not available"
        fi
        
        if command -v uv &>/dev/null; then
            check_passed "uv (fast Python package installer) is available"
        else
            check_warning "uv is not installed"
        fi
    else
        check_failed "Python 3 is not installed"
    fi
    
    # Node.js
    if command -v node &>/dev/null; then
        local node_version
        node_version=$(node --version)
        check_passed "Node.js: $node_version"
        
        if command -v npm &>/dev/null; then
            local npm_version
            npm_version=$(npm --version)
            check_passed "npm: $npm_version"
        else
            check_warning "npm is not available"
        fi
    else
        check_warning "Node.js is not installed"
    fi
    
    # Ruby
    if command -v ruby &>/dev/null; then
        local ruby_version
        ruby_version=$(ruby --version)
        check_passed "Ruby: $ruby_version"
    else
        check_warning "Ruby is not installed"
    fi
    
    # Git configuration
    if git config --global user.name &>/dev/null && git config --global user.email &>/dev/null; then
        local git_user git_email
        git_user=$(git config --global user.name)
        git_email=$(git config --global user.email)
        check_passed "Git configured: $git_user <$git_email>"
    else
        check_warning "Git user configuration is incomplete"
    fi
}

# Validate system configuration
validate_system_configuration() {
    info "Validating system configuration..."
    
    # Check timezone
    local current_tz
    current_tz=$(systemsetup -gettimezone 2>/dev/null | cut -d' ' -f2- || echo "unknown")
    if [[ "$current_tz" == *"Australia/Adelaide"* ]]; then
        check_passed "Timezone correctly set to Australia/Adelaide"
    else
        check_warning "Timezone is not set to Australia/Adelaide (current: $current_tz)"
    fi
    
    # Check locale settings
    if [[ "${LANG:-}" == *"en_AU"* ]]; then
        check_passed "Australian English locale configured"
    else
        check_warning "Australian English locale not configured (current: ${LANG:-unset})"
    fi
    
    # Check shell
    if [[ "$SHELL" == */zsh ]]; then
        check_passed "zsh is the default shell"
    else
        check_warning "zsh is not the default shell (current: $SHELL)"
    fi
    
    # Check FileVault status
    local filevault_status
    filevault_status=$(fdesetup status 2>/dev/null || echo "unknown")
    if [[ "$filevault_status" == *"On"* ]]; then
        check_passed "FileVault encryption is enabled"
    else
        check_warning "FileVault encryption status: $filevault_status"
    fi
}

# Validate device-specific configuration
validate_device_specific() {
    info "Validating device-specific configuration for: $DEVICE_TYPE"
    
    case "$DEVICE_TYPE" in
        "macbook-pro")
            # Check battery settings
            if system_profiler SPPowerDataType | grep -q "Battery" 2>/dev/null; then
                check_passed "Battery detected (MacBook Pro configuration appropriate)"
            else
                check_warning "No battery detected (unexpected for MacBook Pro)"
            fi
            
            # Check for MacBook Pro specific applications
            if [[ -d "/Applications/Jump Desktop.app" ]] || brew list --cask 2>/dev/null | grep -q "jump-desktop"; then
                check_passed "Jump Desktop found (appropriate for portable Mac)"
            else
                check_warning "Jump Desktop not found"
            fi
            ;;
            
        "mac-studio"|"mac-mini")
            # Check for desktop Mac specific tools
            if command -v htop &>/dev/null; then
                check_passed "htop monitoring tool available"
            else
                check_warning "htop monitoring tool not found"
            fi
            
            # Check for server/headless specific applications
            if [[ -d "/Applications/Jump Desktop Connect.app" ]] || brew list --cask 2>/dev/null | grep -q "jump-desktop-connect"; then
                check_passed "Jump Desktop Connect found (appropriate for headless Mac)"
            else
                check_warning "Jump Desktop Connect not found"
            fi
            ;;
    esac
}

# Validate network configuration
validate_network_configuration() {
    info "Validating network configuration..."
    
    # Check network interfaces
    local interfaces
    interfaces=$(networksetup -listallnetworkservices 2>/dev/null | grep -v "asterisk" | tail -n +2 || echo "")
    
    if [[ -n "$interfaces" ]]; then
        check_passed "Network interfaces detected"
        
        # Check for expected interface types based on device
        case "$DEVICE_TYPE" in
            "macbook-pro")
                if echo "$interfaces" | grep -qi "wi-fi\|wifi"; then
                    check_passed "Wi-Fi interface found (appropriate for MacBook Pro)"
                else
                    check_warning "Wi-Fi interface not found"
                fi
                ;;
            "mac-studio"|"mac-mini")
                if echo "$interfaces" | grep -qi "ethernet"; then
                    check_passed "Ethernet interface found (appropriate for desktop Mac)"
                else
                    check_warning "Ethernet interface not found"
                fi
                ;;
        esac
    else
        check_warning "Could not detect network interfaces"
    fi
    
    # Check internet connectivity
    if ping -c 1 -t 5 8.8.8.8 &>/dev/null; then
        check_passed "Internet connectivity verified"
    else
        check_warning "Internet connectivity test failed"
    fi
}

# Validate applications and tools
validate_applications() {
    info "Validating key applications..."
    
    local key_applications=(
        "1Password 7 - Password Manager.app:1Password password manager"
        "Raycast.app:Raycast productivity launcher"
        "Karabiner-Elements.app:Karabiner Elements keyboard customisation"
        "Zed.app:Zed code editor"
    )
    
    for app_spec in "${key_applications[@]}"; do
        local app_name="${app_spec%%:*}"
        local description="${app_spec##*:}"
        
        if [[ -d "/Applications/$app_name" ]]; then
            check_passed "$description is installed"
        else
            check_warning "$description is not installed"
        fi
    done
    
    # Check for chezmoi
    if command -v chezmoi &>/dev/null; then
        check_passed "chezmoi dotfile manager is available"
    else
        check_warning "chezmoi dotfile manager is not installed"
    fi
}

# Validate fonts
validate_fonts() {
    info "Validating fonts..."
    
    # Check for Maple Mono Nerd Font
    local font_dir="$HOME/Library/Fonts"
    if find "$font_dir" -name "*Maple*Mono*" -type f 2>/dev/null | grep -q .; then
        check_passed "Maple Mono Nerd Font found in user fonts"
    elif find "/Library/Fonts" -name "*Maple*Mono*" -type f 2>/dev/null | grep -q .; then
        check_passed "Maple Mono Nerd Font found in system fonts"
    elif find "/System/Library/Fonts" -name "*Maple*Mono*" -type f 2>/dev/null | grep -q .; then
        check_passed "Maple Mono Nerd Font found in system fonts"
    else
        check_warning "Maple Mono Nerd Font not found"
    fi
}

# Generate validation report
generate_report() {
    echo
    info "=========================================="
    info "Setup Validation Report"
    info "=========================================="
    info "Device Type: $DEVICE_TYPE"
    info "Total Checks: $TOTAL_CHECKS"
    echo
    
    if [[ $FAILED_CHECKS -eq 0 ]]; then
        success "✓ All critical validations passed: $PASSED_CHECKS/$TOTAL_CHECKS"
    else
        error "✗ Some validations failed: $FAILED_CHECKS failures, $PASSED_CHECKS successes"
    fi
    
    if [[ $WARNING_CHECKS -gt 0 ]]; then
        warn "⚠ Warnings found: $WARNING_CHECKS (non-critical issues)"
    fi
    
    echo
    
    # Overall status
    if [[ $FAILED_CHECKS -eq 0 ]]; then
        success "=========================================="
        success "Setup validation completed successfully!"
        success "=========================================="
        info "Your $DEVICE_TYPE is properly configured and ready to use"
        return 0
    else
        error "=========================================="
        error "Setup validation found issues"
        error "=========================================="
        error "Please review the failed checks and resolve issues"
        return 1
    fi
}

# Help function
usage() {
    cat << EOF
$SCRIPT_NAME - Setup Validation and Health Checks

USAGE:
    $SCRIPT_NAME [DEVICE_TYPE]

DESCRIPTION:
    Performs comprehensive validation of the macOS setup automation
    installation. Checks system configuration, tools, applications,
    and device-specific settings.

DEVICE_TYPE:
    macbook-pro    Portable development workstation
    mac-studio     Headless server infrastructure
    mac-mini       Lightweight development + multimedia
    
    Default: macbook-pro

VALIDATION AREAS:
    • Homebrew installation and package management
    • Essential development tools and CLI utilities
    • Development environment (Python, Node.js, Ruby, Git)
    • System configuration (timezone, locale, security)
    • Device-specific settings and applications
    • Network configuration and connectivity
    • Key applications and productivity tools
    • Font installation (Maple Mono Nerd Font)

EXAMPLES:
    $SCRIPT_NAME                    # Validate MacBook Pro setup
    $SCRIPT_NAME mac-studio         # Validate Mac Studio setup
    $SCRIPT_NAME mac-mini           # Validate Mac Mini setup

EXIT CODES:
    0    All validations passed
    1    Some validations failed

NOTES:
    • Non-destructive validation only
    • Provides detailed report of setup status
    • Identifies missing components and configuration issues

EOF
}

# Main validation process
main() {
    info "macOS Setup Validation"
    info "====================="
    info "Device type: $DEVICE_TYPE"
    info "Validating installation and configuration..."
    echo
    
    # Run all validation checks
    validate_homebrew
    echo
    
    validate_essential_tools
    echo
    
    validate_development_environment
    echo
    
    validate_system_configuration
    echo
    
    validate_device_specific
    echo
    
    validate_network_configuration
    echo
    
    validate_applications
    echo
    
    validate_fonts
    
    # Generate final report
    generate_report
}

# Parse command line arguments
case "${1:-}" in
    -h|--help)
        usage
        exit 0
        ;;
    macbook-pro|mac-studio|mac-mini)
        DEVICE_TYPE="$1"
        ;;
    "")
        # Use default
        ;;
    *)
        error "Invalid device type: $1"
        usage
        exit 1
        ;;
esac

# Run main function
main
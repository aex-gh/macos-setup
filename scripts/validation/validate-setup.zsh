#!/usr/bin/env zsh

# Script metadata
readonly SCRIPT_NAME="${0:t}"
readonly SCRIPT_DIR="${0:A:h}"

# Load common library
source "${SCRIPT_DIR}/../lib/common.zsh"

# Configuration
readonly DEVICE_TYPE="${1:-$(detect_device_type)}"

# Validation counters
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0

# Check result tracking
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

# Validate Homebrew using brew doctor
validate_homebrew() {
    info "Validating Homebrew installation..."
    
    if ! check_homebrew; then
        check_failed "Homebrew not installed"
        return 1
    fi
    
    check_passed "Homebrew is installed"
    
    # Use brew doctor for comprehensive validation
    if brew doctor &>/dev/null; then
        check_passed "Homebrew doctor check passed"
    else
        check_failed "Homebrew doctor found issues"
        info "Run 'brew doctor' for details"
    fi
    
    # Check package installation using brew bundle
    local common_brewfile device_brewfile
    common_brewfile=$(get_common_brewfile_path)
    device_brewfile=$(get_brewfile_path "$DEVICE_TYPE")
    
    if [[ -f "$common_brewfile" ]]; then
        cd "$(dirname "$common_brewfile")"
        if brew bundle check --file="$common_brewfile" &>/dev/null; then
            check_passed "Common packages validated"
        else
            check_failed "Common packages missing"
        fi
    fi
    
    if [[ -f "$device_brewfile" ]]; then
        cd "$(dirname "$device_brewfile")"
        if brew bundle check --file="$device_brewfile" &>/dev/null; then
            check_passed "Device-specific packages validated"
        else
            check_failed "Device-specific packages missing"
        fi
    fi
}

# Validate system configuration
validate_system() {
    info "Validating system configuration..."
    
    # Check macOS version
    local macos_version
    macos_version=$(sw_vers -productVersion)
    if is_version_gte "$macos_version" "11.0"; then
        check_passed "macOS version: $macos_version"
    else
        check_failed "macOS version too old: $macos_version"
    fi
    
    # Check shell
    local current_shell
    current_shell=$(basename "$SHELL")
    if [[ "$current_shell" == "zsh" ]]; then
        check_passed "Shell: $current_shell"
    else
        check_failed "Shell not zsh: $current_shell"
    fi
    
    # Check essential directories
    local essential_dirs=(
        "/opt/homebrew/bin"
        "/usr/local/bin"
        "$HOME/.config"
        "$HOME/Library/Application Support"
    )
    
    for dir in "${essential_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            check_passed "Directory exists: $dir"
        fi
    done
}

# Validate essential tools
validate_tools() {
    info "Validating essential tools..."
    
    local essential_tools=(
        "git" "jq" "curl" "rg" "bat" "eza" "fzf"
        "python3" "node" "brew" "chezmoi"
    )
    
    for tool in "${essential_tools[@]}"; do
        if command_exists "$tool"; then
            check_passed "$tool is available"
        else
            check_failed "$tool not found"
        fi
    done
}

# Validate device-specific configuration
validate_device_config() {
    info "Validating device-specific configuration..."
    
    case "$DEVICE_TYPE" in
        macbook-pro)
            check_passed "Device type: MacBook Pro (portable)"
            ;;
        mac-studio)
            check_passed "Device type: Mac Studio (server)"
            # Additional server-specific checks could go here
            ;;
        mac-mini)
            check_passed "Device type: Mac Mini (lightweight)"
            ;;
        *)
            check_failed "Unknown device type: $DEVICE_TYPE"
            ;;
    esac
}

# Help function
usage() {
    cat << EOF
$SCRIPT_NAME - Validate macOS Setup

USAGE:
    $SCRIPT_NAME [OPTIONS] [DEVICE_TYPE]

DESCRIPTION:
    Validates the macOS setup by checking Homebrew, system configuration,
    essential tools, and device-specific settings.

OPTIONS:
    -h, --help           Show this help message
    -v, --verbose        Enable verbose output

DEVICE_TYPE:
    Auto-detected if not specified. Valid types:
    macbook-pro, mac-studio, mac-mini

EXAMPLES:
    $SCRIPT_NAME                    # Auto-detect device type
    $SCRIPT_NAME mac-studio         # Validate Mac Studio setup

EOF
}

# Main validation
main() {
    local device_type="${1:-$(detect_device_type)}"
    
    header "Setup Validation for $device_type"
    
    # Check prerequisites
    check_macos
    
    # Run validation checks
    validate_homebrew
    echo
    validate_system
    echo
    validate_tools
    echo
    validate_device_config
    echo
    
    # Summary
    info "Validation Summary:"
    info "  Total checks: $TOTAL_CHECKS"
    info "  Passed: $PASSED_CHECKS"
    info "  Failed: $FAILED_CHECKS"
    
    if [[ $FAILED_CHECKS -eq 0 ]]; then
        success "All validation checks passed!"
        return 0
    else
        error "Validation failed: $FAILED_CHECKS check(s) failed"
        return 1
    fi
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
        -*)
            error "Unknown option: $1"
            usage
            exit 1
            ;;
        *)
            DEVICE_TYPE="$1"
            shift
            ;;
    esac
done

# Run main function
main "$DEVICE_TYPE"
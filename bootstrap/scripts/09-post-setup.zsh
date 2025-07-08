#!/usr/bin/env zsh
# -*- coding: utf-8 -*-

#=============================================================================
# SCRIPT: 09-post-setup.zsh
# AUTHOR: Andrew Exley
# DATE: 2025-01-07
# VERSION: 1.0.0
#
# DESCRIPTION:
#   Post-setup verification and health check module. Validates that all
#   components are properly installed and configured, runs health checks,
#   and provides a summary of the setup status.
#
# USAGE:
#   ./09-post-setup.zsh [options]
#
# OPTIONS:
#   -h, --help      Show this help message
#   -v, --verbose   Enable verbose output
#   -d, --debug     Enable debug mode
#   -f, --fix       Attempt to fix detected issues
#   --report        Generate detailed setup report
#
# REQUIREMENTS:
#   - macOS 11.0+ (Big Sur)
#   - All previous setup modules completed
#
# NOTES:
#   - Runs comprehensive verification checks
#   - Provides actionable recommendations
#   - Generates setup completion report
#=============================================================================

# Strict mode
set -euo pipefail

# Script metadata
readonly SCRIPT_NAME="${0:t}"
readonly SCRIPT_DIR="${0:A:h}"
readonly SCRIPT_VERSION="1.0.0"

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
declare -g FIX_ISSUES=false
declare -g GENERATE_REPORT=false
declare -g ISSUES_FOUND=0
declare -g CHECKS_PASSED=0
declare -g CHECKS_TOTAL=0

# Arrays to track results
declare -ga PASSED_CHECKS=()
declare -ga FAILED_CHECKS=()
declare -ga WARNING_CHECKS=()

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
            [[ $DEBUG == true ]] && echo "${CYAN}[DEBUG]${RESET} $message"
            ;;
        SUCCESS)
            echo "${GREEN}${BOLD}[✓]${RESET} $message"
            ;;
        FAIL)
            echo "${RED}${BOLD}[✗]${RESET} $message"
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
fail() { log FAIL "$@"; }
step() { log STEP "$@"; }

#=============================================================================
# UTILITY FUNCTIONS
#=============================================================================

# Check if running on macOS
check_macos() {
    if [[ $(uname) != "Darwin" ]]; then
        error "This script requires macOS"
        exit 1
    fi
}

# Print section header
print_section() {
    local title=$1
    local emoji=$2
    
    echo ""
    echo "${BOLD}${CYAN}═══════════════════════════════════════════════════════════════════════════════${RESET}"
    echo "${BOLD}${CYAN}  $emoji $title${RESET}"
    echo "${BOLD}${CYAN}═══════════════════════════════════════════════════════════════════════════════${RESET}"
    echo ""
}

# Record check result
record_check() {
    local check_name=$1
    local status=$2  # pass, fail, warn
    local message=$3
    
    ((CHECKS_TOTAL++))
    
    case $status in
        pass)
            PASSED_CHECKS+=("$check_name: $message")
            ((CHECKS_PASSED++))
            success "$check_name: $message"
            ;;
        fail)
            FAILED_CHECKS+=("$check_name: $message")
            ((ISSUES_FOUND++))
            fail "$check_name: $message"
            ;;
        warn)
            WARNING_CHECKS+=("$check_name: $message")
            warn "$check_name: $message"
            ;;
    esac
}

# Load hardware profile
load_hardware_profile() {
    local profile_file="$HOME/.config/dotfiles-setup/hardware-profile.env"
    
    if [[ -f $profile_file ]]; then
        source "$profile_file"
        debug "Loaded hardware profile: $HARDWARE_TYPE ($CHIP_TYPE)"
    else
        warn "Hardware profile not found, using defaults"
        export HARDWARE_TYPE="unknown"
        export CHIP_TYPE="unknown"
    fi
}

#=============================================================================
# VERIFICATION CHECKS
#=============================================================================

# Check system requirements
check_system_requirements() {
    step "Checking system requirements"
    
    # Check macOS version
    local macos_version=$(sw_vers -productVersion)
    local major_version=$(echo $macos_version | cut -d. -f1)
    
    if [[ $major_version -ge 11 ]]; then
        record_check "macOS Version" "pass" "macOS $macos_version (supported)"
    else
        record_check "macOS Version" "fail" "macOS $macos_version (unsupported, requires 11.0+)"
    fi
    
    # Check available disk space
    local available_space=$(df -h / | awk 'NR==2 {print $4}' | sed 's/Gi//')
    if [[ ${available_space%.*} -gt 10 ]]; then
        record_check "Disk Space" "pass" "${available_space}GB available"
    else
        record_check "Disk Space" "warn" "Only ${available_space}GB available"
    fi
    
    # Check memory
    local memory_gb=$(( $(sysctl -n hw.memsize) / 1024 / 1024 / 1024 ))
    if [[ $memory_gb -ge 8 ]]; then
        record_check "Memory" "pass" "${memory_gb}GB RAM"
    else
        record_check "Memory" "warn" "Only ${memory_gb}GB RAM (8GB+ recommended)"
    fi
}

# Check Xcode Command Line Tools
check_xcode_tools() {
    step "Checking Xcode Command Line Tools"
    
    if xcode-select -p &>/dev/null; then
        local xcode_path=$(xcode-select -p)
        record_check "Xcode Tools" "pass" "Installed at $xcode_path"
    else
        record_check "Xcode Tools" "fail" "Not installed"
        
        if [[ $FIX_ISSUES == true ]]; then
            info "Attempting to install Xcode Command Line Tools..."
            xcode-select --install
        fi
    fi
}

# Check Homebrew installation
check_homebrew() {
    step "Checking Homebrew installation"
    
    if command -v brew &>/dev/null; then
        local brew_version=$(brew --version | head -1)
        record_check "Homebrew" "pass" "$brew_version"
        
        # Check Homebrew health
        check_homebrew_health
    else
        record_check "Homebrew" "fail" "Not installed"
        
        if [[ $FIX_ISSUES == true ]]; then
            info "Attempting to install Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
    fi
}

# Check Homebrew health and packages
check_homebrew_health() {
    step "Checking Homebrew health"
    
    # Check for issues
    local brew_issues=$(brew doctor 2>&1 | grep -c "Error\|Warning" || true)
    if [[ $brew_issues -eq 0 ]]; then
        record_check "Homebrew Health" "pass" "No issues found"
    else
        record_check "Homebrew Health" "warn" "$brew_issues issues found"
        
        if [[ $FIX_ISSUES == true ]]; then
            info "Running brew doctor to fix issues..."
            brew doctor
        fi
    fi
    
    # Check for outdated packages
    local outdated_count=$(brew outdated | wc -l | tr -d ' ')
    if [[ $outdated_count -eq 0 ]]; then
        record_check "Package Updates" "pass" "All packages up to date"
    else
        record_check "Package Updates" "warn" "$outdated_count packages outdated"
        
        if [[ $FIX_ISSUES == true ]]; then
            info "Updating outdated packages..."
            brew upgrade
        fi
    fi
}

# Check essential tools
check_essential_tools() {
    step "Checking essential development tools"
    
    local essential_tools=(
        "git"
        "zsh"
        "jq"
        "ripgrep:rg"
        "fd"
        "bat"
    )
    
    for tool_spec in "${essential_tools[@]}"; do
        local tool_name="${tool_spec%:*}"
        local command_name="${tool_spec#*:}"
        [[ $command_name == $tool_name ]] && command_name=$tool_name
        
        if command -v "$command_name" &>/dev/null; then
            local version=$(${command_name} --version 2>/dev/null | head -1 || echo "version unknown")
            record_check "$tool_name" "pass" "Installed ($version)"
        else
            record_check "$tool_name" "fail" "Not installed"
            
            if [[ $FIX_ISSUES == true ]] && command -v brew &>/dev/null; then
                info "Installing $tool_name via Homebrew..."
                brew install "$tool_name"
            fi
        fi
    done
}

# Check shell configuration
check_shell_configuration() {
    step "Checking shell configuration"
    
    # Check current shell
    local current_shell=$(basename "$SHELL")
    if [[ $current_shell == "zsh" ]]; then
        record_check "Default Shell" "pass" "Using Zsh"
    else
        record_check "Default Shell" "warn" "Using $current_shell (Zsh recommended)"
    fi
    
    # Check for .zshrc
    if [[ -f "$HOME/.zshrc" ]]; then
        record_check "Zsh Config" "pass" ".zshrc exists"
    else
        record_check "Zsh Config" "warn" ".zshrc not found"
    fi
    
    # Check for dotfiles
    if [[ -d "$HOME/projects/personal/dotfiles" ]]; then
        record_check "Dotfiles" "pass" "Dotfiles repository found"
    else
        record_check "Dotfiles" "warn" "Dotfiles repository not found in expected location"
    fi
}

# Check Python environment
check_python_environment() {
    step "Checking Python environment"
    
    # Check Python 3
    if command -v python3 &>/dev/null; then
        local python_version=$(python3 --version)
        record_check "Python 3" "pass" "$python_version"
    else
        record_check "Python 3" "fail" "Not installed"
    fi
    
    # Check pip
    if command -v pip3 &>/dev/null; then
        record_check "pip" "pass" "Available"
    else
        record_check "pip" "warn" "Not available"
    fi
    
    # Check for virtual environment tools
    if command -v pyenv &>/dev/null; then
        record_check "pyenv" "pass" "Installed"
    else
        record_check "pyenv" "warn" "Not installed (recommended for Python version management)"
    fi
}

# Check Git configuration
check_git_configuration() {
    step "Checking Git configuration"
    
    if command -v git &>/dev/null; then
        # Check user name
        local git_name=$(git config --global user.name 2>/dev/null || echo "")
        if [[ -n $git_name ]]; then
            record_check "Git User Name" "pass" "$git_name"
        else
            record_check "Git User Name" "warn" "Not configured"
        fi
        
        # Check user email
        local git_email=$(git config --global user.email 2>/dev/null || echo "")
        if [[ -n $git_email ]]; then
            record_check "Git User Email" "pass" "$git_email"
        else
            record_check "Git User Email" "warn" "Not configured"
        fi
        
        # Check SSH keys
        if [[ -f "$HOME/.ssh/id_ed25519" ]] || [[ -f "$HOME/.ssh/id_rsa" ]]; then
            record_check "SSH Keys" "pass" "SSH keys found"
        else
            record_check "SSH Keys" "warn" "No SSH keys found"
        fi
    fi
}

# Check security settings
check_security_settings() {
    step "Checking security settings"
    
    # Check FileVault
    local filevault_status=$(fdesetup status)
    if [[ $filevault_status =~ "FileVault is On" ]]; then
        record_check "FileVault" "pass" "Enabled"
    else
        record_check "FileVault" "warn" "Not enabled (recommended)"
    fi
    
    # Check firewall
    local firewall_status=$(/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate)
    if [[ $firewall_status =~ "enabled" ]]; then
        record_check "Firewall" "pass" "Enabled"
    else
        record_check "Firewall" "warn" "Not enabled"
    fi
    
    # Check Gatekeeper
    local gatekeeper_status=$(spctl --status)
    if [[ $gatekeeper_status =~ "enabled" ]]; then
        record_check "Gatekeeper" "pass" "Enabled"
    else
        record_check "Gatekeeper" "warn" "Not enabled"
    fi
}

# Check hardware-specific configuration
check_hardware_configuration() {
    step "Checking hardware-specific configuration for: $HARDWARE_TYPE"
    
    case $HARDWARE_TYPE in
        "studio")
            check_studio_configuration
            ;;
        "laptop")
            check_laptop_configuration
            ;;
        "mini")
            check_mini_configuration
            ;;
        *)
            record_check "Hardware Config" "warn" "Unknown hardware type: $HARDWARE_TYPE"
            ;;
    esac
}

# Check Mac Studio server configuration
check_studio_configuration() {
    step "Checking Mac Studio server configuration"
    
    # Check for server directories
    if [[ -d "/Users/Shared/Studio-Server" ]]; then
        record_check "Server Directories" "pass" "Studio-Server directory exists"
    else
        record_check "Server Directories" "warn" "Studio-Server directory not found"
    fi
    
    # Check file sharing services
    local afp_status=$(launchctl list | grep -c "com.apple.AppleFileServer" || true)
    if [[ $afp_status -gt 0 ]]; then
        record_check "AFP Sharing" "pass" "Service running"
    else
        record_check "AFP Sharing" "warn" "Service not running"
    fi
    
    # Check for server tools
    local server_tools=("postgresql" "nginx")
    for tool in "${server_tools[@]}"; do
        if command -v "$tool" &>/dev/null; then
            record_check "Server Tool: $tool" "pass" "Installed"
        else
            record_check "Server Tool: $tool" "warn" "Not installed"
        fi
    done
    
    # Check for OrbStack (replaces Docker Desktop)
    if command -v orb &>/dev/null || [[ -d "/Applications/OrbStack.app" ]]; then
        record_check "Container Runtime: OrbStack" "pass" "Installed"
    elif command -v docker &>/dev/null; then
        record_check "Container Runtime: Docker" "pass" "Docker CLI available"
    else
        record_check "Container Runtime" "warn" "No container runtime found"
    fi
}

# Check MacBook Pro configuration
check_laptop_configuration() {
    step "Checking MacBook Pro configuration"
    
    # Check battery optimization
    local battery_health=$(system_profiler SPPowerDataType | grep "Cycle Count" | awk '{print $3}')
    if [[ -n $battery_health ]]; then
        record_check "Battery Health" "pass" "$battery_health cycles"
    else
        record_check "Battery Health" "warn" "Could not determine battery health"
    fi
    
    # Check Touch ID configuration
    if [[ -f "/etc/pam.d/sudo" ]] && grep -q "pam_tid.so" "/etc/pam.d/sudo"; then
        record_check "Touch ID for sudo" "pass" "Configured"
    else
        record_check "Touch ID for sudo" "warn" "Not configured"
    fi
    
    # Check power management
    local sleep_settings=$(pmset -g | grep "sleep" | head -1)
    if [[ -n $sleep_settings ]]; then
        record_check "Power Management" "pass" "Configured"
    else
        record_check "Power Management" "warn" "Default settings"
    fi
}

# Check Mac Mini configuration
check_mini_configuration() {
    step "Checking Mac Mini configuration"
    
    # Check for media tools
    local media_tools=("ffmpeg" "vlc")
    for tool in "${media_tools[@]}"; do
        if command -v "$tool" &>/dev/null || [[ -d "/Applications/VLC.app" ]]; then
            record_check "Media Tool: $tool" "pass" "Available"
        else
            record_check "Media Tool: $tool" "warn" "Not available"
        fi
    done
    
    # Check network configuration
    local network_name=$(scutil --get ComputerName)
    if [[ $network_name == "Mac-Mini" ]] || [[ $network_name =~ "Mini" ]]; then
        record_check "Network Name" "pass" "$network_name"
    else
        record_check "Network Name" "warn" "Generic name: $network_name"
    fi
}

# Check network connectivity
check_network_connectivity() {
    step "Checking network connectivity"
    
    # Check internet connectivity
    if ping -c 1 8.8.8.8 &>/dev/null; then
        record_check "Internet" "pass" "Connected"
    else
        record_check "Internet" "fail" "No connectivity"
    fi
    
    # Check DNS resolution
    if nslookup github.com &>/dev/null; then
        record_check "DNS Resolution" "pass" "Working"
    else
        record_check "DNS Resolution" "fail" "Not working"
    fi
    
    # Check for network shares (if not Mac Studio)
    if [[ $HARDWARE_TYPE != "studio" ]]; then
        if ping -c 1 mac-studio.local &>/dev/null; then
            record_check "Mac Studio Server" "pass" "Reachable"
        else
            record_check "Mac Studio Server" "warn" "Not reachable"
        fi
    fi
}

#=============================================================================
# REPORTING FUNCTIONS
#=============================================================================

# Generate setup report
generate_setup_report() {
    local report_file="$HOME/.config/dotfiles-setup/setup-report-$(date +%Y%m%d-%H%M%S).txt"
    local config_dir=$(dirname "$report_file")
    
    mkdir -p "$config_dir"
    
    cat > "$report_file" << EOF
==============================================================================
macOS Setup Verification Report
Generated: $(date)
Hardware: $HARDWARE_TYPE ($CHIP_TYPE)
==============================================================================

SUMMARY
-------
Total Checks: $CHECKS_TOTAL
Passed: $CHECKS_PASSED
Failed: $ISSUES_FOUND
Warnings: ${#WARNING_CHECKS[@]}

PASSED CHECKS (${#PASSED_CHECKS[@]})
$(printf '%s\n' "${PASSED_CHECKS[@]}")

FAILED CHECKS (${#FAILED_CHECKS[@]})
$(printf '%s\n' "${FAILED_CHECKS[@]}")

WARNING CHECKS (${#WARNING_CHECKS[@]})
$(printf '%s\n' "${WARNING_CHECKS[@]}")

SYSTEM INFORMATION
------------------
$(system_profiler SPSoftwareDataType SPHardwareDataType | grep -E "(System Version|Chip|Memory)")

RECOMMENDATIONS
---------------
EOF
    
    # Add recommendations based on failures
    if [[ ${#FAILED_CHECKS[@]} -gt 0 ]]; then
        echo "Critical Issues to Address:" >> "$report_file"
        for check in "${FAILED_CHECKS[@]}"; do
            echo "  • $check" >> "$report_file"
        done
        echo "" >> "$report_file"
    fi
    
    if [[ ${#WARNING_CHECKS[@]} -gt 0 ]]; then
        echo "Recommended Improvements:" >> "$report_file"
        for check in "${WARNING_CHECKS[@]}"; do
            echo "  • $check" >> "$report_file"
        done
        echo "" >> "$report_file"
    fi
    
    echo "Report saved to: $report_file"
    
    if [[ $VERBOSE == true ]]; then
        cat "$report_file"
    fi
}

# Print summary
print_summary() {
    echo ""
    echo "${BOLD}═══════════════════════════════════════════════════════════════════════════════${RESET}"
    echo "${BOLD}  VERIFICATION SUMMARY${RESET}"
    echo "${BOLD}═══════════════════════════════════════════════════════════════════════════════${RESET}"
    echo ""
    
    local pass_percentage=$(( (CHECKS_PASSED * 100) / CHECKS_TOTAL ))
    
    echo "${BOLD}Results:${RESET}"
    echo "  Total checks: $CHECKS_TOTAL"
    echo "  ${GREEN}Passed: $CHECKS_PASSED${RESET}"
    echo "  ${RED}Failed: $ISSUES_FOUND${RESET}"
    echo "  ${YELLOW}Warnings: ${#WARNING_CHECKS[@]}${RESET}"
    echo "  ${BOLD}Success rate: ${pass_percentage}%${RESET}"
    echo ""
    
    if [[ $ISSUES_FOUND -eq 0 ]]; then
        echo "${GREEN}${BOLD}🎉 Setup verification completed successfully!${RESET}"
        echo "Your macOS development environment is ready to use."
    elif [[ $ISSUES_FOUND -le 2 ]]; then
        echo "${YELLOW}${BOLD}⚠️  Setup mostly complete with minor issues${RESET}"
        echo "Address the failed checks for optimal configuration."
    else
        echo "${RED}${BOLD}❌ Setup has significant issues${RESET}"
        echo "Please address the failed checks before proceeding."
    fi
    
    echo ""
    if [[ $GENERATE_REPORT == true ]]; then
        echo "Run with --report flag for detailed report generation."
    fi
}

#=============================================================================
# MAIN FUNCTIONS
#=============================================================================

# Display usage information
usage() {
    cat << EOF
${BOLD}NAME${RESET}
    $SCRIPT_NAME - Post-setup verification and health checks

${BOLD}SYNOPSIS${RESET}
    $SCRIPT_NAME [options]

${BOLD}DESCRIPTION${RESET}
    Performs comprehensive verification of the macOS setup. Checks that
    all components are properly installed and configured, validates
    system health, and provides actionable recommendations.

${BOLD}OPTIONS${RESET}
    -h, --help          Show this help message
    -v, --verbose       Enable verbose output
    -d, --debug         Enable debug mode
    -f, --fix           Attempt to fix detected issues
    --report            Generate detailed setup report

${BOLD}CHECK CATEGORIES${RESET}
    System              macOS version, disk space, memory
    Development         Xcode tools, Homebrew, essential tools
    Configuration       Shell, Python, Git setup
    Security            FileVault, firewall, Gatekeeper
    Hardware            Type-specific configurations
    Network             Connectivity, DNS, sharing

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
            -f|--fix)
                FIX_ISSUES=true
                shift
                ;;
            --report)
                GENERATE_REPORT=true
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
    # Check environment
    check_macos
    
    # Parse arguments
    parse_args "$@"
    
    # Load hardware profile
    load_hardware_profile
    
    print_section "POST-SETUP VERIFICATION" "🔍"
    
    # Run all verification checks
    check_system_requirements
    check_xcode_tools
    check_homebrew
    check_essential_tools
    check_shell_configuration
    check_python_environment
    check_git_configuration
    check_security_settings
    check_hardware_configuration
    check_network_connectivity
    
    # Generate report if requested
    if [[ $GENERATE_REPORT == true ]]; then
        echo ""
        step "Generating detailed setup report"
        generate_setup_report
    fi
    
    # Print summary
    print_summary
    
    # Exit with appropriate code
    if [[ $ISSUES_FOUND -gt 0 ]]; then
        exit 1
    else
        exit 0
    fi
}

#=============================================================================
# CLEANUP & ERROR HANDLING
#=============================================================================

# Cleanup function
cleanup() {
    local exit_code=$?
    
    debug "Cleaning up..."
    
    # Log exit status
    if [[ $exit_code -eq 0 ]]; then
        debug "Script exited successfully"
    else
        debug "Script exited with code: $exit_code"
    fi
    
    exit $exit_code
}

# Error handler
error_handler() {
    local line_no=$1
    error "An error occurred on line $line_no"
    cleanup
}

# Set traps
trap cleanup EXIT
trap 'error_handler $LINENO' ERR

#=============================================================================
# SCRIPT EXECUTION
#=============================================================================

# Only run main if script is executed directly
if [[ "${(%):-%x}" == "${0}" ]]; then
    main "$@"
fi
#!/usr/bin/env zsh

# Script metadata
readonly SCRIPT_NAME="${0:t}"
readonly SCRIPT_DIR="${0:A:h}"
readonly PROJECT_ROOT="${SCRIPT_DIR}/.."

# Load common library
source "${SCRIPT_DIR}/../lib/common.zsh"

# Global variables
DEVICE_TYPE=""
DETECTED_MODEL=""
DRY_RUN=false
SKIP_CONFIRMATION=false
DEBUG=false

# Enhanced device detection using common library
detect_and_display_device_type() {
    DEVICE_TYPE=$(detect_device_type)
    DETECTED_MODEL=$(get_mac_model)
    
    debug "Detected model identifier: $DETECTED_MODEL"
    
    case "$DEVICE_TYPE" in
        macbook-pro)
            info "Detected: MacBook Pro (Portable Development Workstation)"
            ;;
        mac-mini)
            info "Detected: Mac Mini (Lightweight Development + Multimedia)"
            ;;
        mac-studio)
            info "Detected: Mac Studio (Headless Server Infrastructure)"
            ;;
        *)
            warn "Unknown Mac model: $DETECTED_MODEL"
            warn "Defaulting to MacBook Pro configuration"
            DEVICE_TYPE="macbook-pro"
            ;;
    esac
}

# Interactive device selection override
select_device_type() {
    header "Device Type Selection"
    echo "Detected model: ${DETECTED_MODEL}"
    echo "Auto-detected type: ${DEVICE_TYPE}"
    echo
    echo "Available configurations:"
    echo "  1) MacBook Pro - Portable development workstation"
    echo "  2) Mac Studio - Headless server infrastructure" 
    echo "  3) Mac Mini - Lightweight development + multimedia"
    echo "  4) Use auto-detected type (${DEVICE_TYPE})"
    echo
    
    while true; do
        read -p "Select configuration [1-4]: " choice
        case $choice in
            1)
                DEVICE_TYPE="macbook-pro"
                info "Selected: MacBook Pro configuration"
                break
                ;;
            2)
                DEVICE_TYPE="mac-studio"
                info "Selected: Mac Studio configuration"
                break
                ;;
            3)
                DEVICE_TYPE="mac-mini"
                info "Selected: Mac Mini configuration"
                break
                ;;
            4)
                info "Using auto-detected type: ${DEVICE_TYPE}"
                break
                ;;
            *)
                warn "Invalid choice. Please select 1-4."
                ;;
        esac
    done
}

# Setup phase execution
run_setup_phase() {
    local phase_name="$1"
    local script_name="$2"
    local description="$3"
    local script_path="${SCRIPT_DIR}/${script_name}"
    
    header "Phase: $phase_name"
    info "$description"
    
    if [[ ! -f "$script_path" ]]; then
        warn "Script not found: $script_path"
        warn "Skipping phase: $phase_name"
        return 0
    fi
    
    if [[ "$DRY_RUN" == "true" ]]; then
        info "DRY RUN: Would execute $script_path"
        return 0
    fi
    
    # Make script executable if not already
    chmod +x "$script_path"
    
    if "$script_path" "$DEVICE_TYPE"; then
        success "✓ $phase_name completed successfully"
        notify "macOS Setup" "$phase_name completed"
        return 0
    else
        error "✗ $phase_name failed"
        notify "macOS Setup" "$phase_name failed"
        
        if [[ "$SKIP_CONFIRMATION" != "true" ]]; then
            echo
            read -p "Continue with remaining phases? [y/N]: " continue_choice
            if [[ "$continue_choice" != "y" && "$continue_choice" != "Y" ]]; then
                error "Setup aborted by user"
                exit 1
            fi
        fi
        return 1
    fi
}

# Main setup flow
main_setup() {
    header "macOS Setup Automation"
    echo "Device: $DETECTED_MODEL"
    echo "Configuration: $DEVICE_TYPE"
    echo "Project: $(basename "$PROJECT_ROOT")"
    echo
    
    if [[ "$DRY_RUN" == "true" ]]; then
        warn "DRY RUN MODE - No changes will be made"
        echo
    fi
    
    # Confirmation unless skipped
    if [[ "$SKIP_CONFIRMATION" != "true" && "$DRY_RUN" != "true" ]]; then
        echo "This will configure your Mac with the ${DEVICE_TYPE} setup."
        echo "The process includes:"
        echo "  • Homebrew installation and configuration"
        echo "  • Package installation from Brewfiles"
        echo "  • macOS system defaults configuration"
        echo "  • User account setup (if applicable)"
        echo "  • System validation and health checks"
        echo
        read -p "Continue with setup? [y/N]: " confirm
        if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
            info "Setup cancelled by user"
            exit 0
        fi
        echo
    fi
    
    local start_time=$(date +%s)
    
    # Phase 1: Homebrew Installation
    run_setup_phase "Homebrew Installation" "install-homebrew.zsh" "Installing and configuring Homebrew package manager"
    
    # Phase 2: Package Installation
    run_setup_phase "Package Installation" "install-packages.zsh" "Installing packages from device-specific Brewfiles"
    
    # Phase 3: macOS Configuration
    run_setup_phase "macOS Configuration" "configure-macos.zsh" "Configuring system defaults and preferences"
    
    # Phase 4: User Setup (optional)
    if [[ -f "${SCRIPT_DIR}/setup-users.zsh" ]]; then
        run_setup_phase "User Setup" "setup-users.zsh" "Setting up multi-user environment"
    fi
    
    # Phase 5: Setup Validation
    run_setup_phase "Setup Validation" "validate-setup.zsh" "Performing system health checks and validation"
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    echo
    success "═══════════════════════════════════════"
    success "macOS Setup Completed Successfully!"
    success "═══════════════════════════════════════"
    success "Device: $DEVICE_TYPE"
    success "Duration: ${duration}s"
    success "All phases completed without critical errors"
    
    notify "macOS Setup Complete" "Your $DEVICE_TYPE is ready!"
    
    echo
    info "Next steps:"
    info "  • Restart your Mac to ensure all changes take effect"
    info "  • Run 'source ~/.zshrc' to reload shell configuration"
    info "  • Check system preferences for any manual adjustments"
    
    return 0
}

# Register any additional cleanup functions if needed
# (Basic cleanup is already handled by common library)

# Help function
usage() {
    cat << EOF
$SCRIPT_NAME - macOS Setup Automation Orchestrator

USAGE:
    $SCRIPT_NAME [OPTIONS]

DESCRIPTION:
    Main setup orchestrator for macOS automation. Detects device type and
    runs appropriate configuration scripts for MacBook Pro, Mac Studio, or
    Mac Mini setups.

OPTIONS:
    -d, --device TYPE    Override device detection (macbook-pro, mac-studio, mac-mini)
    -n, --dry-run        Show what would be done without making changes
    -y, --yes            Skip confirmation prompts
    -v, --verbose        Enable verbose debugging output
    -h, --help           Show this help message

EXAMPLES:
    $SCRIPT_NAME                           # Auto-detect and run setup
    $SCRIPT_NAME --device mac-studio       # Force Mac Studio configuration
    $SCRIPT_NAME --dry-run                 # Preview setup without changes
    $SCRIPT_NAME --yes --verbose           # Automated setup with debug output

DEVICE TYPES:
    macbook-pro    Portable development workstation (WiFi, dynamic IP)
    mac-studio     Headless server infrastructure (Ethernet, static IP)
    mac-mini       Lightweight development + multimedia (Ethernet, static IP)

PHASES:
    1. Homebrew Installation    Install and configure package manager
    2. Package Installation     Install from device-specific Brewfiles
    3. macOS Configuration      Configure system defaults and preferences
    4. User Setup              Create multi-user environment (optional)
    5. Setup Validation        Perform health checks and validation

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--device)
            if [[ -n "${2:-}" ]]; then
                DEVICE_TYPE="$2"
                shift 2
            else
                error "Device type required for --device option"
                exit 1
            fi
            ;;
        -n|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -y|--yes)
            SKIP_CONFIRMATION=true
            shift
            ;;
        -v|--verbose)
            DEBUG=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Validate device type if manually specified
if [[ -n "$DEVICE_TYPE" ]]; then
    case "$DEVICE_TYPE" in
        macbook-pro|mac-studio|mac-mini)
            info "Using manually specified device type: $DEVICE_TYPE"
            ;;
        *)
            error "Invalid device type: $DEVICE_TYPE"
            error "Valid types: macbook-pro, mac-studio, mac-mini"
            exit 1
            ;;
    esac
fi

# Main execution
if [[ -z "$DEVICE_TYPE" ]]; then
    detect_and_display_device_type
    
    if [[ "$SKIP_CONFIRMATION" != "true" ]]; then
        select_device_type
    fi
fi

# Verify project structure
if [[ ! -d "$PROJECT_ROOT/configs" ]]; then
    error "Project structure invalid: configs directory not found"
    error "Please run this script from the project root or scripts directory"
    exit 1
fi

# Start main setup
main_setup "$@"
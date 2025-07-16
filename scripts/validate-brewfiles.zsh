#!/usr/bin/env zsh

# Script metadata
readonly SCRIPT_NAME="${0:t}"
readonly SCRIPT_DIR="${0:A:h}"
readonly PROJECT_ROOT="${SCRIPT_DIR}/.."

# Load common library
source "${SCRIPT_DIR}/lib/common.zsh"

# Validate Brewfile using brew bundle check
validate_brewfile() {
    local brewfile="$1"
    local brewfile_name="${brewfile:t}"
    local brewfile_dir="${brewfile:h}"
    
    if ! file_readable "$brewfile"; then
        error "Brewfile not found: $brewfile"
        return 1
    fi
    
    info "Validating $brewfile_name..."
    
    # Change to brewfile directory for proper relative path handling
    cd "$brewfile_dir" || return 1
    
    # Use brew bundle check for validation
    if brew bundle check --file="$brewfile" --verbose; then
        success "✓ $brewfile_name validation passed"
        return 0
    else
        error "✗ $brewfile_name validation failed"
        return 1
    fi
}

# Help function
usage() {
    cat << EOF
$SCRIPT_NAME - Validate Homebrew Brewfiles

USAGE:
    $SCRIPT_NAME [OPTIONS]

DESCRIPTION:
    Validates all Brewfiles using 'brew bundle check' to ensure
    packages are available in current Homebrew repositories.

OPTIONS:
    -h, --help    Show this help message

EXAMPLES:
    $SCRIPT_NAME                    # Validate all Brewfiles
    
EOF
}

# Main execution
main() {
    header "Brewfile Validation"
    
    # Check prerequisites
    check_macos
    check_homebrew || {
        error "Homebrew is required but not installed"
        return 1
    }
    
    # Find all Brewfiles
    local configs_dir="$PROJECT_ROOT/configs"
    
    if [[ ! -d "$configs_dir" ]]; then
        error "Configs directory not found: $configs_dir"
        return 1
    fi
    
    # Collect all Brewfiles
    local brewfiles=($(find "$configs_dir" -name "Brewfile" -type f))
    
    if [[ ${#brewfiles[@]} -eq 0 ]]; then
        error "No Brewfiles found in $configs_dir"
        return 1
    fi
    
    info "Found ${#brewfiles[@]} Brewfiles to validate"
    echo
    
    # Validate each Brewfile
    local total_errors=0
    for brewfile in "${brewfiles[@]}"; do
        if ! validate_brewfile "$brewfile"; then
            ((total_errors++))
        fi
        echo
    done
    
    # Final summary
    if [[ $total_errors -eq 0 ]]; then
        success "All Brewfiles validated successfully!"
        return 0
    else
        error "Validation failed for $total_errors Brewfile(s)"
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
        *)
            error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Run main function
main "$@"
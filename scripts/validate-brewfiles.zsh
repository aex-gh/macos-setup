#!/usr/bin/env zsh
set -euo pipefail

# Script metadata and colour codes
readonly SCRIPT_NAME="${0:t}"
readonly RED=$(tput setaf 1)
readonly GREEN=$(tput setaf 2)
readonly YELLOW=$(tput setaf 3)
readonly BLUE=$(tput setaf 4)
readonly RESET=$(tput sgr0)

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

# Main validation function
validate_brewfile() {
    local brewfile="$1"
    local errors=0
    local warnings=0
    
    if [[ ! -f "$brewfile" ]]; then
        error "Brewfile not found: $brewfile"
        return 1
    fi
    
    info "Validating Brewfile: $brewfile"
    
    # Extract brew formulae (lines starting with 'brew "')
    local formulae
    formulae=$(grep '^brew "' "$brewfile" | sed 's/brew "\([^"]*\)".*/\1/' || true)
    
    if [[ -n "$formulae" ]]; then
        info "Checking ${#${(f)formulae}} formulae..."
        while IFS= read -r formula; do
            if brew info "$formula" &>/dev/null; then
                success "✓ Formula exists: $formula"
            else
                error "✗ Formula not found: $formula"
                ((errors++))
            fi
        done <<< "$formulae"
    fi
    
    # Extract cask applications (lines starting with 'cask "')
    local casks
    casks=$(grep '^cask "' "$brewfile" | sed 's/cask "\([^"]*\)".*/\1/' || true)
    
    if [[ -n "$casks" ]]; then
        info "Checking ${#${(f)casks}} casks..."
        while IFS= read -r cask; do
            if brew info --cask "$cask" &>/dev/null; then
                success "✓ Cask exists: $cask"
            else
                error "✗ Cask not found: $cask"
                ((errors++))
            fi
        done <<< "$casks"
    fi
    
    # Extract Mac App Store applications (lines starting with 'mas "')
    local mas_apps
    mas_apps=$(grep '^mas "' "$brewfile" | sed 's/mas "\([^"]*\)".*/\1/' || true)
    
    if [[ -n "$mas_apps" ]]; then
        info "Found ${#${(f)mas_apps}} Mac App Store apps (cannot validate without mas CLI)"
        while IFS= read -r app; do
            warn "⚠ MAS app (unvalidated): $app"
            ((warnings++))
        done <<< "$mas_apps"
    fi
    
    # Summary
    echo
    if [[ $errors -eq 0 ]]; then
        success "Brewfile validation passed: $brewfile"
        if [[ $warnings -gt 0 ]]; then
            warn "Found $warnings warnings (MAS apps cannot be validated)"
        fi
        return 0
    else
        error "Brewfile validation failed: $brewfile ($errors errors, $warnings warnings)"
        return 1
    fi
}

# Check if Homebrew is installed
check_homebrew() {
    if ! command -v brew &>/dev/null; then
        error "Homebrew is not installed. Please install Homebrew first:"
        error "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        return 1
    fi
    
    info "Homebrew version: $(brew --version | head -1)"
    info "Updating Homebrew database..."
    brew update --quiet
}

# Main execution
main() {
    info "macOS Setup Automation - Brewfile Validation"
    info "=============================================="
    
    # Check prerequisites
    check_homebrew || return 1
    
    # Find all Brewfiles
    local brewfiles
    local script_dir="${0:A:h}"
    local project_root="${script_dir}/.."
    local configs_dir="${project_root}/configs"
    
    if [[ ! -d "$configs_dir" ]]; then
        error "Configs directory not found: $configs_dir"
        return 1
    fi
    
    # Collect all Brewfiles
    brewfiles=($(find "$configs_dir" -name "Brewfile" -type f))
    
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
    echo "=============================================="
    if [[ $total_errors -eq 0 ]]; then
        success "All Brewfiles validated successfully!"
        return 0
    else
        error "Validation failed for $total_errors Brewfile(s)"
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
    Validates all Brewfiles in the configs/ directory by checking if each
    formula and cask exists in the current Homebrew installation.

OPTIONS:
    -h, --help    Show this help message

EXAMPLES:
    $SCRIPT_NAME                    # Validate all Brewfiles
    
NOTES:
    - Requires Homebrew to be installed
    - Mac App Store (mas) applications cannot be validated without mas CLI
    - Updates Homebrew database before validation

EOF
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
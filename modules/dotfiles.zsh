#!/usr/bin/env zsh
# ABOUTME: Manages dotfiles using GNU Stow for automated symlink creation
# ABOUTME: Handles stow installation, package management, and configuration

set -euo pipefail

# Global variables
readonly SCRIPT_DIR="${0:A:h}"
readonly PROJECT_ROOT="${SCRIPT_DIR}/.."
readonly DOTFILES_DIR="${PROJECT_ROOT}/dotfiles"
readonly STOW_CONFIG="${PROJECT_ROOT}/.stowrc"

# Colours for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly RESET='\033[0m'

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${RESET} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${RESET} $*"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${RESET} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${RESET} $*"
}

# Check if stow is installed
check_stow_installed() {
    if ! command -v stow &> /dev/null; then
        log_error "GNU Stow is not installed. Please install it with: brew install stow"
        return 1
    fi
    return 0
}

# Check if dotfiles directory exists
check_dotfiles_directory() {
    if [[ ! -d "$DOTFILES_DIR" ]]; then
        log_error "Dotfiles directory not found: $DOTFILES_DIR"
        return 1
    fi
    return 0
}

# Check if stow configuration exists
check_stow_config() {
    if [[ ! -f "$STOW_CONFIG" ]]; then
        log_warning "Stow configuration not found: $STOW_CONFIG"
        log_info "Stow will use default configuration"
        return 1
    fi
    return 0
}

# List available dotfiles packages
list_dotfiles_packages() {
    log_info "Available dotfiles packages:"
    for package in "$DOTFILES_DIR"/*; do
        if [[ -d "$package" ]]; then
            local package_name=$(basename "$package")
            echo "  • $package_name"
        fi
    done
}

# Check if a package is already stowed
is_package_stowed() {
    local package="$1"
    local package_dir="$DOTFILES_DIR/$package"
    
    if [[ ! -d "$package_dir" ]]; then
        return 1
    fi
    
    # Check if any files from the package are symlinked to home directory
    local has_symlinks=false
    
    # Use BSD find (macOS default) with full path to avoid alias
    /usr/bin/find "$package_dir" -type f -name "dot-*" | while read -r file; do
        local relative_path="${file#$package_dir/}"
        local target_path="$HOME/${relative_path#dot-}"
        
        if [[ -L "$target_path" ]] && [[ "$(readlink "$target_path")" == "$file" ]]; then
            has_symlinks=true
            echo "true"
            return 0
        fi
    done | head -1 | grep -q "true"
}

# Stow a single package
stow_package() {
    local package="$1"
    local package_dir="$DOTFILES_DIR/$package"
    
    if [[ ! -d "$package_dir" ]]; then
        log_error "Package not found: $package"
        return 1
    fi
    
    log_info "Stowing package: $package"
    
    # Change to project root directory to use .stowrc
    pushd "$PROJECT_ROOT" > /dev/null
    
    # Temporarily disable .stowrc if it exists to avoid simulation mode issues
    local stowrc_backup=""
    if [[ -f ".stowrc" ]]; then
        stowrc_backup=".stowrc.temp.$$"
        mv ".stowrc" "$stowrc_backup"
    fi
    
    # Try stowing without --adopt first
    if stow --target="$HOME" --dir=dotfiles --dotfiles "$package" 2>/dev/null; then
        log_success "Successfully stowed: $package"
        local result=0
    else
        # If stowing failed, try with --adopt to handle conflicts
        if stow --target="$HOME" --dir=dotfiles --dotfiles --adopt "$package" 2>/dev/null; then
            log_success "Successfully stowed: $package (adopted existing files)"
            local result=0
        else
            log_error "Failed to stow: $package"
            local result=1
        fi
    fi
    
    # Restore .stowrc if it was backed up
    if [[ -n "$stowrc_backup" && -f "$stowrc_backup" ]]; then
        mv "$stowrc_backup" ".stowrc"
    fi
    
    popd > /dev/null
    return $result
}

# Unstow a single package
unstow_package() {
    local package="$1"
    local package_dir="$DOTFILES_DIR/$package"
    
    if [[ ! -d "$package_dir" ]]; then
        log_error "Package not found: $package"
        return 1
    fi
    
    log_info "Unstowing package: $package"
    
    # Change to project root directory to use .stowrc
    pushd "$PROJECT_ROOT" > /dev/null
    
    # Temporarily disable .stowrc if it exists to avoid simulation mode issues
    local stowrc_backup=""
    if [[ -f ".stowrc" ]]; then
        stowrc_backup=".stowrc.temp.$$"
        mv ".stowrc" "$stowrc_backup"
    fi
    
    if stow --target="$HOME" --dir=dotfiles --dotfiles -D "$package" 2>/dev/null; then
        log_success "Successfully unstowed: $package"
        local result=0
    else
        log_error "Failed to unstow: $package"
        local result=1
    fi
    
    # Restore .stowrc if it was backed up
    if [[ -n "$stowrc_backup" && -f "$stowrc_backup" ]]; then
        mv "$stowrc_backup" ".stowrc"
    fi
    
    popd > /dev/null
    return $result
}

# Restow a single package (unstow then stow)
restow_package() {
    local package="$1"
    local package_dir="$DOTFILES_DIR/$package"
    
    if [[ ! -d "$package_dir" ]]; then
        log_error "Package not found: $package"
        return 1
    fi
    
    log_info "Restowing package: $package"
    
    # Change to project root directory to use .stowrc
    pushd "$PROJECT_ROOT" > /dev/null
    
    # Temporarily disable .stowrc if it exists to avoid simulation mode issues
    local stowrc_backup=""
    if [[ -f ".stowrc" ]]; then
        stowrc_backup=".stowrc.temp.$$"
        mv ".stowrc" "$stowrc_backup"
    fi
    
    if stow --target="$HOME" --dir=dotfiles --dotfiles -R "$package" 2>/dev/null; then
        log_success "Successfully restowed: $package"
        local result=0
    else
        log_error "Failed to restow: $package"
        local result=1
    fi
    
    # Restore .stowrc if it was backed up
    if [[ -n "$stowrc_backup" && -f "$stowrc_backup" ]]; then
        mv "$stowrc_backup" ".stowrc"
    fi
    
    popd > /dev/null
    return $result
}

# Stow all packages
stow_all_packages() {
    log_info "Stowing all dotfiles packages..."
    
    local failed_packages=()
    
    for package in "$DOTFILES_DIR"/*; do
        if [[ -d "$package" ]]; then
            local package_name=$(basename "$package")
            if ! stow_package "$package_name"; then
                failed_packages+=("$package_name")
            fi
        fi
    done
    
    if [[ ${#failed_packages[@]} -eq 0 ]]; then
        log_success "All dotfiles packages stowed successfully!"
        return 0
    else
        log_error "Failed to stow packages: ${failed_packages[*]}"
        return 1
    fi
}

# Unstow all packages
unstow_all_packages() {
    log_info "Unstowing all dotfiles packages..."
    
    local failed_packages=()
    
    for package in "$DOTFILES_DIR"/*; do
        if [[ -d "$package" ]]; then
            local package_name=$(basename "$package")
            if ! unstow_package "$package_name"; then
                failed_packages+=("$package_name")
            fi
        fi
    done
    
    if [[ ${#failed_packages[@]} -eq 0 ]]; then
        log_success "All dotfiles packages unstowed successfully!"
        return 0
    else
        log_error "Failed to unstow packages: ${failed_packages[*]}"
        return 1
    fi
}

# Show status of all packages
show_dotfiles_status() {
    log_info "Dotfiles package status:"
    
    for package in "$DOTFILES_DIR"/*; do
        if [[ -d "$package" ]]; then
            local package_name=$(basename "$package")
            if is_package_stowed "$package_name"; then
                echo -e "  • ${GREEN}$package_name${RESET} (stowed)"
            else
                echo -e "  • ${YELLOW}$package_name${RESET} (not stowed)"
            fi
        fi
    done
}

# Preview what stow would do (simulation mode)
preview_stow_action() {
    local action="$1"
    local package="$2"
    
    log_info "Previewing stow action: $action $package"
    
    # Change to project root directory to use .stowrc
    pushd "$PROJECT_ROOT" > /dev/null
    
    case "$action" in
        "stow")
            stow --simulate "$package"
            ;;
        "unstow")
            stow --simulate -D "$package"
            ;;
        "restow")
            stow --simulate -R "$package"
            ;;
        *)
            log_error "Unknown action: $action"
            return 1
            ;;
    esac
    
    popd > /dev/null
}

# Main setup function - called from setup scripts
setup_dotfiles() {
    log_info "Setting up dotfiles with GNU Stow..."
    
    # Check prerequisites
    if ! check_stow_installed; then
        return 1
    fi
    
    if ! check_dotfiles_directory; then
        return 1
    fi
    
    check_stow_config || true  # Non-fatal
    
    # List available packages
    list_dotfiles_packages
    echo
    
    # Stow all packages
    if stow_all_packages; then
        log_success "Dotfiles setup completed successfully!"
        echo
        show_dotfiles_status
        return 0
    else
        log_error "Dotfiles setup failed"
        return 1
    fi
}

# Interactive mode for manual management
interactive_dotfiles_manager() {
    while true; do
        echo
        echo -e "${CYAN}=== Dotfiles Manager ===${RESET}"
        echo "1. List available packages"
        echo "2. Show package status"
        echo "3. Stow a package"
        echo "4. Unstow a package"
        echo "5. Restow a package"
        echo "6. Stow all packages"
        echo "7. Unstow all packages"
        echo "8. Preview stow action"
        echo "9. Exit"
        echo
        
        read -p "Choose an option (1-9): " choice
        
        case "$choice" in
            1)
                list_dotfiles_packages
                ;;
            2)
                show_dotfiles_status
                ;;
            3)
                read -p "Enter package name to stow: " package
                stow_package "$package"
                ;;
            4)
                read -p "Enter package name to unstow: " package
                unstow_package "$package"
                ;;
            5)
                read -p "Enter package name to restow: " package
                restow_package "$package"
                ;;
            6)
                stow_all_packages
                ;;
            7)
                unstow_all_packages
                ;;
            8)
                read -p "Enter action (stow/unstow/restow): " action
                read -p "Enter package name: " package
                preview_stow_action "$action" "$package"
                ;;
            9)
                log_info "Goodbye!"
                break
                ;;
            *)
                log_error "Invalid option. Please choose 1-9."
                ;;
        esac
    done
}

# If script is run directly, start interactive mode
# To run interactively: zsh -c "source modules/dotfiles.zsh && interactive_dotfiles_manager"
#!/usr/bin/env zsh
set -euo pipefail

readonly SCRIPT_NAME="${0:t}"
readonly RED=$(tput setaf 1)
readonly GREEN=$(tput setaf 2)
readonly YELLOW=$(tput setaf 3)
readonly BLUE=$(tput setaf 4)
readonly RESET=$(tput sgr0)

info() {
    echo "${BLUE}[INFO]${RESET} $*"
}

success() {
    echo "${GREEN}[SUCCESS]${RESET} $*"
}

warn() {
    echo "${YELLOW}[WARN]${RESET} $*"
}

error() {
    echo "${RED}[ERROR]${RESET} $*" >&2
}

cleanup() {
    local exit_code=$?
    if [[ ${exit_code} -ne 0 ]]; then
        error "Script failed with exit code ${exit_code}"
    fi
    exit ${exit_code}
}

trap cleanup EXIT INT TERM

check_prerequisites() {
    info "Checking prerequisites for linuxify installation..."
    
    # Check for git
    if ! command -v git >/dev/null 2>&1; then
        error "git is required for linuxify installation"
        exit 1
    fi
    
    # Check for curl
    if ! command -v curl >/dev/null 2>&1; then
        error "curl is required for linuxify installation"
        exit 1
    fi
    
    success "Prerequisites check passed"
}

download_linuxify() {
    info "Downloading linuxify from GitHub..."
    
    local install_dir="${HOME}/.local/share/linuxify"
    local repo_url="https://github.com/pkill37/linuxify.git"
    
    # Create installation directory
    mkdir -p "${install_dir}"
    
    # Clone or update the repository
    if [[ -d "${install_dir}/.git" ]]; then
        info "Updating existing linuxify installation..."
        cd "${install_dir}"
        git pull origin main
        cd - >/dev/null
    else
        info "Cloning linuxify repository..."
        if git clone "${repo_url}" "${install_dir}"; then
            success "Linuxify repository cloned successfully"
        else
            error "Failed to clone linuxify repository"
            exit 1
        fi
    fi
    
    success "Linuxify downloaded to ${install_dir}"
}

install_linuxify_commands() {
    info "Installing linuxify command aliases..."
    
    local install_dir="${HOME}/.local/share/linuxify"
    local bin_dir="${HOME}/.local/bin"
    local linuxify_script="${install_dir}/linuxify"
    
    # Create bin directory if it doesn't exist
    mkdir -p "${bin_dir}"
    
    # Check if the main linuxify script exists
    if [[ ! -f "${linuxify_script}" ]]; then
        error "Linuxify script not found at ${linuxify_script}"
        
        # Try to find the script in different locations
        if [[ -f "${install_dir}/linuxify.sh" ]]; then
            linuxify_script="${install_dir}/linuxify.sh"
            info "Found linuxify script at ${linuxify_script}"
        else
            error "Could not locate linuxify installation script"
            exit 1
        fi
    fi
    
    # Make the script executable
    chmod +x "${linuxify_script}"
    
    # Run the linuxify installation
    info "Running linuxify installation..."
    if "${linuxify_script}"; then
        success "Linuxify commands installed"
    else
        warn "Linuxify installation may have failed or been interrupted"
    fi
}

create_linuxify_config() {
    info "Creating linuxify configuration..."
    
    local config_dir="${HOME}/.config/linuxify"
    local config_file="${config_dir}/config.zsh"
    
    mkdir -p "${config_dir}"
    
    # Create configuration file with Australian locale settings
    cat > "${config_file}" << 'EOF'
# Linuxify Configuration for macOS Setup
# This file configures Linux-compatible command aliases on macOS

# Australian locale settings
export LANG="en_AU.UTF-8"
export LC_ALL="en_AU.UTF-8"
export TZ="Australia/Adelaide"

# Core Linux command aliases
alias apt='brew'
alias apt-get='brew'
alias apt-cache='brew search'
alias which='command -v'
alias service='launchctl'

# File system commands
alias ll='ls -la'
alias la='ls -la'
alias l='ls -l'

# Process management
alias ps='ps aux'
alias top='htop'
alias free='vm_stat'
alias df='df -h'
alias du='du -h'

# Network commands
alias netstat='lsof -i'
alias ss='lsof -i'
alias ifconfig='ifconfig'

# System information
alias lscpu='sysctl -n machdep.cpu.brand_string'
alias lsblk='diskutil list'
alias lsusb='system_profiler SPUSBDataType'
alias lspci='system_profiler SPPCIDataType'

# File operations
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -i'
alias mkdir='mkdir -p'

# Package management aliases
alias yum='brew'
alias dnf='brew'
alias pacman='brew'
alias zypper='brew'

# Service management
alias systemctl='launchctl'
alias journalctl='log show'

# Development tools
alias make='make'
alias gcc='clang'
alias g++='clang++'

# Text processing (if GNU versions are installed via Homebrew)
if command -v gsed >/dev/null 2>&1; then
    alias sed='gsed'
fi

if command -v gawk >/dev/null 2>&1; then
    alias awk='gawk'
fi

if command -v ggrep >/dev/null 2>&1; then
    alias grep='ggrep'
fi

if command -v gfind >/dev/null 2>&1; then
    alias find='gfind'
fi

if command -v gtar >/dev/null 2>&1; then
    alias tar='gtar'
fi

# Modern replacements (if installed)
if command -v eza >/dev/null 2>&1; then
    alias ls='eza --color=always --group-directories-first'
    alias ll='eza -l --color=always --group-directories-first'
    alias la='eza -la --color=always --group-directories-first'
    alias tree='eza --tree --color=always --group-directories-first'
fi

if command -v bat >/dev/null 2>&1; then
    alias cat='bat --style=plain --paging=never'
fi

if command -v rg >/dev/null 2>&1; then
    alias grep='rg'
fi

if command -v fd >/dev/null 2>&1; then
    alias find='fd'
fi

# Functions to mimic Linux commands
function uname() {
    case "${1:-}" in
        -a|--all)
            echo "Darwin $(hostname) $(sw_vers -productVersion) $(sw_vers -buildVersion) $(uname -m)"
            ;;
        -s|--kernel-name)
            echo "Darwin"
            ;;
        -r|--kernel-release)
            sw_vers -productVersion
            ;;
        -v|--kernel-version)
            sw_vers -buildVersion
            ;;
        -m|--machine)
            /usr/bin/uname -m
            ;;
        *)
            /usr/bin/uname "$@"
            ;;
    esac
}

function lsb_release() {
    case "${1:-}" in
        -a|--all)
            echo "Distributor ID: macOS"
            echo "Description: macOS $(sw_vers -productVersion)"
            echo "Release: $(sw_vers -productVersion)"
            echo "Codename: $(sw_vers -productName)"
            ;;
        -d|--description)
            echo "Description: macOS $(sw_vers -productVersion)"
            ;;
        -r|--release)
            echo "Release: $(sw_vers -productVersion)"
            ;;
        -c|--codename)
            echo "Codename: $(sw_vers -productName)"
            ;;
        *)
            echo "Usage: lsb_release [options]"
            echo "Options: -a, -d, -r, -c"
            ;;
    esac
}

function uptime() {
    local boot_time up_seconds up_days up_hours up_minutes
    boot_time=$(sysctl -n kern.boottime | sed 's/.*sec = \([0-9]*\).*/\1/')
    up_seconds=$(($(date +%s) - boot_time))
    up_days=$((up_seconds / 86400))
    up_hours=$(((up_seconds % 86400) / 3600))
    up_minutes=$(((up_seconds % 3600) / 60))
    
    printf "up %d days, %d hours, %d minutes\n" $up_days $up_hours $up_minutes
}

function free() {
    vm_stat | awk '
    /Pages free/ { free = $3 }
    /Pages active/ { active = $3 }
    /Pages inactive/ { inactive = $3 }
    /Pages speculative/ { speculative = $3 }
    /Pages wired/ { wired = $3 }
    END {
        total = (free + active + inactive + speculative + wired) * 4096
        used = (active + inactive + wired) * 4096
        available = (free + speculative) * 4096
        printf "%-10s %10s %10s %10s\n", "", "total", "used", "available"
        printf "%-10s %10.0f %10.0f %10.0f\n", "Mem:", total/1024/1024, used/1024/1024, available/1024/1024
    }'
}

# Add this configuration to shell profiles
add_to_shell_profile() {
    local profile_file="$1"
    local config_line="source ${HOME}/.config/linuxify/config.zsh"
    
    if [[ -f "${profile_file}" ]]; then
        if ! grep -q "linuxify/config.zsh" "${profile_file}"; then
            echo "" >> "${profile_file}"
            echo "# Linuxify command compatibility" >> "${profile_file}"
            echo "${config_line}" >> "${profile_file}"
        fi
    fi
}

# Apply to shell profiles
add_to_shell_profile "${HOME}/.zshrc"
add_to_shell_profile "${HOME}/.bashrc"
EOF
    
    success "Linuxify configuration created at ${config_file}"
}

install_gnu_tools() {
    info "Installing GNU tools for better Linux compatibility..."
    
    # Check if Homebrew is available
    if ! command -v brew >/dev/null 2>&1; then
        warn "Homebrew not available. Skipping GNU tools installation."
        return 0
    fi
    
    local gnu_tools=(
        "coreutils"     # GNU core utilities
        "findutils"     # GNU find, locate, updatedb, xargs
        "gnu-sed"       # GNU sed
        "gnu-tar"       # GNU tar
        "gawk"          # GNU awk
        "grep"          # GNU grep
        "gnu-getopt"    # GNU getopt
        "gnu-time"      # GNU time
    )
    
    local installed_tools=()
    local failed_tools=()
    
    for tool in "${gnu_tools[@]}"; do
        if brew list "${tool}" >/dev/null 2>&1; then
            info "GNU tool already installed: ${tool}"
        else
            info "Installing GNU tool: ${tool}"
            if brew install "${tool}"; then
                installed_tools+=("${tool}")
            else
                failed_tools+=("${tool}")
            fi
        fi
    done
    
    if [[ ${#installed_tools[@]} -gt 0 ]]; then
        success "Installed GNU tools: ${installed_tools[*]}"
    fi
    
    if [[ ${#failed_tools[@]} -gt 0 ]]; then
        warn "Failed to install: ${failed_tools[*]}"
    fi
}

create_compatibility_tests() {
    info "Creating Linux compatibility test script..."
    
    local test_script="${HOME}/.local/bin/test-linuxify"
    
    cat > "${test_script}" << 'EOF'
#!/usr/bin/env zsh
# Test script for Linux command compatibility

set -euo pipefail

readonly GREEN=$(tput setaf 2)
readonly RED=$(tput setaf 1)
readonly BLUE=$(tput setaf 4)
readonly RESET=$(tput sgr0)

success() { echo "${GREEN}✓${RESET} $*"; }
fail() { echo "${RED}✗${RESET} $*"; }
info() { echo "${BLUE}→${RESET} $*"; }

test_command() {
    local cmd="$1"
    local description="$2"
    
    if command -v "${cmd}" >/dev/null 2>&1; then
        success "${description}: ${cmd} available"
        return 0
    else
        fail "${description}: ${cmd} not found"
        return 1
    fi
}

test_alias() {
    local alias_name="$1"
    local description="$2"
    
    if alias "${alias_name}" >/dev/null 2>&1; then
        success "${description}: ${alias_name} alias configured"
        return 0
    else
        fail "${description}: ${alias_name} alias not found"
        return 1
    fi
}

main() {
    info "Testing Linux command compatibility..."
    echo
    
    # Load linuxify configuration
    if [[ -f "${HOME}/.config/linuxify/config.zsh" ]]; then
        source "${HOME}/.config/linuxify/config.zsh"
        success "Linuxify configuration loaded"
    else
        fail "Linuxify configuration not found"
        exit 1
    fi
    
    echo
    info "Testing package management aliases..."
    test_alias "apt" "Package management"
    test_alias "apt-get" "Package management (apt-get)"
    test_alias "yum" "Package management (yum)"
    
    echo
    info "Testing file system commands..."
    test_command "ls" "List files"
    test_alias "ll" "List files (detailed)"
    test_alias "la" "List all files"
    
    echo
    info "Testing system information..."
    test_command "uname" "System information"
    test_command "uptime" "System uptime"
    test_command "free" "Memory information"
    
    echo
    info "Testing GNU tools..."
    test_command "sed" "Stream editor"
    test_command "awk" "Text processing"
    test_command "grep" "Pattern matching"
    test_command "find" "File search"
    
    echo
    info "Testing modern CLI tools..."
    test_command "eza" "Modern ls replacement"
    test_command "bat" "Modern cat replacement"
    test_command "rg" "Modern grep replacement"
    
    echo
    success "Linux compatibility testing complete!"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
EOF
    
    chmod +x "${test_script}"
    success "Created compatibility test script at ${test_script}"
}

update_shell_configuration() {
    info "Updating shell configuration for linuxify..."
    
    local zshrc="${HOME}/.zshrc"
    local config_line="source \"\${HOME}/.config/linuxify/config.zsh\""
    
    # Add linuxify configuration to .zshrc if not already present
    if [[ -f "${zshrc}" ]]; then
        if ! grep -q "linuxify/config.zsh" "${zshrc}"; then
            echo "" >> "${zshrc}"
            echo "# Linux command compatibility (linuxify)" >> "${zshrc}"
            echo "${config_line}" >> "${zshrc}"
            success "Added linuxify configuration to .zshrc"
        else
            info "Linuxify configuration already present in .zshrc"
        fi
    else
        warn ".zshrc not found. Please manually add: ${config_line}"
    fi
}

verify_installation() {
    info "Verifying linuxify installation..."
    
    local install_dir="${HOME}/.local/share/linuxify"
    local config_file="${HOME}/.config/linuxify/config.zsh"
    local test_script="${HOME}/.local/bin/test-linuxify"
    
    if [[ -d "${install_dir}" ]]; then
        success "Linuxify repository exists"
    else
        error "Linuxify repository not found"
    fi
    
    if [[ -f "${config_file}" ]]; then
        success "Linuxify configuration exists"
    else
        error "Linuxify configuration not found"
    fi
    
    if [[ -f "${test_script}" ]] && [[ -x "${test_script}" ]]; then
        success "Compatibility test script is available"
    else
        error "Compatibility test script not found or not executable"
    fi
}

main() {
    info "Starting linuxify installation..."
    
    check_prerequisites
    download_linuxify
    install_linuxify_commands
    create_linuxify_config
    install_gnu_tools
    create_compatibility_tests
    update_shell_configuration
    verify_installation
    
    success "Linuxify installation complete!"
    info "Linux command compatibility has been added to your system"
    info "Run 'test-linuxify' to verify compatibility"
    info "Restart your shell or run 'source ~/.zshrc' to activate"
    
    warn "Note: Some commands may behave differently than their Linux counterparts"
    info "Use 'test-linuxify' to see what's available"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
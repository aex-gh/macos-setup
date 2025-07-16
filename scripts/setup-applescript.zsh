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

create_applescript_directory() {
    info "Creating AppleScript automation directory..."
    
    local script_dir="${HOME}/Library/Scripts/Setup Automation"
    mkdir -p "${script_dir}"
    
    success "Created AppleScript directory: ${script_dir}"
}

create_system_preference_scripts() {
    info "Creating system preference automation scripts..."
    
    local script_dir="${HOME}/Library/Scripts/Setup Automation"
    
    # Script to configure Dock preferences
    cat > "${script_dir}/Configure Dock.applescript" << 'EOF'
-- Configure Dock Preferences for Gruvbox Setup
tell application "System Events"
    tell dock preferences
        set autohide to true
        set autohide delay to 0.1
        set animate to false
        set magnification to true
        set magnification size to 64
        set icon size to 48
    end tell
end tell

-- Hide Dock and show it again to apply changes
tell application "Dock"
    quit
end tell

delay 2

tell application "System Events"
    do shell script "open /System/Applications/Dock.app"
end tell

display notification "Dock preferences configured" with title "Setup Automation"
EOF
    
    # Script to configure Finder preferences
    cat > "${script_dir}/Configure Finder.applescript" << 'EOF'
-- Configure Finder Preferences for Better Development Experience
tell application "Finder"
    activate
    
    -- Set view preferences
    set view of window 1 to list view
    
    -- Show sidebar
    set sidebar width of window 1 to 200
    
    -- Show status bar
    set statusbar visible of window 1 to true
    
    -- Show path bar
    set pathbar visible of window 1 to true
end tell

-- Configure Finder defaults via shell
do shell script "defaults write com.apple.finder AppleShowAllFiles -bool true"
do shell script "defaults write com.apple.finder ShowStatusBar -bool true"
do shell script "defaults write com.apple.finder ShowPathbar -bool true"
do shell script "defaults write NSGlobalDomain AppleShowAllExtensions -bool true"
do shell script "killall Finder"

display notification "Finder preferences configured" with title "Setup Automation"
EOF
    
    # Script to configure Terminal preferences
    cat > "${script_dir}/Configure Terminal.applescript" << 'EOF'
-- Configure Terminal.app for Gruvbox Theme
tell application "Terminal"
    activate
    
    -- Create new profile if it doesn't exist
    try
        set profile_name to "Gruvbox Maple Mono"
        set new_profile to make new settings set with properties {name:profile_name}
        
        -- Configure the profile
        tell new_profile
            set background color to {8738, 8738, 8738} -- Dark background
            set normal text color to {59624, 55255, 47802} -- Light foreground
            set cursor color to {63736, 46774, 25700} -- Orange cursor
            set font name to "Maple Mono Nerd Font"
            set font size to 13
        end tell
        
        -- Set as default
        set default settings to new_profile
        set startup settings to new_profile
        
    on error
        -- Profile might already exist
        display notification "Terminal profile already configured" with title "Setup Automation"
    end try
end tell

display notification "Terminal preferences configured" with title "Setup Automation"
EOF
    
    success "Created system preference scripts"
}

create_application_automation_scripts() {
    info "Creating application automation scripts..."
    
    local script_dir="${HOME}/Library/Scripts/Setup Automation"
    
    # Script to configure Zed editor
    cat > "${script_dir}/Configure Zed.applescript" << 'EOF'
-- Configure Zed Editor Preferences
-- This script opens Zed and applies basic configuration

tell application "Zed"
    activate
    delay 2
    
    -- Open settings via command palette
    tell application "System Events"
        key code 35 using {command down, shift down} -- Cmd+Shift+P
        delay 1
        type text "zed: open settings"
        key code 36 -- Return
        delay 2
    end tell
end tell

display notification "Zed configuration opened - manual setup required" with title "Setup Automation"
EOF
    
    # Script to install and configure Raycast
    cat > "${script_dir}/Configure Raycast.applescript" << 'EOF'
-- Configure Raycast Preferences
tell application "Raycast"
    activate
    delay 2
end tell

-- Open Raycast preferences
tell application "System Events"
    tell process "Raycast"
        keystroke "," using command down
        delay 2
    end tell
end tell

display notification "Raycast preferences opened" with title "Setup Automation"
EOF
    
    # Script to configure 1Password
    cat > "${script_dir}/Configure 1Password.applescript" << 'EOF'
-- Configure 1Password for CLI Integration
tell application "1Password 7 - Password Manager"
    activate
    delay 2
end tell

-- Open 1Password preferences
tell application "System Events"
    tell process "1Password 7 - Password Manager"
        keystroke "," using command down
        delay 2
        
        -- Navigate to Developer section if it exists
        try
            click button "Developer" of toolbar 1
            delay 1
        on error
            -- Developer section might not be visible
        end try
    end tell
end tell

display notification "1Password preferences opened - enable CLI integration" with title "Setup Automation"
EOF
    
    success "Created application automation scripts"
}

create_development_environment_scripts() {
    info "Creating development environment automation scripts..."
    
    local script_dir="${HOME}/Library/Scripts/Setup Automation"
    
    # Script to set up development directories
    cat > "${script_dir}/Setup Dev Directories.applescript" << 'EOF'
-- Create Standard Development Directory Structure
set home_folder to (path to home folder as string)

-- Create development directories
set directory_list to {"Projects", "Projects/Personal", "Projects/Work", "Projects/Open Source", "Scripts", "Documents/Notes"}

repeat with dir_name in directory_list
    set full_path to home_folder & dir_name
    try
        do shell script "mkdir -p " & quoted form of POSIX path of full_path
    on error
        -- Directory might already exist
    end try
end repeat

-- Open Projects folder in Finder
tell application "Finder"
    open folder "Projects" of home folder
end tell

display notification "Development directories created" with title "Setup Automation"
EOF
    
    # Script to configure Git global settings
    cat > "${script_dir}/Configure Git.applescript" << 'EOF'
-- Configure Git Global Settings
set git_name to text returned of (display dialog "Enter your Git name:" default answer "Andrew Exley")
set git_email to text returned of (display dialog "Enter your Git email:" default answer "andrew@exley.net.au")

-- Configure Git
do shell script "git config --global user.name " & quoted form of git_name
do shell script "git config --global user.email " & quoted form of git_email
do shell script "git config --global init.defaultBranch main"
do shell script "git config --global pull.rebase true"
do shell script "git config --global push.autoSetupRemote true"

-- Configure Git to use 1Password for SSH signing
do shell script "git config --global gpg.format ssh"
do shell script "git config --global user.signingkey 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEkw7d1+vkE2t1xLz3Q4Y2u8K7c5m9n2P3j6k8l1M4o7'"
do shell script "git config --global gpg.ssh.program '/Applications/1Password 7 - Password Manager.app/Contents/MacOS/op-ssh-sign'"
do shell script "git config --global commit.gpgsign true"

display notification "Git configured with 1Password integration" with title "Setup Automation"
EOF
    
    success "Created development environment scripts"
}

create_maintenance_scripts() {
    info "Creating system maintenance scripts..."
    
    local script_dir="${HOME}/Library/Scripts/Setup Automation"
    
    # Script to update all system components
    cat > "${script_dir}/Update System.applescript" << 'EOF'
-- Update All System Components
display notification "Starting system update..." with title "Setup Automation"

-- Update Homebrew
try
    do shell script "brew update && brew upgrade && brew cleanup"
    display notification "Homebrew updated successfully" with title "Setup Automation"
on error
    display notification "Homebrew update failed" with title "Setup Automation"
end try

-- Update Mac App Store apps
tell application "App Store"
    activate
    delay 2
end tell

-- Check for macOS updates
tell application "System Preferences"
    activate
    set current pane to pane "com.apple.preferences.softwareupdate"
    delay 3
end tell

display notification "System update process initiated" with title "Setup Automation"
EOF
    
    # Script to clean up system files
    cat > "${script_dir}/Cleanup System.applescript" << 'EOF'
-- Clean Up System Files and Caches
display notification "Starting system cleanup..." with title "Setup Automation"

-- Clean up various cache directories
set cleanup_commands to {
    "rm -rf ~/Library/Caches/com.apple.Safari/WebKitCache/*",
    "rm -rf ~/Library/Caches/Google/Chrome/Default/Cache/*",
    "sudo rm -rf /System/Library/Caches/*",
    "sudo periodic daily weekly monthly",
    "brew cleanup --prune=all"
}

repeat with cmd in cleanup_commands
    try
        do shell script cmd
    on error
        -- Some commands might fail due to permissions or missing files
    end try
end repeat

-- Empty trash
tell application "Finder"
    empty trash
end tell

display notification "System cleanup completed" with title "Setup Automation"
EOF
    
    success "Created maintenance scripts"
}

create_applescript_runner() {
    info "Creating AppleScript runner utility..."
    
    local runner_script="${HOME}/.local/bin/run-applescript"
    
    cat > "${runner_script}" << 'EOF'
#!/usr/bin/env zsh
# AppleScript Runner Utility

set -euo pipefail

readonly SCRIPT_DIR="${HOME}/Library/Scripts/Setup Automation"
readonly RED=$(tput setaf 1)
readonly GREEN=$(tput setaf 2)
readonly BLUE=$(tput setaf 4)
readonly RESET=$(tput sgr0)

info() { echo "${BLUE}[INFO]${RESET} $*"; }
success() { echo "${GREEN}[SUCCESS]${RESET} $*"; }
error() { echo "${RED}[ERROR]${RESET} $*" >&2; }

list_scripts() {
    info "Available AppleScript automation scripts:"
    if [[ -d "${SCRIPT_DIR}" ]]; then
        find "${SCRIPT_DIR}" -name "*.applescript" -exec basename {} .applescript \; | sort
    else
        error "Script directory not found: ${SCRIPT_DIR}"
    fi
}

run_script() {
    local script_name="$1"
    local script_path="${SCRIPT_DIR}/${script_name}.applescript"
    
    if [[ ! -f "${script_path}" ]]; then
        error "Script not found: ${script_path}"
        return 1
    fi
    
    info "Running AppleScript: ${script_name}"
    if osascript "${script_path}"; then
        success "Script completed: ${script_name}"
    else
        error "Script failed: ${script_name}"
        return 1
    fi
}

case "${1:-}" in
    "list"|"ls")
        list_scripts
        ;;
    "run")
        if [[ -n "${2:-}" ]]; then
            run_script "$2"
        else
            error "Usage: run-applescript run <script-name>"
            echo "Use 'run-applescript list' to see available scripts"
        fi
        ;;
    "help"|"-h"|"--help")
        echo "AppleScript Runner Utility"
        echo "Usage: run-applescript <command> [args]"
        echo ""
        echo "Commands:"
        echo "  list, ls          - List available scripts"
        echo "  run <script>      - Run a specific script"
        echo "  help              - Show this help"
        echo ""
        echo "Available scripts:"
        list_scripts
        ;;
    *)
        error "Unknown command: ${1:-}"
        echo "Run 'run-applescript help' for usage information"
        exit 1
        ;;
esac
EOF
    
    chmod +x "${runner_script}"
    success "Created AppleScript runner at ${runner_script}"
}

compile_applescripts() {
    info "Compiling AppleScript files..."
    
    local script_dir="${HOME}/Library/Scripts/Setup Automation"
    local compiled_count=0
    
    if [[ -d "${script_dir}" ]]; then
        for script_file in "${script_dir}"/*.applescript; do
            if [[ -f "${script_file}" ]]; then
                local script_name="${script_file:t:r}"
                local compiled_script="${script_dir}/${script_name}.scpt"
                
                if osacompile -o "${compiled_script}" "${script_file}"; then
                    ((compiled_count++))
                    info "Compiled: ${script_name}"
                else
                    error "Failed to compile: ${script_name}"
                fi
            fi
        done
        
        success "Compiled ${compiled_count} AppleScript files"
    else
        error "Script directory not found"
    fi
}

verify_installation() {
    info "Verifying AppleScript setup..."
    
    local script_dir="${HOME}/Library/Scripts/Setup Automation"
    
    if [[ -d "${script_dir}" ]]; then
        local script_count
        script_count=$(find "${script_dir}" -name "*.applescript" | wc -l)
        success "AppleScript directory exists with ${script_count} scripts"
    else
        error "AppleScript directory not found"
    fi
    
    if command -v run-applescript >/dev/null 2>&1; then
        success "AppleScript runner utility is accessible"
    else
        warn "AppleScript runner not in PATH"
    fi
}

main() {
    info "Setting up AppleScript automation..."
    
    create_applescript_directory
    create_system_preference_scripts
    create_application_automation_scripts
    create_development_environment_scripts
    create_maintenance_scripts
    create_applescript_runner
    compile_applescripts
    verify_installation
    
    success "AppleScript automation setup complete!"
    info "Use 'run-applescript list' to see available automation scripts"
    info "Scripts location: ${HOME}/Library/Scripts/Setup Automation"
    
    warn "Note: Some scripts may require manual interaction or permissions"
    info "Test scripts individually before using in automated workflows"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
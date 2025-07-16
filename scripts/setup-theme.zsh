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

apply_terminal_theme() {
    info "Applying Gruvbox theme to Terminal.app..."
    
    # Kill Terminal.app if it's running to ensure settings are reloaded
    if pgrep -x "Terminal" >/dev/null; then
        info "Closing Terminal.app to apply new settings..."
        osascript -e 'tell application "Terminal" to quit'
        sleep 2
    fi
    
    # The Terminal preferences will be applied by chezmoi
    success "Terminal.app theme configuration prepared"
    info "Terminal.app will use Gruvbox theme on next launch"
}

configure_system_appearance() {
    info "Configuring system appearance settings..."
    
    # Set to Dark mode
    osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to true' 2>/dev/null || \
    defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"
    
    # Set accent colour to orange (Gruvbox orange)
    defaults write NSGlobalDomain AppleAccentColor -int 1
    
    # Set highlight colour to orange
    defaults write NSGlobalDomain AppleHighlightColor -string "1.000000 0.733333 0.721569 Orange"
    
    # Disable transparency
    defaults write com.apple.universalaccess reduceTransparency -bool true
    
    success "System appearance configured for Gruvbox theme"
}

configure_finder_appearance() {
    info "Configuring Finder appearance..."
    
    # Set Finder to use list view by default
    defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
    
    # Show all filename extensions
    defaults write NSGlobalDomain AppleShowAllExtensions -bool true
    
    # Show status bar
    defaults write com.apple.finder ShowStatusBar -bool true
    
    # Show path bar
    defaults write com.apple.finder ShowPathbar -bool true
    
    # Show sidebar
    defaults write com.apple.finder ShowSidebar -bool true
    
    # Set sidebar icon size to medium
    defaults write NSGlobalDomain NSTableViewDefaultSizeMode -int 2
    
    success "Finder appearance configured"
}

configure_dock_appearance() {
    info "Configuring Dock appearance..."
    
    # Set Dock to auto-hide
    defaults write com.apple.dock autohide -bool true
    
    # Set Dock auto-hide delay
    defaults write com.apple.dock autohide-delay -float 0.1
    
    # Set Dock animation speed
    defaults write com.apple.dock autohide-time-modifier -float 0.5
    
    # Remove auto-hiding animation
    defaults write com.apple.dock launchanim -bool false
    
    # Set Dock to bottom
    defaults write com.apple.dock orientation -string "bottom"
    
    # Set icon size
    defaults write com.apple.dock tilesize -int 48
    
    # Set magnification
    defaults write com.apple.dock magnification -bool true
    defaults write com.apple.dock largesize -int 64
    
    # Don't show recent applications
    defaults write com.apple.dock show-recents -bool false
    
    # Hot corners - disable all
    defaults write com.apple.dock wvous-tl-corner -int 1
    defaults write com.apple.dock wvous-tr-corner -int 1
    defaults write com.apple.dock wvous-bl-corner -int 1
    defaults write com.apple.dock wvous-br-corner -int 1
    
    success "Dock appearance configured"
}

configure_menu_bar() {
    info "Configuring menu bar appearance..."
    
    # Always show menu bar
    defaults write NSGlobalDomain _HIHideMenuBar -bool false
    
    # Show battery percentage
    defaults write com.apple.menuextra.battery ShowPercent -string "YES"
    
    # Show date and time
    defaults write com.apple.menuextra.clock DateFormat -string "EEE d MMM  HH:mm"
    defaults write com.apple.menuextra.clock FlashDateSeparators -bool false
    defaults write com.apple.menuextra.clock IsAnalog -bool false
    
    success "Menu bar configured"
}

configure_wallpaper() {
    info "Setting up Gruvbox wallpaper..."
    
    # Create a simple Gruvbox wallpaper using built-in colours
    local wallpaper_dir="${HOME}/Pictures/Wallpapers"
    local wallpaper_path="${wallpaper_dir}/gruvbox-solid.png"
    
    mkdir -p "${wallpaper_dir}"
    
    # Create a solid colour wallpaper using the Gruvbox dark background
    # Using Python to create a simple image (if available)
    if command -v python3 >/dev/null 2>&1; then
        python3 -c "
from PIL import Image
import os

# Gruvbox dark background colour
bg_colour = (40, 40, 40)  # #282828 in RGB

# Create 2560x1600 image (common Mac resolution)
img = Image.new('RGB', (2560, 1600), bg_colour)
img.save('${wallpaper_path}')
print('Wallpaper created')
" 2>/dev/null || {
            warn "Could not create wallpaper image. PIL not available."
            return 0
        }
        
        # Set as desktop wallpaper
        osascript -e "tell application \"System Events\" to tell every desktop to set picture to \"${wallpaper_path}\"" 2>/dev/null || \
        warn "Could not set wallpaper automatically"
        
        success "Gruvbox wallpaper configured"
    else
        warn "Python3 not available. Skipping wallpaper creation."
    fi
}

configure_text_editing() {
    info "Configuring text editing defaults..."
    
    # Smart quotes and dashes
    defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
    defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
    
    # Auto-correct
    defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
    
    # Auto-capitalisation
    defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
    
    # Auto-period insertion
    defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
    
    success "Text editing defaults configured"
}

restart_affected_applications() {
    info "Restarting affected applications..."
    
    local apps=(
        "Dock"
        "Finder"
        "SystemUIServer"
        "cfprefsd"
    )
    
    for app in "${apps[@]}"; do
        if pgrep -x "${app}" >/dev/null; then
            info "Restarting ${app}..."
            killall "${app}" 2>/dev/null || true
        fi
    done
    
    # Wait a moment for apps to restart
    sleep 2
    
    success "Applications restarted"
}

main() {
    info "Starting Gruvbox theme configuration..."
    
    apply_terminal_theme
    configure_system_appearance
    configure_finder_appearance
    configure_dock_appearance
    configure_menu_bar
    configure_wallpaper
    configure_text_editing
    restart_affected_applications
    
    success "Gruvbox theme configuration complete!"
    info "Some changes may require logging out and back in to take full effect"
    info "Terminal.app will use the new theme when next opened"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
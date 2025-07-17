#!/usr/bin/env zsh

# Script metadata
readonly SCRIPT_NAME="${0:t}"
readonly SCRIPT_DIR="${0:A:h}"

# Load common library
source "${SCRIPT_DIR}/../lib/common.zsh"

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
    set_default NSGlobalDomain AppleInterfaceStyle "Dark"
    
    # Set accent colour to orange (Gruvbox orange)
    set_default NSGlobalDomain AppleAccentColor 1 int
    
    # Set highlight colour to orange
    set_default NSGlobalDomain AppleHighlightColor "1.000000 0.733333 0.721569 Orange"
    
    # Disable transparency
    set_default com.apple.universalaccess reduceTransparency true bool
    
    success "System appearance configured for Gruvbox theme"
}

configure_finder_appearance() {
    info "Configuring Finder appearance..."
    
    # Set Finder to use list view by default
    set_default com.apple.finder FXPreferredViewStyle "Nlsv"
    
    # Show all filename extensions
    set_default NSGlobalDomain AppleShowAllExtensions true bool
    
    # Show status bar
    set_default com.apple.finder ShowStatusBar true bool
    
    # Show path bar
    set_default com.apple.finder ShowPathbar true bool
    
    # Show sidebar
    set_default com.apple.finder ShowSidebar true bool
    
    # Set sidebar icon size to medium
    set_default NSGlobalDomain NSTableViewDefaultSizeMode 2 int
    
    success "Finder appearance configured"
}

configure_dock_appearance() {
    info "Configuring Dock appearance..."
    
    # Set Dock to auto-hide
    set_default com.apple.dock autohide true bool
    
    # Set Dock auto-hide delay
    set_default com.apple.dock autohide-delay 0.1 float
    
    # Set Dock animation speed
    set_default com.apple.dock autohide-time-modifier 0.5 float
    
    # Remove auto-hiding animation
    set_default com.apple.dock launchanim false bool
    
    # Set Dock to bottom
    set_default com.apple.dock orientation "bottom"
    
    # Set icon size
    set_default com.apple.dock tilesize 48 int
    
    # Set magnification
    set_default com.apple.dock magnification true bool
    set_default com.apple.dock largesize 64 int
    
    # Don't show recent applications
    set_default com.apple.dock show-recents false bool
    
    # Hot corners - disable all
    set_default com.apple.dock wvous-tl-corner 1 int
    set_default com.apple.dock wvous-tr-corner 1 int
    set_default com.apple.dock wvous-bl-corner 1 int
    set_default com.apple.dock wvous-br-corner 1 int
    
    success "Dock appearance configured"
}

configure_menu_bar() {
    info "Configuring menu bar appearance..."
    
    # Always show menu bar
    set_default NSGlobalDomain _HIHideMenuBar false bool
    
    # Show battery percentage
    set_default com.apple.menuextra.battery ShowPercent "YES"
    
    # Show date and time
    set_default com.apple.menuextra.clock DateFormat "EEE d MMM  HH:mm"
    set_default com.apple.menuextra.clock FlashDateSeparators false bool
    set_default com.apple.menuextra.clock IsAnalog false bool
    
    success "Menu bar configured"
}

configure_wallpaper() {
    info "Setting up Gruvbox wallpaper..."
    
    # Create a simple Gruvbox wallpaper using built-in colours
    local wallpaper_dir="${HOME}/Pictures/Wallpapers"
    local wallpaper_path="${wallpaper_dir}/gruvbox-solid.png"
    
    create_directory "${wallpaper_dir}" 755
    
    # Create a solid colour wallpaper using the Gruvbox dark background
    # Using Python to create a simple image (if available)
    if command_exists python3; then
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
    set_default NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled false bool
    set_default NSGlobalDomain NSAutomaticDashSubstitutionEnabled false bool
    
    # Auto-correct
    set_default NSGlobalDomain NSAutomaticSpellingCorrectionEnabled false bool
    
    # Auto-capitalisation
    set_default NSGlobalDomain NSAutomaticCapitalizationEnabled false bool
    
    # Auto-period insertion
    set_default NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled false bool
    
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
#!/usr/bin/env zsh
set -euo pipefail

# Script metadata
readonly SCRIPT_NAME="${0:t}"
readonly SCRIPT_DIR="${0:A:h}"

# Load common library
source "${SCRIPT_DIR}/../lib/common.zsh"

# Device type from command line
DEVICE_TYPE="${1:-macbook-pro}"


# Configure general system defaults
configure_system_defaults() {
    info "Configuring general system defaults..."

    # Set timezone to Australia/Adelaide
    sudo systemsetup -settimezone "Australia/Adelaide" 2>/dev/null || warn "Could not set timezone"

    # Disable the sound effects on boot
    set_default "com.apple.loginwindow" "LoginHook" ""

    # Set highlight colour to graphite
    set_default "NSGlobalDomain" "AppleHighlightColor" "0.847059 0.847059 0.862745"

    # Set sidebar icon size to medium
    set_default "NSGlobalDomain" "NSTableViewDefaultSizeMode" "2" "int"

    # Always show scrollbars (Possible values: `WhenScrolling`, `Automatic` and `Always`)
    set_default "NSGlobalDomain" "AppleShowScrollBars" "Always"

    # Disable the over-the-top focus ring animation
    set_default "NSGlobalDomain" "NSUseAnimatedFocusRing" "false" "bool"

    # Increase window resize speed for Cocoa applications
    set_default "NSGlobalDomain" "NSWindowResizeTime" "0.001" "float"

    # Expand save panel by default
    set_default "NSGlobalDomain" "NSNavPanelExpandedStateForSaveMode" "true" "bool"
    set_default "NSGlobalDomain" "NSNavPanelExpandedStateForSaveMode2" "true" "bool"

    # Expand print panel by default
    set_default "NSGlobalDomain" "PMPrintingExpandedStateForPrint" "true" "bool"
    set_default "NSGlobalDomain" "PMPrintingExpandedStateForPrint2" "true" "bool"

    # Save to disk (not to iCloud) by default
    set_default "NSGlobalDomain" "NSDocumentSaveNewDocumentsToCloud" "false" "bool"

    # Automatically quit printer app once the print jobs complete
    set_default "com.apple.print.PrintingPrefs" "Quit When Finished" "true" "bool"

    # Disable the "Are you sure you want to open this application?" dialog
    set_default "com.apple.LaunchServices" "LSQuarantine" "false" "bool"

    success "General system defaults configured"
}

# Configure input devices (keyboard and trackpad)
configure_input_devices() {
    info "Configuring input devices..."

    # Trackpad: enable tap to click for this user and for the login screen
    set_default "com.apple.driver.AppleBluetoothMultitouch.trackpad" "Clicking" "true" "bool"
    set_default "NSGlobalDomain" "com.apple.mouse.tapBehavior" "1" "int"

    # Trackpad: map bottom right corner to right-click
    set_default "com.apple.driver.AppleBluetoothMultitouch.trackpad" "TrackpadCornerSecondaryClick" "2" "int"
    set_default "com.apple.driver.AppleBluetoothMultitouch.trackpad" "TrackpadRightClick" "true" "bool"

    # Trackpad: swipe between pages with three fingers
    set_default "NSGlobalDomain" "AppleEnableSwipeNavigateWithScrolls" "true" "bool"

    # Increase sound quality for Bluetooth headphones/headsets
    set_default "com.apple.BluetoothAudioAgent" "Apple Bitpool Min (editable)" "40" "int"

    # Enable full keyboard access for all controls (e.g. enable Tab in modal dialogs)
    set_default "NSGlobalDomain" "AppleKeyboardUIMode" "3" "int"

    # Use scroll gesture with the Ctrl (^) modifier key to zoom
    set_default "com.apple.universalaccess" "closeViewScrollWheelToggle" "true" "bool"
    set_default "com.apple.universalaccess" "HIDScrollZoomModifierMask" "262144" "int"

    # Follow the keyboard focus while zoomed in
    set_default "com.apple.universalaccess" "closeViewZoomFollowsFocus" "true" "bool"

    # Disable press-and-hold for keys in favour of key repeat
    set_default "NSGlobalDomain" "ApplePressAndHoldEnabled" "false" "bool"

    # Set a fast keyboard repeat rate
    set_default "NSGlobalDomain" "KeyRepeat" "1" "int"
    set_default "NSGlobalDomain" "InitialKeyRepeat" "10" "int"

    # Set language and text formats (Australian English)
    set_default "NSGlobalDomain" "AppleLanguages" "(en-AU)"
    set_default "NSGlobalDomain" "AppleLocale" "en_AU@currency=AUD"
    set_default "NSGlobalDomain" "AppleMeasurementUnits" "Centimeters"
    set_default "NSGlobalDomain" "AppleMetricUnits" "true" "bool"

    success "Input devices configured"
}

# Configure screen and display settings
configure_screen_settings() {
    info "Configuring screen and display settings..."

    # Require password immediately after sleep or screen saver begins
    set_default "com.apple.screensaver" "askForPassword" "1" "int"
    set_default "com.apple.screensaver" "askForPasswordDelay" "0" "int"

    # Save screenshots to the folder Screenshots
    set_default "com.apple.screencapture" "location" "$HOME/Screenshots"

    # Save screenshots in PNG format (other options: BMP, GIF, JPG, PDF, TIFF)
    set_default "com.apple.screencapture" "type" "png"

    # Disable shadow in screenshots
    set_default "com.apple.screencapture" "disable-shadow" "true" "bool"

    # Enable subpixel font rendering on non-Apple LCDs
    set_default "NSGlobalDomain" "AppleFontSmoothing" "1" "int"

    # Enable HiDPI display modes (requires restart)
    sudo defaults write /Library/Preferences/com.apple.windowserver DisplayResolutionEnabled -bool true 2>/dev/null || warn "Could not enable HiDPI modes"

    success "Screen and display settings configured"
}

# Configure Finder
configure_finder() {
    info "Configuring Finder..."

    # Finder: allow quitting via ⌘ + Q; doing so will also hide desktop icons
    set_default "com.apple.finder" "QuitMenuItem" "true" "bool"

    # Finder: disable window animations and Get Info animations
    set_default "com.apple.finder" "DisableAllAnimations" "true" "bool"

    # Set Home as the default location for new Finder windows
    set_default "com.apple.finder" "NewWindowTarget" "PfDe"
    set_default "com.apple.finder" "NewWindowTargetPath" "file://$HOME"

    # Show icons for hard drives, servers, and removable media on the desktop
    set_default "com.apple.finder" "ShowExternalHardDrivesOnDesktop" "false" "bool"
    set_default "com.apple.finder" "ShowHardDrivesOnDesktop" "false" "bool"
    set_default "com.apple.finder" "ShowMountedServersOnDesktop" "false" "bool"
    set_default "com.apple.finder" "ShowRemovableMediaOnDesktop" "false" "bool"

    # Finder: show hidden files by default
    set_default "com.apple.finder" "AppleShowAllFiles" "true" "bool"

    # Finder: show all filename extensions
    set_default "NSGlobalDomain" "AppleShowAllExtensions" "true" "bool"

    # Finder: show status bar
    set_default "com.apple.finder" "ShowStatusBar" "true" "bool"

    # Finder: show path bar
    set_default "com.apple.finder" "ShowPathbar" "true" "bool"

    # Display full POSIX path as Finder window title
    set_default "com.apple.finder" "FXPreferredViewStyle" "Nlsv"

    # Keep folders on top when sorting by name
    set_default "com.apple.finder" "_FXSortFoldersFirst" "true" "bool"

    # When performing a search, search the current folder by default
    set_default "com.apple.finder" "FXDefaultSearchScope" "SCcf"

    # Disable the warning when changing a file extension
    set_default "com.apple.finder" "FXEnableExtensionChangeWarning" "false" "bool"

    # Enable spring loading for directories
    set_default "NSGlobalDomain" "com.apple.springing.enabled" "true" "bool"

    # Remove the spring loading delay for directories
    set_default "NSGlobalDomain" "com.apple.springing.delay" "0" "float"

    # Avoid creating .DS_Store files on network or USB volumes
    set_default "com.apple.desktopservices" "DSDontWriteNetworkStores" "true" "bool"
    set_default "com.apple.desktopservices" "DSDontWriteUSBStores" "true" "bool"

    # Use list view in all Finder windows by default
    set_default "com.apple.finder" "FXPreferredViewStyle" "Nlsv"

    # Show the ~/Library folder
    chflags nohidden "$HOME/Library" 2>/dev/null || warn "Could not unhide Library folder"

    # Show the /Volumes folder
    sudo chflags nohidden /Volumes 2>/dev/null || warn "Could not unhide Volumes folder"

    success "Finder configured"
}

# Configure Dock
configure_dock() {
    info "Configuring Dock..."

    # Set the icon size of Dock items to 40 pixels (neutral size)
    set_default "com.apple.dock" "tilesize" "40" "int"

    # Change minimize/maximize window effect to scale
    set_default "com.apple.dock" "mineffect" "scale"

    # Minimize windows into their application's icon
    set_default "com.apple.dock" "minimize-to-application" "true" "bool"

    # Enable spring loading for all Dock items
    set_default "com.apple.dock" "enable-spring-load-actions-on-all-items" "true" "bool"

    # Show indicator lights for open applications in the Dock
    set_default "com.apple.dock" "show-process-indicators" "true" "bool"

    # Don't animate opening applications from the Dock
    set_default "com.apple.dock" "launchanim" "false" "bool"

    # Speed up Mission Control animations
    set_default "com.apple.dock" "expose-animation-duration" "0.1" "float"

    # Don't group windows by application in Mission Control
    set_default "com.apple.dock" "expose-group-by-app" "false" "bool"

    # Disable Dashboard
    set_default "com.apple.dashboard" "mcx-disabled" "true" "bool"

    # Don't show Dashboard as a Space
    set_default "com.apple.dock" "dashboard-in-overlay" "true" "bool"

    # Don't automatically rearrange Spaces based on most recent use
    set_default "com.apple.dock" "mru-spaces" "false" "bool"

    # Remove the auto-hiding Dock delay
    set_default "com.apple.dock" "autohide-delay" "0" "float"

    # Remove the animation when hiding/showing the Dock
    set_default "com.apple.dock" "autohide-time-modifier" "0" "float"

    # Do not automatically hide the Dock (family-friendly default)
    set_default "com.apple.dock" "autohide" "false" "bool"

    # Make Dock icons of hidden applications translucent
    set_default "com.apple.dock" "showhidden" "true" "bool"

    success "Dock configured"
}

# Configure device-specific settings
configure_device_specific() {
    info "Configuring device-specific settings for: $DEVICE_TYPE"

    case "$DEVICE_TYPE" in
        "macbook-pro")
            # Battery and power management
            info "Configuring MacBook Pro specific settings..."

            # Show battery percentage in menu bar
            set_default "com.apple.menuextra.battery" "ShowPercent" "YES"

            # Set sleep settings for battery
            sudo pmset -b sleep 10 displaysleep 5 2>/dev/null || warn "Could not set battery power settings"

            # Set sleep settings for AC power
            sudo pmset -c sleep 30 displaysleep 10 2>/dev/null || warn "Could not set AC power settings"

            # Enable lid wakeup
            sudo pmset -a lidwake 1 2>/dev/null || warn "Could not enable lid wakeup"
            ;;

        "mac-studio"|"mac-mini")
            # Desktop settings (basic configuration only)
            info "Configuring desktop Mac specific settings..."

            # Basic power management for desktop Macs
            sudo pmset -a sleep 0 displaysleep 30 2>/dev/null || warn "Could not set power settings"
            sudo pmset -a autorestart 1 2>/dev/null || warn "Could not enable auto restart"
            ;;
    esac

    success "Device-specific settings configured for $DEVICE_TYPE"
}

# Restart affected applications
restart_affected_apps() {
    info "Restarting affected applications..."

    local apps_to_restart=(
        "Dock"
        "Finder"
        "SystemUIServer"
    )

    for app in "${apps_to_restart[@]}"; do
        if pgrep "$app" &>/dev/null; then
            info "Restarting $app..."
            killall "$app" 2>/dev/null || warn "Could not restart $app"
            success "✓ $app restarted"
        fi
    done

    success "Applications restarted"
}

# Help function
usage() {
    cat << EOF
$SCRIPT_NAME - macOS System Configuration

USAGE:
    $SCRIPT_NAME [DEVICE_TYPE]

DESCRIPTION:
    Configures macOS system defaults, preferences, and UI settings optimised
    for the specified device type and Australian English locale.

DEVICE_TYPE:
    macbook-pro    Portable development workstation
    mac-studio     Headless server infrastructure
    mac-mini       Lightweight development + multimedia

    Default: macbook-pro

CONFIGURATION AREAS:
    • General system defaults (timezone, highlighting, scrollbars)
    • Input devices (trackpad, keyboard, Australian locale)
    • Screen settings (screenshots, font rendering, security)
    • Finder (hidden files, extensions, search, view options)
    • Dock (size, effects, auto-hide, animations)
    • Device-specific power and display settings

EXAMPLES:
    $SCRIPT_NAME                    # Configure for MacBook Pro
    $SCRIPT_NAME mac-studio         # Configure for Mac Studio
    $SCRIPT_NAME mac-mini           # Configure for Mac Mini

NOTES:
    • Uses Australian English locale and Adelaide timezone
    • Some settings require restart to take effect
    • Automatically restarts Dock, Finder, and SystemUIServer

EOF
}

# Main configuration process
main() {
    info "macOS System Configuration"
    info "========================="
    info "Device type: $DEVICE_TYPE"
    info "Locale: Australian English (en_AU)"
    info "Timezone: Australia/Adelaide"
    echo

    # Configure different areas
    configure_system_defaults
    echo

    configure_input_devices
    echo

    configure_screen_settings
    echo

    configure_finder
    echo

    configure_dock
    echo

    configure_device_specific
    echo

    # Restart applications to apply changes
    restart_affected_apps
    echo

    success "=========================================="
    success "macOS configuration completed successfully!"
    success "=========================================="
    info "Configuration optimised for: $DEVICE_TYPE"
    info "Some changes may require a restart to take full effect"

    return 0
}

# Parse command line arguments
case "${1:-}" in
    -h|--help)
        usage
        exit 0
        ;;
    macbook-pro|mac-studio|mac-mini)
        DEVICE_TYPE="$1"
        ;;
    "")
        # Use default
        ;;
    *)
        error "Invalid device type: $1"
        usage
        exit 1
        ;;
esac

# Run main function
main

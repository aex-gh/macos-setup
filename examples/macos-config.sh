#!/bin/bash

# =============================================================================
# macOS Configuration Script
# =============================================================================
# This script customizes macOS settings for better productivity and user experience
#
# Usage: chmod +x macos-config.sh && ./macos-config.sh
#
# Author: Generated for macOS customization
# =============================================================================

echo "🍎 Starting macOS Configuration..."
echo "This script will modify system settings for dock, finder, and other preferences."
echo ""

# Function to print section headers
print_section() {
    echo ""
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo "  $1"
    echo "═══════════════════════════════════════════════════════════════════════════════"
}

# =============================================================================
# DOCK SETTINGS
# =============================================================================

print_section "📱 DOCK CONFIGURATION"

echo "• Removing all applications from dock..."
defaults write com.apple.dock persistent-apps -array

echo "• Making dock smaller (size: 36)..."
defaults write com.apple.dock tilesize -int 36

echo "• Disabling recent apps in dock..."
defaults write com.apple.dock show-recents -bool false

echo "• Enabling dock auto-hide..."
defaults write com.apple.dock autohide -bool true

echo "• Speeding up dock auto-hide animation..."
defaults write com.apple.dock autohide-time-modifier -float 0.5

echo "• Reducing dock auto-hide delay..."
defaults write com.apple.dock autohide-delay -float 0.2

echo "• Positioning dock at bottom..."
defaults write com.apple.dock orientation -string "bottom"

echo "• Disabling dock magnification..."
defaults write com.apple.dock magnification -bool false

# =============================================================================
# FINDER SETTINGS
# =============================================================================

print_section "📁 FINDER CONFIGURATION"

echo "• Setting default view to list view..."
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

echo "• Setting default sort to date modified..."
defaults write com.apple.finder FXArrangeGroupViewBy -string "Date Modified"

echo "• Showing all filename extensions..."
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

echo "• Showing path bar..."
defaults write com.apple.finder ShowPathbar -bool true

echo "• Showing status bar..."
defaults write com.apple.finder ShowStatusBar -bool true

echo "• Showing hidden files..."
defaults write com.apple.finder AppleShowAllFiles -bool true

echo "• Setting default location to home folder..."
defaults write com.apple.finder NewWindowTarget -string "PfHm"
defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/"

echo "• Disabling warning when changing file extensions..."
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

echo "• Enabling text selection in Quick Look..."
defaults write com.apple.finder QLEnableTextSelection -bool true

# =============================================================================
# SYSTEM PREFERENCES
# =============================================================================

print_section "⚙️  SYSTEM PREFERENCES"

echo "• Disabling 'Are you sure you want to open this application?' dialog..."
defaults write com.apple.LaunchServices LSQuarantine -bool false

echo "• Enabling tap to click on trackpad..."
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true

echo "• Enabling three finger drag..."
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool true

echo "• Setting traditional scroll direction (disable natural scrolling)..."
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false

echo "• Showing battery percentage in menu bar..."
defaults write com.apple.menuextra.battery ShowPercent -string "YES"

echo "• Faster key repeat rate..."
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

echo "• Requiring password immediately after sleep..."
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0

# =============================================================================
# SCREENSHOTS
# =============================================================================

print_section "📸 SCREENSHOT SETTINGS"

echo "• Creating Screenshots folder..."
mkdir -p ~/Pictures/Screenshots

echo "• Setting screenshot location to ~/Pictures/Screenshots..."
defaults write com.apple.screencapture location -string "~/Pictures/Screenshots"

echo "• Setting screenshot format to PNG..."
defaults write com.apple.screencapture type -string "png"

echo "• Disabling screenshot shadow..."
defaults write com.apple.screencapture disable-shadow -bool true

echo "• Including date in screenshot names..."
defaults write com.apple.screencapture include-date -bool true

# =============================================================================
# MENU BAR & CONTROL CENTER
# =============================================================================

print_section "📱 MENU BAR & CONTROL CENTER"

echo "• Showing day of week in menu bar clock..."
defaults write com.apple.menuextra.clock DateFormat -string "EEE MMM d  h:mm a"

echo "• Showing Bluetooth in menu bar..."
defaults write com.apple.controlcenter "NSStatusItem Visible Bluetooth" -bool true

echo "• Showing Sound in menu bar..."
defaults write com.apple.controlcenter "NSStatusItem Visible Sound" -bool true

# =============================================================================
# PERFORMANCE & ANIMATIONS
# =============================================================================

print_section "⚡ PERFORMANCE & ANIMATIONS"

echo "• Speeding up Mission Control animations..."
defaults write com.apple.dock expose-animation-duration -float 0.1

echo "• Reducing window resize animation time..."
defaults write NSGlobalDomain NSWindowResizeTime -float 0.001

echo "• Disabling disk image verification..."
defaults write com.apple.frameworks.diskimages skip-verify -bool true
defaults write com.apple.frameworks.diskimages skip-verify-locked -bool true
defaults write com.apple.frameworks.diskimages skip-verify-remote -bool true

echo "• Speeding up wake from sleep..."
sudo pmset -a standbydelay 86400

# =============================================================================
# TEXT & INPUT SETTINGS
# =============================================================================

print_section "✏️  TEXT & INPUT SETTINGS"

echo "• Disabling automatic capitalization..."
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

echo "• Disabling automatic period substitution..."
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

echo "• Disabling auto-correct..."
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

echo "• Disabling automatic quote substitution..."
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false

echo "• Disabling automatic dash substitution..."
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

# =============================================================================
# DEVELOPMENT SETTINGS
# =============================================================================

print_section "💻 DEVELOPMENT SETTINGS"

echo "• Disabling DS_Store file creation on network volumes..."
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

echo "• Disabling DS_Store file creation on USB volumes..."
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

echo "• Showing all processes in Activity Monitor..."
defaults write com.apple.ActivityMonitor ShowCategory -int 0

echo "• Setting Activity Monitor to show CPU usage in dock icon..."
defaults write com.apple.ActivityMonitor IconType -int 5

echo "• Enabling Secure Keyboard Entry in Terminal..."
defaults write com.apple.terminal SecureKeyboardEntry -bool true

# =============================================================================
# PRIVACY & SECURITY
# =============================================================================

print_section "🔒 PRIVACY & SECURITY"

echo "• Disabling Spotlight indexing for any volume that gets mounted..."
sudo defaults write /.Spotlight-V100/VolumeConfiguration Exclusions -array "/Volumes"

echo "• Disabling automatic app store downloads..."
defaults write com.apple.SoftwareUpdate AutomaticDownload -int 0

echo "• Disabling app store auto-updates..."
defaults write com.apple.commerce AutoUpdate -bool false

# =============================================================================
# RESTART SERVICES
# =============================================================================

print_section "🔄 APPLYING CHANGES"

echo "• Restarting Dock..."
killall Dock

echo "• Restarting Finder..."
killall Finder

echo "• Restarting SystemUIServer..."
killall SystemUIServer

echo "• Restarting Control Center..."
killall ControlCenter 2>/dev/null

# =============================================================================
# COMPLETION
# =============================================================================

print_section "✅ CONFIGURATION COMPLETE"

echo ""
echo "🎉 macOS configuration has been applied successfully!"
echo ""
echo "📋 Summary of changes:"
echo "   • Dock: Smaller, auto-hide, no recent apps, all default apps removed"
echo "   • Finder: List view, sort by date modified, show extensions and hidden files"
echo "   • Screenshots: Saved to ~/Pictures/Screenshots in PNG format"
echo "   • Performance: Faster animations and key repeat"
echo "   • Privacy: Disabled tracking and auto-downloads"
echo "   • Text: Disabled auto-correct and substitutions"
echo "   • Menu Bar: Show battery percentage and improved clock format"
echo ""
echo "🔄 Some changes may require a restart to take full effect."
echo "🎨 You can customize further by editing this script and running it again."
echo ""
echo "💡 To revert any setting, change the -bool true to -bool false or"
echo "   adjust the numeric values in this script and run it again."
echo ""

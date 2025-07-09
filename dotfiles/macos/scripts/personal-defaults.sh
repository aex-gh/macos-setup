#!/usr/bin/env zsh
# Personal macOS defaults (post-bootstrap)
# Additional tweaks beyond the core setup

# Dock preferences
defaults write com.apple.dock "show-recents" -bool false
defaults write com.apple.dock "tilesize" -int 48

# Finder preferences  
defaults write com.apple.finder "FXPreferredViewStyle" -string "clmv"
defaults write com.apple.finder "ShowPathbar" -bool true

# Restart affected applications
killall Dock
killall Finder

echo "Personal macOS defaults applied"
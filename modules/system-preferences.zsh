#!/usr/bin/env zsh
# ABOUTME: Configures macOS system preferences based on YAML configuration
# ABOUTME: Handles display, audio, dock, notifications, and other system settings

set -euo pipefail

# Load YAML configuration
load_config() {
    local config_file="$1"
    if [[ ! -f "$config_file" ]]; then
        echo "Error: Configuration file not found: $config_file"
        return 1
    fi
    
    if command -v yq &> /dev/null; then
        CONFIG_DATA=$(yq eval '.' "$config_file")
    else
        CONFIG_DATA=$(cat "$config_file")
    fi
}

# Get configuration value
get_config_value() {
    local key="$1"
    local default_value="${2:-}"
    
    if command -v yq &> /dev/null; then
        yq eval ".$key" <<< "$CONFIG_DATA" 2>/dev/null || echo "$default_value"
    else
        grep -E "^[[:space:]]*${key}:" <<< "$CONFIG_DATA" | sed 's/.*: *//' | head -1 || echo "$default_value"
    fi
}

# Configure dock settings
configure_dock() {
    local config_file="$1"
    
    echo "Configuring dock from: $config_file"
    
    load_config "$config_file"
    
    local dock_position=$(get_config_value "dock.position" "bottom")
    local dock_size=$(get_config_value "dock.size" "48")
    local dock_autohide=$(get_config_value "dock.autohide" "false")
    local show_recents=$(get_config_value "dock.show_recents" "false")
    
    echo "Setting dock position to: $dock_position"
    defaults write com.apple.dock orientation -string "$dock_position"
    
    echo "Setting dock size to: $dock_size"
    defaults write com.apple.dock tilesize -int "$dock_size"
    
    local autohide_value=$([ "$dock_autohide" = "true" ] && echo "true" || echo "false")
    echo "Setting dock autohide to: $autohide_value"
    defaults write com.apple.dock autohide -bool "$autohide_value"
    
    local recents_value=$([ "$show_recents" = "true" ] && echo "true" || echo "false")
    echo "Setting show recents to: $recents_value"
    defaults write com.apple.dock show-recents -bool "$recents_value"
    
    # Restart Dock to apply changes
    killall Dock
    
    echo "Dock configuration complete"
}

# Configure display settings
configure_display() {
    local config_file="$1"
    
    echo "Configuring display from: $config_file"
    
    load_config "$config_file"
    
    local resolution=$(get_config_value "display.resolution" "auto")
    local scaling=$(get_config_value "display.scaling" "default")
    
    echo "Display resolution: $resolution (manual configuration required)"
    echo "Display scaling: $scaling (manual configuration required)"
    
    echo "Display configuration complete"
}

# Configure audio settings
configure_audio() {
    local config_file="$1"
    
    echo "Configuring audio from: $config_file"
    
    load_config "$config_file"
    
    local disable_sound_effects=$(get_config_value "audio.disable_sound_effects" "false")
    
    if [[ "$disable_sound_effects" = "true" ]]; then
        echo "Disabling sound effects"
        defaults write com.apple.systemsound "com.apple.sound.beep.volume" -float 0
        defaults write com.apple.systemsound "com.apple.sound.uiaudio.enabled" -int 0
    fi
    
    echo "Audio configuration complete"
}

# Configure notifications
configure_notifications() {
    local config_file="$1"
    
    echo "Configuring notifications from: $config_file"
    
    load_config "$config_file"
    
    local enable_notifications=$(get_config_value "notifications.enable_notifications" "true")
    local banner_style=$(get_config_value "notifications.banner_style" "banners")
    
    echo "Notifications enabled: $enable_notifications"
    echo "Banner style: $banner_style"
    
    # Note: Notification settings are complex and often require manual configuration
    echo "Notification configuration complete"
}

# Configure screensaver
configure_screensaver() {
    local config_file="$1"
    
    echo "Configuring screensaver from: $config_file"
    
    load_config "$config_file"
    
    local enable_screensaver=$(get_config_value "screensaver.enable_screensaver" "true")
    local timeout=$(get_config_value "screensaver.timeout" "300")
    
    if [[ "$enable_screensaver" = "true" ]]; then
        echo "Setting screensaver timeout to: $timeout seconds"
        defaults -currentHost write com.apple.screensaver idleTime -int "$timeout"
    else
        echo "Disabling screensaver"
        defaults -currentHost write com.apple.screensaver idleTime -int 0
    fi
    
    echo "Screensaver configuration complete"
}

# Configure Siri
configure_siri() {
    local config_file="$1"
    
    echo "Configuring Siri from: $config_file"
    
    load_config "$config_file"
    
    local enable_siri=$(get_config_value "siri.enable_siri" "true")
    local enable_hey_siri=$(get_config_value "siri.enable_listen_for_hey_siri" "true")
    
    local siri_value=$([ "$enable_siri" = "true" ] && echo "true" || echo "false")
    echo "Setting Siri enabled to: $siri_value"
    defaults write com.apple.assistant.support "Assistant Enabled" -bool "$siri_value"
    
    local hey_siri_value=$([ "$enable_hey_siri" = "true" ] && echo "true" || echo "false")
    echo "Setting Hey Siri to: $hey_siri_value"
    defaults write com.apple.assistant.support "Dictation Enabled" -bool "$hey_siri_value"
    
    echo "Siri configuration complete"
}

# Configure Apple Intelligence
configure_apple_intelligence() {
    local config_file="$1"
    
    echo "Configuring Apple Intelligence from: $config_file"
    
    load_config "$config_file"
    
    local enable_ai=$(get_config_value "apple_intelligence.enable_apple_intelligence" "false")
    
    echo "Apple Intelligence enabled: $enable_ai"
    echo "Note: Apple Intelligence settings may require manual configuration"
    
    echo "Apple Intelligence configuration complete"
}

# Configure wallpaper
configure_wallpaper() {
    local config_file="$1"
    
    echo "Configuring wallpaper from: $config_file"
    
    load_config "$config_file"
    
    local wallpaper_type=$(get_config_value "wallpaper.type" "dynamic")
    local wallpaper_color=$(get_config_value "wallpaper.color" "#1e1e1e")
    local wallpaper_name=$(get_config_value "wallpaper.name" "macOS Sonoma")
    local wallpaper_path=$(get_config_value "wallpaper.path" "")
    
    case "$wallpaper_type" in
        "solid_color")
            echo "Setting solid color wallpaper: $wallpaper_color"
            echo "Note: Solid color wallpaper requires manual configuration"
            ;;
        "dynamic")
            echo "Setting dynamic wallpaper: $wallpaper_name"
            echo "Note: Dynamic wallpaper configuration requires manual setup"
            ;;
        "image")
            if [[ -n "$wallpaper_path" ]]; then
                # Resolve relative path from project root
                local project_root
                if [[ -n "${SCRIPT_DIR:-}" ]]; then
                    project_root="${SCRIPT_DIR}/.."
                else
                    # Fallback: assume we're in modules directory
                    project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
                fi
                
                # Convert to absolute path
                local absolute_wallpaper_path
                if [[ "$wallpaper_path" = /* ]]; then
                    # Already absolute path
                    absolute_wallpaper_path="$wallpaper_path"
                else
                    # Relative path, resolve from project root
                    absolute_wallpaper_path="${project_root}/${wallpaper_path}"
                fi
                
                if [[ -f "$absolute_wallpaper_path" ]]; then
                    echo "Setting image wallpaper: $absolute_wallpaper_path"
                    # Use AppleScript to set the wallpaper for all desktops
                    osascript << EOF
tell application "System Events"
    tell every desktop
        set picture to POSIX file "$absolute_wallpaper_path"
    end tell
end tell
EOF
                    if [[ $? -eq 0 ]]; then
                        echo "Wallpaper set successfully"
                    else
                        echo "Failed to set wallpaper"
                    fi
                else
                    echo "Error: Wallpaper image not found at path: $absolute_wallpaper_path"
                fi
            else
                echo "Error: No wallpaper path specified"
            fi
            ;;
        *)
            echo "Unknown wallpaper type: $wallpaper_type"
            ;;
    esac
    
    echo "Wallpaper configuration complete"
}

# Configure all system preferences
configure_system_preferences() {
    local config_file="$1"
    
    echo "Configuring system preferences from: $config_file"
    
    configure_dock "$config_file"
    configure_display "$config_file"
    configure_audio "$config_file"
    configure_notifications "$config_file"
    configure_screensaver "$config_file"
    configure_siri "$config_file"
    configure_apple_intelligence "$config_file"
    configure_wallpaper "$config_file"
    
    echo "System preferences configuration complete"
}

# Show current system preferences
show_system_preferences() {
    echo "Current system preferences:"
    echo
    echo "Dock Settings:"
    echo "  Position: $(defaults read com.apple.dock orientation 2>/dev/null || echo 'default')"
    echo "  Size: $(defaults read com.apple.dock tilesize 2>/dev/null || echo 'default')"
    echo "  Autohide: $(defaults read com.apple.dock autohide 2>/dev/null || echo 'default')"
    echo
    echo "Screensaver Settings:"
    echo "  Timeout: $(defaults -currentHost read com.apple.screensaver idleTime 2>/dev/null || echo 'default') seconds"
    echo
    echo "Siri Settings:"
    echo "  Enabled: $(defaults read com.apple.assistant.support 'Assistant Enabled' 2>/dev/null || echo 'default')"
}

# Export functions
export -f configure_system_preferences
export -f configure_dock
export -f configure_display
export -f configure_audio
export -f configure_notifications
export -f configure_screensaver
export -f configure_siri
export -f configure_apple_intelligence
export -f configure_wallpaper
export -f show_system_preferences
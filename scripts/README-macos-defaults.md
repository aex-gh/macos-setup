# macOS Defaults Management

A comprehensive macOS defaults management script that consolidates all system configuration with backup/restore capabilities. Optimised for data engineers, AI researchers, and Python developers.

## Features

- **🔄 Backup & Restore**: Automatic backup of current settings before applying changes
- **🔍 Dry Run Mode**: Preview changes without applying them
- **🎯 Interactive Mode**: Selective application of configuration sections
- **📝 Comprehensive Logging**: Detailed logs of all changes made
- **⚡ Performance Optimised**: Faster animations and system responsiveness
- **🔒 Security Focused**: Privacy and security optimisations included

## Quick Start

```bash
# Make the script executable
chmod +x macos-defaults.zsh

# Preview changes without applying
./macos-defaults.zsh --dry-run

# Apply all defaults with confirmation
./macos-defaults.zsh

# Interactive mode for selective application
./macos-defaults.zsh --interactive
```

## Configuration Categories

### 📱 Dock Configuration
- Smaller dock size (36px) with auto-hide enabled
- Faster animations and no recent apps
- Optimised for productivity

### 📁 Finder Configuration
- List view by default, sorted by date modified
- Show hidden files, extensions, path bar, and status bar
- Home folder as default new window location

### ⚙️ System Preferences
- Faster key repeat rates for coding
- Tap to click and three-finger drag enabled
- Traditional scroll direction (natural scrolling disabled)
- Immediate screen lock after sleep

### 📸 Screenshot Settings
- PNG format saved to `~/Pictures/Screenshots`
- No shadows, includes date in filename
- Organised screenshot management

### 📊 Menu Bar & Control Center
- Battery percentage display
- Improved clock format with day of week
- Essential status indicators visible

### ⚡ Performance & Animations
- Reduced window resize animations
- Faster disk image handling
- Optimised system responsiveness

### ✏️ Text & Input Settings
- Disabled automatic text substitutions
- No auto-correct or quote/dash substitution
- Developer-friendly input behaviour

### 💻 Development Settings
- Prevent .DS_Store files on network/USB drives
- Activity Monitor optimised for development
- Secure keyboard entry in Terminal

### 🔒 Privacy & Security
- Controlled Spotlight indexing
- Disabled automatic App Store downloads
- Enhanced privacy settings

## Command Line Options

| Option | Description |
|--------|-------------|
| `-h, --help` | Show help message |
| `-v, --verbose` | Enable verbose output |
| `-d, --debug` | Enable debug mode |
| `-n, --dry-run` | Preview changes without applying |
| `-b, --backup` | Create backup only |
| `-r, --restore` | Restore from backup |
| `-i, --interactive` | Interactive mode |
| `-f, --force` | Skip confirmation prompts |

## Examples

```bash
# Create backup of current settings
./macos-defaults.zsh --backup

# Preview all changes without applying
./macos-defaults.zsh --dry-run

# Apply settings interactively (choose sections)
./macos-defaults.zsh --interactive

# Apply all settings with verbose output
./macos-defaults.zsh --verbose

# Restore from a previous backup
./macos-defaults.zsh --restore
```

## File Locations

- **Script**: `./macos-defaults.zsh`
- **Backups**: `~/.config/macos-defaults/backups/`
- **Logs**: `~/.config/macos-defaults/macos-defaults.log`

## Migration from Old Scripts

This script replaces and consolidates:
- `examples/macos-config.sh` (legacy script)
- macOS defaults commands in `zsh/dot-zprofile`
- macOS defaults commands in `zsh/dot-zshrc`

The legacy script is preserved for reference, but the new consolidated script should be used going forward.

## Requirements

- macOS 11.0+ (Big Sur or later)
- Zsh 5.8+
- Admin privileges for some system-wide settings

## Safety Features

- **Automatic Backups**: Creates backup before applying changes
- **Dry Run Mode**: Preview changes without modification
- **Detailed Logging**: All actions logged with timestamps
- **Service Restart**: Automatically restarts affected services
- **Error Handling**: Comprehensive error detection and reporting

## Troubleshooting

### Common Issues

1. **Permission Denied**: Ensure script is executable (`chmod +x macos-defaults.zsh`)
2. **Admin Rights**: Some settings require admin privileges (script will prompt)
3. **Service Restart**: Some changes require logout/restart to take full effect

### Getting Help

- Run `./macos-defaults.zsh --help` for full documentation
- Check logs at `~/.config/macos-defaults/macos-defaults.log`
- Use `--debug` flag for detailed troubleshooting information

## Version History

- **v1.0.0** (2025-01-07): Initial consolidated version
  - Merged all macOS defaults into single script
  - Added backup/restore functionality
  - Implemented dry-run and interactive modes
  - Enhanced logging and error handling
  - Optimised for data & AI development workflows

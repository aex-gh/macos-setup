# Dotfiles Configuration

This directory contains dotfiles that can be used with GNU Stow or copied manually to configure your macOS environment.

## Directory Structure

- `ghostty/` - Ghostty terminal emulator configuration
- `git/` - Git configuration and account management
- `homebrew/` - Homebrew bundle configuration
- `karabiner/` - Karabiner key mapping configuration
- `macos/` - macOS system defaults and preferences
- `ssh/` - SSH configuration templates
- `zed/` - Zed editor configuration
- `zsh/` - Zsh shell configuration

## Installation Methods

### Option 1: Using the Setup Script (Recommended)

The main setup script (`scripts/macos-setup.zsh`) will handle dotfiles installation automatically:

```bash
# Run the setup script and provide this repository as the dotfiles source
./scripts/macos-setup.zsh --dotfiles-repo https://github.com/your-username/macos-setup.git
```

### Option 2: Manual Installation with GNU Stow

1. Install GNU Stow: `brew install stow`
2. Clone or copy this repository to `~/.dotfiles`
3. Use stow to symlink configurations:

```bash
cd ~/.dotfiles
stow ghostty  # Install Ghostty configuration
stow git      # Install Git configuration
stow zsh      # Install Zsh configuration
# ... etc
```

### Option 3: Manual Copy

Copy individual configuration files to their expected locations:

```bash
# Example: Copy Ghostty configuration
mkdir -p ~/.config/ghostty
cp dotfiles/ghostty/dot-config/ghostty/config ~/.config/ghostty/config
```

## SSH Configuration with Ghostty

The Ghostty configuration includes SSH-specific optimizations:

- **Terminal title updates** - Shows active SSH connections in window title
- **SSH-optimized keybindings** - Efficient navigation and copying
- **Connection status display** - Visual indicators for SSH sessions
- **Large scrollback buffer** - Essential for SSH session logs

### SSH Helper Functions

The zsh configuration includes several SSH helper functions:

- `ssh-status` - Check current SSH connection status
- `ssh-keys` - List loaded SSH keys
- `ssh-config-check` - Validate SSH configuration
- `ssh-tunnel` - Create SSH tunnels easily
- `mac-mini` / `mac-studio` - Quick connections to personal computers

### SSH Key Management

The setup integrates with 1Password for SSH key management:

- Keys are automatically loaded from 1Password SSH Agent
- No need to manually manage SSH keys
- Secure key storage and access

## Configuration Files

### Ghostty (`ghostty/dot-config/ghostty/config`)

SSH-optimized terminal configuration with:
- Catppuccin Mocha theme
- JetBrains Mono font
- SSH-friendly keybindings
- Large scrollback buffer
- Transparency and visual effects

### Zsh (`zsh/dot-zshrc`)

Enhanced shell configuration with:
- Pure prompt with SSH indicators
- SSH helper functions
- Terminal title updates for SSH connections
- Modern CLI tool aliases
- Python/UV development environment

## Prerequisites

- macOS 14.0 or later
- Homebrew installed
- GNU Stow (for automatic installation)
- 1Password with SSH Agent (for key management)

## Customization

All configuration files can be customized by editing them directly. The setup is designed to be modular, so you can choose which configurations to install.

## Troubleshooting

### Ghostty Configuration Not Applied

1. Check that Ghostty is installed: `brew list --cask ghostty`
2. Verify config file location: `~/.config/ghostty/config`
3. Restart Ghostty after configuration changes

### SSH Functions Not Available

1. Ensure zsh configuration is loaded: `source ~/.zshrc`
2. Check that functions are defined: `type ssh-status`
3. Verify SSH configuration: `ssh-config-check`

### 1Password SSH Agent Not Working

1. Enable SSH Agent in 1Password settings
2. Restart 1Password
3. Check SSH config includes agent socket path
4. Test key loading: `ssh-keys`
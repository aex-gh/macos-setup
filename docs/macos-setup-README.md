# macOS Setup

A configuration-driven macOS setup system that follows DRY principles and provides clean, maintainable automation for Mac systems.

## Directory Structure

```
macos-setup/
├── brewfiles/          # Categorized Homebrew package lists
│   ├── base.brewfile    # Essential tools and modern CLI replacements
│   ├── dev.brewfile     # Development tools and programming languages
│   ├── productivity.brewfile  # Office and communication tools
│   └── utilities.brewfile     # System utilities and specialized tools
├── configs/            # Configuration files organised by category
│   ├── applications/    # Application-specific configurations
│   ├── assets/         # Configuration assets and resources
│   ├── development/    # Development environment configurations
│   ├── services/       # System service configurations
│   ├── system/         # System-level configurations
│   └── templates/      # Configuration templates
├── dotfiles/           # Dotfiles packages for GNU Stow
│   ├── claude/         # Claude Code configuration
│   ├── git/           # Git configuration with multi-account support
│   ├── homebrew/      # Homebrew bundle file
│   ├── karabiner/     # Karabiner Elements keyboard configuration
│   ├── macos/         # macOS-specific scripts and system defaults
│   ├── ssh/           # SSH client configuration
│   └── zsh/           # Zsh shell configuration and customisation
├── scripts/            # Setup and utility scripts
│   ├── setup_v4.zsh   # Enhanced macOS setup script (hybrid approach)
│   ├── homebrew-manager.rb    # Idempotent package management
│   ├── brew-cleanup-safe.zsh  # Safe cleanup operations
│   ├── brew-state-tracker.zsh # Package state monitoring
│   └── install-homebrew-idempotent.zsh # Enhanced installation
├── docs/               # Documentation
│   └── README.md      # This file
└── .stowrc            # GNU Stow configuration
```

## Quick Start

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/macos-setup.git
   cd macos-setup
   ```

2. **Run the main setup script:**
   ```bash
   cd scripts
   ./setup_v4.zsh
   ```
   
   This enhanced setup script (v4) provides:
   - Auto-detection of Mac model (Mac Studio, MacBook Pro, Mac Mini, etc.)
   - Hardware-specific power management optimisation
   - Comprehensive security configuration
   - Automated dotfiles management with GNU Stow
   - Module-based configuration (can enable/disable features)

3. **Optional: Run security hardening:**
   ```bash
   ./security-hardening.zsh
   ```

### Script Options

The `setup_v4.zsh` script supports several command-line options:

```bash
# Interactive setup (default)
./setup_v4.zsh

# Non-interactive setup with defaults
./setup_v4.zsh --non-interactive

# Dry run to preview changes
./setup_v4.zsh --dry-run --verbose

# Skip security configuration
./setup_v4.zsh --skip-security

# Specify custom dotfiles repository
./setup_v4.zsh --dotfiles-repo https://github.com/yourusername/dotfiles.git
```

## What Each Script Does

### setup_v4.zsh (Main Setup Script)
The enhanced hybrid setup script that combines the best of all previous versions:
- **Auto-detects Mac model** (Mac Studio, MacBook Pro, Mac Mini, iMac, Mac Pro)
- **Module-based architecture** - Enable/disable specific features:
  - Network and system basics (DNS, timezone)
  - Hardware-specific power management
  - Comprehensive security configuration
  - Sharing services (SSH, Screen Sharing)
  - Mail, Calendar, and Contacts setup
  - System dependencies (Xcode CLI, Homebrew, GNU Stow)
  - Dotfiles management
- **Hardware-specific optimisations**:
  - Mac Studio/Mac Pro: Workstation power profile, always-on operation
  - Mac Mini: Server power profile, headless optimisation
  - MacBook Pro: Battery-optimised profile with AC/battery settings
  - iMac: Desktop power profile balanced for user experience
- **Security features**:
  - FileVault encryption setup
  - Enhanced firewall configuration
  - Touch ID for sudo (portable Macs)
  - Secure defaults for Safari and system
- **Dotfiles integration** via GNU Stow
- **Non-destructive** - Creates backups before changes

### security-hardening.zsh
Additional security hardening beyond the base setup:
- Hardens firewall configuration
- Secures SSH daemon settings
- Tightens system preferences
- Hardens network settings
- Sets secure file permissions
- Disables unnecessary services
- Configures audit logging
- Secures browser settings
- Generates security report

### Homebrew Management Scripts

#### homebrew-manager.rb
Core Ruby script for idempotent package management:
- Install packages from multiple Brewfiles
- Show differences between desired and actual state
- Sync packages (install missing, remove extra)
- Create backups of current state
- Protected packages feature

#### brew-cleanup-safe.zsh
Safe wrapper for cleanup operations:
- Dry-run mode to preview changes
- Automatic backup before cleanup
- Rollback capability
- Force mode for automated workflows
- Comprehensive logging

#### brew-state-tracker.zsh
Monitor and track package state changes:
- Show current package status
- Detailed difference reporting
- Health check functionality
- Change monitoring
- State persistence

#### install-homebrew-idempotent.zsh
Enhanced installation with cleanup integration:
- System-based package installation
- Full sync with backup
- Dry-run support
- Verbose logging

## Configuration

### Module Configuration in setup_v4.zsh

The main setup script uses module toggles at the top of the file to control which features are enabled:

```zsh
# Enable/disable specific modules by changing these values to true/false
typeset -g ENABLE_NETWORK_CONFIG=true      # DNS, timezone, system preferences
typeset -g ENABLE_POWER_MANAGEMENT=true    # Hardware-specific power optimisations
typeset -g ENABLE_SECURITY_CONFIG=true     # Firewall, FileVault, etc.
typeset -g ENABLE_SHARING_SERVICES=true    # SSH, Screen Sharing
typeset -g ENABLE_MAIL_CALENDAR=true       # Mail, Calendar, Contacts apps
typeset -g ENABLE_SYSTEM_DEPENDENCIES=true # Xcode CLI, Homebrew, GNU Stow
typeset -g ENABLE_DOTFILES_MANAGEMENT=true # Backup, clone, stow dotfiles
```

### Configuration Files in configs/

The `configs/` directory contains various configuration files organised by category:
- **applications/**: Application-specific configurations
- **development/**: Development environment settings
- **services/**: System service configurations
- **system/**: System-level preferences
- **templates/**: Reusable configuration templates

## Homebrew Categories

### base.brewfile
Essential tools needed on all systems:
- Modern CLI replacements (eza, bat, fd, ripgrep, fzf)
- Core system tools (git, curl, zsh)
- Essential utilities (jq, yq, tree, htop)
- Shell enhancements (starship, tmux)
- Basic applications (1Password, Raycast, Karabiner Elements)

### dev.brewfile
Development environment tools:
- Programming languages (Python, Node, Go, Rust, Ruby, Java)
- Development tools (Docker, Kubernetes, Terraform)
- Version control (Git tools, GitHub CLI)
- IDEs and editors (VS Code, JetBrains, Sublime Text)
- Database tools (PostgreSQL, MySQL, Redis)

### productivity.brewfile
Office and productivity applications:
- Communication (Zoom, Slack, Teams, Discord)
- Note-taking (Notion, Obsidian, Bear)
- Office suites (LibreOffice, Microsoft Office)
- Creative tools (Figma, Sketch, Canva)
- Media applications (Spotify, VLC, IINA)

### utilities.brewfile
System utilities and specialized tools:
- Network tools (nmap, Wireshark, netcat)
- Media processing (ffmpeg, ImageMagick)
- System monitoring (Stats, iStat Menus)
- Security tools (Little Snitch, Authy)
- Backup tools (Carbon Copy Cloner, Arq)

## Idempotent Homebrew Management

This project now includes advanced idempotent Homebrew management tools that ensure your system packages stay in sync with your Brewfiles and can automatically clean up unwanted packages.

### New Idempotent Tools

#### homebrew-manager.rb
The core Ruby script that provides idempotent package management:

```bash
# Install packages from Brewfiles
./scripts/homebrew-manager.rb --install --brewfiles base.brewfile,dev.brewfile

# Show differences between desired and actual state
./scripts/homebrew-manager.rb --diff

# Sync packages (install missing, remove extra)
./scripts/homebrew-manager.rb --sync --verbose

# Remove packages not in any Brewfile
./scripts/homebrew-manager.rb --cleanup --dry-run

# Create backup of current state
./scripts/homebrew-manager.rb --backup --output backup.yaml
```

#### brew-cleanup-safe.zsh
Safe wrapper for cleanup operations with comprehensive safety features:

```bash
# Dry run to see what would be removed
./scripts/brew-cleanup-safe.zsh --dry-run

# Safe cleanup with backup
./scripts/brew-cleanup-safe.zsh --backup

# Force cleanup without prompts
./scripts/brew-cleanup-safe.zsh --force

# Use specific Brewfiles
./scripts/brew-cleanup-safe.zsh --brewfiles base.brewfile,dev.brewfile

# Rollback to previous state
./scripts/brew-cleanup-safe.zsh --rollback
```

#### brew-state-tracker.zsh
Monitor and track package state changes:

```bash
# Show current status
./scripts/brew-state-tracker.zsh status

# Show detailed differences
./scripts/brew-state-tracker.zsh diff

# Perform health check
./scripts/brew-state-tracker.zsh health

# Generate detailed report
./scripts/brew-state-tracker.zsh report --output report.txt

# Monitor for changes
./scripts/brew-state-tracker.zsh monitor --verbose
```

#### install-homebrew-idempotent.zsh
Enhanced installation script with idempotent cleanup integration:

```bash
# Install base packages only
./scripts/install-homebrew-idempotent.zsh --system base

# Full sync with backup
./scripts/install-homebrew-idempotent.zsh --sync --backup

# Development environment with cleanup
./scripts/install-homebrew-idempotent.zsh --system dev --cleanup --verbose

# Dry run to see what would change
./scripts/install-homebrew-idempotent.zsh --dry-run --system all
```

### Safety Features

- **Dry-run mode**: See what would be changed without executing
- **Confirmation prompts**: Get confirmation before destructive operations
- **Backup creation**: Automatic backup before cleanup operations
- **Protected packages**: Essential packages are never removed
- **Rollback capability**: Restore previous package states
- **Comprehensive logging**: All operations are logged
- **State tracking**: Monitor package changes over time

### System Types

The idempotent tools support different system types:

- **base**: Essential tools for all systems
- **dev**: Development environment packages
- **productivity**: Office and productivity applications
- **utilities**: System utilities and specialised tools
- **all**: All available packages

### Integration

The idempotent tools integrate seamlessly with your existing Brewfile structure:

1. **Merge multiple Brewfiles**: Combine different categories as needed
2. **Deduplication**: Automatically handle duplicate packages
3. **Dependency resolution**: Manage package dependencies correctly
4. **State persistence**: Track changes over time
5. **Backup management**: Automatic backup rotation and cleanup

## Dotfiles Management

The system includes automated dotfiles management using GNU Stow. Dotfiles are organised into packages in the `dotfiles/` directory and automatically symlinked to your home directory.

### Available Dotfiles Packages

- **claude**: Claude Code configuration
- **git**: Git configuration with multi-account support
- **homebrew**: Homebrew bundle file
- **karabiner**: Karabiner Elements keyboard configuration
- **macos**: macOS-specific scripts and system defaults
- **ssh**: SSH client configuration
- **zsh**: Zsh shell configuration and customisation

### Automated Setup

Dotfiles are automatically configured when you run `all-systems.zsh`. The script:

1. Installs GNU Stow via Homebrew
2. Uses the `.stowrc` configuration file for settings
3. Symlinks all dotfiles packages to your home directory
4. Reports any conflicts or issues

### Manual Dotfiles Management

The dotfiles are managed automatically by the `setup_v4.zsh` script using GNU Stow. However, you can also manage them manually:

```bash
# Navigate to the dotfiles directory
cd dotfiles

# Stow specific packages
stow zsh git ssh

# Remove packages
stow -D zsh git ssh

# Re-stow packages (useful after updates)
stow -R zsh git ssh
```

### Adding New Dotfiles

To add new dotfiles to the system:

1. Create a new package directory in `dotfiles/`
2. Place your configuration files in the appropriate structure
3. Use the setup script to apply: `./scripts/setup_v4.zsh --dotfiles-repo /path/to/your/dotfiles`
4. Or manually stow: `cd dotfiles && stow <package_name>`

## Usage Examples

### Install specific categories of applications:

#### Traditional Homebrew Bundle Method:
```bash
# Install base tools only
brew bundle --file=../brewfiles/base.brewfile

# Install development tools
brew bundle --file=../brewfiles/dev.brewfile

# Install productivity apps
brew bundle --file=../brewfiles/productivity.brewfile

# Install utilities
brew bundle --file=../brewfiles/utilities.brewfile
```

#### Idempotent Method (Recommended):
```bash
# Install base tools with cleanup
./scripts/install-homebrew-idempotent.zsh --system base --cleanup

# Install development environment
./scripts/install-homebrew-idempotent.zsh --system dev --backup --verbose

# Install productivity tools with state tracking
./scripts/install-homebrew-idempotent.zsh --system productivity --track

# Install utilities with dry run first
./scripts/install-homebrew-idempotent.zsh --system utilities --dry-run
# Then run without --dry-run if satisfied
./scripts/install-homebrew-idempotent.zsh --system utilities --sync

# Install everything with full safety features
./scripts/install-homebrew-idempotent.zsh --system all --backup --cleanup --track
```

### Use the main setup script with different options:
```bash
# Full interactive setup
./scripts/setup_v4.zsh

# Non-interactive setup with defaults
./scripts/setup_v4.zsh --non-interactive

# Dry run to preview changes
./scripts/setup_v4.zsh --dry-run --verbose

# Skip security configuration for testing
./scripts/setup_v4.zsh --skip-security

# Use specific dotfiles repository
./scripts/setup_v4.zsh --dotfiles-repo https://github.com/yourusername/dotfiles.git
```

## System Requirements

- macOS 11.0+ (Big Sur or later)
- Apple Silicon Mac (M1/M2/M3/M4)
- Administrator privileges
- Internet connection for downloads

## Important Notes

1. **Always run all-systems.zsh first** - it sets up the foundation
2. **Review configuration files** - adjust settings for your environment
3. **Test in non-production** - always test setup scripts before production use
4. **FileVault** - enable manually through System Settings after setup
5. **Backup first** - ensure you have backups before running hardening scripts

## Customisation

To customise for your environment:

1. **Edit module toggles** in `scripts/setup_v4.zsh` to enable/disable features
2. **Modify Brewfiles** in `brewfiles/` to add/remove applications
3. **Adjust dotfiles** in `dotfiles/` for your preferences
4. **Update configuration files** in `configs/` for specific applications
5. **Modify the setup script** directly for custom hardware or requirements

## Troubleshooting

- Check script logs for error messages
- Ensure administrator privileges are available
- Verify internet connectivity
- Review configuration file syntax
- Run individual modules to isolate issues

## Contributing

When adding new features:
1. Follow DRY principles
2. Use YAML configuration files
3. Create reusable modules
4. Update documentation
5. Test on multiple systems

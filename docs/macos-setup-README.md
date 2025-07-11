# macOS Setup

A comprehensive, modular macOS setup system that provides automated configuration for Apple Silicon Macs. Features hardware-specific optimisations, security hardening, and integrated dotfiles management with support for development, productivity, and server environments.

## Directory Structure

```
macos-setup/
├── brewfiles/          # Categorised Homebrew package lists
│   ├── base.brewfile    # Essential tools and modern CLI replacements
│   ├── dev.brewfile     # Development tools and programming languages
│   ├── productivity.brewfile  # Office and communication tools
│   ├── server.brewfile  # Server and infrastructure tools
│   └── utilities.brewfile     # System utilities and specialised tools
├── configs/            # Configuration files organised by category
│   ├── applications/    # Application-specific configurations
│   ├── assets/         # Configuration assets and resources
│   ├── claude/         # Claude Code MCP server configurations
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
│   ├── zed/           # Zed editor configuration
│   └── zsh/           # Zsh shell configuration and customisation
├── scripts/            # Setup and utility scripts
│   ├── macos-setup.zsh # Main macOS setup script with module toggles
│   ├── craftbrew.zsh   # Idempotent Homebrew package management
│   ├── install-claude-code.zsh # Claude Code installation with MCP servers
│   └── macos-security-hardening.zsh # Security hardening script
├── docs/               # Documentation
│   ├── claude-code-README.md   # Claude Code setup documentation
│   ├── macos-setup-README.md   # Main setup documentation
│   └── zed-README.md          # Zed editor configuration documentation
├── .stowrc            # GNU Stow configuration
├── CLAUDE.md          # Project instructions for Claude Code
├── CLAUDE.local.md    # Local project instructions
└── DefaultKeyBinding.dict # macOS key bindings
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
   ./macos-setup.zsh
   ```
   
   This comprehensive setup script (v4.0) provides:
   - Auto-detection of Mac model (Mac Studio, MacBook Pro, Mac Mini, etc.)
   - Hardware-specific power management optimisation
   - Comprehensive security configuration
   - Automated dotfiles management with GNU Stow
   - Module-based configuration (can enable/disable features)
   - Idempotent Homebrew package management

3. **Optional: Run security hardening:**
   ```bash
   ./macos-security-hardening.zsh
   ```

4. **Optional: Install Claude Code with MCP servers:**
   ```bash
   ./install-claude-code.zsh
   ```

### Script Options

The `macos-setup.zsh` script supports several command-line options:

```bash
# Interactive setup (default)
./macos-setup.zsh

# Non-interactive setup with defaults
./macos-setup.zsh --non-interactive

# Dry run to preview changes
./macos-setup.zsh --dry-run --verbose

# Skip security configuration
./macos-setup.zsh --skip-security

# Specify custom dotfiles repository
./macos-setup.zsh --dotfiles-repo https://github.com/yourusername/dotfiles.git
```

## What Each Script Does

### macos-setup.zsh (Main Setup Script)
The comprehensive modular setup script (v4.0) that provides:
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

### macos-security-hardening.zsh
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

#### craftbrew.zsh
Comprehensive idempotent Homebrew package management:
- Install packages from multiple Brewfiles
- Show differences between desired and actual state
- Sync packages (install missing, remove extra)
- Create backups of current state
- Protected packages feature
- Dry-run mode to preview changes
- Automatic backup before cleanup
- Rollback capability
- Force mode for automated workflows
- Comprehensive logging

### Claude Code Integration

#### install-claude-code.zsh
Comprehensive Claude Code installation with MCP server setup:
- Install Claude Code CLI tool
- Configure essential MCP servers (FileSystem, Sequential Thinking, etc.)
- Optional MCP servers with API key setup (GitHub, Brave Search, PostgreSQL)
- Automated dotfiles integration
- Environment variable configuration
- Configuration template management

## Configuration

### Module Configuration in macos-setup.zsh

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
- IDEs and editors (VS Code, JetBrains, Sublime Text, Zed)
- Database tools (PostgreSQL, MySQL, Redis)

### productivity.brewfile
Office and productivity applications:
- Communication (Zoom, Slack, Teams, Discord)
- Note-taking (Notion, Obsidian, Bear)
- Office suites (LibreOffice, Microsoft Office)
- Creative tools (Figma, Sketch, Canva)
- Media applications (Spotify, VLC, IINA)

### server.brewfile
Server and infrastructure tools:
- Web servers (nginx, apache)
- Database servers (PostgreSQL, MySQL, Redis)
- Monitoring tools (Prometheus, Grafana)
- Infrastructure as code (Terraform, Ansible)
- Container orchestration (Docker, Kubernetes)

### utilities.brewfile
System utilities and specialised tools:
- Network tools (nmap, Wireshark, netcat)
- Media processing (ffmpeg, ImageMagick)
- System monitoring (Stats, iStat Menus)
- Security tools (Little Snitch, Authy)
- Backup tools (Carbon Copy Cloner, Arq)

## Idempotent Homebrew Management

This project includes advanced idempotent Homebrew management through the `craftbrew.zsh` script that ensures your system packages stay in sync with your Brewfiles and can automatically clean up unwanted packages.

### Craftbrew Tool

#### craftbrew.zsh
Comprehensive idempotent package management:

```bash
# Install packages from Brewfiles
./scripts/craftbrew.zsh --install --brewfiles base.brewfile,dev.brewfile

# Show differences between desired and actual state
./scripts/craftbrew.zsh --diff

# Sync packages (install missing, remove extra)
./scripts/craftbrew.zsh --sync --verbose

# Remove packages not in any Brewfile
./scripts/craftbrew.zsh --cleanup --dry-run

# Create backup of current state
./scripts/craftbrew.zsh --backup --output backup.yaml

# Dry run to see what would be removed
./scripts/craftbrew.zsh --dry-run

# Safe cleanup with backup
./scripts/craftbrew.zsh --backup

# Force cleanup without prompts
./scripts/craftbrew.zsh --force

# Use specific Brewfiles
./scripts/craftbrew.zsh --brewfiles base.brewfile,dev.brewfile

# Rollback to previous state
./scripts/craftbrew.zsh --rollback
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
- **server**: Server and infrastructure tools
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
- **zed**: Zed editor configuration
- **zsh**: Zsh shell configuration and customisation

### Automated Setup

Dotfiles are automatically configured when you run `macos-setup.zsh`. The script:

1. Installs GNU Stow via Homebrew
2. Uses the `.stowrc` configuration file for settings
3. Symlinks all dotfiles packages to your home directory
4. Reports any conflicts or issues

### Manual Dotfiles Management

The dotfiles are managed automatically by the `macos-setup.zsh` script using GNU Stow. However, you can also manage them manually:

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
3. Use the setup script to apply: `./scripts/macos-setup.zsh --dotfiles-repo /path/to/your/dotfiles`
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
./scripts/craftbrew.zsh --brewfiles base.brewfile --cleanup

# Install development environment
./scripts/craftbrew.zsh --brewfiles dev.brewfile --backup --verbose

# Install productivity tools
./scripts/craftbrew.zsh --brewfiles productivity.brewfile

# Install utilities with dry run first
./scripts/craftbrew.zsh --brewfiles utilities.brewfile --dry-run
# Then run without --dry-run if satisfied
./scripts/craftbrew.zsh --brewfiles utilities.brewfile --sync

# Install everything with full safety features
./scripts/craftbrew.zsh --brewfiles base.brewfile,dev.brewfile,productivity.brewfile,server.brewfile,utilities.brewfile --backup --cleanup
```

### Use the main setup script with different options:
```bash
# Full interactive setup
./scripts/macos-setup.zsh

# Non-interactive setup with defaults
./scripts/macos-setup.zsh --non-interactive

# Dry run to preview changes
./scripts/macos-setup.zsh --dry-run --verbose

# Skip security configuration for testing
./scripts/macos-setup.zsh --skip-security

# Use specific dotfiles repository
./scripts/macos-setup.zsh --dotfiles-repo https://github.com/yourusername/dotfiles.git
```

## System Requirements

- macOS 11.0+ (Big Sur or later)
- Apple Silicon Mac (M1/M2/M3/M4)
- Administrator privileges
- Internet connection for downloads

## Important Notes

1. **Always run macos-setup.zsh first** - it sets up the foundation
2. **Review configuration files** - adjust settings for your environment
3. **Test in non-production** - always test setup scripts before production use
4. **FileVault** - enable manually through System Settings after setup
5. **Backup first** - ensure you have backups before running hardening scripts
6. **Claude Code** - run install-claude-code.zsh for AI development tools

## Customisation

To customise for your environment:

1. **Edit module toggles** in `scripts/macos-setup.zsh` to enable/disable features
2. **Modify Brewfiles** in `brewfiles/` to add/remove applications
3. **Adjust dotfiles** in `dotfiles/` for your preferences
4. **Update configuration files** in `configs/` for specific applications
5. **Modify the setup script** directly for custom hardware or requirements
6. **Configure Claude Code** in `configs/claude/` for MCP server settings

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

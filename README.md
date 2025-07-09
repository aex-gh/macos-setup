# Simple macOS Setup

A simplified, configuration-driven macOS setup system that follows DRY principles and provides clean, maintainable automation for Mac systems.

## Directory Structure

```
macos-setup/simple/
├── brewfiles/          # Categorized Homebrew package lists
│   ├── base.brewfile    # Essential tools and modern CLI replacements
│   ├── dev.brewfile     # Development tools and programming languages
│   ├── productivity.brewfile  # Office and communication tools
│   └── utilities.brewfile     # System utilities and specialized tools
├── dotfiles/           # Dotfiles and configuration packages
│   └── packages/       # Copied from main packages directory
├── scripts/            # Setup scripts
│   ├── config/         # YAML configuration files
│   │   ├── base.yml    # Base configuration for all systems
│   │   ├── mac-studio.yml    # Mac Studio specific config
│   │   ├── macbook-pro.yml   # MacBook Pro specific config
│   │   └── mac-mini.yml      # Mac Mini specific config
│   ├── all-systems.zsh       # Common setup for all systems
│   ├── mac-studio.zsh        # Mac Studio specific setup
│   ├── macbook-pro.zsh       # MacBook Pro specific setup
│   ├── mac-mini.zsh          # Mac Mini specific setup
│   └── security-hardening.zsh # Security hardening script
├── configs/            # Additional configuration files
├── modules/            # Reusable configuration modules
│   ├── network.zsh           # Network configuration
│   ├── power-management.zsh  # Power management settings
│   ├── security.zsh          # Security configuration
│   ├── sharing.zsh           # File sharing and remote access
│   └── system-preferences.zsh # System preferences
└── README.md           # This file
```

## Quick Start

1. **Run the all-systems setup first:**
   ```bash
   cd macos-setup/simple/scripts
   ./all-systems.zsh
   ```

2. **Run your system-specific setup:**
   ```bash
   # For Mac Studio
   ./mac-studio.zsh
   
   # For MacBook Pro
   ./macbook-pro.zsh
   
   # For Mac Mini
   ./mac-mini.zsh
   ```

3. **Optional: Run security hardening:**
   ```bash
   ./security-hardening.zsh
   ```

## What Each Script Does

### all-systems.zsh
- Updates macOS system
- Installs Xcode Command Line Tools
- Installs and configures Homebrew
- Installs essential applications (1Password, Karabiner Elements)
- **Configures dotfiles using GNU Stow**
- Configures remote access (SSH)
- Enables file sharing (SMB)
- Configures network discovery (Bonjour)
- Applies basic security settings
- Configures time synchronization for Adelaide, Australia
- Applies common macOS defaults
- Disables telemetry and analytics

### System-Specific Scripts

#### mac-studio.zsh
- Configures system for always-on server operation
- Sets static IP address (192.168.1.100)
- Disables Wi-Fi, enables Ethernet
- Optimizes power management (never sleep)
- Enables comprehensive sharing services
- Configures for high-performance operation

#### macbook-pro.zsh
- Configures system for mobile productivity
- Enables balanced power management
- Keeps Wi-Fi enabled for mobility
- Enables Touch ID for sudo
- Configures for battery optimization
- Enables full visual effects and user experience

#### mac-mini.zsh
- Configures system for compact server operation
- Sets static IP address (192.168.1.101)
- Disables Wi-Fi, enables Ethernet
- Optimizes for always-on operation with limited resources
- Enables server-like functionality
- Minimizes UI elements for headless operation

### security-hardening.zsh
- Hardens firewall configuration
- Secures SSH daemon settings
- Tightens system preferences
- Hardens network settings
- Sets secure file permissions
- Disables unnecessary services
- Configures audit logging
- Secures browser settings
- Generates security report

## Configuration Files

Each system has a corresponding YAML configuration file in `scripts/config/` that defines:

- Hardware specifications
- System naming
- Network configuration
- Power management settings
- Security preferences
- Sharing services
- Performance optimizations
- Application preferences

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

You can also manage dotfiles manually using the dedicated module:

```bash
# Interactive dotfiles manager
./modules/dotfiles.zsh

# Or source the module and use individual functions
source modules/dotfiles.zsh
setup_dotfiles                    # Setup all packages
stow_package "zsh"                # Stow a specific package
unstow_package "git"              # Remove a package
show_dotfiles_status              # Show current status
```

### Adding New Dotfiles

To add new dotfiles to the system:

1. Create a new package directory in `dotfiles/`
2. Use the `dot-` prefix for files that should become hidden (e.g., `dot-zshrc` → `~/.zshrc`)
3. Run `stow_package <package_name>` to activate

## Usage Examples

### Install specific categories of applications:
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

### Use individual modules:
```bash
# Configure network settings
source ../modules/network.zsh
configure_network config/mac-studio.yml

# Configure power management
source ../modules/power-management.zsh
configure_power_management config/macbook-pro.yml

# Configure security
source ../modules/security.zsh
configure_security config/base.yml
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

## Customization

To customize for your environment:

1. Edit the YAML configuration files in `scripts/config/`
2. Modify the Brewfiles to add/remove applications
3. Adjust modules in `modules/` for different behaviours
4. Update system-specific scripts as needed

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
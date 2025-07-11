# Craftbrew - Idempotent Homebrew Package Manager

## Overview

Craftbrew is a sophisticated idempotent Homebrew package management tool that provides safe, automated package installation, cleanup, and synchronisation. Built on native `brew bundle` functionality, it ensures your system packages stay in sync with your Brewfiles while providing comprehensive safety features and rollback capabilities.

## Features

### Core Functionality
- **Idempotent Operations**: Safe to run multiple times without side effects
- **Multi-Brewfile Support**: Merge and process multiple Brewfiles simultaneously
- **System Type Management**: Predefined package sets for different system configurations
- **Dry-Run Mode**: Preview changes before execution
- **Backup and Rollback**: Create backups before destructive operations
- **Comprehensive Logging**: Detailed operation logs for troubleshooting

### Safety Features
- **Confirmation Prompts**: Interactive confirmation for destructive operations
- **Force Mode**: Skip prompts for automated workflows
- **Temporary File Management**: Automatic cleanup of temporary files
- **Error Handling**: Robust error handling with cleanup on failure
- **Homebrew Auto-Installation**: Automatically installs Homebrew if missing

## Installation

Craftbrew is part of the macOS setup system and is located at:
```bash
/Users/andrew/projects/personal/macos-setup/scripts/craftbrew.zsh
```

### Prerequisites
- macOS 11.0+ (Big Sur)
- Zsh shell
- Internet connection for package downloads
- Administrator privileges (for Homebrew installation)

## Usage

### Basic Syntax
```bash
./scripts/craftbrew.zsh [options] [command]
```

### Commands

#### install (default)
Install missing packages only:
```bash
./scripts/craftbrew.zsh install
./scripts/craftbrew.zsh --system dev
```

#### cleanup
Remove packages not in Brewfiles:
```bash
./scripts/craftbrew.zsh cleanup --dry-run
./scripts/craftbrew.zsh cleanup --force
```

#### sync
Install missing and remove unlisted packages:
```bash
./scripts/craftbrew.zsh sync
./scripts/craftbrew.zsh sync --system all --verbose
```

#### diff
Show what would be installed/removed:
```bash
./scripts/craftbrew.zsh diff
./scripts/craftbrew.zsh diff --system productivity
```

#### backup
Export current state to Brewfile:
```bash
./scripts/craftbrew.zsh backup
./scripts/craftbrew.zsh backup --output ~/my-backup.brewfile
```

### Options

| Option | Description |
|--------|-------------|
| `-h, --help` | Show help message |
| `-v, --verbose` | Enable verbose output |
| `-n, --dry-run` | Show what would be done without executing |
| `-f, --force` | Skip confirmation prompts |
| `-q, --quiet` | Suppress non-error output |
| `--system TYPE` | System type (base\|dev\|productivity\|server\|utilities\|all) |
| `--brewfiles FILES` | Comma-separated list of specific Brewfiles to use |
| `--output FILE` | Output file for backup command |
| `--version` | Show version information |

## System Types

### Predefined System Types

#### base
Essential tools for all systems:
- Modern CLI replacements (eza, bat, fd, ripgrep, fzf)
- Core system tools (git, curl, zsh)
- Essential utilities (jq, yq, tree, htop)
- Shell enhancements (starship, tmux)

#### dev
Development environment packages:
- Base packages plus development tools
- Programming languages (Python, Node, Go, Rust)
- IDEs and editors (VS Code, Zed)
- Database tools (PostgreSQL, MySQL, Redis)

#### productivity
Office and productivity applications:
- Base packages plus productivity tools
- Communication (Zoom, Slack, Teams)
- Note-taking (Notion, Obsidian)
- Creative tools (Figma, Sketch)

#### server
Server and infrastructure tools:
- Base packages plus server tools
- Web servers (nginx, apache)
- Infrastructure as code (Terraform, Ansible)
- Container orchestration (Docker, Kubernetes)

#### utilities
System utilities and specialised tools:
- Base packages plus utilities
- Network tools (nmap, Wireshark)
- Media processing (ffmpeg, ImageMagick)
- System monitoring (Stats, iStat Menus)

#### all
All available packages from all system types.

## Usage Examples

### Basic Package Management
```bash
# Install base packages
./scripts/craftbrew.zsh --system base

# Install development environment
./scripts/craftbrew.zsh --system dev

# Install everything
./scripts/craftbrew.zsh --system all
```

### Advanced Operations
```bash
# Preview changes before installing
./scripts/craftbrew.zsh install --system dev --dry-run

# Synchronise packages with verbose output
./scripts/craftbrew.zsh sync --system all --verbose

# Clean up unused packages (with confirmation)
./scripts/craftbrew.zsh cleanup --system dev

# Force cleanup without prompts
./scripts/craftbrew.zsh cleanup --force --quiet
```

### Custom Brewfiles
```bash
# Use specific Brewfiles
./scripts/craftbrew.zsh --brewfiles base.brewfile,custom.brewfile

# Use absolute paths
./scripts/craftbrew.zsh --brewfiles /path/to/custom.brewfile
```

### Backup and Restore
```bash
# Create backup of current state
./scripts/craftbrew.zsh backup --output ~/backup-$(date +%Y%m%d).brewfile

# Show what would be installed from backup
./scripts/craftbrew.zsh diff --brewfiles ~/backup-20240101.brewfile
```

## Configuration

### Brewfile Location
Craftbrew automatically looks for Brewfiles in:
```
../brewfiles/
├── base.brewfile
├── dev.brewfile
├── productivity.brewfile
├── server.brewfile
└── utilities.brewfile
```

### Temporary Files
- Merged Brewfiles are created in `/tmp/` with secure permissions
- Automatic cleanup on script exit
- Log files stored in `/tmp/craftbrew.log`

### Environment Variables
Craftbrew respects standard Homebrew environment variables:
- `HOMEBREW_PREFIX`: Homebrew installation prefix
- `HOMEBREW_NO_ANALYTICS`: Disable analytics (automatically set)

## Integration with macOS Setup

### Automatic Integration
Craftbrew is automatically used by the main setup script:
```bash
./scripts/macos-setup.zsh
```

### Manual Integration
Use specific system types in your own scripts:
```bash
# Install development environment
./scripts/craftbrew.zsh --system dev --force --quiet

# Clean up after installation
./scripts/craftbrew.zsh cleanup --dry-run
```

## Troubleshooting

### Common Issues

#### Homebrew Not Found
```bash
Error: Missing required commands: brew
```
**Solution**: Craftbrew will automatically install Homebrew if missing.

#### Permission Denied
```bash
Error: Permission denied when installing packages
```
**Solution**: Ensure you have administrator privileges. Some packages require sudo access.

#### Brewfile Not Found
```bash
Error: Brewfile not found: /path/to/brewfile
```
**Solution**: Verify the Brewfile exists and path is correct. Use `--brewfiles` option for custom locations.

### Debug Mode
Enable verbose output for troubleshooting:
```bash
./scripts/craftbrew.zsh --verbose --dry-run
```

### Log Files
Check the log file for detailed information:
```bash
cat /tmp/craftbrew.log
```

## Safety and Best Practices

### Before Running
1. **Always test first**: Use `--dry-run` to preview changes
2. **Create backups**: Use `backup` command before major changes
3. **Start small**: Begin with `--system base` before installing everything
4. **Review Brewfiles**: Ensure your Brewfiles contain only desired packages

### During Operation
1. **Monitor output**: Watch for errors or warnings
2. **Check confirmations**: Read prompts carefully before confirming
3. **Use verbose mode**: Enable for detailed operation logs
4. **Interrupt safely**: Use Ctrl+C to cancel operations if needed

### After Operation
1. **Verify installation**: Check that required packages are installed
2. **Test functionality**: Ensure applications work as expected
3. **Review logs**: Check for any warnings or errors
4. **Clean up**: Remove unnecessary packages with `cleanup` command

## Advanced Usage

### Custom Brewfile Creation
Create custom Brewfiles for specific use cases:
```bash
# Create a custom Brewfile
cat > custom.brewfile << 'EOF'
# Custom development setup
tap "homebrew/cask-fonts"
brew "neovim"
brew "tmux"
cask "font-fira-code"
EOF

# Use custom Brewfile
./scripts/craftbrew.zsh --brewfiles custom.brewfile
```

### Automated Workflows
Use in CI/CD or automated setup scripts:
```bash
# Non-interactive installation
./scripts/craftbrew.zsh install --system dev --force --quiet

# Automated cleanup
./scripts/craftbrew.zsh cleanup --force --quiet
```

### Combining with Other Tools
Integrate with other macOS setup tools:
```bash
# Install packages then configure dotfiles
./scripts/craftbrew.zsh --system dev
stow -d dotfiles zsh git
```

## Version Information

- **Version**: 1.0.0
- **Compatibility**: macOS 11.0+ (Big Sur)
- **Shell**: Zsh
- **Dependencies**: Homebrew (auto-installed)

## Support

For issues or questions:
1. Check verbose output: `./scripts/craftbrew.zsh --verbose`
2. Review log files: `cat /tmp/craftbrew.log`
3. Test with dry-run: `./scripts/craftbrew.zsh --dry-run`
4. Create backup first: `./scripts/craftbrew.zsh backup`
5. Review the main project documentation

## Contributing

When modifying Craftbrew:
1. Follow the existing code style and patterns
2. Test thoroughly with `--dry-run` mode
3. Update documentation for new features
4. Ensure backwards compatibility
5. Add appropriate error handling and logging
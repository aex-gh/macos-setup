# macOS Setup Automation

A comprehensive macOS setup automation project designed to create reproducible, automated configurations for multiple Mac types within a family environment.

## Overview

This project supports three distinct Mac configurations:
- **MacBook Pro**: Portable development workstation with WiFi connectivity
- **Mac Studio**: Headless server infrastructure with static IP
- **Mac Mini**: Lightweight development + multimedia system with static IP

## Features

- **Layered Configuration Architecture**: Modular approach with User, Application, Mac Model, and Common Base layers
- **Device-Specific Optimisations**: Tailored configurations for each Mac model
- **Multi-User Family Environment**: Support for multiple family members with appropriate permissions
- **Security-First Approach**: FileVault encryption, 1Password integration, gentle hardening
- **Australian Localisation**: All text uses Australian English spelling and Adelaide timezone
- **Complete Automation**: Fully automated setup from fresh macOS installation to production-ready system
- **Comprehensive Testing**: Full test suite covering all setup scenarios
- **Performance Optimised**: Caching and parallel operations for faster deployment

## Project Structure

```
macos-setupv2/
├── docs/                    # Documentation and planning
├── configs/                 # Device-specific configurations
│   ├── common/             # Base layer configurations
│   ├── macbook-pro/        # Portable development configs
│   ├── mac-studio/         # Server infrastructure configs
│   └── mac-mini/           # Lightweight development configs
├── scripts/                # Setup and utility scripts
├── dotfiles/               # chezmoi source directory
└── tests/                  # BATS test files
```

## Technology Stack

- **Shell**: Zsh with comprehensive scripting standards
- **Package Management**: Homebrew with clean, device-specific Brewfiles
- **Dotfile Management**: chezmoi for reproducible user configurations with encryption
- **Development**: Python 3.13 (uv/ruff), Node.js, Ruby, containerisation via OrbStack
- **Testing**: BATS (Bash Automated Testing System) with comprehensive test coverage
- **Performance**: Optimisation tools and caching for faster setup times

## Core Applications

- **1Password**: Centralised password management
- **Jump Desktop**: Remote access for headless systems
- **Raycast**: Productivity launcher
- **Karabiner Elements**: Keyboard customisation
- **Zed**: Code editor
- **Gruvbox Dark Soft Contrast**: Standardised theme
- **Maple Mono Nerd Font**: Standardised font

## Network Configuration

- **MacBook Pro**: WiFi, dynamic IP (10.20.0.11)
- **Mac Studio**: Ethernet, static IP (10.20.0.10)
- **Mac Mini**: Ethernet, static IP (10.20.0.12)

## Family Users

- **Andrew Exley** (andrew): Primary admin user
- **Ali Exley** (ali): Standard user
- **Amelia Exley** (amelia): Standard user
- **Annabelle Exley** (annabelle): Standard user

## Quick Start

> **Status**: All implementation phases complete. Ready for production use.

1. Clone this repository
2. Review device-specific configurations in `configs/`
3. **Check for script conflicts**: `./scripts/detect-script-conflicts.zsh`
4. Run the main setup script: `./scripts/setup.zsh`
5. Follow the interactive prompts for your specific Mac model
6. System will automatically detect Mac type and apply appropriate configurations

> **Important**: Review [Script Execution Guidelines](docs/script-execution-guidelines.md) before running setup scripts to avoid conflicts.

## Development

### Prerequisites

- macOS (tested on recent versions)
- Zsh shell
- Git

### Scripting Standards

All scripts follow comprehensive zsh standards documented in `docs/macos-zsh-standards.md`:
- Strict error handling with `set -euo pipefail`
- Colour-coded logging with context tracking
- Proper cleanup functions and trap handling
- BATS framework for testing

### Testing

```bash
# Run all tests
./scripts/run-tests.zsh

# Run specific test file
bats tests/test_setup_main.bats

# Run tests for specific component
bats tests/test_homebrew.bats
bats tests/test_security.bats
bats tests/test_dotfiles.bats
```

## Security

- Never commit credentials or API keys
- All passwords and SSH keys managed via 1Password
- FileVault encryption enabled on all devices
- Appropriate firewall settings for each device type
- Secure temporary file creation patterns

## Documentation

- [Project Plan](docs/project-plan.md) - Detailed implementation roadmap
- [Zsh Standards](docs/macos-zsh-standards.md) - Comprehensive scripting guidelines
- [macOS Specialist Role](docs/role-macos-specialist.md) - AI assistant role definition
- [Task List](docs/todo.md) - Project completion status
- [Script Execution Guidelines](docs/script-execution-guidelines.md) - Safe script execution procedures
- [Script Conflict Analysis](docs/script-conflict-analysis.md) - Detailed conflict analysis
- [Troubleshooting](docs/troubleshooting.md) - Common issues and solutions
- [Security Best Practices](docs/security-best-practices.md) - Security implementation guide
- [Customisation Examples](docs/customisation-examples.md) - How to customise for your needs

## Unique Features

- **Linux Compatibility**: Integration with [linuxify](https://github.com/pkill37/linuxify) for Linux command compatibility
- **Claude Code Integration**: Complete MCP server configurations for AI development assistance
- **Dotfile Templates**: Based on proven macOS-specific configurations with encryption support
- **Idempotent Operations**: Safe to run multiple times without side effects
- **Performance Optimisation**: Built-in caching and parallel operations for faster setup
- **Comprehensive Brewfiles**: Clean, validated package lists with no trial/paid software (except 1Password and Jump Desktop)
- **Advanced Features**: AppleScript automation, system maintenance tools, and backup/restore procedures

## Implementation Status

✅ **Complete** - All 10 phases implemented and tested:
- Phase 1: Foundation Setup
- Phase 2: Project Structure Creation
- Phase 3: Core Brewfiles
- Phase 4: Essential Scripts
- Phase 5: Security and User Management
- Phase 6: Device-Specific Features
- Phase 7: Dotfiles and Theming
- Phase 8: Advanced Features
- Phase 9: Testing and Documentation
- Phase 10: Script Conflict Resolution

## Script Conflict Resolution

This project includes comprehensive conflict detection and resolution:

### Conflict Detection
- **Automated Analysis**: `detect-script-conflicts.zsh` identifies overlapping operations
- **Detailed Reports**: Comprehensive conflict analysis with recommendations
- **Regular Monitoring**: Tools to check for conflicts after script modifications

### Conflict Resolution
- **Script Refactoring**: Eliminated overlapping operations between scripts
- **Clear Separation**: Each script has distinct responsibilities
- **Execution Guidelines**: Safe script execution order and combinations

### Key Resolutions
- **User Management**: Separated user creation from family environment setup
- **System Configuration**: Removed duplicate system preference settings
- **Font Installation**: Standardised on Homebrew-only font installation
- **Power Management**: Consolidated device-specific power settings

> **Note**: Always run `detect-script-conflicts.zsh` before executing setup scripts to ensure no conflicts exist.

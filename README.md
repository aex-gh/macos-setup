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
- **Package Management**: Homebrew with device-specific Brewfiles
- **Dotfile Management**: chezmoi for reproducible user configurations
- **Development**: Python (uv/ruff), Node.js, Ruby, containerisation via OrbStack
- **Testing**: BATS (Bash Automated Testing System)

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

> **Note**: This project is currently in the planning and documentation phase. Implementation scripts are being developed.

1. Clone this repository
2. Review device-specific configurations in `configs/`
3. Run the main setup script: `./scripts/setup.zsh`
4. Follow the interactive prompts for your specific Mac model

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
bats tests/

# Run specific test file
bats tests/test-setup.bats
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
- [Task List](docs/todo.md) - Current development progress

## Unique Features

- **Linux Compatibility**: Integration with [linuxify](https://github.com/pkill37/linuxify) for Linux command compatibility
- **Claude Code Integration**: MCP server configurations for AI development assistance
- **Dotfile Templates**: Based on proven macOS-specific configurations
- **Idempotent Operations**: Safe to run multiple times without side effects

## Contributing

This is a personal family setup project, but contributions and suggestions are welcome. Please ensure all contributions:
- Follow the established zsh scripting standards
- Use Australian English spelling
- Include appropriate tests
- Maintain security best practices

## Licence

This project is for personal use within the Exley family environment.
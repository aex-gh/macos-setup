# Claude Configuration for macOS Setup

This is the Claude configuration for the macOS setup repository, providing context and guidelines for working with this project.

## Project Overview

This is a configuration-driven macOS setup system that automates the installation and configuration of development environments across multiple Mac systems. The project follows DRY principles and uses modular architecture.

## Key Architecture Principles

- **Modular Design**: Scripts are organised into modules for different system aspects (network, security, power management, etc.)
- **Configuration-Driven**: Uses YAML configuration files for different Mac models
- **Brewfile Management**: Categorised Homebrew packages for different use cases
- **Dotfiles Integration**: Uses GNU Stow for dotfiles management
- **Australian Standards**: Uses Australian English (en-AU) spelling throughout

## Directory Structure

```
macos-setup/
├── brewfiles/          # Categorised Homebrew package lists
├── dotfiles/           # Dotfiles and configuration packages
├── scripts/            # Setup scripts for different systems
├── configs/            # Additional configuration files
├── modules/            # Reusable configuration modules
└── README.md           # Project documentation
```

## Coding Standards

- Use Australian English (en-AU) spelling (e.g., "colour" not "color", "customise" not "customize")
- Follow zsh scripting standards as defined in `.project-settings/macos-zsh-standards.md`
- All scripts should have ABOUTME comments explaining their purpose
- Use consistent logging functions: `log_info`, `log_success`, `log_warn`, `log_error`
- Include proper error handling with `set -euo pipefail`
- Use readonly variables for configuration
- Include comprehensive usage documentation

## File Naming Conventions

- Scripts: `kebab-case.zsh`
- Configuration files: `kebab-case.yml`
- Dotfiles: Use `dot-` prefix for stow packages
- Brewfiles: `category.brewfile`

## Common Tasks

When working on this project, common tasks include:
- Adding new packages to appropriate brewfiles
- Creating system-specific configuration scripts
- Updating dotfiles packages
- Enhancing security and system configuration modules
- Testing across different Mac models (MacBook Pro, Mac Studio, Mac Mini)

## Testing Approach

- Scripts should be tested across different Mac models
- Use the configuration files in `scripts/config/` for model-specific settings
- Verify installations work with both fresh systems and updates
- Test dotfiles integration with stow

## Security Considerations

- All scripts include security hardening where appropriate
- File permissions are set correctly
- No credentials or sensitive data should be hardcoded
- Use secure defaults for all configurations

## Usage

To use this configuration:
1. Stow this package: `stow claude`
2. Claude will use these settings when working in this environment
3. Edit this file to customise Claude behaviour for this project
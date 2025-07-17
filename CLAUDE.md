# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a macOS setup automation project designed to create reproducible, automated configurations for multiple Mac types within a family environment. The project supports MacBook Pro (portable development), Mac Studio (headless server), and Mac Mini (lightweight development + multimedia) with device-specific optimisations.

**Current Status:** Complete implementation with comprehensive script optimisation and conflict resolution system. All 10 phases completed including Phase 11 script optimisation.

## Core Architecture

The system uses a **layered configuration approach**:

```
User Layer          ← Personal dotfiles managed by chezmoi
Application Layer   ← App-specific configurations
Mac Model Layer     ← Device-specific settings and optimisations  
Common Base Layer   ← Universal tools and macOS defaults
```

**Device-Specific Network Configuration:**
- MacBook Pro: WiFi, dynamic IP (10.20.0.11) - portable development workstation
- Mac Studio: Ethernet, static IP (10.20.0.10) - headless server infrastructure  
- Mac Mini: Ethernet, static IP (10.20.0.12) - lightweight development + multimedia

## Technology Stack

**Core Tools:**
- **Shell:** Zsh (with comprehensive scripting standards in `docs/macos-zsh-standards.md`)
- **Package Management:** Homebrew with Brewfiles for each device type
- **Dotfile Management:** chezmoi for reproducible user configurations
- **Development:** Python (uv/ruff), Node.js, Ruby, containerisation via OrbStack

**Essential Applications:**
- 1Password (centralised password management)
- Jump Desktop (remote access for headless systems)
- Raycast, Karabiner Elements, Zed editor
- Standardised font: Maple Mono Nerd Font
- Standardised theme: Gruvbox Dark Soft Contrast

## Key Requirements and Standards

**Australian English:** All documentation, comments, and user-facing text must use Australian English spelling.

**Multi-User Family Environment:**
- Primary admin user: Andrew Exley (andrew)
- Standard users: Ali Exley (ali), Amelia Exley (amelia), Annabelle Exley (annabelle)
- Mac Studio provides central file server and Time Machine backup for all users

**Security Approach:**
- FileVault encryption on all devices
- Gentle hardening rather than enterprise-level restrictions
- Network segmentation between device types
- All passwords and SSH keys managed via 1Password

## Development Workflows

**Zsh Scripting Standards:**
- Follow comprehensive standards documented in `docs/macos-zsh-standards.md`
- Use strict error handling: `set -euo pipefail`
- Implement colour-coded logging with context tracking
- Include cleanup functions and proper trap handling
- Test scripts using BATS framework

**Code Structure Template:**
```zsh
#!/usr/bin/env zsh

# Script metadata
readonly SCRIPT_NAME="${0:t}"
readonly SCRIPT_DIR="${0:A:h}"

# Load common library
source "${SCRIPT_DIR}/lib/common.zsh"

# Main logic with proper argument parsing
```

**Implementation Approach:**
- Use common library (`scripts/lib/common.zsh`) for all shared functionality
- Eliminate code duplication through standardised functions
- Implement idempotent operations (safe to run multiple times)
- Use built-in validation tools (`brew bundle check`) over manual validation
- Create device-specific Brewfiles in `/configs/` directory
- Implement chezmoi templates for dotfile management
- Build modular setup scripts for each configuration layer

## Project Structure (Implemented)

```
macos-setupv2/
├── docs/                    # Documentation and planning
│   ├── project-plan.md
│   ├── macos-zsh-standards.md
│   ├── role-macos-specialist.md
│   ├── todo.md
│   ├── script-conflict-analysis.md
│   ├── script-execution-guidelines.md
│   ├── security-best-practices.md
│   └── troubleshooting.md
├── configs/                 # Device-specific configurations
│   ├── common/             # Base layer configurations
│   ├── macbook-pro/        # Portable development configs
│   ├── mac-studio/         # Server infrastructure configs
│   └── mac-mini/           # Lightweight development configs
├── scripts/                # Setup and utility scripts
│   ├── lib/                # Common library
│   │   └── common.zsh      # Shared functions and utilities
│   ├── setup.zsh          # Main setup orchestrator
│   ├── install-homebrew.zsh
│   ├── configure-macos.zsh
│   ├── setup-users.zsh
│   ├── detect-script-conflicts.zsh
│   └── [25+ additional scripts]
├── dotfiles/               # chezmoi source directory
└── tests/                  # BATS test files
```

## Unique Features

**Script Optimisation:** Comprehensive common library reducing code duplication by 1,437+ lines across all scripts with 47% average reduction.

**Conflict Resolution:** Automated conflict detection system with detailed analysis and resolution recommendations.

**Linux Compatibility:** Integrate https://github.com/pkill37/linuxify for Linux command compatibility on macOS.

**Claude Code Integration:** Configure MCP servers including @upstash/context7-mcp, @modelcontextprotocol/server-filesystem, @microsoft/markitdown-mcp, and others.

**Dotfile Templates:** Reference https://github.com/thushan/dotfiles and https://github.com/mathiasbynens/dotfiles for macOS-specific configurations.

**Timezone/Locale:** Australia/Adelaide timezone with Australian locale settings.

## Implementation Guidelines

**When creating setup scripts:**
- Always use the common library (`scripts/lib/common.zsh`) for shared functionality
- Follow the layered architecture approach
- Implement idempotent operations (safe to run multiple times)
- Include progress feedback and error recovery
- Validate prerequisites before proceeding
- Create device-specific entry points that call common functions
- Run `detect-script-conflicts.zsh` before executing setup scripts

**When working with Homebrew:**
- Use `brew bundle check` for validation instead of manual checks
- Maintain separate Brewfiles for each device type
- Validate all formulae/casks exist in current Homebrew repositories
- Include descriptions for why specific packages are included
- Group packages logically (development, productivity, security, etc.)

**When implementing chezmoi configurations:**
- Use templates for device-specific variations
- Encrypt sensitive configurations
- Version control all dotfile sources
- Test configurations on clean systems before deployment

## Security Considerations

- Never commit credentials or API keys to the repository
- Use 1Password CLI integration for secure credential access
- Implement proper file permissions (600 for sensitive files)
- Enable FileVault encryption as part of base setup
- Configure firewall settings appropriate for each device type
- Use secure temporary file creation patterns from the zsh standards

## Claude AI Guidelines

- Do not generate code specifically for this system. It has to be generic for multiple models.

## Commit Guidelines

- Make commits without Claude Code signature and Claude Code author

## Current Implementation Status

The project has successfully completed all planned phases:

**Phase 1-10:** All core functionality implemented and tested
**Phase 11:** Complete script optimisation and conflict resolution system
- 8 scripts optimised reducing codebase by 1,437 lines (47% average reduction)
- Comprehensive common library eliminating 125+ duplicate functions
- Automated conflict detection and resolution system
- Extensive documentation and execution guidelines

**Key Achievements:**
- Complete macOS setup automation for all three device types
- Idempotent, safe-to-run scripts with comprehensive error handling
- Multi-user family environment support
- Security-first implementation with 1Password integration
- Comprehensive testing and documentation

## Memories

- Ensure @docs/todo.md is updated as tasks completed
- All scripts now use common library to eliminate code duplication
- Use Australian English spelling in all documentation and code
- Run conflict detection before executing setup scripts
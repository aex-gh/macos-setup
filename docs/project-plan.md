# Project Plan

## Overview
Generate a simple macOS setup process for new systems supporting multiple configurations and macOS 15.5+ using zsh, Homebrew and chezmois.

## Requirements
1. mac model specific setups (mac mini (headless workstation/media player), macbook pro (daily driver), mac studio(server)).
2. Use homebrew with Brewfiles. Validate all Brewfile and Caskfile apps exist. Essential apps include:
   - Homebrew
   - Git
   - Node.js
   - Python (using uv, ruff only)
   - Ruby
   - Vim
   - Zsh
   - OrbStack
   - 1Password
   - Jump Desktop Connect (Mac Mini and Mac Studio)
   - Jump Desktop (Macbook Pro) - MAS Install
   - Raycast
   - Karabiner Elements
   - Zed
   - iina
   - Zen browser
3. Use https://github.com/pkill37/linuxify to enable linux compatibility.
4. Use https://github.com/thushan/dotfiles and https://github.com/mathiasbynens/dotfiles as a template for dotfiles and macOS configuration.
5. Network connectivity
  - Mac mini and Mac Studio ethernet only (IP v4: 10.20.0.12, 10.20.0.10)
  - Macbook pro wifi only (IP v4: 10.20.0.11)
6. Security considerations
  - User account management
      - Primary User - Andrew Exley, andrew, admin
        - create user accounts for
          - Ali Exley, ali, standard
          - Amelia Exley, amelia, standard
          - Annabelle Exley, annabelle, standard
  - Gentle hardening of common security measures
    - Enable FileVault encryption
    - Configure firewall settings
    - Install antivirus software
    - Enable automatic security updates
7. Common macOS defaults and osascripts for users and developers (search Github and prioritise recent refreshed repos).
8. Mac Studio to provide central file server and time machine backup functionality for all users.
9. Implement a backup strategy for user data and configurations.
10. Claude Code setup and MCP servers (@upstash/context7-mcp, @alioshr/memory-bank-mcp, @modelcontextprotocol/server-filesystem, @microsoft/markitdown-mcp, @wonderwhy-er/desktop-commander-mcp, @modelcontextprotocol/server-github, AppleScript)
11. Use chezmois for managing dotfiles and configurations.
12. Timezone and location configuration Australia/Adelaide.
13. Set primary font for zed, terminal and ghostty to Maple Mono Nerd Font.
14. Set colour scheme for zed, terminal, and ghostty to Gruvbox Dark Soft Contrast theme.
15. All passwords and SSH keys are installed in 1Password.

## Documentation
### MacBook Pro (Portable Development Workstation)
**Focus:** Complete data stack, productivity tools, development environment

- **Hardware:** Optimised for 32GB M1 Pro systems
- **Software:** Full Python/SQL/data engineering stack
- **Security:** FileVault encryption, Touch ID, theft protection
- **Network:** Dynamic IP with workstation optimisations
- **Power:** Battery-optimised AC/battery profiles
- **Applications:** VMware Fusion, DataGrip, PyCharm, Jupyter, database tools, OrbStack, Claude Code, iina, LibreOffice, zed,

### Mac Studio (Headless Server)
**Focus:** Server infrastructure, virtualisation, containerisation

- **Hardware:** Optimised for M1 Max 32GB headless operation
- **Software:** Server tools, containers, monitoring, databases
- **Security:** Server hardening with external network SSH/screen sharing access from MacBook Pro only via VPN, internal network access from any device on the 10.20.0.0/24 subnet, enhanced monitoring and intrusion detection
- **Network:** Static IP (10.20.0.10), server network optimisations
- **Power:** Always-on server performance profile
- **Applications:** VMware Fusion, OrbStack, monitoring tools, security utilities

### Mac Mini (Lightweight Development + Multimedia)
**Focus:** Essential development tools, multimedia for TV/speakers

- **Hardware:** Memory-optimised for 16GB M4 systems
- **Software:** Essential dev tools, multimedia applications
- **Security:** Basic hardening with user account management
- **Network:** Static IP (10.20.0.11), multimedia optimisations
- **Power:** Always-on server performance profile
- **Applications:** Media players, basic development tools, home automation, Claude Code

## Architecture Overview

### Configuration Layers

The system uses a layered approach to configuration:

```
┌─────────────────────────────────────┐
│           User Layer                │  ← Personal dotfiles (chezmois)
├─────────────────────────────────────┤
│       Application Layer             │  ← App-specific configs
├─────────────────────────────────────┤
│        Mac Model Layer              │  ← Device-specific settings
├─────────────────────────────────────┤
│        Common Base Layer            │  ← Universal tools & defaults
└─────────────────────────────────────┘
```
### Configuration Layers

1. **Common Base Layer:** Essential tools and settings shared across all Macs
2. **Mac Model Layer:** Optimised configurations for each Mac type
3. **Application Layer:** Curated application configurations (Claude Code, Docker, etc.)
4. **User Layer:** Dotfiles and personal configurations via chezmois

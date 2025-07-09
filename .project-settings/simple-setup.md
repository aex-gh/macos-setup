# Simple MacOS Setup

## Overview
Generate the initial setup script for MacOS systems for a home network.

## Instructions
DO NOT use any information from the files anywhere in the macos-setup directory unless you are specifically instructed to do so.
DO NOT overcomplicate things. Keep it simple.
DO NOT confabulate.
DO NOT generate any unnecessary code or files unless you are specifically instructed to do so.
DO keep configuration options in YAML files.
DO keep secrets in environment variables.
DO use the role @role-macos-specialist.md to complete this.
DO call me by my name, Andrew, when you require further information or want me to do something.

## Directory structure
macos-setup/brewfiles
macos-setup/dotfiles
macos-setup/scripts
macos-setup/configs
macos-setup/modules

## Brewfiles
1. Review all brewfiles in macos-setup and consolidate into macos-setup/brewfiles in the following files, ensuring no duplicates:
   - base: modern cli replacements, updated versions of macos coreutils, raycast, etc.
   - dev: git, node, python, rust, etc.
   - productivity: libreoffice, todoist, slack, zoom, etc.
   - utilities: orbstack, kubernetes, Parallels, etc.

## Dotfiles
1. Copy packages folder into macos-setup/dotfiles.

## Scripts
DO start by reviewing script requirements below and generating configuration YAML files to provide the scripts with the configuration inputs required. Place these files in macos-setup/scripts/config.
DO follow DRY principles and create modules in macos-setup/modules (e.g. power-management, network, etc.).

1. Create a setup script per system [mac-studio, macbook-pro, mac-mini] and an all-systems script.
2. Each setup script should be named after the system it is for.
3. Each setup script should be executable.
4. Each setup script should be simple, easy to understand, idempotent and independent.
5. Each setup script should be well-documented.
6. Each setup script should be organised into sections.
7. If sudo is required, add it to the beginning of the script so it is only executed once.
8. In the all-systems script, include the following:
   - Updates: ensure that the system is up-to-date before proceeding.
   - Install: Xcode tools, Homebrew, 1Password, Karabiner Elements.
   - Remote Access: Configure remote login and SSH keys using 1Password (this should be provided by the dot-ssh/config file)
   - File Sharing: Enable SMB3 and SSH.
   - Network Discovery: Configure Bonjour and network visibility.
   - Security: Basic hardening, FileVault disk encryption, and firewall setup.
   - Time Sync: Configure NTP and timezone for Adelaide, Australia.
   - System Preferences: Review macos-setup/scripts/05-macos-defaults.zsh.
   - Telemetry: Disable telemetry and analytics.
9. Create a separate script for each system to configure specific settings, include the following:
   - System Naming: Configure hostname, localhostname and computername.
   - System Configuration: Configure system settings such as display resolution, keyboard shortcuts, dock configuration, notifications, sound effects, audio output, screensaver, Apple Intelligence, Siri, and wallpaper.
   - Network Configuration: Configure network settings. Disable Wi-Fi, Enable Ethernet and manually configure IPv4. Enable thunderbolt networking.
   - DNS Configuration: Configure DNS settings.
   - DHCP Configuration: Configure DHCP settings.
   - Security: Configure security settings such as firewall rules, user accounts, and permissions.
10. Create a separate security hardening script for use after installation and configuration.

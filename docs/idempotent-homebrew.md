# Idempotent Homebrew Management

This document provides comprehensive information about the idempotent Homebrew management system implemented in this macOS setup project.

## Overview

The idempotent Homebrew management system ensures that your macOS system packages remain in sync with your declared Brewfiles and can automatically clean up unwanted packages. This approach provides:

- **Declarative package management**: Define your desired package state in Brewfiles
- **Automatic cleanup**: Remove packages not declared in any Brewfile
- **Safety features**: Dry-run mode, backups, and confirmation prompts
- **State tracking**: Monitor package changes over time
- **Multi-system support**: Handle different system configurations

## Components

### 1. homebrew-manager.rb

The core Ruby script that provides idempotent package management functionality.

**Key Features:**
- Merge multiple Brewfiles into a single desired state
- Handle package deduplication and dependency resolution
- Support multiple package types (tap, brew, cask, mas, vscode)
- Provide comprehensive logging and error handling
- Generate detailed reports and backups

**Usage:**
```bash
# Basic operations
./scripts/homebrew-manager.rb --install --brewfiles base.brewfile,dev.brewfile
./scripts/homebrew-manager.rb --cleanup --dry-run
./scripts/homebrew-manager.rb --sync --verbose

# Advanced operations
./scripts/homebrew-manager.rb --diff --output differences.txt
./scripts/homebrew-manager.rb --backup --output backup-$(date +%Y%m%d).yaml
```

**Options:**
- `--install`: Install packages from Brewfiles
- `--cleanup`: Remove packages not in any Brewfile
- `--sync`: Install missing and remove extra packages
- `--diff`: Show differences between desired and actual state
- `--backup`: Create backup of current state
- `--dry-run`: Show what would be done without executing
- `--verbose`: Enable detailed output
- `--force`: Skip confirmation prompts
- `--brewfiles FILE1,FILE2`: Specify Brewfiles to use
- `--output FILE`: Specify output file for reports/backups

### 2. brew-cleanup-safe.zsh

Safe wrapper for cleanup operations with comprehensive safety features.

**Key Features:**
- Dry-run mode to preview changes
- Automatic backup creation before cleanup
- Confirmation prompts for destructive operations
- Rollback capability to restore previous states
- Integration with homebrew-manager.rb

**Usage:**
```bash
# Safety-first approach
./scripts/brew-cleanup-safe.zsh --dry-run
./scripts/brew-cleanup-safe.zsh --backup

# Advanced cleanup
./scripts/brew-cleanup-safe.zsh --force --verbose
./scripts/brew-cleanup-safe.zsh --rollback
```

**Options:**
- `--dry-run`: Preview changes without executing
- `--backup`: Create backup before cleanup
- `--force`: Skip confirmation prompts
- `--verbose`: Enable detailed output
- `--rollback`: Restore previous backup
- `--brewfiles FILES`: Specify Brewfiles to use

### 3. brew-state-tracker.zsh

Monitor and track package state changes over time.

**Key Features:**
- Real-time state monitoring
- Historical state tracking
- Health check functionality
- Multiple output formats (text, JSON, CSV)
- Detailed reporting capabilities

**Usage:**
```bash
# Status and monitoring
./scripts/brew-state-tracker.zsh status
./scripts/brew-state-tracker.zsh monitor --verbose

# Reporting
./scripts/brew-state-tracker.zsh diff --format json
./scripts/brew-state-tracker.zsh report --output detailed-report.txt
./scripts/brew-state-tracker.zsh health
```

**Commands:**
- `status`: Show current package state summary
- `diff`: Show detailed differences
- `health`: Perform health check
- `history`: Show state change history
- `monitor`: Continuously monitor for changes
- `report`: Generate detailed package report

### 4. install-homebrew-idempotent.zsh

Enhanced installation script with idempotent cleanup integration.

**Key Features:**
- System-specific package installation
- Integrated cleanup and state tracking
- Backup and rollback capabilities
- Comprehensive safety features
- Summary reporting

**Usage:**
```bash
# System-specific installation
./scripts/install-homebrew-idempotent.zsh --system base
./scripts/install-homebrew-idempotent.zsh --system dev --cleanup

# Full featured installation
./scripts/install-homebrew-idempotent.zsh --sync --backup --track --verbose
```

**System Types:**
- `base`: Essential tools for all systems
- `dev`: Development environment packages
- `productivity`: Office and productivity applications
- `utilities`: System utilities and specialised tools
- `all`: All available packages

## Safety Features

### 1. Dry-Run Mode

All scripts support dry-run mode to preview changes without executing:

```bash
./scripts/homebrew-manager.rb --cleanup --dry-run
./scripts/brew-cleanup-safe.zsh --dry-run
./scripts/install-homebrew-idempotent.zsh --dry-run --system all
```

### 2. Backup and Rollback

Automatic backup creation before destructive operations:

```bash
# Create backup before cleanup
./scripts/brew-cleanup-safe.zsh --backup

# Rollback to previous state
./scripts/brew-cleanup-safe.zsh --rollback

# Manual backup
./scripts/homebrew-manager.rb --backup --output manual-backup.yaml
```

### 3. Protected Packages

Essential packages are protected from removal:

- `homebrew/core`, `homebrew/cask`, `homebrew/bundle`
- `brew`, `git`, `curl`, `zsh`
- Any package explicitly marked as protected

### 4. Confirmation Prompts

Interactive confirmation for destructive operations:

```bash
# Will prompt before removing packages
./scripts/brew-cleanup-safe.zsh

# Skip prompts with --force
./scripts/brew-cleanup-safe.zsh --force
```

### 5. Comprehensive Logging

All operations are logged for audit and troubleshooting:

- Log files: `/tmp/script-name.log`
- Structured logging with timestamps
- Different log levels (ERROR, WARN, INFO, DEBUG)
- Persistent state tracking

## Workflow Examples

### Daily Package Management

```bash
# Check current state
./scripts/brew-state-tracker.zsh status

# Show what needs to be changed
./scripts/homebrew-manager.rb --diff

# Sync packages with backup
./scripts/install-homebrew-idempotent.zsh --sync --backup
```

### New System Setup

```bash
# Install base packages
./scripts/install-homebrew-idempotent.zsh --system base --track

# Add development tools
./scripts/install-homebrew-idempotent.zsh --system dev --backup

# Clean up any unwanted packages
./scripts/brew-cleanup-safe.zsh --dry-run
./scripts/brew-cleanup-safe.zsh --backup
```

### Package Cleanup

```bash
# Safe cleanup workflow
./scripts/brew-cleanup-safe.zsh --dry-run
./scripts/brew-cleanup-safe.zsh --backup
./scripts/brew-cleanup-safe.zsh

# Emergency rollback if needed
./scripts/brew-cleanup-safe.zsh --rollback
```

### State Monitoring

```bash
# Check system health
./scripts/brew-state-tracker.zsh health

# Generate detailed report
./scripts/brew-state-tracker.zsh report --output monthly-report.txt

# Monitor for changes
./scripts/brew-state-tracker.zsh monitor --verbose
```

## Advanced Configuration

### Custom Brewfiles

You can specify custom Brewfiles for specific scenarios:

```bash
# Use only specific Brewfiles
./scripts/homebrew-manager.rb --sync --brewfiles custom.brewfile,extra.brewfile

# Use system-specific Brewfiles
./scripts/install-homebrew-idempotent.zsh --brewfiles base.brewfile,dev.brewfile
```

### Output Formats

State tracker supports multiple output formats:

```bash
# JSON output
./scripts/brew-state-tracker.zsh status --format json

# CSV output for spreadsheet analysis
./scripts/brew-state-tracker.zsh status --format csv --output packages.csv
```

### Backup Management

Backups are automatically managed with rotation:

- Location: `~/.homebrew-backups/`
- Automatic rotation (keeps last 30 snapshots)
- YAML format for easy inspection
- Symlink to latest backup

## Integration with Existing Scripts

The idempotent tools integrate with your existing setup scripts:

```bash
# In your system-specific scripts
source "${SCRIPT_DIR}/install-homebrew-idempotent.zsh"
install_homebrew_idempotent --system base --cleanup

# In your maintenance scripts
source "${SCRIPT_DIR}/brew-state-tracker.zsh"
generate_report --output "/var/log/homebrew-$(date +%Y%m%d).txt"
```

## Troubleshooting

### Common Issues

1. **Permission Errors**
   - Ensure you have administrator privileges
   - Check Homebrew installation permissions

2. **Network Issues**
   - Verify internet connectivity
   - Check firewall settings

3. **Package Conflicts**
   - Review package dependencies
   - Use `--force` flag carefully

4. **State Inconsistencies**
   - Run health check: `./scripts/brew-state-tracker.zsh health`
   - Check logs in `/tmp/`

### Debug Mode

Enable verbose output for troubleshooting:

```bash
./scripts/homebrew-manager.rb --sync --verbose
./scripts/brew-cleanup-safe.zsh --verbose
./scripts/brew-state-tracker.zsh status --verbose
```

### Recovery Procedures

If something goes wrong:

1. **Check logs**: Review `/tmp/script-name.log`
2. **Restore backup**: Use `--rollback` option
3. **Manual intervention**: Use `brew doctor` and `brew cleanup`
4. **Health check**: Run `brew-state-tracker.zsh health`

## Best Practices

1. **Always use dry-run first** before making changes
2. **Create backups** before major operations
3. **Monitor state changes** regularly
4. **Review logs** for errors and warnings
5. **Test on non-production** systems first
6. **Keep Brewfiles updated** with current needs
7. **Use system types** appropriately for different machines
8. **Document custom configurations** for team use

## Performance Considerations

- Ruby script performance depends on number of packages
- State tracking uses minimal disk space
- Backups are compressed YAML files
- Monitoring mode uses polling (configurable interval)
- Network operations may be slow during initial sync

## Security Considerations

- Scripts require administrator privileges
- Backups contain package lists (not sensitive data)
- Network operations use HTTPS
- Protected packages prevent accidental removal
- Confirmation prompts prevent accidental operations

## Future Enhancements

Potential improvements for the idempotent system:

1. **Web UI**: Browser-based package management
2. **Scheduling**: Automated maintenance scheduling
3. **Notifications**: System notifications for changes
4. **Integration**: CI/CD integration for automated testing
5. **Metrics**: Performance and usage metrics
6. **Clustering**: Multi-system management capabilities

---

For more information, see the main [README.md](../README.md) and individual script documentation.
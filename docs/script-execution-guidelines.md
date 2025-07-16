# Script Execution Guidelines

## Overview

This document provides guidelines for safely executing setup scripts without conflicts. Following these guidelines ensures idempotent operation and prevents duplicate or conflicting configurations.

## Recommended Execution Order

### 1. Foundation Setup (Required First)
```bash
# Install Homebrew and basic dependencies
./scripts/install-homebrew.zsh

# Install all packages including fonts via Brewfiles
./scripts/install-packages.zsh [device-type]
```

### 2. System Configuration (Core Setup)
```bash
# Configure universal macOS defaults
./scripts/configure-macos.zsh [device-type]

# Set up basic security (FileVault, firewall)
./scripts/setup-filevault.zsh [device-type]
./scripts/setup-firewall.zsh [device-type]
```

### 3. User Management (If Needed)
```bash
# Create family user accounts (optional)
./scripts/setup-users.zsh [device-type]
```

### 4. Family Environment (If Applicable)
```bash
# Configure family-specific features
./scripts/setup-family-environment.zsh [device-type]
```

### 5. Device-Specific Features
```bash
# Configure network settings
./scripts/setup-network.zsh [device-type]

# Set up remote access (headless systems)
./scripts/setup-remote-access.zsh [device-type]

# Configure Mac Studio server features (Mac Studio only)
./scripts/setup-mac-studio-server.zsh
```

### 6. Advanced Configuration (Optional)
```bash
# Set up dotfiles and theming
./scripts/setup-dotfiles.zsh [device-type]
./scripts/setup-theme.zsh [device-type]

# Install and configure specialized tools
./scripts/install-claude-code.zsh
./scripts/setup-mcp-servers.zsh
```

## Script Interaction Matrix

### ✅ Safe Combinations
- `install-homebrew.zsh` → `install-packages.zsh` → Any other script
- `configure-macos.zsh` → `setup-family-environment.zsh` (no conflicts)
- `setup-users.zsh` → `setup-family-environment.zsh` (complementary)
- `setup-filevault.zsh` → `setup-firewall.zsh` → `setup-hardening.zsh`

### ⚠️ Requires Coordination
- `setup-users.zsh` AND `setup-family-environment.zsh` - Run users first
- `configure-macos.zsh` AND device-specific scripts - Some settings may override
- Font installation - Use Brewfile OR install-fonts.zsh, not both

### ❌ Conflicting Combinations
- `install-packages.zsh` + `install-fonts.zsh` - Font installation conflicts
- Multiple power management scripts simultaneously
- Running setup scripts multiple times without idempotent checks

## Device-Specific Guidelines

### MacBook Pro (Portable Development)
```bash
# Full setup sequence
./scripts/install-homebrew.zsh
./scripts/install-packages.zsh macbook-pro
./scripts/configure-macos.zsh macbook-pro
./scripts/setup-users.zsh macbook-pro          # Optional
./scripts/setup-family-environment.zsh macbook-pro
./scripts/setup-network.zsh macbook-pro
./scripts/setup-dotfiles.zsh macbook-pro
./scripts/setup-theme.zsh macbook-pro
```

### Mac Studio (Server Infrastructure)
```bash
# Server-focused setup
./scripts/install-homebrew.zsh
./scripts/install-packages.zsh mac-studio
./scripts/configure-macos.zsh mac-studio
./scripts/setup-users.zsh mac-studio           # Required for server
./scripts/setup-family-environment.zsh mac-studio
./scripts/setup-network.zsh mac-studio
./scripts/setup-remote-access.zsh mac-studio
./scripts/setup-mac-studio-server.zsh
```

### Mac Mini (Lightweight Development + Multimedia)
```bash
# Balanced setup
./scripts/install-homebrew.zsh
./scripts/install-packages.zsh mac-mini
./scripts/configure-macos.zsh mac-mini
./scripts/setup-users.zsh mac-mini             # Optional
./scripts/setup-family-environment.zsh mac-mini
./scripts/setup-network.zsh mac-mini
./scripts/setup-dotfiles.zsh mac-mini
./scripts/setup-theme.zsh mac-mini
```

## Conflict Prevention

### Font Installation
- **Recommended:** Use Brewfile installation (via `install-packages.zsh`)
- **Alternative:** Use `install-fonts.zsh` only if fonts not in Brewfile
- **Never:** Run both Brewfile and manual font installation

### User Management
- **Recommended:** Run `setup-users.zsh` first, then `setup-family-environment.zsh`
- **Alternative:** Run only `setup-family-environment.zsh` if users already exist
- **Never:** Run user creation scripts simultaneously

### System Configuration
- **Recommended:** Run `configure-macos.zsh` first for universal settings
- **Then:** Run device-specific scripts for specialized configuration
- **Check:** Use `detect-script-conflicts.zsh` to identify issues

## Validation and Testing

### Before Running Scripts
```bash
# Check for conflicts
./scripts/detect-script-conflicts.zsh

# Validate Brewfiles
./scripts/validate-brewfiles.zsh

# Verify system requirements
./scripts/validate-setup.zsh
```

### After Running Scripts
```bash
# Verify installation
./scripts/validate-setup.zsh

# Check for remaining conflicts
./scripts/detect-script-conflicts.zsh

# Run tests
./scripts/run-tests.zsh
```

## Error Recovery

### If Script Fails
1. **Check prerequisites** - Ensure previous steps completed
2. **Review logs** - Check for error messages and warnings
3. **Resolve conflicts** - Use conflict detection tool
4. **Retry safely** - Scripts should be idempotent

### If Conflicts Occur
1. **Stop execution** - Do not continue with conflicting scripts
2. **Analyze conflicts** - Review `script-conflict-analysis.md`
3. **Resolve manually** - Edit configurations as needed
4. **Test resolution** - Use conflict detection tool

## Best Practices

### Script Selection
- **Minimal setup:** Run only essential scripts
- **Full setup:** Follow complete execution order
- **Custom setup:** Pick scripts based on requirements

### Monitoring
- **Watch output** - Monitor for warnings and errors
- **Check logs** - Review script execution logs
- **Verify results** - Test that configurations work as expected

### Maintenance
- **Regular updates** - Keep scripts and dependencies current
- **Conflict checks** - Run detection tool after changes
- **Documentation** - Update guidelines as scripts evolve

## Troubleshooting

### Common Issues
1. **Font installation failures** - Check Homebrew tap and connectivity
2. **User creation errors** - Verify admin privileges and unique usernames
3. **System setting conflicts** - Review defaults write commands
4. **Permission issues** - Check file/directory permissions

### Recovery Steps
1. **Backup first** - Time Machine or manual backup
2. **Identify issue** - Use conflict detection and validation tools
3. **Fix incrementally** - Resolve one issue at a time
4. **Test thoroughly** - Verify fix before continuing

## Updates and Maintenance

### When Scripts Change
1. **Review changes** - Check git diff for modifications
2. **Update guidelines** - Modify execution order if needed
3. **Test combinations** - Verify no new conflicts introduced
4. **Update documentation** - Keep guidelines current

### Regular Maintenance
- **Monthly:** Run conflict detection tool
- **Quarterly:** Review and update script execution order
- **Annually:** Full review of script interactions and guidelines

---

*Generated during Phase 10: Script Conflict Resolution*  
*Last updated: $(date '+%Y-%m-%d %H:%M:%S')*
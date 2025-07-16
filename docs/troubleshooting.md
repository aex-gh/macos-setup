# Troubleshooting Guide

This guide covers common issues and solutions for the macOS setup automation project.

## Table of Contents

- [Prerequisites Issues](#prerequisites-issues)
- [Homebrew Problems](#homebrew-problems)
- [Git and Repository Issues](#git-and-repository-issues)
- [1Password Integration Issues](#1password-integration-issues)
- [Device Detection Problems](#device-detection-problems)
- [Dotfiles and Chezmoi Issues](#dotfiles-and-chezmoi-issues)
- [Security and Permissions](#security-and-permissions)
- [Network Configuration Issues](#network-configuration-issues)
- [Theme and Font Problems](#theme-and-font-problems)
- [Claude Code and MCP Issues](#claude-code-and-mcp-issues)
- [Testing and Validation Issues](#testing-and-validation-issues)
- [Performance Problems](#performance-problems)

## Prerequisites Issues

### Command Line Tools Not Installed

**Problem**: Scripts fail with "xcrun: error: invalid active developer path"

**Solution**:
```bash
# Install Xcode Command Line Tools
xcode-select --install

# Verify installation
xcode-select -p
```

**Verification**:
```bash
# Check that basic tools are available
which git
which make
which clang
```

### Rosetta 2 Missing (Apple Silicon Macs)

**Problem**: Some Intel-based applications fail to run

**Solution**:
```bash
# Install Rosetta 2
sudo softwareupdate --install-rosetta
```

### macOS Version Compatibility

**Problem**: Scripts fail on older macOS versions

**Solution**:
- Ensure you're running macOS 12.0 (Monterey) or later
- Update macOS: System Settings → General → Software Update
- Check version: `sw_vers -productVersion`

## Homebrew Problems

### Homebrew Installation Fails

**Problem**: Homebrew installation script hangs or fails

**Solutions**:
```bash
# Manual installation
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Alternative installation method
curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | bash

# Check network connectivity
curl -I https://brew.sh
```

### PATH Issues with Homebrew

**Problem**: `brew` command not found after installation

**Solutions**:
```bash
# Add Homebrew to PATH manually
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
source ~/.zshrc

# For Intel Macs
echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zshrc

# Verify PATH
echo $PATH | grep brew
```

### Homebrew Package Installation Fails

**Problem**: Individual packages fail to install

**Diagnostics**:
```bash
# Update Homebrew
brew update

# Check for issues
brew doctor

# Check specific package
brew info <package-name>

# Install with verbose output
brew install -v <package-name>
```

**Common Solutions**:
- Clear cache: `brew cleanup --prune=all`
- Reset Homebrew: `brew reset`
- Check disk space: `df -h`
- Update macOS if package requires newer version

### Brewfile Validation Errors

**Problem**: Brewfile contains invalid packages

**Solution**:
```bash
# Validate specific Brewfile
./scripts/validate-brewfiles.zsh path/to/Brewfile

# Check if package exists
brew search <package-name>

# Update Brewfile with correct package names
```

## Git and Repository Issues

### Git Configuration Errors

**Problem**: Git operations fail due to missing configuration

**Solution**:
```bash
# Set basic Git configuration
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Verify configuration
git config --list
```

### SSH Key Issues

**Problem**: Git operations fail with authentication errors

**Solutions**:
```bash
# Generate new SSH key
ssh-keygen -t ed25519 -C "your.email@example.com"

# Add to ssh-agent
ssh-add ~/.ssh/id_ed25519

# Test GitHub connection
ssh -T git@github.com

# Alternative: Use HTTPS instead
git remote set-url origin https://github.com/username/repo.git
```

### Repository Clone Failures

**Problem**: Cannot clone dotfiles repository

**Solutions**:
- Check network connectivity
- Verify repository URL and permissions
- Use HTTPS instead of SSH if behind corporate firewall
- Check if repository is private and requires authentication

## 1Password Integration Issues

### 1Password CLI Not Found

**Problem**: `op` command not available

**Solutions**:
```bash
# Install via Homebrew
brew install 1password-cli

# Verify installation
op --version

# Sign in to 1Password
op signin
```

### 1Password Authentication Fails

**Problem**: Cannot retrieve secrets from 1Password

**Diagnostics**:
```bash
# Check if signed in
op account list

# Test secret retrieval
op read "op://Personal/test-item/password"
```

**Solutions**:
```bash
# Sign in again
op signin --account your-account

# Check item exists
op item list | grep "item-name"

# Verify vault access
op vault list
```

### 1Password Desktop Integration

**Problem**: CLI integration with 1Password app not working

**Solutions**:
1. Open 1Password app
2. Go to Settings → Developer
3. Enable "Integrate with 1Password CLI"
4. Restart terminal and try again

## Device Detection Problems

### Unknown Device Type

**Problem**: Setup script cannot determine device type

**Diagnostics**:
```bash
# Check hostname
hostname

# Check system profiler
system_profiler SPHardwareDataType | grep "Model Name"

# Manual override
./scripts/setup.zsh --device macbook-pro
```

**Solutions**:
- Ensure hostname follows expected pattern
- Use manual device specification
- Update device detection logic if needed

### Incorrect Device Configuration

**Problem**: Wrong device type detected

**Solution**:
```bash
# Override device detection
export DEVICE_TYPE="mac-studio"
./scripts/setup.zsh

# Or use command line flag
./scripts/setup.zsh --device mac-mini
```

## Dotfiles and Chezmoi Issues

### Chezmoi Installation Problems

**Problem**: Chezmoi not installed or not working

**Solutions**:
```bash
# Install chezmoi
brew install chezmoi

# Initialize chezmoi
chezmoi init

# Check chezmoi status
chezmoi doctor
```

### Dotfiles Application Fails

**Problem**: Chezmoi cannot apply dotfiles

**Diagnostics**:
```bash
# Check what would change
chezmoi diff

# Dry run application
chezmoi apply --dry-run

# Verbose output
chezmoi apply -v
```

**Solutions**:
- Check file permissions
- Resolve conflicts manually
- Reset chezmoi: `chezmoi reset`

### Template Execution Errors

**Problem**: Chezmoi templates fail to execute

**Solutions**:
```bash
# Check template syntax
chezmoi execute-template < template-file

# Verify template data
chezmoi data

# Fix template syntax errors
```

### Encryption Issues

**Problem**: Encrypted files cannot be decrypted

**Solutions**:
```bash
# Check age installation
brew install age

# Verify age key
age-keygen -y ~/.age/key.txt

# Re-run encryption setup
./dotfiles/scripts/setup-encryption.zsh
```

## Security and Permissions

### FileVault Setup Fails

**Problem**: Cannot enable FileVault

**Prerequisites**:
- Admin user account
- User logged in locally (not via SSH)
- Secure boot enabled

**Solutions**:
```bash
# Check current status
sudo fdesetup status

# Enable FileVault (requires GUI)
sudo fdesetup enable

# Check requirements
sudo fdesetup isactive
```

### Firewall Configuration Issues

**Problem**: Firewall rules not applying

**Solutions**:
```bash
# Check firewall status
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate

# Enable firewall
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on

# Reset firewall if needed
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setdefaults
```

### Permission Denied Errors

**Problem**: Scripts fail with permission errors

**Solutions**:
```bash
# Make scripts executable
chmod +x scripts/*.zsh

# Check file ownership
ls -la scripts/

# Fix ownership if needed
sudo chown -R $(whoami) scripts/
```

### Keychain Access Issues

**Problem**: Cannot access keychain items

**Solutions**:
```bash
# Unlock keychain
security unlock-keychain

# List keychains
security list-keychains

# Reset keychain if corrupted
security delete-keychain login.keychain
security create-keychain login.keychain
```

## Network Configuration Issues

### Static IP Configuration Fails

**Problem**: Cannot set static IP address

**Prerequisites**:
- Admin privileges
- Correct network interface name
- Valid IP range

**Solutions**:
```bash
# Check network interfaces
networksetup -listallnetworkservices

# Get current IP configuration
networksetup -getinfo "Wi-Fi"

# Manual static IP setup
sudo networksetup -setmanual "Ethernet" 10.20.0.10 255.255.255.0 10.20.0.1
```

### DNS Resolution Problems

**Problem**: DNS not working after network changes

**Solutions**:
```bash
# Flush DNS cache
sudo dscacheutil -flushcache

# Check DNS servers
networksetup -getdnsservers "Wi-Fi"

# Set DNS servers
sudo networksetup -setdnsservers "Wi-Fi" 8.8.8.8 8.8.4.4
```

### Network Service Order Issues

**Problem**: Wrong network interface priority

**Solutions**:
```bash
# Check service order
networksetup -listnetworkserviceorder

# Set service order
sudo networksetup -ordernetworkservices "Ethernet" "Wi-Fi"
```

## Theme and Font Problems

### Font Installation Fails

**Problem**: Fonts don't install or aren't recognized

**Solutions**:
```bash
# Check font directory permissions
ls -la ~/Library/Fonts

# Clear font cache
sudo atsutil databases -remove
atsutil server -shutdown
atsutil server -ping

# Verify font installation
system_profiler SPFontsDataType | grep "Maple Mono"
```

### Theme Not Applied

**Problem**: Gruvbox theme not working in applications

**Solutions**:
1. Restart affected applications
2. Check application-specific theme settings
3. Log out and back in for system-wide changes
4. Manually configure theme in applications

### Terminal Theme Issues

**Problem**: Terminal doesn't use new theme

**Solutions**:
```bash
# Kill Terminal to reload settings
killall Terminal

# Import Terminal profile manually
# Terminal → Preferences → Profiles → Import

# Set default profile
defaults write com.apple.Terminal "Default Window Settings" "Gruvbox Maple Mono"
```

## Claude Code and MCP Issues

### Claude Code Installation Fails

**Problem**: Cannot install Claude Code

**Prerequisites**:
- Node.js 18+ installed
- npm available
- Network access

**Solutions**:
```bash
# Check Node.js version
node --version

# Update npm
npm install -g npm@latest

# Manual installation
curl -L -o claude-code https://github.com/anthropics/claude-code/releases/latest/download/claude-code-macos-arm64
chmod +x claude-code
mv claude-code ~/.local/bin/
```

### MCP Server Configuration Issues

**Problem**: MCP servers not working

**Diagnostics**:
```bash
# Test MCP manager
mcp-manager list

# Check MCP configuration
cat ~/.config/mcp/config.json | jq .

# Test individual server
mcp-manager test filesystem
```

**Solutions**:
- Verify npm packages are installed
- Check configuration file syntax
- Restart Claude Code
- Re-run MCP setup script

### API Key Issues

**Problem**: Claude Code cannot authenticate

**Solutions**:
```bash
# Check API key in configuration
cat ~/.config/claude-code/config.json | jq .apiKey

# Set API key manually
# Edit ~/.config/claude-code/config.json

# Test with 1Password integration
op read "op://Personal/Anthropic-API-Key/credential"
```

## Testing and Validation Issues

### BATS Tests Fail

**Problem**: Test suite reports failures

**Solutions**:
```bash
# Install BATS
brew install bats-core

# Run tests with verbose output
./scripts/run-tests.zsh --verbose

# Run specific test suite
bats tests/test_setup_main.bats

# Check test helper
source tests/test_helper.bash
```

### Mock Command Issues

**Problem**: Tests fail due to mock setup

**Solutions**:
- Check PATH in test environment
- Verify mock commands are executable
- Review test helper functions
- Run tests with debugging output

## Performance Problems

### Slow Script Execution

**Problem**: Setup scripts take too long

**Diagnostics**:
```bash
# Profile script execution
time ./scripts/setup.zsh --dry-run

# Check system resources
top -l 1 | head -20
df -h
```

**Solutions**:
- Run scripts with `--dry-run` first
- Check available disk space
- Close unnecessary applications
- Run during low system usage

### Network Timeouts

**Problem**: Downloads fail or timeout

**Solutions**:
```bash
# Test network connectivity
ping -c 3 github.com

# Use alternative mirrors if available
# Configure longer timeouts in scripts

# Check proxy settings if behind corporate firewall
echo $http_proxy
echo $https_proxy
```

## Getting Help

### Diagnostic Information

When reporting issues, include:

```bash
# System information
sw_vers
uname -a
hostname

# Setup environment
echo $PATH
which brew git zsh

# Current setup state
./scripts/validate-setup.zsh --verbose
```

### Log Files

Check these locations for detailed logs:
- `/tmp/setup-*.log` - Setup script logs
- `/tmp/system-maintenance.log` - Maintenance logs
- `~/Library/Logs/` - Application-specific logs
- Console.app - System logs

### Common Patterns

Many issues follow these patterns:
1. **Missing dependencies** - Install required tools
2. **Permission errors** - Check sudo/admin access
3. **Network issues** - Verify connectivity and proxies
4. **Path problems** - Source shell configuration
5. **Stale state** - Clear caches and restart services

### Reset Procedures

If all else fails, try these reset procedures:

```bash
# Reset Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Reset chezmoi
chezmoi purge
rm -rf ~/.local/share/chezmoi
./scripts/setup-dotfiles.zsh

# Reset shell configuration
mv ~/.zshrc ~/.zshrc.backup
source ~/.zshrc

# Reset 1Password CLI
op signout
op signin
```

## Prevention

To avoid common issues:
1. **Read documentation** before running scripts
2. **Run with --dry-run** first to preview changes
3. **Keep backups** of important configurations
4. **Test on clean systems** before deploying
5. **Monitor system resources** during setup
6. **Use version control** for custom configurations

## Emergency Recovery

If the system becomes unusable:
1. **Boot into Recovery Mode** (⌘+R during startup)
2. **Use Time Machine** to restore from backup
3. **Reinstall macOS** if necessary
4. **Restore from automated backups** created by setup scripts

For critical issues, contact the project maintainer with detailed diagnostic information.
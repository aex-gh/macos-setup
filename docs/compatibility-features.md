# macOS Linux Compatibility Features

This document outlines the Linux compatibility features implemented in the macOS setup automation project, including limitations and usage guidelines.

## Overview

The macOS setup includes integration with [linuxify](https://github.com/pkill37/linuxify) to provide Linux-compatible command aliases and functions on macOS. This helps developers who work across both Linux and macOS environments maintain consistent workflows.

## Installed Components

### Linuxify Integration
- **Source**: https://github.com/pkill37/linuxify
- **Installation Path**: `~/.local/share/linuxify`
- **Configuration**: `~/.config/linuxify/config.zsh`
- **Test Utility**: `test-linuxify` command

### GNU Tools (via Homebrew)
- `coreutils` - GNU core utilities (ls, cat, chmod, etc.)
- `findutils` - GNU find, locate, updatedb, xargs
- `gnu-sed` - GNU stream editor
- `gnu-tar` - GNU tar archiver
- `gawk` - GNU awk text processor
- `grep` - GNU grep pattern matcher
- `gnu-getopt` - GNU getopt argument parser
- `gnu-time` - GNU time command

## Command Compatibility

### Package Management
| Linux Command | macOS Equivalent | Notes |
|---------------|------------------|-------|
| `apt` | `brew` | Homebrew package manager |
| `apt-get` | `brew` | Alias to Homebrew |
| `apt-cache search` | `brew search` | Package search |
| `yum` | `brew` | Alias for RHEL users |
| `dnf` | `brew` | Alias for Fedora users |
| `pacman` | `brew` | Alias for Arch users |

### File System Operations
| Linux Command | macOS Implementation | Compatibility |
|---------------|---------------------|---------------|
| `ls` | `eza` (if installed) or native `ls` | ✅ Full |
| `ll` | `eza -l` or `ls -la` | ✅ Full |
| `la` | `eza -la` or `ls -la` | ✅ Full |
| `cat` | `bat` (if installed) or native `cat` | ✅ Full |
| `grep` | `rg` (ripgrep) or GNU grep | ✅ Full |
| `find` | `fd` (if installed) or GNU find | ✅ Full |

### System Information
| Linux Command | macOS Implementation | Compatibility |
|---------------|---------------------|---------------|
| `uname` | Custom function + native `uname` | ✅ Full |
| `lsb_release` | Custom function using `sw_vers` | ⚠️ Partial |
| `uptime` | Custom function using `sysctl` | ✅ Full |
| `free` | Custom function using `vm_stat` | ⚠️ Partial |
| `lscpu` | `sysctl machdep.cpu.brand_string` | ⚠️ Limited |
| `lsblk` | `diskutil list` | ⚠️ Different format |
| `lsusb` | `system_profiler SPUSBDataType` | ⚠️ Different format |
| `lspci` | `system_profiler SPPCIDataType` | ⚠️ Different format |

### Process Management
| Linux Command | macOS Implementation | Compatibility |
|---------------|---------------------|---------------|
| `ps` | `ps aux` | ✅ Full |
| `top` | `htop` (if installed) or native `top` | ✅ Full |
| `systemctl` | `launchctl` | ⚠️ Different syntax |
| `service` | `launchctl` | ⚠️ Different syntax |
| `journalctl` | `log show` | ⚠️ Different options |

### Network Commands
| Linux Command | macOS Implementation | Compatibility |
|---------------|---------------------|---------------|
| `netstat` | `lsof -i` | ⚠️ Different output |
| `ss` | `lsof -i` | ⚠️ Different output |
| `ifconfig` | Native `ifconfig` | ✅ Full |

## Limitations and Differences

### Known Limitations

1. **System Service Management**
   - Linux `systemctl` vs macOS `launchctl` have different syntax
   - Service names and paths differ between systems
   - No direct equivalent to `systemd` units

2. **Package Management**
   - Homebrew package names may differ from Linux repositories
   - No equivalent to Linux distribution-specific packages
   - Different dependency resolution mechanisms

3. **System Information**
   - Hardware enumeration tools provide different output formats
   - Process information may include different fields
   - Memory reporting uses different units and terminology

4. **File System**
   - Case sensitivity differences (HFS+ vs ext4)
   - Different extended attributes and permissions
   - No equivalent to Linux `/proc` filesystem

5. **Log Management**
   - macOS unified logging vs Linux syslog
   - Different log file locations and formats
   - Limited `journalctl` compatibility

### Partial Compatibility

Some commands provide similar functionality but with different options or output:

- `free` - Shows memory usage but format differs from Linux
- `lsb_release` - Provides macOS version info in Linux-like format
- `netstat`/`ss` - Network information with different field names
- System profiler commands - Hardware info but different structure

## Usage Guidelines

### Testing Compatibility
Run the compatibility test to verify which commands are available:
```bash
test-linuxify
```

### Recommended Workflow
1. Use compatible commands where possible for cross-platform scripts
2. Test scripts on both Linux and macOS if targeting both platforms
3. Use modern CLI tools (eza, bat, rg) for better consistency
4. Wrap platform-specific commands in functions when needed

### Configuration
The linuxify configuration is automatically loaded in new shell sessions. To manually load:
```bash
source ~/.config/linuxify/config.zsh
```

## Modern CLI Tool Replacements

The setup includes modern Rust-based CLI tools that provide consistent interfaces across platforms:

| Traditional | Modern Replacement | Benefits |
|-------------|-------------------|----------|
| `ls` | `eza` | Colours, icons, git integration |
| `cat` | `bat` | Syntax highlighting, line numbers |
| `grep` | `ripgrep` (`rg`) | Faster, better defaults |
| `find` | `fd` | Simpler syntax, faster |
| `du` | `dust` | Visual output, faster |
| `top` | `htop`/`bottom` | Better interface |

## Troubleshooting

### Common Issues

1. **Command not found after installation**
   - Restart shell session or run `source ~/.zshrc`
   - Check PATH includes `~/.local/bin`

2. **GNU tools not working**
   - Verify Homebrew installation: `brew list coreutils`
   - Check tool priority in PATH

3. **Aliases not working**
   - Verify linuxify config is loaded: `which ll`
   - Check for conflicting aliases in shell config

### Manual Configuration
If automatic setup fails, manually add to `~/.zshrc`:
```bash
# Linux command compatibility
source "${HOME}/.config/linuxify/config.zsh"
```

## Integration with Other Tools

### Git Configuration
The setup configures Git with Linux-compatible settings:
- UNIX line endings (`core.autocrlf = input`)
- Australian locale for commit messages
- 1Password SSH signing integration

### Development Environment
Linux compatibility is integrated with:
- Zsh configuration and aliases
- Modern CLI tools (eza, bat, rg, fd)
- Homebrew package management
- Python/Node.js development tools

## Security Considerations

- GNU tools are installed via Homebrew (trusted source)
- No system-level modifications required
- User-space configuration only
- Scripts include safety checks and error handling

## Future Enhancements

Potential improvements for Linux compatibility:
- Container-based Linux environment (Docker/Podman)
- More comprehensive `systemctl` emulation
- Additional GNU tool aliases
- Cross-platform development scripts
- Integration with Linux VMs (Parallels/VMware)

## Resources

- [Linuxify Project](https://github.com/pkill37/linuxify)
- [GNU Coreutils](https://www.gnu.org/software/coreutils/)
- [Homebrew](https://brew.sh/)
- [Modern CLI Tools in Rust](https://github.com/ibraheemdev/modern-unix)

For issues or suggestions, refer to the project documentation or create an issue in the setup repository.
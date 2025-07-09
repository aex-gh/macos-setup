# Application Configuration Files

This directory contains configuration files for various applications that require specific setup outside of dotfiles.

## Docker

### docker-daemon.json
Docker daemon configuration with:
- BuildKit enabled for improved build performance
- Automatic garbage collection (20GB storage limit)
- Log rotation (3 files, 10MB each)
- Custom DNS servers

Installation:
```bash
# For Docker Desktop on macOS
cp docker-daemon.json ~/.docker/daemon.json

# Restart Docker Desktop from menu bar
```

## Adding New Application Configs

1. Create configuration file with descriptive name
2. Include comments explaining non-obvious settings
3. Document installation location and method
4. Add any prerequisites or dependencies
# Configuration Templates

This directory contains template files that can be copied and customised for various use cases.

## Files

### backup-exclude.txt
Time Machine exclusion list for development environments. Contains paths to exclude from backups including:
- Cache directories
- Build artifacts
- Virtual environments
- Large temporary files
- Cloud storage (already backed up elsewhere)

Usage:
```bash
# Add individual exclusions
sudo tmutil addexclusion -p ~/Library/Caches

# Or configure through Time Machine preferences
```

### ssh_config.template
SSH client configuration template with:
- Security best practices
- Connection multiplexing for performance
- Host-specific configurations
- Jump host examples
- GitHub/GitLab configurations

Usage:
```bash
# Create SSH directory if needed
mkdir -p ~/.ssh/sockets

# Copy and customise
cp ssh_config.template ~/.ssh/config
chmod 600 ~/.ssh/config

# Generate SSH keys
ssh-keygen -t ed25519 -f ~/.ssh/github_ed25519 -C "your-email@example.com"
```

## Creating New Templates

1. Use `.template` extension for clarity
2. Include comprehensive comments
3. Use placeholder values that are obvious to replace
4. Document security implications
5. Provide usage examples in this README
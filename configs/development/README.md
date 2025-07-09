# Development Environment Configurations

This directory contains configuration files and templates for development environments and tools.

## VS Code

### vscode-workspace.code-workspace
A comprehensive VS Code workspace configuration for macOS development including:
- Recommended extensions for Python, Shell, YAML, and Markdown
- Format-on-save settings
- Language-specific formatting rules
- File exclusions for cleaner workspace
- Terminal configuration
- Launch configurations for debugging

Usage:
```bash
# Open workspace in VS Code
code configs/development/vscode-workspace.code-workspace
```

## Python Project Templates

### pyproject.toml.template
Modern Python project configuration template with:
- Project metadata structure
- Development and documentation dependencies
- Ruff configuration for linting and formatting
- MyPy settings for type checking
- Pytest configuration with coverage
- Build system configuration using Hatchling

Usage:
```bash
# Copy to new Python project
cp configs/development/pyproject.toml.template ~/my-project/pyproject.toml
# Edit to customise project details
```

## Adding New Development Configs

1. Use `.template` extension for files meant to be copied and modified
2. Include comprehensive comments explaining options
3. Provide sensible defaults that work out of the box
4. Document any required customisations
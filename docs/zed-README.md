# Zed Editor Configuration

This package contains enhanced Zed editor configuration optimised for macOS development, particularly shell scripting and system administration. Part of the comprehensive macOS setup system with integrated dotfiles management.

## Features

### Core Enhancements
- **Shell Script Support**: Full language server support for Bash and Zsh
- **Code Formatting**: Automatic formatting with `shfmt` for shell scripts
- **Python Development**: Enhanced Python support with Ruff and Pyright
- **macOS File Support**: Proper handling of plist, system configs, and YAML files
- **Security**: Disabled inline completions for sensitive files
- **Productivity**: Optimised file exclusions and search settings

### Key Improvements Over Base Config
1. **Language Support**:
   - Bash/Zsh language server with explainshell integration
   - Prettier formatting for JSON, YAML, and Markdown
   - XML support for plist files
   - Enhanced Python tooling

2. **File Type Associations**:
   - `.zsh` files properly recognised as Zsh scripts
   - `.plist` files as XML
   - `Brewfile` and `Pipfile` as TOML
   - `CLAUDE.md` as Markdown

3. **Security Features**:
   - Inline completions disabled for sensitive files
   - Telemetry disabled
   - Private value redaction enabled

4. **Performance**:
   - Extensive file exclusions for faster search
   - Optimised Python cache exclusions
   - macOS-specific cache and log exclusions

## Installation

### Automatic Installation (Recommended)
The Zed configuration is automatically installed when you run the main setup script:
```bash
./scripts/macos-setup.zsh
```

### Manual Installation
1. **Install required tools**:
   ```bash
   brew install shfmt shellcheck
   npm install -g bash-language-server prettier
   ```

2. **Stow the package from project directory**:
   ```bash
   cd /Users/andrew/projects/personal/macos-setup
   stow -d dotfiles zed
   ```

3. **Restart Zed** to apply the new configuration

## Recommended Extensions

The configuration includes these recommended extensions:
- `bash-language-server` - Shell script language support
- `shellcheck` - Shell script linting
- `shfmt` - Shell script formatting
- `prettier` - Code formatting
- `pyright` - Python language server
- `ruff` - Python linting and formatting
- `json-language-server` - JSON support
- `yaml-language-server` - YAML support
- `xml-language-server` - XML/plist support
- `dockerfile-language-server` - Docker support
- `markdownlint` - Markdown linting

## Key Shortcuts

Shell script specific shortcuts:
- `space s c` - Toggle line numbers
- `space s f` - Format document
- `space s e` - Go to diagnostic

## Configuration Files

- `dot-config/zed/settings.json` - Main Zed configuration
- `dot-config/zed/keymap.json` - Keyboard shortcuts
- `dot-config/zed/extensions.json` - Extension management

## Dotfiles Structure

This package follows the GNU Stow dotfiles convention:
```
dotfiles/zed/
├── dot-config/
│   └── zed/
│       ├── settings.json    → ~/.config/zed/settings.json
│       ├── keymap.json      → ~/.config/zed/keymap.json
│       └── extensions.json  → ~/.config/zed/extensions.json
└── README.md
```

## Customisation

To customise the configuration:

1. **Edit settings**: Modify `dot-config/zed/settings.json` for editor preferences
2. **Add shortcuts**: Update `dot-config/zed/keymap.json` for custom key bindings
3. **Manage extensions**: Edit `dot-config/zed/extensions.json` for extension preferences
4. **Restow**: Run `stow -R -d dotfiles zed` to apply changes

## Troubleshooting

If shell script language server isn't working:
1. Ensure `bash-language-server` is installed: `npm install -g bash-language-server`
2. Check that `shellcheck` is available: `which shellcheck`
3. Verify `shfmt` is installed: `which shfmt`

## Integration with Existing Setup

This configuration builds on the excellent [jellydn/zed-101-setup](https://github.com/jellydn/zed-101-setup) while adding:
- Better shell script support
- Enhanced Python development
- macOS-specific optimisations
- Security improvements
- Performance enhancements

## Project Integration

This zed package integrates with the macos-setup project's dotfiles management system:
- **Location**: `/Users/andrew/projects/personal/macos-setup/dotfiles/zed/`
- **Management**: Automatically managed via GNU Stow by `macos-setup.zsh`
- **Consistency**: Follows the same naming conventions as other dotfiles packages
- **Integration**: Works alongside claude, git, homebrew, karabiner, macos, ssh, and zsh packages
- **Configuration**: Enhanced for macOS development workflows

## Automatic Setup

When you run the main setup script (`macos-setup.zsh`), the Zed configuration is automatically:
1. Installed via GNU Stow
2. Configured with optimal settings for macOS development
3. Integrated with shell script development tools
4. Set up with security and performance optimisations

## Development Workflow Integration

This configuration is optimised for the macOS setup project's development workflow:
- **Shell Scripts**: Enhanced support for `.zsh` files and Homebrew scripts
- **Configuration Files**: Proper handling of YAML, JSON, and plist files
- **Security**: Disabled inline completions for sensitive files
- **Performance**: Optimised file exclusions for faster search
- **Integration**: Works seamlessly with the project's coding standards
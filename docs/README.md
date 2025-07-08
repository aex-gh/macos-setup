# macOS Dotfiles & Setup Automation

A comprehensive, modular macOS setup system with hardware detection, multiple user profiles, and automated configuration management.

## 🎯 Overview

This dotfiles repository provides an intelligent, automated macOS setup system that:

- **Hardware-aware setup**: Automatically detects your Mac model (MacBook Pro, Mac Studio, Mac Mini) and applies appropriate configurations
- **Profile-based installation**: Choose from developer, data scientist, personal, or minimal setups
- **Modular architecture**: Each setup component is a separate, testable module
- **Comprehensive automation**: From system preferences to application installation and shell configuration
- **Multiple machine support**: Optimised configurations for different hardware setups

## 🚀 Quick Start

### One-Line Installation

```bash
curl -fsSL https://raw.githubusercontent.com/aex-gh/macos-setup/main/install.sh | bash
```

### Manual Installation

```bash
git clone https://github.com/aex-gh/macos-setup.git ~/.dotfiles
cd ~/.dotfiles
./bootstrap/scripts/00-bootstrap.zsh
```

## 📁 Repository Structure

```
macos-setup/
├── bootstrap/               # Initial macOS setup (run once)
│   ├── scripts/             # Setup modules (numbered for execution order)
│   │   ├── 00-bootstrap.zsh # Main orchestration script
│   │   ├── 01-system-detection.zsh
│   │   ├── 02-xcode-tools.zsh
│   │   ├── 03-homebrew-setup.zsh
│   │   ├── 04-system-setup.zsh
│   │   ├── 05-macos-defaults.zsh
│   │   ├── 06-applications.zsh
│   │   ├── 07-security-hardening.zsh
│   │   ├── 08-development-env.zsh
│   │   ├── 09-post-setup.zsh
│   │   ├── 10-power-remote-access.zsh  # Power management & remote access
│   │   ├── validate-dry-run.zsh        # Dry-run validation script
│   │   ├── lib/                        # Utility libraries
│   │   │   └── dry-run-utils.zsh       # Dry-run testing utilities
│   │   └── modules/                    # Modular components
│   │       ├── network-shares.zsh      # Network sharing setup
│   │       ├── power-management.zsh    # Power management settings
│   │       ├── remote-access.zsh       # Remote access configuration
│   │       └── system-health.zsh       # System health monitoring
│   ├── profiles/            # User profile configurations
│   │   ├── developer.yml    # Full development environment
│   │   ├── data-scientist.yml # ML/DS focused setup
│   │   └── personal.yml     # Personal productivity setup
│   ├── config/              # Bootstrap configuration files
│   │   ├── Brewfile         # Core packages
│   │   ├── Brewfile.development
│   │   ├── Brewfile.data-science
│   │   ├── Brewfile.minimal
│   │   ├── hardware/        # Hardware-specific configs
│   │   │   ├── Brewfile.mac-mini
│   │   │   ├── Brewfile.mac-studio
│   │   │   └── Brewfile.macbook-pro
│   │   ├── karabiner/       # Karabiner configuration
│   │   │   └── karabiner-popular.json
│   │   └── machine-configs/ # Machine-specific configurations
│   │       ├── mac-mini.conf
│   │       ├── mac-studio.conf
│   │       └── macbook-pro.conf
│   └── tests/               # Testing framework
│       ├── test_dry_run.bats
│       └── test_helper.bash
├── packages/                # Stow packages (ongoing management)
│   ├── zsh/                 # Shell configuration
│   ├── git/                 # Git configuration  
│   ├── ssh/                 # SSH configuration
│   ├── karabiner/           # Keyboard customisation
│   ├── homebrew/            # Personal packages
│   ├── claude/              # Claude AI configuration
│   └── macos/               # macOS-specific configurations
├── docs/                    # Documentation
│   ├── README.md            # This file
│   ├── DRY-RUN-TESTING.md   # Dry-run testing guide
│   ├── PACKAGE_SUMMARY.md   # Package summaries
│   └── POWER-MANAGEMENT-REMOTE-ACCESS.md # Power & remote access docs
├── install.sh               # One-line installer
├── .stowrc                  # Stow configuration
├── spec.md                  # Stow specification
├── macos-zsh-standards.md   # Shell scripting standards
├── role-macos-specialist.md # macOS specialist role definition
├── DefaultKeyBinding.dict   # macOS key bindings
├── CLAUDE.MD                # Claude AI project configuration
└── CLAUDE.local.md          # Local Claude AI settings
```

## 🎨 Setup Profiles

### Developer Profile
Perfect for software engineers and full-stack developers:
- **Languages**: Python, Node.js, Go, Rust, Java
- **Tools**: VS Code, Zed, JetBrains Toolbox, OrbStack, Claude Code
- **Databases**: PostgreSQL, Redis, MongoDB
- **Cloud**: AWS, Azure, GCP CLI tools
- **DevOps**: Docker, Kubernetes, Terraform

### Data Scientist Profile
Optimised for machine learning and data analysis:
- **Languages**: Python (with ML stack), R, Julia, Scala
- **Tools**: Jupyter Lab, RStudio, Anaconda, Claude Code
- **ML Frameworks**: TensorFlow, PyTorch, scikit-learn
- **Big Data**: Apache Spark, Kafka, Airflow
- **Visualisation**: Tableau, Plotly, Seaborn
- **Security**: Enhanced data protection measures

### Personal Profile
Essential tools for personal productivity:
- **Applications**: 1Password, Rectangle, Alfred
- **Communication**: Zoom, Slack
- **Utilities**: The Unarchiver, Keka, Amphetamine
- **Basic development**: Git, VS Code, Terminal tools

### Minimal Profile
Bare essentials only:
- Core command-line tools
- Basic GUI applications
- Essential system configuration

## 🔄 Two-Phase Setup Approach

This repository uses a clear separation between initial setup and ongoing management:

### Phase 1: Bootstrap (Initial Setup)
Run once on new machines to establish the base environment:
- System detection and hardware configuration  
- Xcode Command Line Tools installation
- Homebrew installation and core packages
- System preferences and security hardening
- Essential applications and development tools

### Phase 2: Stow Packages (Ongoing Management)
Personal dotfiles managed with GNU Stow for easy updates:
- Shell configurations (`.zshrc`, `.zshenv`, `.zprofile`)
- Application-specific settings (Git, SSH, Karabiner)
- Personal preferences and customisations

```bash
# Initial setup (run once)
./bootstrap/scripts/00-bootstrap.zsh --profile developer

# Ongoing management (run as needed)
stow zsh git ssh karabiner
```

## 🖥️ Hardware-Specific Optimisations

### Mac Studio (Always-On Server)
- High-performance databases and services
- Network file sharing (AFP, SMB, NFS)
- Multiple Java versions for compatibility
- Container orchestration tools
- Performance monitoring suite

### MacBook Pro (Mobile Development)
- Battery optimisation settings
- Touch ID configuration
- Portable development tools
- Power management profiles

### Mac Mini (Compact Desktop)
- Balanced configuration
- Essential tools focus
- Optimised for limited resources

## ⚙️ Core Features

### Intelligent Hardware Detection
- Automatically identifies Mac model and capabilities
- Detects Apple Silicon vs Intel architecture
- Configures hardware-specific optimisations
- Exports hardware profile for other scripts

### Modern Shell Environment
- **Zsh** with [Zinit](https://github.com/zdharma-continuum/zinit) plugin manager
- **Pure prompt** for clean, informative display
- **Modern CLI tools**: `eza`, `bat`, `fzf`, `ripgrep`, `fd`
- **Smart aliases** with fallbacks for missing tools
- **Auto-activation** of Python virtual environments

### Python Development Excellence
- **uv** package manager for blazing-fast operations
- Multiple Python versions via pyenv
- Automatic virtual environment management
- Data science project templates
- Jupyter Lab integration

### AI-Powered Development
- **Claude Code** - Anthropic's official CLI for AI-assisted coding
- Interactive coding sessions with Claude
- Context-aware code generation and refactoring
- Integrated with your project files and codebase
- Run `claude` in any project directory to start
- **Project-specific Claude configuration** via `CLAUDE.MD` files
- **Local Claude settings** for personalised AI assistance

### Advanced macOS Integration
- **Custom key bindings** via `DefaultKeyBinding.dict`
- **Karabiner Elements** configuration for keyboard customisation
- **System-wide shortcuts** and productivity enhancements
- **Application-specific settings** and preferences
- **Dock and Finder customisations** for optimal workflow

### Comprehensive Package Management
- **Homebrew** for command-line tools
- **Homebrew Cask** for GUI applications
- **Mac App Store** integration via `mas`
- Hardware-specific package selection
- Service auto-start configuration
- Profile-specific package management

### Modular Architecture
- **Modular components** in `bootstrap/scripts/modules/`
- **Utility libraries** in `bootstrap/scripts/lib/`
- **Machine-specific configurations** in `bootstrap/config/machine-configs/`
- **Dry-run testing framework** with validation scripts
- **BATS testing suite** for automated testing

### Enhanced Power Management & Remote Access
- **Power management** optimised for different hardware types
- **Remote access** configuration (SSH, Screen Sharing, File Sharing)
- **Network shares** setup for AFP, SMB, and NFS
- **System health monitoring** with automated checks

### Testing & Validation Framework
- **Dry-run testing** with comprehensive validation scripts
- **BATS testing suite** for automated script testing
- **Utility libraries** for testing infrastructure
- **Validation tools** for setup verification
- **Machine-specific testing** across different hardware

## 🛠️ Usage Examples

### Interactive Setup
```bash
./bootstrap/scripts/00-bootstrap.zsh
# Follow prompts to select profile and modules
```

### Automated Setup (CI/CD)
```bash
./bootstrap/scripts/00-bootstrap.zsh --profile developer --force
```

### Dry Run (Preview Changes)
```bash
./bootstrap/scripts/00-bootstrap.zsh --profile data-scientist --dry-run
```

### Specific Modules Only
```bash
./bootstrap/scripts/00-bootstrap.zsh --modules-only "01,03,05"
```

### Debug Mode
```bash
./bootstrap/scripts/00-bootstrap.zsh --debug --verbose
```

### Testing & Validation
```bash
# Validate dry-run functionality
./bootstrap/scripts/validate-dry-run.zsh

# Run BATS tests
cd bootstrap/tests
bats test_dry_run.bats
```

## 🐍 Python Development Features

### UV Package Manager Integration
Modern Python package management with lightning-fast performance:

```bash
# Project management
pynew myproject        # Create new Python project with uv
ds-new datascience     # Create data science project template
vquick                 # Quick venv creation and activation

# Environment management
va                     # Activate virtual environment (auto-detect)
vd                     # Deactivate virtual environment
venv-select           # Interactive environment selection with fzf

# Package operations
uv sync               # Install all dependencies
uv add pandas         # Add new package
uvx black .           # Run tools without installing
```

### Data Science Workflow
```bash
# Create new data science project
ds-new my-analysis
cd my-analysis

# Auto-activates virtual environment
# Installs: jupyter, pandas, numpy, matplotlib, seaborn, scikit-learn

# Launch Jupyter Lab
jl                    # or jupyter lab
```

## 🔧 Shell Configuration

### Modern CLI Experience
- **File listing**: `eza` with icons and tree view
- **File viewing**: `bat` with syntax highlighting
- **File finding**: `fd` and `ripgrep` for fast searches
- **Fuzzy finding**: `fzf` for interactive selections
- **Smart navigation**: `zoxide` for intelligent directory jumping

### Git Workflow Enhancement
```bash
# Multi-account Git management
git-personal          # Switch to personal GitHub account
git-lument           # Switch to work account
git-pollex           # Switch to consulting account
git-context          # Show current account context
```

### Productivity Features
```bash
# Quick utilities
mkcd newdir           # Create directory and cd into it
extract archive.zip   # Smart archive extraction
pathclean            # Remove duplicate PATH entries
path                 # Display PATH entries clearly

# macOS integration
show                 # Show hidden files in Finder
hide                 # Hide hidden files in Finder
flushdns            # Clear DNS cache
ql file.pdf         # Quick Look preview
```

## 🛡️ Security Features

### System Hardening
- FileVault disk encryption
- Firewall configuration
- Touch ID for sudo (when available)
- SSH key management
- Secure credential storage

### Data Protection (Data Scientist Profile)
- Enhanced data encryption
- Notebook security measures
- API key management
- Secure data storage protocols

## 📊 Hardware-Specific Configurations

### Apple Silicon Optimisations
- Native ARM64 applications preferred
- TensorFlow Metal acceleration
- PyTorch MPS backend support
- Optimised memory management

### Intel Mac Support
- Rosetta 2 when necessary
- Legacy application compatibility
- Performance tuning for older hardware

## 🔄 Post-Installation

### Verification
The setup automatically verifies:
- All required commands are available
- Services are running correctly
- Programming environments work
- Database connections function

### Manual Steps
Some configurations require manual intervention:
1. **1Password setup**: Sign in to sync passwords and SSH keys
2. **Git configuration**: Verify commit signing and remotes
3. **Cloud services**: Authenticate with AWS, Azure, GCP
4. **IDE preferences**: Import settings and extensions

## 📝 Customisation

### Local Overrides
Create `~/.zshrc.local` for machine-specific shell configuration:
```bash
# ~/.zshrc.local
export MY_CUSTOM_VAR="value"
alias myalias="my command"
```

### Custom Key Bindings
Modify `DefaultKeyBinding.dict` for system-wide key bindings:
```bash
# Custom macOS key bindings
# Place in ~/Library/KeyBindings/DefaultKeyBinding.dict
```

### Claude AI Configuration
Customise Claude AI integration:
```bash
# Project-specific Claude settings
echo "# Custom Claude configuration" >> CLAUDE.MD

# Local Claude preferences  
echo "# Local settings" >> CLAUDE.local.md
```

### Hardware-Specific Packages
Add hardware-specific Brewfiles:
```
bootstrap/config/hardware/Brewfile.my-machine
```

### Machine-Specific Configuration
Add machine-specific configuration files:
```
bootstrap/config/machine-configs/my-machine.conf
```

### Profile Customisation
Modify existing profiles or create new ones in the `profiles/` directory.

## 🚨 Troubleshooting

### Common Issues

**Command not found errors**
```bash
# Reload shell configuration
exec zsh

# Check PATH
path

# Clean duplicate PATH entries
pathclean
```

**Package installation failures**
```bash
# Update Homebrew
brew update && brew upgrade

# Check system requirements
system_profiler SPSoftwareDataType
```

**Python environment issues**
```bash
# Reset UV cache
uv cache clean

# Recreate virtual environment
rm -rf .venv && uv venv && va
```

### Debug Mode
Enable detailed logging for troubleshooting:
```bash
./bootstrap/scripts/00-bootstrap.zsh --debug --verbose
```

Log files are stored in `~/.config/dotfiles-setup/`

### Validation Tools
Use the built-in validation tools to check setup integrity:
```bash
# Validate dry-run capabilities
./bootstrap/scripts/validate-dry-run.zsh

# Run comprehensive tests
cd bootstrap/tests && bats test_dry_run.bats
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Follow the shell scripting standards in `../macos-zsh-standards.md`
4. Test on multiple macOS versions and hardware
5. Submit a pull request

### Adding New Modules
1. Create `bootstrap/scripts/XX-module-name.zsh`
2. Follow the template structure in `macos-zsh-standards.md`
3. Add to `AVAILABLE_MODULES` in bootstrap script
4. Update profile configurations
5. Add tests and documentation
6. Consider adding modular components in `scripts/modules/`
7. Update machine-specific configurations if needed

## 📖 Documentation

### Core Documentation
- [macOS Zsh Standards](../macos-zsh-standards.md) - Shell scripting guidelines
- [macOS Specialist Role](../role-macos-specialist.md) - Expert system administrator guidance
- [Stow Package Specification](../spec.md) - Package management with GNU Stow

### Feature Documentation
- [Dry-Run Testing](DRY-RUN-TESTING.md) - Testing framework and validation
- [Power Management & Remote Access](POWER-MANAGEMENT-REMOTE-ACCESS.md) - Advanced system configuration
- [Package Summary](PACKAGE_SUMMARY.md) - Complete package listings

### Script Documentation
- [Hardware Detection](../bootstrap/scripts/01-system-detection.zsh) - How hardware detection works
- [Security Hardening](../bootstrap/scripts/07-security-hardening.zsh) - Security implementation details
- [Power & Remote Access](../bootstrap/scripts/10-power-remote-access.zsh) - Power management setup

### Module Documentation
- [Network Shares](../bootstrap/scripts/modules/network-shares.zsh) - Network sharing configuration
- [System Health](../bootstrap/scripts/modules/system-health.zsh) - Health monitoring setup
- [Remote Access](../bootstrap/scripts/modules/remote-access.zsh) - Remote access configuration

## 📄 License

MIT License - see [LICENSE](../LICENSE) for details.

## 🙏 Acknowledgements

- [Zinit](https://github.com/zdharma-continuum/zinit) - Fast zsh plugin manager
- [Pure](https://github.com/sindresorhus/pure) - Minimal and fast zsh prompt
- [Homebrew](https://brew.sh/) - Package manager for macOS
- [UV](https://github.com/astral-sh/uv) - Fast Python package installer

---

**Author**: Andrew Exley

For questions, issues, or contributions, please visit the [GitHub repository](https://github.com/aex-gh/macos-setup).

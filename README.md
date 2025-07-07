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
curl -fsSL https://raw.githubusercontent.com/aex-gh/dotfiles/main/install.sh | bash
```

### Manual Installation

```bash
git clone https://github.com/aex-gh/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./scripts/00-bootstrap.zsh
```

## 📁 Repository Structure

```
dotfiles/
├── scripts/                 # Setup modules (numbered for execution order)
│   ├── 00-bootstrap.zsh     # Main orchestration script
│   ├── 01-system-detection.zsh
│   ├── 02-xcode-tools.zsh
│   ├── 03-homebrew-setup.zsh
│   ├── 04-system-setup.zsh
│   ├── 05-macos-defaults.zsh
│   ├── 06-applications.zsh
│   ├── 07-security-hardening.zsh
│   ├── 09-post-setup.zsh
│   └── modules/
├── profiles/                # User profile configurations
│   ├── developer.yml        # Full development environment
│   ├── data-scientist.yml   # ML/DS focused setup
│   └── personal.yml         # Personal productivity setup
├── config/                  # Application and system configurations
│   ├── Brewfile*            # Homebrew package definitions
│   ├── hardware/            # Hardware-specific configurations
│   └── machine-configs/     # Per-machine settings
├── zsh/                     # Shell configuration
│   ├── dot-zshrc           # Main zsh configuration
│   ├── dot-zshenv          # Environment variables
│   └── dot-zprofile        # Login shell setup
└── ssh/                     # SSH configuration templates
```

## 🎨 Setup Profiles

### Developer Profile
Perfect for software engineers and full-stack developers:
- **Languages**: Python, Node.js, Go, Rust, Java
- **Tools**: VS Code, Zed, JetBrains Toolbox, OrbStack
- **Databases**: PostgreSQL, Redis, MongoDB
- **Cloud**: AWS, Azure, GCP CLI tools
- **DevOps**: Docker, Kubernetes, Terraform

### Data Scientist Profile
Optimised for machine learning and data analysis:
- **Languages**: Python (with ML stack), R, Julia, Scala
- **Tools**: Jupyter Lab, RStudio, Anaconda
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

### Comprehensive Package Management
- **Homebrew** for command-line tools
- **Homebrew Cask** for GUI applications
- **Mac App Store** integration via `mas`
- Hardware-specific package selection
- Service auto-start configuration

## 🛠️ Usage Examples

### Interactive Setup
```bash
./scripts/00-bootstrap.zsh
# Follow prompts to select profile and modules
```

### Automated Setup (CI/CD)
```bash
./scripts/00-bootstrap.zsh --profile developer --force
```

### Dry Run (Preview Changes)
```bash
./scripts/00-bootstrap.zsh --profile data-scientist --dry-run
```

### Specific Modules Only
```bash
./scripts/00-bootstrap.zsh --modules-only "01,03,05"
```

### Debug Mode
```bash
./scripts/00-bootstrap.zsh --debug --verbose
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

### Hardware-Specific Packages
Add hardware-specific Brewfiles:
```
config/hardware/Brewfile.my-machine
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
./scripts/00-bootstrap.zsh --debug --verbose
```

Log files are stored in `~/.config/dotfiles-setup/`

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Follow the shell scripting standards in `macos-zsh-standards.md`
4. Test on multiple macOS versions and hardware
5. Submit a pull request

### Adding New Modules
1. Create `scripts/XX-module-name.zsh`
2. Follow the template structure
3. Add to `AVAILABLE_MODULES` in bootstrap script
4. Update profile configurations
5. Add tests and documentation

## 📖 Documentation

- [macOS Zsh Standards](macos-zsh-standards.md) - Shell scripting guidelines
- [macOS Specialist Role](role-macos-specialist.md) - Expert system administrator guidance
- [Hardware Detection](scripts/01-system-detection.zsh) - How hardware detection works
- [Security Hardening](scripts/07-security-hardening.zsh) - Security implementation details

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

## 🙏 Acknowledgements

- [Zinit](https://github.com/zdharma-continuum/zinit) - Fast zsh plugin manager
- [Pure](https://github.com/sindresorhus/pure) - Minimal and fast zsh prompt
- [Homebrew](https://brew.sh/) - Package manager for macOS
- [UV](https://github.com/astral-sh/uv) - Fast Python package installer

---

**Author**: Andrew Exley (with Claude)
**Co-Authored-By**: Claude <noreply@anthropic.com>

For questions, issues, or contributions, please visit the [GitHub repository](https://github.com/aex-gh/dotfiles).

# macOS Setup Automation - Task List

Status: 🔴 Not Started | 🟡 In Progress | 🟢 Complete | ❌ Blocked

## Phase 1: Foundation Setup (Priority: High)

### Repository Initialisation
- [x] 🟢 Initialise git repository with `git init`
- [x] 🟢 Create comprehensive `.gitignore` for macOS and secrets
- [x] 🟢 Make initial commit with existing documentation
- [x] 🟢 Configure git user settings (name, email, default branch)

## Phase 2: Project Structure Creation (Priority: High)

### Directory Structure
- [x] 🟢 Create `configs/` directory
- [x] 🟢 Create `configs/common/` for base configurations
- [x] 🟢 Create `configs/macbook-pro/` for portable development configs
- [x] 🟢 Create `configs/mac-studio/` for server infrastructure configs
- [x] 🟢 Create `configs/mac-mini/` for lightweight development configs
- [x] 🟢 Create `scripts/` directory for setup and utility scripts
- [x] 🟢 Create `dotfiles/` directory for chezmoi source files
- [x] 🟢 Create `tests/` directory for BATS test files

### Documentation Organisation
- [x] 🟢 Move existing docs to `docs/` subdirectory
- [x] 🟢 Update CLAUDE.md with correct file paths
- [x] 🟢 Create `README.md` with project overview and usage

## Phase 3: Core Brewfiles (Priority: High)

### Core Dependencies Planning
- [x] 🟢 Add chezmoi to base Brewfile (`chezmoi`)
- [x] 🟢 Add essential development tools to base Brewfile (`jq`, `ripgrep`, `bat`, `eza`, `fzf`)
- [x] 🟢 Add BATS testing framework to base Brewfile (`bats-core`)
- [x] 🟢 Create script to verify required tools are accessible in PATH

### Base Configuration
- [x] 🟢 Create `configs/common/Brewfile` with universal tools
  - [x] Essential CLI tools (git, gh, jq, ripgrep, bat, eza, fzf)
  - [x] Development languages (python, node, ruby)
  - [x] Container tools (orbstack)
  - [x] Productivity apps (1password, raycast, karabiner-elements)

### Device-Specific Brewfiles
- [x] 🟢 Create `configs/macbook-pro/Brewfile` extending base
  - [x] Portable development tools
  - [x] Jump Desktop (MAS install)
  - [x] Battery optimisation tools
- [x] 🟢 Create `configs/mac-studio/Brewfile` extending base
  - [x] Server infrastructure tools
  - [x] Jump Desktop Connect
  - [x] Monitoring and virtualisation tools
- [x] 🟢 Create `configs/mac-mini/Brewfile` extending base
  - [x] Media applications (iina, zen-browser)
  - [x] Jump Desktop Connect
  - [x] Home automation tools

### Validation
- [x] 🟢 Create script to validate all formulae exist in current Homebrew
- [x] 🟢 Create script to validate all casks exist in current Homebrew
- [x] 🟢 Create script to test Brewfile syntax and dependencies

## Phase 4: Essential Scripts (Priority: High)

### Main Setup Orchestrator
- [x] 🟢 Create `scripts/setup.zsh` following zsh standards
  - [x] Device detection logic (MacBook Pro/Mac Studio/Mac Mini)
  - [x] Interactive setup flow with progress feedback
  - [x] Integration points for all setup scripts
  - [x] Error handling and recovery mechanisms

### Individual Setup Scripts
- [x] 🟢 Create `scripts/install-homebrew.zsh`
  - [x] Script to install Homebrew if missing
  - [x] Script to configure PATH correctly
  - [x] Script to perform initial package updates
- [x] 🟢 Create `scripts/configure-macos.zsh`
  - [x] System defaults configuration
  - [x] Dock, Finder, and UI preferences
  - [x] Screenshot and keyboard settings
- [x] 🟢 Create `scripts/setup-users.zsh`
  - [x] Script for multi-user account creation
  - [x] Script to set appropriate permissions and groups
  - [x] Script for home directory setup

### Utility Scripts
- [x] 🟢 Create `scripts/install-packages.zsh`
  - [x] Script for device-specific Brewfile installation
  - [x] Script for dependency resolution
  - [x] Script to track installation progress
- [x] 🟢 Create `scripts/validate-setup.zsh`
  - [x] Script to perform system health checks
  - [x] Script for required tool verification
  - [x] Script for configuration validation

## Phase 5: Security and User Management (Priority: Medium)

### Security Configuration
- [x] 🟢 Create script to set up FileVault encryption
- [x] 🟢 Create script to configure firewall settings for each device type
- [x] 🟢 Create script for 1Password CLI integration
  - [x] Script for service account configuration
  - [x] Script with secure credential retrieval functions
- [x] 🟢 Create script to implement basic macOS hardening measures

### Multi-User Setup
- [x] 🟢 Create script with user account creation functions
  - [x] Script to create Ali Exley (ali) - standard user
  - [x] Script to create Amelia Exley (amelia) - standard user
  - [x] Script to create Annabelle Exley (annabelle) - standard user
- [x] 🟢 Create script to configure shared directories and permissions
- [x] 🟢 Create script to set up Time Machine access for all users
- [x] 🟢 Create script to configure user-specific preferences

## Phase 6: Device-Specific Features (Priority: Medium)

### Network Configuration
- [x] 🟢 Create script for static IP setup for Mac Studio (10.20.0.10)
- [x] 🟢 Create script for static IP setup for Mac Mini (10.20.0.12)
- [x] 🟢 Create script to configure WiFi settings for MacBook Pro (dynamic IP)
- [x] 🟢 Create script to set up network service ordering and priorities

### Remote Access Setup
- [x] 🟢 Create script to configure Jump Desktop Connect for headless systems
- [x] 🟢 Create script to configure Jump Desktop for MacBook Pro
- [x] 🟢 Create script to set up SSH key management via 1Password
- [x] 🟢 Create script to configure Screen Sharing preferences

### Mac Studio Server Features
- [x] 🟢 Create script to configure central file server functionality
- [x] 🟢 Create script to set up Time Machine backup server
- [x] 🟢 Create script to implement headless operation optimisations
- [x] 🟢 Create monitoring and maintenance scripts

## Phase 7: Dotfiles and Theming (Priority: Medium)

### Chezmoi Implementation
- [x] 🟢 Initialise chezmoi in `dotfiles/` directory
- [x] 🟢 Create device-specific templates
- [x] 🟢 Configure encrypted storage for sensitive files
- [x] 🟢 Set up automatic dotfile synchronisation

### Font and Theme Standardisation
- [x] 🟢 Create script to install Maple Mono Nerd Font system-wide
- [x] 🟢 Create script to configure Gruvbox Dark Soft Contrast theme
- [x] 🟢 Create script to apply theme to Zed editor
- [x] 🟢 Create script to apply theme to Terminal application
- [x] 🟢 Create script to apply theme to other compatible applications

### Application Configurations
- [x] 🟢 Create Zed editor configuration templates
- [x] 🟢 Create Terminal.app configuration templates
- [x] 🟢 Create shell (zsh) configuration templates
- [x] 🟢 Create git configuration templates

## Phase 8: Advanced Features (Priority: Low)

### Claude Code Integration
- [x] 🟢 Create script to install Claude Code via appropriate method
- [x] 🟢 Create script to configure MCP servers:
  - [x] Script for @upstash/context7-mcp
  - [x] Script for @alioshr/memory-bank-mcp
  - [x] Script for @modelcontextprotocol/server-filesystem
  - [x] Script for @microsoft/markitdown-mcp
  - [x] Script for @wonderwhy-er/desktop-commander-mcp
  - [x] Script for @modelcontextprotocol/server-github
- [x] 🟢 Create script to configure AppleScript integration

### Linux Compatibility
- [x] 🟢 Create script to integrate linuxify from https://github.com/pkill37/linuxify
- [x] 🟢 Create script to test and validate Linux command aliases
- [x] 🟢 Document compatibility features and limitations

### Automation Tools
- [x] 🟢 Create AppleScript automation scripts for system tasks
- [x] 🟢 Create maintenance and update scripts
- [x] 🟢 Create backup and restore procedure scripts

## Phase 9: Testing and Documentation (Priority: Medium)

### Testing Framework
- [x] 🟢 Implement BATS tests for all setup scripts
- [x] 🟢 Create integration tests for complete setup flows
- [x] 🟢 Set up automated testing for different scenarios
- [x] 🟢 Create test data and mock environments

### Documentation
- [x] 🟢 Write comprehensive README with usage instructions
- [x] 🟢 Document troubleshooting procedures
- [x] 🟢 Create examples for common customisation scenarios
- [x] 🟢 Document security considerations and best practices

### Quality Assurance
- [x] 🟢 Code review and cleanup of all scripts
- [x] 🟢 Performance optimisation where needed

## Milestones

### Milestone 1: Foundation Complete
- ✅ Repository initialised with proper structure
- ✅ Phase 1: Repository initialisation completed
- ✅ Phase 2: Project structure creation completed

### Milestone 2: Core Functionality
- ✅ All Brewfiles created and validated
- ✅ Main setup scripts implemented and tested
- ✅ Device detection and basic setup working

### Milestone 3: Security & Users
- ✅ Multi-user setup functioning
- ✅ Security configurations implemented
- ✅ 1Password integration working

### Milestone 4: Device-Specific Features
- ✅ Network configurations working
- ✅ Remote access configured
- ✅ Mac Studio server features operational

### Milestone 5: Complete System
- ✅ Dotfiles and theming implemented
- ✅ Advanced features integrated
- ✅ Testing and documentation complete

### Milestone 6: Conflict Resolution
- ✅ Script conflicts identified and analyzed
- ✅ Conflicting operations eliminated
- ✅ Conflict detection tools implemented
- ✅ Script execution guidelines documented

## Phase 10: Script Conflict Resolution (Priority: High)

### User Management Conflicts
- [x] 🟢 Analyze overlap between `setup-users.zsh` and `setup-family-environment.zsh`
- [x] 🟢 Refactor `setup-users.zsh` to handle basic user setup only
  - [x] Remove family-specific user creation (ali, amelia, annabelle)
  - [x] Remove shared directory creation logic
  - [x] Remove Time Machine backup setup
  - [x] Focus on core user account creation functions only
- [x] 🟢 Expand `setup-family-environment.zsh` to handle all family features
  - [x] Move family user creation from `setup-users.zsh`
  - [x] Ensure all shared directory creation is consolidated here
  - [x] Consolidate all family-specific permission settings
- [x] 🟢 Test user management scripts independently
- [x] 🟢 Verify no duplicate user creation operations

### System Configuration Conflicts
- [x] 🟢 Analyze overlap between `configure-macos.zsh` and `setup-family-environment.zsh`
- [x] 🟢 Refactor `configure-macos.zsh` to handle universal defaults only
  - [x] Remove family-specific `defaults write` commands
  - [x] Remove family-specific Dock configuration
  - [x] Remove family-specific Finder settings
  - [x] Remove family-specific power management settings
  - [x] Keep only universal system preferences
- [x] 🟢 Move family-specific system defaults to `setup-family-environment.zsh`
  - [x] Consolidate all family-specific `defaults write` commands
  - [x] Ensure family-specific Dock settings are here only
  - [x] Ensure family-specific Finder settings are here only
- [x] 🟢 Create conflict detection script to identify overlapping `defaults write` commands
- [x] 🟢 Test system configuration scripts independently
- [x] 🟢 Verify no duplicate system default operations

### Font Installation Conflicts
- [x] 🟢 Analyze overlap between Homebrew font installation and manual font installation
- [x] 🟢 Decide on single font installation approach
  - [x] Option A: Remove manual font installation, rely on Homebrew only
  - [x] Option B: Add detection to prevent duplicate installations
  - [x] Option C: Make font installation methods mutually exclusive
- [x] 🟢 Implement chosen font installation strategy
- [x] 🟢 Update `install-fonts.zsh` to align with chosen approach
- [x] 🟢 Test font installation to ensure no duplicates

### Script Interaction Analysis
- [x] 🟢 Create script dependency mapping document
- [x] 🟢 Identify all `defaults write` commands across all scripts
- [x] 🟢 Identify all `dscl` commands across all scripts
- [x] 🟢 Identify all `sudo` operations across all scripts
- [x] 🟢 Create script execution order recommendations
- [x] 🟢 Document which scripts should not be run together

### Validation and Testing
- [x] 🟢 Create integration tests for automatic + manual script combinations
- [x] 🟢 Test automatic scripts followed by manual scripts
- [x] 🟢 Test manual scripts followed by automatic scripts
- [x] 🟢 Create script conflict detection tool
- [x] 🟢 Add warnings to scripts about potential conflicts
- [x] 🟢 Update documentation with script interaction warnings

### Documentation Updates
- [x] 🟢 Update README.md with script conflict information
- [x] 🟢 Create script execution guidelines document
- [x] 🟢 Document recommended script execution order
- [x] 🟢 Add warnings about running conflicting scripts
- [x] 🟢 Update troubleshooting guide with conflict resolution steps

## Success Criteria
- [x] 🟢 Complete, automated setup for all three Mac models
- [x] 🟢 Idempotent scripts (safe to run multiple times)
- [x] 🟢 Comprehensive error handling and recovery
- [x] 🟢 Full compliance with Australian English requirements
- [x] 🟢 Security-first implementation with 1Password integration
- [x] 🟢 Working multi-user family environment with appropriate permissions
- [x] 🟢 Comprehensive testing and documentation
- [x] 🟢 **No script conflicts or overlapping operations**
- [x] 🟢 **Clear script execution guidelines and warnings**

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
- [ ] 🔴 Initialise chezmoi in `dotfiles/` directory
- [ ] 🔴 Create device-specific templates
- [ ] 🔴 Configure encrypted storage for sensitive files
- [ ] 🔴 Set up automatic dotfile synchronisation

### Font and Theme Standardisation
- [ ] 🔴 Create script to install Maple Mono Nerd Font system-wide
- [ ] 🔴 Create script to configure Gruvbox Dark Soft Contrast theme
- [ ] 🔴 Create script to apply theme to Zed editor
- [ ] 🔴 Create script to apply theme to Terminal application
- [ ] 🔴 Create script to apply theme to other compatible applications

### Application Configurations
- [ ] 🔴 Create Zed editor configuration templates
- [ ] 🔴 Create Terminal.app configuration templates
- [ ] 🔴 Create shell (zsh) configuration templates
- [ ] 🔴 Create git configuration templates

## Phase 8: Advanced Features (Priority: Low)

### Claude Code Integration
- [ ] 🔴 Create script to install Claude Code via appropriate method
- [ ] 🔴 Create script to configure MCP servers:
  - [ ] Script for @upstash/context7-mcp
  - [ ] Script for @alioshr/memory-bank-mcp
  - [ ] Script for @modelcontextprotocol/server-filesystem
  - [ ] Script for @microsoft/markitdown-mcp
  - [ ] Script for @wonderwhy-er/desktop-commander-mcp
  - [ ] Script for @modelcontextprotocol/server-github
- [ ] 🔴 Create script to configure AppleScript integration

### Linux Compatibility
- [ ] 🔴 Create script to integrate linuxify from https://github.com/pkill37/linuxify
- [ ] 🔴 Create script to test and validate Linux command aliases
- [ ] 🔴 Document compatibility features and limitations

### Automation Tools
- [ ] 🔴 Create AppleScript automation scripts for system tasks
- [ ] 🔴 Create maintenance and update scripts
- [ ] 🔴 Create backup and restore procedure scripts

## Phase 9: Testing and Documentation (Priority: Medium)

### Testing Framework
- [ ] 🔴 Implement BATS tests for all setup scripts
- [ ] 🔴 Create integration tests for complete setup flows
- [ ] 🔴 Set up automated testing for different scenarios
- [ ] 🔴 Create test data and mock environments

### Documentation
- [x] 🟢 Write comprehensive README with usage instructions
- [ ] 🔴 Document troubleshooting procedures
- [ ] 🔴 Create examples for common customisation scenarios
- [ ] 🔴 Document security considerations and best practices

### Quality Assurance
- [ ] 🔴 Code review and cleanup of all scripts
- [ ] 🔴 Performance optimisation where needed
- [ ] 🔴 Accessibility and usability improvements
- [ ] 🔴 Final testing on clean macOS installations

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

## Success Criteria
- [ ] Complete, automated setup for all three Mac models
- [ ] Idempotent scripts (safe to run multiple times)
- [ ] Comprehensive error handling and recovery
- [ ] Full compliance with Australian English requirements
- [ ] Security-first implementation with 1Password integration
- [ ] Working multi-user family environment with appropriate permissions
- [ ] Comprehensive testing and documentation
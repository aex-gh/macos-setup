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
- [ ] 🔴 Add chezmoi to base Brewfile (`chezmoi`)
- [ ] 🔴 Add essential development tools to base Brewfile (`jq`, `ripgrep`, `bat`, `eza`, `fzf`)
- [ ] 🔴 Add BATS testing framework to base Brewfile (`bats-core`)
- [ ] 🔴 Create script to verify required tools are accessible in PATH

### Base Configuration
- [ ] 🔴 Create `configs/common/Brewfile` with universal tools
  - [ ] Essential CLI tools (git, gh, jq, ripgrep, bat, eza, fzf)
  - [ ] Development languages (python, node, ruby)
  - [ ] Container tools (orbstack)
  - [ ] Productivity apps (1password, raycast, karabiner-elements)

### Device-Specific Brewfiles
- [ ] 🔴 Create `configs/macbook-pro/Brewfile` extending base
  - [ ] Portable development tools
  - [ ] Jump Desktop (MAS install)
  - [ ] Battery optimisation tools
- [ ] 🔴 Create `configs/mac-studio/Brewfile` extending base
  - [ ] Server infrastructure tools
  - [ ] Jump Desktop Connect
  - [ ] Monitoring and virtualisation tools
- [ ] 🔴 Create `configs/mac-mini/Brewfile` extending base
  - [ ] Media applications (iina, zen-browser)
  - [ ] Jump Desktop Connect
  - [ ] Home automation tools

### Validation
- [ ] 🔴 Create script to validate all formulae exist in current Homebrew
- [ ] 🔴 Create script to validate all casks exist in current Homebrew
- [ ] 🔴 Create script to test Brewfile syntax and dependencies

## Phase 4: Essential Scripts (Priority: High)

### Main Setup Orchestrator
- [ ] 🔴 Create `scripts/setup.zsh` following zsh standards
  - [ ] Device detection logic (MacBook Pro/Mac Studio/Mac Mini)
  - [ ] Interactive setup flow with progress feedback
  - [ ] Integration points for all setup scripts
  - [ ] Error handling and recovery mechanisms

### Individual Setup Scripts
- [ ] 🔴 Create `scripts/install-homebrew.zsh`
  - [ ] Script to install Homebrew if missing
  - [ ] Script to configure PATH correctly
  - [ ] Script to perform initial package updates
- [ ] 🔴 Create `scripts/configure-macos.zsh`
  - [ ] System defaults configuration
  - [ ] Dock, Finder, and UI preferences
  - [ ] Screenshot and keyboard settings
- [ ] 🔴 Create `scripts/setup-users.zsh`
  - [ ] Script for multi-user account creation
  - [ ] Script to set appropriate permissions and groups
  - [ ] Script for home directory setup

### Utility Scripts
- [ ] 🔴 Create `scripts/install-packages.zsh`
  - [ ] Script for device-specific Brewfile installation
  - [ ] Script for dependency resolution
  - [ ] Script to track installation progress
- [ ] 🔴 Create `scripts/validate-setup.zsh`
  - [ ] Script to perform system health checks
  - [ ] Script for required tool verification
  - [ ] Script for configuration validation

## Phase 5: Security and User Management (Priority: Medium)

### Security Configuration
- [ ] 🔴 Create script to set up FileVault encryption
- [ ] 🔴 Create script to configure firewall settings for each device type
- [ ] 🔴 Create script for 1Password CLI integration
  - [ ] Script for service account configuration
  - [ ] Script with secure credential retrieval functions
- [ ] 🔴 Create script to implement basic macOS hardening measures

### Multi-User Setup
- [ ] 🔴 Create script with user account creation functions
  - [ ] Script to create Ali Exley (ali) - standard user
  - [ ] Script to create Amelia Exley (amelia) - standard user  
  - [ ] Script to create Annabelle Exley (annabelle) - standard user
- [ ] 🔴 Create script to configure shared directories and permissions
- [ ] 🔴 Create script to set up Time Machine access for all users
- [ ] 🔴 Create script to configure user-specific preferences

## Phase 6: Device-Specific Features (Priority: Medium)

### Network Configuration
- [ ] 🔴 Create script for static IP setup for Mac Studio (10.20.0.10)
- [ ] 🔴 Create script for static IP setup for Mac Mini (10.20.0.12)
- [ ] 🔴 Create script to configure WiFi settings for MacBook Pro (dynamic IP)
- [ ] 🔴 Create script to set up network service ordering and priorities

### Remote Access Setup
- [ ] 🔴 Create script to configure Jump Desktop Connect for headless systems
- [ ] 🔴 Create script to configure Jump Desktop for MacBook Pro
- [ ] 🔴 Create script to set up SSH key management via 1Password
- [ ] 🔴 Create script to configure Screen Sharing preferences

### Mac Studio Server Features
- [ ] 🔴 Create script to configure central file server functionality
- [ ] 🔴 Create script to set up Time Machine backup server
- [ ] 🔴 Create script to implement headless operation optimisations
- [ ] 🔴 Create monitoring and maintenance scripts

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
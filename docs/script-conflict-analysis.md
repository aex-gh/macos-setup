# Script Conflict Analysis

## Overview

This document identifies script conflicts and overlapping operations discovered during Phase 10 implementation. All conflicts must be resolved to ensure idempotent script execution.

## Major Conflicts Identified

### 1. User Management Conflicts

**Scripts:** `setup-users.zsh` vs `setup-family-environment.zsh`

**Overlapping Operations:**
- **Family user creation:** Both scripts create the same family users (ali, amelia, annabelle)
- **Shared directory setup:** Both create `/Users/Shared/Family/` structure
- **Time Machine configuration:** Both handle Time Machine backup settings
- **User preference configuration:** Both set Australian English locale and Finder preferences

**Conflict Details:**
- `setup-users.zsh:266-293` - Creates family users with basic setup
- `setup-family-environment.zsh` - Comprehensive family environment but no user creation
- Both scripts create shared directories with slightly different structures
- Both configure Time Machine but with different approaches

### 2. System Configuration Conflicts

**Scripts:** `configure-macos.zsh` vs `setup-family-environment.zsh`

**Overlapping Operations:**
- **Finder preferences:** Both set identical Finder defaults
- **Dock configuration:** Both configure Dock settings
- **Power management:** Both set energy/power settings
- **Australian locale:** Both set Australian English locale settings

**Conflict Details:**
- `configure-macos.zsh:354-368` - Sets Finder defaults globally
- `setup-family-environment.zsh:347-389` - Sets identical Finder defaults
- `configure-macos.zsh:248-293` - Configures Dock settings
- `setup-family-environment.zsh:371-386` - Sets overlapping Dock settings
- Both scripts configure power management but with different device-specific logic

### 3. Font Installation Conflicts

**Scripts:** `install-fonts.zsh` vs Homebrew Brewfile installation

**Overlapping Operations:**
- **Maple Mono installation:** Manual download vs Homebrew cask installation
- **Additional fonts:** Manual Homebrew installation vs Brewfile specification

**Conflict Details:**
- `install-fonts.zsh:51-111` - Downloads and installs Maple Mono manually
- `configs/common/Brewfile:37` - Installs `font-maple-mono-nf` via Homebrew
- `install-fonts.zsh:113-159` - Installs additional fonts via Homebrew
- Potential for duplicate installations and conflicting font cache operations

## Detailed Conflict Matrix

### `defaults write` Commands

**Finder Preferences:**
- `configure-macos.zsh:199` - `com.apple.finder AppleShowAllFiles true`
- `setup-family-environment.zsh:357` - `com.apple.finder AppleShowAllFiles true`
- `configure-macos.zsh:202` - `NSGlobalDomain AppleShowAllExtensions true`
- `setup-family-environment.zsh:354` - `NSGlobalDomain AppleShowAllExtensions true`

**Dock Configuration:**
- `configure-macos.zsh:249` - `com.apple.dock tilesize 36`
- `setup-family-environment.zsh:374` - `com.apple.dock tilesize 48`
- `configure-macos.zsh:288` - `com.apple.dock autohide true`
- `setup-family-environment.zsh:384` - `com.apple.dock mru-spaces false`

**Locale Settings:**
- `configure-macos.zsh:144-147` - Sets Australian English locale
- `setup-users.zsh:257-260` - Sets Australian English locale per user

### `sudo` Operations

**Power Management:**
- `configure-macos.zsh:309-329` - Device-specific power settings
- `setup-family-environment.zsh:399-418` - Family-optimised power settings

**Directory Creation:**
- `setup-users.zsh:194-217` - Creates shared directories
- `setup-family-environment.zsh:55-89` - Creates comprehensive directory structure

### `dscl` Commands

**User Creation:**
- `setup-users.zsh:82-94` - Creates family users
- No conflicts identified - only `setup-users.zsh` performs user creation

### Font Installation

**Maple Mono:**
- `install-fonts.zsh:51-111` - Manual download and installation
- `configs/common/Brewfile:37` - Homebrew cask installation

## Impact Assessment

### High Priority Conflicts
1. **Finder/Dock defaults** - May cause unexpected behaviour if values differ
2. **Power management** - Conflicting settings can cause system instability
3. **Font installation** - Duplicate installations waste resources and may cause conflicts

### Medium Priority Conflicts
1. **Shared directory creation** - May cause permission issues
2. **Time Machine configuration** - Different approaches may not be compatible

### Low Priority Conflicts
1. **User preference setting** - Mostly cosmetic but may cause confusion

## Recommended Resolution Strategy

### 1. Script Separation by Responsibility
- **setup-users.zsh** - Core user account creation only
- **setup-family-environment.zsh** - Family-specific environment configuration
- **configure-macos.zsh** - Universal system defaults only

### 2. Font Installation Standardisation
- **Option A:** Remove manual font installation, use Homebrew only
- **Option B:** Add detection to prevent duplicate installations
- **Option C:** Make font installation methods mutually exclusive

### 3. Configuration Layering
- **Universal defaults** - Applied by `configure-macos.zsh`
- **Family-specific defaults** - Applied by `setup-family-environment.zsh`
- **User-specific defaults** - Applied per user in appropriate scripts

## Next Steps

1. **Refactor scripts** to eliminate overlapping operations
2. **Create conflict detection tool** to identify future conflicts
3. **Update documentation** with script execution guidelines
4. **Test script combinations** to ensure no conflicts remain
5. **Add warnings** to scripts about potential conflicts

## Script Execution Order Recommendations

### Safe Execution Order
1. `install-homebrew.zsh`
2. `install-packages.zsh` (includes font installation via Brewfile)
3. `configure-macos.zsh` (universal defaults only)
4. `setup-users.zsh` (user creation only)
5. `setup-family-environment.zsh` (family-specific configuration)
6. Device-specific scripts

### Conflicting Combinations
- **DO NOT** run `install-fonts.zsh` if fonts are installed via Brewfile
- **DO NOT** run `setup-users.zsh` and `setup-family-environment.zsh` without coordination
- **DO NOT** run `configure-macos.zsh` and `setup-family-environment.zsh` without checking for conflicts

---

*Generated during Phase 10: Script Conflict Resolution*  
*Last updated: $(date '+%Y-%m-%d %H:%M:%S')*
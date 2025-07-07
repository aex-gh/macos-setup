# Dotfiles Management Specification for macOS (using GNU Stow)

## 1. Introduction

This document specifies a robust and maintainable approach for managing "dotfiles" on macOS, leveraging **GNU Stow** as the primary tool. Dotfiles are hidden configuration files (prefixed with a dot, e.g., `.zshrc`, `.gitconfig`) that customize various aspects of a user's environment, including shell configurations, application settings, and system preferences. Effective dotfile management ensures a consistent, reproducible, and portable development environment across different machines.

## 2. Goals

The primary goals of this specification are:

*   **Portability:** Easily transfer configurations to new macOS machines.
*   **Version Control:** Track changes to configuration files over time using Git.
*   **Reproducibility:** Quickly set up a development environment that matches a previous one.
*   **Simplicity:** Maintain a straightforward and understandable management system.
*   **Modularity:** Organize configurations logically for easier management, allowing selective deployment.

## 3. Core Concepts

### 3.1. What are Dotfiles?

Dotfiles are text files that store user-specific configurations for command-line tools, applications, and the operating system itself. Examples include:

*   Shell configurations (`.zshrc`, `.zshenv`, `.zprofile`)
*   Git configuration (`.gitconfig`)
*   Text editor/IDE configurations (e.g., `.vimrc`, VS Code settings)
*   SSH configurations (`.ssh/config`)
*   Application-specific configuration directories (e.g., `~/.config/nvim/`)

### 3.2. Why Manage Dotfiles?

*   **Backup:** Prevent loss of personalized settings.
*   **Efficiency:** Automate the setup of new machines.
*   **Consistency:** Maintain a uniform environment across multiple devices.
*   **Sharing:** Easily share configurations with others or between personal and work machines.
*   **Experimentation:** Safely test new configurations with version control and easy activation/deactivation.

## 4. Recommended Approach: GNU Stow

**GNU Stow** is a symlink farm manager that provides a clean and modular way to manage dotfiles. Instead of placing dotfiles directly in your home directory and tracking them with a bare Git repo, you organize them into logical, independent packages within a dedicated dotfiles repository (e.g., `~/dotfiles/`). Stow then creates symbolic links from these packages into your home directory, making them active.

### 4.1. Advantages of GNU Stow:

*   **Clean Home Directory:** Your actual dotfiles reside in a dedicated repository (e.g., `~/dotfiles/`), keeping your home directory uncluttered.
*   **Modularity and Organization:** Each set of related dotfiles (e.g., Zsh config, Git config, Neovim config) can be managed as an independent "package" within the repository.
*   **Selective Deployment:** You can easily "stow" (activate/symlink) or "unstow" (deactivate/remove symlinks) specific packages, which is ideal for managing different configurations across multiple machines or for experimentation.
*   **Version Control:** The `~/dotfiles/` repository is a standard Git repository, allowing full version control of your configurations.

### 4.2. Initialization Steps (using Stow):

1.  **Install GNU Stow:**
    Stow is available via Homebrew on macOS:
    ```bash
    brew install stow
    ```
2.  **Clone your Dotfiles Repository:**
    Clone your Git repository containing your dotfiles into a dedicated directory in your home folder (e.g., `~/dotfiles/`). If you don't have one yet, initialize a new Git repository here.
    ```bash
    mkdir -p ~/dotfiles
    cd ~/dotfiles
    git init # If starting a new repo
    # OR: git clone git@github.com:your_username/dotfiles.git . # If cloning an existing repo
    ```
3.  **Organize your Dotfiles:**
    Within `~/dotfiles/`, create subdirectories for each "package" of dotfiles you want to manage. For example:
    ```
    ~/dotfiles/
    ├── zsh/
    │   └── .zshrc
    ├── git/
    │   └── .gitconfig
    ├── nvim/
    │   └── .config/
    │       └── nvim/
    │           └── init.vim
    ├── starship/
    │   └── .config/
    │       └── starship.toml
    └── ssh/
        └── .ssh/
            └── config
    ```
    *   **Important:** The path *relative to the package directory* (e.g., `nvim/` or `starship/`) should match the desired path *relative to your home directory* (`~`). So, if you want `init.vim` to end up at `~/.config/nvim/init.vim`, then inside your `nvim` package, the structure should be `.config/nvim/init.vim`.

4.  **Stow your Dotfiles:**
    From inside the `~/dotfiles/` directory, use the `stow` command to create symlinks for your packages.
    ```bash
    cd ~/dotfiles/
    stow zsh      # Creates symlink for ~/.zshrc
    stow git      # Creates symlink for ~/.gitconfig
    stow nvim     # Creates symlink for ~/.config/nvim/
    stow starship # Creates symlink for ~/.config/starship.toml
    stow ssh      # Creates symlink for ~/.ssh/config
    ```
    *   `stow -D <package>` will delete the symlinks.
    *   `stow -R <package>` will restow (delete and recreate) the symlinks.

5.  **Push to remote (optional but recommended):**
    ```bash
    git remote add origin git@github.com:your_username/dotfiles.git
    git push -u origin master
    ```

## 5. macOS-Specific Considerations

macOS has unique configurations that should be managed alongside general dotfiles.

### 5.1. Homebrew (Package Manager)

Homebrew is the de facto package manager for macOS.

*   **Installation:**
    ```bash
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    ```
*   **`Brewfile` for Dependencies:** Use `brew bundle` to manage installed applications and command-line tools.
    *   Generate a `Brewfile`:
        ```bash
        brew bundle dump --force --file=$HOME/.Brewfile
        ```
    *   Include `.Brewfile` in a `homebrew/` package within your `~/dotfiles/` repository, and then `stow homebrew`.
    *   To restore on a new machine:
        ```bash
        brew bundle --file=$HOME/.Brewfile
        ```
    *   Consider separating `Brewfile` for Cask (GUI apps) and Formulae (CLI tools) if desired, or using multiple `Brewfile`s for different environments (e.g., work vs. personal).

### 5.2. `defaults` Commands for System Settings

macOS system settings are stored in Property List (plist) files, which can be manipulated using the `defaults` command.

*   **Management:** Create a shell script (e.g., `macos_defaults.sh`) within a `macos/` package in your `~/dotfiles/` repository to apply common macOS settings. This script should be explicitly run.
*   **Examples:**
    ```bash
    #!/bin/zsh

    # General UI/UX
    defaults write NSGlobalDomain AppleKeyboardUIMode -int 3                  # Enable full keyboard access for all controls
    defaults write com.apple.menuextra.battery ShowPercent -string "YES"      # Show battery percentage
    defaults write com.apple.dock autohide -bool TRUE                         # Auto-hide the Dock
    defaults write com.apple.finder AppleShowAllFiles -bool TRUE              # Show hidden files in Finder

    # Finder
    defaults write com.apple.finder ShowPathbar -bool TRUE                    # Show Path bar
    defaults write com.apple.finder ShowStatusBar -bool TRUE                  # Show Status bar
    defaults write com.apple.finder FXPreferredViewStyle -string "clmv"       # Four-letter codes for the other view modes: `icnv`, `Nsli`, `Flwv`
    defaults write NSGlobalDomain "com.apple.springing.delay" -float "0.5"    # Reduce spring loading delay for folders
    ```
*   **Execution:** Run this script on new machines after cloning and stowing dotfiles (e.g., `~/dotfiles/macos/macos_defaults.sh`).

### 5.3. Application-Specific Configurations

Many applications store configurations in various locations.

*   **Symlinking `~/Library/Application Support/`:** Some applications allow their configuration directories within `~/Library/Application Support/` to be symlinked. Research individual applications. This can be achieved by structuring a Stow package to create symlinks into this directory.
*   **VS Code Settings:** VS Code settings (`settings.json`, `keybindings.json`, `snippets/`) are typically in:
    *   macOS: `~/Library/Application Support/Code/User/`
    *   These can be symlinked via Stow (e.g., `~/dotfiles/vscode/.config/Code/User/settings.json`), or you can use VS Code's built-in Settings Sync.

### 5.3.1 Claude AI Configuration

Claude configuration should be managed in the following way:

* **Location:** Store Claude-specific configurations in `~/dotfiles/.claude/`
* **Structure:**
  * `CLAUDE.MD`: Main configuration file defining interaction patterns, coding standards, and project preferences
  * `.claude/docs/`: Directory containing technology-specific documentation and preferences

### 5.3.2 1Password SSH Integration

Implement 1Password SSH agent for secure credential management:

* **Configuration:**
  * Enable 1Password SSH agent in `~/.ssh/config`:
    ```
    Host *
      IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
    ```
  * Store SSH keys in 1Password instead of filesystem
  * Use biometric authentication for SSH operations

* **Benefits:**
  * Centralized credential management
  * Secure key storage with encryption at rest
  * Automatic synchronization across devices
  * Biometric authentication for key usage
  * Audit logging of SSH key usage

* **Implementation:**
  1. Install 1Password CLI using Homebrew
  2. Enable SSH agent in 1Password settings
  3. Add SSH keys to 1Password vault
  4. Configure SSH config to use 1Password agent

## 5.4. XDG Base Directory Specification

The XDG Base Directory Specification is a standard that defines where user-specific data files should be stored. Adhering to this specification helps keep your home directory cleaner by consolidating configuration, data, and cache files into specific directories. Many modern command-line tools and applications support this standard.

### 5.4.1. Core Directories

The specification defines three primary environment variables that point to base directories:

*   **`XDG_CONFIG_HOME`**: User-specific configuration files.
    *   Default: `~/.config`
    *   This is the most relevant directory for dotfiles, as many applications will look for their configurations here (e.g., `~/.config/nvim`, `~/.config/starship`).
*   **`XDG_DATA_HOME`**: User-specific data files.
    *   Default: `~/.local/share`
    *   Used for application-specific data that is not configuration (e.g., databases, game saves, downloaded assets).
*   **`XDG_CACHE_HOME`**: User-specific non-essential data files (cache).
    *   Default: `~/.cache`
    *   Used for temporary, non-critical data that can be re-generated (e.g., downloaded packages, build caches).

### 5.4.2. Adopting XDG on macOS with Stow

While macOS applications often use `~/Library/Application Support/`, many command-line tools and cross-platform applications will respect XDG environment variables. Stow is particularly well-suited for managing XDG-compliant configurations.

1.  **Set Environment Variables:** Ensure these variables are set in your shell configuration (`.zshrc`, `.bashrc`). While their defaults are often respected, explicitly setting them can ensure consistency.
    ```bash
    # XDG Base Directory Specification
    export XDG_CONFIG_HOME="$HOME/.config"
    export XDG_DATA_HOME="$HOME/.local/share"
    export XDG_CACHE_HOME="$HOME/.cache"
    ```
    This shell config (`.zshrc`, etc.) would be part of a Stow package (e.g., `zsh/`).
2.  **Organize Dotfiles as Stow Packages:** For applications that support XDG, their configuration directories should be placed within a corresponding Stow package, mirroring the `~/.config/` structure.
    *   **Example: Neovim**
        If Neovim config should be at `~/.config/nvim`, your Stow package `nvim/` would contain a `.config/nvim/` directory:
        ```
        ~/dotfiles/
        └── nvim/
            └── .config/
                └── nvim/
                    ├── init.vim
                    └── lua/
                        └── ...
        ```
        Then, `stow nvim` would create the symlink `~/.config/nvim` pointing to `~/dotfiles/nvim/.config/nvim`.
    *   **Example: Starship (Cross-Shell Prompt)**
        If Starship configuration defaults to `~/.config/starship.toml`, your Stow package `starship/` would contain a `.config/starship.toml` file:
        ```
        ~/dotfiles/
        └── starship/
            └── .config/
                └── starship.toml
        ```
        Then, `stow starship` would create the symlink `~/.config/starship.toml` pointing to `~/dotfiles/starship/.config/starship.toml`.
3.  **Check Application Documentation:** Always refer to an application's documentation to see if it supports XDG. Some applications might require specific environment variables or configuration options to use XDG paths.

By adopting the XDG specification and managing it with Stow, your home directory remains cleaner, and it becomes easier to backup and restore configurations for XDG-compliant applications.

## 6. Directory Structure within the Dotfiles Repository (`~/dotfiles/`)

This structure exemplifies how your dotfiles are organized into "packages" within your `~/dotfiles/` Git repository, ready to be symlinked by Stow.

~/dotfiles/
├── .git/                      # Git internal files
├── zsh/
│   ├── .zshrc
│   └── .zprofile
├── bash/
│   ├── .bashrc
│   └── .bash_profile
├── git/
│   ├── .gitconfig
│   └── .gitignore_global
├── zed/                      # XDG compliant app config
│   └── .config/
│       └── zed/
├── starship/                  # XDG compliant app config
│   └── .config/
│       └── starship.toml
├── ssh/
│   └── .ssh/                  # Note: Stow can handle hidden directories like .ssh
│       └── config             # But be cautious with permissions for this.
├── homebrew/
│   └── .Brewfile
├── macos/
│   └── macos_defaults.sh
└── scripts/                   # Helper scripts, not directly stowed
    └── setup.sh               # The main installation script


## 7. Installation/Setup Script

A well-crafted installation script simplifies the setup process on new machines. This script (e.g., `~/dotfiles/scripts/setup.sh`) should:

1.  **Install Homebrew** (if not already present).
    ```bash
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    ```
2.  **Install GNU Stow** (via Homebrew).
    ```bash
    brew install stow
    ```
3.  **Clone the dotfiles repository** (if not already cloned).
    ```bash
    # Assuming the script is run from the home directory or can navigate to it
    # If the repo isn't already cloned to ~/dotfiles, do so:
    if [ ! -d "$HOME/dotfiles" ]; then
        git clone git@github.com:your_username/dotfiles.git "$HOME/dotfiles"
    fi
    ```
4.  **Navigate to the dotfiles directory.**
    ```bash
    cd "$HOME/dotfiles" || exit 1
    ```
5.  **Stow selected dotfile packages.**
    ```bash
    stow zsh
    stow git
    stow nvim
    stow starship
    stow homebrew
    # Add other packages you want to universally stow
    ```
    *Self-correction:* The `ssh` package with `.ssh/config` needs special care if `~/.ssh` already exists. Stow won't overwrite existing directories. You might need to move `~/.ssh/config` first or explicitly handle it. For critical directories like `.ssh`, manual intervention or a more sophisticated setup is often preferred to avoid accidental data loss.
6.  **Run `brew bundle`.**
    ```bash
    brew bundle --file="$HOME/.Brewfile"
    ```
7.  **Execute `macos_defaults.sh`.**
    ```bash
    # Ensure the macos package is stowed or script is directly referenced
    if [ -f "$HOME/dotfiles/macos/macos_defaults.sh" ]; then
        "$HOME/dotfiles/macos/macos_defaults.sh"
    fi
    ```
8.  **Source shell configurations** (typically handled by the symlinked `.zshrc` or `.bashrc` after a new shell session).

## 8. Best Practices

*   **Commit Frequently:** Treat dotfiles like any other codebase; commit changes regularly with descriptive messages.
*   **Use Gitignore:** Add sensitive information (e.g., API keys, private SSH keys) to a `.gitignore` file within your `~/dotfiles/` repo, or use separate files that are not committed.
*   **Minimize Hardcoding:** Use environment variables or relative paths where possible.
*   **Comments:** Comment your shell scripts and configuration files for clarity.
*   **Backup Private Keys:** Your SSH keys should NOT be in your dotfiles repo. Manage them separately and securely. While `stow` can create symlinks for `.ssh/config`, ensure you understand the implications and permissions.
*   **Handle Conflicts:** If a file or directory already exists in your home directory where Stow tries to create a symlink, Stow will report an error. You'll need to manually move or delete the existing item before stowing.

## 9. Current Implementation Notes

This dotfiles repository includes a `.stowrc` configuration file for future GNU Stow usage. The current setup works with direct symlinks, but can be migrated to Stow when needed.

### Quick Stow Commands (for future use):
```bash
# Install GNU Stow
brew install stow

# From dotfiles directory, stow specific packages
stow zsh    # Would symlink shell configurations
stow ssh    # Would symlink SSH configuration

# Remove stowed packages
stow -D zsh ssh

# Restow (useful after updates)
stow -R zsh ssh
```

### Current Repository Structure:
- **Shell configs**: `zsh/` package with `dot-zshrc`, `dot-zshenv`, `dot-zprofile`
- **SSH config**: `ssh/dot-ssh/config` package structure
- **Documentation**: `spec.md`, `CLAUDE.md`, role definitions
- **Examples**: Reference implementations in `examples/`

### Package Structure (using --dotfiles mode):
```
~/dotfiles/
├── zsh/                    # Shell configuration package
│   ├── dot-zshrc          # → ~/.zshrc
│   ├── dot-zshenv         # → ~/.zshenv
│   └── dot-zprofile       # → ~/.zprofile
└── ssh/                    # SSH configuration package
    └── dot-ssh/           # → ~/.ssh/
        └── config         # → ~/.ssh/config
```

## 10. Conclusion

By following this specification and leveraging GNU Stow, you can establish a systematic and efficient way to manage your macOS dotfiles. This approach promotes modularity, keeps your home directory clean, and ensures your development environment is consistent, portable, and easily reproducible across different machines.

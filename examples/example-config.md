## Setup Methodology

### Phase 1: Core System Setup
```bash
# 1. Install Xcode Command Line Tools
xcode-select --install

# 2. Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 3. Add Homebrew to PATH (Apple Silicon Macs)
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

# 4. Update Homebrew
brew update && brew upgrade
```

### Phase 2: Essential Developer Tools
```bash
# Core development tools
brew install \
  git \
  gh \
  wget \
  curl \
  jq \
  ripgrep \
  fd \
  bat \
  eza \
  zoxide \
  fzf \
  tmux \
  neovim \
  pure \
  direnv

# Python environment management
brew install pyenv pyenv-virtualenv
curl -LsSf https://astral.sh/uv/install.sh | sh

# Install multiple Python versions
pyenv install 3.11.8
pyenv install 3.12.2
pyenv global 3.12.2
```

### Phase 3: Data Engineering Tools
```bash
# Database clients
brew install postgresql@16 mysql redis

# Data processing
brew install apache-spark kafka apache-airflow

# Cloud tools
brew install awscli azure-cli google-cloud-sdk
brew install terraform kubectl helm

# Container tools
brew install --cask docker
brew install docker-compose colima
```

### Phase 4: AI/ML Environment
```bash
# Create ML project with uv
mkdir ~/projects/ml-workspace && cd ~/projects/ml-workspace
uv init
uv python pin 3.11

# Install core ML libraries with uv
uv add numpy pandas scikit-learn matplotlib seaborn jupyterlab ipywidgets

# Install deep learning frameworks
# For Apple Silicon Macs
uv add torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
uv add tensorflow-macos tensorflow-metal
uv add jax jaxlib

# Create and activate environment
uv sync
source .venv/bin/activate

# Alternative: Global tool installations
uv tool install jupyterlab
uv tool install ipython
uv tool install ruff
uv tool install mypy
```

### Using UV for Project Management
```bash
# Create new data project
uv init my-data-project --python 3.12
cd my-data-project

# Add data engineering dependencies
uv add pandas polars duckdb pyarrow
uv add apache-airflow sqlalchemy alembic
uv add pydantic typer rich

# Add dev dependencies
uv add --dev pytest pytest-cov pytest-asyncio
uv add --dev ruff mypy pre-commit

# Lock and sync
uv lock
uv sync

# Run scripts
uv run python script.py
uv run pytest
uv run jupyter lab
```

### Phase 5: Development Applications
```bash
# IDEs and Editors
brew install --cask zed
brew install --cask pycharm
brew install --cask datagrip
brew install --cask tableau-public

# Terminal and productivity
brew install --cask ghostty
brew install --cask rectangle
brew install --cask raycast
brew install --cask obsidian
brew install --cask 1password
brew install --cask 1password-cli

# Communication and collaboration
brew install --cask slack
brew install --cask zoom
```

## Configuration Examples

### Shell Configuration (.zshrc)
```bash
# Pure prompt setup
fpath+=("$(brew --prefix)/share/zsh/site-functions")
autoload -U promptinit; promptinit
prompt pure

# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

# 1Password CLI
export OP_BIOMETRIC_UNLOCK_ENABLED=true
source <(op completion zsh)

# Pyenv
export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

# UV
export PATH="$HOME/.cargo/bin:$PATH"

# Better command replacements
alias ls='eza --icons'
alias cat='bat'
alias find='fd'
alias grep='rg'

# Zoxide (better cd)
eval "$(zoxide init zsh)"

# FZF
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Direnv
eval "$(direnv hook zsh)"

# Custom functions
mkcd() { mkdir -p "$1" && cd "$1"; }
activate() { source .venv/bin/activate 2>/dev/null || source venv/bin/activate; }

# Git account switcher
git-lument() { git config user.email "andrew.exley@lument.com"; git config user.name "Andrew Exley"; }
git-pollex() { git config user.email "andrew@pollex.com.au"; git config user.name "Andrew Exley"; }
git-personal() { git config user.email "andrew@exley.com.au"; git config user.name "Andrew Exley"; }
```

### Git Configuration
```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
git config --global init.defaultBranch main
git config --global pull.rebase true
git config --global fetch.prune true
git config --global diff.colorMoved zebra
git config --global rerere.enabled true

# Better diff
brew install git-delta
git config --global core.pager "delta"
git config --global interactive.diffFilter "delta --color-only"
```

### 1Password SSH Integration for Multiple GitHub Accounts

#### Step 1: Configure 1Password CLI
```bash
# Sign in to 1Password (will open browser for authentication)
op account add

# Enable biometric unlock
op account list
```

#### Step 2: Create SSH Keys in 1Password
1. Open 1Password 8
2. Create new items → SSH Key for each account:
   - **Lument GitHub**:
     - Title: "GitHub - Lument"
     - Add custom field: "github-account" = "Lument-AndrewExley"
   - **Pollex GitHub**:
     - Title: "GitHub - Pollex"
     - Add custom field: "github-account" = "Pollex-Andrew"
   - **Personal GitHub**:
     - Title: "GitHub - Personal"
     - Add custom field: "github-account" = "aex-gh"

#### Step 3: Configure SSH Config
```bash
# Create/edit ~/.ssh/config
cat > ~/.ssh/config << 'EOF'
# 1Password SSH Agent
Host *
  IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"

# Lument GitHub
Host gh-lument
  HostName github.com
  User git
  IdentityFile ~/.ssh/gh-lument.pub
  IdentitiesOnly yes

# Pollex GitHub
Host gh-pollex
  HostName github.com
  User git
  IdentityFile ~/.ssh/gh-pollex.pub
  IdentitiesOnly yes

# Personal GitHub
Host gh-personal
  HostName github.com
  User git
  IdentityFile ~/.ssh/gh-personal.pub
  IdentitiesOnly yes

# Default GitHub (personal)
Host gh
  HostName github.com
  User git
  IdentityFile ~/.ssh/gh-personal.pub
  IdentitiesOnly yes
EOF

# Set correct permissions
chmod 600 ~/.ssh/config
```

#### Step 4: Export Public Keys from 1Password
```bash
# Export public keys (1Password will prompt for selection)
op read "op://Private/GitHub - Lument/public key" > ~/.ssh/gh-lument.pub
op read "op://Private/GitHub - Pollex/public key" > ~/.ssh/gh-pollex.pub
op read "op://Private/GitHub - Personal/public key" > ~/.ssh/gh-personal.pub

# Set correct permissions
chmod 644 ~/.ssh/*.pub
```

#### Step 5: Add Public Keys to GitHub Accounts
```bash
# Copy each public key and add to respective GitHub accounts
cat ~/.ssh/github-lument.pub | pbcopy
echo "Add this key to https://github.com/settings/keys for Lument account"

cat ~/.ssh/github-pollex.pub | pbcopy
echo "Add this key to https://github.com/settings/keys for Pollex account"

cat ~/.ssh/github-personal.pub | pbcopy
echo "Add this key to https://github.com/settings/keys for Personal account"
```

#### Step 6: Clone Repositories with Correct Accounts
```bash
# Clone Lument repositories
git clone git@github.com-lument:Lument/repository-name.git
cd repository-name
git config user.email "andrew.exley@lument.com"
git config user.name "Andrew Exley"

# Clone Pollex repositories
git clone git@github.com-pollex:Pollex/repository-name.git
cd repository-name
git config user.email "andrew@pollex.com.au"
git config user.name "Andrew Exley"

# Clone Personal repositories
git clone git@github.com-personal:aex-gh/repository-name.git
# or just use default
git clone git@github.com:aex-gh/repository-name.git
cd repository-name
git config user.email "andrew@exley.com.au"
git config user.name "Andrew Exley"
```

#### Step 7: Configure Git Account Management
```bash
# Create git identity manager script
cat > ~/.local/bin/git-identity << 'EOF'
#!/bin/bash

case "$1" in
  lument)
    git config user.email "andrew.exley@lument.com"
    git config user.name "Andrew Exley"
    echo "Switched to Lument identity"
    ;;
  pollex)
    git config user.email "andrew@pollex.com.au"
    git config user.name "Andrew Exley"
    echo "Switched to Pollex identity"
    ;;
  personal)
    git config user.email "andrew@exley.com.au"
    git config user.name "Andrew Exley"
    echo "Switched to Personal identity"
    ;;
  *)
    echo "Usage: git-identity [lument|pollex|personal]"
    echo "Current identity:"
    git config user.email
    ;;
esac
EOF

chmod +x ~/.local/bin/git-identity

# Add to PATH if not already there
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
```

### Alternative: Using 1Password CLI for Git Commits
```bash
# Configure git to use 1Password for commit signing
git config --global user.signingkey "op://Private/GitHub - Personal/public key"
git config --global commit.gpgsign true
git config --global gpg.format ssh
git config --global gpg.ssh.program "/Applications/1Password.app/Contents/MacOS/op-ssh-sign"
```

### VS Code Extensions for Data & AI
```bash
# Install essential extensions
code --install-extension ms-python.python
code --install-extension ms-python.vscode-pylance
code --install-extension ms-toolsai.jupyter
code --install-extension ms-toolsai.jupyter-keymap
code --install-extension ms-toolsai.jupyter-renderers
code --install-extension mechatroner.rainbow-csv
code --install-extension RandomFractalsInc.vscode-data-preview
code --install-extension GrapeCity.gc-excelviewer
code --install-extension github.copilot
code --install-extension eamodio.gitlens
```

## Constraints and Guidelines
- Always verify Homebrew formula names before installation
- Check compatibility with Apple Silicon (M1/M2/M3) Macs
- Respect system security settings and user privacy
- Avoid modifying system files without explicit permission
- Provide rollback instructions for major changes
- Test commands before recommending them
- Consider both Intel and Apple Silicon architectures

## Interaction Approach
1. **System Assessment**
   - Determine Mac model and macOS version
   - Check existing installations
   - Identify specific use cases and priorities

2. **Phased Installation**
   - Start with essential tools
   - Build up to specialised software
   - Verify each phase before proceeding

3. **Configuration and Testing**
   - Configure installed tools
   - Test functionality
   - Provide troubleshooting guidance

4. **Documentation**
   - Create setup documentation
   - Note custom configurations
   - Provide maintenance guidelines

## Example Interaction Pattern
```
User: "I just got a new M3 MacBook Pro and need to set it up for data engineering and ML work"

macOS Setup Specialist: "Excellent! Let's set up your M3 MacBook Pro for data engineering and ML development. I'll guide you through a comprehensive setup optimised for Apple Silicon.

First, let's verify your system and start with the essentials:

1. **Check your macOS version**:
   ```bash
   sw_vers -productVersion
   ```

2. **Install Xcode Command Line Tools** (required for everything else):
   ```bash
   xcode-select --install
   ```
   This will pop up a dialog - click 'Install' and wait for completion (5-10 minutes).

3. **Install Homebrew** (the package manager):
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

After Homebrew installs, you'll see instructions to add it to your PATH. For M3 Macs:
   ```bash
   echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
   eval "$(/opt/homebrew/bin/brew shellenv)"
   ```

Ready to proceed with Python environments and data tools?"
```

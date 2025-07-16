# Customisation Examples

This document provides practical examples of how to customise the macOS setup automation for different use cases and preferences.

## Table of Contents

- [Basic Customisation](#basic-customisation)
- [Device-Specific Customisation](#device-specific-customisation)
- [Development Environment Customisation](#development-environment-customisation)
- [Theme and Appearance Customisation](#theme-and-appearance-customisation)
- [Security Configuration Customisation](#security-configuration-customisation)
- [Network and Remote Access Customisation](#network-and-remote-access-customisation)
- [Family Environment Customisation](#family-environment-customisation)
- [Advanced Workflow Customisation](#advanced-workflow-customisation)

## Basic Customisation

### Changing User Information

**Use Case**: Update personal information for git configuration and certificates.

**Files to Modify**:
- `dotfiles/dot_gitconfig.tmpl`
- `dotfiles/.chezmoi.toml.tmpl`

**Example**:
```toml
# In dotfiles/.chezmoi.toml.tmpl
[data]
    # Update personal information
    full_name = "Jane Smith"
    email = "jane@smith.net.au"
    timezone = "Australia/Sydney"  # Change from Adelaide
```

```ini
# In dotfiles/dot_gitconfig.tmpl
[user]
    name = Jane Smith
    email = jane@smith.net.au
    signingkey = ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINewKeyHere
```

### Customising Shell Aliases

**Use Case**: Add personal aliases and functions to zsh configuration.

**File**: `dotfiles/dot_zshrc.tmpl`

**Example**:
```bash
# Add after existing aliases
# Personal aliases
alias ll='ls -alFh'
alias grep='grep --color=auto'
alias df='df -H'
alias du='du -ch'

# Quick navigation
alias projects='cd ~/Projects'
alias work='cd ~/Work'
alias downloads='cd ~/Downloads'

# Git shortcuts
alias gst='git status'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gp='git push'
alias gl='git pull'

# Python development
alias py='python3'
alias pip='pip3'
alias venv='python3 -m venv'
alias activate='source venv/bin/activate'

# Custom functions
function mkcd() {
    mkdir -p "$1" && cd "$1"
}

function backup() {
    cp "$1"{,.backup}
}
```

### Adding Custom Homebrew Packages

**Use Case**: Include additional packages for specific workflows.

**Files**: `configs/*/Brewfile`

**Example** (Add to appropriate device Brewfile):
```ruby
# Photography workflow
cask "adobe-lightroom"
cask "capture-one"
brew "exiftool"
brew "imagemagick"

# Video editing
cask "davinci-resolve"
cask "handbrake"
brew "ffmpeg"

# Web development
brew "hugo"
brew "netlify-cli"
cask "figma"

# System monitoring
brew "htop"
brew "glances"
cask "activity-monitor"

# Database tools
brew "postgresql"
brew "redis"
cask "tableplus"
```

## Device-Specific Customisation

### Custom MacBook Pro Configuration

**Use Case**: Optimise MacBook Pro for mobile development work.

**File**: `configs/macbook-pro/Brewfile`

**Example**:
```ruby
# Mobile development
cask "xcode"
cask "android-studio"
brew "flutter"
brew "fastlane"

# Battery optimisation
cask "aldente"
cask "battery-toolkit"

# Presentation tools
cask "keynote"
cask "deckset"
cask "pdf-expert"

# VPN and security for travel
cask "tunnelblick"
cask "little-snitch"

# Backup for mobile work
cask "carbon-copy-cloner"
```

**Device-specific zsh config**:
```bash
# In dotfiles/dot_zshrc.tmpl
{{- if eq .device_type "macbook-pro" }}
# MacBook Pro specific aliases
alias battery='pmset -g batt'
alias caffeine='pmset -g assertions | grep -i preventuseridledisplay'
alias power='pmset -g powerstate'

# Mobile development
export ANDROID_HOME="$HOME/Library/Android/sdk"
export PATH="$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools"
export FLUTTER_ROOT="/opt/homebrew/bin/flutter"

# Work from anywhere setup
alias vpn-connect='sudo /usr/sbin/networksetup -connectpppoeservice "Work VPN"'
alias vpn-disconnect='sudo /usr/sbin/networksetup -disconnectpppoeservice "Work VPN"'
{{- end }}
```

### Mac Studio Server Configuration

**Use Case**: Configure Mac Studio as a home development server.

**File**: `configs/mac-studio/Brewfile`

**Example**:
```ruby
# Server applications
brew "nginx"
brew "postgresql"
brew "redis"
brew "docker"
cask "docker"

# Monitoring and management
brew "prometheus"
brew "grafana"
brew "telegraf"

# Remote management
cask "vnc-viewer"
cask "screens-connect"

# File server
cask "plex-media-server"
brew "samba"

# Development server
brew "jenkins"
brew "gitlab-runner"
```

**Network configuration**:
```bash
# In scripts/setup-network.zsh for Mac Studio
configure_static_ip() {
    info "Configuring static IP for Mac Studio..."
    
    # Custom IP configuration
    networksetup -setmanual "Ethernet" \
        "10.20.0.10" \
        "255.255.255.0" \
        "10.20.0.1"
    
    # DNS servers
    networksetup -setdnsservers "Ethernet" \
        "10.20.0.1" \
        "8.8.8.8" \
        "1.1.1.1"
    
    # Custom hostname
    sudo scutil --set HostName "dev-server"
    sudo scutil --set LocalHostName "dev-server"
    sudo scutil --set ComputerName "Development Server"
}
```

## Development Environment Customisation

### Python Data Science Setup

**Use Case**: Configure environment for data science and machine learning.

**Brewfile additions**:
```ruby
# Python data science stack
brew "python@3.11"
brew "pipenv"
brew "jupyter"
brew "numpy"
brew "scipy"
brew "matplotlib"

# Database connectors
brew "postgresql"
brew "mysql"
brew "sqlite"

# Visualization tools
cask "rstudio"
cask "tableau-public"

# Jupyter extensions
brew "pandoc"
brew "texlive"
```

**Shell configuration**:
```bash
# Data science aliases and functions
alias jlab='jupyter lab'
alias jnb='jupyter notebook'
alias python='python3'
alias pip='pip3'

# Virtual environment helpers
function create-ds-env() {
    python3 -m venv ds-env
    source ds-env/bin/activate
    pip install pandas numpy matplotlib seaborn scikit-learn jupyter
}

# Database shortcuts
alias pgstart='brew services start postgresql'
alias pgstop='brew services stop postgresql'
alias redisstart='brew services start redis'
alias redisstop='brew services stop redis'

# Environment variables
export PYTHONPATH="$HOME/Projects/python:$PYTHONPATH"
export JUPYTER_CONFIG_DIR="$HOME/.jupyter"
```

### Web Development Setup

**Use Case**: Full-stack web development environment.

**Brewfile additions**:
```ruby
# Node.js and package managers
brew "node"
brew "npm"
brew "yarn"
brew "pnpm"

# Build tools
brew "webpack"
brew "gulp-cli"
brew "typescript"

# Databases
brew "mongodb-community"
brew "postgresql"
cask "redis"

# Development tools
cask "insomnia"
cask "docker"
cask "github-desktop"

# Design tools
cask "figma"
cask "sketch"
```

**Development aliases**:
```bash
# Node.js development
alias ni='npm install'
alias ns='npm start'
alias nt='npm test'
alias nb='npm run build'
alias nrd='npm run dev'

# Package manager shortcuts
alias yi='yarn install'
alias ys='yarn start'
alias ya='yarn add'
alias yad='yarn add --dev'

# Docker shortcuts
alias dps='docker ps'
alias dpa='docker ps -a'
alias di='docker images'
alias dcu='docker-compose up'
alias dcd='docker-compose down'

# Git workflow
alias gaa='git add .'
alias gcm='git commit -m'
alias gpf='git push --force-with-lease'
alias gpr='gh pr create'
```

## Theme and Appearance Customisation

### Alternative Color Schemes

**Use Case**: Use a different color scheme instead of Gruvbox.

**Create custom theme script** (`scripts/setup-theme-custom.zsh`):
```bash
#!/usr/bin/env zsh
# Custom theme setup

# Nord theme colors
export NORD_BG="#2e3440"
export NORD_FG="#d8dee9"
export NORD_ACCENT="#88c0d0"

configure_nord_theme() {
    info "Applying Nord theme..."
    
    # System appearance
    defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"
    defaults write NSGlobalDomain AppleAccentColor -int 4  # Blue
    
    # Terminal configuration
    # (Create custom terminal profile)
    
    # Update dotfiles to use Nord colors
    # (Modify zsh and other configs)
}
```

**Update zsh configuration**:
```bash
# In dotfiles/dot_zshrc.tmpl
{{- if eq .theme "nord" }}
# Nord theme colours
export NORD_BG="#2e3440"
export NORD_FG="#d8dee9"
export NORD_RED="#bf616a"
export NORD_GREEN="#a3be8c"
export NORD_YELLOW="#ebcb8b"
export NORD_BLUE="#81a1c1"

# FZF Nord theme
export FZF_DEFAULT_OPTS="
    --color=bg+:$NORD_BG,bg:$NORD_BG,spinner:$NORD_RED,hl:$NORD_RED
    --color=fg:$NORD_FG,header:$NORD_RED,info:$NORD_BLUE,pointer:$NORD_RED
    --layout=reverse --border
"
{{- end }}
```

### Custom Font Configuration

**Use Case**: Use a different font family system-wide.

**Create font installation script**:
```bash
#!/usr/bin/env zsh
# Custom font setup

install_jetbrains_mono() {
    info "Installing JetBrains Mono font..."
    
    # Download and install
    local font_url="https://github.com/JetBrains/JetBrainsMono/releases/latest/download/JetBrainsMono.zip"
    local temp_dir=$(mktemp -d)
    
    curl -L -o "${temp_dir}/JetBrainsMono.zip" "${font_url}"
    unzip "${temp_dir}/JetBrainsMono.zip" -d "${temp_dir}"
    
    # Install fonts
    cp "${temp_dir}/fonts/ttf/"*.ttf "${HOME}/Library/Fonts/"
    
    success "JetBrains Mono installed"
}
```

**Update application configurations**:
```json
// In dotfiles/private_dot_config/zed/settings.json.tmpl
{
  "buffer_font_family": "JetBrains Mono",
  "ui_font_family": "JetBrains Mono",
  "buffer_font_size": 14,
  "terminal": {
    "font_family": "JetBrains Mono",
    "font_size": 13
  }
}
```

## Security Configuration Customisation

### Enhanced Security Setup

**Use Case**: Implement additional security measures for sensitive work.

**Create enhanced security script**:
```bash
#!/usr/bin/env zsh
# Enhanced security configuration

configure_enhanced_security() {
    info "Applying enhanced security settings..."
    
    # Stricter firewall rules
    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setblockall on
    
    # Disable unnecessary services
    sudo launchctl disable system/com.apple.screensharing
    sudo launchctl disable system/com.apple.RemoteDesktop
    
    # Enhanced privacy settings
    defaults write com.apple.Safari SendDoNotTrackHTTPHeader -bool true
    defaults write com.apple.Safari WebKitDNTPrefetchingEnabled -bool false
    
    # Secure sleep settings
    sudo pmset -a hibernatemode 25
    sudo pmset -a sleep 10
    
    # Require password immediately after sleep
    defaults write com.apple.screensaver askForPassword -int 1
    defaults write com.apple.screensaver askForPasswordDelay -int 0
}

configure_corporate_security() {
    info "Applying corporate security policies..."
    
    # Certificate management
    # (Install corporate certificates)
    
    # VPN configuration
    # (Configure corporate VPN)
    
    # Device management
    # (Configure MDM if required)
}
```

### Custom Firewall Rules

**Use Case**: Configure specific firewall rules for development servers.

**Device-specific firewall configuration**:
```bash
# In scripts/setup-firewall.zsh
configure_development_firewall() {
    local device_type="$1"
    
    case "${device_type}" in
        "mac-studio")
            # Allow development servers
            sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add /usr/local/bin/node
            sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add /opt/homebrew/bin/nginx
            
            # Allow specific ports
            # (Configure pf rules for specific ports)
            ;;
        "macbook-pro")
            # Stricter rules for mobile device
            sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setblockall on
            
            # Only allow essential services
            ;;
    esac
}
```

## Network and Remote Access Customisation

### Custom Network Configuration

**Use Case**: Different network setup for home office vs corporate environment.

**Environment-specific network script**:
```bash
#!/usr/bin/env zsh
# Environment-specific network configuration

detect_network_environment() {
    local ssid=$(networksetup -getairportnetwork en0 | cut -d: -f2)
    
    case "${ssid}" in
        *"HomeOffice"*)
            configure_home_network
            ;;
        *"Corporate"*)
            configure_corporate_network
            ;;
        *)
            configure_default_network
            ;;
    esac
}

configure_home_network() {
    info "Configuring for home office network..."
    
    # Set DNS to home router + cloudflare
    networksetup -setdnsservers "Wi-Fi" "192.168.1.1" "1.1.1.1"
    
    # Enable file sharing
    sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.AppleFileServer.plist
}

configure_corporate_network() {
    info "Configuring for corporate network..."
    
    # Use corporate DNS
    networksetup -setdnsservers "Wi-Fi" "10.0.0.1" "10.0.0.2"
    
    # Disable file sharing
    sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.AppleFileServer.plist
    
    # Configure proxy if needed
    networksetup -setwebproxy "Wi-Fi" "proxy.company.com" 8080
}
```

### Remote Access Customisation

**Use Case**: Different remote access needs for different devices.

**Custom remote access script**:
```bash
configure_remote_access() {
    local device_type="$1"
    
    case "${device_type}" in
        "mac-studio")
            # Headless server setup
            configure_vnc_server
            configure_ssh_server
            setup_remote_monitoring
            ;;
        "macbook-pro")
            # Mobile device setup
            configure_back_to_my_mac
            setup_find_my_mac
            ;;
    esac
}

configure_vnc_server() {
    info "Configuring VNC server for headless operation..."
    
    # Enable screen sharing
    sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.screensharing.plist
    
    # Set VNC password (from 1Password)
    local vnc_password
    vnc_password=$(op read "op://Personal/VNC-Password/password")
    
    # Configure VNC settings
    sudo defaults write /var/db/launchd.db/com.apple.launchd/overrides.plist \
        com.apple.screensharing -dict Disabled -bool false
}
```

## Family Environment Customisation

### Multi-User Setup

**Use Case**: Customise user accounts for different family members.

**Enhanced user setup script**:
```bash
#!/usr/bin/env zsh
# Family-specific user configuration

create_family_users() {
    local users=(
        "ali:Ali Exley:admin"
        "amelia:Amelia Exley:standard"
        "annabelle:Annabelle Exley:standard"
    )
    
    for user_info in "${users[@]}"; do
        IFS=':' read -r username fullname usertype <<< "${user_info}"
        create_user_account "${username}" "${fullname}" "${usertype}"
        configure_user_environment "${username}" "${usertype}"
    done
}

configure_user_environment() {
    local username="$1"
    local usertype="$2"
    
    case "${username}" in
        "ali")
            # Adult user - full access
            configure_adult_user "${username}"
            ;;
        "amelia"|"annabelle")
            # Child users - restricted access
            configure_child_user "${username}"
            ;;
    esac
}

configure_child_user() {
    local username="$1"
    
    # Parental controls
    sudo dscl . create "/Users/${username}" ParentalControls 1
    
    # Time restrictions
    # (Configure screen time limits)
    
    # App restrictions
    # (Configure allowed applications)
    
    # Web filtering
    # (Configure content filters)
}
```

### Shared Resources Configuration

**Use Case**: Set up shared directories and resources for family.

**Shared resources script**:
```bash
configure_shared_resources() {
    info "Setting up shared family resources..."
    
    # Create shared directories
    local shared_dirs=(
        "/Users/Shared/Family Photos"
        "/Users/Shared/Family Documents"
        "/Users/Shared/Projects"
        "/Users/Shared/Media"
    )
    
    for dir in "${shared_dirs[@]}"; do
        sudo mkdir -p "${dir}"
        sudo chown :staff "${dir}"
        sudo chmod 775 "${dir}"
    done
    
    # Configure Time Machine for all users
    configure_family_backups
    
    # Set up media server
    configure_plex_server
}

configure_family_backups() {
    info "Configuring family backup strategy..."
    
    # Enable Time Machine for all users
    sudo defaults write /Library/Preferences/com.apple.TimeMachine \
        IncludeByPath -array-add "/Users"
    
    # Exclude unnecessary directories
    sudo defaults write /Library/Preferences/com.apple.TimeMachine \
        SkipPaths -array-add "/Users/*/Downloads"
}
```

## Advanced Workflow Customisation

### Development Workflow Integration

**Use Case**: Integrate with specific development workflows and tools.

**Create workflow-specific setup**:
```bash
#!/usr/bin/env zsh
# Development workflow customisation

setup_ci_cd_workflow() {
    info "Setting up CI/CD development workflow..."
    
    # Install workflow tools
    brew install gh                # GitHub CLI
    brew install gitlab-ci-local   # GitLab CI testing
    brew install act              # GitHub Actions locally
    
    # Configure environment
    setup_github_workflow
    setup_docker_workflow
    setup_testing_workflow
}

setup_github_workflow() {
    # GitHub CLI configuration
    gh auth login
    
    # Set up templates
    mkdir -p ~/.config/gh
    cat > ~/.config/gh/config.yml << 'EOF'
git_protocol: ssh
editor: zed
prompt: enabled
pager: bat
EOF
    
    # Create workflow templates
    mkdir -p ~/Templates/github-workflows
    # (Copy workflow templates)
}

setup_docker_workflow() {
    # Docker development environment
    docker run hello-world  # Test installation
    
    # Create common docker-compose templates
    mkdir -p ~/Templates/docker-compose
    # (Copy docker-compose templates)
    
    # Set up development containers
    # (Configure dev container templates)
}
```

### Automation Integration

**Use Case**: Integrate with external automation systems.

**Create automation integrations**:
```bash
setup_automation_integration() {
    info "Setting up automation integrations..."
    
    # Zapier CLI
    npm install -g zapier-platform-cli
    
    # Home automation
    brew install homebridge
    
    # Webhook endpoints
    setup_webhook_server
    
    # Monitoring integration
    setup_monitoring_hooks
}

setup_webhook_server() {
    # Simple webhook server for automation
    cat > ~/bin/webhook-server << 'EOF'
#!/usr/bin/env python3
import http.server
import socketserver
import json
import subprocess

class WebhookHandler(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        # Handle webhook requests
        content_length = int(self.headers['Content-Length'])
        post_data = self.rfile.read(content_length)
        
        try:
            data = json.loads(post_data)
            self.handle_webhook(data)
            self.send_response(200)
        except:
            self.send_response(400)
        
        self.end_headers()
    
    def handle_webhook(self, data):
        # Process webhook data
        # Run automation scripts based on webhook content
        pass

if __name__ == "__main__":
    PORT = 8080
    with socketserver.TCPServer(("", PORT), WebhookHandler) as httpd:
        print(f"Webhook server running on port {PORT}")
        httpd.serve_forever()
EOF
    
    chmod +x ~/bin/webhook-server
}
```

This customisation guide provides practical examples for adapting the macOS setup to various needs and preferences. Each example can be further modified and combined to create the perfect setup for your specific requirements.
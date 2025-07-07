# macOS specific login items

# Homebrew (only needed once per login)
if [[ -f "/opt/homebrew/bin/brew" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# SSH agent (if not already running)
if [ -z "$SSH_AUTH_SOCK" ]; then
  eval "$(ssh-agent -s)"
  ssh-add --apple-use-keychain ~/.ssh/id_ed25519 2>/dev/null
fi

# macOS with Homebrew
echo "Checking for Homebrew updates..."
brew update --auto-update &> /dev/null

# Set macOS defaults (only on login)
# Faster key repeat
defaults write NSGlobalDomain KeyRepeat -int 5
defaults write NSGlobalDomain InitialKeyRepeat -int 10


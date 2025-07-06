# macOS specific login items

# Homebrew (only needed once per login)
if [[ -f "/opt/homebrew/bin/brew" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# SSH agent (if not already running)
if [ -z "$SSH_AUTH_SOCK" ]; then
  eval "$(ssh-agent -s)"
  # Try multiple common key names
  for key in ~/.ssh/id_{ed25519,rsa,ecdsa}; do
    [[ -f "$key" ]] && ssh-add --apple-use-keychain "$key" 2>/dev/null
  done
fi

# Set macOS defaults (only on login)
# Faster key repeat
defaults write NSGlobalDomain KeyRepeat -int 1
defaults write NSGlobalDomain InitialKeyRepeat -int 10

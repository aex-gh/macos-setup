#!/usr/bin/env zsh
# ~/.zlogin - Executed for login shells after .zshrc
# This file is sourced only for login shells, making it ideal for:
# - Starting background services
# - Displaying system information
# - Running commands that should only execute once per login

# Source any machine-specific login configurations
if [[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/zlogin.local" ]]; then
source "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/zlogin.local"
fi

# Start ssh-agent if not already running
if [[ -z "$SSH_AUTH_SOCK" ]]; then
eval "$(ssh-agent -s)" > /dev/null 2>&1
fi

# Clear any completed background jobs
jobs -l 2> /dev/null | grep -E "Done|Exit" > /dev/null && jobs -l

#Custom welcome message
echo "Welcome to $(hostname), $USER!"
echo "Current time: $(date '+%Y-%m-%d %H:%M:%S')"
fortune

# Universal environment variables
export EDITOR='zed --wait'
export VISUAL='zed --wait'

# XDG Base Directories
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"

# Python/uv
export UV_CACHE_DIR="$XDG_CACHE_HOME/uv"
export UV_TOOL_DIR="$XDG_DATA_HOME/uv/tools"
export UV_TOOL_BIN_DIR="$HOME/.local/bin"

# Ensure local bin is in PATH
export PATH="$HOME/.local/bin:$PATH"

# FZF defaults (used by scripts too)
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'

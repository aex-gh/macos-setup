#!/usr/bin/env zsh
# /etc/zprofile - System-wide settings for login shells
# This file is sourced before ~/.zprofile
# Keep this minimal and focused on system-wide needs

# System-wide path additions
# Note: User paths should be added in ~/.zshenv
typeset -U path

# Add system administration directories if they exist
for dir in /usr/local/sbin /usr/sbin /sbin; do
    [[ -d "$dir" ]] && path=("$dir" $path)
done

# Set umask for security
# 022 - Group and others can read but not write
# 027 - Group can read but not write, others have no permissions
umask 022

# System-wide locale settings (can be overridden in user config)
export LANG="${LANG:-en_US.UTF-8}"

# Terminal settings
# Set terminal type if not set
if [[ -z "$TERM" ]]; then
    export TERM="xterm-256color"
fi

# System-wide temporary directory settings
export TMPDIR="${TMPDIR:-/tmp}"

# macOS specific system settings
if [[ "$OSTYPE" == "darwin"* ]]; then
    # Ensure /usr/local/bin is in path for Intel Macs
    [[ -d "/usr/local/bin" ]] && path=("/usr/local/bin" $path)
    
    # Enable color ls on macOS
    export CLICOLOR=1
    export LSCOLORS="ExGxBxDxCxEgEdxbxgxcxd"
fi

# Linux specific system settings
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Enable color support for various commands
    if [[ -x /usr/bin/dircolors ]]; then
        test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    fi
    
    # Set default system editor fallbacks
    for editor in nvim vim vi nano; do
        if command -v $editor &> /dev/null; then
            export SYSTEMD_EDITOR="$editor"
            break
        fi
    done
fi

# Security: Prevent unauthorized ptrace
if [[ "$OSTYPE" == "linux-gnu"* ]] && [[ -f /proc/sys/kernel/yama/ptrace_scope ]]; then
    # This is typically set in sysctl, but mentioned here for awareness
    : # kernel.yama.ptrace_scope = 1
fi

# Export the final PATH
export PATH
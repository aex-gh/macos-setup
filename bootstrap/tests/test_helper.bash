#!/usr/bin/env bash
# -*- coding: utf-8 -*-

#=============================================================================
# SCRIPT: test_helper.bash
# AUTHOR: Andrew Exley (with Claude)
# DATE: 2025-01-07
# VERSION: 1.0.0
#
# DESCRIPTION:
#   Test helper functions and utilities for BATS testing framework.
#   Provides common setup, teardown, and utility functions for testing
#   the dotfiles setup system.
#
# USAGE:
#   load 'test_helper' (from within BATS test files)
#
# REQUIREMENTS:
#   - BATS (Bash Automated Testing System)
#   - macOS testing environment
#   - Standard Unix utilities
#
# NOTES:
#   - Sets up isolated testing environments
#   - Provides mock functions for system commands
#   - Includes utility functions for common test patterns
#=============================================================================

# Determine dotfiles root directory
if [[ -z "$DOTFILES_ROOT" ]]; then
    export DOTFILES_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi

# Test environment variables
export BATS_TEST_SKIPPED=""
export TEST_TEMP_DIR=""
export TEST_HOMEBREW_PREFIX=""

#=============================================================================
# SETUP AND TEARDOWN HELPERS
#=============================================================================

# Common setup for all tests
common_setup() {
    # Create isolated test environment
    export TEST_TEMP_DIR="$(mktemp -d)"
    export HOME="$TEST_TEMP_DIR/home"
    export XDG_CONFIG_HOME="$HOME/.config"
    
    # Create basic directory structure
    mkdir -p "$HOME"/{.config,.local/bin,.ssh}
    mkdir -p "$TEST_TEMP_DIR/opt/homebrew/bin"
    
    # Mock Homebrew environment
    export HOMEBREW_PREFIX="$TEST_TEMP_DIR/opt/homebrew"
    export PATH="$HOMEBREW_PREFIX/bin:$PATH"
    
    # Set up test-specific shell environment
    export SHELL="/bin/zsh"
    export ZSH_VERSION="5.8"
    
    # Prevent actual system modifications
    export BATS_TESTING=true
}

# Common teardown for all tests
common_teardown() {
    # Clean up test environment
    if [[ -n "$TEST_TEMP_DIR" && -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
    
    # Reset environment variables
    unset TEST_TEMP_DIR
    unset BATS_TESTING
}

#=============================================================================
# MOCK FUNCTIONS
#=============================================================================

# Mock Homebrew commands
mock_brew() {
    local command="$1"
    shift
    
    case "$command" in
        "list")
            case "$1" in
                "--formula")
                    echo "git"
                    echo "jq"
                    echo "node"
                    ;;
                "--cask")
                    echo "visual-studio-code"
                    echo "firefox"
                    ;;
                *)
                    echo "git"
                    echo "jq"
                    echo "visual-studio-code"
                    ;;
            esac
            ;;
        "install")
            echo "Installing: $*"
            # Create fake installation markers
            for package in "$@"; do
                touch "$HOMEBREW_PREFIX/installed_$package"
            done
            ;;
        "bundle")
            if [[ "$1" == "--file="* ]]; then
                local brewfile="${1#--file=}"
                echo "Installing from Brewfile: $brewfile"
                [[ -f "$brewfile" ]] && echo "Brewfile exists" || echo "Brewfile not found"
            fi
            ;;
        "update")
            echo "Updated Homebrew"
            ;;
        "upgrade")
            echo "Upgraded packages"
            ;;
        *)
            echo "Unknown brew command: $command"
            return 1
            ;;
    esac
}

# Mock system commands
mock_defaults() {
    local action="$1"
    local domain="$2"
    local key="$3"
    
    case "$action" in
        "read")
            # Return fake values for testing
            case "$domain.$key" in
                "com.apple.dock.tilesize")
                    echo "64"
                    ;;
                "com.apple.finder.ShowPathbar")
                    echo "1"
                    ;;
                *)
                    echo "test_value"
                    ;;
            esac
            ;;
        "write")
            echo "Would write: $domain $key = $4"
            ;;
        *)
            echo "Unknown defaults action: $action"
            return 1
            ;;
    esac
}

# Mock launchctl
mock_launchctl() {
    local action="$1"
    local target="$2"
    
    case "$action" in
        "list")
            echo "com.apple.test.service"
            echo "com.example.daemon"
            ;;
        "load"|"unload"|"enable"|"disable")
            echo "$action: $target"
            ;;
        *)
            echo "Unknown launchctl action: $action"
            return 1
            ;;
    esac
}

# Mock system_profiler
mock_system_profiler() {
    case "$1" in
        "SPHardwareDataType")
            cat << EOF
Hardware:

    Hardware Overview:

      Model Name: MacBook Pro
      Model Identifier: MacBookPro18,1
      Chip: Apple M1 Pro
      Total Number of Cores: 10 (8 performance and 2 efficiency)
      Memory: 32 GB
      System Firmware Version: 8419.80.7
      OS Loader Version: 8419.80.7
      Serial Number (system): TEST123456789
      Hardware UUID: 12345678-1234-1234-1234-123456789ABC
      Provisioning UDID: 12345678-1234-1234-1234-123456789ABC
      Activation Lock Status: Disabled
EOF
            ;;
        *)
            echo "Unknown system_profiler data type: $1"
            return 1
            ;;
    esac
}

# Mock sw_vers
mock_sw_vers() {
    case "$1" in
        "-productVersion")
            echo "13.0"
            ;;
        "-buildVersion")
            echo "22A123"
            ;;
        *)
            cat << EOF
ProductName:	macOS
ProductVersion:	13.0
BuildVersion:	22A123
EOF
            ;;
    esac
}

# Mock df command
mock_df() {
    case "$1" in
        "-g")
            echo "Filesystem     1G-blocks  Used Available Capacity  iused      ifree %iused  Mounted on"
            echo "/dev/disk1s1         500   250       250      50%  1234567  1234567    50%   /"
            ;;
        *)
            echo "Filesystem     1K-blocks      Used Available Capacity  iused      ifree %iused  Mounted on"
            echo "/dev/disk1s1   524288000 262144000 262144000      50%  1234567  1234567    50%   /"
            ;;
    esac
}

#=============================================================================
# UTILITY FUNCTIONS
#=============================================================================

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Skip test if command is not available
require_command() {
    local cmd="$1"
    local reason="${2:-Command '$cmd' not available}"
    
    if ! command_exists "$cmd"; then
        skip "$reason"
    fi
}

# Skip test on non-macOS systems
require_macos() {
    if [[ "$(uname)" != "Darwin" ]]; then
        skip "This test requires macOS"
    fi
}

# Create a temporary file with specific content
create_temp_file() {
    local content="$1"
    local filename="$2"
    local filepath="${3:-$TEST_TEMP_DIR}"
    
    local full_path="$filepath/$filename"
    echo "$content" > "$full_path"
    echo "$full_path"
}

# Create a test Brewfile
create_test_brewfile() {
    local brewfile_path="${1:-$TEST_TEMP_DIR/Brewfile}"
    
    cat > "$brewfile_path" << 'EOF'
tap "homebrew/core"
tap "homebrew/cask"

# Essential CLI tools
brew "git"
brew "jq"
brew "ripgrep"
brew "fzf"

# Development tools
brew "node"
brew "python@3.11"
brew "go"

# GUI applications
cask "visual-studio-code"
cask "firefox"
cask "rectangle"

# Mac App Store apps
mas "Xcode", id: 497799835
mas "1Password 7", id: 1333542190
EOF
    
    echo "$brewfile_path"
}

# Assert file exists
assert_file_exists() {
    local file="$1"
    local message="${2:-File $file should exist}"
    
    if [[ ! -f "$file" ]]; then
        echo "$message" >&2
        return 1
    fi
}

# Assert file does not exist
assert_file_not_exists() {
    local file="$1"
    local message="${2:-File $file should not exist}"
    
    if [[ -f "$file" ]]; then
        echo "$message" >&2
        return 1
    fi
}

# Assert directory exists
assert_dir_exists() {
    local dir="$1"
    local message="${2:-Directory $dir should exist}"
    
    if [[ ! -d "$dir" ]]; then
        echo "$message" >&2
        return 1
    fi
}

# Assert string contains substring
assert_contains() {
    local string="$1"
    local substring="$2"
    local message="${3:-String should contain '$substring'}"
    
    if [[ "$string" != *"$substring"* ]]; then
        echo "$message" >&2
        echo "String: $string" >&2
        echo "Expected to contain: $substring" >&2
        return 1
    fi
}

# Assert JSON structure is valid
assert_valid_json() {
    local file="$1"
    local message="${2:-File $file should contain valid JSON}"
    
    if ! jq . "$file" >/dev/null 2>&1; then
        echo "$message" >&2
        return 1
    fi
}

# Assert JSON path exists
assert_json_path() {
    local file="$1"
    local path="$2"
    local message="${3:-JSON path '$path' should exist in $file}"
    
    if ! jq -e "$path" "$file" >/dev/null 2>&1; then
        echo "$message" >&2
        return 1
    fi
}

# Get JSON value from file
get_json_value() {
    local file="$1"
    local path="$2"
    
    jq -r "$path" "$file" 2>/dev/null
}

#=============================================================================
# TEST ENVIRONMENT SETUP
#=============================================================================

# Set up mock environment for testing
setup_mock_environment() {
    # Replace system commands with mocks
    export -f mock_brew mock_defaults mock_launchctl
    export -f mock_system_profiler mock_sw_vers mock_df
    
    # Create mock binaries in test PATH
    mkdir -p "$TEST_TEMP_DIR/bin"
    export PATH="$TEST_TEMP_DIR/bin:$PATH"
    
    # Create mock brew
    cat > "$TEST_TEMP_DIR/bin/brew" << 'EOF'
#!/bin/bash
source test_helper.bash
mock_brew "$@"
EOF
    chmod +x "$TEST_TEMP_DIR/bin/brew"
    
    # Create mock defaults
    cat > "$TEST_TEMP_DIR/bin/defaults" << 'EOF'
#!/bin/bash
source test_helper.bash
mock_defaults "$@"
EOF
    chmod +x "$TEST_TEMP_DIR/bin/defaults"
    
    # Create mock system commands
    for cmd in launchctl system_profiler sw_vers df; do
        cat > "$TEST_TEMP_DIR/bin/$cmd" << EOF
#!/bin/bash
source test_helper.bash
mock_$cmd "\$@"
EOF
        chmod +x "$TEST_TEMP_DIR/bin/$cmd"
    done
}

# Restore real environment
restore_real_environment() {
    # Remove mock binaries from PATH
    export PATH="${PATH#$TEST_TEMP_DIR/bin:}"
    
    # Unset mock functions
    unset -f mock_brew mock_defaults mock_launchctl
    unset -f mock_system_profiler mock_sw_vers mock_df
}

#=============================================================================
# PERFORMANCE TESTING UTILITIES
#=============================================================================

# Time a command execution
time_command() {
    local start_time=$(date +%s.%N)
    "$@"
    local end_time=$(date +%s.%N)
    local duration=$(echo "$end_time - $start_time" | bc)
    echo "Command took: ${duration}s" >&2
    return $?
}

# Assert command completes within time limit
assert_completes_within() {
    local time_limit="$1"
    shift
    local cmd=("$@")
    
    local start_time=$(date +%s.%N)
    "${cmd[@]}"
    local end_time=$(date +%s.%N)
    local duration=$(echo "$end_time - $start_time" | bc)
    
    if (( $(echo "$duration > $time_limit" | bc -l) )); then
        echo "Command took ${duration}s, expected < ${time_limit}s" >&2
        return 1
    fi
}

#=============================================================================
# DEBUGGING UTILITIES
#=============================================================================

# Print debug information
debug_info() {
    echo "=== DEBUG INFO ===" >&2
    echo "TEST_TEMP_DIR: $TEST_TEMP_DIR" >&2
    echo "HOME: $HOME" >&2
    echo "PATH: $PATH" >&2
    echo "PWD: $PWD" >&2
    echo "DOTFILES_ROOT: $DOTFILES_ROOT" >&2
    echo "=================" >&2
}

# Print file tree for debugging
debug_tree() {
    local path="${1:-$TEST_TEMP_DIR}"
    echo "=== DIRECTORY TREE: $path ===" >&2
    if command -v tree >/dev/null 2>&1; then
        tree "$path" >&2
    else
        find "$path" -type f -exec echo "  {}" \; >&2
    fi
    echo "========================" >&2
}
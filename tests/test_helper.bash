#!/usr/bin/env bash
# BATS test helper functions for macOS setup scripts

# Test environment setup
export TEST_TEMP_DIR=""
export TEST_HOME_DIR=""
export TEST_SCRIPTS_DIR=""

# Mock directories for testing
setup_test_environment() {
    TEST_TEMP_DIR="$(mktemp -d)"
    TEST_HOME_DIR="${TEST_TEMP_DIR}/home"
    TEST_SCRIPTS_DIR="${BATS_TEST_DIRNAME}/../scripts"
    
    mkdir -p "${TEST_HOME_DIR}"
    mkdir -p "${TEST_HOME_DIR}/.config"
    mkdir -p "${TEST_HOME_DIR}/.local/bin"
    mkdir -p "${TEST_HOME_DIR}/Library/Preferences"
    
    # Set up PATH for tests
    export PATH="${TEST_HOME_DIR}/.local/bin:${PATH}"
    export HOME="${TEST_HOME_DIR}"
}

teardown_test_environment() {
    if [[ -n "${TEST_TEMP_DIR}" ]] && [[ -d "${TEST_TEMP_DIR}" ]]; then
        rm -rf "${TEST_TEMP_DIR}"
    fi
}

# Mock command helpers
create_mock_command() {
    local command_name="$1"
    local exit_code="${2:-0}"
    local output="${3:-}"
    
    cat > "${TEST_HOME_DIR}/.local/bin/${command_name}" << EOF
#!/usr/bin/env bash
echo "${output}"
exit ${exit_code}
EOF
    chmod +x "${TEST_HOME_DIR}/.local/bin/${command_name}"
}

create_brew_mock() {
    local subcommand="$1"
    local exit_code="${2:-0}"
    local output="${3:-OK}"
    
    cat > "${TEST_HOME_DIR}/.local/bin/brew" << EOF
#!/usr/bin/env bash
case "\$1" in
    "${subcommand}")
        echo "${output}"
        exit ${exit_code}
        ;;
    *)
        echo "brew \$1 not mocked"
        exit 1
        ;;
esac
EOF
    chmod +x "${TEST_HOME_DIR}/.local/bin/brew"
}

# File creation helpers
create_test_file() {
    local file_path="$1"
    local content="${2:-test content}"
    
    mkdir -p "$(dirname "${file_path}")"
    echo "${content}" > "${file_path}"
}

create_test_brewfile() {
    local brewfile_path="$1"
    
    cat > "${brewfile_path}" << 'EOF'
# Core development tools
brew "git"
brew "zsh"
brew "curl"

# Development languages
brew "node"
brew "python@3.11"

# Applications
cask "1password"
cask "zed"

# Mac App Store
mas "Xcode", id: 497799835
EOF
}

# Assertion helpers
assert_file_exists() {
    local file_path="$1"
    [[ -f "${file_path}" ]] || {
        echo "Expected file to exist: ${file_path}"
        return 1
    }
}

assert_directory_exists() {
    local dir_path="$1"
    [[ -d "${dir_path}" ]] || {
        echo "Expected directory to exist: ${dir_path}"
        return 1
    }
}

assert_file_contains() {
    local file_path="$1"
    local expected_content="$2"
    
    assert_file_exists "${file_path}"
    grep -q "${expected_content}" "${file_path}" || {
        echo "Expected file ${file_path} to contain: ${expected_content}"
        echo "Actual content:"
        cat "${file_path}"
        return 1
    }
}

assert_command_exists() {
    local command_name="$1"
    command -v "${command_name}" >/dev/null 2>&1 || {
        echo "Expected command to exist: ${command_name}"
        return 1
    }
}

assert_script_succeeds() {
    local script_path="$1"
    shift
    
    run "${script_path}" "$@"
    [[ "${status}" -eq 0 ]] || {
        echo "Expected script to succeed: ${script_path}"
        echo "Exit code: ${status}"
        echo "Output: ${output}"
        return 1
    }
}

assert_script_fails() {
    local script_path="$1"
    shift
    
    run "${script_path}" "$@"
    [[ "${status}" -ne 0 ]] || {
        echo "Expected script to fail: ${script_path}"
        echo "Output: ${output}"
        return 1
    }
}

# Device detection helpers
mock_macbook_pro() {
    create_mock_command "hostname" 0 "Andrews-MacBook-Pro.local"
    create_mock_command "system_profiler" 0 "Model Name: MacBook Pro"
}

mock_mac_studio() {
    create_mock_command "hostname" 0 "mac-studio.local"
    create_mock_command "system_profiler" 0 "Model Name: Mac Studio"
}

mock_mac_mini() {
    create_mock_command "hostname" 0 "mac-mini.local"
    create_mock_command "system_profiler" 0 "Model Name: Mac mini"
}

# macOS version helpers
mock_macos_version() {
    local version="$1"
    local build="$2"
    
    cat > "${TEST_HOME_DIR}/.local/bin/sw_vers" << EOF
#!/usr/bin/env bash
case "\$1" in
    "-productVersion")
        echo "${version}"
        ;;
    "-buildVersion")
        echo "${build}"
        ;;
    *)
        echo "ProductName: macOS"
        echo "ProductVersion: ${version}"
        echo "BuildVersion: ${build}"
        ;;
esac
EOF
    chmod +x "${TEST_HOME_DIR}/.local/bin/sw_vers"
}

# 1Password CLI mock
create_op_mock() {
    cat > "${TEST_HOME_DIR}/.local/bin/op" << 'EOF'
#!/usr/bin/env bash
case "$1" in
    "account")
        case "$2" in
            "list")
                echo "test-account"
                ;;
        esac
        ;;
    "read")
        case "$2" in
            "op://Personal/test-item/password")
                echo "test-password"
                ;;
            "op://Personal/Anthropic-API-Key/credential")
                echo "sk-test-key"
                ;;
        esac
        ;;
    "item")
        case "$2" in
            "create"|"get")
                echo "test-item-id"
                ;;
        esac
        ;;
    *)
        echo "op command not mocked: $*"
        exit 1
        ;;
esac
EOF
    chmod +x "${TEST_HOME_DIR}/.local/bin/op"
}

# Git configuration helpers
setup_git_mock() {
    cat > "${TEST_HOME_DIR}/.local/bin/git" << 'EOF'
#!/usr/bin/env bash
case "$1" in
    "config")
        # Just echo the config command for verification
        echo "git config $*"
        ;;
    "init")
        mkdir -p .git
        echo "Initialized empty Git repository"
        ;;
    "add"|"commit"|"push"|"pull")
        echo "git $1 executed"
        ;;
    "--version")
        echo "git version 2.39.0"
        ;;
    *)
        echo "git command not mocked: $*"
        exit 1
        ;;
esac
EOF
    chmod +x "${TEST_HOME_DIR}/.local/bin/git"
}

# Homebrew test helpers
setup_homebrew_mock() {
    cat > "${TEST_HOME_DIR}/.local/bin/brew" << 'EOF'
#!/usr/bin/env bash
case "$1" in
    "list")
        case "$2" in
            "--formula")
                echo "git"
                echo "node"
                echo "python@3.11"
                ;;
            "--cask")
                echo "1password"
                echo "zed"
                ;;
            *)
                echo "git"
                echo "node"
                echo "1password"
                ;;
        esac
        ;;
    "install")
        echo "Installing $2..."
        echo "Successfully installed $2"
        ;;
    "update")
        echo "Updated Homebrew"
        ;;
    "upgrade")
        echo "Upgraded packages"
        ;;
    "cleanup")
        echo "Cleaned up old packages"
        ;;
    "doctor")
        echo "Your system is ready to brew"
        ;;
    "bundle")
        case "$2" in
            "dump")
                create_test_brewfile "${3#--file=}"
                ;;
            *)
                echo "Bundle operation: $*"
                ;;
        esac
        ;;
    "--version")
        echo "Homebrew 4.0.0"
        ;;
    *)
        echo "brew command not mocked: $*"
        exit 1
        ;;
esac
EOF
    chmod +x "${TEST_HOME_DIR}/.local/bin/brew"
}

# Network mock helpers
setup_network_mocks() {
    # Mock curl for downloads
    cat > "${TEST_HOME_DIR}/.local/bin/curl" << 'EOF'
#!/usr/bin/env bash
# Simple curl mock for testing downloads
if [[ "$*" == *"-o"* ]]; then
    # Extract output file
    local output_file=""
    local next_is_output=false
    for arg in "$@"; do
        if [[ "${next_is_output}" == "true" ]]; then
            output_file="${arg}"
            break
        fi
        if [[ "${arg}" == "-o" ]]; then
            next_is_output=true
        fi
    done
    
    if [[ -n "${output_file}" ]]; then
        echo "Mock download content" > "${output_file}"
    fi
else
    echo "Mock curl response"
fi
EOF
    chmod +x "${TEST_HOME_DIR}/.local/bin/curl"
}

# Chezmoi mock
setup_chezmoi_mock() {
    cat > "${TEST_HOME_DIR}/.local/bin/chezmoi" << 'EOF'
#!/usr/bin/env bash
case "$1" in
    "init")
        mkdir -p "${HOME}/.local/share/chezmoi"
        echo "Initialized chezmoi"
        ;;
    "apply")
        echo "Applied dotfiles"
        ;;
    "source-path")
        echo "${HOME}/.local/share/chezmoi"
        ;;
    "status")
        echo "No changes"
        ;;
    *)
        echo "chezmoi command not mocked: $*"
        exit 1
        ;;
esac
EOF
    chmod +x "${TEST_HOME_DIR}/.local/bin/chezmoi"
}

# Common test setup that most tests will use
common_setup() {
    setup_test_environment
    mock_macos_version "14.0" "23A344"
    setup_git_mock
    setup_homebrew_mock
    setup_network_mocks
}

# Common test teardown
common_teardown() {
    teardown_test_environment
}
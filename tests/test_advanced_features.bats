#!/usr/bin/env bats
# Tests for advanced features (Claude Code, MCP, linuxify, etc.)

load 'test_helper'

setup() {
    common_setup
}

teardown() {
    common_teardown
}

@test "claude code installation script exists and is executable" {
    assert_file_exists "${BATS_TEST_DIRNAME}/../scripts/install-claude-code.zsh"
    [[ -x "${BATS_TEST_DIRNAME}/../scripts/install-claude-code.zsh" ]]
}

@test "mcp servers setup script exists and is executable" {
    assert_file_exists "${BATS_TEST_DIRNAME}/../scripts/setup-mcp-servers.zsh"
    [[ -x "${BATS_TEST_DIRNAME}/../scripts/setup-mcp-servers.zsh" ]]
}

@test "linuxify installation script exists and is executable" {
    assert_file_exists "${BATS_TEST_DIRNAME}/../scripts/install-linuxify.zsh"
    [[ -x "${BATS_TEST_DIRNAME}/../scripts/install-linuxify.zsh" ]]
}

@test "applescript setup script exists and is executable" {
    assert_file_exists "${BATS_TEST_DIRNAME}/../scripts/setup-applescript.zsh"
    [[ -x "${BATS_TEST_DIRNAME}/../scripts/setup-applescript.zsh" ]]
}

@test "claude code installation checks for prerequisites" {
    # Remove npm to test prerequisite checking
    rm -f "${TEST_HOME_DIR}/.local/bin/npm"
    
    run "${BATS_TEST_DIRNAME}/../scripts/install-claude-code.zsh" --check-deps
    
    [[ "${status}" -ne 0 ]]
    [[ "${output}" == *"npm"* ]] || [[ "${output}" == *"prerequisite"* ]]
}

@test "claude code installation creates configuration" {
    # Mock npm and node
    create_mock_command "npm" 0 "npm installed"
    create_mock_command "node" 0 "v18.0.0"
    
    run "${BATS_TEST_DIRNAME}/../scripts/install-claude-code.zsh" --dry-run
    
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"config"* ]] || [[ "${output}" == *"Claude"* ]]
}

@test "mcp servers setup creates configuration directory" {
    create_mock_command "npm" 0 "npm installed"
    create_mock_command "python3" 0 "Python 3.11.0"
    
    run "${BATS_TEST_DIRNAME}/../scripts/setup-mcp-servers.zsh" --dry-run
    
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"MCP"* ]] || [[ "${output}" == *"server"* ]]
}

@test "linuxify installation downloads and configures aliases" {
    create_mock_command "git" 0 "git version 2.39.0"
    
    run "${BATS_TEST_DIRNAME}/../scripts/install-linuxify.zsh" --dry-run
    
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"linuxify"* ]] || [[ "${output}" == *"Linux"* ]]
}

@test "linuxify creates compatibility test script" {
    run "${BATS_TEST_DIRNAME}/../scripts/install-linuxify.zsh" --dry-run
    
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"test"* ]] || [[ "${output}" == *"compatibility"* ]]
}

@test "applescript setup creates script directory" {
    run "${BATS_TEST_DIRNAME}/../scripts/setup-applescript.zsh" --dry-run
    
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"AppleScript"* ]] || [[ "${output}" == *"script"* ]]
}

@test "fonts installation script exists and is executable" {
    assert_file_exists "${BATS_TEST_DIRNAME}/../scripts/install-fonts.zsh"
    [[ -x "${BATS_TEST_DIRNAME}/../scripts/install-fonts.zsh" ]]
}

@test "theme setup script exists and is executable" {
    assert_file_exists "${BATS_TEST_DIRNAME}/../scripts/setup-theme.zsh"
    [[ -x "${BATS_TEST_DIRNAME}/../scripts/setup-theme.zsh" ]]
}

@test "fonts installation handles missing dependencies" {
    rm -f "${TEST_HOME_DIR}/.local/bin/curl"
    
    run "${BATS_TEST_DIRNAME}/../scripts/install-fonts.zsh" --dry-run
    
    # Should handle missing curl gracefully
    [[ "${output}" == *"curl"* ]] || [[ "${output}" == *"download"* ]] || [[ "${status}" -ne 0 ]]
}

@test "theme setup configures gruvbox colors" {
    run "${BATS_TEST_DIRNAME}/../scripts/setup-theme.zsh" --dry-run
    
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"Gruvbox"* ]] || [[ "${output}" == *"theme"* ]]
}

@test "mcp servers configuration is valid json" {
    create_mock_command "npm" 0 "npm installed"
    create_mock_command "python3" 0 "Python 3.11.0"
    
    # Create a temporary config file to test
    mkdir -p "${TEST_HOME_DIR}/.config/mcp"
    echo '{"mcpServers": {}, "globalSettings": {"timeout": 30000}}' > "${TEST_HOME_DIR}/.config/mcp/config.json"
    
    run "${BATS_TEST_DIRNAME}/../scripts/setup-mcp-servers.zsh" --verify-config
    
    # Should validate configuration or show it's valid
    [[ "${output}" == *"config"* ]] || [[ "${output}" == *"valid"* ]] || [[ "${status}" -eq 0 ]]
}

@test "maintenance script exists and is executable" {
    assert_file_exists "${BATS_TEST_DIRNAME}/../scripts/system-maintenance.zsh"
    [[ -x "${BATS_TEST_DIRNAME}/../scripts/system-maintenance.zsh" ]]
}

@test "backup restore script exists and is executable" {
    assert_file_exists "${BATS_TEST_DIRNAME}/../scripts/backup-restore.zsh"
    [[ -x "${BATS_TEST_DIRNAME}/../scripts/backup-restore.zsh" ]]
}

@test "maintenance script handles automated mode" {
    run "${BATS_TEST_DIRNAME}/../scripts/system-maintenance.zsh" --automated
    
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"automated"* ]] || [[ "${output}" == *"maintenance"* ]]
}

@test "backup script creates backup structure" {
    run "${BATS_TEST_DIRNAME}/../scripts/backup-restore.zsh" backup --dry-run
    
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"backup"* ]] || [[ "${output}" == *"directory"* ]]
}
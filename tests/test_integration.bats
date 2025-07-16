#!/usr/bin/env bats
# Integration tests for complete setup workflows

load 'test_helper'

setup() {
    common_setup
    mock_macbook_pro
}

teardown() {
    common_teardown
}

@test "complete setup workflow for macbook pro" {
    # This test simulates a complete setup on a MacBook Pro
    mock_macbook_pro
    
    # Test that all major scripts can run in dry-run mode
    run "${BATS_TEST_DIRNAME}/../scripts/setup.zsh" --dry-run --device macbook-pro
    
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"MacBook"* ]]
}

@test "complete setup workflow for mac studio" {
    mock_mac_studio
    
    run "${BATS_TEST_DIRNAME}/../scripts/setup.zsh" --dry-run --device mac-studio
    
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"Studio"* ]]
}

@test "complete setup workflow for mac mini" {
    mock_mac_mini
    
    run "${BATS_TEST_DIRNAME}/../scripts/setup.zsh" --dry-run --device mac-mini
    
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"mini"* ]]
}

@test "setup handles missing dependencies gracefully across workflow" {
    # Remove critical dependencies
    rm -f "${TEST_HOME_DIR}/.local/bin/git"
    rm -f "${TEST_HOME_DIR}/.local/bin/brew"
    
    run "${BATS_TEST_DIRNAME}/../scripts/setup.zsh" --check-deps
    
    [[ "${status}" -ne 0 ]]
    [[ "${output}" == *"dependency"* ]] || [[ "${output}" == *"missing"* ]]
}

@test "dotfiles integration with device detection" {
    setup_chezmoi_mock
    
    # Test MacBook Pro configuration
    mock_macbook_pro
    run "${BATS_TEST_DIRNAME}/../scripts/setup-dotfiles.zsh" --dry-run
    
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"dotfiles"* ]] || [[ "${output}" == *"chezmoi"* ]]
}

@test "security setup integration" {
    create_op_mock
    
    # Test that security scripts can work together
    run "${BATS_TEST_DIRNAME}/../scripts/setup-1password.zsh" --dry-run
    [[ "${status}" -eq 0 ]]
    
    run "${BATS_TEST_DIRNAME}/../scripts/setup-filevault.zsh" --dry-run
    [[ "${status}" -eq 0 ]]
    
    run "${BATS_TEST_DIRNAME}/../scripts/setup-firewall.zsh" --dry-run
    [[ "${status}" -eq 0 ]]
}

@test "homebrew and package installation integration" {
    # Test that Homebrew setup integrates with package installation
    run "${BATS_TEST_DIRNAME}/../scripts/install-homebrew.zsh" --dry-run
    [[ "${status}" -eq 0 ]]
    
    run "${BATS_TEST_DIRNAME}/../scripts/install-packages.zsh" --dry-run
    [[ "${status}" -eq 0 ]]
}

@test "advanced features integration" {
    create_mock_command "npm" 0 "npm installed"
    create_mock_command "python3" 0 "Python 3.11.0"
    create_mock_command "node" 0 "v18.0.0"
    
    # Test Claude Code and MCP integration
    run "${BATS_TEST_DIRNAME}/../scripts/install-claude-code.zsh" --dry-run
    [[ "${status}" -eq 0 ]]
    
    run "${BATS_TEST_DIRNAME}/../scripts/setup-mcp-servers.zsh" --dry-run
    [[ "${status}" -eq 0 ]]
}

@test "theme and fonts integration" {
    # Test that theme and font setup work together
    run "${BATS_TEST_DIRNAME}/../scripts/install-fonts.zsh" --dry-run
    [[ "${status}" -eq 0 ]]
    
    run "${BATS_TEST_DIRNAME}/../scripts/setup-theme.zsh" --dry-run
    [[ "${status}" -eq 0 ]]
}

@test "maintenance and backup integration" {
    # Test maintenance and backup systems
    run "${BATS_TEST_DIRNAME}/../scripts/system-maintenance.zsh" --automated
    [[ "${status}" -eq 0 ]]
    
    run "${BATS_TEST_DIRNAME}/../scripts/backup-restore.zsh" list
    [[ "${status}" -eq 0 ]]
}

@test "user setup integration with family environment" {
    # Test multi-user family setup
    run "${BATS_TEST_DIRNAME}/../scripts/setup-users.zsh" --dry-run
    [[ "${status}" -eq 0 ]]
    
    run "${BATS_TEST_DIRNAME}/../scripts/setup-family-environment.zsh" --dry-run
    [[ "${status}" -eq 0 ]]
}

@test "network configuration integration with device types" {
    # Test Mac Studio (static IP)
    mock_mac_studio
    run "${BATS_TEST_DIRNAME}/../scripts/setup-network.zsh" --dry-run
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"static"* ]] || [[ "${output}" == *"10.20.0.10"* ]]
    
    # Test MacBook Pro (dynamic IP)
    mock_macbook_pro
    run "${BATS_TEST_DIRNAME}/../scripts/setup-network.zsh" --dry-run
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"WiFi"* ]] || [[ "${output}" == *"dynamic"* ]]
}

@test "remote access setup integration with device types" {
    # Test headless setup for Mac Studio
    mock_mac_studio
    run "${BATS_TEST_DIRNAME}/../scripts/setup-remote-access.zsh" --dry-run
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"headless"* ]] || [[ "${output}" == *"remote"* ]]
    
    # Test portable setup for MacBook Pro
    mock_macbook_pro
    run "${BATS_TEST_DIRNAME}/../scripts/setup-remote-access.zsh" --dry-run
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"portable"* ]] || [[ "${output}" == *"Jump"* ]]
}

@test "validation scripts work with generated configurations" {
    # Test that validation works after setup
    create_test_brewfile "${TEST_HOME_DIR}/test-Brewfile"
    
    run "${BATS_TEST_DIRNAME}/../scripts/validate-brewfiles.zsh" "${TEST_HOME_DIR}/test-Brewfile"
    [[ "${status}" -eq 0 ]]
    
    run "${BATS_TEST_DIRNAME}/../scripts/validate-setup.zsh" --dry-run
    [[ "${status}" -eq 0 ]]
}

@test "error handling across integrated workflows" {
    # Test error propagation and handling
    
    # Simulate a failure in one component
    create_mock_command "git" 1 "git failed"
    
    run "${BATS_TEST_DIRNAME}/../scripts/setup.zsh" --dry-run
    
    # Should handle the error gracefully
    [[ "${status}" -ne 0 ]] || [[ "${output}" == *"error"* ]] || [[ "${output}" == *"failed"* ]]
}
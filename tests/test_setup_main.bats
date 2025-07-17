#!/usr/bin/env bats
# Tests for main setup script

load 'test_helper'

setup() {
    common_setup
    mock_macbook_pro
}

teardown() {
    common_teardown
}

@test "main setup script exists and is executable" {
    assert_file_exists "${BATS_TEST_DIRNAME}/../scripts/setup/setup.zsh"
    [[ -x "${BATS_TEST_DIRNAME}/../scripts/setup/setup.zsh" ]]
}

@test "setup script detects device type correctly - MacBook Pro" {
    mock_macbook_pro
    
    run "${BATS_TEST_DIRNAME}/../scripts/setup/setup.zsh" --dry-run
    
    [[ "${output}" == *"MacBook Pro"* ]]
}

@test "setup script detects device type correctly - Mac Studio" {
    mock_mac_studio
    
    run "${BATS_TEST_DIRNAME}/../scripts/setup/setup.zsh" --dry-run
    
    [[ "${output}" == *"Mac Studio"* ]]
}

@test "setup script detects device type correctly - Mac Mini" {
    mock_mac_mini
    
    run "${BATS_TEST_DIRNAME}/../scripts/setup/setup.zsh" --dry-run
    
    [[ "${output}" == *"Mac mini"* ]]
}

@test "setup script fails gracefully when device type cannot be determined" {
    create_mock_command "hostname" 0 "unknown-device.local"
    create_mock_command "system_profiler" 0 "Model Name: Unknown Device"
    
    run "${BATS_TEST_DIRNAME}/../scripts/setup/setup.zsh" --dry-run
    
    [[ "${status}" -ne 0 ]]
    [[ "${output}" == *"unknown"* ]]
}

@test "setup script checks for required dependencies" {
    # Remove mock commands to test dependency checking
    rm -f "${TEST_HOME_DIR}/.local/bin/git"
    rm -f "${TEST_HOME_DIR}/.local/bin/brew"
    
    run "${BATS_TEST_DIRNAME}/../scripts/setup/setup.zsh" --dry-run
    
    [[ "${status}" -ne 0 ]]
    [[ "${output}" == *"git"* ]] || [[ "${output}" == *"brew"* ]]
}

@test "setup script runs in dry-run mode without making changes" {
    run "${BATS_TEST_DIRNAME}/../scripts/setup/setup.zsh" --dry-run
    
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"dry run"* ]] || [[ "${output}" == *"would"* ]]
}

@test "setup script creates necessary directories" {
    run "${BATS_TEST_DIRNAME}/../scripts/setup/setup.zsh" --dry-run --verbose
    
    [[ "${status}" -eq 0 ]]
    # Check that script mentions directory creation
    [[ "${output}" == *"directory"* ]] || [[ "${output}" == *"mkdir"* ]]
}

@test "setup script handles missing Homebrew gracefully" {
    rm -f "${TEST_HOME_DIR}/.local/bin/brew"
    
    run "${BATS_TEST_DIRNAME}/../scripts/setup/setup.zsh" --check-deps
    
    [[ "${status}" -ne 0 ]]
    [[ "${output}" == *"Homebrew"* ]] || [[ "${output}" == *"brew"* ]]
}

@test "setup script accepts command line arguments" {
    run "${BATS_TEST_DIRNAME}/../scripts/setup/setup.zsh" --help
    
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"Usage"* ]] || [[ "${output}" == *"help"* ]]
}

@test "setup script shows version information" {
    run "${BATS_TEST_DIRNAME}/../scripts/setup/setup.zsh" --version
    
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"version"* ]] || [[ "${output}" == *"macOS Setup"* ]]
}
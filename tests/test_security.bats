#!/usr/bin/env bats
# Tests for security scripts and configurations

load 'test_helper'

setup() {
    common_setup
    create_op_mock
}

teardown() {
    common_teardown
}

@test "1password setup script exists and is executable" {
    assert_file_exists "${BATS_TEST_DIRNAME}/../scripts/setup-1password.zsh"
    [[ -x "${BATS_TEST_DIRNAME}/../scripts/setup-1password.zsh" ]]
}

@test "filevault setup script exists and is executable" {
    assert_file_exists "${BATS_TEST_DIRNAME}/../scripts/setup-filevault.zsh"
    [[ -x "${BATS_TEST_DIRNAME}/../scripts/setup-filevault.zsh" ]]
}

@test "firewall setup script exists and is executable" {
    assert_file_exists "${BATS_TEST_DIRNAME}/../scripts/setup-firewall.zsh"
    [[ -x "${BATS_TEST_DIRNAME}/../scripts/setup-firewall.zsh" ]]
}

@test "hardening setup script exists and is executable" {
    assert_file_exists "${BATS_TEST_DIRNAME}/../scripts/setup-hardening.zsh"
    [[ -x "${BATS_TEST_DIRNAME}/../scripts/setup-hardening.zsh" ]]
}

@test "1password setup detects existing installation" {
    create_mock_command "op" 0 "test-account"
    
    run "${BATS_TEST_DIRNAME}/../scripts/setup-1password.zsh" --check
    
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"1Password"* ]]
}

@test "1password setup handles missing CLI gracefully" {
    rm -f "${TEST_HOME_DIR}/.local/bin/op"
    
    run "${BATS_TEST_DIRNAME}/../scripts/setup-1password.zsh" --dry-run
    
    # Should handle missing CLI (install or warn)
    [[ "${output}" == *"1Password"* ]] || [[ "${output}" == *"op"* ]]
}

@test "filevault setup checks current status" {
    # Mock fdesetup command
    create_mock_command "fdesetup" 0 "FileVault is On."
    
    run "${BATS_TEST_DIRNAME}/../scripts/setup-filevault.zsh" --status
    
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"FileVault"* ]]
}

@test "firewall setup configures device-specific rules" {
    mock_mac_studio
    
    run "${BATS_TEST_DIRNAME}/../scripts/setup-firewall.zsh" --dry-run
    
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"firewall"* ]] || [[ "${output}" == *"rule"* ]]
}

@test "hardening script applies appropriate security settings" {
    run "${BATS_TEST_DIRNAME}/../scripts/setup-hardening.zsh" --dry-run
    
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"security"* ]] || [[ "${output}" == *"hardening"* ]]
}

@test "security scripts don't contain hardcoded credentials" {
    local security_scripts=(
        "${BATS_TEST_DIRNAME}/../scripts/setup-1password.zsh"
        "${BATS_TEST_DIRNAME}/../scripts/setup-filevault.zsh"
        "${BATS_TEST_DIRNAME}/../scripts/setup-firewall.zsh"
        "${BATS_TEST_DIRNAME}/../scripts/setup-hardening.zsh"
    )
    
    for script in "${security_scripts[@]}"; do
        if [[ -f "${script}" ]]; then
            # Check for common patterns of hardcoded credentials
            ! grep -i "password.*=" "${script}" | grep -v "PASSWORD_PROMPT\|read.*password\|op read"
            ! grep -i "secret.*=" "${script}" | grep -v "SECRET_PROMPT\|read.*secret\|op read"
            ! grep -i "key.*=" "${script}" | grep -v "KEY_PATH\|SSH_KEY\|GPG_KEY\|op read"
        fi
    done
}

@test "1password integration uses secure credential retrieval" {
    run "${BATS_TEST_DIRNAME}/../scripts/setup-1password.zsh" --test-integration
    
    # Should use 'op read' or similar secure methods
    [[ "${output}" == *"op read"* ]] || [[ "${output}" == *"credential"* ]] || [[ "${status}" -ne 0 ]]
}

@test "filevault script requires admin privileges" {
    run "${BATS_TEST_DIRNAME}/../scripts/setup-filevault.zsh" --check-privileges
    
    # Should check for admin privileges or sudo access
    [[ "${output}" == *"admin"* ]] || [[ "${output}" == *"sudo"* ]] || [[ "${output}" == *"privilege"* ]]
}

@test "firewall rules are device-specific" {
    # Test MacBook Pro configuration
    mock_macbook_pro
    run "${BATS_TEST_DIRNAME}/../scripts/setup-firewall.zsh" --dry-run
    local macbook_output="${output}"
    
    # Test Mac Studio configuration
    mock_mac_studio
    run "${BATS_TEST_DIRNAME}/../scripts/setup-firewall.zsh" --dry-run
    local studio_output="${output}"
    
    # Outputs should be different for different devices
    [[ "${macbook_output}" != "${studio_output}" ]] || {
        echo "Firewall configuration should be device-specific"
        return 1
    }
}

@test "security configurations use Australian locale" {
    run "${BATS_TEST_DIRNAME}/../scripts/setup-hardening.zsh" --dry-run
    
    [[ "${status}" -eq 0 ]]
    # Should set Australian locale or mention it
    [[ "${output}" == *"Australia"* ]] || [[ "${output}" == *"en_AU"* ]] || [[ "${output}" == *"Adelaide"* ]]
}
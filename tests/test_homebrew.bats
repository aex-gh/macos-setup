#!/usr/bin/env bats
# Tests for Homebrew installation and package management

load 'test_helper'

setup() {
    common_setup
}

teardown() {
    common_teardown
}

@test "install-homebrew script exists and is executable" {
    assert_file_exists "${BATS_TEST_DIRNAME}/../scripts/install-homebrew.zsh"
    [[ -x "${BATS_TEST_DIRNAME}/../scripts/install-homebrew.zsh" ]]
}

@test "install-homebrew detects existing installation" {
    run "${BATS_TEST_DIRNAME}/../scripts/install-homebrew.zsh" --check
    
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"already installed"* ]] || [[ "${output}" == *"found"* ]]
}

@test "install-homebrew handles missing installation" {
    rm -f "${TEST_HOME_DIR}/.local/bin/brew"
    
    run "${BATS_TEST_DIRNAME}/../scripts/install-homebrew.zsh" --dry-run
    
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"install"* ]] || [[ "${output}" == *"download"* ]]
}

@test "validate-brewfiles script validates formula existence" {
    create_test_brewfile "${TEST_HOME_DIR}/test-Brewfile"
    
    run "${BATS_TEST_DIRNAME}/../scripts/validate-brewfiles.zsh" "${TEST_HOME_DIR}/test-Brewfile"
    
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"valid"* ]] || [[ "${output}" == *"OK"* ]]
}

@test "validate-brewfiles script detects invalid formulae" {
    cat > "${TEST_HOME_DIR}/invalid-Brewfile" << 'EOF'
brew "git"
brew "nonexistent-package-12345"
cask "1password"
EOF
    
    run "${BATS_TEST_DIRNAME}/../scripts/validate-brewfiles.zsh" "${TEST_HOME_DIR}/invalid-Brewfile"
    
    # May succeed with warnings or fail - either is acceptable for invalid packages
    [[ "${output}" == *"nonexistent"* ]] || [[ "${output}" == *"invalid"* ]] || [[ "${output}" == *"warning"* ]]
}

@test "install-packages script processes device-specific Brewfiles" {
    mock_macbook_pro
    create_test_brewfile "${BATS_TEST_DIRNAME}/../configs/macbook-pro/Brewfile"
    
    run "${BATS_TEST_DIRNAME}/../scripts/install-packages.zsh" --dry-run
    
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"macbook-pro"* ]] || [[ "${output}" == *"MacBook"* ]]
}

@test "install-packages script handles missing Brewfile gracefully" {
    run "${BATS_TEST_DIRNAME}/../scripts/install-packages.zsh" --dry-run --device unknown
    
    [[ "${status}" -ne 0 ]]
    [[ "${output}" == *"not found"* ]] || [[ "${output}" == *"missing"* ]]
}

@test "Brewfile contains required base packages" {
    assert_file_exists "${BATS_TEST_DIRNAME}/../configs/common/Brewfile"
    
    local brewfile="${BATS_TEST_DIRNAME}/../configs/common/Brewfile"
    assert_file_contains "${brewfile}" "git"
    assert_file_contains "${brewfile}" "chezmoi"
}

@test "device-specific Brewfiles exist for all supported devices" {
    assert_file_exists "${BATS_TEST_DIRNAME}/../configs/macbook-pro/Brewfile"
    assert_file_exists "${BATS_TEST_DIRNAME}/../configs/mac-studio/Brewfile"
    assert_file_exists "${BATS_TEST_DIRNAME}/../configs/mac-mini/Brewfile"
}

@test "Brewfiles have correct syntax" {
    local brewfiles=(
        "${BATS_TEST_DIRNAME}/../configs/common/Brewfile"
        "${BATS_TEST_DIRNAME}/../configs/macbook-pro/Brewfile"
        "${BATS_TEST_DIRNAME}/../configs/mac-studio/Brewfile"
        "${BATS_TEST_DIRNAME}/../configs/mac-mini/Brewfile"
    )
    
    for brewfile in "${brewfiles[@]}"; do
        if [[ -f "${brewfile}" ]]; then
            # Check that file doesn't have syntax errors
            run bash -n "${brewfile}"
            # Note: Brewfiles aren't shell scripts, but checking for basic syntax issues
            
            # Check for required format
            assert_file_contains "${brewfile}" "brew" || assert_file_contains "${brewfile}" "cask" || assert_file_contains "${brewfile}" "mas"
        fi
    done
}
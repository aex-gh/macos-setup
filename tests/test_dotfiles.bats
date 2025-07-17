#!/usr/bin/env bats
# Tests for dotfiles and chezmoi configuration

load 'test_helper'

setup() {
    common_setup
    setup_chezmoi_mock
}

teardown() {
    common_teardown
}

@test "setup-dotfiles script exists and is executable" {
    assert_file_exists "${BATS_TEST_DIRNAME}/../scripts/setup/setup-dotfiles.zsh"
    [[ -x "${BATS_TEST_DIRNAME}/../scripts/setup/setup-dotfiles.zsh" ]]
}

@test "dotfiles directory structure exists" {
    assert_directory_exists "${BATS_TEST_DIRNAME}/../dotfiles"
}

@test "chezmoi configuration template exists" {
    assert_file_exists "${BATS_TEST_DIRNAME}/../dotfiles/.chezmoi.toml.tmpl"
}

@test "chezmoi configuration contains device detection" {
    local config_file="${BATS_TEST_DIRNAME}/../dotfiles/.chezmoi.toml.tmpl"
    assert_file_contains "${config_file}" "device_type"
    assert_file_contains "${config_file}" "macbook-pro"
    assert_file_contains "${config_file}" "mac-studio"
    assert_file_contains "${config_file}" "mac-mini"
}

@test "chezmoi configuration contains Australian locale" {
    local config_file="${BATS_TEST_DIRNAME}/../dotfiles/.chezmoi.toml.tmpl"
    assert_file_contains "${config_file}" "Australia/Adelaide"
    assert_file_contains "${config_file}" "en_AU"
}

@test "zsh configuration template exists and is valid" {
    local zshrc_file="${BATS_TEST_DIRNAME}/../dotfiles/dot_zshrc.tmpl"
    assert_file_exists "${zshrc_file}"
    assert_file_contains "${zshrc_file}" "LANG="
    assert_file_contains "${zshrc_file}" "Australia/Adelaide"
}

@test "git configuration template exists and is valid" {
    local gitconfig_file="${BATS_TEST_DIRNAME}/../dotfiles/dot_gitconfig.tmpl"
    assert_file_exists "${gitconfig_file}"
    assert_file_contains "${gitconfig_file}" "user"
    assert_file_contains "${gitconfig_file}" "Andrew Exley"
}

@test "zed configuration exists and contains gruvbox theme" {
    local zed_config="${BATS_TEST_DIRNAME}/../dotfiles/private_dot_config/zed/settings.json.tmpl"
    assert_file_exists "${zed_config}"
    assert_file_contains "${zed_config}" "Gruvbox Dark Soft"
    assert_file_contains "${zed_config}" "Maple Mono"
}

@test "setup-dotfiles initializes chezmoi correctly" {
    run "${BATS_TEST_DIRNAME}/../scripts/setup/setup-dotfiles.zsh" --dry-run
    
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"chezmoi"* ]]
}

@test "chezmoi ignore file exists and excludes sensitive files" {
    local ignore_file="${BATS_TEST_DIRNAME}/../dotfiles/.chezmoiignore"
    assert_file_exists "${ignore_file}"
    assert_file_contains "${ignore_file}" ".ssh/id_"
    assert_file_contains "${ignore_file}" ".DS_Store"
}

@test "dotfiles contain device-specific templates" {
    local zshrc_file="${BATS_TEST_DIRNAME}/../dotfiles/dot_zshrc.tmpl"
    assert_file_contains "${zshrc_file}" "device_type"
    assert_file_contains "${zshrc_file}" "mac-studio"
    assert_file_contains "${zshrc_file}" "macbook-pro"
}

@test "terminal configuration template exists" {
    local terminal_config="${BATS_TEST_DIRNAME}/../dotfiles/Library/Preferences/com.apple.Terminal.plist.tmpl"
    assert_file_exists "${terminal_config}"
    assert_file_contains "${terminal_config}" "Gruvbox"
}

@test "encryption setup script exists" {
    assert_file_exists "${BATS_TEST_DIRNAME}/../dotfil../scripts/setup-encryption.zsh"
    [[ -x "${BATS_TEST_DIRNAME}/../dotfil../scripts/setup-encryption.zsh" ]]
}

@test "setup-dotfiles creates necessary directories" {
    run "${BATS_TEST_DIRNAME}/../scripts/setup/setup-dotfiles.zsh" --dry-run
    
    [[ "${status}" -eq 0 ]]
    # Should mention directory creation or checking
    [[ "${output}" == *"directory"* ]] || [[ "${output}" == *"path"* ]]
}
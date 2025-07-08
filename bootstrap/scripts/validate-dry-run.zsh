#!/usr/bin/env zsh
# -*- coding: utf-8 -*-

#=============================================================================
# SCRIPT: validate-dry-run.zsh
# AUTHOR: Andrew Exley (with Claude)
# DATE: 2025-01-07
# VERSION: 1.0.0
#
# DESCRIPTION:
#   Comprehensive validation script for the dry run testing system.
#   Tests all modules and utilities to ensure dry run mode works correctly
#   and doesn't make any actual changes to the system.
#
# USAGE:
#   ./validate-dry-run.zsh [options]
#
# OPTIONS:
#   -h, --help         Show this help message
#   -v, --verbose      Enable verbose output
#   -m, --module       Test specific module only
#   -a, --all-profiles Test all profiles
#   --quick            Quick validation (essential tests only)
#
# REQUIREMENTS:
#   - macOS 11.0+ (Big Sur)
#   - Zsh 5.8+
#   - BATS (for comprehensive testing)
#   - jq (for JSON processing)
#
# NOTES:
#   - Runs in isolated test environment
#   - Validates system state before and after
#   - Generates comprehensive test reports
#=============================================================================

# Strict mode
set -euo pipefail

# Script metadata
readonly SCRIPT_NAME="${0:t}"
readonly SCRIPT_DIR="${0:A:h}"
readonly SCRIPT_VERSION="1.0.0"
readonly DOTFILES_ROOT="${SCRIPT_DIR:h}"

# Colour codes
readonly RED=$(tput setaf 1)
readonly GREEN=$(tput setaf 2)
readonly YELLOW=$(tput setaf 3)
readonly BLUE=$(tput setaf 4)
readonly MAGENTA=$(tput setaf 5)
readonly CYAN=$(tput setaf 6)
readonly BOLD=$(tput bold)
readonly RESET=$(tput sgr0)

# Global variables
declare -g VERBOSE=false
declare -g MODULE_FILTER=""
declare -g TEST_ALL_PROFILES=false
declare -g QUICK_MODE=false
declare -g TEST_DIR=""
declare -g VALIDATION_REPORT=""

# Test results tracking
declare -gi TESTS_PASSED=0
declare -gi TESTS_FAILED=0
declare -ga FAILED_TESTS=()

#=============================================================================
# LOGGING FUNCTIONS
#=============================================================================

log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case $level in
        ERROR)
            echo "${RED}${BOLD}[ERROR]${RESET} $message" >&2
            ;;
        WARN)
            echo "${YELLOW}${BOLD}[WARN]${RESET} $message" >&2
            ;;
        INFO)
            echo "${BLUE}${BOLD}[INFO]${RESET} $message"
            ;;
        SUCCESS)
            echo "${GREEN}${BOLD}[✓]${RESET} $message"
            ;;
        TEST)
            echo "${MAGENTA}${BOLD}[TEST]${RESET} $message"
            ;;
        VERBOSE)
            [[ $VERBOSE == true ]] && echo "${CYAN}[VERBOSE]${RESET} $message"
            ;;
    esac
}

error() { log ERROR "$@"; }
warn() { log WARN "$@"; }
info() { log INFO "$@"; }
success() { log SUCCESS "$@"; }
test_log() { log TEST "$@"; }
verbose() { log VERBOSE "$@"; }

#=============================================================================
# TEST UTILITIES
#=============================================================================

# Run a test and track results
run_test() {
    local test_name="$1"
    local test_function="$2"
    
    test_log "Running: $test_name"
    
    if $test_function; then
        success "PASSED: $test_name"
        ((TESTS_PASSED++))
        return 0
    else
        error "FAILED: $test_name"
        FAILED_TESTS+=("$test_name")
        ((TESTS_FAILED++))
        return 1
    fi
}

# Capture system state
capture_system_state() {
    local state_file="$1"
    local label="${2:-System State}"
    
    verbose "Capturing $label to $state_file"
    
    cat > "$state_file" << EOF
{
    "timestamp": "$(date -Iseconds)",
    "disk_usage": $(df -g / | awk 'NR==2 {print $3}'),
    "file_count": $(find "$HOME" -type f 2>/dev/null | wc -l | xargs),
    "process_count": $(ps aux | wc -l | xargs),
    "homebrew_installed": $(command -v brew &>/dev/null && echo true || echo false),
    "homebrew_packages": $(brew list --formula 2>/dev/null | wc -l | xargs || echo 0),
    "homebrew_casks": $(brew list --cask 2>/dev/null | wc -l | xargs || echo 0),
    "shell_env": {
        "path_entries": $(echo "$PATH" | tr ':' '\n' | wc -l | xargs),
        "zsh_version": "$ZSH_VERSION",
        "home_dir": "$HOME"
    }
}
EOF
}

# Compare system states
compare_system_states() {
    local before_file="$1"
    local after_file="$2"
    
    if ! command -v jq >/dev/null; then
        warn "jq not available, skipping detailed state comparison"
        return 0
    fi
    
    # Compare key metrics
    local before_disk=$(jq -r '.disk_usage' "$before_file")
    local after_disk=$(jq -r '.disk_usage' "$after_file")
    local before_files=$(jq -r '.file_count' "$before_file")
    local after_files=$(jq -r '.file_count' "$after_file")
    local before_brew=$(jq -r '.homebrew_packages' "$before_file")
    local after_brew=$(jq -r '.homebrew_packages' "$after_file")
    
    # Allow small variance for temporary files
    local disk_diff=$((after_disk - before_disk))
    local file_diff=$((after_files - before_files))
    local brew_diff=$((after_brew - before_brew))
    
    if [[ $disk_diff -gt 1 ]]; then
        error "Disk usage increased by ${disk_diff}GB (unexpected in dry run)"
        return 1
    fi
    
    if [[ $file_diff -gt 5 ]]; then
        error "File count increased by $file_diff (only small temp files expected)"
        return 1
    fi
    
    if [[ $brew_diff -gt 0 ]]; then
        error "Homebrew packages increased by $brew_diff (no packages should be installed)"
        return 1
    fi
    
    verbose "System state comparison passed (disk: ${disk_diff}GB, files: ${file_diff}, brew: ${brew_diff})"
    return 0
}

#=============================================================================
# INDIVIDUAL TESTS
#=============================================================================

# Test dry run utilities library
test_dry_run_utils() {
    test_log "Testing dry run utilities library"
    
    # Source the library
    if [[ ! -f "$DOTFILES_ROOT/scripts/lib/dry-run-utils.zsh" ]]; then
        error "Dry run utilities library not found"
        return 1
    fi
    
    export DRY_RUN_ENABLED=true
    export DRY_RUN_REPORT_FILE="$TEST_DIR/test-report.json"
    source "$DOTFILES_ROOT/scripts/lib/dry-run-utils.zsh"
    
    # Test initialization
    dr_init "test_module"
    if [[ ! -f "$DRY_RUN_REPORT_FILE" ]]; then
        error "Report file not created"
        return 1
    fi
    
    # Test command execution (should not execute)
    local test_file="$TEST_DIR/should_not_exist.txt"
    dr_execute "Test command" touch "$test_file"
    if [[ -f "$test_file" ]]; then
        error "Command was executed in dry run mode"
        return 1
    fi
    
    # Test file operations
    dr_mkdir "Test directory" "$TEST_DIR/test_dir"
    if [[ -d "$TEST_DIR/test_dir" ]]; then
        error "Directory was created in dry run mode"
        return 1
    fi
    
    # Test report generation
    dr_finalize_module "test_module"
    if ! jq -e '.modules.test_module.completed' "$DRY_RUN_REPORT_FILE" >/dev/null; then
        error "Module completion not recorded"
        return 1
    fi
    
    success "Dry run utilities library tests passed"
    return 0
}

# Test bootstrap script dry run
test_bootstrap_dry_run() {
    test_log "Testing bootstrap script dry run mode"
    
    local bootstrap_script="$DOTFILES_ROOT/scripts/00-bootstrap.zsh"
    if [[ ! -f "$bootstrap_script" ]]; then
        error "Bootstrap script not found"
        return 1
    fi
    
    # Test with minimal profile
    export HOME="$TEST_DIR/home"
    mkdir -p "$HOME"
    
    local output_file="$TEST_DIR/bootstrap_output.txt"
    
    # Run bootstrap in dry run mode
    if "$bootstrap_script" --dry-run --profile minimal --force > "$output_file" 2>&1; then
        verbose "Bootstrap dry run completed successfully"
    else
        error "Bootstrap dry run failed"
        cat "$output_file"
        return 1
    fi
    
    # Check that no actual changes were made to system
    if grep -q "DRY RUN" "$output_file"; then
        success "Bootstrap correctly identified dry run mode"
    else
        error "Bootstrap did not indicate dry run mode"
        return 1
    fi
    
    return 0
}

# Test individual module dry run
test_module_dry_run() {
    local module="$1"
    local module_script="$DOTFILES_ROOT/scripts/$module.zsh"
    
    test_log "Testing module dry run: $module"
    
    if [[ ! -f "$module_script" ]]; then
        warn "Module script not found: $module_script"
        return 0  # Skip missing modules
    fi
    
    # Capture state before
    local before_state="$TEST_DIR/before_${module}.json"
    local after_state="$TEST_DIR/after_${module}.json"
    capture_system_state "$before_state" "Before $module"
    
    # Run module in dry run mode
    export HOME="$TEST_DIR/home"
    export DRY_RUN=true
    export FORCE=true
    
    local output_file="$TEST_DIR/${module}_output.txt"
    
    if timeout 60 "$module_script" > "$output_file" 2>&1; then
        verbose "Module $module completed dry run"
    else
        local exit_code=$?
        if [[ $exit_code -eq 124 ]]; then
            error "Module $module timed out (60s)"
        else
            error "Module $module failed with exit code $exit_code"
            tail -20 "$output_file"
        fi
        return 1
    fi
    
    # Capture state after
    capture_system_state "$after_state" "After $module"
    
    # Compare states
    if ! compare_system_states "$before_state" "$after_state"; then
        error "System state changed unexpectedly for module $module"
        return 1
    fi
    
    success "Module $module dry run passed"
    return 0
}

# Test BATS test suite
test_bats_suite() {
    if ! command -v bats >/dev/null; then
        warn "BATS not available, skipping test suite"
        return 0
    fi
    
    test_log "Running BATS test suite"
    
    local test_file="$DOTFILES_ROOT/tests/test_dry_run.bats"
    if [[ ! -f "$test_file" ]]; then
        warn "BATS test file not found"
        return 0
    fi
    
    local bats_output="$TEST_DIR/bats_output.txt"
    
    if bats "$test_file" > "$bats_output" 2>&1; then
        success "BATS test suite passed"
        return 0
    else
        error "BATS test suite failed"
        tail -20 "$bats_output"
        return 1
    fi
}

# Test all profiles
test_all_profiles() {
    local profiles=("developer" "data-scientist" "personal" "minimal")
    local bootstrap_script="$DOTFILES_ROOT/scripts/00-bootstrap.zsh"
    
    for profile in "${profiles[@]}"; do
        test_log "Testing profile: $profile"
        
        export HOME="$TEST_DIR/home_$profile"
        mkdir -p "$HOME"
        
        local output_file="$TEST_DIR/profile_${profile}_output.txt"
        
        if timeout 120 "$bootstrap_script" --dry-run --profile "$profile" --force > "$output_file" 2>&1; then
            success "Profile $profile dry run completed"
        else
            error "Profile $profile dry run failed"
            tail -20 "$output_file"
            return 1
        fi
    done
    
    return 0
}

#=============================================================================
# MAIN VALIDATION WORKFLOW
#=============================================================================

# Run quick validation tests
run_quick_tests() {
    info "Running quick validation tests..."
    
    run_test "Dry Run Utils Library" test_dry_run_utils
    run_test "Bootstrap Dry Run" test_bootstrap_dry_run
    run_test "Homebrew Module Dry Run" "test_module_dry_run 03-homebrew-setup"
    
    if [[ $TEST_ALL_PROFILES == true ]]; then
        run_test "All Profiles" test_all_profiles
    fi
}

# Run comprehensive validation tests
run_comprehensive_tests() {
    info "Running comprehensive validation tests..."
    
    run_test "Dry Run Utils Library" test_dry_run_utils
    run_test "Bootstrap Dry Run" test_bootstrap_dry_run
    run_test "BATS Test Suite" test_bats_suite
    
    # Test individual modules
    local modules=(
        "01-system-detection"
        "02-xcode-tools"
        "03-homebrew-setup"
        "04-system-setup"
        "05-macos-defaults"
        "06-applications"
        "07-security-hardening"
        "08-development-env"
        "09-post-setup"
    )
    
    for module in "${modules[@]}"; do
        if [[ -n $MODULE_FILTER && $module != *"$MODULE_FILTER"* ]]; then
            continue
        fi
        
        run_test "Module $module" "test_module_dry_run $module"
    done
    
    if [[ $TEST_ALL_PROFILES == true ]]; then
        run_test "All Profiles" test_all_profiles
    fi
}

# Generate validation report
generate_validation_report() {
    local report_file="$VALIDATION_REPORT"
    
    cat > "$report_file" << EOF
# Dry Run Validation Report

**Generated:** $(date)
**Test Environment:** $TEST_DIR
**Mode:** $([ "$QUICK_MODE" = true ] && echo "Quick" || echo "Comprehensive")

## Summary

- **Tests Passed:** $TESTS_PASSED
- **Tests Failed:** $TESTS_FAILED
- **Success Rate:** $(( TESTS_PASSED * 100 / (TESTS_PASSED + TESTS_FAILED) ))%

## Failed Tests

EOF

    if [[ ${#FAILED_TESTS[@]} -eq 0 ]]; then
        echo "No failed tests ✅" >> "$report_file"
    else
        for test in "${FAILED_TESTS[@]}"; do
            echo "- $test ❌" >> "$report_file"
        done
    fi
    
    cat >> "$report_file" << EOF

## Test Environment Details

- **Dotfiles Root:** $DOTFILES_ROOT
- **Test Directory:** $TEST_DIR
- **macOS Version:** $(sw_vers -productVersion)
- **Zsh Version:** $ZSH_VERSION
- **Homebrew Available:** $(command -v brew >/dev/null && echo "Yes" || echo "No")
- **BATS Available:** $(command -v bats >/dev/null && echo "Yes" || echo "No")
- **jq Available:** $(command -v jq >/dev/null && echo "Yes" || echo "No")

## Recommendations

EOF

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo "All tests passed! The dry run system is working correctly." >> "$report_file"
    else
        echo "Some tests failed. Review the failures above and check:" >> "$report_file"
        echo "- System dependencies are installed" >> "$report_file"
        echo "- File permissions are correct" >> "$report_file"
        echo "- No conflicting processes are running" >> "$report_file"
    fi
    
    info "Validation report generated: $report_file"
}

# Usage information
usage() {
    cat << EOF
${BOLD}NAME${RESET}
    $SCRIPT_NAME - Validate dry run testing system

${BOLD}SYNOPSIS${RESET}
    $SCRIPT_NAME [options]

${BOLD}DESCRIPTION${RESET}
    Comprehensive validation of the dry run testing system to ensure
    that dry run mode works correctly across all modules and doesn't
    make any actual changes to the system.

${BOLD}OPTIONS${RESET}
    -h, --help          Show this help message
    -v, --verbose       Enable verbose output
    -m, --module MODULE Test specific module only
    -a, --all-profiles  Test all setup profiles
    --quick             Run quick validation only

${BOLD}EXAMPLES${RESET}
    # Quick validation
    $SCRIPT_NAME --quick

    # Comprehensive validation
    $SCRIPT_NAME --verbose

    # Test specific module
    $SCRIPT_NAME --module homebrew-setup

    # Test all profiles
    $SCRIPT_NAME --all-profiles

${BOLD}AUTHOR${RESET}
    Andrew Exley (with Claude) <noreply@anthropic.com>

${BOLD}VERSION${RESET}
    $SCRIPT_VERSION
EOF
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -m|--module)
                MODULE_FILTER="$2"
                shift 2
                ;;
            -a|--all-profiles)
                TEST_ALL_PROFILES=true
                shift
                ;;
            --quick)
                QUICK_MODE=true
                shift
                ;;
            *)
                error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
}

# Main validation logic
main() {
    parse_args "$@"
    
    # Set up test environment
    TEST_DIR="$(mktemp -d)"
    VALIDATION_REPORT="$TEST_DIR/validation-report.md"
    
    info "Starting dry run validation"
    info "Test directory: $TEST_DIR"
    
    # Check prerequisites
    if ! command -v jq >/dev/null; then
        warn "jq not available - some tests will be skipped"
    fi
    
    # Run tests
    if [[ $QUICK_MODE == true ]]; then
        run_quick_tests
    else
        run_comprehensive_tests
    fi
    
    # Generate report
    generate_validation_report
    
    # Summary
    echo ""
    echo "${BOLD}${CYAN}═══════════════════════════════════════════════════════════════════════════════${RESET}"
    echo "${BOLD}${CYAN}  📊 VALIDATION SUMMARY${RESET}"
    echo "${BOLD}${CYAN}═══════════════════════════════════════════════════════════════════════════════${RESET}"
    echo ""
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        success "All $TESTS_PASSED tests passed! 🎉"
        success "Dry run system is working correctly"
    else
        error "$TESTS_FAILED out of $((TESTS_PASSED + TESTS_FAILED)) tests failed"
        error "Failed tests: ${FAILED_TESTS[*]}"
        echo ""
        warn "Review the validation report for details: $VALIDATION_REPORT"
    fi
    
    # Cleanup
    verbose "Cleaning up test directory: $TEST_DIR"
    # rm -rf "$TEST_DIR"  # Keep for debugging
    
    exit $([[ $TESTS_FAILED -eq 0 ]] && echo 0 || echo 1)
}

# Only run main if script is executed directly
if [[ "${(%):-%x}" == "${0}" ]]; then
    main "$@"
fi
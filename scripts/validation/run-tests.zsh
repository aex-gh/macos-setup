#!/usr/bin/env zsh

readonly SCRIPT_NAME="${0:t}"
readonly SCRIPT_DIR="${0:A:h}"

# Load common library
source "${SCRIPT_DIR}/../lib/common.zsh"

# Test execution variables
typeset -g TEST_RESULTS=()
typeset -g FAILED_TESTS=()

check_prerequisites() {
    info "Checking test prerequisites..."
    check_requirements bats
    
    local test_dir="${PWD}/tests"
    [[ ! -d "${test_dir}" ]] && { error "Test directory not found: ${test_dir}"; exit 1; }
    [[ ! -f "${test_dir}/test_helper.bash" ]] && { error "Test helper not found"; exit 1; }
    
    success "Prerequisites check passed"
}

# Generic test runner function
run_test_suite() {
    local test_name=$1
    local test_pattern=$2
    
    info "Running ${test_name}..."
    local files=($(find tests -name "${test_pattern}" -type f 2>/dev/null))
    [[ ${#files[@]} -eq 0 ]] && { warn "No ${test_name} found"; return 0; }
    
    local failures=()
    for test_file in "${files[@]}"; do
        if bats "${test_file}" >/dev/null 2>&1; then
            success "✓ ${test_file:t}"
        else
            error "✗ ${test_file:t}"
            failures+=("${test_file:t}")
        fi
    done
    
    [[ ${#failures[@]} -eq 0 ]] && return 0
    FAILED_TESTS+=("${test_name}: ${failures[*]}")
    return 1
}

run_unit_tests() {
    run_test_suite "unit tests" "test_*.bats"
}

run_integration_tests() {
    run_test_suite "integration tests" "*integration*.bats"
}

run_device_specific_tests() {
    info "Running device-specific tests..."
    local devices=("macbook-pro" "mac-studio" "mac-mini")
    local failures=()
    
    for device in "${devices[@]}"; do
        if scripts/setup/setup.zsh --dry-run --device "${device}" >/dev/null 2>&1; then
            success "✓ ${device}"
        else
            error "✗ ${device}"
            failures+=("${device}")
        fi
    done
    
    [[ ${#failures[@]} -eq 0 ]] && return 0
    FAILED_TESTS+=("device tests: ${failures[*]}")
    return 1
}

# Generic syntax validator
validate_files() {
    local file_type=$1
    local pattern=$2
    local validator=$3
    
    local files=($(find . -name "${pattern}" -type f 2>/dev/null))
    local failures=()
    
    for file in "${files[@]}"; do
        if eval "${validator} '${file}'" >/dev/null 2>&1; then
            success "✓ ${file:t}"
        else
            error "✗ ${file:t}"
            failures+=("${file:t}")
        fi
    done
    
    [[ ${#failures[@]} -eq 0 ]] && return 0
    FAILED_TESTS+=("${file_type}: ${failures[*]}")
    return 1
}

run_script_syntax_tests() {
    info "Running script syntax validation..."
    validate_files "script syntax" "scripts/*.zsh" "zsh -n"
    local syntax_result=$?
    
    info "Validating Brewfiles..."
    validate_files "brewfile format" "configs/*/Brewfile" "grep -q 'brew\\|cask\\|mas'"
    local brewfile_result=$?
    
    [[ $syntax_result -eq 0 && $brewfile_result -eq 0 ]]
}

run_security_tests() {
    info "Running security validation tests..."
    local issues=()
    
    # Security pattern checks
    local patterns=(
        "password.*=:hardcoded_passwords"
        "secret.*=:hardcoded_secrets"
        "chmod 777\|chmod 666:insecure_permissions"
    )
    
    for pattern_check in "${patterns[@]}"; do
        local pattern="${pattern_check%:*}"
        local issue_type="${pattern_check#*:}"
        
        if grep -r -i "${pattern}" scripts/ | grep -v "PASSWORD_PROMPT\|read.*password\|op read\|SECRET_PROMPT\|read.*secret" >/dev/null 2>&1; then
            error "Found ${issue_type}"
            issues+=("${issue_type}")
        fi
    done
    
    [[ ${#issues[@]} -eq 0 ]] && return 0
    FAILED_TESTS+=("security: ${issues[*]}")
    return 1
}

run_documentation_tests() {
    info "Running documentation validation..."
    local required_docs=("README.md" "docs/project-plan.md" "docs/macos-zsh-standards.md" "docs/todo.md")
    local missing=()
    
    for doc in "${required_docs[@]}"; do
        [[ ! -f "${doc}" ]] && missing+=("${doc}")
    done
    
    [[ ${#missing[@]} -eq 0 ]] && return 0
    FAILED_TESTS+=("docs: ${missing[*]}")
    return 1
}

run_performance_tests() {
    info "Running performance tests..."
    local start_time=$(date +%s)
    
    if timeout 30 scripts/setup/setup.zsh --dry-run >/dev/null 2>&1; then
        local duration=$(($(date +%s) - start_time))
        [[ $duration -lt 30 ]] && success "✓ Setup script performance OK (${duration}s)" || warn "? Setup script slow (${duration}s)"
    else
        warn "? Setup script timed out"
    fi
}

generate_test_report() {
    local report_file="test-results-$(date +%Y%m%d-%H%M%S).txt"
    {
        echo "macOS Setup Test Report - $(date)"
        echo "================================"
        echo "Environment: macOS $(sw_vers -productVersion) on $(hostname)"
        echo "Test Coverage: $(find scripts -name "*.zsh" | wc -l) scripts, $(find tests -name "*.bats" | wc -l) test files"
        echo
        echo "Results:"
        printf "%s\n" "${TEST_RESULTS[@]}" 2>/dev/null || echo "No detailed results available"
        echo
        [[ ${#FAILED_TESTS[@]} -gt 0 ]] && echo "Failures: ${FAILED_TESTS[*]}"
    } > "${report_file}"
    success "Report saved: ${report_file}"
}

show_help() {
    cat << 'EOF'
macOS Setup Test Runner

Usage: run-tests.zsh [options] [test-types]

Options:
  -h, --help          Show help
  -r, --report        Generate report
  -q, --quick         Essential tests only

Test Types: unit, integration, device, syntax, security, docs, performance, all

Examples:
  run-tests.zsh                 # Run all tests
  run-tests.zsh unit syntax     # Run specific tests
  run-tests.zsh --quick         # Essential tests only
EOF
}

main() {
    local test_types=() generate_report=false quick_mode=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help) show_help; exit 0 ;;
            -r|--report) generate_report=true; shift ;;
            -q|--quick) quick_mode=true; shift ;;
            unit|integration|device|syntax|security|docs|performance|all) test_types+=("$1"); shift ;;
            *) error "Unknown option: $1"; show_help; exit 1 ;;
        esac
    done
    
    # Default test selection
    [[ ${#test_types[@]} -eq 0 ]] && test_types=($(${quick_mode} && echo "unit syntax security" || echo "all"))
    
    header "Starting macOS setup test suite..."
    check_prerequisites
    
    # Test execution mapping
    local -A test_functions=(
        [unit]="run_unit_tests"
        [integration]="run_integration_tests"
        [device]="run_device_specific_tests"
        [syntax]="run_script_syntax_tests"
        [security]="run_security_tests"
        [docs]="run_documentation_tests"
        [performance]="run_performance_tests"
    )
    
    local failed=false
    for test_type in "${test_types[@]}"; do
        if [[ $test_type == "all" ]]; then
            for func in "${test_functions[@]}"; do
                $func || failed=true
            done
        else
            ${test_functions[$test_type]} || failed=true
        fi
    done
    
    ${generate_report} && generate_test_report
    
    if $failed; then
        error "Test failures detected: ${FAILED_TESTS[*]}"
        exit 1
    else
        success "All tests completed successfully!"
        exit 0
    fi
}

# Execute main function if script is run directly
[[ "${ZSH_EVAL_CONTEXT:-toplevel}" == "toplevel" ]] && main "$@"
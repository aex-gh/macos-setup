#!/usr/bin/env zsh
set -euo pipefail

readonly SCRIPT_NAME="${0:t}"
readonly RED=$(tput setaf 1)
readonly GREEN=$(tput setaf 2)
readonly YELLOW=$(tput setaf 3)
readonly BLUE=$(tput setaf 4)
readonly RESET=$(tput sgr0)

info() {
    echo "${BLUE}[INFO]${RESET} $*"
}

success() {
    echo "${GREEN}[SUCCESS]${RESET} $*"
}

warn() {
    echo "${YELLOW}[WARN]${RESET} $*"
}

error() {
    echo "${RED}[ERROR]${RESET} $*" >&2
}

cleanup() {
    local exit_code=$?
    if [[ ${exit_code} -ne 0 ]]; then
        error "Test runner failed with exit code ${exit_code}"
    fi
    exit ${exit_code}
}

trap cleanup EXIT INT TERM

check_prerequisites() {
    info "Checking test prerequisites..."
    
    # Check for BATS
    if ! command -v bats >/dev/null 2>&1; then
        error "BATS is required for testing. Install with: brew install bats-core"
        exit 1
    fi
    
    # Check for test directory
    local test_dir="${PWD}/tests"
    if [[ ! -d "${test_dir}" ]]; then
        error "Test directory not found: ${test_dir}"
        exit 1
    fi
    
    # Check for test helper
    if [[ ! -f "${test_dir}/test_helper.bash" ]]; then
        error "Test helper not found: ${test_dir}/test_helper.bash"
        exit 1
    fi
    
    success "Prerequisites check passed"
}

run_unit_tests() {
    info "Running unit tests..."
    
    local test_files=(
        "test_setup_main.bats"
        "test_homebrew.bats"
        "test_dotfiles.bats"
        "test_security.bats"
        "test_advanced_features.bats"
    )
    
    local failed_tests=()
    local passed_tests=()
    
    for test_file in "${test_files[@]}"; do
        local test_path="tests/${test_file}"
        
        if [[ -f "${test_path}" ]]; then
            info "Running ${test_file}..."
            
            if bats "${test_path}"; then
                passed_tests+=("${test_file}")
                success "✓ ${test_file}"
            else
                failed_tests+=("${test_file}")
                error "✗ ${test_file}"
            fi
            echo
        else
            warn "Test file not found: ${test_path}"
        fi
    done
    
    # Report results
    if [[ ${#failed_tests[@]} -eq 0 ]]; then
        success "All unit tests passed (${#passed_tests[@]})"
    else
        error "Unit test failures: ${failed_tests[*]}"
        return 1
    fi
}

run_integration_tests() {
    info "Running integration tests..."
    
    local integration_test="tests/test_integration.bats"
    
    if [[ -f "${integration_test}" ]]; then
        if bats "${integration_test}"; then
            success "✓ Integration tests passed"
        else
            error "✗ Integration tests failed"
            return 1
        fi
    else
        warn "Integration test file not found: ${integration_test}"
    fi
}

run_device_specific_tests() {
    info "Running device-specific tests..."
    
    local devices=("macbook-pro" "mac-studio" "mac-mini")
    local test_failures=()
    
    for device in "${devices[@]}"; do
        info "Testing ${device} configuration..."
        
        # Test device detection
        if scripts/setup.zsh --dry-run --device "${device}" >/dev/null 2>&1; then
            success "✓ ${device} configuration valid"
        else
            error "✗ ${device} configuration failed"
            test_failures+=("${device}")
        fi
    done
    
    if [[ ${#test_failures[@]} -eq 0 ]]; then
        success "All device-specific tests passed"
    else
        error "Device test failures: ${test_failures[*]}"
        return 1
    fi
}

run_script_syntax_tests() {
    info "Running script syntax validation..."
    
    local script_failures=()
    
    # Test all shell scripts for syntax errors
    find scripts -name "*.zsh" -type f | while read -r script; do
        if zsh -n "${script}"; then
            success "✓ ${script} syntax valid"
        else
            error "✗ ${script} syntax error"
            script_failures+=("${script}")
        fi
    done
    
    # Test Brewfiles for basic syntax
    find configs -name "Brewfile" -type f | while read -r brewfile; do
        if [[ -s "${brewfile}" ]]; then
            # Check for required elements
            if grep -q "brew\|cask\|mas" "${brewfile}"; then
                success "✓ ${brewfile} format valid"
            else
                warn "? ${brewfile} appears empty or invalid"
            fi
        else
            warn "? ${brewfile} is empty"
        fi
    done
    
    if [[ ${#script_failures[@]} -eq 0 ]]; then
        success "All script syntax tests passed"
    else
        error "Script syntax failures: ${script_failures[*]}"
        return 1
    fi
}

run_security_tests() {
    info "Running security validation tests..."
    
    local security_issues=()
    
    # Check for hardcoded credentials
    info "Checking for hardcoded credentials..."
    if grep -r -i "password.*=" scripts/ | grep -v "PASSWORD_PROMPT\|read.*password\|op read"; then
        error "Found potential hardcoded passwords"
        security_issues+=("hardcoded_passwords")
    fi
    
    if grep -r -i "secret.*=" scripts/ | grep -v "SECRET_PROMPT\|read.*secret\|op read"; then
        error "Found potential hardcoded secrets"
        security_issues+=("hardcoded_secrets")
    fi
    
    # Check for proper permission handling
    info "Checking for proper permission handling..."
    local scripts_needing_sudo=(
        "setup-filevault.zsh"
        "setup-hardening.zsh"
        "system-maintenance.zsh"
    )
    
    for script in "${scripts_needing_sudo[@]}"; do
        if [[ -f "scripts/${script}" ]]; then
            if grep -q "sudo\|privilege\|admin" "scripts/${script}"; then
                success "✓ ${script} handles privileges"
            else
                warn "? ${script} may need privilege checking"
            fi
        fi
    done
    
    # Check for secure file operations
    info "Checking for secure file operations..."
    if grep -r "chmod 777\|chmod 666" scripts/; then
        error "Found insecure file permissions"
        security_issues+=("insecure_permissions")
    fi
    
    if [[ ${#security_issues[@]} -eq 0 ]]; then
        success "All security tests passed"
    else
        error "Security issues found: ${security_issues[*]}"
        return 1
    fi
}

run_documentation_tests() {
    info "Running documentation validation..."
    
    local doc_issues=()
    
    # Check for required documentation files
    local required_docs=(
        "README.md"
        "docs/project-plan.md"
        "docs/macos-zsh-standards.md"
        "docs/todo.md"
        "docs/compatibility-features.md"
    )
    
    for doc in "${required_docs[@]}"; do
        if [[ -f "${doc}" ]]; then
            success "✓ ${doc} exists"
        else
            error "✗ Missing required documentation: ${doc}"
            doc_issues+=("${doc}")
        fi
    done
    
    # Check that scripts have basic documentation
    find scripts -name "*.zsh" -type f | while read -r script; do
        if head -20 "${script}" | grep -q "#!/usr/bin/env zsh"; then
            if head -20 "${script}" | grep -q "# .*"; then
                success "✓ ${script} has header documentation"
            else
                warn "? ${script} missing description"
            fi
        else
            error "✗ ${script} missing shebang"
            doc_issues+=("${script}")
        fi
    done
    
    if [[ ${#doc_issues[@]} -eq 0 ]]; then
        success "All documentation tests passed"
    else
        error "Documentation issues: ${doc_issues[*]}"
        return 1
    fi
}

run_performance_tests() {
    info "Running performance tests..."
    
    # Test script execution time
    local slow_scripts=()
    local time_limit=30  # seconds
    
    # Test main setup script performance
    local start_time end_time duration
    start_time=$(date +%s)
    
    if timeout ${time_limit} scripts/setup.zsh --dry-run >/dev/null 2>&1; then
        end_time=$(date +%s)
        duration=$((end_time - start_time))
        
        if [[ ${duration} -lt 10 ]]; then
            success "✓ Main setup script is fast (${duration}s)"
        elif [[ ${duration} -lt 30 ]]; then
            warn "? Main setup script is slow (${duration}s)"
        else
            error "✗ Main setup script is too slow (${duration}s)"
            slow_scripts+=("setup.zsh")
        fi
    else
        error "✗ Main setup script timed out (>${time_limit}s)"
        slow_scripts+=("setup.zsh")
    fi
    
    if [[ ${#slow_scripts[@]} -eq 0 ]]; then
        success "All performance tests passed"
    else
        warn "Slow scripts detected: ${slow_scripts[*]}"
        # Don't fail on performance issues, just warn
    fi
}

generate_test_report() {
    info "Generating test report..."
    
    local report_file="test-results-$(date +%Y%m%d-%H%M%S).txt"
    
    {
        echo "macOS Setup Test Report"
        echo "Generated: $(date)"
        echo "================================"
        echo
        
        echo "Test Environment:"
        echo "- macOS Version: $(sw_vers -productVersion)"
        echo "- Hostname: $(hostname)"
        echo "- BATS Version: $(bats --version)"
        echo "- Working Directory: $(pwd)"
        echo
        
        echo "Test Results Summary:"
        echo "- Unit Tests: ${unit_test_result:-Not Run}"
        echo "- Integration Tests: ${integration_test_result:-Not Run}"
        echo "- Device-Specific Tests: ${device_test_result:-Not Run}"
        echo "- Script Syntax Tests: ${syntax_test_result:-Not Run}"
        echo "- Security Tests: ${security_test_result:-Not Run}"
        echo "- Documentation Tests: ${doc_test_result:-Not Run}"
        echo "- Performance Tests: ${perf_test_result:-Not Run}"
        echo
        
        echo "Test Coverage:"
        local total_scripts
        total_scripts=$(find scripts -name "*.zsh" | wc -l)
        echo "- Total Scripts: ${total_scripts}"
        echo "- Scripts with Tests: $(find tests -name "*.bats" | wc -l)"
        
        echo
        echo "Recommendations:"
        if [[ "${unit_test_result}" == "PASS" ]]; then
            echo "- ✓ Core functionality is working correctly"
        else
            echo "- ✗ Core functionality needs attention"
        fi
        
        if [[ "${security_test_result}" == "PASS" ]]; then
            echo "- ✓ Security configurations appear sound"
        else
            echo "- ✗ Security configurations need review"
        fi
        
    } > "${report_file}"
    
    success "Test report saved to ${report_file}"
    
    # Also display summary
    echo
    info "Test Summary:"
    echo "Report: ${report_file}"
    echo "Overall Status: ${overall_status:-UNKNOWN}"
}

show_help() {
    cat << EOF
macOS Setup Test Runner

Usage: ${SCRIPT_NAME} [options] [test-types]

Options:
  --help, -h          Show this help message
  --verbose, -v       Verbose output
  --report, -r        Generate detailed test report
  --quick, -q         Run only essential tests

Test Types:
  unit                Run unit tests only
  integration         Run integration tests only
  device              Run device-specific tests only
  syntax              Run script syntax validation only
  security            Run security validation only
  docs                Run documentation validation only
  performance         Run performance tests only
  all                 Run all tests (default)

Examples:
  ${SCRIPT_NAME}                    # Run all tests
  ${SCRIPT_NAME} unit integration   # Run specific test types
  ${SCRIPT_NAME} --quick            # Run essential tests only
  ${SCRIPT_NAME} --report           # Generate detailed report

EOF
}

main() {
    local test_types=()
    local verbose=false
    local generate_report=false
    local quick_mode=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h)
                show_help
                exit 0
                ;;
            --verbose|-v)
                verbose=true
                shift
                ;;
            --report|-r)
                generate_report=true
                shift
                ;;
            --quick|-q)
                quick_mode=true
                shift
                ;;
            unit|integration|device|syntax|security|docs|performance|all)
                test_types+=("$1")
                shift
                ;;
            *)
                error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Default to all tests if none specified
    if [[ ${#test_types[@]} -eq 0 ]]; then
        if [[ "${quick_mode}" == "true" ]]; then
            test_types=("unit" "syntax" "security")
        else
            test_types=("all")
        fi
    fi
    
    info "Starting macOS setup test suite..."
    
    check_prerequisites
    
    # Track test results
    local overall_status="PASS"
    local unit_test_result="SKIP"
    local integration_test_result="SKIP"
    local device_test_result="SKIP"
    local syntax_test_result="SKIP"
    local security_test_result="SKIP"
    local doc_test_result="SKIP"
    local perf_test_result="SKIP"
    
    # Run requested tests
    for test_type in "${test_types[@]}"; do
        case "${test_type}" in
            unit|all)
                if run_unit_tests; then
                    unit_test_result="PASS"
                else
                    unit_test_result="FAIL"
                    overall_status="FAIL"
                fi
                ;;
            integration|all)
                if run_integration_tests; then
                    integration_test_result="PASS"
                else
                    integration_test_result="FAIL"
                    overall_status="FAIL"
                fi
                ;;
            device|all)
                if run_device_specific_tests; then
                    device_test_result="PASS"
                else
                    device_test_result="FAIL"
                    overall_status="FAIL"
                fi
                ;;
            syntax|all)
                if run_script_syntax_tests; then
                    syntax_test_result="PASS"
                else
                    syntax_test_result="FAIL"
                    overall_status="FAIL"
                fi
                ;;
            security|all)
                if run_security_tests; then
                    security_test_result="PASS"
                else
                    security_test_result="FAIL"
                    overall_status="FAIL"
                fi
                ;;
            docs|all)
                if run_documentation_tests; then
                    doc_test_result="PASS"
                else
                    doc_test_result="FAIL"
                    overall_status="FAIL"
                fi
                ;;
            performance|all)
                if run_performance_tests; then
                    perf_test_result="PASS"
                else
                    perf_test_result="WARN"
                    # Don't fail overall on performance issues
                fi
                ;;
        esac
    done
    
    # Generate report if requested
    if [[ "${generate_report}" == "true" ]]; then
        generate_test_report
    fi
    
    # Final status
    echo
    if [[ "${overall_status}" == "PASS" ]]; then
        success "All tests completed successfully!"
        exit 0
    else
        error "Some tests failed. Please review the output above."
        exit 1
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
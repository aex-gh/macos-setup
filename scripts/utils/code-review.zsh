#!/usr/bin/env zsh

# Script metadata
readonly SCRIPT_NAME="${0:t}"
readonly SCRIPT_DIR="${0:A:h}"

# Load common library
source "${SCRIPT_DIR}/../lib/common.zsh"

check_script_standards() {
    info "Checking script adherence to zsh standards..."
    
    local issues=()
    
    find scripts -name "*.zsh" -type f | while read -r script; do
        local script_issues=()
        
        # Check shebang
        if ! head -1 "${script}" | grep -q "#!/usr/bin/env zsh"; then
            script_issues+=("Missing or incorrect shebang")
        fi
        
        # Check set -euo pipefail
        if ! head -10 "${script}" | grep -q "set -euo pipefail"; then
            script_issues+=("Missing 'set -euo pipefail'")
        fi
        
        # Check for color definitions
        if ! grep -q "readonly.*RED\|readonly.*GREEN\|readonly.*BLUE" "${script}"; then
            script_issues+=("Missing color definitions")
        fi
        
        # Check for logging functions
        if ! grep -q "info()\|success()\|warn()\|error()" "${script}"; then
            script_issues+=("Missing logging functions")
        fi
        
        # Check for cleanup function
        if ! grep -q "cleanup()" "${script}"; then
            script_issues+=("Missing cleanup function")
        fi
        
        # Check for trap handling
        if ! grep -q "trap.*cleanup.*EXIT" "${script}"; then
            script_issues+=("Missing trap handling")
        fi
        
        # Check for readonly SCRIPT_NAME
        if ! grep -q "readonly SCRIPT_NAME" "${script}"; then
            script_issues+=("Missing readonly SCRIPT_NAME")
        fi
        
        # Report issues for this script
        if [[ ${#script_issues[@]} -gt 0 ]]; then
            warn "Issues in ${script}:"
            for issue in "${script_issues[@]}"; do
                echo "  - ${issue}"
            done
            echo
        else
            success "✓ ${script} follows standards"
        fi
    done
}

check_security_issues() {
    info "Checking for security issues..."
    
    local security_issues=()
    
    # Check for hardcoded credentials
    info "Scanning for hardcoded credentials..."
    if grep -r -i "password.*=" scripts/ | grep -v "PASSWORD_PROMPT\|read.*password\|op read\|echo.*password"; then
        security_issues+=("Potential hardcoded passwords found")
    fi
    
    if grep -r -i "secret.*=" scripts/ | grep -v "SECRET_PROMPT\|read.*secret\|op read"; then
        security_issues+=("Potential hardcoded secrets found")
    fi
    
    if grep -r -i "key.*=" scripts/ | grep -v "KEY_PATH\|SSH_KEY\|GPG_KEY\|op read\|api.*key.*read"; then
        security_issues+=("Potential hardcoded keys found")
    fi
    
    # Check for insecure permissions
    info "Checking for insecure file permissions..."
    if grep -r "chmod 777\|chmod 666" scripts/; then
        security_issues+=("Insecure file permissions (777/666) found")
    fi
    
    # Check for unquoted variables
    info "Checking for unquoted variables..."
    if grep -r '\$[A-Z_][A-Z0-9_]*[^"]' scripts/ | grep -v "echo\|printf\|case\|\[\["; then
        warn "Potential unquoted variables found (may need review)"
    fi
    
    # Check for unsafe temp file creation
    info "Checking for unsafe temporary file creation..."
    if grep -r ">/tmp/\|echo.*>/tmp/" scripts/; then
        security_issues+=("Unsafe temporary file creation found")
    fi
    
    # Check for eval usage
    info "Checking for eval usage..."
    if grep -r "eval " scripts/; then
        security_issues+=("eval usage found (potential security risk)")
    fi
    
    # Report security issues
    if [[ ${#security_issues[@]} -gt 0 ]]; then
        error "Security issues found:"
        for issue in "${security_issues[@]}"; do
            echo "  - ${issue}"
        done
        return 1
    else
        success "No security issues detected"
    fi
}

check_error_handling() {
    info "Checking error handling patterns..."
    
    find scripts -name "*.zsh" -type f | while read -r script; do
        local error_issues=()
        
        # Check for command substitution without error handling
        if grep -q '\$(' "${script}" && ! grep -q "set -euo pipefail" "${script}"; then
            error_issues+=("Command substitution without proper error handling")
        fi
        
        # Check for network operations without error handling
        if grep -E "(curl|wget|git clone)" "${script}" | grep -v "if.*then\|&&\|||"; then
            error_issues+=("Network operations without explicit error handling")
        fi
        
        # Check for file operations without error handling
        if grep -E "(cp|mv|rm|mkdir)" "${script}" | grep -v "if.*then\|&&\|||"; then
            error_issues+=("File operations without explicit error handling")
        fi
        
        if [[ ${#error_issues[@]} -gt 0 ]]; then
            warn "Error handling issues in ${script}:"
            for issue in "${error_issues[@]}"; do
                echo "  - ${issue}"
            done
            echo
        fi
    done
}

check_documentation() {
    info "Checking script documentation..."
    
    find scripts -name "*.zsh" -type f | while read -r script; do
        local doc_issues=()
        
        # Check for script description
        if ! head -20 "${script}" | grep -q "^# .*[Ss]cript\|^# .*[Tt]ool\|^# .*[Ss]etup"; then
            doc_issues+=("Missing script description")
        fi
        
        # Check for usage information
        if grep -q "show_help\|--help" "${script}" && ! grep -q "Usage:" "${script}"; then
            doc_issues+=("Missing usage information")
        fi
        
        # Check for function documentation
        local functions=$(grep "^[a-zA-Z_][a-zA-Z0-9_]*() {" "${script}" | wc -l)
        local documented_functions=$(grep -B 1 "^[a-zA-Z_][a-zA-Z0-9_]*() {" "${script}" | grep "^#" | wc -l)
        
        if [[ ${functions} -gt 5 ]] && [[ ${documented_functions} -lt $((functions / 2)) ]]; then
            doc_issues+=("Insufficient function documentation")
        fi
        
        if [[ ${#doc_issues[@]} -gt 0 ]]; then
            warn "Documentation issues in ${script}:"
            for issue in "${doc_issues[@]}"; do
                echo "  - ${issue}"
            done
            echo
        fi
    done
}

check_portability() {
    info "Checking macOS/zsh portability..."
    
    find scripts -name "*.zsh" -type f | while read -r script; do
        local portability_issues=()
        
        # Check for bash-specific syntax
        if grep -E "function [a-zA-Z_]|declare |local -[a-Z]" "${script}"; then
            portability_issues+=("bash-specific syntax detected")
        fi
        
        # Check for Linux-specific commands
        if grep -E "apt-get|yum|systemctl|service " "${script}"; then
            portability_issues+=("Linux-specific commands found")
        fi
        
        # Check for hardcoded paths
        if grep -E "/usr/local/bin|/opt/homebrew" "${script}" | grep -v "command -v\|which\|PATH"; then
            portability_issues+=("Hardcoded paths found (should check PATH)")
        fi
        
        if [[ ${#portability_issues[@]} -gt 0 ]]; then
            warn "Portability issues in ${script}:"
            for issue in "${portability_issues[@]}"; do
                echo "  - ${issue}"
            done
            echo
        fi
    done
}

check_performance() {
    info "Checking for performance issues..."
    
    find scripts -name "*.zsh" -type f | while read -r script; do
        local perf_issues=()
        
        # Check for inefficient loops
        if grep -A 5 -B 5 "for.*in.*\$(.*)" "${script}" | grep -q "grep\|awk\|sed"; then
            perf_issues+=("Potentially inefficient loop with external commands")
        fi
        
        # Check for repeated command executions
        local repeated_commands=$(grep -o "brew \|git \|npm " "${script}" | sort | uniq -c | awk '$1 > 10 {print $2}')
        if [[ -n "${repeated_commands}" ]]; then
            perf_issues+=("Repeated command executions detected")
        fi
        
        # Check for unnecessary cat usage
        if grep "cat.*|" "${script}"; then
            perf_issues+=("Unnecessary cat usage (UUOC)")
        fi
        
        if [[ ${#perf_issues[@]} -gt 0 ]]; then
            warn "Performance issues in ${script}:"
            for issue in "${perf_issues[@]}"; do
                echo "  - ${issue}"
            done
            echo
        fi
    done
}

check_consistency() {
    info "Checking for consistency across scripts..."
    
    local consistency_issues=()
    
    # Check color variable consistency
    local color_patterns=$(grep -h "readonly.*=" scripts/*.zsh | grep -E "RED|GREEN|YELLOW|BLUE" | sort | uniq)
    local expected_colors="readonly RED=\$(tput setaf 1)
readonly GREEN=\$(tput setaf 2)
readonly YELLOW=\$(tput setaf 3)
readonly BLUE=\$(tput setaf 4)
readonly RESET=\$(tput sgr0)"
    
    # Check function naming consistency
    local function_patterns=$(grep -h "^[a-zA-Z_][a-zA-Z0-9_]*() {" scripts/*.zsh | grep -E "info|success|warn|error" | sort | uniq)
    
    # Check variable naming consistency
    if grep -h "readonly SCRIPT_DIR\|readonly SCRIPT_PATH" scripts/*.zsh | sort | uniq | wc -l | grep -q "[2-9]"; then
        consistency_issues+=("Inconsistent script directory variable naming")
    fi
    
    if [[ ${#consistency_issues[@]} -gt 0 ]]; then
        warn "Consistency issues found:"
        for issue in "${consistency_issues[@]}"; do
            echo "  - ${issue}"
        done
        echo
    else
        success "Scripts are consistent across the project"
    fi
}

check_file_structure() {
    info "Checking file structure and naming..."
    
    local structure_issues=()
    
    # Check for executable permissions
    find scripts -name "*.zsh" -type f ! -executable | while read -r script; do
        warn "Script not executable: ${script}"
    done
    
    # Check for proper file extensions
    find scripts -type f ! -name "*.zsh" ! -name ".*" | while read -r file; do
        warn "Non-zsh file in scripts directory: ${file}"
    done
    
    # Check for consistent naming
    find scripts -name "*.zsh" | grep -E "[A-Z]|_.*_" | while read -r script; do
        warn "Inconsistent naming: ${script} (should be kebab-case)"
    done
    
    # Check for missing main function
    find scripts -name "*.zsh" -type f | while read -r script; do
        if ! grep -q "main()" "${script}"; then
            warn "Missing main() function: ${script}"
        fi
        
        if ! grep -q 'if.*BASH_SOURCE.*0.*then' "${script}"; then
            warn "Missing script execution guard: ${script}"
        fi
    done
}

generate_review_report() {
    info "Generating code review report..."
    
    local report_file="code-review-$(date +%Y%m%d-%H%M%S).md"
    
    {
        echo "# Code Review Report"
        echo "Generated: $(date)"
        echo "Project: macOS Setup Automation"
        echo ""
        
        echo "## Summary"
        echo "- Total scripts reviewed: $(find scripts -name "*.zsh" | wc -l)"
        echo "- Configuration files: $(find configs -name "*" -type f | wc -l)"
        echo "- Test files: $(find tests -name "*.bats" | wc -l)"
        echo "- Documentation files: $(find docs -name "*.md" | wc -l)"
        echo ""
        
        echo "## Standards Compliance"
        check_script_standards 2>&1
        echo ""
        
        echo "## Security Analysis"
        check_security_issues 2>&1
        echo ""
        
        echo "## Error Handling"
        check_error_handling 2>&1
        echo ""
        
        echo "## Documentation Review"
        check_documentation 2>&1
        echo ""
        
        echo "## Portability Check"
        check_portability 2>&1
        echo ""
        
        echo "## Performance Analysis"
        check_performance 2>&1
        echo ""
        
        echo "## Consistency Review"
        check_consistency 2>&1
        echo ""
        
        echo "## Recommendations"
        echo "1. Address any security issues immediately"
        echo "2. Improve error handling in flagged scripts"
        echo "3. Add documentation where missing"
        echo "4. Consider performance optimizations"
        echo "5. Maintain consistency across all scripts"
        echo ""
        
        echo "## Next Steps"
        echo "- Fix high-priority issues"
        echo "- Update documentation"
        echo "- Run automated tests"
        echo "- Schedule follow-up review"
        
    } > "${report_file}"
    
    success "Code review report saved to ${report_file}"
    echo "${report_file}"
}

show_help() {
    cat << EOF
Code Review Tool for macOS Setup Scripts

Usage: ${SCRIPT_NAME} [options] [checks]

Options:
  --help, -h          Show this help message
  --report, -r        Generate detailed report
  --fix, -f           Attempt to fix common issues
  --verbose, -v       Verbose output

Checks:
  standards           Check adherence to zsh standards
  security            Check for security issues
  errors              Check error handling patterns
  docs                Check documentation
  portability         Check macOS/zsh portability
  performance         Check for performance issues
  consistency         Check consistency across scripts
  structure           Check file structure and naming
  all                 Run all checks (default)

Examples:
  ${SCRIPT_NAME}                    # Run all checks
  ${SCRIPT_NAME} security errors    # Run specific checks
  ${SCRIPT_NAME} --report           # Generate detailed report

EOF
}

main() {
    local checks=()
    local generate_report=false
    local fix_issues=false
    local verbose=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h)
                show_help
                exit 0
                ;;
            --report|-r)
                generate_report=true
                shift
                ;;
            --fix|-f)
                fix_issues=true
                shift
                ;;
            --verbose|-v)
                verbose=true
                shift
                ;;
            standards|security|errors|docs|portability|performance|consistency|structure|all)
                checks+=("$1")
                shift
                ;;
            *)
                error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Default to all checks if none specified
    if [[ ${#checks[@]} -eq 0 ]]; then
        checks=("all")
    fi
    
    info "Starting code review for macOS setup scripts..."
    echo
    
    local overall_status="PASS"
    
    # Run requested checks
    for check in "${checks[@]}"; do
        case "${check}" in
            standards|all)
                if ! check_script_standards; then
                    overall_status="FAIL"
                fi
                echo
                ;;
            security|all)
                if ! check_security_issues; then
                    overall_status="FAIL"
                fi
                echo
                ;;
            errors|all)
                check_error_handling
                echo
                ;;
            docs|all)
                check_documentation
                echo
                ;;
            portability|all)
                check_portability
                echo
                ;;
            performance|all)
                check_performance
                echo
                ;;
            consistency|all)
                check_consistency
                echo
                ;;
            structure|all)
                check_file_structure
                echo
                ;;
        esac
    done
    
    # Generate report if requested
    if [[ "${generate_report}" == "true" ]]; then
        local report_file
        report_file=$(generate_review_report)
        info "Detailed report available: ${report_file}"
    fi
    
    # Final status
    echo
    if [[ "${overall_status}" == "PASS" ]]; then
        success "Code review completed successfully!"
        exit 0
    else
        error "Code review found issues that need attention."
        exit 1
    fi
}

if [[ "${(%):-%x}" == "${0}" ]]; then
    main "$@"
fi
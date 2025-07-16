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
        error "Performance optimization failed with exit code ${exit_code}"
    fi
    exit ${exit_code}
}

trap cleanup EXIT INT TERM

profile_script_performance() {
    info "Profiling script performance..."
    
    local scripts_dir="scripts"
    local results_file="performance-results-$(date +%Y%m%d-%H%M%S).csv"
    
    echo "Script,Execution Time (seconds),Memory Usage (KB),Status" > "${results_file}"
    
    find "${scripts_dir}" -name "*.zsh" -type f | while read -r script; do
        if [[ -x "${script}" ]]; then
            info "Profiling ${script}..."
            
            local start_time end_time duration memory_usage script_status
            
            # Measure execution time and memory
            start_time=$(date +%s.%N)
            
            if timeout 60 "${script}" --dry-run >/dev/null 2>&1; then
                script_status="SUCCESS"
            else
                script_status="TIMEOUT_OR_ERROR"
            fi
            
            end_time=$(date +%s.%N)
            duration=$(echo "${end_time} - ${start_time}" | bc)
            
            # Get memory usage (approximation)
            memory_usage=$(ps -o rss= -p $$ | tail -1 | tr -d ' ')
            
            echo "${script},${duration},${memory_usage},${script_status}" >> "${results_file}"
            
            # Report slow scripts
            if (( $(echo "${duration} > 10" | bc -l) )); then
                warn "Slow script detected: ${script} (${duration}s)"
            fi
        fi
    done
    
    success "Performance profiling complete. Results: ${results_file}"
}

optimize_homebrew_operations() {
    info "Optimizing Homebrew operations..."
    
    # Find scripts that use Homebrew
    local brew_scripts=()
    while IFS= read -r script; do
        brew_scripts+=("${script}")
    done < <(grep -l "brew " scripts/*.zsh)
    
    for script in "${brew_scripts[@]}"; do
        local optimizations=()
        
        # Check for multiple brew update calls
        local update_count
        update_count=$(grep -c "brew update" "${script}" || echo 0)
        if [[ ${update_count} -gt 1 ]]; then
            optimizations+=("Multiple 'brew update' calls - should be consolidated")
        fi
        
        # Check for inefficient package installation
        if grep -q "brew install.*brew install" "${script}"; then
            optimizations+=("Sequential brew install calls - should be batched")
        fi
        
        # Check for missing --quiet flags
        if grep "brew install\|brew upgrade" "${script}" | grep -v -q "\-\-quiet"; then
            optimizations+=("Missing --quiet flags for non-interactive operations")
        fi
        
        if [[ ${#optimizations[@]} -gt 0 ]]; then
            warn "Homebrew optimization opportunities in ${script}:"
            for opt in "${optimizations[@]}"; do
                echo "  - ${opt}"
            done
        fi
    done
}

optimize_network_operations() {
    info "Optimizing network operations..."
    
    # Find scripts with network operations
    local network_scripts=()
    while IFS= read -r script; do
        network_scripts+=("${script}")
    done < <(grep -l "curl\|wget\|git clone" scripts/*.zsh)
    
    for script in "${network_scripts[@]}"; do
        local optimizations=()
        
        # Check for missing timeout options
        if grep "curl" "${script}" | grep -v -q "\-\-max-time\|\-\-connect-timeout"; then
            optimizations+=("curl operations missing timeout settings")
        fi
        
        # Check for missing retry options
        if grep "curl" "${script}" | grep -v -q "\-\-retry"; then
            optimizations+=("curl operations missing retry logic")
        fi
        
        # Check for inefficient git operations
        if grep "git clone" "${script}" | grep -v -q "\-\-depth"; then
            optimizations+=("git clone without --depth (consider shallow clones)")
        fi
        
        # Check for parallel download opportunities
        local download_count
        download_count=$(grep -c "curl\|wget" "${script}" || echo 0)
        if [[ ${download_count} -gt 2 ]]; then
            optimizations+=("Multiple downloads - consider parallel execution")
        fi
        
        if [[ ${#optimizations[@]} -gt 0 ]]; then
            warn "Network optimization opportunities in ${script}:"
            for opt in "${optimizations[@]}"; do
                echo "  - ${opt}"
            done
        fi
    done
}

optimize_file_operations() {
    info "Optimizing file operations..."
    
    find scripts -name "*.zsh" -type f | while read -r script; do
        local optimizations=()
        
        # Check for inefficient loops over files
        if grep -A 5 -B 5 "for.*in.*\$(find\|ls)" "${script}" | grep -q "cp\|mv\|rm"; then
            optimizations+=("File operations in loops - consider bulk operations")
        fi
        
        # Check for unnecessary cat usage (UUOC)
        if grep "cat.*|" "${script}"; then
            optimizations+=("Unnecessary cat usage - direct redirection preferred")
        fi
        
        # Check for inefficient text processing
        if grep "grep.*|.*grep\|sed.*|.*sed" "${script}"; then
            optimizations+=("Chained text processing - consider combining operations")
        fi
        
        # Check for repeated file checks
        local file_checks
        file_checks=$(grep -c "\[\[ -[fed] " "${script}" || echo 0)
        if [[ ${file_checks} -gt 5 ]]; then
            optimizations+=("Many file existence checks - consider caching results")
        fi
        
        if [[ ${#optimizations[@]} -gt 0 ]]; then
            warn "File operation optimization opportunities in ${script}:"
            for opt in "${optimizations[@]}"; do
                echo "  - ${opt}"
            done
        fi
    done
}

optimize_command_execution() {
    info "Optimizing command execution patterns..."
    
    find scripts -name "*.zsh" -type f | while read -r script; do
        local optimizations=()
        
        # Check for command repetition
        local repeated_commands
        repeated_commands=$(grep -o "command -v [a-zA-Z0-9_-]*\|which [a-zA-Z0-9_-]*" "${script}" | sort | uniq -c | awk '$1 > 3 {print $2, $3}')
        if [[ -n "${repeated_commands}" ]]; then
            optimizations+=("Repeated command existence checks - consider caching")
        fi
        
        # Check for subshell usage
        local subshell_count
        subshell_count=$(grep -c "\$(" "${script}" || echo 0)
        if [[ ${subshell_count} -gt 10 ]]; then
            optimizations+=("High subshell usage - consider variable caching")
        fi
        
        # Check for external command usage in loops
        if grep -A 10 -B 2 "for\|while" "${script}" | grep -E "awk|sed|grep|cut"; then
            optimizations+=("External commands in loops - consider pure zsh alternatives")
        fi
        
        # Check for inefficient conditionals
        if grep "\[\[ .*-eq 0.*\]\].*&&.*echo\|\[\[ .*-ne 0.*\]\].*&&.*echo" "${script}"; then
            optimizations+=("Complex conditionals - consider simplification")
        fi
        
        if [[ ${#optimizations[@]} -gt 0 ]]; then
            warn "Command execution optimization opportunities in ${script}:"
            for opt in "${optimizations[@]}"; do
                echo "  - ${opt}"
            done
        fi
    done
}

create_performance_improvements() {
    info "Creating performance improvement suggestions..."
    
    local improvements_file="performance-improvements-$(date +%Y%m%d-%H%M%S).md"
    
    {
        echo "# Performance Improvement Suggestions"
        echo "Generated: $(date)"
        echo ""
        
        echo "## General Optimizations"
        echo ""
        echo "### 1. Batch Operations"
        echo "- Combine multiple Homebrew installations into single commands"
        echo "- Use parallel downloads where possible"
        echo "- Batch file operations instead of individual commands"
        echo ""
        
        echo "### 2. Caching Strategies"
        echo "- Cache command existence checks"
        echo "- Store frequently accessed values in variables"
        echo "- Use temporary files for intermediate results"
        echo ""
        
        echo "### 3. Network Optimizations"
        echo "- Add timeouts to all network operations"
        echo "- Implement retry logic for transient failures"
        echo "- Use shallow git clones where possible"
        echo "- Parallel downloads for multiple files"
        echo ""
        
        echo "### 4. File System Optimizations"
        echo "- Use bulk file operations instead of loops"
        echo "- Avoid unnecessary file existence checks"
        echo "- Use efficient text processing tools"
        echo ""
        
        echo "## Specific Script Optimizations"
        echo ""
        
        # Analyze specific scripts for optimization opportunities
        local heavy_scripts=(
            "scripts/install-homebrew.zsh:Homebrew installation and configuration"
            "scripts/setup-dotfiles.zsh:Dotfiles setup and chezmoi operations"
            "scripts/install-packages.zsh:Package installation and validation"
            "scripts/system-maintenance.zsh:System maintenance and updates"
        )
        
        for script_info in "${heavy_scripts[@]}"; do
            local script="${script_info%%:*}"
            local description="${script_info##*:}"
            
            echo "### $(basename "${script}")"
            echo "${description}"
            echo ""
            
            if [[ -f "${script}" ]]; then
                # Specific optimization suggestions based on script content
                if grep -q "brew install" "${script}"; then
                    echo "- Batch brew install commands: \`brew install pkg1 pkg2 pkg3\`"
                fi
                
                if grep -q "curl" "${script}"; then
                    echo "- Add curl timeouts: \`curl --max-time 30 --retry 3\`"
                fi
                
                if grep -q "for.*in.*\$(find" "${script}"; then
                    echo "- Replace find loops with xargs or parallel processing"
                fi
                
                if grep -q "git clone" "${script}"; then
                    echo "- Use shallow clones: \`git clone --depth 1\`"
                fi
            fi
            echo ""
        done
        
        echo "## Implementation Examples"
        echo ""
        
        echo "### Optimized Homebrew Installation"
        echo '```bash'
        echo '# Instead of:'
        echo '# brew install git'
        echo '# brew install node'
        echo '# brew install python'
        echo ''
        echo '# Use:'
        echo 'brew install git node python'
        echo '```'
        echo ""
        
        echo "### Parallel Downloads"
        echo '```bash'
        echo '# Instead of sequential downloads:'
        echo '# curl -O url1'
        echo '# curl -O url2'
        echo ''
        echo '# Use parallel downloads:'
        echo 'curl -O url1 & curl -O url2 & wait'
        echo '```'
        echo ""
        
        echo "### Cached Command Checks"
        echo '```bash'
        echo '# Cache command existence'
        echo 'declare -A COMMAND_CACHE'
        echo ''
        echo 'command_exists() {'
        echo '    local cmd="$1"'
        echo '    if [[ -z "${COMMAND_CACHE[$cmd]:-}" ]]; then'
        echo '        if command -v "$cmd" >/dev/null 2>&1; then'
        echo '            COMMAND_CACHE[$cmd]="true"'
        echo '        else'
        echo '            COMMAND_CACHE[$cmd]="false"'
        echo '        fi'
        echo '    fi'
        echo '    [[ "${COMMAND_CACHE[$cmd]}" == "true" ]]'
        echo '}'
        echo '```'
        echo ""
        
        echo "## Monitoring and Measurement"
        echo ""
        echo "### Performance Monitoring"
        echo "- Use \`time\` command to measure script execution"
        echo "- Monitor memory usage with \`ps\` or \`top\`"
        echo "- Profile network operations with \`netstat\`"
        echo "- Use \`dtrace\` or \`instruments\` for detailed analysis"
        echo ""
        
        echo "### Benchmarking"
        echo '```bash'
        echo '# Time script execution'
        echo 'time ./scripts/setup.zsh --dry-run'
        echo ''
        echo '# Memory usage monitoring'
        echo '/usr/bin/time -l ./scripts/setup.zsh --dry-run'
        echo '```'
        echo ""
        
    } > "${improvements_file}"
    
    success "Performance improvement suggestions saved to: ${improvements_file}"
    echo "${improvements_file}"
}

implement_caching_optimizations() {
    info "Implementing caching optimizations..."
    
    local cache_script="scripts/performance-cache.zsh"
    
    cat > "${cache_script}" << 'EOF'
#!/usr/bin/env zsh
# Performance caching utilities for setup scripts

# Command existence cache
declare -A COMMAND_CACHE

# Check if command exists (cached)
command_exists() {
    local cmd="$1"
    if [[ -z "${COMMAND_CACHE[$cmd]:-}" ]]; then
        if command -v "$cmd" >/dev/null 2>&1; then
            COMMAND_CACHE[$cmd]="true"
        else
            COMMAND_CACHE[$cmd]="false"
        fi
    fi
    [[ "${COMMAND_CACHE[$cmd]}" == "true" ]]
}

# System information cache
declare -A SYSTEM_INFO_CACHE

# Get cached system information
get_system_info() {
    local key="$1"
    
    if [[ -z "${SYSTEM_INFO_CACHE[$key]:-}" ]]; then
        case "$key" in
            "hostname")
                SYSTEM_INFO_CACHE[$key]=$(hostname)
                ;;
            "macos_version")
                SYSTEM_INFO_CACHE[$key]=$(sw_vers -productVersion)
                ;;
            "device_type")
                local model_name
                model_name=$(system_profiler SPHardwareDataType | grep "Model Name" | cut -d: -f2 | xargs)
                case "$model_name" in
                    *"MacBook Pro"*) SYSTEM_INFO_CACHE[$key]="macbook-pro" ;;
                    *"Mac Studio"*) SYSTEM_INFO_CACHE[$key]="mac-studio" ;;
                    *"Mac mini"*) SYSTEM_INFO_CACHE[$key]="mac-mini" ;;
                    *) SYSTEM_INFO_CACHE[$key]="unknown" ;;
                esac
                ;;
        esac
    fi
    
    echo "${SYSTEM_INFO_CACHE[$key]}"
}

# Parallel execution helper
run_parallel() {
    local max_jobs=${1:-4}
    shift
    local commands=("$@")
    
    local job_count=0
    for cmd in "${commands[@]}"; do
        eval "$cmd" &
        ((job_count++))
        
        if [[ $job_count -ge $max_jobs ]]; then
            wait
            job_count=0
        fi
    done
    
    wait  # Wait for remaining jobs
}

# Batch Homebrew operations
brew_batch_install() {
    local packages=("$@")
    
    if [[ ${#packages[@]} -gt 0 ]]; then
        info "Installing packages in batch: ${packages[*]}"
        brew install "${packages[@]}"
    fi
}

# Network operation with retry and timeout
download_with_retry() {
    local url="$1"
    local output="$2"
    local max_retries=${3:-3}
    local timeout=${4:-30}
    
    local retry=0
    while [[ $retry -lt $max_retries ]]; do
        if curl --max-time "$timeout" --retry 1 -L -o "$output" "$url"; then
            return 0
        fi
        ((retry++))
        warn "Download failed, retry $retry/$max_retries"
        sleep $((retry * 2))
    done
    
    error "Download failed after $max_retries attempts"
    return 1
}
EOF
    
    chmod +x "${cache_script}"
    success "Performance caching utilities created: ${cache_script}"
}

benchmark_current_performance() {
    info "Benchmarking current performance..."
    
    local benchmark_results="benchmark-$(date +%Y%m%d-%H%M%S).txt"
    
    {
        echo "Performance Benchmark Results"
        echo "Generated: $(date)"
        echo "System: $(sw_vers -productVersion) on $(hostname)"
        echo "================================"
        echo
        
        # Test main setup script
        echo "Main Setup Script Performance:"
        echo "------------------------------"
        /usr/bin/time -l timeout 120 scripts/setup.zsh --dry-run 2>&1 || echo "Timeout or error"
        echo
        
        # Test individual components
        local test_scripts=(
            "scripts/install-homebrew.zsh"
            "scripts/setup-dotfiles.zsh"
            "scripts/install-packages.zsh"
            "scripts/validate-setup.zsh"
        )
        
        echo "Individual Script Performance:"
        echo "-----------------------------"
        for script in "${test_scripts[@]}"; do
            if [[ -x "$script" ]]; then
                echo "Testing $script:"
                /usr/bin/time timeout 60 "$script" --dry-run 2>&1 || echo "Timeout or error"
                echo
            fi
        done
        
        # System resource usage
        echo "System Resources:"
        echo "----------------"
        echo "Memory usage:"
        vm_stat | head -10
        echo
        echo "Disk usage:"
        df -h | head -5
        echo
        echo "CPU info:"
        sysctl -n machdep.cpu.brand_string
        sysctl -n hw.ncpu
        
    } > "$benchmark_results"
    
    success "Benchmark results saved to: $benchmark_results"
}

main() {
    local operations=()
    local benchmark=false
    local create_suggestions=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h)
                cat << EOF
Performance Optimizer for macOS Setup Scripts

Usage: $SCRIPT_NAME [options] [operations]

Options:
  --help, -h              Show this help message
  --benchmark, -b         Run performance benchmark
  --suggestions, -s       Create performance improvement suggestions

Operations:
  profile                 Profile script execution times
  homebrew               Analyze Homebrew operation efficiency
  network                Analyze network operation efficiency  
  files                  Analyze file operation efficiency
  commands               Analyze command execution patterns
  cache                  Implement caching optimizations
  all                    Run all optimizations (default)

Examples:
  $SCRIPT_NAME                    # Run all optimizations
  $SCRIPT_NAME profile homebrew   # Run specific optimizations
  $SCRIPT_NAME --benchmark        # Benchmark current performance

EOF
                exit 0
                ;;
            --benchmark|-b)
                benchmark=true
                shift
                ;;
            --suggestions|-s)
                create_suggestions=true
                shift
                ;;
            profile|homebrew|network|files|commands|cache|all)
                operations+=("$1")
                shift
                ;;
            *)
                error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    # Default to all operations if none specified
    if [[ ${#operations[@]} -eq 0 ]] && [[ "$benchmark" == "false" ]] && [[ "$create_suggestions" == "false" ]]; then
        operations=("all")
    fi
    
    info "Starting performance optimization analysis..."
    echo
    
    # Run benchmark if requested
    if [[ "$benchmark" == "true" ]]; then
        benchmark_current_performance
    fi
    
    # Run requested operations
    for operation in "${operations[@]}"; do
        case "$operation" in
            profile|all)
                profile_script_performance
                ;;
            homebrew|all)
                optimize_homebrew_operations
                ;;
            network|all)
                optimize_network_operations
                ;;
            files|all)
                optimize_file_operations
                ;;
            commands|all)
                optimize_command_execution
                ;;
            cache|all)
                implement_caching_optimizations
                ;;
        esac
        echo
    done
    
    # Create suggestions if requested
    if [[ "$create_suggestions" == "true" ]]; then
        create_performance_improvements
    fi
    
    success "Performance optimization analysis complete!"
}

if [[ "${0}" == "${(%):-%x}" ]]; then
    main "$@"
fi
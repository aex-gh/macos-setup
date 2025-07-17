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

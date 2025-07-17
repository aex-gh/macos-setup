#!/usr/bin/env zsh
# Performance caching utilities for setup scripts

# Load common library for consistent functionality
readonly SCRIPT_DIR="${0:A:h}"
source "${SCRIPT_DIR}/../lib/common.zsh"

# Command existence cache (extending common.zsh functionality)
declare -A COMMAND_CACHE

# Enhanced command_exists with caching (extends common.zsh)
cached_command_exists() {
    local cmd="$1"
    if [[ -z "${COMMAND_CACHE[$cmd]:-}" ]]; then
        if command_exists "$cmd"; then
            COMMAND_CACHE[$cmd]="true"
        else
            COMMAND_CACHE[$cmd]="false"
        fi
    fi
    [[ "${COMMAND_CACHE[$cmd]}" == "true" ]]
}

# System information cache (extending common.zsh functionality)
declare -A SYSTEM_INFO_CACHE

# Get cached system information (extends common.zsh)
get_cached_system_info() {
    local key="$1"
    
    if [[ -z "${SYSTEM_INFO_CACHE[$key]:-}" ]]; then
        case "$key" in
            "hostname")
                SYSTEM_INFO_CACHE[$key]=$(hostname)
                ;;
            "macos_version")
                SYSTEM_INFO_CACHE[$key]=$(get_macos_version)
                ;;
            "device_type")
                SYSTEM_INFO_CACHE[$key]=$(detect_device_type)
                ;;
            "cpu_info")
                SYSTEM_INFO_CACHE[$key]=$(get_cpu_info)
                ;;
            "memory_info")
                SYSTEM_INFO_CACHE[$key]=$(get_memory_info)
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

# Batch Homebrew operations (uses common.zsh validation)
brew_batch_install() {
    local packages=("$@")
    
    # Check Homebrew availability using common library
    if ! check_homebrew; then
        error "Homebrew not available for batch installation"
        return 1
    fi
    
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

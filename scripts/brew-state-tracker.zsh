#!/usr/bin/env zsh
# -*- coding: utf-8 -*-

# ABOUTME: This script tracks Homebrew package states and provides monitoring capabilities for desired vs actual states
# ABOUTME: It integrates with the homebrew-manager.rb to provide ongoing state monitoring and reporting

#=============================================================================
# SCRIPT: brew-state-tracker.zsh
# VERSION: 1.0.0
# 
# DESCRIPTION:
#   Tracks and monitors Homebrew package states, providing detailed reporting
#   on package differences, health checks, and state history.
#
# USAGE:
#   ./brew-state-tracker.zsh [options] [command]
#
# COMMANDS:
#   status      Show current package state summary (default)
#   diff        Show detailed differences between desired and actual state
#   health      Perform health check on Homebrew installation
#   history     Show state change history
#   monitor     Continuously monitor for state changes
#   report      Generate detailed package report
#
# OPTIONS:
#   -h, --help      Show this help message
#   -v, --verbose   Enable verbose output
#   -f, --format    Output format (text|json|csv)
#   -o, --output    Output file
#   --brewfiles     Specific Brewfiles to track
#=============================================================================

# Strict mode
set -euo pipefail

# Script metadata
readonly SCRIPT_NAME="${0:t}"
readonly SCRIPT_DIR="${0:A:h}"
readonly SCRIPT_VERSION="1.0.0"

# Colour codes
readonly RED=$(tput setaf 1)
readonly GREEN=$(tput setaf 2)
readonly YELLOW=$(tput setaf 3)
readonly BLUE=$(tput setaf 4)
readonly MAGENTA=$(tput setaf 5)
readonly CYAN=$(tput setaf 6)
readonly WHITE=$(tput setaf 7)
readonly BOLD=$(tput bold)
readonly RESET=$(tput sgr0)

# Global variables
declare -g VERBOSE=false
declare -g OUTPUT_FORMAT="text"
declare -g OUTPUT_FILE=""
declare -g BREWFILES=""
declare -g COMMAND="status"
declare -g STATE_DIR="$HOME/.homebrew-state"
declare -g LOG_FILE="/tmp/${SCRIPT_NAME%.zsh}.log"

# Ruby manager script
readonly HOMEBREW_MANAGER="${SCRIPT_DIR}/homebrew-manager.rb"

#=============================================================================
# LOGGING FUNCTIONS
#=============================================================================

log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Log to file
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    
    # Log to console based on level
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
        DEBUG)
            [[ $VERBOSE == true ]] && echo "${CYAN}[DEBUG]${RESET} $message"
            ;;
        SUCCESS)
            echo "${GREEN}${BOLD}[✓]${RESET} $message"
            ;;
    esac
}

error() { log ERROR "$@"; }
warn() { log WARN "$@"; }
info() { log INFO "$@"; }
debug() { log DEBUG "$@"; }
success() { log SUCCESS "$@"; }

#=============================================================================
# UTILITY FUNCTIONS
#=============================================================================

# Display usage information
usage() {
    cat << EOF
${BOLD}NAME${RESET}
    $SCRIPT_NAME - Homebrew package state tracker and monitor

${BOLD}SYNOPSIS${RESET}
    $SCRIPT_NAME [options] [command]

${BOLD}DESCRIPTION${RESET}
    This script tracks and monitors Homebrew package states, providing
    detailed reporting on package differences, health checks, and state
    history for maintaining idempotent Homebrew installations.

${BOLD}COMMANDS${RESET}
    status          Show current package state summary (default)
    diff            Show detailed differences between desired and actual state
    health          Perform health check on Homebrew installation
    history         Show state change history
    monitor         Continuously monitor for state changes
    report          Generate detailed package report

${BOLD}OPTIONS${RESET}
    -h, --help          Show this help message
    -v, --verbose       Enable verbose output
    -f, --format FORMAT Output format (text|json|csv)
    -o, --output FILE   Output file
    --brewfiles FILES   Comma-separated list of specific Brewfiles to track

${BOLD}EXAMPLES${RESET}
    # Show current status
    $SCRIPT_NAME status

    # Show differences in JSON format
    $SCRIPT_NAME diff --format json

    # Generate detailed report
    $SCRIPT_NAME report --output /tmp/brew-report.txt

    # Monitor for changes
    $SCRIPT_NAME monitor --verbose

    # Health check
    $SCRIPT_NAME health

${BOLD}AUTHOR${RESET}
    macOS Setup Project

${BOLD}VERSION${RESET}
    $SCRIPT_VERSION
EOF
}

# Check for required commands
check_requirements() {
    local requirements=("ruby" "brew" "jq")
    local missing=()
    
    for cmd in "${requirements[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing+=("$cmd")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        error "Missing required commands: ${missing[*]}"
        if [[ " ${missing[*]} " =~ " jq " ]]; then
            info "Install jq with: brew install jq"
        fi
        exit 1
    fi
    
    # Check for homebrew-manager.rb
    if [[ ! -f "$HOMEBREW_MANAGER" ]]; then
        error "Homebrew manager script not found: $HOMEBREW_MANAGER"
        exit 1
    fi
}

# Ensure state directory exists
ensure_state_dir() {
    if [[ ! -d "$STATE_DIR" ]]; then
        debug "Creating state directory: $STATE_DIR"
        mkdir -p "$STATE_DIR"
    fi
}

# Get current state using homebrew-manager
get_current_state() {
    local temp_file=$(mktemp)
    
    local cmd_args=("$HOMEBREW_MANAGER" "--diff" "--output" "$temp_file")
    [[ $VERBOSE == true ]] && cmd_args+=("--verbose")
    [[ -n "$BREWFILES" ]] && cmd_args+=("--brewfiles" "$BREWFILES")
    
    "${cmd_args[@]}" > /dev/null 2>&1
    
    if [[ -f "$temp_file" ]]; then
        cat "$temp_file"
        rm -f "$temp_file"
    fi
}

# Save state snapshot
save_state_snapshot() {
    ensure_state_dir
    
    local timestamp=$(date '+%Y%m%d-%H%M%S')
    local state_file="$STATE_DIR/state-$timestamp.txt"
    
    debug "Saving state snapshot: $state_file"
    
    {
        echo "# Homebrew State Snapshot"
        echo "# Generated: $(date)"
        echo "# Hostname: $(hostname)"
        echo ""
        get_current_state
    } > "$state_file"
    
    # Keep only last 30 snapshots
    local snapshots=($(ls -t "$STATE_DIR"/state-*.txt 2>/dev/null | tail -n +31))
    if [[ ${#snapshots[@]} -gt 0 ]]; then
        debug "Cleaning up old snapshots: ${#snapshots[@]} files"
        rm -f "${snapshots[@]}"
    fi
    
    # Update latest symlink
    ln -sf "$state_file" "$STATE_DIR/latest-state.txt"
}

# Show status summary
show_status() {
    local output_stream
    
    if [[ -n "$OUTPUT_FILE" ]]; then
        output_stream="$OUTPUT_FILE"
    else
        output_stream="/dev/stdout"
    fi
    
    {
        case $OUTPUT_FORMAT in
            json)
                show_status_json
                ;;
            csv)
                show_status_csv
                ;;
            *)
                show_status_text
                ;;
        esac
    } > "$output_stream"
}

# Show status in text format
show_status_text() {
    info "Homebrew Package State Summary"
    echo ""
    
    # Get current state
    local diff_output=$(get_current_state)
    
    if [[ -z "$diff_output" ]]; then
        success "All packages are in sync"
        return 0
    fi
    
    # Parse and display differences
    local in_section=""
    local package_type=""
    
    while IFS= read -r line; do
        case $line in
            "TAP:")
                package_type="TAP"
                echo "${BOLD}${BLUE}Homebrew Taps:${RESET}"
                ;;
            "BREW:")
                package_type="BREW"
                echo "${BOLD}${BLUE}Homebrew Formulae:${RESET}"
                ;;
            "CASK:")
                package_type="CASK"
                echo "${BOLD}${BLUE}Homebrew Casks:${RESET}"
                ;;
            "MAS:")
                package_type="MAS"
                echo "${BOLD}${BLUE}Mac App Store:${RESET}"
                ;;
            "VSCODE:")
                package_type="VSCODE"
                echo "${BOLD}${BLUE}VS Code Extensions:${RESET}"
                ;;
            "  To install:")
                in_section="install"
                echo "  ${GREEN}To install:${RESET}"
                ;;
            "  To remove:")
                in_section="remove"
                echo "  ${RED}To remove:${RESET}"
                ;;
            "    + "*)
                echo "    ${GREEN}+${RESET} ${line#    + }"
                ;;
            "    - "*)
                echo "    ${RED}-${RESET} ${line#    - }"
                ;;
            "")
                echo ""
                ;;
            *)
                [[ -n "$line" ]] && echo "$line"
                ;;
        esac
    done <<< "$diff_output"
}

# Show status in JSON format
show_status_json() {
    local diff_output=$(get_current_state)
    
    # Parse diff output into JSON structure
    local json_output='{"timestamp":"'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'","hostname":"'"$(hostname)"'","packages":{}}'
    
    # TODO: Parse diff output and convert to JSON
    # For now, output basic structure
    echo "$json_output" | jq '.'
}

# Show status in CSV format
show_status_csv() {
    echo "Type,Package,Action,Timestamp"
    
    local diff_output=$(get_current_state)
    local timestamp=$(date +%Y-%m-%d\ %H:%M:%S)
    
    # Parse diff output into CSV
    local current_type=""
    while IFS= read -r line; do
        case $line in
            "TAP:")
                current_type="tap"
                ;;
            "BREW:")
                current_type="brew"
                ;;
            "CASK:")
                current_type="cask"
                ;;
            "MAS:")
                current_type="mas"
                ;;
            "VSCODE:")
                current_type="vscode"
                ;;
            "    + "*)
                echo "$current_type,${line#    + },install,$timestamp"
                ;;
            "    - "*)
                echo "$current_type,${line#    - },remove,$timestamp"
                ;;
        esac
    done <<< "$diff_output"
}

# Show detailed differences
show_diff() {
    info "Detailed Package Differences"
    echo ""
    
    local cmd_args=("$HOMEBREW_MANAGER" "--diff")
    [[ $VERBOSE == true ]] && cmd_args+=("--verbose")
    [[ -n "$BREWFILES" ]] && cmd_args+=("--brewfiles" "$BREWFILES")
    [[ -n "$OUTPUT_FILE" ]] && cmd_args+=("--output" "$OUTPUT_FILE")
    
    "${cmd_args[@]}"
}

# Perform health check
health_check() {
    info "Performing Homebrew health check"
    echo ""
    
    local issues=0
    
    # Check Homebrew installation
    if ! command -v brew &> /dev/null; then
        error "Homebrew is not installed"
        ((issues++))
    else
        success "Homebrew is installed"
    fi
    
    # Check for brew doctor issues
    info "Running brew doctor..."
    if brew doctor &> /dev/null; then
        success "No issues found by brew doctor"
    else
        warn "brew doctor found issues:"
        brew doctor
        ((issues++))
    fi
    
    # Check for outdated packages
    local outdated=$(brew outdated --quiet)
    if [[ -n "$outdated" ]]; then
        warn "Outdated packages found:"
        echo "$outdated" | sed 's/^/  /'
        ((issues++))
    else
        success "All packages are up to date"
    fi
    
    # Check for broken symlinks
    local broken=$(brew cleanup --dry-run 2>&1 | grep -c "broken symlink" || true)
    if [[ $broken -gt 0 ]]; then
        warn "Found $broken broken symlinks"
        ((issues++))
    else
        success "No broken symlinks found"
    fi
    
    # Summary
    echo ""
    if [[ $issues -eq 0 ]]; then
        success "Health check passed - no issues found"
    else
        warn "Health check found $issues issue(s)"
    fi
    
    return $issues
}

# Show state history
show_history() {
    ensure_state_dir
    
    info "State Change History"
    echo ""
    
    local snapshots=($(ls -t "$STATE_DIR"/state-*.txt 2>/dev/null | head -10))
    
    if [[ ${#snapshots[@]} -eq 0 ]]; then
        warn "No state history found"
        return 1
    fi
    
    for snapshot in "${snapshots[@]}"; do
        local filename=$(basename "$snapshot")
        local timestamp=${filename#state-}
        timestamp=${timestamp%.txt}
        local human_date=$(date -j -f "%Y%m%d-%H%M%S" "$timestamp" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "$timestamp")
        
        echo "${BOLD}$human_date${RESET}"
        
        # Show summary of changes in this snapshot
        local changes=$(grep -E "^    [+-]" "$snapshot" | wc -l | tr -d ' ')
        if [[ $changes -gt 0 ]]; then
            echo "  Changes: $changes packages"
        else
            echo "  No changes"
        fi
        
        echo ""
    done
}

# Monitor for state changes
monitor_state() {
    info "Starting state monitoring (Press Ctrl+C to stop)"
    echo ""
    
    local last_state=""
    local check_interval=60  # Check every minute
    
    while true; do
        local current_state=$(get_current_state)
        
        if [[ "$current_state" != "$last_state" ]]; then
            local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
            
            if [[ -n "$last_state" ]]; then
                warn "State change detected at $timestamp"
                echo "$current_state"
                echo ""
                
                # Save snapshot
                save_state_snapshot
            fi
            
            last_state="$current_state"
        fi
        
        debug "Checking state at $(date '+%H:%M:%S')"
        sleep $check_interval
    done
}

# Generate detailed report
generate_report() {
    local output_stream
    
    if [[ -n "$OUTPUT_FILE" ]]; then
        output_stream="$OUTPUT_FILE"
    else
        output_stream="/dev/stdout"
    fi
    
    {
        echo "# Homebrew Package Report"
        echo "Generated: $(date)"
        echo "Hostname: $(hostname)"
        echo ""
        
        # Current status
        echo "## Current Status"
        show_status_text
        echo ""
        
        # Health check
        echo "## Health Check"
        health_check
        echo ""
        
        # System information
        echo "## System Information"
        echo "Homebrew version: $(brew --version | head -1)"
        echo "Ruby version: $(ruby --version)"
        echo "System: $(uname -a)"
        echo ""
        
        # Package counts
        echo "## Package Counts"
        echo "Taps: $(brew tap | wc -l | tr -d ' ')"
        echo "Formulae: $(brew list --formula | wc -l | tr -d ' ')"
        echo "Casks: $(brew list --cask | wc -l | tr -d ' ')"
        
        if command -v mas &> /dev/null; then
            echo "MAS apps: $(mas list | wc -l | tr -d ' ')"
        fi
        
        if command -v code &> /dev/null; then
            echo "VS Code extensions: $(code --list-extensions | wc -l | tr -d ' ')"
        fi
        
    } > "$output_stream"
    
    if [[ -n "$OUTPUT_FILE" ]]; then
        success "Report generated: $OUTPUT_FILE"
    fi
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            status|diff|health|history|monitor|report)
                COMMAND="$1"
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -f|--format)
                OUTPUT_FORMAT="$2"
                case $OUTPUT_FORMAT in
                    text|json|csv)
                        ;;
                    *)
                        error "Invalid format: $OUTPUT_FORMAT"
                        exit 1
                        ;;
                esac
                shift 2
                ;;
            -o|--output)
                OUTPUT_FILE="$2"
                shift 2
                ;;
            --brewfiles)
                BREWFILES="$2"
                shift 2
                ;;
            --version)
                echo "$SCRIPT_NAME v$SCRIPT_VERSION"
                exit 0
                ;;
            -*)
                error "Unknown option: $1"
                usage
                exit 1
                ;;
            *)
                error "Unexpected argument: $1"
                usage
                exit 1
                ;;
        esac
    done
}

# Main script logic
main() {
    # Parse arguments
    parse_args "$@"
    
    # Check requirements
    check_requirements
    
    debug "Starting $SCRIPT_NAME v$SCRIPT_VERSION"
    debug "Command: $COMMAND"
    debug "Format: $OUTPUT_FORMAT"
    
    # Execute command
    case $COMMAND in
        status)
            show_status
            ;;
        diff)
            show_diff
            ;;
        health)
            health_check
            ;;
        history)
            show_history
            ;;
        monitor)
            monitor_state
            ;;
        report)
            generate_report
            ;;
        *)
            error "Unknown command: $COMMAND"
            usage
            exit 1
            ;;
    esac
}

#=============================================================================
# CLEANUP & ERROR HANDLING
#=============================================================================

# Cleanup function
cleanup() {
    local exit_code=$?
    debug "Cleaning up..."
    exit $exit_code
}

# Error handler
error_handler() {
    local line_no=$1
    error "An error occurred on line $line_no"
    cleanup
}

# Set traps
trap cleanup EXIT
trap 'error_handler $LINENO' ERR

#=============================================================================
# SCRIPT EXECUTION
#=============================================================================

# Only run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
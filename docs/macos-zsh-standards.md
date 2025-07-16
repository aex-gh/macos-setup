# macOS Zsh Scripting Standards

## Overview
Zsh (Z shell) is the default shell for macOS since Catalina (10.15). These standards ensure robust, maintainable, and macOS-optimised shell scripts that leverage Zsh's powerful features while maintaining compatibility with common Bash patterns.

## Core Tools & Utilities

### Essential macOS Command Line Tools
- **brew**: Homebrew package manager (must be installed)
- **jq**: JSON processor for API responses and config files
- **fzf**: Fuzzy finder for interactive selections
- **ripgrep (rg)**: Fast recursive grep replacement
- **fd**: Modern find replacement
- **bat**: Cat replacement with syntax highlighting
- **eza**: Modern ls replacement
- **gh**: GitHub CLI for repository operations
- **mas**: Mac App Store command line interface
- **dockutil**: Dock management utility

### Development Tools
- **shellcheck**: Shell script static analysis
- **shfmt**: Shell script formatter
- **bats**: Bash Automated Testing System
- **entr**: Run commands when files change
- **fswatch**: File system event monitor
- **terminal-notifier**: macOS notifications from terminal

### macOS-Specific Utilities
- **osascript**: AppleScript/JavaScript automation
- **defaults**: Manage macOS preferences
- **launchctl**: Manage Launch Agents/Daemons
- **diskutil**: Disk management
- **pmset**: Power management settings
- **networksetup**: Network configuration
- **mdfind**: Spotlight search from terminal
- **pbcopy/pbpaste**: Clipboard utilities

## Script Structure

### Standard Template
```zsh
#!/usr/bin/env zsh
# -*- coding: utf-8 -*-

#=============================================================================
# SCRIPT: script_name.zsh
# AUTHOR: Your Name
# DATE: $(date +%Y-%m-%d)
# VERSION: 1.0.0
#
# DESCRIPTION:
#   Brief description of what this script does
#
# USAGE:
#   ./script_name.zsh [options] <arguments>
#
# OPTIONS:
#   -h, --help      Show this help message
#   -v, --verbose   Enable verbose output
#   -d, --debug     Enable debug mode
#
# REQUIREMENTS:
#   - macOS 11.0+ (Big Sur)
#   - Zsh 5.8+
#   - Specific tools: jq, ripgrep
#
# NOTES:
#   - Additional implementation notes
#   - Known limitations
#=============================================================================

# Strict mode
set -euo pipefail

# Script metadata
readonly SCRIPT_NAME="${0:t}"
readonly SCRIPT_DIR="${0:A:h}"
readonly SCRIPT_VERSION="1.0.0"

# Colour codes (using tput for compatibility)
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
declare -g DEBUG=false
declare -g LOG_FILE="/tmp/${SCRIPT_NAME%.zsh}.log"

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
            [[ $DEBUG == true ]] && echo "${CYAN}[DEBUG]${RESET} $message"
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

# Check if running on macOS
check_macos() {
    if [[ $(uname) != "Darwin" ]]; then
        error "This script requires macOS"
        exit 1
    fi
}

# Check macOS version
check_macos_version() {
    local required_version="${1:-11.0}"
    local current_version=$(sw_vers -productVersion)

    if ! is_version_gte "$current_version" "$required_version"; then
        error "macOS $required_version or later required (current: $current_version)"
        exit 1
    fi
}

# Version comparison
is_version_gte() {
    [ "$1" = "$(echo -e "$1\n$2" | sort -V | tail -n1)" ]
}

# Check for required commands
check_requirements() {
    local requirements=("$@")
    local missing=()

    for cmd in "${requirements[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing+=("$cmd")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        error "Missing required commands: ${missing[*]}"
        info "Install with: brew install ${missing[*]}"
        exit 1
    fi
}

# Display usage information
usage() {
    cat << EOF
${BOLD}NAME${RESET}
    $SCRIPT_NAME - Brief description

${BOLD}SYNOPSIS${RESET}
    $SCRIPT_NAME [options] <arguments>

${BOLD}DESCRIPTION${RESET}
    Detailed description of what the script does.

${BOLD}OPTIONS${RESET}
    -h, --help          Show this help message
    -v, --verbose       Enable verbose output
    -d, --debug         Enable debug mode
    -f, --file FILE     Specify input file
    -o, --output DIR    Specify output directory

${BOLD}EXAMPLES${RESET}
    # Basic usage
    $SCRIPT_NAME input.txt

    # With options
    $SCRIPT_NAME -v -o /tmp input.txt

${BOLD}AUTHOR${RESET}
    Your Name <your.email@example.com>

${BOLD}VERSION${RESET}
    $SCRIPT_VERSION
EOF
}

#=============================================================================
# macOS-SPECIFIC FUNCTIONS
#=============================================================================

# Send macOS notification
notify() {
    local title="${1:-Script Notification}"
    local message="${2:-Task completed}"
    local sound="${3:-default}"

    if command -v terminal-notifier &> /dev/null; then
        terminal-notifier -title "$title" -message "$message" -sound "$sound"
    else
        osascript -e "display notification \"$message\" with title \"$title\""
    fi
}

# Get/set macOS defaults
get_default() {
    local domain=$1
    local key=$2
    defaults read "$domain" "$key" 2>/dev/null || echo ""
}

set_default() {
    local domain=$1
    local key=$2
    local value=$3
    local type=${4:-string}

    defaults write "$domain" "$key" "-$type" "$value"
}

# Check if app is running
is_app_running() {
    local app_name=$1
    osascript -e "tell application \"System Events\" to (name of processes) contains \"$app_name\"" 2>/dev/null
}

# Restart app
restart_app() {
    local app_name=$1

    if is_app_running "$app_name"; then
        osascript -e "quit app \"$app_name\""
        sleep 2
    fi

    open -a "$app_name"
}

#=============================================================================
# MAIN FUNCTIONS
#=============================================================================

# Parse command line arguments
parse_args() {
    local args=()

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
            -d|--debug)
                DEBUG=true
                shift
                ;;
            -f|--file)
                INPUT_FILE="$2"
                shift 2
                ;;
            -o|--output)
                OUTPUT_DIR="$2"
                shift 2
                ;;
            -*)
                error "Unknown option: $1"
                usage
                exit 1
                ;;
            *)
                args+=("$1")
                shift
                ;;
        esac
    done

    # Store remaining arguments
    set -- "${args[@]}"

    # Validate required arguments
    if [[ $# -eq 0 ]]; then
        error "No arguments provided"
        usage
        exit 1
    fi
}

# Main script logic
main() {
    # Check environment
    check_macos
    check_macos_version "11.0"
    check_requirements "jq" "ripgrep"

    # Parse arguments
    parse_args "$@"

    info "Starting $SCRIPT_NAME v$SCRIPT_VERSION"

    # Your main logic here
    # ...

    success "Operation completed successfully"

    # Send notification on completion
    notify "$SCRIPT_NAME" "Task completed successfully"
}

#=============================================================================
# CLEANUP & ERROR HANDLING
#=============================================================================

# Cleanup function
cleanup() {
    local exit_code=$?

    debug "Cleaning up..."

    # Remove temporary files
    [[ -n ${TEMP_DIR:-} && -d $TEMP_DIR ]] && rm -rf "$TEMP_DIR"

    # Log exit status
    if [[ $exit_code -eq 0 ]]; then
        debug "Script exited successfully"
    else
        error "Script exited with code: $exit_code"
    fi

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
```

## Zsh-Specific Features

### Arrays and Associative Arrays
```zsh
# Indexed arrays (1-based in Zsh!)
local -a fruits=(apple banana cherry)
echo ${fruits[1]}  # apple (not banana!)

# Associative arrays
typeset -A config=(
    [host]="localhost"
    [port]="8080"
    [ssl]="true"
)

# Array operations
fruits+=(orange)                    # Append
fruits[2]="blueberry"              # Update
unset "fruits[3]"                  # Remove element

# Array slicing
echo ${fruits[1,2]}                # First two elements
echo ${fruits[-1]}                 # Last element
echo ${#fruits[@]}                 # Array length

# Iteration
for fruit in ${fruits[@]}; do
    echo "Fruit: $fruit"
done

# With index
for i in {1..${#fruits[@]}}; do
    echo "$i: ${fruits[$i]}"
done
```

### Parameter Expansion
```zsh
# Advanced parameter expansion
filename="/path/to/file.txt"

echo ${filename:t}      # file.txt (tail - basename)
echo ${filename:h}      # /path/to (head - dirname)
echo ${filename:r}      # /path/to/file (root - remove extension)
echo ${filename:e}      # txt (extension)
echo ${filename:A}      # Absolute path
echo ${filename:a}      # Absolute path (resolve symlinks)

# String manipulation
text="Hello World"
echo ${text:u}          # HELLO WORLD (uppercase)
echo ${text:l}          # hello world (lowercase)
echo ${(C)text}         # Hello world (capitalise words)

# Pattern matching
echo ${text/#Hello/Hi}  # Hi World (replace start)
echo ${text/%World/Zsh} # Hello Zsh (replace end)
echo ${text//o/0}       # Hell0 W0rld (replace all)
```

### Glob Patterns
```zsh
# Extended globbing
setopt EXTENDED_GLOB

# Recursive globbing
files=(**/*.txt)                   # All .txt files recursively

# Glob qualifiers
recent_files=(*(.mh-1))           # Regular files modified in last hour
large_dirs=(*(Lm+10/))            # Directories larger than 10MB
executables=(*(x))                # Executable files

# Numeric ranges
logs=(log<1-10>.txt)              # log1.txt through log10.txt

# Negation
non_hidden=(*~.*)                 # All except hidden files

# OR patterns
docs=(*.(pdf|doc|docx))           # Multiple extensions
```

### Functions
```zsh
# Function with local variables and return values
calculate_size() {
    local -r path="${1:?Path required}"
    local size

    if [[ -d $path ]]; then
        size=$(du -sh "$path" | cut -f1)
    elif [[ -f $path ]]; then
        size=$(ls -lh "$path" | awk '{print $5}')
    else
        return 1
    fi

    echo "$size"
    return 0
}

# Function with options parsing
process_files() {
    local -A opts
    zparseopts -D -A opts \
        h=help -help=help \
        v=verbose -verbose=verbose \
        o:=output -output:=output

    [[ -n ${opts[(i)(-h|--help)]} ]] && { usage; return 0; }
    [[ -n ${opts[(i)(-v|--verbose)]} ]] && local verbose=true

    local output_dir="${opts[-o]:-${opts[--output]:-/tmp}}"

    # Process remaining arguments
    for file in "$@"; do
        [[ -n $verbose ]] && echo "Processing: $file"
        # Process file...
    done
}

# Anonymous functions
() {
    local temp_var="local to this scope"
    echo "Anonymous function: $temp_var"
}
```

## macOS Integration

### System Information
```zsh
# Get system information
get_system_info() {
    local -A info

    info[hostname]=$(scutil --get ComputerName)
    info[model]=$(sysctl -n hw.model)
    info[cpu]=$(sysctl -n machdep.cpu.brand_string)
    info[memory]=$(( $(sysctl -n hw.memsize) / 1024 / 1024 / 1024 ))GB
    info[macos]=$(sw_vers -productVersion)
    info[build]=$(sw_vers -buildVersion)
    info[uptime]=$(uptime | sed 's/.*up \([^,]*\),.*/\1/')

    for key val in ${(kv)info}; do
        printf "%-10s: %s\n" "$key" "$val"
    done
}

# Check system resources
check_resources() {
    local cpu_usage=$(top -l 1 | grep "CPU usage" | awk '{print $3}' | sed 's/%//')
    local memory_pressure=$(memory_pressure | grep "System-wide memory free" | awk '{print $5}' | sed 's/%//')
    local disk_usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')

    [[ ${cpu_usage%.*} -gt 80 ]] && warn "High CPU usage: $cpu_usage%"
    [[ ${memory_pressure%.*} -lt 20 ]] && warn "Low memory: $memory_pressure% free"
    [[ ${disk_usage%.*} -gt 90 ]] && warn "Low disk space: $disk_usage used"
}
```

### Application Management
```zsh
# Install applications via Homebrew
install_apps() {
    local -a brew_apps=(
        "git"
        "jq"
        "ripgrep"
        "fzf"
        "bat"
        "eza"
    )

    local -a cask_apps=(
        "visual-studio-code"
        "iterm2"
        "rectangle"
        "alfred"
    )

    # Install Homebrew if missing
    if ! command -v brew &> /dev/null; then
        info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    # Update Homebrew
    brew update

    # Install CLI tools
    for app in ${brew_apps[@]}; do
        if ! brew list --formula | grep -q "^$app$"; then
            info "Installing $app..."
            brew install "$app"
        fi
    done

    # Install GUI applications
    for app in ${cask_apps[@]}; do
        if ! brew list --cask | grep -q "^$app$"; then
            info "Installing $app..."
            brew install --cask "$app"
        fi
    done
}

# Manage Launch Agents
manage_launch_agent() {
    local action=$1
    local plist_name=$2
    local plist_path="$HOME/Library/LaunchAgents/$plist_name"

    case $action in
        create)
            cat > "$plist_path" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${plist_name%.plist}</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/zsh</string>
        <string>$HOME/scripts/backup.zsh</string>
    </array>
    <key>StartInterval</key>
    <integer>3600</integer>
    <key>StandardOutPath</key>
    <string>/tmp/${plist_name%.plist}.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/${plist_name%.plist}.error.log</string>
</dict>
</plist>
EOF
            launchctl load "$plist_path"
            ;;

        start|stop|restart)
            launchctl "$action" "${plist_name%.plist}"
            ;;

        remove)
            launchctl unload "$plist_path"
            rm -f "$plist_path"
            ;;
    esac
}
```

### File System Operations
```zsh
# Secure file operations with Finder tags
tag_files() {
    local tag=$1
    shift
    local files=("$@")

    for file in ${files[@]}; do
        if [[ -e $file ]]; then
            xattr -w com.apple.metadata:_kMDItemUserTags "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\"><plist version=\"1.0\"><array><string>$tag</string></array></plist>" "$file"
            info "Tagged $file with '$tag'"
        fi
    done
}

# Spotlight search wrapper
spotlight_search() {
    local query=$1
    local kind=${2:-}
    local location=${3:-$HOME}

    local mdfind_args=(-onlyin "$location")

    case $kind in
        app|application)
            mdfind_args+=("kMDItemKind == 'Application'")
            ;;
        doc|document)
            mdfind_args+=("kMDItemKind == '*Document'")
            ;;
        image)
            mdfind_args+=("kMDItemKind == 'Image'")
            ;;
        *)
            # Plain text search
            ;;
    esac

    mdfind "${mdfind_args[@]}" "$query"
}

# Backup with Time Machine
trigger_backup() {
    local backup_type=${1:-manual}

    if ! tmutil destinationinfo &> /dev/null; then
        error "No Time Machine destination configured"
        return 1
    fi

    case $backup_type in
        manual)
            info "Starting manual Time Machine backup..."
            tmutil startbackup
            ;;

        auto)
            info "Enabling automatic backups..."
            sudo tmutil enable
            ;;

        status)
            tmutil status
            ;;
    esac
}
```

## Error Handling & Debugging

### Advanced Error Handling
```zsh
# Error context tracking
typeset -A ERROR_CONTEXT

set_error_context() {
    ERROR_CONTEXT[function]=${funcstack[2]:-main}
    ERROR_CONTEXT[line]=$1
    ERROR_CONTEXT[command]=$2
}

error_handler() {
    local exit_code=$?
    local line_no=$1

    error "Command failed with exit code $exit_code"
    error "Location: ${ERROR_CONTEXT[function]} at line $line_no"
    error "Command: ${ERROR_CONTEXT[command]}"

    # Stack trace
    if [[ $DEBUG == true ]]; then
        error "Stack trace:"
        for i in {1..${#funcstack[@]}}; do
            error "  $i: ${funcstack[$i]} (${functrace[$i]})"
        done
    fi

    cleanup
    exit $exit_code
}

# Command wrapper with error handling
safe_execute() {
    local cmd=("$@")

    if [[ $DEBUG == true ]]; then
        debug "Executing: ${cmd[*]}"
    fi

    set_error_context $LINENO "${cmd[*]}"

    if ! "${cmd[@]}"; then
        return $?
    fi
}

# Retry mechanism
retry() {
    local max_attempts=${1:-3}
    local delay=${2:-1}
    shift 2
    local cmd=("$@")
    local attempt=1

    until "${cmd[@]}"; do
        if [[ $attempt -ge $max_attempts ]]; then
            error "Command failed after $max_attempts attempts: ${cmd[*]}"
            return 1
        fi

        warn "Attempt $attempt failed, retrying in ${delay}s..."
        sleep "$delay"
        ((attempt++))
        ((delay *= 2))  # Exponential backoff
    done

    return 0
}
```

### Debugging Tools
```zsh
# Debug mode enhancements
if [[ $DEBUG == true ]]; then
    # Show all commands
    set -x

    # Trap DEBUG for command logging
    trap 'debug "Executing: $BASH_COMMAND"' DEBUG
fi

# Performance profiling
profile_start() {
    PROFILE_START=$(date +%s.%N)
}

profile_end() {
    local label=${1:-"Operation"}
    local end=$(date +%s.%N)
    local duration=$(echo "$end - $PROFILE_START" | bc)
    debug "$label completed in ${duration}s"
}

# Memory usage tracking
show_memory_usage() {
    local process=${1:-$$}
    ps -o pid,vsz,rss,comm -p "$process"
}

# Variable dump
dump_vars() {
    local pattern=${1:-*}

    debug "=== Variable Dump ==="
    for var in ${(k)parameters[(I)$pattern]}; do
        if [[ ${(Pt)var} == *array* ]]; then
            debug "$var=(${(P)var})"
        elif [[ ${(Pt)var} == *association* ]]; then
            debug "$var=("
            for key in ${(Pk)var}; do
                debug "  [$key]=${${(P)var}[$key]}"
            done
            debug ")"
        else
            debug "$var=${(P)var}"
        fi
    done
    debug "=================="
}
```

## Testing Framework

### BATS Test Example
```bash
#!/usr/bin/env bats
# test_script.bats

setup() {
    # Load script functions
    source "${BATS_TEST_DIRNAME}/../script.zsh"

    # Create temp directory
    TEST_DIR=$(mktemp -d)
}

teardown() {
    # Cleanup
    rm -rf "$TEST_DIR"
}

@test "check_macos detects macOS correctly" {
    run check_macos
    [ "$status" -eq 0 ]
}

@test "calculate_size returns correct size for file" {
    echo "test content" > "$TEST_DIR/test.txt"

    run calculate_size "$TEST_DIR/test.txt"
    [ "$status" -eq 0 ]
    [[ "$output" =~ [0-9]+[BKMG]? ]]
}

@test "error logging works correctly" {
    LOG_FILE="$TEST_DIR/test.log"

    run error "Test error message"
    [ "$status" -eq 0 ]

    grep -q "ERROR" "$LOG_FILE"
    grep -q "Test error message" "$LOG_FILE"
}

@test "parse_args handles options correctly" {
    run parse_args -v -f input.txt -o /tmp output.txt
    [ "$status" -eq 0 ]
    [ "$VERBOSE" = "true" ]
    [ "$INPUT_FILE" = "input.txt" ]
    [ "$OUTPUT_DIR" = "/tmp" ]
}
```

## Performance Optimisation

### Efficient Patterns
```zsh
# Use built-in parameter expansion instead of external commands
# Bad
filename=$(echo $path | awk -F/ '{print $NF}')
# Good
filename=${path:t}

# Read file efficiently
# Bad
while read line; do
    process "$line"
done < file.txt

# Good - handles spaces and special characters
while IFS= read -r line; do
    process "$line"
done < file.txt

# Better - for large files
zmodload zsh/mapfile
lines=("${(f)mapfile[file.txt]}")

# Process substitution for parallel operations
diff <(sort file1.txt) <(sort file2.txt)

# Efficient array operations
# Bad
for item in "${array[@]}"; do
    new_array+=("processed_$item")
done

# Good
new_array=("processed_${^array[@]}")

# Background jobs with job control
process_parallel() {
    local -a jobs
    local max_jobs=4

    for file in *.txt; do
        # Wait if too many jobs
        while (( ${#jobs[@]} >= max_jobs )); do
            wait -n
            jobs=(${jobs:|})
        done

        # Start background job
        process_file "$file" &
        jobs+=($!)
    done

    # Wait for remaining jobs
    wait
}
```

## Security Best Practices

### Input Validation
```zsh
# Validate and sanitise input
validate_input() {
    local input=$1
    local type=$2

    case $type in
        email)
            [[ $input =~ '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$' ]] || return 1
            ;;

        path)
            # Remove potentially dangerous characters
            input=${input//[^a-zA-Z0-9._\/-]/}
            # Prevent directory traversal
            [[ $input =~ '\.\.' ]] && return 1
            ;;

        number)
            [[ $input =~ '^[0-9]+$' ]] || return 1
            ;;

        alphanum)
            [[ $input =~ '^[a-zA-Z0-9]+$' ]] || return 1
            ;;
    esac

    echo "$input"
}

# Secure temporary files
create_secure_temp() {
    local template=${1:-"script.XXXXXX"}
    local temp_file

    # Use mktemp with secure permissions
    temp_file=$(mktemp -t "$template") || return 1
    chmod 600 "$temp_file"

    # Register for cleanup
    TEMP_FILES+=("$temp_file")

    echo "$temp_file"
}

# Secure credential handling
get_credential() {
    local service=$1
    local account=$2

    # Try keychain first
    if security find-generic-password -s "$service" -a "$account" -w 2>/dev/null; then
        return 0
    fi

    # Fall back to prompting
    echo -n "Enter password for $account: " >&2
    read -rs password
    echo >&2

    # Optionally save to keychain
    if confirm "Save to keychain?"; then
        security add-generic-password -s "$service" -a "$account" -w "$password"
    fi

    echo "$password"
}
```

## Integration Examples

### Git Integration
```zsh
# Enhanced git operations
git_smart_commit() {
    local message=$1
    local scope=${2:-}

    # Check for staged changes
    if ! git diff --cached --quiet; then
        # Generate conventional commit message
        if [[ -n $scope ]]; then
            message="$scope: $message"
        fi

        # Add ticket number if in branch name
        local branch=$(git branch --show-current)
        if [[ $branch =~ '([A-Z]+-[0-9]+)' ]]; then
            message="$message (${match[1]})"
        fi

        git commit -m "$message"
    else
        warn "No staged changes to commit"
        return 1
    fi
}

# Repository statistics
git_stats() {
    local days=${1:-30}

    echo "=== Git Statistics (last $days days) ==="
    echo
    echo "Contributors:"
    git log --since="$days days ago" --format="%an" | sort | uniq -c | sort -rn

    echo
    echo "File changes:"
    git log --since="$days days ago" --name-only --format="" | \
        grep -v '^$' | sort | uniq -c | sort -rn | head -10

    echo
    echo "Commit activity by day:"
    git log --since="$days days ago" --format="%ad" --date=format:"%A" | \
        sort | uniq -c
}
```

### API Integration
```zsh
# RESTful API wrapper
api_request() {
    local method=$1
    local endpoint=$2
    local data=${3:-}

    local base_url=${API_BASE_URL:-"https://api.example.com"}
    local auth_token=${API_TOKEN:-$(get_credential "api" "token")}

    local curl_args=(
        -s
        -X "$method"
        -H "Authorization: Bearer $auth_token"
        -H "Content-Type: application/json"
        -H "User-Agent: $SCRIPT_NAME/$SCRIPT_VERSION"
    )

    [[ -n $data ]] && curl_args+=(-d "$data")

    local response
    local http_code

    response=$(curl "${curl_args[@]}" -w "\n%{http_code}" "$base_url$endpoint")
    http_code=$(tail -1 <<< "$response")
    response=$(sed '$ d' <<< "$response")

    if [[ $http_code -ge 200 && $http_code -lt 300 ]]; then
        echo "$response"
        return 0
    else
        error "API request failed with code $http_code"
        [[ -n $response ]] && error "Response: $response"
        return 1
    fi
}

# JSON parsing wrapper
parse_json() {
    local json=$1
    local query=$2

    if command -v jq &> /dev/null; then
        jq -r "$query" <<< "$json"
    else
        # Fallback to Python
        python3 -c "
import json, sys
data = json.load(sys.stdin)
query = '$query'.strip('.')
for key in query.split('.'):
    if key:
        data = data.get(key, '')
print(data)
" <<< "$json"
    fi
}
```

## macOS Automation Examples

### Desktop Setup Automation
```zsh
#!/usr/bin/env zsh

setup_macos_defaults() {
    info "Configuring macOS defaults..."

    # Dock settings
    defaults write com.apple.dock tilesize -int 48
    defaults write com.apple.dock show-recents -bool false
    defaults write com.apple.dock minimize-to-application -bool true

    # Finder settings
    defaults write com.apple.finder ShowPathbar -bool true
    defaults write com.apple.finder ShowStatusBar -bool true
    defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
    defaults write com.apple.finder FXPreferredViewStyle -string "clmv"

    # Screenshots
    defaults write com.apple.screencapture location -string "$HOME/Screenshots"
    defaults write com.apple.screencapture disable-shadow -bool true

    # Keyboard
    defaults write NSGlobalDomain KeyRepeat -int 2
    defaults write NSGlobalDomain InitialKeyRepeat -int 15

    # Trackpad
    defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
    defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true

    # Restart affected apps
    for app in "Dock" "Finder" "SystemUIServer"; do
        killall "$app" &> /dev/null || true
    done

    success "macOS defaults configured"
}

# Development environment setup
setup_dev_environment() {
    info "Setting up development environment..."

    # Install Xcode Command Line Tools
    if ! xcode-select -p &> /dev/null; then
        info "Installing Xcode Command Line Tools..."
        xcode-select --install

        # Wait for installation
        until xcode-select -p &> /dev/null; do
            sleep 5
        done
    fi

    # Install Homebrew
    if ! command -v brew &> /dev/null; then
        info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # Add to PATH
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi

    # Install development tools
    local -a dev_tools=(
        # Languages
        "python@3.11"
        "node"
        "go"
        "rust"

        # Tools
        "git"
        "gh"
        "docker"
        "terraform"
        "ansible"

        # Utilities
        "jq"
        "yq"
        "ripgrep"
        "fd"
        "bat"
        "eza"
        "fzf"
        "tmux"
        "neovim"
    )

    brew install "${dev_tools[@]}"

    # Configure git
    git config --global user.name "${GIT_USER_NAME:-Your Name}"
    git config --global user.email "${GIT_USER_EMAIL:-you@example.com}"
    git config --global init.defaultBranch main
    git config --global pull.rebase true

    success "Development environment ready"
}
```

## Common Pitfalls & Solutions

### Zsh vs Bash Differences
```zsh
# Array indexing (Zsh is 1-based!)
# Bash: ${array[0]}
# Zsh:  ${array[1]}

# Word splitting
# Zsh doesn't split by default
var="one two three"
# Bash: for word in $var  # splits into three
# Zsh:  for word in $=var # need explicit split

# Null glob
# Prevent errors when no matches
setopt NULL_GLOB
files=(*.txt)  # Empty array if no matches instead of error

# Command substitution
# Both work, but $(...) is preferred
output=$(command)
# Avoid: output=`command`

# Test command
# Use [[ ]] instead of [ ]
[[ -f $file ]]  # No need to quote in Zsh
# Avoid: [ -f "$file" ]
```

### Performance Tips
```zsh
# Efficient file processing
# Bad: Multiple process spawning
for file in *.log; do
    line_count=$(wc -l < "$file")
    size=$(stat -f%z "$file")
    echo "$file: $line_count lines, $size bytes"
done

# Good: Built-in operations
for file in *.log; do
    lines=("${(@f)$(<$file)}")
    echo "$file: ${#lines[@]} lines, $(stat -f%z "$file") bytes"
done

# Caching expensive operations
typeset -gA CACHE

cached_get() {
    local key=$1
    local compute_func=$2

    if [[ -z ${CACHE[$key]} ]]; then
        CACHE[$key]=$($compute_func)
    fi

    echo "${CACHE[$key]}"
}

# Use: result=$(cached_get "system_info" get_system_info)
```

## Style Guide Summary

### Naming Conventions
- Scripts: `kebab-case.zsh`
- Functions: `snake_case`
- Global variables: `UPPER_SNAKE_CASE`
- Local variables: `lower_snake_case`
- Constants: `readonly UPPER_SNAKE_CASE`

### Code Organisation
1. Shebang and encoding
2. Script documentation header
3. Strict mode settings
4. Global constants
5. Utility functions
6. Core functions
7. Main function
8. Trap handlers
9. Script execution guard

### Best Practices
- Always use `local` for function variables
- Quote variables unless you need word splitting
- Use `readonly` for constants
- Prefer `[[ ]]` over `[ ]` for tests
- Use `$(...)` over backticks
- Check command existence with `command -v`
- Handle errors explicitly
- Provide meaningful error messages
- Clean up resources in trap handlers
- Document complex logic

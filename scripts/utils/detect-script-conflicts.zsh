#!/usr/bin/env zsh
set -euo pipefail

# Script metadata
readonly SCRIPT_NAME="${0:t}"
readonly SCRIPT_DIR="${0:A:h}"

# Load common library
source "${SCRIPT_DIR}/../lib/common.zsh"

# Extract defaults write commands from scripts
extract_defaults_commands() {
    local script_path="$1"
    local script_name="$(basename "$script_path")"
    
    grep -n "defaults write" "$script_path" 2>/dev/null | while read -r line; do
        echo "[$script_name] $line"
    done
}

# Extract dscl commands from scripts
extract_dscl_commands() {
    local script_path="$1"
    local script_name="$(basename "$script_path")"
    
    grep -n "dscl" "$script_path" 2>/dev/null | while read -r line; do
        echo "[$script_name] $line"
    done
}

# Extract sudo operations from scripts
extract_sudo_operations() {
    local script_path="$1"
    local script_name="$(basename "$script_path")"
    
    grep -n "sudo.*pmset\|sudo.*mkdir\|sudo.*chmod\|sudo.*chown" "$script_path" 2>/dev/null | while read -r line; do
        echo "[$script_name] $line"
    done
}

# Check for font installation conflicts
check_font_conflicts() {
    info "Checking for font installation conflicts..."
    
    local font_conflicts=0
    
    # Check if both manual and Homebrew font installation exist
    local brewfile_fonts
    local manual_fonts
    
    brewfile_fonts=$(find "$SCRIPT_DIR/../configs" -name "Brewfile" -exec grep -l "font-" {} \; 2>/dev/null || true)
    manual_fonts=$(find "$SCRIPT_DIR" -name "*.zsh" -exec grep -l "install.*font\|font.*install" {} \; 2>/dev/null || true)
    
    if [[ -n "$brewfile_fonts" && -n "$manual_fonts" ]]; then
        warn "Font installation conflict detected:"
        echo "  Brewfile font installation: $brewfile_fonts"
        echo "  Manual font installation: $manual_fonts"
        ((font_conflicts++))
    fi
    
    # Check for specific Maple Mono conflicts
    local maple_homebrew
    local maple_manual
    
    maple_homebrew=$(grep -r "font-maple-mono" "$SCRIPT_DIR/../configs" 2>/dev/null || true)
    maple_manual=$(grep -r "install_maple_mono\|Maple.*Mono" "$SCRIPT_DIR"/*.zsh 2>/dev/null || true)
    
    if [[ -n "$maple_homebrew" && -n "$maple_manual" ]]; then
        warn "Maple Mono font conflict detected:"
        echo "  Homebrew: $maple_homebrew"
        echo "  Manual: $maple_manual"
        ((font_conflicts++))
    fi
    
    if [[ $font_conflicts -eq 0 ]]; then
        success "No font installation conflicts detected"
    else
        error "Found $font_conflicts font installation conflicts"
    fi
    
    return $font_conflicts
}

# Check for user creation conflicts
check_user_creation_conflicts() {
    info "Checking for user creation conflicts..."
    
    local user_conflicts=0
    local scripts_creating_users=()
    
    # Find scripts that create users
    for script in "$SCRIPT_DIR"/*.zsh; do
        if grep -q "create_user\|dscl.*create.*Users" "$script" 2>/dev/null; then
            scripts_creating_users+=("$(basename "$script")")
        fi
    done
    
    if [[ ${#scripts_creating_users[@]} -gt 1 ]]; then
        warn "Multiple scripts create users:"
        for script in "${scripts_creating_users[@]}"; do
            echo "  - $script"
        done
        ((user_conflicts++))
    fi
    
    # Check for shared directory creation conflicts
    local shared_dir_scripts=()
    for script in "$SCRIPT_DIR"/*.zsh; do
        if grep -q "mkdir.*Shared\|Shared.*mkdir" "$script" 2>/dev/null; then
            shared_dir_scripts+=("$(basename "$script")")
        fi
    done
    
    if [[ ${#shared_dir_scripts[@]} -gt 1 ]]; then
        warn "Multiple scripts create shared directories:"
        for script in "${shared_dir_scripts[@]}"; do
            echo "  - $script"
        done
        ((user_conflicts++))
    fi
    
    if [[ $user_conflicts -eq 0 ]]; then
        success "No user creation conflicts detected"
    else
        error "Found $user_conflicts user creation conflicts"
    fi
    
    return $user_conflicts
}

# Check for system configuration conflicts
check_system_config_conflicts() {
    info "Checking for system configuration conflicts..."
    
    local config_conflicts=0
    local temp_file
    temp_file=$(mktemp)
    
    # Collect all defaults write commands
    for script in "$SCRIPT_DIR"/*.zsh; do
        extract_defaults_commands "$script" >> "$temp_file"
    done
    
    # Check for duplicate domain/key combinations
    local duplicate_configs
    duplicate_configs=$(awk -F'defaults write ' '{if (NF > 1) print $2}' "$temp_file" | \
                       awk '{print $1" "$2}' | sort | uniq -d)
    
    if [[ -n "$duplicate_configs" ]]; then
        warn "Duplicate system configuration detected:"
        echo "$duplicate_configs" | while read -r config; do
            echo "  Duplicate: $config"
            grep "$config" "$temp_file" | head -5
        done
        ((config_conflicts++))
    fi
    
    # Check for conflicting power management settings
    local power_scripts=()
    for script in "$SCRIPT_DIR"/*.zsh; do
        if grep -q "pmset" "$script" 2>/dev/null; then
            power_scripts+=("$(basename "$script")")
        fi
    done
    
    if [[ ${#power_scripts[@]} -gt 1 ]]; then
        warn "Multiple scripts configure power management:"
        for script in "${power_scripts[@]}"; do
            echo "  - $script"
        done
        ((config_conflicts++))
    fi
    
    rm -f "$temp_file"
    
    if [[ $config_conflicts -eq 0 ]]; then
        success "No system configuration conflicts detected"
    else
        error "Found $config_conflicts system configuration conflicts"
    fi
    
    return $config_conflicts
}

# Generate conflict report
generate_conflict_report() {
    local report_file="$SCRIPT_DIR/../docs/conflict-detection-report.md"
    
    info "Generating conflict report: $report_file"
    
    cat > "$report_file" << EOF
# Script Conflict Detection Report

Generated: $(date '+%Y-%m-%d %H:%M:%S')

## Defaults Write Commands

### System Configuration Scripts
EOF
    
    for script in "$SCRIPT_DIR"/*.zsh; do
        local script_name="$(basename "$script")"
        echo "#### $script_name" >> "$report_file"
        echo '```' >> "$report_file"
        extract_defaults_commands "$script" >> "$report_file"
        echo '```' >> "$report_file"
        echo "" >> "$report_file"
    done
    
    cat >> "$report_file" << EOF

## Power Management Commands

### Scripts with pmset operations
EOF
    
    for script in "$SCRIPT_DIR"/*.zsh; do
        local script_name="$(basename "$script")"
        local pmset_commands
        pmset_commands=$(extract_sudo_operations "$script" | grep pmset || true)
        
        if [[ -n "$pmset_commands" ]]; then
            echo "#### $script_name" >> "$report_file"
            echo '```' >> "$report_file"
            echo "$pmset_commands" >> "$report_file"
            echo '```' >> "$report_file"
            echo "" >> "$report_file"
        fi
    done
    
    cat >> "$report_file" << EOF

## User Creation Commands

### Scripts with dscl operations
EOF
    
    for script in "$SCRIPT_DIR"/*.zsh; do
        local script_name="$(basename "$script")"
        local dscl_commands
        dscl_commands=$(extract_dscl_commands "$script" || true)
        
        if [[ -n "$dscl_commands" ]]; then
            echo "#### $script_name" >> "$report_file"
            echo '```' >> "$report_file"
            echo "$dscl_commands" >> "$report_file"
            echo '```' >> "$report_file"
            echo "" >> "$report_file"
        fi
    done
    
    success "Conflict report generated: $report_file"
}

# Main conflict detection
main() {
    info "Script Conflict Detection Tool"
    info "=============================="
    echo
    
    local total_conflicts=0
    
    # Check different types of conflicts
    check_font_conflicts
    local font_result=$?
    ((total_conflicts += font_result))
    echo
    
    check_user_creation_conflicts
    local user_result=$?
    ((total_conflicts += user_result))
    echo
    
    check_system_config_conflicts
    local config_result=$?
    ((total_conflicts += config_result))
    echo
    
    # Generate detailed report
    generate_conflict_report
    echo
    
    # Summary
    if [[ $total_conflicts -eq 0 ]]; then
        success "===========================================" 
        success "No script conflicts detected!"
        success "All scripts appear to be properly separated"
        success "==========================================="
    else
        error "==========================================="
        error "Found $total_conflicts script conflicts"
        error "Review the issues above and refactor scripts"
        error "==========================================="
        return 1
    fi
    
    return 0
}

# Help function
usage() {
    cat << EOF
$SCRIPT_NAME - Script Conflict Detection Tool

USAGE:
    $SCRIPT_NAME [OPTIONS]

DESCRIPTION:
    Analyzes setup scripts for conflicts and overlapping operations.
    Generates detailed conflict reports to help identify issues.

OPTIONS:
    -h, --help           Show this help message

DETECTION AREAS:
    • Font installation conflicts (Homebrew vs manual)
    • User creation conflicts (multiple scripts creating users)
    • System configuration conflicts (duplicate defaults write)
    • Power management conflicts (conflicting pmset commands)

OUTPUT:
    • Console output with conflict warnings
    • Detailed conflict report in docs/conflict-detection-report.md

EXAMPLES:
    $SCRIPT_NAME                    # Run conflict detection
    $SCRIPT_NAME --help             # Show help

NOTES:
    • Run this tool after making changes to setup scripts
    • Review the generated report for detailed analysis
    • Resolve conflicts before running setup scripts

EOF
}

# Parse command line arguments
case "${1:-}" in
    -h|--help)
        usage
        exit 0
        ;;
    "")
        # Run conflict detection
        ;;
    *)
        error "Invalid argument: $1"
        usage
        exit 1
        ;;
esac

# Run main function
main
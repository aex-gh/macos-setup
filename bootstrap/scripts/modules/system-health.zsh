#!/usr/bin/env zsh
# ABOUTME: System health monitoring and diagnostic utilities for macOS setup
# ABOUTME: Provides power management monitoring, remote access testing, and system health checks

#=============================================================================
# SCRIPT: system-health.zsh
# AUTHOR: macOS Setup System
# DATE: 2025-01-07
# VERSION: 1.0.0
# 
# DESCRIPTION:
#   Comprehensive system health monitoring for macOS, focusing on power
#   management, remote access services, and overall system performance
#
# USAGE:
#   source system-health.zsh
#   system_health_check
#
# REQUIREMENTS:
#   - macOS 11.0+ (Big Sur)
#   - Network connectivity for remote access testing
#   - Administrator privileges for some checks
#
# NOTES:
#   - Monitors power management configuration
#   - Tests remote access connectivity
#   - Provides system performance metrics
#   - Includes automated health reports
#=============================================================================

# Source common utilities
source "${0:A:h}/../lib/dry-run-utils.zsh"

# Health monitoring constants
readonly HEALTH_LOG_FILE="/tmp/system-health.log"
readonly HEALTH_REPORT_DIR="$HOME/.system-health"
readonly HEALTH_HISTORY_FILE="$HEALTH_REPORT_DIR/health-history.log"

#=============================================================================
# POWER MANAGEMENT MONITORING
#=============================================================================

check_power_management() {
    info "Checking power management configuration..."
    
    local issues=()
    local warnings=()
    local machine_type
    machine_type=$(system_profiler SPHardwareDataType | grep "Model Name" | awk -F': ' '{print $2}' | xargs)
    
    # Get current power settings
    local power_settings
    power_settings=$(pmset -g 2>/dev/null)
    
    if [[ -z "$power_settings" ]]; then
        issues+=("Unable to read power management settings")
        return 1
    fi
    
    # Extract key settings
    local system_sleep
    local display_sleep
    local disk_sleep
    local hibernation_mode
    local standby_mode
    local womp_setting
    
    system_sleep=$(echo "$power_settings" | grep -E "^\s*sleep\s+" | awk '{print $2}')
    display_sleep=$(echo "$power_settings" | grep -E "^\s*displaysleep\s+" | awk '{print $2}')
    disk_sleep=$(echo "$power_settings" | grep -E "^\s*disksleep\s+" | awk '{print $2}')
    hibernation_mode=$(echo "$power_settings" | grep -E "^\s*hibernatemode\s+" | awk '{print $2}')
    standby_mode=$(echo "$power_settings" | grep -E "^\s*standby\s+" | awk '{print $2}')
    womp_setting=$(echo "$power_settings" | grep -E "^\s*womp\s+" | awk '{print $2}')
    
    # Check settings based on machine type
    if [[ "$machine_type" == *"Mac Studio"* || "$machine_type" == *"Mac mini"* ]]; then
        # Desktop machines should be always-on
        [[ "$system_sleep" != "0" ]] && issues+=("Desktop machine should have system sleep disabled (current: $system_sleep minutes)")
        [[ "$disk_sleep" != "0" ]] && warnings+=("Consider disabling disk sleep for immediate responsiveness (current: $disk_sleep minutes)")
        [[ "$hibernation_mode" != "0" ]] && warnings+=("Consider disabling hibernation for always-on operation (current: $hibernation_mode)")
    elif [[ "$machine_type" == *"MacBook"* ]]; then
        # Mobile machines should have balanced settings
        [[ "$system_sleep" == "0" ]] && warnings+=("Mobile device with system sleep disabled - consider battery settings")
        [[ "$hibernation_mode" == "0" ]] && warnings+=("Mobile device with hibernation disabled - may impact battery life")
    fi
    
    # Common checks
    [[ "$womp_setting" != "1" ]] && warnings+=("Wake for network access disabled - remote access may be limited")
    [[ "$display_sleep" == "0" ]] && warnings+=("Display never sleeps - consider enabling for screen longevity")
    
    # Power assertions check
    local power_assertions
    power_assertions=$(pmset -g assertions 2>/dev/null)
    
    if echo "$power_assertions" | grep -q "PreventUserIdleSystemSleep.*1"; then
        warnings+=("Active power assertions preventing system sleep")
    fi
    
    # Report results
    if [[ ${#issues[@]} -eq 0 && ${#warnings[@]} -eq 0 ]]; then
        success "Power management configuration is optimal for $machine_type"
    else
        if [[ ${#issues[@]} -gt 0 ]]; then
            error "Power management issues found:"
            for issue in "${issues[@]}"; do
                echo "  ❌ $issue"
            done
        fi
        
        if [[ ${#warnings[@]} -gt 0 ]]; then
            warn "Power management recommendations:"
            for warning in "${warnings[@]}"; do
                echo "  ⚠️  $warning"
            done
        fi
    fi
    
    # Display current settings summary
    echo
    info "Current Power Settings Summary:"
    echo "  Machine Type: $machine_type"
    echo "  System Sleep: $system_sleep minutes"
    echo "  Display Sleep: $display_sleep minutes"
    echo "  Disk Sleep: $disk_sleep minutes"
    echo "  Hibernation Mode: $hibernation_mode"
    echo "  Wake for Network: $womp_setting"
    echo "  Standby Mode: $standby_mode"
    
    return ${#issues[@]}
}

monitor_power_events() {
    info "Monitoring power events..."
    
    # Check recent sleep/wake events
    local sleep_events
    sleep_events=$(pmset -g log | grep -E "(Sleep|Wake)" | tail -10)
    
    if [[ -n "$sleep_events" ]]; then
        echo
        info "Recent Power Events (last 10):"
        echo "$sleep_events" | while read -r line; do
            echo "  $line"
        done
    else
        info "No recent power events found"
    fi
    
    # Check current power source
    local power_source
    power_source=$(pmset -g ps | head -1)
    info "Current Power Source: $power_source"
    
    # Battery information (if applicable)
    if pmset -g ps | grep -q "Battery"; then
        local battery_info
        battery_info=$(pmset -g ps | grep "Battery")
        info "Battery Status: $battery_info"
    fi
}

#=============================================================================
# REMOTE ACCESS MONITORING
#=============================================================================

test_remote_access_services() {
    info "Testing remote access services..."
    
    local services_status=()
    local failed_services=()
    
    # Test SSH (port 22)
    if nc -z localhost 22 2>/dev/null; then
        services_status+=("✅ SSH (port 22): Running")
    else
        services_status+=("❌ SSH (port 22): Not accessible")
        failed_services+=("SSH")
    fi
    
    # Test VNC/Screen Sharing (port 5900)
    if nc -z localhost 5900 2>/dev/null; then
        services_status+=("✅ VNC/Screen Sharing (port 5900): Running")
    else
        services_status+=("❌ VNC/Screen Sharing (port 5900): Not accessible")
        failed_services+=("VNC")
    fi
    
    # Test SMB (port 445)
    if nc -z localhost 445 2>/dev/null; then
        services_status+=("✅ SMB File Sharing (port 445): Running")
    else
        services_status+=("❌ SMB File Sharing (port 445): Not accessible")
        failed_services+=("SMB")
    fi
    
    # Test AFP (port 548)
    if nc -z localhost 548 2>/dev/null; then
        services_status+=("✅ AFP File Sharing (port 548): Running")
    else
        services_status+=("❌ AFP File Sharing (port 548): Not accessible")
        failed_services+=("AFP")
    fi
    
    # Display results
    echo
    info "Remote Access Services Status:"
    for status in "${services_status[@]}"; do
        echo "  $status"
    done
    
    # Test network connectivity
    echo
    test_network_connectivity
    
    # Return status
    if [[ ${#failed_services[@]} -eq 0 ]]; then
        success "All remote access services are running"
        return 0
    else
        warn "Some remote access services are not running: ${failed_services[*]}"
        return 1
    fi
}

test_network_connectivity() {
    info "Testing network connectivity..."
    
    local hostname
    hostname=$(hostname)
    
    # Test local network interfaces
    echo "Network Interfaces:"
    ifconfig | grep -E "inet [0-9]" | grep -v "127.0.0.1" | while read -r line; do
        local ip
        ip=$(echo "$line" | awk '{print $2}')
        echo "  📍 $ip"
        
        # Test if this IP is reachable
        if ping -c 1 -W 1000 "$ip" &>/dev/null; then
            echo "    ✅ Reachable"
        else
            echo "    ❌ Not reachable"
        fi
    done
    
    # Test DNS resolution
    echo
    info "DNS Resolution:"
    if nslookup google.com &>/dev/null; then
        echo "  ✅ External DNS resolution working"
    else
        echo "  ❌ External DNS resolution failed"
    fi
    
    if nslookup "$hostname.local" &>/dev/null; then
        echo "  ✅ Local hostname resolution working"
    else
        echo "  ❌ Local hostname resolution failed"
    fi
    
    # Test internet connectivity
    echo
    info "Internet Connectivity:"
    if ping -c 1 -W 3000 8.8.8.8 &>/dev/null; then
        echo "  ✅ Internet connectivity available"
    else
        echo "  ❌ Internet connectivity unavailable"
    fi
}

check_firewall_status() {
    info "Checking firewall configuration..."
    
    local firewall_status
    firewall_status=$(sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null)
    
    if [[ "$firewall_status" == *"enabled"* ]]; then
        success "Application firewall is enabled"
    else
        warn "Application firewall is disabled"
    fi
    
    # Check stealth mode
    local stealth_mode
    stealth_mode=$(sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getstealthmode 2>/dev/null)
    
    if [[ "$stealth_mode" == *"enabled"* ]]; then
        info "Stealth mode is enabled"
    else
        warn "Stealth mode is disabled"
    fi
    
    # Check allowed applications
    echo
    info "Firewall Allowed Applications:"
    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --listapps 2>/dev/null | grep -E "(ALLOW|ssh|vnc)" || echo "  No specific applications configured"
}

#=============================================================================
# SYSTEM PERFORMANCE MONITORING
#=============================================================================

check_system_performance() {
    info "Checking system performance..."
    
    # CPU usage
    local cpu_usage
    cpu_usage=$(top -l 1 | grep "CPU usage" | awk '{print $3}' | sed 's/%//')
    
    echo "System Performance Metrics:"
    echo "  CPU Usage: $cpu_usage%"
    
    if [[ ${cpu_usage%.*} -gt 80 ]]; then
        warn "High CPU usage detected: $cpu_usage%"
    fi
    
    # Memory usage
    local memory_info
    memory_info=$(vm_stat | awk '
        /Pages free/ { free = $3 }
        /Pages active/ { active = $3 }
        /Pages inactive/ { inactive = $3 }
        /Pages speculative/ { speculative = $3 }
        /Pages wired/ { wired = $3 }
        END {
            gsub(/\./, "", free)
            gsub(/\./, "", active)
            gsub(/\./, "", inactive)
            gsub(/\./, "", speculative)
            gsub(/\./, "", wired)
            total = free + active + inactive + speculative + wired
            used = active + inactive + speculative + wired
            printf "%.1f%% (%.1fGB used / %.1fGB total)", 
                (used/total)*100, 
                (used*4096)/(1024*1024*1024), 
                (total*4096)/(1024*1024*1024)
        }'
    )
    
    echo "  Memory Usage: $memory_info"
    
    # Disk usage
    local disk_usage
    disk_usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
    
    echo "  Disk Usage: $disk_usage% of root volume"
    
    if [[ $disk_usage -gt 90 ]]; then
        warn "Low disk space: $disk_usage% used"
    elif [[ $disk_usage -gt 80 ]]; then
        info "Disk usage warning: $disk_usage% used"
    fi
    
    # Load average
    local load_avg
    load_avg=$(uptime | awk -F'load averages:' '{print $2}' | xargs)
    
    echo "  Load Average: $load_avg"
    
    # Uptime
    local uptime_info
    uptime_info=$(uptime | sed 's/.*up \([^,]*\),.*/\1/')
    
    echo "  Uptime: $uptime_info"
}

check_system_health() {
    info "Checking overall system health..."
    
    local health_issues=()
    
    # Check disk health
    if ! diskutil verifyVolume / &>/dev/null; then
        health_issues+=("Disk verification failed")
    fi
    
    # Check system log for errors
    local recent_errors
    recent_errors=$(sudo tail -100 /var/log/system.log | grep -i error | wc -l | xargs)
    
    if [[ $recent_errors -gt 10 ]]; then
        health_issues+=("High number of recent errors in system log: $recent_errors")
    fi
    
    # Check for kernel panics
    if ls /Library/Logs/DiagnosticReports/Kernel_* &>/dev/null; then
        local panic_count
        panic_count=$(ls /Library/Logs/DiagnosticReports/Kernel_* 2>/dev/null | wc -l | xargs)
        health_issues+=("Recent kernel panics detected: $panic_count")
    fi
    
    # Check temperature (if available)
    if command -v powermetrics &>/dev/null; then
        local temp_info
        temp_info=$(sudo powermetrics -n 1 -s thermal 2>/dev/null | grep "CPU die temperature" | head -1)
        if [[ -n "$temp_info" ]]; then
            echo "  System Temperature: $temp_info"
        fi
    fi
    
    # Report health status
    if [[ ${#health_issues[@]} -eq 0 ]]; then
        success "System health check passed"
    else
        warn "System health issues detected:"
        for issue in "${health_issues[@]}"; do
            echo "  ⚠️  $issue"
        done
    fi
    
    return ${#health_issues[@]}
}

#=============================================================================
# COMPREHENSIVE HEALTH CHECK
#=============================================================================

system_health_check() {
    info "Running comprehensive system health check..."
    echo
    
    # Create health report directory
    mkdir -p "$HEALTH_REPORT_DIR"
    
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Initialize health report
    local health_report="$HEALTH_REPORT_DIR/health-report-$(date '+%Y%m%d-%H%M%S').txt"
    
    echo "=== macOS System Health Report ===" > "$health_report"
    echo "Generated: $timestamp" >> "$health_report"
    echo "Hostname: $(hostname)" >> "$health_report"
    echo "System: $(sw_vers -productName) $(sw_vers -productVersion)" >> "$health_report"
    echo "" >> "$health_report"
    
    # Run health checks
    local checks_passed=0
    local checks_failed=0
    
    # Power management check
    echo "=== Power Management Check ===" >> "$health_report"
    if check_power_management >> "$health_report" 2>&1; then
        ((checks_passed++))
    else
        ((checks_failed++))
    fi
    echo "" >> "$health_report"
    
    # Remote access check
    echo "=== Remote Access Services Check ===" >> "$health_report"
    if test_remote_access_services >> "$health_report" 2>&1; then
        ((checks_passed++))
    else
        ((checks_failed++))
    fi
    echo "" >> "$health_report"
    
    # System performance check
    echo "=== System Performance Check ===" >> "$health_report"
    check_system_performance >> "$health_report" 2>&1
    ((checks_passed++))
    echo "" >> "$health_report"
    
    # System health check
    echo "=== System Health Check ===" >> "$health_report"
    if check_system_health >> "$health_report" 2>&1; then
        ((checks_passed++))
    else
        ((checks_failed++))
    fi
    echo "" >> "$health_report"
    
    # Firewall check
    if [[ $DRY_RUN != "true" ]]; then
        echo "=== Firewall Check ===" >> "$health_report"
        check_firewall_status >> "$health_report" 2>&1
        ((checks_passed++))
        echo "" >> "$health_report"
    fi
    
    # Summary
    echo "=== Health Check Summary ===" >> "$health_report"
    echo "Checks Passed: $checks_passed" >> "$health_report"
    echo "Checks Failed: $checks_failed" >> "$health_report"
    echo "" >> "$health_report"
    
    # Log to history
    echo "[$timestamp] Health Check - Passed: $checks_passed, Failed: $checks_failed" >> "$HEALTH_HISTORY_FILE"
    
    # Display results
    echo
    if [[ $checks_failed -eq 0 ]]; then
        success "System health check completed successfully"
        echo "  ✅ All $checks_passed checks passed"
    else
        warn "System health check completed with issues"
        echo "  ✅ $checks_passed checks passed"
        echo "  ❌ $checks_failed checks failed"
    fi
    
    echo
    info "Detailed report saved to: $health_report"
    info "Health history: $HEALTH_HISTORY_FILE"
    
    return $checks_failed
}

#=============================================================================
# MONITORING UTILITIES
#=============================================================================

start_health_monitoring() {
    info "Starting continuous health monitoring..."
    
    if [[ $DRY_RUN == "true" ]]; then
        echo "[DRY RUN] Would start health monitoring daemon"
        return 0
    fi
    
    # Create monitoring script
    local monitor_script="$HEALTH_REPORT_DIR/health-monitor.zsh"
    
    cat > "$monitor_script" << 'EOF'
#!/usr/bin/env zsh
# Automated health monitoring script

while true; do
    sleep 3600  # Run every hour
    
    # Quick health check
    if ! nc -z localhost 22 &>/dev/null; then
        echo "[$(date)] SSH service down" >> ~/.system-health/alerts.log
    fi
    
    if ! nc -z localhost 5900 &>/dev/null; then
        echo "[$(date)] VNC service down" >> ~/.system-health/alerts.log
    fi
    
    # Log system metrics
    echo "[$(date)] $(uptime)" >> ~/.system-health/uptime.log
done
EOF
    
    chmod +x "$monitor_script"
    
    # Start monitoring in background
    nohup "$monitor_script" &
    local monitor_pid=$!
    
    echo "$monitor_pid" > "$HEALTH_REPORT_DIR/monitor.pid"
    
    success "Health monitoring started (PID: $monitor_pid)"
    info "Logs will be written to: $HEALTH_REPORT_DIR/"
}

stop_health_monitoring() {
    info "Stopping health monitoring..."
    
    local pid_file="$HEALTH_REPORT_DIR/monitor.pid"
    
    if [[ -f "$pid_file" ]]; then
        local monitor_pid
        monitor_pid=$(cat "$pid_file")
        
        if kill "$monitor_pid" 2>/dev/null; then
            success "Health monitoring stopped (PID: $monitor_pid)"
            rm -f "$pid_file"
        else
            warn "Could not stop monitoring process (PID: $monitor_pid)"
        fi
    else
        warn "No monitoring process found"
    fi
}

#=============================================================================
# UTILITY FUNCTIONS
#=============================================================================

health_report_summary() {
    info "System Health Summary:"
    
    if [[ -f "$HEALTH_HISTORY_FILE" ]]; then
        echo
        echo "Recent Health Checks:"
        tail -5 "$HEALTH_HISTORY_FILE"
    fi
    
    echo
    echo "Available Reports:"
    ls -la "$HEALTH_REPORT_DIR"/health-report-*.txt 2>/dev/null | tail -5 || echo "No reports found"
}

system_health_help() {
    cat << EOF
${BOLD}System Health Monitoring${RESET}

${BOLD}USAGE${RESET}
    system_health_check          Run comprehensive health check
    check_power_management       Check power management configuration
    test_remote_access_services  Test remote access connectivity
    check_system_performance     Check system performance metrics
    start_health_monitoring      Start continuous monitoring
    stop_health_monitoring       Stop continuous monitoring
    health_report_summary        Show recent health reports

${BOLD}HEALTH CHECKS${RESET}
    Power Management:
        • Sleep/wake settings validation
        • Machine-specific configuration check
        • Power event monitoring

    Remote Access:
        • SSH, VNC, SMB, AFP service testing
        • Network connectivity validation
        • Firewall configuration check

    System Performance:
        • CPU, memory, disk usage
        • Load average and uptime
        • System health validation

${BOLD}REPORTS${RESET}
    • Detailed reports saved to ~/.system-health/
    • Health history tracking
    • Continuous monitoring available

${BOLD}EXAMPLES${RESET}
    # Run full health check
    system_health_check

    # Check specific components
    check_power_management
    test_remote_access_services

    # Start monitoring
    start_health_monitoring
EOF
}

# Export functions for use in other scripts
autoload -U system_health_check
autoload -U check_power_management
autoload -U test_remote_access_services
autoload -U check_system_performance
autoload -U start_health_monitoring
autoload -U stop_health_monitoring
autoload -U health_report_summary
autoload -U system_health_help
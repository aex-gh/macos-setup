# Power Management & Remote Access Guide

## Overview

This guide covers the comprehensive power management and remote access configuration system designed specifically for Apple Silicon Macs, addressing the limitations of traditional Wake on LAN while ensuring reliable remote connectivity.

## Table of Contents

- [Apple Silicon Wake on LAN Limitations](#apple-silicon-wake-on-lan-limitations)
- [Power Management Strategy](#power-management-strategy)
- [Remote Access Configuration](#remote-access-configuration)
- [Machine-Specific Configurations](#machine-specific-configurations)
- [System Health Monitoring](#system-health-monitoring)
- [Usage Examples](#usage-examples)
- [Troubleshooting](#troubleshooting)

## Apple Silicon Wake on LAN Limitations

### Key Limitations

Apple Silicon Macs (M1, M1 Pro, M1 Max, M2, M3, M4) have significant limitations compared to Intel Macs:

- **No Traditional Ethernet Wake on LAN**: Unlike Intel Macs, Apple Silicon cannot wake from sleep via Ethernet magic packets
- **Limited Wi-Fi Wake Support**: Only works for specific Apple services (AirPlay, etc.), not for SSH or Screen Sharing
- **Deep Sleep States**: Apple Silicon Macs enter deep sleep states that cannot be remotely awakened
- **Power Management Architecture**: Fundamentally different power management compared to Intel-based systems

### Why Always-On is Superior

Given these limitations, an always-on configuration provides:

1. **100% Reliability**: Guaranteed remote access availability
2. **Immediate Response**: No wake-up delays or failed wake attempts
3. **Consistent Performance**: No power state-related connectivity issues
4. **Energy Efficiency**: Apple Silicon is extremely power-efficient even when awake

## Power Management Strategy

### Desktop Machines (Mac Studio, Mac mini)

**Philosophy**: Always-on operation for reliable server-like functionality

```bash
# Configuration applied:
sleep_system=0                 # Never sleep system
sleep_display=10               # Display sleep after 10 minutes (screen protection)
sleep_disk=0                   # Never sleep disks (immediate response)
hibernate_mode=0               # Disable hibernation
standby_mode=0                 # Disable standby mode
power_nap=1                    # Enable for background updates
```

**Benefits**:
- Always accessible via SSH and Screen Sharing
- Immediate file sharing response
- Continuous network service availability
- Background maintenance and updates

**Power Consumption**:
- Mac Studio M1 Max: ~20-30W idle (≈$20-40 AUD annually)
- Mac mini M4: ~10-15W idle (≈$15-25 AUD annually)

### Mobile Machines (MacBook Pro, MacBook Air)

**Philosophy**: Balanced configuration - conservative on battery, always-on when plugged in

```bash
# Battery power settings:
sleep_system_battery=15        # Sleep after 15 minutes on battery
sleep_display_battery=5        # Display sleep after 5 minutes on battery
sleep_disk_battery=10          # Disk sleep after 10 minutes on battery

# AC power settings:
sleep_system_power=0           # Never sleep when plugged in
sleep_display_power=30         # Display sleep after 30 minutes on AC
sleep_disk_power=0             # Never sleep disks on AC power
```

**Benefits**:
- Extended battery life when mobile
- Always-on behaviour when connected to power
- Automatic network integration when docked
- Seamless transition between mobile and desktop use

## Remote Access Configuration

### Services Configured

#### SSH (Secure Shell)
- **Port**: 22
- **Security**: Hardened configuration with key-based authentication
- **Features**: SFTP support, connection keep-alive, fail2ban protection

#### Screen Sharing (VNC)
- **Port**: 5900
- **Security**: Encrypted VNC with password protection
- **Features**: Full remote desktop access, clipboard sharing

#### File Sharing
- **SMB**: Port 445 (Windows/Linux compatibility)
- **AFP**: Port 548 (macOS native protocol)
- **Features**: Network discovery, Time Machine support

#### Network Discovery
- **Bonjour**: Automatic service discovery
- **mDNS**: Hostname resolution (.local domains)
- **Features**: Zero-configuration networking

### Security Features

#### Firewall Configuration
```bash
# Firewall settings applied:
firewall_enabled=true          # Application firewall enabled
stealth_mode=true              # Hide from port scans
allow_signed_apps=true         # Allow signed applications
specific_service_rules=true    # Explicit rules for SSH, VNC, file sharing
```

#### SSH Hardening
```bash
# SSH security measures:
key_authentication=preferred   # SSH keys preferred over passwords
max_auth_tries=3               # Limit authentication attempts
disable_root_login=true        # Prevent root SSH access
use_privilege_separation=true  # Enhanced security model
connection_timeout=300         # Automatic session timeout
```

## Machine-Specific Configurations

### Mac Studio Configuration

**Profile**: High-performance always-on server

```ini
[system]
# Always-on configuration for maximum availability
sleep_system=0                 # Never sleep
sleep_display=10               # Screen protection only
maintenance_wake_time=03:00    # Daily maintenance at 3 AM

[sharing]
# Full network services
enable_all_sharing=true        # SSH, VNC, AFP, SMB
time_machine_server=true       # Act as Time Machine destination
network_discovery=true         # Full Bonjour advertisement

[performance]
# Optimised for continuous operation
thermal_management=aggressive  # Active cooling
background_refresh=unlimited   # No restrictions
```

### Mac mini Configuration

**Profile**: Compact always-on desktop

```ini
[system]
# Always-on with power efficiency focus
sleep_system=0                 # Never sleep
sleep_display=10               # Screen protection
thermal_management=balanced    # Balanced cooling for compact design

[sharing]
# Standard network services
enable_ssh=true               # SSH access
enable_screen_sharing=true    # VNC access
enable_file_sharing=true      # SMB/AFP sharing
client_mode=true              # Can mount Mac Studio shares

[performance]
# Optimised for 16GB memory
memory_management=aggressive   # Efficient memory use
container_limits=8GB          # Docker memory limit
```

### MacBook Pro Configuration

**Profile**: Mobile productivity with network integration

```ini
[system]
# Balanced mobile configuration
sleep_system_battery=15        # Conservative battery settings
sleep_system_power=0           # Always-on when plugged in
optimised_battery_charging=true # Battery health protection

[sharing]
# Client-focused configuration
enable_ssh=true               # SSH for development
auto_mount_servers=true       # Connect to Mac Studio/mini
network_integration=true      # Seamless network switching

[performance]
# Mobile-optimised settings
visual_effects=standard       # Balance performance/battery
background_refresh=intelligent # Smart background processing
```

## System Health Monitoring

### Automated Health Checks

The system includes comprehensive health monitoring:

```bash
# Available monitoring commands:
system_health_check            # Full system health check
check_power_management         # Power configuration validation
test_remote_access_services    # Remote service connectivity test
monitor_system_performance     # Performance metrics
```

### Health Check Components

#### Power Management Validation
- Verifies power settings match machine type
- Checks for active power assertions
- Monitors sleep/wake events
- Validates hibernation configuration

#### Remote Access Testing
- Tests SSH connectivity (port 22)
- Validates VNC service (port 5900)
- Checks file sharing (SMB port 445, AFP port 548)
- Verifies network discovery services

#### System Performance Monitoring
- CPU usage and load average
- Memory pressure and swap usage
- Disk space and I/O performance
- Network connectivity and latency

#### Continuous Monitoring
- Hourly service availability checks
- System metric logging
- Alert generation for service failures
- Historical performance tracking

### Health Reports

Reports are automatically generated and stored:

```bash
# Report locations:
~/.system-health/health-report-YYYYMMDD-HHMMSS.txt  # Detailed reports
~/.system-health/health-history.log                 # Historical summary
~/.system-health/alerts.log                         # Service alerts
~/.system-health/uptime.log                         # System uptime tracking
```

## Usage Examples

### Initial Setup

```bash
# Configure power management for current machine
source bootstrap/scripts/modules/power-management.zsh
configure_power_management

# Set up remote access services
source bootstrap/scripts/modules/remote-access.zsh
configure_remote_access

# Run initial health check
source bootstrap/scripts/modules/system-health.zsh
system_health_check
```

### Daily Monitoring

```bash
# Quick health check
system_health_check

# Test specific services
test_remote_access_services

# Check power configuration
check_power_management

# Monitor system performance
check_system_performance
```

### Troubleshooting

```bash
# Reset power management to defaults
reset_power_defaults

# Disable all remote access
disable_remote_access

# View detailed system status
display_current_power_settings
monitor_remote_access

# Check system health
health_report_summary
```

### Connecting to Remote Machines

```bash
# SSH connections
ssh andrew@mac-studio.local
ssh andrew@mac-mini.local
ssh andrew@macbook-pro.local

# VNC connections
open vnc://mac-studio.local:5900
open vnc://mac-mini.local:5900

# File sharing
open afp://mac-studio.local
open smb://mac-mini.local
```

## Troubleshooting

### Common Issues

#### Remote Access Not Working

**Symptoms**: Cannot connect via SSH or VNC
**Solutions**:
1. Check service status: `test_remote_access_services`
2. Verify firewall settings: `check_firewall_status`
3. Test network connectivity: `test_network_connectivity`
4. Restart services: `configure_remote_access`

#### Power Management Issues

**Symptoms**: System sleeps unexpectedly
**Solutions**:
1. Verify configuration: `check_power_management`
2. Check power assertions: `pmset -g assertions`
3. Review recent power events: `monitor_power_events`
4. Reconfigure settings: `configure_power_management`

#### High Power Consumption

**Symptoms**: Unexpected power usage on desktop machines
**Solutions**:
1. Check running processes: `check_system_performance`
2. Review background applications
3. Verify thermal management settings
4. Consider display sleep settings

#### Network Discovery Problems

**Symptoms**: Machines not visible on network
**Solutions**:
1. Check Bonjour services: `test_network_connectivity`
2. Verify hostname configuration
3. Test mDNS resolution: `nslookup hostname.local`
4. Restart network discovery: `configure_network_discovery`

### Performance Optimisation

#### Desktop Machines (Always-On)
- Monitor thermal performance during continuous operation
- Schedule maintenance during low-usage periods (3 AM default)
- Use SSD optimisation for continuous disk access
- Configure network storage for large file operations

#### Mobile Machines (Balanced)
- Optimise background app refresh settings
- Use Power Nap selectively based on usage patterns
- Configure automatic network mounting for seamless connectivity
- Balance visual effects with battery requirements

### Security Considerations

#### Network Security
- Regularly update SSH keys and VNC passwords
- Monitor connection logs for unauthorised access attempts
- Use VPN for remote access over internet
- Keep firewall rules up to date

#### Physical Security
- Enable FileVault disk encryption on all machines
- Configure Touch ID for sudo access (MacBook Pro)
- Use secure passphrases for user accounts
- Regular security updates via automated processes

## Advanced Configuration

### Custom Power Schedules

```bash
# Custom maintenance windows
sudo pmset repeat wakeorpoweron MTWRFSU 02:00:00  # Wake at 2 AM
sudo pmset repeat shutdown MTWRFSU 04:00:00       # Shutdown at 4 AM (if needed)
```

### Network Optimisation

```bash
# Ethernet preference for desktop machines
sudo networksetup -ordernetworkservices "Ethernet" "Wi-Fi"

# Custom DNS for improved performance
sudo networksetup -setdnsservers "Wi-Fi" 1.1.1.1 1.0.0.1
```

### Service Customisation

```bash
# Custom SSH configuration
sudo vim /etc/ssh/sshd_config

# VNC display settings
sudo defaults write /Library/Preferences/com.apple.RemoteDesktop.plist VNCDisplayNumber -int 1

# File sharing optimisation
sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server.plist MaxProtocol -string "SMB3"
```

## Integration with macOS Setup System

This power management and remote access system integrates seamlessly with the broader macOS setup system:

- **Machine Detection**: Automatically detects hardware type and applies appropriate configuration
- **Profile Integration**: Works with existing machine profiles (mac-studio.conf, mac-mini.conf, macbook-pro.conf)
- **Dry Run Support**: Full dry-run capability for testing configurations
- **Logging Integration**: Comprehensive logging with existing system logging infrastructure
- **Health Monitoring**: Integrated with system health checking and reporting

The system respects the existing configuration management approach while adding robust power management and remote access capabilities specifically designed for Apple Silicon limitations.

---

## Conclusion

This comprehensive power management and remote access system addresses the fundamental limitations of Wake on LAN on Apple Silicon Macs by implementing an always-on strategy for desktop machines and balanced power management for mobile devices. The result is reliable, secure, and efficient remote access across your entire Mac ecosystem.

The system provides:
- **Reliability**: 100% remote access availability for desktop machines
- **Efficiency**: Optimised power consumption for each machine type
- **Security**: Hardened remote access with comprehensive firewall protection
- **Monitoring**: Continuous health monitoring and alerting
- **Integration**: Seamless integration with existing macOS setup workflows

For additional support or feature requests, refer to the project documentation or submit issues through the appropriate channels.
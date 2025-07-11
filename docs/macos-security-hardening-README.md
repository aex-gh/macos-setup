# macOS Security Hardening Script

## Overview

The macOS Security Hardening Script provides comprehensive security enhancements for macOS systems beyond the base setup configuration. This script implements industry-standard security practices to protect against common threats while maintaining system usability. It should be run after the initial macOS setup is complete.

## Features

### Security Enhancements
- **Firewall Hardening**: Advanced firewall configuration with stealth mode
- **SSH Security**: Hardened SSH daemon configuration with modern encryption
- **System Preferences**: Secure system-wide preference settings
- **Network Security**: Network service hardening and unnecessary service disabling
- **File Permissions**: Secure file and directory permissions
- **Audit Logging**: Comprehensive system audit logging configuration
- **Browser Security**: Secure Safari and system browser settings
- **Service Management**: Disable unnecessary system services

### Reporting and Monitoring
- **Security Report Generation**: Comprehensive security status report
- **Real-time Status Checks**: Live verification of security settings
- **Compliance Monitoring**: Track security configuration compliance
- **Recommendations**: Actionable security improvement suggestions

## Installation and Usage

### Prerequisites
- macOS 11.0+ (Big Sur)
- Administrator privileges (sudo access)
- Completed basic macOS setup
- Internet connection for service configuration

### Running the Script
```bash
# Navigate to scripts directory
cd /Users/andrew/projects/personal/macos-setup/scripts

# Run security hardening
./macos-security-hardening.zsh
```

### Integration with Main Setup
The script can be run as part of the main setup process:
```bash
# Run main setup first
./macos-setup.zsh

# Then run security hardening
./macos-security-hardening.zsh
```

## Security Hardening Features

### 1. Firewall Hardening
```bash
# What it does:
- Enables macOS Application Firewall
- Activates stealth mode (invisible to port scans)
- Blocks all incoming connections by default
- Allows only signed applications
- Enables logging for security monitoring
```

**Configuration Applied**:
- Global firewall state: ON
- Stealth mode: ON
- Block all incoming: ON
- Allow signed apps: ON
- Allow downloaded signed apps: ON

### 2. SSH Security Hardening
```bash
# What it does:
- Disables root login completely
- Enforces key-based authentication only
- Implements modern encryption algorithms
- Limits connection attempts and sessions
- Disables dangerous forwarding options
```

**SSH Configuration**:
- Protocol: 2 (SSH-2 only)
- Root login: Disabled
- Password authentication: Disabled
- Public key authentication: Enabled
- Max auth tries: 3
- Login grace time: 30 seconds
- Strong encryption ciphers only

### 3. System Preferences Hardening
```bash
# What it does:
- Disables automatic login
- Requires immediate password after sleep
- Disables automatic software updates (for manual control)
- Disables Bonjour advertisements
- Configures secure power management
- Disables captive portal assistance
```

**Key Settings**:
- Screensaver password: Immediate
- Auto-login: Disabled
- Wake for network: Disabled
- PowerNap: Disabled
- Bonjour ads: Disabled

### 4. Network Security
```bash
# What it does:
- Disables IPv6 (if not needed)
- Disables AirDrop
- Disables Bluetooth (if not needed)
- Disables IR receiver
- Hardens network service configurations
```

**Network Configuration**:
- IPv6: Disabled on all interfaces
- AirDrop: Disabled
- Bluetooth: Disabled
- IR receiver: Disabled

### 5. File Permissions Hardening
```bash
# What it does:
- Secures SSH directory permissions (700)
- Protects SSH keys (600)
- Secures user directories (700)
- Hardens system log file permissions
```

**Permissions Applied**:
- `~/.ssh/`: 700 (user only)
- `~/.ssh/*`: 600 (user read/write only)
- `~/Documents`, `~/Downloads`, `~/Desktop`: 700
- System logs: 640 (admin readable)

### 6. Service Management
```bash
# What it does:
- Disables AirPlay receiver
- Disables DVD/CD sharing
- Disables Internet sharing
- Disables printer sharing
- Disables unnecessary Bluetooth services
```

**Services Disabled**:
- Remote Desktop (ARD)
- ODS Agent (DVD/CD sharing)
- Internet Sharing
- CUPS printing daemon
- Bluetooth daemon

### 7. Audit Logging
```bash
# What it does:
- Enables comprehensive system audit logging
- Configures audit log rotation
- Sets appropriate audit flags
- Manages audit log retention
```

**Audit Configuration**:
- Audit daemon: Enabled
- Audit flags: Login/logout, administrative actions
- File size limit: 10MB
- Retention: 7 days

### 8. Browser Security
```bash
# What it does:
- Disables Safari developer tools
- Prevents automatic window opening
- Disables autofill for sensitive data
- Enables fraud protection
- Disables plugins and Java
- Shows full URLs in address bar
```

**Safari Settings**:
- Developer tools: Disabled
- Auto-fill passwords: Disabled
- Auto-fill credit cards: Disabled
- Fraud protection: Enabled
- Plugins: Disabled
- Java: Disabled

## Security Report

The script generates a comprehensive security report that includes:

### System Information
- macOS version and build
- Hardware configuration
- System uptime and status

### Security Status
- Firewall configuration and status
- SSH daemon configuration
- FileVault encryption status
- Network interface configuration
- Power management settings

### Service Status
- Running system services
- Disabled unnecessary services
- Audit logging configuration

### File Permissions
- SSH directory permissions
- User directory permissions
- System log file permissions

### Recommendations
- FileVault encryption status
- Software update recommendations
- Additional security tool suggestions
- Monitoring and alerting setup

## Post-Hardening Checklist

### Immediate Actions
1. **Verify SSH Access**: Test SSH key-based authentication
2. **Check FileVault**: Enable FileVault encryption if not already enabled
3. **Test Network Services**: Ensure required services still function
4. **Review Firewall**: Confirm firewall isn't blocking needed applications
5. **Update Software**: Install critical security updates

### Ongoing Maintenance
1. **Monitor Logs**: Regularly review audit logs for suspicious activity
2. **Review SSH Keys**: Audit and update SSH authorized keys
3. **Update Configuration**: Review and update security settings periodically
4. **Backup Configuration**: Backup security configurations before changes
5. **Test Recovery**: Verify system recovery procedures work

## Customisation

### Modifying Security Settings
The script can be customised for specific environments:

```bash
# Edit the script to modify settings
nano /Users/andrew/projects/personal/macos-setup/scripts/macos-security-hardening.zsh

# Common customisations:
# - Enable/disable specific hardening functions
# - Modify SSH configuration for specific needs
# - Adjust firewall rules for applications
# - Configure audit logging retention
```

### Environment-Specific Adjustments
- **Development Systems**: May need less restrictive SSH settings
- **Production Systems**: May require additional monitoring and logging
- **Shared Systems**: May need different user directory permissions
- **Network Systems**: May require IPv6 or specific network services

## Troubleshooting

### Common Issues

#### SSH Access Problems
```bash
# Symptoms: Cannot connect via SSH
# Solution: Check SSH configuration and keys
sudo cat /etc/ssh/sshd_config
ls -la ~/.ssh/
```

#### Network Service Issues
```bash
# Symptoms: Network services not working
# Solution: Re-enable specific services if needed
sudo launchctl load -w /System/Library/LaunchDaemons/service.plist
```

#### Firewall Blocking Applications
```bash
# Symptoms: Applications cannot connect
# Solution: Add firewall exceptions
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add /path/to/app
```

#### Audit Logging Errors
```bash
# Symptoms: Audit logs not generating
# Solution: Check audit daemon status
sudo launchctl list | grep audit
```

### Recovery Procedures

#### Restore SSH Configuration
```bash
# Restore original SSH config
sudo cp /etc/ssh/sshd_config.backup /etc/ssh/sshd_config
sudo launchctl unload /System/Library/LaunchDaemons/ssh.plist
sudo launchctl load /System/Library/LaunchDaemons/ssh.plist
```

#### Disable Firewall
```bash
# Temporarily disable firewall
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate off
```

#### Re-enable Services
```bash
# Re-enable specific services
sudo launchctl load -w /System/Library/LaunchDaemons/service.plist
```

## Security Best Practices

### Before Running
1. **Test in Non-Production**: Always test hardening changes first
2. **Backup Configuration**: Create backups of current settings
3. **Document Changes**: Keep record of what will be changed
4. **Plan Recovery**: Have recovery procedures ready

### During Hardening
1. **Monitor Output**: Watch for errors or warnings
2. **Verify Changes**: Check that changes are applied correctly
3. **Test Immediately**: Test critical services after changes
4. **Document Issues**: Note any problems encountered

### After Hardening
1. **Generate Report**: Run security report to verify status
2. **Test All Services**: Ensure all required services work
3. **Monitor Logs**: Check for any new errors or warnings
4. **Update Documentation**: Document any custom changes made

## Integration with Enterprise Security

### Compliance Standards
The hardening script helps meet various compliance requirements:
- **CIS Benchmarks**: Follows CIS macOS security guidelines
- **NIST Guidelines**: Implements NIST cybersecurity framework practices
- **SOC 2**: Supports SOC 2 security control requirements
- **ISO 27001**: Aligns with ISO 27001 security standards

### Enterprise Features
- **Centralized Logging**: Audit logs can be forwarded to SIEM systems
- **Policy Enforcement**: Settings can be enforced via MDM solutions
- **Monitoring Integration**: Security status can be monitored remotely
- **Compliance Reporting**: Generate reports for audit purposes

## Version Information

- **Version**: Current (updated regularly)
- **Compatibility**: macOS 11.0+ (Big Sur and later)
- **Shell**: Zsh
- **Dependencies**: Administrator privileges, internet connection

## Support and Maintenance

### Getting Help
1. Review the security report for specific issues
2. Check system logs for error messages
3. Verify individual security settings manually
4. Test in a controlled environment first

### Regular Maintenance
1. Run security report monthly
2. Review audit logs weekly
3. Update SSH keys quarterly
4. Refresh security settings after major macOS updates

### Contributing
When modifying the security hardening script:
1. Test thoroughly in isolated environment
2. Document all changes and their security implications
3. Follow principle of least privilege
4. Ensure changes don't break essential functionality
5. Update documentation and security report accordingly

## Warning and Disclaimers

⚠️ **Important Security Considerations**:
- This script makes significant system changes
- Some settings may impact system functionality
- Always test in non-production environment first
- Backup important data before running
- Some changes may require system restart
- Not all settings are appropriate for all environments

🔒 **Security Notice**:
- Security hardening is an ongoing process
- Regular updates and monitoring are essential
- This script provides baseline security improvements
- Additional security measures may be needed based on your threat model
- Consider professional security assessment for critical systems
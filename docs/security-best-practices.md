# Security Considerations and Best Practices

This document outlines security considerations, best practices, and recommendations for the macOS setup automation project.

## Table of Contents

- [Security Architecture](#security-architecture)
- [Credential Management](#credential-management)
- [Network Security](#network-security)
- [System Hardening](#system-hardening)
- [Application Security](#application-security)
- [Data Protection](#data-protection)
- [Monitoring and Auditing](#monitoring-and-auditing)
- [Family Environment Security](#family-environment-security)
- [Development Security](#development-security)
- [Incident Response](#incident-response)

## Security Architecture

### Defense in Depth

The setup implements multiple layers of security:

1. **Physical Security**: FileVault encryption protects data at rest
2. **Network Security**: Firewall rules and network segmentation
3. **Access Control**: User account management and privilege separation
4. **Application Security**: Code signing verification and sandboxing
5. **Data Security**: Encrypted backups and secure credential storage

### Threat Model

**Primary Threats Addressed**:
- Data theft from lost/stolen devices
- Network-based attacks on home infrastructure
- Malware installation and execution
- Unauthorized access to family accounts
- Credential compromise and lateral movement

**Threat Actors Considered**:
- Opportunistic attackers (lost device scenarios)
- Network-based automated attacks
- Malicious software/downloads
- Insider threats (family members with inappropriate access)

## Credential Management

### 1Password Integration

**Security Benefits**:
- Centralized credential storage with strong encryption
- Hardware security key support (WebAuthn/FIDO2)
- Secure sharing within family accounts
- CLI integration without storing credentials in scripts

**Best Practices**:
```bash
# Never store credentials in scripts
# BAD: password="hardcoded_password"
# GOOD: password=$(op read "op://vault/item/field")

# Use service accounts for automation
op read "op://Service-Accounts/setup-automation/token"

# Verify 1Password CLI integrity
op --version
op account list
```

**Configuration Security**:
```bash
# Set restrictive permissions on 1Password config
chmod 600 ~/.config/op/config

# Use device-specific service accounts
# Rotate credentials regularly
# Monitor access logs in 1Password
```

### SSH Key Management

**Key Generation**:
```bash
# Use Ed25519 keys for better security
ssh-keygen -t ed25519 -C "andrew@exley.net.au" -f ~/.ssh/id_ed25519

# Use strong passphrases stored in 1Password
# Configure SSH agent with timeout
ssh-add -t 3600 ~/.ssh/id_ed25519
```

**SSH Configuration**:
```bash
# ~/.ssh/config
Host *
    AddKeysToAgent yes
    UseKeychain yes
    IdentitiesOnly yes
    HashKnownHosts yes
    VerifyHostKeyDNS yes
    ForwardAgent no
    ForwardX11 no
```

### API Key Security

**Storage**:
- Store all API keys in 1Password
- Use environment-specific vaults
- Implement key rotation schedules
- Monitor key usage

**Usage**:
```bash
# Retrieve API keys securely
ANTHROPIC_API_KEY=$(op read "op://Personal/Anthropic-API-Key/credential")
export ANTHROPIC_API_KEY

# Don't log API keys
set +x  # Disable command echoing when handling secrets
unset HISTFILE  # Disable history for sensitive operations
```

## Network Security

### Firewall Configuration

**Device-Specific Rules**:

**MacBook Pro (Mobile)**:
```bash
# Strict rules for portable device
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setblockall on
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on

# Only allow essential signed applications
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add /Applications/Zed.app
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add /Applications/1Password\ 7.app
```

**Mac Studio (Server)**:
```bash
# Selective rules for home server
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setblockall off

# Allow specific development services
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add /opt/homebrew/bin/nginx
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add /usr/local/bin/node

# Configure pf rules for granular control
sudo pfctl -f /etc/pf-custom.conf
```

### Network Segmentation

**IP Range Allocation**:
- MacBook Pro: 10.20.0.11 (dynamic fallback)
- Mac Studio: 10.20.0.10 (static server)
- Mac Mini: 10.20.0.12 (static media center)
- IoT devices: 10.20.1.0/24 (separate VLAN)
- Guest network: 10.20.2.0/24 (isolated)

**DNS Security**:
```bash
# Use secure DNS providers
networksetup -setdnsservers "Wi-Fi" "1.1.1.1" "1.0.0.1"  # Cloudflare
networksetup -setdnsservers "Ethernet" "9.9.9.9" "149.112.112.112"  # Quad9

# Enable DNS over HTTPS where possible
```

### VPN and Remote Access

**Security Considerations**:
- Use WireGuard or modern VPN protocols
- Implement certificate-based authentication
- Configure VPN kill switches
- Monitor VPN connection logs

**Remote Access Security**:
```bash
# SSH hardening
echo "PasswordAuthentication no" | sudo tee -a /etc/ssh/sshd_config
echo "PermitRootLogin no" | sudo tee -a /etc/ssh/sshd_config
echo "Protocol 2" | sudo tee -a /etc/ssh/sshd_config
sudo launchctl stop com.openssh.sshd
sudo launchctl start com.openssh.sshd
```

## System Hardening

### macOS Security Settings

**System Integrity Protection (SIP)**:
```bash
# Verify SIP is enabled
csrutil status
# Should show: "System Integrity Protection status: enabled"

# Never disable SIP in production environments
```

**Gatekeeper Configuration**:
```bash
# Ensure Gatekeeper is enabled
sudo spctl --master-enable

# Check Gatekeeper status
spctl --status

# Allow only Mac App Store and identified developers
sudo spctl --global-enable
```

**Secure Boot and FileVault**:
```bash
# Enable FileVault on all devices
sudo fdesetup enable -user andrew

# Verify FileVault status
fdesetup status

# Configure secure boot policy
# (Boot into Recovery Mode, use Startup Security Utility)
```

### User Account Security

**Privilege Separation**:
- Admin accounts only for system administration
- Standard user accounts for daily use
- Service accounts for automation (where applicable)
- Guest account disabled

**Account Configuration**:
```bash
# Disable guest account
sudo defaults write /Library/Preferences/com.apple.loginwindow GuestEnabled -bool false

# Set account lockout policy
sudo pwpolicy setaccountpolicies $PWD/account-policy.plist

# Configure password requirements
sudo pwpolicy setglobalpolicy "usingHistory=5 minChars=12 requiresAlpha=1 requiresNumeric=1"
```

### Application Security

**Code Signing Verification**:
```bash
# Verify application signatures
codesign -dv --verbose=4 /Applications/Zed.app
spctl -a -v /Applications/Zed.app

# Check for malware
sudo /usr/bin/xprotect
```

**Sandboxing and Permissions**:
```bash
# Review application permissions
tccutil reset All

# Monitor system events
log stream --predicate 'eventMessage contains "deny"'
```

## Data Protection

### Encryption Standards

**Data at Rest**:
- FileVault 2 with AES-256 encryption
- Encrypted Time Machine backups
- Encrypted cloud storage (when used)
- Age-encrypted sensitive dotfiles

**Data in Transit**:
- TLS 1.3 for all network communications
- SSH for remote access
- VPN for untrusted networks
- Verified HTTPS for package downloads

### Backup Security

**Time Machine Security**:
```bash
# Encrypt Time Machine backups
sudo tmutil setdestination -a -p /Volumes/TimeMachine

# Verify backup encryption
tmutil destinationinfo

# Set exclusions for sensitive directories
tmutil addexclusion ~/.ssh/id_*
tmutil addexclusion ~/.gnupg/
```

**Backup Validation**:
```bash
# Verify backup integrity
tmutil verifychecksums /Volumes/TimeMachine

# Test backup restoration
tmutil restore /Volumes/TimeMachine/Latest/Users/andrew/test-file ~/restored-test-file
```

### Sensitive File Handling

**Temporary Files**:
```bash
# Create secure temporary files
TMPFILE=$(mktemp -t setup-script.XXXXXX)
chmod 600 "$TMPFILE"

# Clean up temporary files
trap 'rm -f "$TMPFILE"' EXIT
```

**File Permissions**:
```bash
# Set restrictive permissions on sensitive files
chmod 600 ~/.ssh/config
chmod 700 ~/.ssh/
chmod 600 ~/.gnupg/gpg.conf
chmod 700 ~/.gnupg/

# Check for world-readable files
find ~ -type f -perm -004 -ls
```

## Monitoring and Auditing

### System Monitoring

**Security Event Logging**:
```bash
# Monitor authentication events
log show --predicate 'eventMessage contains "authentication"' --last 1h

# Monitor privilege escalation
log show --predicate 'eventMessage contains "sudo"' --last 1h

# Monitor file system events
sudo fs_usage | grep -E "(write|read)" | head -20
```

**Network Monitoring**:
```bash
# Monitor network connections
lsof -i -P | grep LISTEN
netstat -an | grep LISTEN

# Monitor DNS requests
sudo tcpdump -i any port 53

# Check for suspicious network activity
sudo lsof -i | grep -v "127.0.0.1\|::1"
```

### Intrusion Detection

**File Integrity Monitoring**:
```bash
# Create baseline checksums
find /Applications -type f -exec shasum -a 256 {} \; > ~/security/app-checksums.txt

# Regular integrity checks
# (Compare current checksums with baseline)
```

**Behavioral Monitoring**:
```bash
# Monitor unusual process activity
ps aux | awk '{print $11}' | sort | uniq -c | sort -nr

# Check for unauthorized cron jobs
crontab -l
sudo crontab -l
```

## Family Environment Security

### Child Account Protection

**Parental Controls**:
```bash
# Enable Screen Time restrictions
sudo defaults write /Library/Preferences/com.apple.ScreenTime.plist RestrictionsEnabled -bool true

# Configure app restrictions
sudo defaults write /Library/Preferences/com.apple.applicationaccess.plist allowedApps -array \
    "com.apple.Safari" \
    "com.apple.iWork.Pages" \
    "com.apple.iWork.Numbers"

# Set time-based restrictions
# (Configure through System Preferences > Screen Time)
```

**Content Filtering**:
```bash
# Configure DNS-based content filtering
networksetup -setdnsservers "Wi-Fi" "1.1.1.3" "1.0.0.3"  # Cloudflare for Families

# Enable Safari content filtering
defaults write com.apple.Safari WebKitDeveloperExtrasEnabled -bool false
defaults write com.apple.Safari IncludeDevelopMenu -bool false
```

### Shared Resource Security

**File Sharing Permissions**:
```bash
# Set up secure shared directories
sudo mkdir -p /Users/Shared/Family
sudo chown :staff /Users/Shared/Family
sudo chmod 775 /Users/Shared/Family

# Set ACLs for granular control
sudo chmod +a "andrew allow read,write,delete,chmod,chown" /Users/Shared/Family
sudo chmod +a "ali allow read,write" /Users/Shared/Family
```

**Network Access Control**:
```bash
# Configure user-specific network access
# (Use router-based controls where possible)

# Monitor family network usage
# (Implement usage monitoring and reporting)
```

## Development Security

### Secure Development Practices

**Environment Isolation**:
```bash
# Use virtual environments for all projects
python3 -m venv project-env
source project-env/bin/activate

# Use Docker for service isolation
docker run --rm -it --network=none alpine sh

# Use dedicated development networks
docker network create dev-network --internal
```

**Dependency Security**:
```bash
# Audit Node.js dependencies
npm audit
npm audit fix

# Audit Python dependencies
pip-audit

# Use dependency scanning tools
brew install safety
safety check
```

**Code Security**:
```bash
# Use pre-commit hooks for security scanning
pre-commit install

# Scan for secrets in code
brew install gitleaks
gitleaks detect --source .

# Static code analysis
brew install bandit  # Python security linter
bandit -r src/
```

### Container Security

**Docker Security**:
```bash
# Use official base images
FROM python:3.11-slim

# Run as non-root user
RUN adduser --disabled-password --gecos '' appuser
USER appuser

# Scan images for vulnerabilities
docker scout cves local-image:latest
```

**Development Environment Security**:
```bash
# Isolate development environments
# Use separate user accounts for different projects
# Implement network segmentation for development services
# Regular security scanning of development tools
```

## Incident Response

### Preparation

**Incident Response Plan**:
1. **Detection**: Automated monitoring alerts
2. **Analysis**: Log analysis and forensics
3. **Containment**: Isolate affected systems
4. **Eradication**: Remove threats and vulnerabilities
5. **Recovery**: Restore services and data
6. **Lessons Learned**: Update security measures

**Emergency Contacts**:
- IT Support: [Contact Information]
- Security Team: [Contact Information]
- 1Password Emergency Kit: [Secure Location]

### Detection and Response

**Security Incident Detection**:
```bash
# Automated monitoring script
#!/bin/bash
# Check for suspicious activity
SUSPICIOUS_PROCESSES=$(ps aux | grep -E "(nc|ncat|netcat|telnet)" | grep -v grep)
if [[ -n "$SUSPICIOUS_PROCESSES" ]]; then
    echo "Suspicious network tools detected: $SUSPICIOUS_PROCESSES"
    # Alert mechanism
fi

# Check for unauthorized files
find /Applications -name "*.app" -newer /var/log/install.log
```

**Incident Response Actions**:
```bash
# Immediate containment
sudo pfctl -f /etc/pf-lockdown.conf  # Block all network traffic
sudo launchctl unload /System/Library/LaunchDaemons/com.apple.screensharing.plist

# Evidence collection
sudo fs_usage > /tmp/incident-$(date +%Y%m%d-%H%M%S).log &
sudo lsof > /tmp/incident-lsof-$(date +%Y%m%d-%H%M%S).log
```

### Recovery Procedures

**System Recovery**:
```bash
# Restore from Time Machine backup
tmutil restore /Volumes/TimeMachine/Latest /

# Restore from automated backups
./scripts/backup-restore.zsh restore-all

# Re-run security hardening
./scripts/setup-hardening.zsh
```

**Security Updates**:
```bash
# Emergency security update procedure
sudo softwareupdate -i -a
brew update && brew upgrade
./scripts/system-maintenance.zsh
```

## Compliance and Auditing

### Audit Logging

**Enable Comprehensive Logging**:
```bash
# Enable security auditing
sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.auditd.plist

# Configure audit policy
sudo audit -s
```

**Log Retention**:
- System logs: 30 days minimum
- Security logs: 90 days minimum
- Backup logs: 1 year
- Access logs: As required by policy

### Regular Security Reviews

**Monthly Tasks**:
- Review user accounts and permissions
- Update passwords and rotate keys
- Check system and application updates
- Review firewall and security logs
- Test backup and recovery procedures

**Quarterly Tasks**:
- Comprehensive security assessment
- Penetration testing (if applicable)
- Review and update security policies
- Security awareness training
- Vendor security assessment

**Annual Tasks**:
- Complete security audit
- Disaster recovery testing
- Security policy review and updates
- Risk assessment update
- Compliance validation

## Security Tools and Resources

### Recommended Security Tools

**System Security**:
- Little Snitch: Network monitoring and firewall
- Malwarebytes: Anti-malware protection
- Micro Snitch: Microphone and camera monitoring

**Development Security**:
- GitLeaks: Credential scanning
- Safety: Python dependency scanning
- npm audit: Node.js dependency scanning
- OWASP ZAP: Web application security testing

**Network Security**:
- Wireshark: Network protocol analysis
- Nmap: Network discovery and security auditing
- OpenVPN: Secure VPN solution

### Security Resources

**Apple Security Documentation**:
- [macOS Security Compliance Project](https://github.com/usnistgov/macos_security)
- [Apple Platform Security Guide](https://support.apple.com/guide/security/)
- [CIS macOS Benchmark](https://www.cisecurity.org/benchmark/apple_os)

**Security Communities**:
- OWASP: Web application security
- SANS: Information security training and research
- Apple Developer Security: Developer-focused security resources

This security guide provides a comprehensive framework for implementing and maintaining security in the macOS setup automation project. Regular review and updates of these practices are essential to maintain an effective security posture.
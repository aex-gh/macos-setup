# System Configuration Files

This directory contains macOS system-level configuration files, primarily LaunchAgents and LaunchDaemons.

## LaunchAgent Installation

To install a LaunchAgent (runs as user):

```bash
cp com.user.maintenance.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.user.maintenance.plist
```

To uninstall:

```bash
launchctl unload ~/Library/LaunchAgents/com.user.maintenance.plist
rm ~/Library/LaunchAgents/com.user.maintenance.plist
```

## Files

### com.user.maintenance.plist
Weekly maintenance tasks including:
- Homebrew updates and cleanup
- Log file cleanup (>30 days)
- Trash cleanup (>30 days)

Runs every Monday at 3:00 AM.
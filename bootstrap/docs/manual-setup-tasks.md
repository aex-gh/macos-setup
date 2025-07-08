# Manual Setup Tasks

This document outlines manual configuration tasks that require user interaction through System Preferences or other GUI applications. These tasks are performed after the automated bootstrap setup is complete.

## File Sharing Configuration

### SMB (Windows File Sharing) Setup

Modern macOS file sharing is best configured through System Preferences for reliability and proper security setup.

#### Steps:

1. **Open System Preferences**
   - Click Apple menu > System Preferences
   - Or use Spotlight: `⌘ + Space`, type "System Preferences"

2. **Access Sharing Settings**
   - Click "Sharing" (or search for "Sharing" in System Preferences)

3. **Enable File Sharing**
   - Check the box next to "File Sharing" in the left sidebar
   - This will start the file sharing service

4. **Configure SMB Sharing**
   - Click the "Options..." button
   - Check "Share files and folders using SMB"
   - Select users who should have SMB access
   - Enter passwords for selected users when prompted

5. **Add Shared Folders**
   - In the main File Sharing panel, click the "+" button under "Shared Folders"
   - Add folders you want to share (e.g., the `~/Shared` folder created during setup)
   - Select appropriate permissions for each folder

6. **Configure User Access**
   - For each shared folder, click the "Options" button next to user names
   - Set read/write permissions as needed
   - Consider creating a "Shared" user account for guest access if needed

### Time Machine Network Destination

If you want to share Time Machine backup destinations over the network:

1. **Follow SMB Setup Steps Above**

2. **Enable Time Machine Sharing**
   - In File Sharing > Options
   - Check "Share as a Time Machine backup destination"
   - This allows other Macs to use this machine for network backups

3. **Configure Time Machine Folder**
   - Create a dedicated Time Machine folder (e.g., `~/TimeMachine`)
   - Add it to File Sharing with appropriate permissions
   - Ensure sufficient disk space for backups

## Network Discovery Configuration

### Bonjour Service Advertisement

1. **Computer Name Setup**
   - System Preferences > Sharing
   - Set "Computer Name" to something descriptive
   - Note the ".local" name shown (e.g., "Mac-Studio.local")

2. **Service Discovery**
   - Ensure "File Sharing" is enabled for network discovery
   - Other Macs will see this machine in Finder sidebar under "Network"

## Security Considerations

### File Sharing Security

1. **User Accounts**
   - Only enable SMB access for users who need it
   - Use strong passwords for all shared accounts
   - Consider creating dedicated sharing accounts

2. **Folder Permissions**
   - Set minimum necessary permissions
   - Use "Read Only" for public content
   - Restrict "Read & Write" to trusted users

3. **Network Access**
   - Consider enabling the firewall (done automatically during setup)
   - Only share folders that need network access
   - Monitor shared folder access regularly

### SSH Access (Already Configured)

The bootstrap setup has already configured SSH access with:
- SSH service enabled
- Secure configuration applied
- Key-based authentication (if configured)

To connect via SSH:
```bash
ssh username@mac-studio.local
```

## Verification Steps

### Test File Sharing

1. **From Another Mac:**
   - Open Finder
   - Look for your Mac under "Network" in the sidebar
   - Connect and test access to shared folders

2. **From Windows/Linux:**
   - Use SMB client to connect to `smb://mac-studio.local`
   - Enter credentials for a user with SMB access

### Test SSH Access

1. **From Terminal on Another Machine:**
   ```bash
   ssh your-username@mac-studio.local
   ```

2. **Verify SSH Configuration:**
   ```bash
   ssh -T git@github.com  # Test SSH keys if using 1Password SSH agent
   ```

## Troubleshooting

### File Sharing Issues

- **Can't see shared folders:** Check firewall settings and ensure SMB is enabled
- **Access denied:** Verify user permissions and SMB account setup
- **Slow performance:** Consider wired network connection for large file transfers

### Network Discovery Issues

- **Mac not visible on network:** Check Computer Name and Bonjour settings
- **Connection timeouts:** Verify both machines are on same network

### SSH Issues

- **Connection refused:** Ensure SSH service is running: `sudo systemsetup -getremotelogin`
- **Key authentication fails:** Check SSH key configuration and 1Password SSH agent

## Additional Setup Tasks

### Development Environment

If you're using this Mac for development:

1. **Configure IDE/Editor Settings**
   - Import settings and configurations
   - Set up project directories
   - Configure version control authentication

2. **Database Setup**
   - Start database services if installed via Homebrew
   - Configure database users and permissions
   - Set up development databases

3. **Container Services**
   - Configure Docker/OrbStack settings
   - Set resource limits appropriate for your hardware
   - Set up development containers

### Productivity Applications

1. **Configure Installed Applications**
   - Set up 1Password browser integration
   - Configure Raycast/Alfred workflows
   - Set up Karabiner Elements keyboard customisations
   - Add Karabiner Elements to login items if not done automatically:
     - System Preferences > Users & Groups > Login Items
     - Click '+' and select Karabiner-Elements from Applications

2. **System Preferences Customisation**
   - Review and adjust settings applied by the bootstrap
   - Configure additional system preferences as needed
   - Set up additional user accounts if required

---

**Note:** This document will be updated as new manual tasks are identified. Keep this as a reference for post-setup configuration and troubleshooting.
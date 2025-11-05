# Haruki Nguyen's Windows Dotfiles

A comprehensive Windows development environment setup with automated PowerShell scripts for installation and maintenance.

## Features

- **Automated Installation**: Single script installs all essential development tools and productivity apps
- **Package Management**: Uses Scoop and winget for reliable package management
- **Idempotent Operations**: Skips already installed tools and handles errors gracefully
- **Comprehensive Logging**: Detailed progress tracking and error reporting
- **Maintenance Scripts**: Automated system cleanup and package updates
- **Dotfiles Integration**: Symbolic links and configuration management

## Prerequisites & Manual Steps

Before running the scripts, please note:

1. **Manual Installation Required Before Running Scripts:**
   - Install Scoop, Git, and PowerShell manually.
2. **Run as Administrator:**
   - The installer script must be run as administrator to install ProtonVPN.
3. **Manual Installation Required After Running Scripts:**
   - Install manually:
      - MS Office.
      - Docker Desktop.
      - PC Manager.
      - VLC.
      - Google Drive Desktop.
      - [John’s Background Switcher](https://johnsad.ventures/software/backgroundswitcher/).
      - Discord.
      - 1.1.1.1.
      - Google Quick Share.
      - [Wintoys](https://apps.microsoft.com/detail/9P8LTPGCBZXD?hl=en-us&gl=VN&ocid=pdpshare).
      - [O&O ShutUp10++](https://www.oo-software.com/en/shutup10).
      - [Davinci Resolve](https://www.blackmagicdesign.com/products/davinciresolve).
   - Game development:
      - Unity.
      - .NET SDK (For using Unity with VSCode).
   - Unikey: put the executable file into the `Programs` folder in `~`, then create a shortcut to it in the Startup folder (Press `Win + R` and run `shell:startup`).
4. Setting up [MCP for Unity](./docs/MCP-Unity.md).

## Scripts Overview

### 1. `windows-installer.ps1`

Automates the setup of your Windows development environment. Now uses improved configuration and installer functions for maintainability.

**Key Features:**

- Installs and configures Scoop buckets (extras, nonportable)
- Installs winget (if not present)
- Installs development tools: VSCode, Cursor
- Installs productivity apps: Discord, Chrome, Notion, Obsidian
- Installs system utilities: PowerToys, Flowlauncher, Everything, KeePassXC, Windows Terminal
- Installs communication/media: WhatsApp, ProtonVPN (requires admin), VLC, Syncthing
- Installs cloud/file sharing: Google QuickShare
- Sets up GitHub SSH keys
- Creates symbolic links for dotfiles
- Comprehensive logging and error handling

**Usage:**

```powershell
# Run with default settings
.\installers\windows-installer.ps1

# Run with debug logging
.\installers\windows-installer.ps1 -LogLevel Debug

# Run with GitHub email for SSH key
.\installers\windows-installer.ps1 -GitHubEmail "your.email@example.com"
```

### 2. `windows-updater.ps1`

Maintains and cleans your system, updates packages, and performs cleanup operations.

**Key Features:**

- Updates Scoop and winget packages
- Cleans temp files, browser caches, DNS cache, Recycle Bin
- Optional force cleanup (Windows Update cache, disk optimization)
- Logging system with adjustable verbosity

**Usage:**

```powershell
# Run full update and cleanup
.\installers\windows-updater.ps1

# Update packages only
.\installers\windows-updater.ps1 -UpdateOnly

# Cleanup only
.\installers\windows-updater.ps1 -CleanupOnly

# Force cleanup
.\installers\windows-updater.ps1 -ForceCleanup

# Run with debug logging
.\installers\windows-updater.ps1 -LogLevel Debug

# Combine options
.\installers\windows-updater.ps1 -UpdateOnly -LogLevel Debug
```

**Parameters:**

- `-LogLevel`: Set logging level (Debug, Info, Warning, Error). Default: Info
- `-UpdateOnly`: Only update packages, skip cleanup
- `-CleanupOnly`: Only cleanup, skip updates
- `-ForceCleanup`: Aggressive cleanup (use with caution)

## What Gets Installed Automatically

The installer script sets up:

### Package Managers

- **winget** (if not present)
- **Scoop** (must be installed manually before running script)

### Development Tools

- **VSCode**
- **Cursor**

### Productivity Applications

- **Discord**
- **Google Chrome**
- **Notion**
- **Obsidian**

### System Utilities

- **PowerToys**
- **Flowlauncher**
- **Everything**
- **KeePassXC**
- **Windows Terminal**

### Communication & Media

- **ProtonVPN** (requires admin)
- **WhatsApp**
- **VLC Media Player**
- **Syncthing**

### Cloud & File Sharing

- **Google QuickShare**

### Manual Installation Required After Script

- **MS Office**
- **Docker Desktop**
- **PC Manager**
- **Google Drive Desktop**

## After Installation

- Use `scoop install <package>` or `winget install <package>` for additional apps
- Run `code`, `cursor`, `discord`, `chrome`, etc. to verify installations
- Press `Alt+Space` for FlowLauncher
- Check logs for any manual steps or errors
- **DaVinci Resolve:** Follow the script's notification to download and install manually from [the official website](https://www.blackmagicdesign.com/products/davinciresolve)

## Maintenance

Run the updater script regularly to keep your system clean and up to date:

```powershell
# Weekly maintenance
.\installers\windows-updater.ps1

# Monthly deep cleanup
.\installers\windows-updater.ps1 -ForceCleanup
```

## Repository Structure

```
.dotfiles-windows/
├── .config/                    # Configuration directories
│   ├── FlowLauncher/          # FlowLauncher settings
│   └── Windows-Terminal/      # Windows Terminal configuration
├── installers/
│   ├── windows-installer.ps1  # Main installation script
│   └── windows-updater.ps1    # Maintenance and cleanup script
├── scripts/                    # Additional utility scripts
├── shared-dotfiles/           # Git submodule with shared configs
├── .gitconfig                 # Global Git configuration
├── .gitmodules                # Git submodule definitions
└── README.md                  # This file
```

## Git Submodules

This repository uses Git submodules to manage shared configuration files:

- **shared-dotfiles**: Contains configuration files shared between Linux and Windows environments
- To update: `git submodule update --remote`
- To clone with submodules: `git clone --recursive <repository-url>`

## Troubleshooting

### Common Issues

1. **Execution Policy Error:**

   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

2. **Scoop Installation Fails:**
   - Ensure PowerShell is running as Administrator
   - Check internet connection
   - Try running: `irm get.scoop.sh | iex`

3. **winget Not Found:**
   - Install from Microsoft Store: "App Installer"
   - Or download from: <https://github.com/microsoft/winget-cli/releases>

4. **PowerToys Installation Issues:**
   - Try alternative installation: `winget install Microsoft.PowerToys`
   - Or download from: <https://github.com/microsoft/PowerToys/releases>

5. **Scoop Bucket Issues:**
   - If extras bucket fails: `scoop bucket add extras`
   - If nonportable bucket fails: `scoop bucket add nonportable`

### Logging

Both scripts include comprehensive logging. Use the `-LogLevel Debug` parameter for detailed information:

```powershell
.\installers\windows-installer.ps1 -LogLevel Debug
.\installers\windows-updater.ps1 -LogLevel Debug
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

---

**Note:** Most applications are installed automatically. Some applications (e.g., Microsoft Office via winget) may require user interaction during installation. The scripts provide guidance where automation is not possible.

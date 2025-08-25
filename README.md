# Haruki Nguyen's Windows Dotfiles

A comprehensive Windows development environment setup with automated PowerShell scripts for installation and maintenance.

## Features

- **Automated Installation**: Single script installs all essential development tools and productivity apps
- **Package Management**: Uses Scoop and winget for reliable package management
- **Idempotent Operations**: Skips already installed tools and handles errors gracefully
- **Comprehensive Logging**: Detailed progress tracking and error reporting
- **Maintenance Scripts**: Automated system cleanup and package updates
- **Dotfiles Integration**: Symbolic links and configuration management

## Prerequisites

- Windows 10/11
- PowerShell 5.1 or later
- Administrator privileges

## Quick Start

1. **Clone the repository:**

   ```powershell
   git clone https://github.com/yourusername/.dotfiles-windows.git
   cd .dotfiles-windows
   ```

2. **Run the installer:**

   ```powershell
   # Open PowerShell as Administrator
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   .\installers\windows-installer.ps1
   ```

3. **For debug logging:**

   ```powershell
   .\installers\windows-installer.ps1 -LogLevel Debug
   ```

## Scripts Overview

### 1. `windows-installer.ps1`

A streamlined installer script that sets up your complete Windows development environment using a configuration-based approach.

**Features:**

- Installs and configures Scoop package manager with extras and nonportable buckets
- Installs winget (Windows Package Manager)
- Installs essential development tools (Git, VSCode, Cursor)
- Installs productivity applications (Discord, Chrome, Notion, Obsidian)
- Installs system utilities (PowerToys, Flowlauncher, Everything, KeePassXC)
- Installs communication tools (WhatsApp, ProtonVPN)
- Installs media applications (VLC, Syncthing)
- Installs system management tools (PC Manager, Windows Terminal, Office 365)
- Installs cloud tools (Docker Desktop, Google QuickShare, Google Drive)
- Sets up GitHub SSH keys
- Creates symbolic links for dotfiles
- Uses generic installer functions for maintainable code

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

A maintenance script for keeping your system and packages up to date, with comprehensive cleanup capabilities.

**Features:**

- Updates all package managers (Scoop, winget)
- Cleans temporary files and caches
- Clears browser caches
- Clears DNS cache
- Clears Recycle Bin
- Optional force cleanup operations
- Comprehensive logging system

**Usage:**

```powershell
# Run full update and cleanup
.\installers\windows-updater.ps1

# Update packages only
.\installers\windows-updater.ps1 -UpdateOnly

# Cleanup only
.\installers\windows-updater.ps1 -CleanupOnly

# Force cleanup (includes Windows Update cache and disk optimization)
.\installers\windows-updater.ps1 -ForceCleanup

# Run with debug logging
.\installers\windows-updater.ps1 -LogLevel Debug

# Combine options
.\installers\windows-updater.ps1 -UpdateOnly -LogLevel Debug
```

**Parameters:**

- `-LogLevel`: Set logging level (Debug, Info, Warning, Error). Default: Info
- `-UpdateOnly`: Only update packages, skip cleanup operations
- `-CleanupOnly`: Only perform cleanup operations, skip package updates
- `-ForceCleanup`: Enable aggressive cleanup operations (use with caution)

## What Gets Installed

The installer script installs (in order):

### Package Managers

- **winget**: Windows Package Manager (Microsoft)
- **Scoop**: Command-line installer for Windows

### Development Tools

- **Git**: Version control system
- **VSCode**: Code editor
- **Cursor**: AI-powered code editor

### Productivity Applications

- **Discord**: Communication platform
- **Google Chrome**: Web browser
- **Notion**: Note-taking and collaboration
- **Obsidian**: Knowledge management

### System Utilities

- **PowerToys**: Windows utilities and productivity tools
- **Flowlauncher**: Application launcher (Alt+Space)
- **Everything**: File search utility
- **KeePassXC**: Password manager
- **Windows Terminal**: Modern terminal application

### Communication & Media

- **ProtonVPN**: VPN service
- **WhatsApp**: Messaging app
- **VLC Media Player**: Media player
- **Syncthing**: File synchronization

### System Management

- **PC Manager**: Microsoft system optimization tool
- **Pure Battery Add-on**: Battery management
- **Office 365**: Microsoft Office suite

### Cloud & File Sharing

- **Docker Desktop**: Container platform
- **Google QuickShare**: File sharing
- **Google Drive**: Cloud storage

## After Installation

- Use `scoop install <package>` or `winget install <package>` for additional apps
- Run `git --version`, `code`, `cursor`, `discord`, `chrome`, etc. to verify installations
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

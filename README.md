# Haruki Nguyen's Windows Dotfiles

A streamlined setup for a Windows development environment with a single automated PowerShell script.

## Features

- Automated installation of essential development tools and productivity apps
- Uses Scoop and winget for package management
- Idempotent: skips already installed tools
- Error handling and progress logging
- Optional configuration for FlowLauncher

## Prerequisites

- Windows 10/11
- PowerShell 5.1+
- Administrator privileges

## Quick Start

1. **Clone the repository:**

   ```powershell
   git clone https://github.com/yourusername/dotfiles-windows.git
   cd dotfiles-windows
   ```

2. **Run the installer:**

   ```powershell
   .\installers\windows-installer.ps1
   ```

   For debug logging:

   ```powershell
   .\installers\windows-installer.ps1 -LogLevel Debug
   ```

## What Gets Installed

The script installs (in order):

- Scoop (package manager)
- winget (Windows package manager)
- Git
- VSCode
- Cursor AI Editor
- Discord
- Google Chrome
- Notion
- Obsidian
- PowerToys
- FlowLauncher (with optional settings sync)
- ProtonVPN
- Google QuickShare
- Syncthing
- VLC Media Player
- Zalo
- PC Manager
- Pure Battery Add-on
- Windows Terminal
- **Microsoft Office** (manual install guide only)

## After Installation

- Use `scoop install <package>` or `winget install <package>` for more apps
- Run `git --version`, `code`, `cursor`, `discord`, `chrome`, etc. to verify installations
- Press `Alt+Space` for FlowLauncher
- See logs for any manual steps or errors

## Repository Structure

```
dotfiles-windows/
├── installers/
│   └── windows-installer.ps1  # Main installation script
└── README.md                  # This file
```

## License

MIT License. See [LICENSE](LICENSE).

---

**Note:** Some apps (e.g., Microsoft Office) require manual installation. The script provides guidance where automation is not possible.

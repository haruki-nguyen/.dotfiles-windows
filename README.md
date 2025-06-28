# Haruki Nguyen Windows Dotfiles

A comprehensive Windows development environment setup with automated installation scripts for essential development tools and applications.

## 🚀 Features

This repository provides a streamlined way to set up a complete Windows development environment with:

- **Package Management**: Scoop for easy software installation
- **Development Tools**: Git for version control
- **Code Editors**: VSCode and Cursor AI Editor
- **Productivity**: Notion and Obsidian for note-taking
- **Communication**: Discord and Zalo for team collaboration
- **Web Browser**: Google Chrome for development and browsing
- **Media**: VLC Media Player for multimedia
- **Utilities**: PowerToys, Flowlauncher, and Syncthing
- **Security**: ProtonVPN for secure browsing
- **File Sharing**: Google QuickShare for easy file transfer

## 📋 Prerequisites

- Windows 10/11
- PowerShell 5.1 or higher
- Administrator privileges (required for installation)

## 🛠️ Installation

### Quick Start

1. **Clone the repository**:

   ```powershell
   git clone https://github.com/yourusername/dotfiles-windows.git
   cd dotfiles-windows
   ```

2. **Run the installer**:

   ```powershell
   .\installers\windows-installer.ps1
   ```

### Advanced Usage

Run with debug logging for detailed output:

```powershell
.\installers\windows-installer.ps1 -LogLevel Debug
```

## 📦 What Gets Installed

The installer will set up the following tools in order:

1. **Scoop** - Package manager for Windows
2. **Git** - Version control system
3. **VSCode** - Popular code editor
4. **Cursor AI Editor** - AI-powered code editor
5. **Discord** - Communication platform
6. **Google Chrome** - Web browser
7. **Notion** - Productivity and note-taking
8. **Obsidian** - Knowledge management
9. **PowerToys** - Windows utilities
10. **Flowlauncher** - Application launcher
11. **ProtonVPN** - VPN service
12. **Google QuickShare** - File sharing
13. **Syncthing** - File synchronization
14. **VLC** - Media player
15. **Zalo** - Vietnamese messaging app
16. **Microsoft Office** - Manual installation guide

## 🎯 After Installation

Once the installation is complete, you can:

- Use `scoop install <package>` to install additional packages
- Run `git --version` to verify Git installation
- Launch VSCode with `code` command
- Launch Cursor AI Editor with `cursor` command
- Launch Discord with `discord` command
- Launch Google Chrome with `chrome` command
- Launch Notion with `notion` command
- Launch Obsidian with `obsidian` command
- Launch PowerToys with `powertoys` command
- Press `Alt+Space` to launch Flowlauncher
- Launch ProtonVPN with `protonvpn` command
- Look for QuickShare in system tray
- Launch Syncthing with `syncthing` command
- Launch VLC with `vlc` command
- Find Zalo in Start menu
- Install Microsoft Office manually using the provided guide

## 🔧 Script Features

- **Idempotent**: Won't reinstall already installed tools
- **Error Handling**: Comprehensive error handling and logging
- **Progress Tracking**: Step-by-step progress with success/failure indicators
- **Logging Levels**: Configurable logging (Debug, Info, Warning, Error)
- **Smart Bucket Management**: Automatic Scoop bucket management
- **Mixed Installation Methods**: Combines Scoop packages and direct downloads
- **Automatic Cleanup**: Removes temporary installers after installation

## 📁 Repository Structure

```txt
dotfiles-windows/
├── installers/
│   └── windows-installer.ps1    # Main installation script
└── README.md                    # This file
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test the installation script
5. Submit a pull request

## 📝 License

This project is open source and available under the [MIT License](LICENSE).

## 🙏 Acknowledgments

- [Scoop](https://scoop.sh/) - Package manager for Windows
- [VSCode](https://code.visualstudio.com/) - Code editor
- [Cursor](https://cursor.sh/) - AI-powered editor
- [Discord](https://discord.com/) - Communication platform
- [Zalo](https://zalo.me/) - Vietnamese messaging platform
- [VLC](https://www.videolan.org/) - Media player
- [Syncthing](https://syncthing.net/) - File synchronization

---

**Note**: This installer requires administrator privileges to set execution policies and install system-wide applications.

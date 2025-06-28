# Haruki Nguyen Windows Dotfiles

A comprehensive Windows development environment setup with automated installation scripts for essential development tools and applications.

## 🚀 Features

This repository provides a streamlined way to set up a complete Windows development environment with:

- **Package Management**: Scoop for easy software installation
- **Development Tools**: Git for version control
- **Code Editors**: VSCode and Cursor AI Editor
- **Communication**: Discord for team collaboration
- **Web Browser**: Google Chrome for development and browsing

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

## 🎯 After Installation

Once the installation is complete, you can:

- Use `scoop install <package>` to install additional packages
- Run `git --version` to verify Git installation
- Launch VSCode with `code` command
- Launch Cursor AI Editor with `cursor` command
- Launch Discord with `discord` command
- Launch Google Chrome with `chrome` command
- Run `scoop help` to see available commands

## 🔧 Script Features

- **Idempotent**: Won't reinstall already installed tools
- **Error Handling**: Comprehensive error handling and logging
- **Progress Tracking**: Step-by-step progress with success/failure indicators
- **Logging Levels**: Configurable logging (Debug, Info, Warning, Error)
- **Bucket Management**: Smart Scoop bucket management for extras

## 📁 Repository Structure

```
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

---

**Note**: This installer requires administrator privileges to set execution policies and install system-wide applications.

# Windows Development Environment – Simplified Setup

## 1. Purpose

This repository stores your Windows dotfiles and configuration. Instead of running a full installer, you will:

* install required tools manually
* set up your environment step-by-step
* create clean, reliable automation scripts later

---

## 2. Quick Start

### Clone the repository with submodules

```bash
git clone --recursive <repo-url>
```

### Prepare PowerShell

```ps1
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

## 3. Manual Setup Steps

These are the essential tools to install manually.

### 3.1 Install Scoop (recommended)

```ps1
iwr -useb get.scoop.sh | iex
scoop bucket add main
scoop bucket add extras
scoop bucket add nonportable
```

### 3.2 Install Required Apps via Scoop

Put [SyncthingHidden.vbs](scripts\SyncthingHideen.vbs) inside `shell:startup` to make Syncthing start on startup without opening a window of terminal.

```ps1
scoop install git
scoop install extras/vscode
scoop install extras/googlechrome
scoop install extras/obsidian
scoop install extras/powertoys
scoop install extras/flow-launcher
scoop install nonportable/protonvpn-np
scoop install syncthing
scoop install extras/everything
scoop install extras/keepassxc
scoop install python
scoop install nodejs
```

### 3.3 Install Apps via Winget

```ps1
winget install Microsoft.WindowsTerminal -e --accept-source-agreements --accept-package-agreements
winget install 9N3HDTNCF6Z8 -e --accept-source-agreements --accept-package-agreements
```

### 3.4 Optional NPM Tools

```ps1
npm install -g @google/gemini-cli
```

### 3.5 WSL Setup (optional)

```ps1
wsl --install -d Ubuntu-22.04
```

---

## 4. GitHub SSH Setup (manual)

```ps1
mkdir "$env:USERPROFILE/.ssh" -Force
ssh-keygen -t ed25519 -C "<your email>" -f "$env:USERPROFILE/.ssh/id_ed25519"
```

Add the public key to GitHub, then verify:

```ps1
ssh -T git@github.com
```

---

## 5. Link Dotfiles Manually

Example:

```ps1
# This command requires Administrator
New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE/.gitconfig" -Target "$env:USERPROFILE/.dotfiles-windows/.gitconfig" -Force
```

Repeat for any additional config files.

---

## 6. Manual Post-Install Apps

Install these from the Microsoft Store or their websites:

* Office softwares
* Wise Memory Optimizer
* VLC
* Google Drive Desktop
* Discord
* Zalo
* 1.1.1.1 (Cloudflare WARP)
* Google Quick Share
* John’s Background Switcher
* Wintoys
* O&O ShutUp10++
* DaVinci Resolve
* Iriun Webcam
* SoundWire Server

### Game Development Tools

* Unity
* .NET SDK
* Claude Desktop (for MCP)

### Unikey Setup

Copy Unikey to a folder, then add to Startup:

```txt
Win + R → shell:startup
```

---

## 7. Updating Your System Manually

### Update Scoop

```ps1
scoop update
scoop update *
```

### Update Winget

```ps1
winget upgrade --all --accept-source-agreements --accept-package-agreements
```

### Cleanup (manual)

* Clear Recycle Bin
* Clear Temp folder (`%temp%`)
* Scoop cleanup:

```ps1
scoop cache rm *
```

---

## 8. Git Submodules

```bash
git submodule update --remote
```

---

## 9. Repo Layout

```txt
.dotfiles-windows/
├── .config/           # Configs
├── installers/        # (OLD / NOT USED)
├── scripts/           # For future automation
├── shared-dotfiles/   # Submodule
├── .gitconfig
└── README.md
```

---

## 10. Future Automation (recommended)

After your environment is stable, create simple scripts to automate:

* installing Scoop + buckets
* installing core apps
* linking dotfiles
* WSL setup
* updates & cleanup

Keep each script small and testable (no monolithic installer).

---

## 11. License

MIT

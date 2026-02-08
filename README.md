# Windows Development Environment – Simplified Setup

## 1. Purpose

This repository stores my Windows dotfiles and configuration.

- Install required tools manually
- Set up my environment step-by-step
- Create clean, reliable automation scripts later

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
scoop install gcc
```

### 3.3 Install Apps via Winget

```ps1
winget install Microsoft.WindowsTerminal -e --accept-source-agreements --accept-package-agreements
```

### 3.4 WSL Setup (optional)

```ps1
wsl --install -d Ubuntu-22.04
```

### 3.6 JetBrains Mono Font Setup for VSCode

<https://www.jetbrains.com/lp/mono/>

---

## 4. GitHub SSH Setup (manual)

```ps1
mkdir "$env:USERPROFILE/.ssh" -Force
ssh-keygen -t ed25519 -C "<my email>" -f "$env:USERPROFILE/.ssh/id_ed25519"
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

- MS Edge
- Office softwares
- Dropbox
- Discord
- Zalo
- 1.1.1.1 (Cloudflare WARP)
- Google Quick Share
- Wintoys
- O&O ShutUp10++
- Shotcut/Kdenlive
- GIMP
- Iriun Webcam
- SoundWire Server
- Spotify
- [Dropshelf](https://apps.microsoft.com/detail/9MZPC6P14L7N?hl=en-us&gl=VN&ocid=pdpshare)

### Unikey Setup

Copy Unikey to a folder, then add to Startup:

```txt
Win + R → shell:startup
```

---

## 7. Updating my System Manually

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

- Clear Recycle Bin
- Clear Temp folder (`%temp%`)
- Scoop cleanup:

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
├── scripts/           # For automation
├── shared-dotfiles/   # Submodule
├── .gitconfig
└── README.md
```

---

## 11. License

MIT

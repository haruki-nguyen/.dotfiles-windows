# 💻 Windows Development Environment

A curated collection of dotfiles, scripts, and configurations to transform Windows into a high-control, privacy-focused development environment.

---

## 1. Prerequisites & Foundation

Before doing anything else, set the execution policy to allow scripts and clone this repository.

### 🔌 Prepare PowerShell

Open PowerShell as Administrator:

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

```

### 📥 Clone Repository

```bash
git clone --recursive <repo-url>
cd .dotfiles-windows

```

---

## 2. System Optimization (WinUtil)

I use [Chris Titus’s Windows Utility](https://christitus.com/windows-tool/) to "tame" the OS before installing apps. This handles privacy tweaks and system bloat.

1. Run the utility: `irm christitus.com/win | iex`
2. **Tweaks Tab:** Apply recommended desktop/laptop tweaks.
3. **Config Tab:** Disable Bing Search, Telemetry, and Recommendations.
4. **Install Tab:** Use this to install core "heavy" apps:

* LibreOffice, VLC, Discord (Vesktop), PowerShell 7, Windows Terminal.

---

## 3. Package Management (Scoop)

I prefer **Scoop** for developer tools because it installs apps into your user directory and keeps the system PATH clean.

### 3.1 Install Scoop & Buckets

```powershell
iwr -useb get.scoop.sh | iex
scoop bucket add main
scoop bucket add extras
scoop bucket add nonportable

```

### 3.2 Install Core Toolset

```powershell
# Development & Editor
scoop install git nodejs pnpm jetbrains-mono-nerd-font

# Productivity & Utilities
scoop install extras/vscode extras/obsidian extras/powertoys extras/flow-launcher wezterm
scoop install extras/everything extras/keepassxc syncthing harmonoid hourglass

# Network & Privacy
scoop install nonportable/protonvpn-np

```

---

## 4. Environment Configuration

### 🔑 GitHub SSH Setup

```powershell
mkdir "$env:USERPROFILE/.ssh" -Force
ssh-keygen -t ed25519 -C "<your-email>" -f "$env:USERPROFILE/.ssh/id_ed25519"
# Add id_ed25519.pub to GitHub settings
ssh -T git@github.com

```

### 🐧 WSL Setup (Optional)

```powershell
wsl --install -d Ubuntu-22.04

```

### 🔗 Linking Dotfiles (The "Dot" Part)

Link your configurations from the repo to your user profile.

```powershell
# Example: Git Config (Run as Admin)
New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE/.gitconfig" -Target "$env:USERPROFILE/.dotfiles-windows/.gitconfig" -Force

New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE/.wezterm.lua" -Target "$env:USERPROFILE/.dotfiles-windows/.config/WezTerm/.wezterm.lua" -Force

```

---

## 5. Manual & GUI Apps

Some apps are better managed via the Microsoft Store or standalone installers:

* **Communication:** Zalo, WhatsApp.
* **Networking:** 1.1.1.1 (Cloudflare WARP)
* **File Sync:** Google Drive, Google Quick Share
* **System Tools:** Wintoys, VeraCrypt
* **Hardware:** Iriun Webcam, SoundWire Server

### ⌨️ Unikey & Startup Tricks

* **Unikey:** Copy the folder to your preferred location. Press `Win + R` → type `shell:startup` → Paste a shortcut to Unikey here.
* **Syncthing:** To run silently, copy `scripts\SyncthingHidden.vbs` to `shell:startup`.

---

## 6. Maintenance & Updates

Keep the environment fresh with these commands:

### Update Packages

```powershell
# Scoop
scoop update *

# Winget (for apps installed via WinUtil/Store)
winget upgrade --all --accept-source-agreements

```

### Cleanup

```powershell
# Remove old Scoop versions/cache
scoop cleanup *
scoop cache rm *

# Update Submodules
git submodule update --remote

```

---

## 📁 Repository Layout

```text
.dotfiles-windows/
├── .config/           # Application-specific configs (VSCode, etc.)
├── scripts/           # VBS and automation scripts
├── shared-dotfiles/   # Cross-platform submodule
├── .gitconfig         # Global git settings
└── README.md

```

## License

MIT

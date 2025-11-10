# Haruki Nguyen's Windows Dotfiles

Scripts and dotfiles to bootstrap and maintain a Windows development environment.

## Quick Start

1. Clone with submodules:  

   ```bash
   git clone --recursive <repo-url>
   ````

2. Open PowerShell in the repo folder.
3. Run the installer (admin only if prompted):

   ```ps1
   .\installers\windows-installer.ps1 -GitHubEmail "<you@example.com>"
   ```

## Installer: `installers/windows-installer.ps1`

* Installs and configures package managers (Scoop, winget).
* Installs development, productivity, and system apps.
* Sets up GitHub SSH key (if email provided).
* Creates symlinks for dotfiles.
* Skips already-installed items and logs actions/errors.

Optional parameters:

* `-GitHubEmail "<email>"` — setup SSH key
* `-LogLevel Debug|Info|Warning|Error` — default: Info

## Updater / Maintenance: `installers/windows-updater.ps1`

* Updates Scoop and winget packages.
* Cleans temp files, caches, and Recycle Bin.
* Optional deep cleanup with `-ForceCleanup`.

Usage examples:

```ps1
.\installers\windows-updater.ps1          # full update + cleanup
.\installers\windows-updater.ps1 -UpdateOnly
.\installers\windows-updater.ps1 -CleanupOnly
```

## Pre-Install Recommendations

* Open PowerShell as normal user.
* Optional: preinstall Git, Scoop, PowerShell 7+.
* Set execution policy:

  ```ps1
  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
  ```

## Manual Post-Install Tasks

* **Manual Installation After Scripts:**  
  * **Applications:**  
     MS Office, PC Manager, VLC, Google Drive Desktop, Discord, Zalo, 1.1.1.1, Google Quick Share  
     [John’s Background Switcher](https://johnsad.ventures/software/backgroundswitcher/), [Wintoys](https://apps.microsoft.com/detail/9P8LTPGCBZXD?hl=en-us&gl=VN&ocid=pdpshare), [O&O ShutUp10++](https://www.oo-software.com/en/shutup10), [Davinci Resolve](https://www.blackmagicdesign.com/products/davinciresolve)  
  * **Game development tools:**  
     Unity, .NET SDK (for Unity + VSCode), Claude Desktop (for MCP for Unity)  
  * **Unikey:**  
     Copy the executable to a `Programs` folder, then create a Startup shortcut (`Win + R`, run `shell:startup`)  

* **MCP for Unity setup:**  
   See [docs/MCP-Unity.md](./docs/MCP-Unity.md) for instructions.

## Installed Packages (automatic)

* **Dev tools:** VS Code, Python, Node.js
* **Productivity:** Chrome, Notion, Obsidian, Discord
* **System utils:** PowerToys, FlowLauncher, Everything, KeePassXC, Windows Terminal
* **Communication & media:** WhatsApp, ProtonVPN, VLC, Syncthing
* **Cloud:** Google QuickShare

Scripts log failures and guide manual installs.

## Git Submodules

* `shared-dotfiles` contains configs shared across platforms.
* Update submodules:

  ```bash
  git submodule update --remote
  ```

## Troubleshooting

* Execution policy blocked → `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser`
* Scoop errors → run installer as normal user
* winget missing → install “App Installer” or update Windows
* Manual install may be required for some packages

## Repo Layout

```txt
.dotfiles-windows/
├── .config/           # Tool configs
├── installers/        # Installer + updater
├── scripts/           # Utilities
├── shared-dotfiles/   # Submodule
├── .gitconfig
└── README.md
```

## Contributing

Fork → branch → edit → test → pull request.

## License

MIT

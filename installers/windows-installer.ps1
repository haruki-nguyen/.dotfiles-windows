#Requires -Version 5.1
param([string]$GitHubEmail)

$ErrorActionPreference = "Stop"

function Install-Scoop {
    if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
        Invoke-WebRequest -useb get.scoop.sh | Invoke-Expression
    }
    scoop update

    # Add buckets if not already present
    if (-not (scoop bucket list | Select-String '^main$')) { scoop bucket add main -ErrorAction SilentlyContinue }
    if (-not (scoop bucket list | Select-String '^extras$')) { scoop bucket add extras -ErrorAction SilentlyContinue }
    if (-not (scoop bucket list | Select-String '^nonportable$')) { scoop bucket add nonportable -ErrorAction SilentlyContinue }
}

function Install-Winget {
    param($Id)
    try {
        winget install --id=$Id -e --accept-source-agreements --accept-package-agreements
    }
    catch {
        Write-Warning "Failed to install $Id via winget"
    }
}

function Install-ScoopApp {
    param($Pkg)
    if (-not (scoop list | Select-String "^$($Pkg.Split('/')[-1])$")) {
        scoop install $Pkg
    }
    else {
        Write-Host "$Pkg already installed."
    }
}

Write-Host "=== Simple Windows Setup ==="

# --- Scoop setup
Install-Scoop

# --- Scoop apps
$scoopApps = @(
    "git", "extras/vscode",
    "extras/googlechrome", "extras/obsidian",
    "extras/powertoys", "extras/flow-launcher",
    "nonportable/protonvpn-np", "main/syncthing",
    "extras/everything", "extras/keepassxc",
    # MCP for Unity Setup
    "main/python", 
    # For some software development
    "main/nodejs"
)
foreach ($app in $scoopApps) { Install-ScoopApp $app }

# --- NPM apps
try { npm install -g @google/gemini-cli } catch { Write-Warning "Failed to install npm package" }

# --- Winget PATH fix
$env:Path += ";$env:LOCALAPPDATA\Microsoft\WindowsApps"

# --- Winget apps
$wingetApps = @(
    "Microsoft.WindowsTerminal",
    "9N3HDTNCF6Z8"   # Pure Battery Add-on
)
foreach ($id in $wingetApps) { Install-Winget $id }

# --- GitHub SSH setup
if (Get-Command git -ErrorAction SilentlyContinue) {
    $sshDir = "$env:USERPROFILE\.ssh"
    $keyPath = Join-Path $sshDir "id_ed25519"
    if (-not (Test-Path $keyPath)) {
        if (-not (Test-Path $sshDir)) { New-Item -ItemType Directory -Path $sshDir -Force | Out-Null }
        $email = if ($GitHubEmail) { $GitHubEmail } else { Read-Host "Enter your GitHub email" }
        ssh-keygen -t ed25519 -C $email -f $keyPath -N ""
        Write-Host "SSH key generated. Add it to GitHub. Then run `ssh -T git@github.com` to establish the connection."
    }
}

# --- Git config symlink
$homeGitConfig = Join-Path $env:USERPROFILE ".gitconfig"
$repoGitConfig = Join-Path $env:USERPROFILE ".dotfiles-windows\.gitconfig"

if (-not (Test-Path $homeGitConfig)) {
    try {
        New-Item -ItemType SymbolicLink -Path $homeGitConfig -Target $repoGitConfig -Force | Out-Null
        Write-Host "Created symlink for .gitconfig → .dotfiles-windows\.gitconfig"
    }
    catch {
        Write-Warning "Failed to create .gitconfig symlink"
    }
}

# --- WSL2 setup
try { wsl --install -d Ubuntu-22.04 } catch { Write-Warning "WSL2 installation failed or already installed" }

Write-Host "=== Setup Completed ==="
#Requires -Version 5.1
param([string]$GitHubEmail)

$ErrorActionPreference = "Stop"

function Install-Scoop {
    if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
        iwr -useb get.scoop.sh | iex
    }
    scoop update
    scoop bucket add main    -ErrorAction SilentlyContinue
    scoop bucket add extras  -ErrorAction SilentlyContinue
    scoop bucket add nonportable -ErrorAction SilentlyContinue
}

function Install-Winget {
    param($Id)
    winget install --id=$Id -e --accept-source-agreements --accept-package-agreements
}

function Install-ScoopApp {
    param($Pkg)
    scoop install $Pkg
}

Write-Host "=== Simple Windows Setup ==="

# --- Scoop setup
Install-Scoop

# --- Scoop apps
$scoopApps = @(
    "git", "extras/vscode",
    "extras/googlechrome", "extras/obsidian",
    "extras/powertoys", "extras/flow-launcher",
    "nonportable/protonvpn-np",
    "extras/everything", "extras/keepassxc"
)
foreach ($app in $scoopApps) { Install-ScoopApp $app }

# --- Winget PATH fix
$env:Path += ";$env:LOCALAPPDATA\Microsoft\WindowsApps"

# --- Winget apps
$wingetApps = @(
    "Microsoft.WindowsTerminal",
    "9N3HDTNCF6Z8",   # Pure Battery Add-on
    "Google.Drive"
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
        Write-Host "SSH key generated. Add it to GitHub."
    }
}

Write-Host "=== Setup Completed ==="

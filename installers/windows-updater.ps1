#Requires -Version 5.1
#Requires -RunAsAdministrator

param(
    [switch]$UpdateOnly,
    [switch]$CleanupOnly
)

$ErrorActionPreference = "Stop"

function Update-Scoop {
    if (Get-Command scoop -ErrorAction SilentlyContinue) {
        Write-Host "Updating Scoop apps..."
        scoop update
        scoop update *
        scoop cleanup *
    }
    else {
        Write-Host "Scoop not installed, skipping."
    }
}

# --- Winget PATH fix
$env:Path += ";$env:LOCALAPPDATA\Microsoft\WindowsApps"

function Update-Winget {
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Host "Updating only Winget apps installed by the installer..."
        $wingetApps = @(
            "Microsoft.WindowsTerminal",
            "9N3HDTNCF6Z8"   # Pure Battery Add-on
        )
        foreach ($id in $wingetApps) {
            Write-Host "Upgrading $id via winget..."
            winget upgrade --id=$id --accept-source-agreements --accept-package-agreements
        }
    }
    else {
        Write-Host "Winget not found, skipping."
    }
}

function Cleanup-System {
    Write-Host "Cleaning system temp files..."
    $temp = @($env:TEMP, $env:TMP, "$env:LOCALAPPDATA\Temp")
    foreach ($p in $temp) {
        if (Test-Path $p) { Remove-Item "$p\*" -Recurse -Force -ErrorAction SilentlyContinue }
    }
    try { Clear-RecycleBin -Force -ErrorAction SilentlyContinue } catch {}
}

# Check for .gitconfig in home directory and create symlink if missing
$homeGitConfig = Join-Path $env:USERPROFILE ".gitconfig"
$repoGitConfig = "C:\Users\nmdex\.dotfiles-windows\.gitconfig"
if (-not (Test-Path $homeGitConfig)) {
    Write-Host "Creating symbolic link for .gitconfig in home directory..."
    New-Item -ItemType SymbolicLink -Path $homeGitConfig -Target $repoGitConfig -Force | Out-Null
}

Write-Host "=== Updater Started ==="

if (-not $CleanupOnly) { Update-Scoop; Update-Winget }
if (-not $UpdateOnly) { Cleanup-System }

Write-Host "=== Updater Completed ==="

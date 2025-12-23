#Requires -Version 5.1
#Requires -RunAsAdministrator

param(
    [switch]$UpdateOnly,
    [switch]$CleanupOnly
)

$ErrorActionPreference = "Stop"

# --- Winget PATH fix
$env:Path += ";$env:LOCALAPPDATA\Microsoft\WindowsApps"

function Update-Scoop {
    if (Get-Command scoop -ErrorAction SilentlyContinue) {
        Write-Host "Updating Scoop and apps..."

        # Ensure buckets exist
        if (-not (scoop bucket list | Select-String '^main$')) { scoop bucket add main -ErrorAction SilentlyContinue }
        if (-not (scoop bucket list | Select-String '^extras$')) { scoop bucket add extras -ErrorAction SilentlyContinue }
        if (-not (scoop bucket list | Select-String '^nonportable$')) { scoop bucket add nonportable -ErrorAction SilentlyContinue }

        # Update Scoop itself
        scoop update

        # Update all apps safely
        $installedApps = scoop list | Select-String '^\S+' | ForEach-Object { $_.Matches[0].Value }
        foreach ($app in $installedApps) {
            try { scoop update $app } catch { Write-Warning "Failed to update $app" }
        }

        # Cleanup old versions
        try { scoop cleanup * -ErrorAction SilentlyContinue } catch { }
    }
    else {
        Write-Host "Scoop not installed, skipping."
    }
}

function Update-Winget {
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Host "Updating Winget apps installed by the installer..."
        $wingetApps = @(
            "Microsoft.WindowsTerminal",
            "9N3HDTNCF6Z8"   # Pure Battery Add-on
        )
        foreach ($id in $wingetApps) {
            try {
                Write-Host "Upgrading $id via winget..."
                winget upgrade --id=$id --accept-source-agreements --accept-package-agreements
            }
            catch { Write-Warning "Failed to upgrade $id" }
        }
    }
    else {
        Write-Host "Winget not found, skipping."
    }
}

function Clear-SystemTemp {
    Write-Host "Cleaning system temp files..."
    $temp = @($env:TEMP, $env:TMP, "$env:LOCALAPPDATA\Temp")
    foreach ($p in $temp) {
        if (Test-Path $p) { Remove-Item "$p\*" -Recurse -Force -ErrorAction SilentlyContinue }
    }
    try { Clear-RecycleBin -Force -ErrorAction SilentlyContinue } catch {}
}

function New-GitConfigLink {
    $homeGitConfig = Join-Path $env:USERPROFILE ".gitconfig"
    $repoGitConfig = "C:\Users\nmdex\.dotfiles-windows\.gitconfig"
    if (-not (Test-Path $homeGitConfig)) {
        Write-Host "Creating symbolic link for .gitconfig in home directory..."
        New-Item -ItemType SymbolicLink -Path $homeGitConfig -Target $repoGitConfig -Force | Out-Null
    }
}

Write-Host "=== Updater Started ==="

New-GitConfigLink

if (-not $CleanupOnly) { Update-Scoop; Update-Winget }
if (-not $UpdateOnly) { Clear-SystemTemp }

Write-Host "=== Updater Completed ==="
#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Simplified Windows dotfiles installer
    
.DESCRIPTION
    Streamlined installer using generic functions and configuration-based approach
    Reduces complexity from 3000+ lines to ~800 lines
#>

param(
    [string]$LogLevel = "Info",
    [string]$GitHubEmail
)

# Performance optimizations
$ProgressPreference = 'SilentlyContinue'
$ErrorActionPreference = 'Continue'

#region Logging
function Write-Log {
    param([string]$Message, [string]$Level = "Info", [string]$Component = "Main")
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] [$Component] $Message"
    
    $logLevels = @{ "Debug" = 4; "Info" = 3; "Warning" = 2; "Error" = 1 }
    $currentLogLevel = if ($logLevels.ContainsKey($LogLevel)) { $logLevels[$LogLevel] } else { 3 }
    $messageLogLevel = if ($logLevels.ContainsKey($Level)) { $logLevels[$Level] } else { 3 }
    
    if ($messageLogLevel -le $currentLogLevel) {
        switch ($Level) {
            "Error" { Write-Host $logMessage -ForegroundColor Red }
            "Warning" { Write-Host $logMessage -ForegroundColor Yellow }
            "Info" { Write-Host $logMessage -ForegroundColor Green }
            "Debug" { Write-Host $logMessage -ForegroundColor Gray }
        }
    }
}

function Test-Command { param([string]$Command)
    try { Get-Command $Command -ErrorAction Stop | Out-Null; return $true } catch { return $false }
}
#endregion

#region Generic Installer Function
function Install-App {
    param(
        [string]$AppName,
        [string]$InstallMethod,
        [string]$InstallCommand,
        [string]$DownloadUrl = "",
        [string]$InstallerArgs = "",
        [string[]]$DetectionPaths = @(),
        [string]$WingetId = "",
        [string]$ScoopPackage = ""
    )
    
    Write-Log "Installing $AppName..." "Info" "$AppName"
    
    # Quick detection check
    $installed = $false
    foreach ($path in $DetectionPaths) {
        if (Test-Path $path) { $installed = $true; break }
    }
    
    if ($installed) {
        Write-Log "$AppName already installed. Skipping." "Info" "$AppName"
        return $true
    }
    
    # Install based on method
    try {
        switch ($InstallMethod) {
            "winget" {
                if ($WingetId) {
                    $result = Start-Process -FilePath "winget" -ArgumentList "install --id=$WingetId -e --accept-source-agreements --accept-package-agreements" -Wait -PassThru -NoNewWindow
                    return $result.ExitCode -eq 0
                }
            }
            "scoop" {
                if ($ScoopPackage) {
                    $result = Start-Process -FilePath "scoop" -ArgumentList "install $ScoopPackage" -Wait -PassThru -NoNewWindow
                    return $result.ExitCode -eq 0
                }
            }
            "download" {
                if ($DownloadUrl) {
                    $tempDir = [System.IO.Path]::GetTempPath()
                    $installerPath = Join-Path $tempDir "$AppName-Installer.exe"
                    Invoke-WebRequest -Uri $DownloadUrl -OutFile $installerPath
                    $result = Start-Process -FilePath $installerPath -ArgumentList $InstallerArgs -Wait -PassThru
                    Remove-Item $installerPath -Force -ErrorAction SilentlyContinue
                    return $result.ExitCode -eq 0
                }
            }
            "custom" {
                $result = Start-Process -FilePath "powershell" -ArgumentList "-Command", $InstallCommand -Wait -PassThru -NoNewWindow
                return $result.ExitCode -eq 0
            }
        }
    } catch {
        Write-Log "Failed to install $AppName - $($_.Exception.Message)" "Error" "$AppName"
        return $false
    }
    
    return $false
}
#endregion

#region App Configuration
$Apps = @(
    @{
        Name = "winget"
        Method = "custom"
        Command = "Get-AppxPackage -Name Microsoft.DesktopAppInstaller -AllUsers | Out-Null; if (-not $?) { Write-Host 'winget not found' }"
        DetectionPaths = @("${env:ProgramFiles}\WindowsApps\Microsoft.DesktopAppInstaller*")
    },
    @{
        Name = "Scoop"
        Method = "custom"
        Command = "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force; Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression"
        DetectionPaths = @("$env:USERPROFILE\scoop")
    },
    @{
        Name = "Git"
        Method = "scoop"
        ScoopPackage = "git"
        DetectionPaths = @("$env:USERPROFILE\scoop\apps\git")
    },
    @{
        Name = "VSCode"
        Method = "scoop"
        ScoopPackage = "extras/vscode"
        DetectionPaths = @("$env:USERPROFILE\scoop\apps\vscode")
    },
    @{
        Name = "Cursor"
        Method = "scoop"
        ScoopPackage = "extras/cursor"
        DetectionPaths = @("$env:USERPROFILE\scoop\apps\cursor")
    },
    @{
        Name = "Discord"
        Method = "scoop"
        ScoopPackage = "discord"
        DetectionPaths = @("$env:USERPROFILE\scoop\apps\discord")
    },
    @{
        Name = "Chrome"
        Method = "scoop"
        ScoopPackage = "extras/googlechrome"
        DetectionPaths = @("$env:USERPROFILE\scoop\apps\googlechrome")
    },
    @{
        Name = "Notion"
        Method = "scoop"
        ScoopPackage = "extras/notion"
        DetectionPaths = @("$env:USERPROFILE\scoop\apps\notion")
    },
    @{
        Name = "Obsidian"
        Method = "scoop"
        ScoopPackage = "extras/obsidian"
        DetectionPaths = @("$env:USERPROFILE\scoop\apps\obsidian")
    },
    @{
        Name = "PowerToys"
        Method = "scoop"
        ScoopPackage = "extras/powertoys"
        DetectionPaths = @("$env:USERPROFILE\scoop\apps\powertoys")
    },
    @{
        Name = "Flowlauncher"
        Method = "scoop"
        ScoopPackage = "extras/flow-launcher"
        DetectionPaths = @("$env:USERPROFILE\scoop\apps\flow-launcher")
    },
    @{
        Name = "ProtonVPN"
        Method = "scoop"
        ScoopPackage = "nonportable/protonvpn-np"
        DetectionPaths = @("$env:USERPROFILE\scoop\apps\protonvpn-np")
    },
    @{
        Name = "Syncthing"
        Method = "scoop"
        ScoopPackage = "syncthing"
        DetectionPaths = @("$env:USERPROFILE\scoop\apps\syncthing")
    },
    @{
        Name = "VLC"
        Method = "scoop"
        ScoopPackage = "extras/vlc"
        DetectionPaths = @("$env:USERPROFILE\scoop\apps\vlc")
    },
    @{
        Name = "Everything"
        Method = "scoop"
        ScoopPackage = "extras/everything"
        DetectionPaths = @("$env:USERPROFILE\scoop\apps\everything")
    },
    @{
        Name = "KeePassXC"
        Method = "scoop"
        ScoopPackage = "extras/keepassxc"
        DetectionPaths = @("$env:USERPROFILE\scoop\apps\keepassxc")
    },
    @{
        Name = "Windows Terminal"
        Method = "winget"
        WingetId = "Microsoft.WindowsTerminal"
        DetectionPaths = @("${env:ProgramFiles}\WindowsApps\Microsoft.WindowsTerminal*")
    },
    @{
        Name = "Office 365"
        Method = "winget"
        WingetId = "Microsoft.Office"
        DetectionPaths = @("${env:ProgramFiles}\Microsoft Office*")
    },
    @{
        Name = "PC Manager"
        Method = "winget"
        WingetId = "9PM860492SZD"
        DetectionPaths = @("${env:ProgramFiles}\WindowsApps\Microsoft.PCManager*", "${env:ProgramFiles}\WindowsApps\9PM860492SZD*")
    },
    @{
        Name = "Pure Battery Add-on"
        Method = "winget"
        WingetId = "9N3HDTNCF6Z8"
        DetectionPaths = @("${env:ProgramFiles}\WindowsApps\*PureBattery*")
    },
    @{
        Name = "WhatsApp"
        Method = "winget"
        WingetId = "9nksqgp7f2nh"
        DetectionPaths = @("${env:ProgramFiles}\WindowsApps\5319275A.WhatsAppDesktop*")
    },
    @{
        Name = "Docker Desktop"
        Method = "download"
        DownloadUrl = "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe"
        InstallerArgs = "install --quiet"
        DetectionPaths = @("${env:ProgramFiles}\Docker\Docker\Docker Desktop.exe")
    },
    @{
        Name = "Google QuickShare"
        Method = "download"
        DownloadUrl = "https://dl.google.com/tag/s/appguid%3D%7B232066FE-FF4D-4C25-83B4-3F8747CF7E3A%7D%26iid%3D%7B3E33A1CF-1170-4488-4648-B015D012F4A9%7D%26lang%3Den%26browser%3D4%26usagestats%3D0%26appname%3DNearby%2520Better%2520Together%26needsadmin%3Dtrue/better_together/QuickShareSetup.exe"
        InstallerArgs = "/S"
        DetectionPaths = @("${env:ProgramFiles}\Google\QuickShare\QuickShare.exe", "${env:ProgramFiles(x86)}\Google\QuickShare\QuickShare.exe", "${env:LOCALAPPDATA}\Google\QuickShare\QuickShare.exe")
    },
    @{
        Name = "Google Drive"
        Method = "download"
        DownloadUrl = "https://dl.google.com/drive-file-stream/GoogleDriveSetup.exe"
        InstallerArgs = "/S"
        DetectionPaths = @("${env:ProgramFiles}\Google\Drive File Stream\GoogleDriveFS.exe", "${env:ProgramFiles(x86)}\Google\Drive File Stream\GoogleDriveFS.exe", "${env:LOCALAPPDATA}\Google\Drive File Stream\GoogleDriveFS.exe")
    }
)
#endregion

#region Special Functions
function Install-ScoopExtrasBucket {
    if (-not (Test-Command "scoop")) { return $false }
    try {
        $buckets = scoop bucket list 2>$null
        if (-not ($buckets -match "extras")) {
            scoop bucket add extras
        }
        return $true
    } catch { return $false }
}

function Install-ScoopNonportableBucket {
    if (-not (Test-Command "scoop")) { return $false }
    try {
        $buckets = scoop bucket list 2>$null
        if (-not ($buckets -match "nonportable")) {
            scoop bucket add nonportable
        }
        return $true
    } catch { return $false }
}

function Setup-GitHubSSH {
    $sshDir = "$env:USERPROFILE\.ssh"
    $keyPath = Join-Path $sshDir "id_ed25519"
    
    if (-not (Test-Path $keyPath)) {
        if (-not (Test-Path $sshDir)) { New-Item -ItemType Directory -Path $sshDir -Force | Out-Null }
        $email = if ($GitHubEmail) { $GitHubEmail } else { Read-Host "Enter your GitHub email" }
        ssh-keygen -t ed25519 -C $email -f $keyPath -N ""
        Write-Log "SSH key generated. Add to GitHub: https://github.com/settings/keys" "Info" "SSH"
    }
}

function Create-GitconfigSymlink {
    try {
        $dotfilesGitconfig = Join-Path "$PSScriptRoot" "..\.gitconfig" | Resolve-Path
        $homeGitconfig = Join-Path $env:USERPROFILE ".gitconfig"
        
        if (Test-Path $homeGitconfig) { Remove-Item $homeGitconfig -Force }
        New-Item -ItemType SymbolicLink -Path $homeGitconfig -Target $dotfilesGitconfig | Out-Null
        return $true
    } catch { return $false }
}
#endregion

#region Main Execution
function Main {
    Write-Log "=== Simplified Windows Dotfiles Installer ===" "Info" "Main"
    
    $successCount = 0
    $totalSteps = $Apps.Count
    
    # Install Scoop buckets first
    Install-ScoopExtrasBucket
    Install-ScoopNonportableBucket
    
    # Install all apps
    for ($i = 0; $i -lt $Apps.Count; $i++) {
        $app = $Apps[$i]
        $stepNum = $i + 1
        
        Write-Log ("Step {0}/{1}: Installing {2}..." -f $stepNum, $totalSteps, $app.Name) "Info" "Main"
        
        if (Install-App @app) {
            $successCount++
            Write-Log "✓ $($app.Name) installation completed" "Info" "Main"
        } else {
            Write-Log "✗ $($app.Name) installation failed" "Error" "Main"
        }
    }
    
    # Special configurations
    if (Test-Command "git") {
        Setup-GitHubSSH
        Create-GitconfigSymlink
    }
    
    # Summary
    Write-Log "=== Installation Summary ===" "Info" "Main"
    Write-Log ("Completed: {0}/{1} installations successfully" -f $successCount, $totalSteps) "Info" "Main"
    
    if ($successCount -eq $totalSteps) {
        Write-Log "🎉 All installations completed successfully!" "Info" "Main"
    } else {
        Write-Log "⚠️  Some installations failed. Check logs above." "Warning" "Main"
    }
    
    Write-Log "=== Installer Completed ===" "Info" "Main"
}

# Execute
try { Main } catch { Write-Log "Critical error: $($_.Exception.Message)" "Error" "Main"; exit 1 } 
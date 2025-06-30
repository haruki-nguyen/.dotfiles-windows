#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Windows dotfiles installer with Scoop package manager setup
    
.DESCRIPTION
    This script installs and configures Scoop package manager for Windows,
    along with VSCode and Cursor AI editor.
    
.PARAMETER LogLevel
    Logging level: Debug, Info, Warning, Error. Default: Info
    
.EXAMPLE
    .\windows-installer.ps1 -LogLevel Debug
#>

param(
    [ValidateSet("Debug", "Info", "Warning", "Error")]
    [string]$LogLevel = "Info"
)

#region Logging Functions
function Write-Log {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Debug", "Info", "Warning", "Error")]
        [string]$Level = "Info",
        
        [Parameter(Mandatory = $false)]
        [string]$Component = "Main"
    )
    
    # Handle empty or null messages
    if ([string]::IsNullOrEmpty($Message)) {
        $Message = " "
    }
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] [$Component] $Message"
    
    # Define log levels (higher number = more verbose)
    $logLevels = @{
        "Debug" = 4
        "Info" = 3
        "Warning" = 2
        "Error" = 1
    }
    
    $currentLogLevel = $logLevels[$LogLevel]
    $messageLogLevel = $logLevels[$Level]
    
    if ($messageLogLevel -le $currentLogLevel) {
        switch ($Level) {
            "Error" { Write-Host $logMessage -ForegroundColor Red }
            "Warning" { Write-Host $logMessage -ForegroundColor Yellow }
            "Info" { Write-Host $logMessage -ForegroundColor Green }
            "Debug" { Write-Host $logMessage -ForegroundColor Gray }
        }
    }
}

function Test-Command {
    param([string]$Command)
    try {
        Get-Command $Command -ErrorAction Stop | Out-Null
        return $true
    } catch {
        return $false
    }
}
#endregion

#region Scoop Installation
function Install-Scoop {
    Write-Log "Starting Scoop installation..." "Info" "Scoop"
    
    try {
        # Check if Scoop is already installed
        if (Test-Command "scoop") {
            Write-Log "Scoop is already installed. Skipping installation." "Info" "Scoop"
            return $true
        }
        
        # Set execution policy
        Write-Log "Setting execution policy to RemoteSigned for current user..." "Debug" "Scoop"
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force -ErrorAction Stop
        
        # Install Scoop
        Write-Log "Downloading and installing Scoop..." "Info" "Scoop"
        Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression -ErrorAction Stop
        
        if (Test-Command "scoop") {
            Write-Log "Scoop installed successfully!" "Info" "Scoop"
            return $true
        } else {
            Write-Log "Scoop installation failed - command not found after installation" "Error" "Scoop"
            return $false
        }
    } catch {
        Write-Log "Failed to install Scoop: $($_.Exception.Message)" "Error" "Scoop"
        return $false
    }
}
#endregion

#region Scoop Bucket Management
function Add-ScoopExtrasBucket {
    Write-Log "Checking and adding extras bucket to Scoop..." "Debug" "ScoopBuckets"
    
    try {
        # Check if extras bucket is already added
        $buckets = scoop bucket list 2>$null
        if ($buckets -match "extras") {
            Write-Log "Extras bucket is already added. Skipping..." "Debug" "ScoopBuckets"
            return $true
        }
        
        # Add extras bucket
        Write-Log "Adding extras bucket to Scoop..." "Info" "ScoopBuckets"
        scoop bucket add extras
        
        # Verify bucket was added
        $buckets = scoop bucket list 2>$null
        if ($buckets -match "extras") {
            Write-Log "Extras bucket added successfully!" "Info" "ScoopBuckets"
            return $true
        } else {
            Write-Log "Failed to add extras bucket" "Error" "ScoopBuckets"
            return $false
        }
    } catch {
        Write-Log "Failed to add extras bucket: $($_.Exception.Message)" "Error" "ScoopBuckets"
        return $false
    }
}
#endregion

#region winget Installation and Setup
function Install-Winget {
    Write-Log "Starting winget (Windows Package Manager) installation..." "Info" "Winget"
    
    try {
        # Check if winget is already installed and accessible
        if (Test-Command "winget") {
            Write-Log "winget is already installed and accessible. Checking version..." "Info" "Winget"
            try {
                $wingetVersion = winget --version 2>$null
                Write-Log "winget version: $wingetVersion" "Debug" "Winget"
            } catch {
                Write-Log "Could not determine winget version" "Debug" "Winget"
            }
            return $true
        }
        
        # Check if winget is available in the system but not in PATH
        $wingetPaths = @(
            "${env:LOCALAPPDATA}\Microsoft\WinGet\winget.exe",
            "${env:ProgramFiles}\WindowsApps\Microsoft.DesktopAppInstaller_*\winget.exe",
            "${env:ProgramFiles(x86)}\WindowsApps\Microsoft.DesktopAppInstaller_*\winget.exe"
        )
        
        # Also check for wildcard patterns in WindowsApps
        $windowsAppsPaths = @(
            "${env:ProgramFiles}\WindowsApps\Microsoft.DesktopAppInstaller_*",
            "${env:ProgramFiles(x86)}\WindowsApps\Microsoft.DesktopAppInstaller_*"
        )
        
        foreach ($basePath in $windowsAppsPaths) {
            try {
                $desktopAppInstallerDirs = Get-ChildItem -Path $basePath -Directory -ErrorAction SilentlyContinue | Sort-Object Name -Descending
                foreach ($dir in $desktopAppInstallerDirs) {
                    $wingetPath = Join-Path $dir.FullName "winget.exe"
                    if (Test-Path $wingetPath) {
                        Write-Log "Found winget at: $wingetPath" "Debug" "Winget"
                        # Add to PATH temporarily for this session
                        $env:PATH += ";$(Split-Path $wingetPath -Parent)"
                        if (Test-Command "winget") {
                            Write-Log "winget is available but not in PATH. Added to PATH for this session." "Info" "Winget"
                            try {
                                $wingetVersion = winget --version 2>$null
                                Write-Log "winget version: $wingetVersion" "Debug" "Winget"
                            } catch {
                                Write-Log "Could not determine winget version" "Debug" "Winget"
                            }
                            return $true
                        }
                    }
                }
            } catch {
                # Continue with other checks
            }
        }
        
        # Check specific paths
        foreach ($path in $wingetPaths) {
            if (Test-Path $path) {
                Write-Log "Found winget at: $path" "Debug" "Winget"
                # Add to PATH temporarily for this session
                $env:PATH += ";$(Split-Path $path -Parent)"
                if (Test-Command "winget") {
                    Write-Log "winget is available but not in PATH. Added to PATH for this session." "Info" "Winget"
                    try {
                        $wingetVersion = winget --version 2>$null
                        Write-Log "winget version: $wingetVersion" "Debug" "Winget"
                    } catch {
                        Write-Log "Could not determine winget version" "Debug" "Winget"
                    }
                    return $true
                }
            }
        }
        
        # Check if Windows App Installer is installed via Get-AppxPackage
        try {
            $appInstaller = Get-AppxPackage -Name "Microsoft.DesktopAppInstaller" -AllUsers -ErrorAction SilentlyContinue
            if ($appInstaller) {
                Write-Log "Windows App Installer is installed but winget may not be in PATH" "Info" "Winget"
                
                # Try to find the winget executable in the package
                $packagePath = $appInstaller.InstallLocation
                if ($packagePath) {
                    $wingetPath = Join-Path $packagePath "winget.exe"
                    if (Test-Path $wingetPath) {
                        Write-Log "Found winget in App Installer package at: $wingetPath" "Debug" "Winget"
                        $env:PATH += ";$packagePath"
                        if (Test-Command "winget") {
                            Write-Log "winget is available from App Installer package. Added to PATH for this session." "Info" "Winget"
                            try {
                                $wingetVersion = winget --version 2>$null
                                Write-Log "winget version: $wingetVersion" "Debug" "Winget"
                            } catch {
                                Write-Log "Could not determine winget version" "Debug" "Winget"
                            }
                            return $true
                        }
                    }
                }
            }
        } catch {
            # Continue with other checks
        }
        
        # Check if winget is available in system PATH but not working
        try {
            $wingetInPath = Get-Command "winget" -ErrorAction SilentlyContinue
            if ($wingetInPath) {
                Write-Log "winget found in PATH at: $($wingetInPath.Source)" "Debug" "Winget"
                # Try to run it to see if it works
                $testResult = winget --version 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Write-Log "winget is working from PATH. Version: $testResult" "Info" "Winget"
                    return $true
                } else {
                    Write-Log "winget found in PATH but not working properly" "Debug" "Winget"
                }
            }
        } catch {
            # Continue with installation
        }
        
        # If we get here, winget is not installed or not accessible
        Write-Log "winget not found or not accessible. Attempting to install Windows App Installer..." "Info" "Winget"
        
        # Try to install via Microsoft Store using PowerShell
        try {
            Write-Log "Attempting to install Windows App Installer via Microsoft Store..." "Info" "Winget"
            
            # Use Add-AppxPackage to install from Microsoft Store
            $storeUrl = "ms-windows-store://pdp/?ProductId=9NBLGGH4NNS1"
            Start-Process $storeUrl
            
            Write-Log "Microsoft Store opened for Windows App Installer installation." "Info" "Winget"
            Write-Log "Please complete the installation manually in the Microsoft Store." "Info" "Winget"
            Write-Log "After installation, restart this script to continue." "Info" "Winget"
            
            # Wait a bit and check if installation completed
            Start-Sleep -Seconds 10
            
            # Check if winget is now available
            if (Test-Command "winget") {
                Write-Log "winget installation completed successfully!" "Info" "Winget"
                return $true
            } else {
                Write-Log "winget installation may still be in progress. Please wait and restart the script." "Warning" "Winget"
                return $false
            }
        } catch {
            Write-Log "Failed to open Microsoft Store for winget installation: $($_.Exception.Message)" "Error" "Winget"
        }
        
        # Alternative: Try to download and install manually
        Write-Log "Attempting manual winget installation..." "Info" "Winget"
        
        try {
            # Download the latest winget release
            $tempDir = [System.IO.Path]::GetTempPath()
            $wingetDir = Join-Path $tempDir "winget-install"
            
            if (-not (Test-Path $wingetDir)) {
                New-Item -ItemType Directory -Path $wingetDir -Force | Out-Null
            }
            
            # Get the latest release info from GitHub
            $releaseUrl = "https://api.github.com/repos/microsoft/winget-cli/releases/latest"
            $releaseInfo = Invoke-RestMethod -Uri $releaseUrl -Headers @{
                "Accept" = "application/vnd.github.v3+json"
                "User-Agent" = "PowerShell-Winget-Installer"
            }
            
            # Find the MSIX bundle for x64
            $msixAsset = $releaseInfo.assets | Where-Object { 
                $_.name -like "*x64.msixbundle" -and $_.name -notlike "*preview*" 
            } | Select-Object -First 1
            
            if (-not $msixAsset) {
                Write-Log "Could not find winget MSIX bundle in latest release" "Error" "Winget"
                return $false
            }
            
            $downloadUrl = $msixAsset.browser_download_url
            $downloadPath = Join-Path $wingetDir $msixAsset.name
            
            Write-Log "Downloading winget from: $downloadUrl" "Info" "Winget"
            Invoke-WebRequest -Uri $downloadUrl -OutFile $downloadPath
            
            # Install the MSIX bundle
            Write-Log "Installing winget MSIX bundle..." "Info" "Winget"
            Add-AppxPackage -Path $downloadPath -ErrorAction Stop
            
            # Clean up
            Remove-Item $wingetDir -Recurse -Force -ErrorAction SilentlyContinue
            
            # Check if installation was successful
            if (Test-Command "winget") {
                Write-Log "winget installed successfully via manual installation!" "Info" "Winget"
                return $true
            } else {
                Write-Log "winget installation failed - command not found after installation" "Error" "Winget"
                return $false
            }
            
        } catch {
            Write-Log "Failed to install winget manually: $($_.Exception.Message)" "Error" "Winget"
            return $false
        }
        
    } catch {
        Write-Log "Failed to install winget: $($_.Exception.Message)" "Error" "Winget"
        return $false
    }
}
#endregion

#region Git Installation
function Install-Git {
    Write-Log "Starting Git installation..." "Info" "Git"
    
    try {
        # Check if Git is already installed
        if (Test-Command "git") {
            Write-Log "Git is already installed. Skipping installation." "Info" "Git"
            return $true
        }
        
        # Check if Scoop is available
        if (-not (Test-Command "scoop")) {
            Write-Log "Scoop is not available. Cannot install Git." "Error" "Git"
            return $false
        }
        
        # Install Git using Scoop
        Write-Log "Installing Git using Scoop..." "Info" "Git"
        scoop install git
        
        if (Test-Command "git") {
            Write-Log "Git installed successfully!" "Info" "Git"
            return $true
        } else {
            Write-Log "Git installation failed - command not found after installation" "Error" "Git"
            return $false
        }
    } catch {
        Write-Log "Failed to install Git: $($_.Exception.Message)" "Error" "Git"
        return $false
    }
}
#endregion

#region Discord Installation
function Install-Discord {
    Write-Log "Starting Discord installation..." "Info" "Discord"
    
    try {
        # Check if Discord is already installed via Scoop
        $discordInstalled = $false
        try {
            $scoopList = scoop list 2>$null
            if ($scoopList -match "discord") {
                $discordInstalled = $true
                Write-Log "Discord is already installed via Scoop. Skipping installation." "Info" "Discord"
            }
        } catch {
            # If scoop list fails, continue with command check
        }
        
        # Also check if discord command is available
        if (-not $discordInstalled -and (Test-Command "discord")) {
            Write-Log "Discord is already installed. Skipping installation." "Info" "Discord"
            return $true
        }
        
        if ($discordInstalled) {
            return $true
        }
        
        # Check if Scoop is available
        if (-not (Test-Command "scoop")) {
            Write-Log "Scoop is not available. Cannot install Discord." "Error" "Discord"
            return $false
        }
        
        # Install Discord using Scoop
        Write-Log "Installing Discord using Scoop..." "Info" "Discord"
        scoop install discord
        
        # Check if installation was successful by checking Scoop list
        $scoopList = scoop list 2>$null
        if ($scoopList -match "discord") {
            Write-Log "Discord installed successfully via Scoop!" "Info" "Discord"
            return $true
        } else {
            Write-Log "Discord installation failed - not found in Scoop list" "Error" "Discord"
            return $false
        }
    } catch {
        Write-Log "Failed to install Discord: $($_.Exception.Message)" "Error" "Discord"
        return $false
    }
}
#endregion

#region Google Chrome Installation
function Install-GoogleChrome {
    Write-Log "Starting Google Chrome installation..." "Info" "Chrome"
    
    try {
        # Check if Chrome is already installed via Scoop
        $chromeInstalled = $false
        try {
            $scoopList = scoop list 2>$null
            if ($scoopList -match "googlechrome") {
                $chromeInstalled = $true
                Write-Log "Google Chrome is already installed via Scoop. Skipping installation." "Info" "Chrome"
            }
        } catch {
            # If scoop list fails, continue with command check
        }
        
        # Also check if chrome command is available
        if (-not $chromeInstalled -and (Test-Command "chrome")) {
            Write-Log "Google Chrome is already installed. Skipping installation." "Info" "Chrome"
            return $true
        }
        
        if ($chromeInstalled) {
            return $true
        }
        
        # Check if Scoop is available
        if (-not (Test-Command "scoop")) {
            Write-Log "Scoop is not available. Cannot install Google Chrome." "Error" "Chrome"
            return $false
        }
        
        # Add extras bucket if needed
        if (-not (Add-ScoopExtrasBucket)) {
            Write-Log "Failed to add extras bucket. Cannot install Google Chrome." "Error" "Chrome"
            return $false
        }
        
        # Install Google Chrome using Scoop extras bucket
        Write-Log "Installing Google Chrome using Scoop extras bucket..." "Info" "Chrome"
        scoop install extras/googlechrome
        
        # Check if installation was successful by checking Scoop list
        $scoopList = scoop list 2>$null
        if ($scoopList -match "googlechrome") {
            Write-Log "Google Chrome installed successfully via Scoop!" "Info" "Chrome"
            return $true
        } else {
            Write-Log "Google Chrome installation failed - not found in Scoop list" "Error" "Chrome"
            return $false
        }
    } catch {
        Write-Log "Failed to install Google Chrome: $($_.Exception.Message)" "Error" "Chrome"
        return $false
    }
}
#endregion

#region VSCode Installation
function Install-VSCode {
    Write-Log "Starting VSCode installation..." "Info" "VSCode"
    
    try {
        # Check if VSCode is already installed via Scoop
        $vscodeInstalled = $false
        try {
            $scoopList = scoop list 2>$null
            if ($scoopList -match "vscode") {
                $vscodeInstalled = $true
                Write-Log "VSCode is already installed via Scoop. Skipping installation." "Info" "VSCode"
            }
        } catch {
            # If scoop list fails, continue with command check
        }
        
        # Also check if code command is available
        if (-not $vscodeInstalled -and (Test-Command "code")) {
            Write-Log "VSCode is already installed. Skipping installation." "Info" "VSCode"
            return $true
        }
        
        if ($vscodeInstalled) {
            return $true
        }
        
        # Check if Scoop is available
        if (-not (Test-Command "scoop")) {
            Write-Log "Scoop is not available. Cannot install VSCode." "Error" "VSCode"
            return $false
        }
        
        # Add extras bucket if needed
        if (-not (Add-ScoopExtrasBucket)) {
            Write-Log "Failed to add extras bucket. Cannot install VSCode." "Error" "VSCode"
            return $false
        }
        
        # Install VSCode using Scoop extras bucket
        Write-Log "Installing VSCode using Scoop extras bucket..." "Info" "VSCode"
        scoop install extras/vscode
        
        # Check if installation was successful by checking Scoop list
        $scoopList = scoop list 2>$null
        if ($scoopList -match "vscode") {
            Write-Log "VSCode installed successfully via Scoop!" "Info" "VSCode"
            return $true
        } else {
            Write-Log "VSCode installation failed - not found in Scoop list" "Error" "VSCode"
            return $false
        }
    } catch {
        Write-Log "Failed to install VSCode: $($_.Exception.Message)" "Error" "VSCode"
        return $false
    }
}
#endregion

#region Cursor AI Editor Installation
function Install-Cursor {
    Write-Log "Starting Cursor AI editor installation..." "Info" "Cursor"
    
    try {
        # Check if Cursor is already installed via Scoop
        $cursorInstalled = $false
        try {
            $scoopList = scoop list 2>$null
            if ($scoopList -match "cursor") {
                $cursorInstalled = $true
                Write-Log "Cursor is already installed via Scoop. Skipping installation." "Info" "Cursor"
            }
        } catch {
            # If scoop list fails, continue with command check
        }
        
        # Also check if cursor command is available
        if (-not $cursorInstalled -and (Test-Command "cursor")) {
            Write-Log "Cursor is already installed. Skipping installation." "Info" "Cursor"
            return $true
        }
        
        if ($cursorInstalled) {
            return $true
        }
        
        # Check if Scoop is available
        if (-not (Test-Command "scoop")) {
            Write-Log "Scoop is not available. Cannot install Cursor." "Error" "Cursor"
            return $false
        }
        
        # Add extras bucket if needed
        if (-not (Add-ScoopExtrasBucket)) {
            Write-Log "Failed to add extras bucket. Cannot install Cursor." "Error" "Cursor"
            return $false
        }
        
        # Install Cursor using Scoop extras bucket
        Write-Log "Installing Cursor AI editor using Scoop extras bucket..." "Info" "Cursor"
        scoop install extras/cursor
        
        # Check if installation was successful by checking Scoop list
        $scoopList = scoop list 2>$null
        if ($scoopList -match "cursor") {
            Write-Log "Cursor AI editor installed successfully via Scoop!" "Info" "Cursor"
            return $true
        } else {
            Write-Log "Cursor installation failed - not found in Scoop list" "Error" "Cursor"
            return $false
        }
    } catch {
        Write-Log "Failed to install Cursor: $($_.Exception.Message)" "Error" "Cursor"
        return $false
    }
}
#endregion

#region Notion Installation
function Install-Notion {
    Write-Log "Starting Notion installation..." "Info" "Notion"
    
    try {
        # Check if Notion is already installed via Scoop
        $notionInstalled = $false
        try {
            $scoopList = scoop list 2>$null
            if ($scoopList -match "notion") {
                $notionInstalled = $true
                Write-Log "Notion is already installed via Scoop. Skipping installation." "Info" "Notion"
            }
        } catch {
            # If scoop list fails, continue with command check
        }
        
        # Also check if notion command is available
        if (-not $notionInstalled -and (Test-Command "notion")) {
            Write-Log "Notion is already installed. Skipping installation." "Info" "Notion"
            return $true
        }
        
        if ($notionInstalled) {
            return $true
        }
        
        # Check if Scoop is available
        if (-not (Test-Command "scoop")) {
            Write-Log "Scoop is not available. Cannot install Notion." "Error" "Notion"
            return $false
        }
        
        # Add extras bucket if needed
        if (-not (Add-ScoopExtrasBucket)) {
            Write-Log "Failed to add extras bucket. Cannot install Notion." "Error" "Notion"
            return $false
        }
        
        # Install Notion using Scoop extras bucket
        Write-Log "Installing Notion using Scoop extras bucket..." "Info" "Notion"
        scoop install extras/notion
        
        # Check if installation was successful by checking Scoop list
        $scoopList = scoop list 2>$null
        if ($scoopList -match "notion") {
            Write-Log "Notion installed successfully via Scoop!" "Info" "Notion"
            return $true
        } else {
            Write-Log "Notion installation failed - not found in Scoop list" "Error" "Notion"
            return $false
        }
    } catch {
        Write-Log "Failed to install Notion: $($_.Exception.Message)" "Error" "Notion"
        return $false
    }
}
#endregion

#region Obsidian Installation
function Install-Obsidian {
    Write-Log "Starting Obsidian installation..." "Info" "Obsidian"
    
    try {
        # Check if Obsidian is already installed via Scoop
        $obsidianInstalled = $false
        try {
            $scoopList = scoop list 2>$null
            if ($scoopList -match "obsidian") {
                $obsidianInstalled = $true
                Write-Log "Obsidian is already installed via Scoop. Skipping installation." "Info" "Obsidian"
            }
        } catch {
            # If scoop list fails, continue with command check
        }
        
        # Also check if obsidian command is available
        if (-not $obsidianInstalled -and (Test-Command "obsidian")) {
            Write-Log "Obsidian is already installed. Skipping installation." "Info" "Obsidian"
            return $true
        }
        
        if ($obsidianInstalled) {
            return $true
        }
        
        # Check if Scoop is available
        if (-not (Test-Command "scoop")) {
            Write-Log "Scoop is not available. Cannot install Obsidian." "Error" "Obsidian"
            return $false
        }
        
        # Add extras bucket if needed
        if (-not (Add-ScoopExtrasBucket)) {
            Write-Log "Failed to add extras bucket. Cannot install Obsidian." "Error" "Obsidian"
            return $false
        }
        
        # Install Obsidian using Scoop extras bucket
        Write-Log "Installing Obsidian using Scoop extras bucket..." "Info" "Obsidian"
        scoop install extras/obsidian
        
        # Check if installation was successful by checking Scoop list
        $scoopList = scoop list 2>$null
        if ($scoopList -match "obsidian") {
            Write-Log "Obsidian installed successfully via Scoop!" "Info" "Obsidian"
            return $true
        } else {
            Write-Log "Obsidian installation failed - not found in Scoop list" "Error" "Obsidian"
            return $false
        }
    } catch {
        Write-Log "Failed to install Obsidian: $($_.Exception.Message)" "Error" "Obsidian"
        return $false
    }
}
#endregion

#region PowerToys Installation
function Install-PowerToys {
    Write-Log "Starting PowerToys installation..." "Info" "PowerToys"
    
    try {
        # Check if PowerToys is already installed via Scoop
        $powertoysInstalled = $false
        try {
            $scoopList = scoop list 2>$null
            if ($scoopList -match "powertoys") {
                $powertoysInstalled = $true
                Write-Log "PowerToys is already installed via Scoop. Skipping installation." "Info" "PowerToys"
            }
        } catch {
            # If scoop list fails, continue with command check
        }
        
        # Also check if powertoys command is available
        if (-not $powertoysInstalled -and (Test-Command "powertoys")) {
            Write-Log "PowerToys is already installed. Skipping installation." "Info" "PowerToys"
            return $true
        }
        
        if ($powertoysInstalled) {
            return $true
        }
        
        # Check if Scoop is available
        if (-not (Test-Command "scoop")) {
            Write-Log "Scoop is not available. Cannot install PowerToys." "Error" "PowerToys"
            return $false
        }
        
        # Add extras bucket if needed
        if (-not (Add-ScoopExtrasBucket)) {
            Write-Log "Failed to add extras bucket. Cannot install PowerToys." "Error" "PowerToys"
            return $false
        }
        
        # Install PowerToys using Scoop extras bucket
        Write-Log "Installing PowerToys using Scoop extras bucket..." "Info" "PowerToys"
        Write-Log "Note: PowerToys installation may show Windows Store package errors, but the main application should still install successfully." "Warning" "PowerToys"
        
        # Capture the output to check for specific errors
        $installOutput = scoop install extras/powertoys 2>&1 | Out-String
        
        # Check if installation was successful by checking Scoop list
        $scoopList = scoop list 2>$null
        if ($scoopList -match "powertoys") {
            Write-Log "PowerToys installed successfully via Scoop!" "Info" "PowerToys"
            
            # Check for Windows Store package errors in output
            if ($installOutput -match "Deployment failed with HRESULT: 0x80073D2E" -or $installOutput -match "package deployment failed") {
                Write-Log "⚠️  PowerToys installed but some Windows Store components failed to install." "Warning" "PowerToys"
                Write-Log "This is normal and PowerToys should still work. You can manually install missing components later." "Info" "PowerToys"
                Write-Log "To install missing components, run: winget install Microsoft.PowerToys" "Info" "PowerToys"
            }
            
            return $true
        } else {
            Write-Log "PowerToys installation failed - not found in Scoop list" "Error" "PowerToys"
            Write-Log "Installation output: $installOutput" "Debug" "PowerToys"
            return $false
        }
    } catch {
        Write-Log "Failed to install PowerToys: $($_.Exception.Message)" "Error" "PowerToys"
        return $false
    }
}
#endregion

#region PowerToys Alternative Installation Information
function Show-PowerToysAlternativeInfo {
    Write-Log "=== PowerToys Alternative Installation Methods ===" "Info" "PowerToys"
    Write-Log "If PowerToys installation via Scoop continues to have issues, try these alternatives:" "Info" "PowerToys"
    Write-Log " " "Info" "PowerToys"
    Write-Log "🔧 Alternative Installation Methods:" "Info" "PowerToys"
    Write-Log "1. Using winget (Windows Package Manager):" "Info" "PowerToys"
    Write-Log "   winget install Microsoft.PowerToys" "Info" "PowerToys"
    Write-Log " " "Info" "PowerToys"
    Write-Log "2. Direct download from Microsoft:" "Info" "PowerToys"
    Write-Log "   Visit: https://github.com/microsoft/PowerToys/releases" "Info" "PowerToys"
    Write-Log "   Download the latest .exe installer and run it" "Info" "PowerToys"
    Write-Log " " "Info" "PowerToys"
    Write-Log "3. Microsoft Store:" "Info" "PowerToys"
    Write-Log "   Search for 'PowerToys' in the Microsoft Store" "Info" "PowerToys"
    Write-Log " " "Info" "PowerToys"
    Write-Log "💡 Note: The Windows Store package error is common and usually doesn't affect core functionality." "Info" "PowerToys"
    Write-Log "PowerToys should still work even if some components fail to install." "Info" "PowerToys"
    Write-Log "=== End of PowerToys Alternative Installation Methods ===" "Info" "PowerToys"
    
    return $true
}
#endregion

#region Microsoft Office Installation Information
function Show-MicrosoftOfficeInfo {
    Write-Log "=== Microsoft Office Home and Student 2021 Installation Guide ===" "Info" "Office"
    Write-Log "Microsoft Office cannot be installed via Scoop due to licensing requirements." "Info" "Office"
    Write-Log "Please follow these steps to install Microsoft Office manually:" "Info" "Office"
    Write-Log " " "Info" "Office"
    Write-Log "📋 Manual Installation Steps:" "Info" "Office"
    Write-Log "1. Visit: https://www.microsoft.com/en-us/microsoft-365/try" "Info" "Office"
    Write-Log "2. Sign in with your Microsoft account" "Info" "Office"
    Write-Log "3. Choose 'Microsoft Office Home and Student 2021'" "Info" "Office"
    Write-Log "4. Purchase or enter your product key" "Info" "Office"
    Write-Log "5. Download the Office installer" "Info" "Office"
    Write-Log "6. Run the installer and follow the setup wizard" "Info" "Office"
    Write-Log "7. Activate Office with your product key when prompted" "Info" "Office"
    Write-Log " " "Info" "Office"
    Write-Log "💡 Tips:" "Info" "Office"
    Write-Log "- Office Home and Student 2021 includes: Word, Excel, PowerPoint" "Info" "Office"
    Write-Log "- One-time purchase (no subscription required)" "Info" "Office"
    Write-Log "- Valid for 1 PC (Windows or Mac)" "Info" "Office"
    Write-Log "- Product key is required for activation" "Info" "Office"
    Write-Log " " "Info" "Office"
    Write-Log "🔗 Useful Links:" "Info" "Office"
    Write-Log "- Office 2021 Home & Student: https://www.microsoft.com/en-us/microsoft-365/p/office-home-student-2021/CFQ7TTC0K7C8" "Info" "Office"
    Write-Log "- Office Support: https://support.microsoft.com/office" "Info" "Office"
    Write-Log "- Product Key Help: https://support.microsoft.com/en-us/office/find-your-office-product-key-032c9a43-8b0c-4d8a-9e3a-6e0c1c6c6c6c" "Info" "Office"
    Write-Log "=== End of Microsoft Office Installation Guide ===" "Info" "Office"
    
    return $true
}
#endregion

#region Flowlauncher Installation
function Install-Flowlauncher {
    Write-Log "Starting Flowlauncher installation..." "Info" "Flowlauncher"
    
    try {
        # Check if Flowlauncher is already installed via Scoop
        $flowlauncherInstalled = $false
        try {
            $scoopList = scoop list 2>$null
            if ($scoopList -match "flow-launcher") {
                $flowlauncherInstalled = $true
                Write-Log "Flowlauncher is already installed via Scoop. Skipping installation." "Info" "Flowlauncher"
            }
        } catch {
            # If scoop list fails, continue with command check
        }
        
        # Also check if flowlauncher command is available
        if (-not $flowlauncherInstalled -and (Test-Command "flowlauncher")) {
            Write-Log "Flowlauncher is already installed. Skipping installation." "Info" "Flowlauncher"
            return $true
        }
        
        if ($flowlauncherInstalled) {
            return $true
        }
        
        # Check if Scoop is available
        if (-not (Test-Command "scoop")) {
            Write-Log "Scoop is not available. Cannot install Flowlauncher." "Error" "Flowlauncher"
            return $false
        }
        
        # Add extras bucket if needed
        if (-not (Add-ScoopExtrasBucket)) {
            Write-Log "Failed to add extras bucket. Cannot install Flowlauncher." "Error" "Flowlauncher"
            return $false
        }
        
        # Install Flowlauncher using Scoop extras bucket
        Write-Log "Installing Flowlauncher using Scoop extras bucket..." "Info" "Flowlauncher"
        scoop install extras/flow-launcher
        
        # Check if installation was successful by checking Scoop list
        $scoopList = scoop list 2>$null
        if ($scoopList -match "flow-launcher") {
            Write-Log "Flowlauncher installed successfully via Scoop!" "Info" "Flowlauncher"
            return $true
        } else {
            Write-Log "Flowlauncher installation failed - not found in Scoop list" "Error" "Flowlauncher"
            return $false
        }
    } catch {
        Write-Log "Failed to install Flowlauncher: $($_.Exception.Message)" "Error" "Flowlauncher"
        return $false
    }
}
#endregion

#region FlowLauncher Settings Configuration
function Configure-FlowLauncherSettings {
    Write-Log "Starting FlowLauncher settings configuration..." "Info" "FlowLauncherConfig"
    
    try {
        # Define paths
        $dotfilesSettingsPath = "C:\Users\nmdex\.dotfiles-windows\.config\FlowLauncher\Settings.json"
        $flowlauncherSettingsPath = "C:\Users\nmdex\scoop\apps\flow-launcher\current\app-1.20.1\UserData\Settings\Settings.json"
        $flowlauncherSettingsDir = Split-Path $flowlauncherSettingsPath -Parent
        
        # Check if FlowLauncher is installed
        if (-not (Test-Command "flowlauncher")) {
            Write-Log "FlowLauncher is not installed. Cannot configure settings." "Error" "FlowLauncherConfig"
            return $false
        }
        
        # Check if dotfiles settings file exists
        if (-not (Test-Path $dotfilesSettingsPath)) {
            Write-Log "Dotfiles settings file not found at: $dotfilesSettingsPath" "Error" "FlowLauncherConfig"
            Write-Log "Please ensure the .config/FlowLauncher/Settings.json file exists in your dotfiles repository." "Error" "FlowLauncherConfig"
            return $false
        }
        
        # Check if FlowLauncher settings directory exists
        if (-not (Test-Path $flowlauncherSettingsDir)) {
            Write-Log "FlowLauncher settings directory not found at: $flowlauncherSettingsDir" "Error" "FlowLauncherConfig"
            Write-Log "FlowLauncher may not be properly installed or the path has changed." "Error" "FlowLauncherConfig"
            return $false
        }
        
        # Check if symbolic link already exists
        if (Test-Path $flowlauncherSettingsPath) {
            $existingItem = Get-Item $flowlauncherSettingsPath -ErrorAction SilentlyContinue
            if ($existingItem.LinkType -eq "SymbolicLink") {
                $targetPath = $existingItem.Target
                if ($targetPath -eq $dotfilesSettingsPath) {
                    Write-Log "Symbolic link already exists and points to the correct dotfiles path. Skipping configuration." "Info" "FlowLauncherConfig"
                    return $true
                } else {
                    Write-Log "Symbolic link exists but points to different path: $targetPath" "Warning" "FlowLauncherConfig"
                    Write-Log "Removing existing symbolic link..." "Info" "FlowLauncherConfig"
                    Remove-Item $flowlauncherSettingsPath -Force
                }
            } else {
                Write-Log "Settings.json exists but is not a symbolic link. Creating backup..." "Info" "FlowLauncherConfig"
                $backupPath = "$flowlauncherSettingsPath.backup"
                Copy-Item $flowlauncherSettingsPath $backupPath -Force
                Write-Log "Backup created at: $backupPath" "Info" "FlowLauncherConfig"
                Remove-Item $flowlauncherSettingsPath -Force
            }
        }
        
        # Create symbolic link
        Write-Log "Creating symbolic link from dotfiles to FlowLauncher settings..." "Info" "FlowLauncherConfig"
        $result = New-Item -ItemType SymbolicLink -Path $flowlauncherSettingsPath -Target $dotfilesSettingsPath -ErrorAction Stop
        
        if ($result -and (Test-Path $flowlauncherSettingsPath)) {
            Write-Log "Symbolic link created successfully!" "Info" "FlowLauncherConfig"
            Write-Log "FlowLauncher settings are now synchronized with your dotfiles repository." "Info" "FlowLauncherConfig"
            
            # Verify the link works
            try {
                $testContent = Get-Content $flowlauncherSettingsPath -TotalCount 1 -ErrorAction Stop
                Write-Log "Symbolic link verification successful - settings file is accessible." "Info" "FlowLauncherConfig"
            } catch {
                Write-Log "Warning: Symbolic link created but verification failed: $($_.Exception.Message)" "Warning" "FlowLauncherConfig"
            }
            
            return $true
        } else {
            Write-Log "Failed to create symbolic link" "Error" "FlowLauncherConfig"
            return $false
        }
        
    } catch {
        Write-Log "Failed to configure FlowLauncher settings: $($_.Exception.Message)" "Error" "FlowLauncherConfig"
        return $false
    }
}
#endregion

#region ProtonVPN Installation
function Install-ProtonVPN {
    Write-Log "Starting ProtonVPN installation..." "Info" "ProtonVPN"
    
    try {
        # Check if ProtonVPN is already installed via Scoop
        $protonvpnInstalled = $false
        try {
            $scoopList = scoop list 2>$null
            if ($scoopList -match "protonvpn-np") {
                $protonvpnInstalled = $true
                Write-Log "ProtonVPN is already installed via Scoop. Skipping installation." "Info" "ProtonVPN"
            }
        } catch {
            # If scoop list fails, continue with command check
        }
        
        # Also check if protonvpn command is available
        if (-not $protonvpnInstalled -and (Test-Command "protonvpn")) {
            Write-Log "ProtonVPN is already installed. Skipping installation." "Info" "ProtonVPN"
            return $true
        }
        
        if ($protonvpnInstalled) {
            return $true
        }
        
        # Check if Scoop is available
        if (-not (Test-Command "scoop")) {
            Write-Log "Scoop is not available. Cannot install ProtonVPN." "Error" "ProtonVPN"
            return $false
        }
        
        # Add nonportable bucket if needed
        Write-Log "Adding nonportable bucket to Scoop..." "Debug" "ProtonVPN"
        try {
            $buckets = scoop bucket list 2>$null
            if (-not ($buckets -match "nonportable")) {
                Write-Log "Adding nonportable bucket to Scoop..." "Info" "ProtonVPN"
                scoop bucket add nonportable
            }
        } catch {
            Write-Log "Failed to add nonportable bucket: $($_.Exception.Message)" "Error" "ProtonVPN"
            return $false
        }
        
        # Install ProtonVPN using Scoop nonportable bucket
        Write-Log "Installing ProtonVPN using Scoop nonportable bucket..." "Info" "ProtonVPN"
        scoop install nonportable/protonvpn-np
        
        # Check if installation was successful by checking Scoop list
        $scoopList = scoop list 2>$null
        if ($scoopList -match "protonvpn-np") {
            Write-Log "ProtonVPN installed successfully via Scoop!" "Info" "ProtonVPN"
            return $true
        } else {
            Write-Log "ProtonVPN installation failed - not found in Scoop list" "Error" "ProtonVPN"
            return $false
        }
    } catch {
        Write-Log "Failed to install ProtonVPN: $($_.Exception.Message)" "Error" "ProtonVPN"
        return $false
    }
}
#endregion

#region Google QuickShare Installation
function Install-GoogleQuickShare {
    Write-Log "Starting Google QuickShare installation..." "Info" "QuickShare"
    
    try {
        # Check if QuickShare is already installed
        $quickShareInstalled = $false
        $detectionMethod = ""
        
        Write-Log "Checking for existing Google QuickShare installation..." "Debug" "QuickShare"
        
        # Check if QuickShare is installed via Scoop
        try {
            $scoopList = scoop list 2>$null
            if ($scoopList -match "quickshare") {
                $quickShareInstalled = $true
                $detectionMethod = "Scoop"
                Write-Log "Google QuickShare is already installed via Scoop. Skipping installation." "Info" "QuickShare"
            }
        } catch {
            Write-Log "Scoop list check failed, continuing with other checks..." "Debug" "QuickShare"
        }
        
        # Check if QuickShare is installed in Program Files
        if (-not $quickShareInstalled) {
            $quickSharePath = "${env:ProgramFiles}\Google\QuickShare\QuickShare.exe"
            Write-Log "Checking Program Files path: $quickSharePath" "Debug" "QuickShare"
            if (Test-Path $quickSharePath) {
                $quickShareInstalled = $true
                $detectionMethod = "Program Files"
                Write-Log "Google QuickShare is already installed in Program Files. Skipping installation." "Info" "QuickShare"
            }
        }
        
        # Check if QuickShare is installed in Program Files (x86)
        if (-not $quickShareInstalled) {
            $quickSharePathX86 = "${env:ProgramFiles(x86)}\Google\QuickShare\QuickShare.exe"
            Write-Log "Checking Program Files (x86) path: $quickSharePathX86" "Debug" "QuickShare"
            if (Test-Path $quickSharePathX86) {
                $quickShareInstalled = $true
                $detectionMethod = "Program Files (x86)"
                Write-Log "Google QuickShare is already installed in Program Files (x86). Skipping installation." "Info" "QuickShare"
            }
        }
        
        # Check if QuickShare is installed in AppData
        if (-not $quickShareInstalled) {
            $quickShareAppDataPath = "${env:LOCALAPPDATA}\Google\QuickShare\QuickShare.exe"
            Write-Log "Checking AppData path: $quickShareAppDataPath" "Debug" "QuickShare"
            if (Test-Path $quickShareAppDataPath) {
                $quickShareInstalled = $true
                $detectionMethod = "AppData"
                Write-Log "Google QuickShare is already installed in AppData. Skipping installation." "Info" "QuickShare"
            }
        }
        
        # Check if QuickShare is installed via winget
        if (-not $quickShareInstalled) {
            try {
                Write-Log "Checking winget for Google.QuickShare..." "Debug" "QuickShare"
                $wingetList = winget list "Google.QuickShare" 2>$null
                if ($wingetList -match "Google.QuickShare") {
                    $quickShareInstalled = $true
                    $detectionMethod = "winget"
                    Write-Log "Google QuickShare is already installed via winget. Skipping installation." "Info" "QuickShare"
                }
            } catch {
                Write-Log "winget check failed, continuing with other checks..." "Debug" "QuickShare"
            }
        }
        
        # Check Windows Registry for QuickShare installation
        if (-not $quickShareInstalled) {
            try {
                Write-Log "Checking Windows Registry for QuickShare..." "Debug" "QuickShare"
                $registryPaths = @(
                    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
                    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
                    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
                )
                
                foreach ($regPath in $registryPaths) {
                    $installedApps = Get-ItemProperty $regPath -ErrorAction SilentlyContinue | Where-Object {
                        $_.DisplayName -like "*QuickShare*" -or $_.DisplayName -like "*Nearby Share*" -or $_.DisplayName -like "*Better Together*"
                    }
                    
                    if ($installedApps) {
                        $quickShareInstalled = $true
                        $detectionMethod = "Registry"
                        Write-Log "Google QuickShare is already installed (found in registry). Skipping installation." "Info" "QuickShare"
                        break
                    }
                }
            } catch {
                Write-Log "Registry check failed, continuing with other checks..." "Debug" "QuickShare"
            }
        }
        
        # Check if QuickShare process is running (indicates it's installed)
        if (-not $quickShareInstalled) {
            try {
                Write-Log "Checking for running QuickShare processes..." "Debug" "QuickShare"
                $quickShareProcess = Get-Process -Name "QuickShare" -ErrorAction SilentlyContinue
                if ($quickShareProcess) {
                    $quickShareInstalled = $true
                    $detectionMethod = "Running Process"
                    Write-Log "Google QuickShare is already installed and running. Skipping installation." "Info" "QuickShare"
                }
            } catch {
                Write-Log "Process check failed, continuing with other checks..." "Debug" "QuickShare"
            }
        }
        
        # Check for QuickShare in Start Menu
        if (-not $quickShareInstalled) {
            Write-Log "Checking Start Menu for QuickShare shortcuts..." "Debug" "QuickShare"
            $startMenuPaths = @(
                "${env:APPDATA}\Microsoft\Windows\Start Menu\Programs\Google QuickShare.lnk",
                "${env:APPDATA}\Microsoft\Windows\Start Menu\Programs\QuickShare.lnk",
                "${env:APPDATA}\Microsoft\Windows\Start Menu\Programs\Nearby Share.lnk"
            )
            
            foreach ($startMenuPath in $startMenuPaths) {
                Write-Log "Checking Start Menu path: $startMenuPath" "Debug" "QuickShare"
                if (Test-Path $startMenuPath) {
                    $quickShareInstalled = $true
                    $detectionMethod = "Start Menu"
                    Write-Log "Google QuickShare is already installed (found in Start Menu). Skipping installation." "Info" "QuickShare"
                    break
                }
            }
        }
        
        # Check for QuickShare in Desktop shortcuts
        if (-not $quickShareInstalled) {
            Write-Log "Checking Desktop for QuickShare shortcuts..." "Debug" "QuickShare"
            $desktopPaths = @(
                "${env:USERPROFILE}\Desktop\Google QuickShare.lnk",
                "${env:USERPROFILE}\Desktop\QuickShare.lnk",
                "${env:USERPROFILE}\Desktop\Nearby Share.lnk"
            )
            
            foreach ($desktopPath in $desktopPaths) {
                Write-Log "Checking Desktop path: $desktopPath" "Debug" "QuickShare"
                if (Test-Path $desktopPath) {
                    $quickShareInstalled = $true
                    $detectionMethod = "Desktop"
                    Write-Log "Google QuickShare is already installed (found on Desktop). Skipping installation." "Info" "QuickShare"
                    break
                }
            }
        }
        
        # Check for QuickShare in All Users Start Menu
        if (-not $quickShareInstalled) {
            Write-Log "Checking All Users Start Menu for QuickShare..." "Debug" "QuickShare"
            $allUsersStartMenuPaths = @(
                "${env:ProgramData}\Microsoft\Windows\Start Menu\Programs\Google QuickShare.lnk",
                "${env:ProgramData}\Microsoft\Windows\Start Menu\Programs\QuickShare.lnk",
                "${env:ProgramData}\Microsoft\Windows\Start Menu\Programs\Nearby Share.lnk"
            )
            
            foreach ($startMenuPath in $allUsersStartMenuPaths) {
                Write-Log "Checking All Users Start Menu path: $startMenuPath" "Debug" "QuickShare"
                if (Test-Path $startMenuPath) {
                    $quickShareInstalled = $true
                    $detectionMethod = "All Users Start Menu"
                    Write-Log "Google QuickShare is already installed (found in All Users Start Menu). Skipping installation." "Info" "QuickShare"
                    break
                }
            }
        }
        
        # Check for QuickShare in WindowsApps (Microsoft Store app)
        if (-not $quickShareInstalled) {
            Write-Log "Checking WindowsApps for QuickShare..." "Debug" "QuickShare"
            $windowsAppsPaths = @(
                "${env:ProgramFiles}\WindowsApps\Google.QuickShare*",
                "${env:ProgramFiles(x86)}\WindowsApps\Google.QuickShare*"
            )
            
            foreach ($basePath in $windowsAppsPaths) {
                try {
                    $quickShareDirs = Get-ChildItem -Path $basePath -Directory -ErrorAction SilentlyContinue
                    foreach ($dir in $quickShareDirs) {
                        $quickShareExe = Join-Path $dir.FullName "QuickShare.exe"
                        Write-Log "Checking WindowsApps path: $quickShareExe" "Debug" "QuickShare"
                        if (Test-Path $quickShareExe) {
                            $quickShareInstalled = $true
                            $detectionMethod = "WindowsApps"
                            Write-Log "Google QuickShare is already installed (found in WindowsApps). Skipping installation." "Info" "QuickShare"
                            break
                        }
                    }
                    if ($quickShareInstalled) { break }
                } catch {
                    Write-Log "WindowsApps check failed for path: $basePath" "Debug" "QuickShare"
                }
            }
        }
        
        if ($quickShareInstalled) {
            Write-Log "Google QuickShare installation check completed - already installed (detected via: $detectionMethod)." "Info" "QuickShare"
            return $true
        }
        
        Write-Log "Google QuickShare not found in any expected location. Proceeding with installation..." "Info" "QuickShare"
        
        # Download and install QuickShare
        Write-Log "Downloading Google QuickShare installer..." "Info" "QuickShare"
        $tempDir = [System.IO.Path]::GetTempPath()
        $installerPath = Join-Path $tempDir "QuickShareSetup.exe"
        
        try {
            # Download the installer
            Invoke-WebRequest -Uri "https://dl.google.com/tag/s/appguid%3D%7B232066FE-FF4D-4C25-83B4-3F8747CF7E3A%7D%26iid%3D%7B3E33A1CF-1170-4488-4648-B015D012F4A9%7D%26lang%3Den%26browser%3D4%26usagestats%3D0%26appname%3DNearby%2520Better%2520Together%26needsadmin%3Dtrue/better_together/QuickShareSetup.exe" -OutFile $installerPath
            
            Write-Log "Installing Google QuickShare..." "Info" "QuickShare"
            
            # Run the installer silently
            $process = Start-Process -FilePath $installerPath -ArgumentList "/S" -Wait -PassThru
            
            if ($process.ExitCode -eq 0) {
                Write-Log "Google QuickShare installed successfully!" "Info" "QuickShare"
                
                # Clean up the installer
                if (Test-Path $installerPath) {
                    Remove-Item $installerPath -Force
                }
                
                return $true
            } else {
                Write-Log "Google QuickShare installation failed with exit code: $($process.ExitCode)" "Error" "QuickShare"
                
                # Clean up the installer
                if (Test-Path $installerPath) {
                    Remove-Item $installerPath -Force
                }
                
                return $false
            }
        } catch {
            Write-Log "Failed to download or install Google QuickShare: $($_.Exception.Message)" "Error" "QuickShare"
            
            # Clean up the installer if it exists
            if (Test-Path $installerPath) {
                Remove-Item $installerPath -Force
            }
            
            return $false
        }
    } catch {
        Write-Log "Failed to install Google QuickShare: $($_.Exception.Message)" "Error" "QuickShare"
        return $false
    }
}
#endregion

#region Syncthing Installation
function Install-Syncthing {
    Write-Log "Starting Syncthing installation..." "Info" "Syncthing"
    
    try {
        # Check if Syncthing is already installed via Scoop
        $syncthingInstalled = $false
        try {
            $scoopList = scoop list 2>$null
            if ($scoopList -match "syncthing") {
                $syncthingInstalled = $true
                Write-Log "Syncthing is already installed via Scoop. Skipping installation." "Info" "Syncthing"
            }
        } catch {
            # If scoop list fails, continue with command check
        }
        
        # Also check if syncthing command is available
        if (-not $syncthingInstalled -and (Test-Command "syncthing")) {
            Write-Log "Syncthing is already installed. Skipping installation." "Info" "Syncthing"
            return $true
        }
        
        if ($syncthingInstalled) {
            return $true
        }
        
        # Check if Scoop is available
        if (-not (Test-Command "scoop")) {
            Write-Log "Scoop is not available. Cannot install Syncthing." "Error" "Syncthing"
            return $false
        }
        
        # Install Syncthing using Scoop main bucket
        Write-Log "Installing Syncthing using Scoop..." "Info" "Syncthing"
        scoop install syncthing
        
        # Check if installation was successful by checking Scoop list
        $scoopList = scoop list 2>$null
        if ($scoopList -match "syncthing") {
            Write-Log "Syncthing installed successfully via Scoop!" "Info" "Syncthing"
            return $true
        } else {
            Write-Log "Syncthing installation failed - not found in Scoop list" "Error" "Syncthing"
            return $false
        }
    } catch {
        Write-Log "Failed to install Syncthing: $($_.Exception.Message)" "Error" "Syncthing"
        return $false
    }
}
#endregion

#region VLC Installation
function Install-VLC {
    Write-Log "Starting VLC installation..." "Info" "VLC"
    
    try {
        # Check if VLC is already installed via Scoop
        $vlcInstalled = $false
        try {
            $scoopList = scoop list 2>$null
            if ($scoopList -match "vlc") {
                $vlcInstalled = $true
                Write-Log "VLC is already installed via Scoop. Skipping installation." "Info" "VLC"
            }
        } catch {
            # If scoop list fails, continue with command check
        }
        
        # Also check if vlc command is available
        if (-not $vlcInstalled -and (Test-Command "vlc")) {
            Write-Log "VLC is already installed. Skipping installation." "Info" "VLC"
            return $true
        }
        
        if ($vlcInstalled) {
            return $true
        }
        
        # Check if Scoop is available
        if (-not (Test-Command "scoop")) {
            Write-Log "Scoop is not available. Cannot install VLC." "Error" "VLC"
            return $false
        }
        
        # Add extras bucket if needed
        if (-not (Add-ScoopExtrasBucket)) {
            Write-Log "Failed to add extras bucket. Cannot install VLC." "Error" "VLC"
            return $false
        }
        
        # Install VLC using Scoop extras bucket
        Write-Log "Installing VLC using Scoop extras bucket..." "Info" "VLC"
        scoop install extras/vlc
        
        # Check if installation was successful by checking Scoop list
        $scoopList = scoop list 2>$null
        if ($scoopList -match "vlc") {
            Write-Log "VLC installed successfully via Scoop!" "Info" "VLC"
            return $true
        } else {
            Write-Log "VLC installation failed - not found in Scoop list" "Error" "VLC"
            return $false
        }
    } catch {
        Write-Log "Failed to install VLC: $($_.Exception.Message)" "Error" "VLC"
        return $false
    }
}
#endregion

#region Zalo Installation
function Install-Zalo {
    Write-Log "Starting Zalo installation..." "Info" "Zalo"
    
    try {
        # Check if Zalo is already installed
        $zaloInstalled = $false
        
        # Check if Zalo is installed via Scoop
        try {
            $scoopList = scoop list 2>$null
            if ($scoopList -match "zalo") {
                $zaloInstalled = $true
                Write-Log "Zalo is already installed via Scoop. Skipping installation." "Info" "Zalo"
            }
        } catch {
            # If scoop list fails, continue with other checks
        }
        
        # Check if Zalo is installed in Program Files
        $zaloPath = "${env:ProgramFiles}\Zalo\Zalo.exe"
        if (Test-Path $zaloPath) {
            $zaloInstalled = $true
            Write-Log "Zalo is already installed in Program Files. Skipping installation." "Info" "Zalo"
        }
        
        # Check if Zalo is installed in Program Files (x86)
        $zaloPathX86 = "${env:ProgramFiles(x86)}\Zalo\Zalo.exe"
        if (Test-Path $zaloPathX86) {
            $zaloInstalled = $true
            Write-Log "Zalo is already installed in Program Files (x86). Skipping installation." "Info" "Zalo"
        }
        
        # Check if Zalo is installed in AppData
        $zaloAppDataPath = "${env:LOCALAPPDATA}\Programs\Zalo\Zalo.exe"
        if (Test-Path $zaloAppDataPath) {
            $zaloInstalled = $true
            Write-Log "Zalo is already installed in AppData. Skipping installation." "Info" "Zalo"
        }
        
        if ($zaloInstalled) {
            return $true
        }
        
        # Download and install Zalo
        Write-Log "Downloading Zalo installer..." "Info" "Zalo"
        $tempDir = [System.IO.Path]::GetTempPath()
        $installerPath = Join-Path $tempDir "ZaloSetup.exe"
        
        try {
            # Download the installer from Zalo's official download page
            # The URL redirects to the actual download, so we'll use a more direct approach
            Write-Log "Attempting to download Zalo from official source..." "Info" "Zalo"
            
            # Use PowerShell to download from the Zalo download page
            $webRequest = Invoke-WebRequest -Uri "https://zalo.me/download/zalo-pc?utm=90000" -UseBasicParsing
            $downloadUrl = $webRequest.Links | Where-Object { $_.href -like "*.exe" } | Select-Object -First 1 -ExpandProperty href
            
            if (-not $downloadUrl) {
                # Fallback to a direct download approach
                Write-Log "Direct download URL not found, using alternative method..." "Info" "Zalo"
                $downloadUrl = "https://zalo.me/download/zalo-pc?utm=90000"
            }
            
            Invoke-WebRequest -Uri $downloadUrl -OutFile $installerPath
            
            Write-Log "Installing Zalo..." "Info" "Zalo"
            
            # Run the installer silently
            $process = Start-Process -FilePath $installerPath -ArgumentList "/S" -Wait -PassThru
            
            if ($process.ExitCode -eq 0) {
                Write-Log "Zalo installed successfully!" "Info" "Zalo"
                
                # Clean up the installer
                if (Test-Path $installerPath) {
                    Remove-Item $installerPath -Force
                }
                
                return $true
            } else {
                Write-Log "Zalo installation failed with exit code: $($process.ExitCode)" "Error" "Zalo"
                
                # Clean up the installer
                if (Test-Path $installerPath) {
                    Remove-Item $installerPath -Force
                }
                
                return $false
            }
        } catch {
            Write-Log "Failed to download or install Zalo: $($_.Exception.Message)" "Error" "Zalo"
            
            # Clean up the installer if it exists
            if (Test-Path $installerPath) {
                Remove-Item $installerPath -Force
            }
            
            return $false
        }
    } catch {
        Write-Log "Failed to install Zalo: $($_.Exception.Message)" "Error" "Zalo"
        return $false
    }
}
#endregion

#region PC Manager Installation
function Install-PCManager {
    Write-Log "Starting PC Manager installation..." "Info" "PCManager"
    
    try {
        # Check if PC Manager is already installed
        $pcManagerInstalled = $false
        $detectionMethod = ""
        
        Write-Log "Checking for existing PC Manager installation..." "Debug" "PCManager"
        
        # Check if PC Manager is installed via winget (msstore)
        Write-Log "Checking winget for PC Manager (msstore ID 9PM860492SZD)..." "Debug" "PCManager"
        $wingetList = winget list "9PM860492SZD" 2>$null
        if ($wingetList -match "PC Manager" -or $wingetList -match "9PM860492SZD") {
            $pcManagerInstalled = $true
            $detectionMethod = "winget (msstore)"
            Write-Log "PC Manager is already installed via winget (msstore). Skipping installation." "Info" "PCManager"
        }
        
        # Check if PC Manager is installed in WindowsApps (Microsoft Store app)
        if (-not $pcManagerInstalled) {
            Write-Log "Checking WindowsApps for PC Manager..." "Debug" "PCManager"
            $windowsAppsPaths = @(
                "${env:ProgramFiles}\WindowsApps\Microsoft.PCManager*",
                "${env:ProgramFiles(x86)}\WindowsApps\Microsoft.PCManager*"
            )
            
            foreach ($basePath in $windowsAppsPaths) {
                try {
                    $pcManagerDirs = Get-ChildItem -Path $basePath -Directory -ErrorAction SilentlyContinue | Sort-Object Name -Descending
                    foreach ($dir in $pcManagerDirs) {
                        $pcManagerExe = Join-Path $dir.FullName "PCManager.exe"
                        Write-Log "Checking WindowsApps path: $pcManagerExe" "Debug" "PCManager"
                        if (Test-Path $pcManagerExe) {
                            $pcManagerInstalled = $true
                            $detectionMethod = "WindowsApps"
                            Write-Log "PC Manager is already installed (found in WindowsApps). Skipping installation." "Info" "PCManager"
                            break
                        }
                    }
                    if ($pcManagerInstalled) { break }
                } catch {
                    Write-Log "WindowsApps check failed for path: $basePath" "Debug" "PCManager"
                }
            }
        }
        
        # Check if PC Manager is installed via Get-AppxPackage
        if (-not $pcManagerInstalled) {
            try {
                Write-Log "Checking AppxPackage for PC Manager..." "Debug" "PCManager"
                $appxPackage = Get-AppxPackage -Name "Microsoft.PCManager" -AllUsers -ErrorAction SilentlyContinue
                if ($appxPackage) {
                    $pcManagerInstalled = $true
                    $detectionMethod = "AppxPackage"
                    Write-Log "PC Manager is already installed (found via AppxPackage). Skipping installation." "Info" "PCManager"
                }
            } catch {
                Write-Log "AppxPackage check failed, continuing with other checks..." "Debug" "PCManager"
            }
        }
        
        # Check Windows Registry for PC Manager installation
        if (-not $pcManagerInstalled) {
            try {
                Write-Log "Checking Windows Registry for PC Manager..." "Debug" "PCManager"
                $registryPaths = @(
                    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
                    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
                    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
                )
                
                foreach ($regPath in $registryPaths) {
                    $installedApps = Get-ItemProperty $regPath -ErrorAction SilentlyContinue | Where-Object {
                        $_.DisplayName -like "*PC Manager*" -or $_.DisplayName -like "*Microsoft PC Manager*"
                    }
                    
                    if ($installedApps) {
                        $pcManagerInstalled = $true
                        $detectionMethod = "Registry"
                        Write-Log "PC Manager is already installed (found in registry). Skipping installation." "Info" "PCManager"
                        break
                    }
                }
            } catch {
                Write-Log "Registry check failed, continuing with other checks..." "Debug" "PCManager"
            }
        }
        
        # Check for PC Manager in Start Menu
        if (-not $pcManagerInstalled) {
            Write-Log "Checking Start Menu for PC Manager..." "Debug" "PCManager"
            $startMenuPaths = @(
                "${env:APPDATA}\Microsoft\Windows\Start Menu\Programs\PC Manager.lnk",
                "${env:APPDATA}\Microsoft\Windows\Start Menu\Programs\Microsoft PC Manager.lnk"
            )
            
            foreach ($startMenuPath in $startMenuPaths) {
                Write-Log "Checking Start Menu path: $startMenuPath" "Debug" "PCManager"
                if (Test-Path $startMenuPath) {
                    $pcManagerInstalled = $true
                    $detectionMethod = "Start Menu"
                    Write-Log "PC Manager is already installed (found in Start Menu). Skipping installation." "Info" "PCManager"
                    break
                }
            }
        }
        
        # Check for PC Manager in All Users Start Menu
        if (-not $pcManagerInstalled) {
            Write-Log "Checking All Users Start Menu for PC Manager..." "Debug" "PCManager"
            $allUsersStartMenuPaths = @(
                "${env:ProgramData}\Microsoft\Windows\Start Menu\Programs\PC Manager.lnk",
                "${env:ProgramData}\Microsoft\Windows\Start Menu\Programs\Microsoft PC Manager.lnk"
            )
            
            foreach ($startMenuPath in $allUsersStartMenuPaths) {
                Write-Log "Checking All Users Start Menu path: $startMenuPath" "Debug" "PCManager"
                if (Test-Path $startMenuPath) {
                    $pcManagerInstalled = $true
                    $detectionMethod = "All Users Start Menu"
                    Write-Log "PC Manager is already installed (found in All Users Start Menu). Skipping installation." "Info" "PCManager"
                    break
                }
            }
        }
        
        if ($pcManagerInstalled) {
            Write-Log "PC Manager installation check completed - already installed (detected via: $detectionMethod)." "Info" "PCManager"
            return $true
        }
        
        Write-Log "PC Manager not found in any expected location. Proceeding with installation..." "Info" "PCManager"
        
        # Install PC Manager using winget (msstore)
        Write-Log "Installing PC Manager using winget (msstore)..." "Info" "PCManager"
        Write-Log "Note: This may take a few minutes and require user interaction..." "Info" "PCManager"

        try {
            Write-Log "Using winget command: winget install --id=9PM860492SZD --source=msstore" "Debug" "PCManager"
            $process = Start-Process -FilePath "winget" -ArgumentList 'install --id=9PM860492SZD --source=msstore --accept-source-agreements --accept-package-agreements --verbose-logs' -Wait -PassThru -NoNewWindow
            $exitCode = $process.ExitCode
            Write-Log "winget install process exited with code: $exitCode" "Debug" "PCManager"

            if ($exitCode -eq 0) {
                Write-Log "PC Manager install command completed successfully (exit code 0)." "Info" "PCManager"
                # Wait a few seconds for registration
                Start-Sleep -Seconds 5
                # Fallback: check with Get-AppxPackage
                $appxPackage = Get-AppxPackage -Name "9PM860492SZD" -AllUsers -ErrorAction SilentlyContinue
                if ($appxPackage) {
                    Write-Log "PC Manager detected via Get-AppxPackage after install." "Info" "PCManager"
                    return $true
                } else {
                    Write-Log "PC Manager not detected via Get-AppxPackage, but install command succeeded. Please verify manually." "Warning" "PCManager"
                    return $true
                }
            } else {
                Write-Log "PC Manager install command failed with exit code $exitCode." "Error" "PCManager"
                return $false
            }
        } catch {
            Write-Log "Failed to install PC Manager via winget (msstore): $($_.Exception.Message)" "Error" "PCManager"
            return $false
        }
        
    } catch {
        Write-Log "Failed to install PC Manager: $($_.Exception.Message)" "Error" "PCManager"
        return $false
    }
}
#endregion

#region PC Manager Alternative Installation Information
function Show-PCManagerAlternativeInfo {
    Write-Log "=== PC Manager Alternative Installation Methods ===" "Info" "PCManager"
    Write-Log "If PC Manager installation via winget (msstore) fails, try these alternatives:" "Info" "PCManager"
    Write-Log " " "Info" "PCManager"
    Write-Log "🔧 Alternative Installation Methods:" "Info" "PCManager"
    Write-Log "1. Microsoft Store (Recommended):" "Info" "PCManager"
    Write-Log "   - Open Microsoft Store" "Info" "PCManager"
    Write-Log "   - Search for 'PC Manager' or use the code 9PM860492SZD" "Info" "PCManager"
    Write-Log "   - Click 'Get' or 'Install'" "Info" "PCManager"
    Write-Log "   - Direct link: https://www.microsoft.com/store/apps/9PM860492SZD" "Info" "PCManager"
    Write-Log " " "Info" "PCManager"
    Write-Log "2. Using winget manually:" "Info" "PCManager"
    Write-Log "   winget install --id=9PM860492SZD --source=msstore" "Info" "PCManager"
    Write-Log " " "Info" "PCManager"
    Write-Log "3. Direct download (if available):" "Info" "PCManager"
    Write-Log "   Visit: https://www.microsoft.com/store/apps/9PM860492SZD" "Info" "PCManager"
    Write-Log "   Click 'Get' to open Microsoft Store" "Info" "PCManager"
    Write-Log " " "Info" "PCManager"
    Write-Log "💡 Note: PC Manager is a Microsoft Store app and requires a Microsoft account." "Info" "PCManager"
    Write-Log "The app provides system optimization, cleanup, and performance monitoring features." "Info" "PCManager"
    Write-Log "=== End of PC Manager Alternative Installation Methods ===" "Info" "PCManager"
    return $true
}
#endregion

#region winget Alternative Installation Information
function Show-WingetAlternativeInfo {
    Write-Log "=== winget Alternative Installation Methods ===" "Info" "Winget"
    Write-Log "If winget installation fails, try these alternatives:" "Info" "Winget"
    Write-Log " " "Info" "Winget"
    Write-Log "🔧 Alternative Installation Methods:" "Info" "Winget"
    Write-Log "1. Microsoft Store (Recommended):" "Info" "Winget"
    Write-Log "   - Open Microsoft Store" "Info" "Winget"
    Write-Log "   - Search for 'App Installer'" "Info" "Winget"
    Write-Log "   - Click 'Get' or 'Install'" "Info" "Winget"
    Write-Log "   - Direct link: https://www.microsoft.com/store/apps/9NBLGGH4NNS1" "Info" "Winget"
    Write-Log " " "Info" "Winget"
    Write-Log "2. Manual download from GitHub:" "Info" "Winget"
    Write-Log "   - Visit: https://github.com/microsoft/winget-cli/releases" "Info" "Winget"
    Write-Log "   - Download the latest x64.msixbundle" "Info" "Winget"
    Write-Log "   - Double-click to install" "Info" "Winget"
    Write-Log " " "Info" "Winget"
    Write-Log "3. Using PowerShell (if available):" "Info" "Winget"
    Write-Log "   Add-AppxPackage -Path 'path-to-winget.msixbundle'" "Info" "Winget"
    Write-Log " " "Info" "Winget"
    Write-Log "💡 Note: winget requires Windows 10 version 1709 or later." "Info" "Winget"
    Write-Log "After installation, restart your terminal/PowerShell to use winget commands." "Info" "Winget"
    Write-Log "=== End of winget Alternative Installation Methods ===" "Info" "Winget"
    
    return $true
}
#endregion

#region Pure Battery Add-on Installation
function Install-PureBatteryAddon {
    Write-Log "Starting Pure Battery Add-on installation..." "Info" "PureBatteryAddon"
    try {
        # Check if Pure Battery Add-on is already installed via winget (msstore)
        Write-Log "Checking winget for Pure Battery Add-on (msstore ID 9N3HDTNCF6Z8)..." "Debug" "PureBatteryAddon"
        $wingetList = winget list "9N3HDTNCF6Z8" 2>$null
        if ($wingetList -match "Pure Battery" -or $wingetList -match "9N3HDTNCF6Z8") {
            Write-Log "Pure Battery Add-on is already installed via winget (msstore). Skipping installation." "Info" "PureBatteryAddon"
            return $true
        }
        # Install Pure Battery Add-on using winget (msstore)
        Write-Log "Installing Pure Battery Add-on using winget (msstore)..." "Info" "PureBatteryAddon"
        Write-Log "Using winget command: winget install --id=9N3HDTNCF6Z8 --source=msstore" "Debug" "PureBatteryAddon"
        $process = Start-Process -FilePath "winget" -ArgumentList 'install --id=9N3HDTNCF6Z8 --source=msstore --accept-source-agreements --accept-package-agreements --verbose-logs' -Wait -PassThru -NoNewWindow
        $exitCode = $process.ExitCode
        Write-Log "winget install process exited with code: $exitCode" "Debug" "PureBatteryAddon"
        if ($exitCode -eq 0) {
            Write-Log "Pure Battery Add-on install command completed successfully (exit code 0)." "Info" "PureBatteryAddon"
            # Wait a few seconds for registration
            Start-Sleep -Seconds 5
            # Fallback: check with Get-AppxPackage
            $appxPackage = Get-AppxPackage -Name "9N3HDTNCF6Z8" -AllUsers -ErrorAction SilentlyContinue
            if ($appxPackage) {
                Write-Log "Pure Battery Add-on detected via Get-AppxPackage after install." "Info" "PureBatteryAddon"
                return $true
            } else {
                Write-Log "Pure Battery Add-on not detected via Get-AppxPackage, but install command succeeded. Please verify manually." "Warning" "PureBatteryAddon"
                return $true
            }
        } else {
            Write-Log "Pure Battery Add-on install command failed with exit code $exitCode." "Error" "PureBatteryAddon"
            return $false
        }
    } catch {
        Write-Log "Failed to install Pure Battery Add-on: $($_.Exception.Message)" "Error" "PureBatteryAddon"
        return $false
    }
}
#endregion

#region Windows Terminal Installation
function Install-WindowsTerminal {
    Write-Log "Starting Windows Terminal installation..." "Info" "WindowsTerminal"
    try {
        # Check if Windows Terminal is already installed via winget
        Write-Log "Checking winget for Windows Terminal (ID Microsoft.WindowsTerminal)..." "Debug" "WindowsTerminal"
        $wingetList = winget list "Microsoft.WindowsTerminal" 2>$null
        if ($wingetList -match "Windows Terminal" -or $wingetList -match "Microsoft.WindowsTerminal") {
            Write-Log "Windows Terminal is already installed via winget. Skipping installation." "Info" "WindowsTerminal"
            return $true
        }
        # Install Windows Terminal using winget
        Write-Log "Installing Windows Terminal using winget..." "Info" "WindowsTerminal"
        Write-Log "Using winget command: winget install --id=Microsoft.WindowsTerminal -e" "Debug" "WindowsTerminal"
        $process = Start-Process -FilePath "winget" -ArgumentList 'install --id=Microsoft.WindowsTerminal -e --accept-source-agreements --accept-package-agreements --verbose-logs' -Wait -PassThru -NoNewWindow
        $exitCode = $process.ExitCode
        Write-Log "winget install process exited with code: $exitCode" "Debug" "WindowsTerminal"
        if ($exitCode -eq 0) {
            Write-Log "Windows Terminal install command completed successfully (exit code 0)." "Info" "WindowsTerminal"
            # Wait a few seconds for registration
            Start-Sleep -Seconds 5
            # Fallback: check with Get-AppxPackage
            $appxPackage = Get-AppxPackage -Name "Microsoft.WindowsTerminal" -AllUsers -ErrorAction SilentlyContinue
            if ($appxPackage) {
                Write-Log "Windows Terminal detected via Get-AppxPackage after install." "Info" "WindowsTerminal"
                return $true
            } else {
                Write-Log "Windows Terminal not detected via Get-AppxPackage, but install command succeeded. Please verify manually." "Warning" "WindowsTerminal"
                return $true
            }
        } else {
            Write-Log "Windows Terminal install command failed with exit code $exitCode." "Error" "WindowsTerminal"
            return $false
        }
    } catch {
        Write-Log "Failed to install Windows Terminal: $($_.Exception.Message)" "Error" "WindowsTerminal"
        return $false
    }
}
#endregion

#region Main Execution
function Main {
    Write-Log "=== Windows Dotfiles Installer Started ===" "Info" "Main"
    Write-Log "Log Level: $LogLevel" "Debug" "Main"
    Write-Log "Running as Administrator: $([Security.Principal.WindowsIdentity]::GetCurrent().Groups -contains 'S-1-5-32-544')" "Debug" "Main"
    
    $successCount = 0
    $totalSteps = 21
    
    # Step 1: Install winget
    Write-Log ("Step 1/{0}: Installing winget (Windows Package Manager)..." -f $totalSteps) "Info" "Main"
    if (Install-Winget) {
        $successCount++
        Write-Log "✓ winget installation completed" "Info" "Main"
    } else {
        Write-Log "✗ winget installation failed" "Error" "Main"
    }
    
    # Step 2: Install Scoop
    Write-Log ("Step 2/{0}: Installing Scoop..." -f $totalSteps) "Info" "Main"
    if (Install-Scoop) {
        $successCount++
        Write-Log "✓ Scoop installation completed" "Info" "Main"
    } else {
        Write-Log "✗ Scoop installation failed" "Error" "Main"
    }
    
    # Step 3: Install Git
    Write-Log ("Step 3/{0}: Installing Git..." -f $totalSteps) "Info" "Main"
    if (Install-Git) {
        $successCount++
        Write-Log "✓ Git installation completed" "Info" "Main"
    } else {
        Write-Log "✗ Git installation failed" "Error" "Main"
    }
    
    # Step 4: Install VSCode
    Write-Log ("Step 4/{0}: Installing VSCode..." -f $totalSteps) "Info" "Main"
    if (Install-VSCode) {
        $successCount++
        Write-Log "✓ VSCode installation completed" "Info" "Main"
    } else {
        Write-Log "✗ VSCode installation failed" "Error" "Main"
    }
    
    # Step 5: Install Cursor AI Editor
    Write-Log ("Step 5/{0}: Installing Cursor AI Editor..." -f $totalSteps) "Info" "Main"
    if (Install-Cursor) {
        $successCount++
        Write-Log "✓ Cursor AI Editor installation completed" "Info" "Main"
    } else {
        Write-Log "✗ Cursor AI Editor installation failed" "Error" "Main"
    }
    
    # Step 6: Install Discord
    Write-Log ("Step 6/{0}: Installing Discord..." -f $totalSteps) "Info" "Main"
    if (Install-Discord) {
        $successCount++
        Write-Log "✓ Discord installation completed" "Info" "Main"
    } else {
        Write-Log "✗ Discord installation failed" "Error" "Main"
    }
    
    # Step 7: Install Google Chrome
    Write-Log ("Step 7/{0}: Installing Google Chrome..." -f $totalSteps) "Info" "Main"
    if (Install-GoogleChrome) {
        $successCount++
        Write-Log "✓ Google Chrome installation completed" "Info" "Main"
    } else {
        Write-Log "✗ Google Chrome installation failed" "Error" "Main"
    }
    
    # Step 8: Install Notion
    Write-Log ("Step 8/{0}: Installing Notion..." -f $totalSteps) "Info" "Main"
    if (Install-Notion) {
        $successCount++
        Write-Log "✓ Notion installation completed" "Info" "Main"
    } else {
        Write-Log "✗ Notion installation failed" "Error" "Main"
    }
    
    # Step 9: Install Obsidian
    Write-Log ("Step 9/{0}: Installing Obsidian..." -f $totalSteps) "Info" "Main"
    if (Install-Obsidian) {
        $successCount++
        Write-Log "✓ Obsidian installation completed" "Info" "Main"
    } else {
        Write-Log "✗ Obsidian installation failed" "Error" "Main"
    }
    
    # Step 10: Install PowerToys
    Write-Log ("Step 10/{0}: Installing PowerToys..." -f $totalSteps) "Info" "Main"
    if (Install-PowerToys) {
        $successCount++
        Write-Log "✓ PowerToys installation completed" "Info" "Main"
    } else {
        Write-Log "✗ PowerToys installation failed" "Error" "Main"
        Write-Log "Showing alternative installation methods..." "Info" "Main"
        Show-PowerToysAlternativeInfo
    }
    
    # Step 11: Install Flowlauncher
    Write-Log ("Step 11/{0}: Installing Flowlauncher..." -f $totalSteps) "Info" "Main"
    if (Install-Flowlauncher) {
        $successCount++
        Write-Log "✓ Flowlauncher installation completed" "Info" "Main"
    } else {
        Write-Log "✗ Flowlauncher installation failed" "Error" "Main"
    }
    
    # Step 12: Configure FlowLauncher Settings
    Write-Log ("Step 12/{0}: Configuring FlowLauncher settings..." -f $totalSteps) "Info" "Main"
    if (Configure-FlowLauncherSettings) {
        $successCount++
        Write-Log "✓ FlowLauncher settings configuration completed" "Info" "Main"
    } else {
        Write-Log "✗ FlowLauncher settings configuration failed" "Error" "Main"
    }
    
    # Step 13: Install ProtonVPN
    Write-Log ("Step 13/{0}: Installing ProtonVPN..." -f $totalSteps) "Info" "Main"
    if (Install-ProtonVPN) {
        $successCount++
        Write-Log "✓ ProtonVPN installation completed" "Info" "Main"
    } else {
        Write-Log "✗ ProtonVPN installation failed" "Error" "Main"
    }
    
    # Step 14: Install Google QuickShare
    Write-Log ("Step 14/{0}: Installing Google QuickShare..." -f $totalSteps) "Info" "Main"
    if (Install-GoogleQuickShare) {
        $successCount++
        Write-Log "✓ Google QuickShare installation completed" "Info" "Main"
    } else {
        Write-Log "✗ Google QuickShare installation failed" "Error" "Main"
    }
    
    # Step 15: Install Syncthing
    Write-Log ("Step 15/{0}: Installing Syncthing..." -f $totalSteps) "Info" "Main"
    if (Install-Syncthing) {
        $successCount++
        Write-Log "✓ Syncthing installation completed" "Info" "Main"
    } else {
        Write-Log "✗ Syncthing installation failed" "Error" "Main"
    }
    
    # Step 16: Install VLC
    Write-Log ("Step 16/{0}: Installing VLC..." -f $totalSteps) "Info" "Main"
    if (Install-VLC) {
        $successCount++
        Write-Log "✓ VLC installation completed" "Info" "Main"
    } else {
        Write-Log "✗ VLC installation failed" "Error" "Main"
    }
    
    # Step 17: Install Zalo
    Write-Log ("Step 17/{0}: Installing Zalo..." -f $totalSteps) "Info" "Main"
    if (Install-Zalo) {
        $successCount++
        Write-Log "✓ Zalo installation completed" "Info" "Main"
    } else {
        Write-Log "✗ Zalo installation failed" "Error" "Main"
    }
    
    # Step 18: Install PC Manager
    Write-Log ("Step 18/{0}: Installing PC Manager..." -f $totalSteps) "Info" "Main"
    if (Install-PCManager) {
        $successCount++
        Write-Log "✓ PC Manager installation completed" "Info" "Main"
    } else {
        Write-Log "✗ PC Manager installation failed" "Error" "Main"
        Write-Log "Showing alternative installation methods..." "Info" "Main"
        Show-PCManagerAlternativeInfo
    }
    # Step 19: Install Pure Battery Add-on
    Write-Log ("Step 19/{0}: Installing Pure Battery Add-on..." -f $totalSteps) "Info" "Main"
    if (Install-PureBatteryAddon) {
        $successCount++
        Write-Log "✓ Pure Battery Add-on installation completed" "Info" "Main"
    } else {
        Write-Log "✗ Pure Battery Add-on installation failed" "Error" "Main"
    }
    # Step 20: Install Windows Terminal
    Write-Log ("Step 20/{0}: Installing Windows Terminal..." -f $totalSteps) "Info" "Main"
    if (Install-WindowsTerminal) {
        $successCount++
        Write-Log "✓ Windows Terminal installation completed" "Info" "Main"
    } else {
        Write-Log "✗ Windows Terminal installation failed" "Error" "Main"
    }
    # Step 21: Show Microsoft Office Installation Information
    Write-Log ("Step 21/{0}: Providing Microsoft Office installation information..." -f $totalSteps) "Info" "Main"
    if (Show-MicrosoftOfficeInfo) {
        $successCount++
        Write-Log "✓ Microsoft Office information provided" "Info" "Main"
    } else {
        Write-Log "✗ Failed to show Microsoft Office information" "Error" "Main"
    }
    
    # Summary
    Write-Log "=== Installation Summary ===" "Info" "Main"
    Write-Log ("Completed: {0}/{1} steps successfully" -f $successCount, $totalSteps) "Info" "Main"
    
    if ($successCount -eq $totalSteps) {
        Write-Log "🎉 All installations completed successfully!" "Info" "Main"
        Write-Log "Next steps:" "Info" "Main"
        Write-Log "1. You can now use 'winget install <package>' to install packages" "Info" "Main"
        Write-Log "2. You can now use 'scoop install <package>' to install packages" "Info" "Main"
        Write-Log "3. Run 'git --version' to verify Git installation" "Info" "Main"
        Write-Log "4. Run 'code' to launch VSCode" "Info" "Main"
        Write-Log "5. Run 'cursor' to launch Cursor AI Editor" "Info" "Main"
        Write-Log "6. Run 'discord' to launch Discord" "Info" "Main"
        Write-Log "7. Run 'chrome' to launch Google Chrome" "Info" "Main"
        Write-Log "8. Run 'notion' to launch Notion" "Info" "Main"
        Write-Log "9. Run 'obsidian' to launch Obsidian" "Info" "Main"
        Write-Log "10. Run 'powertoys' to launch PowerToys" "Info" "Main"
        Write-Log "11. Press 'Alt+Space' to launch Flowlauncher" "Info" "Main"
        Write-Log "12. FlowLauncher settings are now synchronized with your dotfiles repository" "Info" "Main"
        Write-Log "13. Run 'protonvpn' to launch ProtonVPN" "Info" "Main"
        Write-Log "14. Look for QuickShare in your system tray or Start menu" "Info" "Main"
        Write-Log "15. Run 'syncthing' to launch Syncthing" "Info" "Main"
        Write-Log "16. Run 'vlc' to launch VLC Media Player" "Info" "Main"
        Write-Log "17. Look for Zalo in your Start menu or desktop" "Info" "Main"
        Write-Log "18. Look for PC Manager in your Start menu or Microsoft Store" "Info" "Main"
        Write-Log "19. Install Pure Battery Add-on manually using the guide above" "Info" "Main"
        Write-Log "20. Run 'winget --help' to see available commands" "Info" "Main"
        Write-Log "21. Run 'scoop help' to see available commands" "Info" "Main"
        Write-Log "22. Visit https://winget.run/ for winget packages" "Info" "Main"
        Write-Log "23. Visit https://scoop.sh/ for more information" "Info" "Main"
    } else {
        Write-Log "⚠️  Some installations failed. Please review the logs above." "Warning" "Main"
        Write-Log "You may need to run the script again or manually install the failed components." "Warning" "Main"
    }
    
    Write-Log "=== Windows Dotfiles Installer Completed ===" "Info" "Main"
}
#endregion

# Execute main function
try {
    Main
} catch {
    Write-Log "Critical error in main execution: $($_.Exception.Message)" "Error" "Main"
    Write-Log "Stack trace: $($_.ScriptStackTrace)" "Debug" "Main"
    exit 1
}

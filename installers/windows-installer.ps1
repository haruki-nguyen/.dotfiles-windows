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
        
        # Check if QuickShare is installed via Scoop
        try {
            $scoopList = scoop list 2>$null
            if ($scoopList -match "quickshare") {
                $quickShareInstalled = $true
                Write-Log "Google QuickShare is already installed via Scoop. Skipping installation." "Info" "QuickShare"
            }
        } catch {
            # If scoop list fails, continue with other checks
        }
        
        # Check if QuickShare is installed in Program Files
        $quickSharePath = "${env:ProgramFiles}\Google\QuickShare\QuickShare.exe"
        if (Test-Path $quickSharePath) {
            $quickShareInstalled = $true
            Write-Log "Google QuickShare is already installed in Program Files. Skipping installation." "Info" "QuickShare"
        }
        
        # Check if QuickShare is installed in Program Files (x86)
        $quickSharePathX86 = "${env:ProgramFiles(x86)}\Google\QuickShare\QuickShare.exe"
        if (Test-Path $quickSharePathX86) {
            $quickShareInstalled = $true
            Write-Log "Google QuickShare is already installed in Program Files (x86). Skipping installation." "Info" "QuickShare"
        }
        
        if ($quickShareInstalled) {
            return $true
        }
        
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

#region Main Execution
function Main {
    Write-Log "=== Windows Dotfiles Installer Started ===" "Info" "Main"
    Write-Log "Log Level: $LogLevel" "Debug" "Main"
    Write-Log "Running as Administrator: $([Security.Principal.WindowsIdentity]::GetCurrent().Groups -contains 'S-1-5-32-544')" "Debug" "Main"
    
    $successCount = 0
    $totalSteps = 13
    
    # Step 1: Install Scoop
    Write-Log ("Step 1/{0}: Installing Scoop..." -f $totalSteps) "Info" "Main"
    if (Install-Scoop) {
        $successCount++
        Write-Log "✓ Scoop installation completed" "Info" "Main"
    } else {
        Write-Log "✗ Scoop installation failed" "Error" "Main"
    }
    
    # Step 2: Install Git
    Write-Log ("Step 2/{0}: Installing Git..." -f $totalSteps) "Info" "Main"
    if (Install-Git) {
        $successCount++
        Write-Log "✓ Git installation completed" "Info" "Main"
    } else {
        Write-Log "✗ Git installation failed" "Error" "Main"
    }
    
    # Step 3: Install VSCode
    Write-Log ("Step 3/{0}: Installing VSCode..." -f $totalSteps) "Info" "Main"
    if (Install-VSCode) {
        $successCount++
        Write-Log "✓ VSCode installation completed" "Info" "Main"
    } else {
        Write-Log "✗ VSCode installation failed" "Error" "Main"
    }
    
    # Step 4: Install Cursor AI Editor
    Write-Log ("Step 4/{0}: Installing Cursor AI Editor..." -f $totalSteps) "Info" "Main"
    if (Install-Cursor) {
        $successCount++
        Write-Log "✓ Cursor AI Editor installation completed" "Info" "Main"
    } else {
        Write-Log "✗ Cursor AI Editor installation failed" "Error" "Main"
    }
    
    # Step 5: Install Discord
    Write-Log ("Step 5/{0}: Installing Discord..." -f $totalSteps) "Info" "Main"
    if (Install-Discord) {
        $successCount++
        Write-Log "✓ Discord installation completed" "Info" "Main"
    } else {
        Write-Log "✗ Discord installation failed" "Error" "Main"
    }
    
    # Step 6: Install Google Chrome
    Write-Log ("Step 6/{0}: Installing Google Chrome..." -f $totalSteps) "Info" "Main"
    if (Install-GoogleChrome) {
        $successCount++
        Write-Log "✓ Google Chrome installation completed" "Info" "Main"
    } else {
        Write-Log "✗ Google Chrome installation failed" "Error" "Main"
    }
    
    # Step 7: Install Notion
    Write-Log ("Step 7/{0}: Installing Notion..." -f $totalSteps) "Info" "Main"
    if (Install-Notion) {
        $successCount++
        Write-Log "✓ Notion installation completed" "Info" "Main"
    } else {
        Write-Log "✗ Notion installation failed" "Error" "Main"
    }
    
    # Step 8: Install Obsidian
    Write-Log ("Step 8/{0}: Installing Obsidian..." -f $totalSteps) "Info" "Main"
    if (Install-Obsidian) {
        $successCount++
        Write-Log "✓ Obsidian installation completed" "Info" "Main"
    } else {
        Write-Log "✗ Obsidian installation failed" "Error" "Main"
    }
    
    # Step 9: Install PowerToys
    Write-Log ("Step 9/{0}: Installing PowerToys..." -f $totalSteps) "Info" "Main"
    if (Install-PowerToys) {
        $successCount++
        Write-Log "✓ PowerToys installation completed" "Info" "Main"
    } else {
        Write-Log "✗ PowerToys installation failed" "Error" "Main"
        Write-Log "Showing alternative installation methods..." "Info" "Main"
        Show-PowerToysAlternativeInfo
    }
    
    # Step 10: Install Flowlauncher
    Write-Log ("Step 10/{0}: Installing Flowlauncher..." -f $totalSteps) "Info" "Main"
    if (Install-Flowlauncher) {
        $successCount++
        Write-Log "✓ Flowlauncher installation completed" "Info" "Main"
    } else {
        Write-Log "✗ Flowlauncher installation failed" "Error" "Main"
    }
    
    # Step 11: Install ProtonVPN
    Write-Log ("Step 11/{0}: Installing ProtonVPN..." -f $totalSteps) "Info" "Main"
    if (Install-ProtonVPN) {
        $successCount++
        Write-Log "✓ ProtonVPN installation completed" "Info" "Main"
    } else {
        Write-Log "✗ ProtonVPN installation failed" "Error" "Main"
    }
    
    # Step 12: Install Google QuickShare
    Write-Log ("Step 12/{0}: Installing Google QuickShare..." -f $totalSteps) "Info" "Main"
    if (Install-GoogleQuickShare) {
        $successCount++
        Write-Log "✓ Google QuickShare installation completed" "Info" "Main"
    } else {
        Write-Log "✗ Google QuickShare installation failed" "Error" "Main"
    }
    
    # Step 13: Show Microsoft Office Installation Information
    Write-Log ("Step 13/{0}: Providing Microsoft Office installation information..." -f $totalSteps) "Info" "Main"
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
        Write-Log "1. You can now use 'scoop install <package>' to install packages" "Info" "Main"
        Write-Log "2. Run 'git --version' to verify Git installation" "Info" "Main"
        Write-Log "3. Run 'code' to launch VSCode" "Info" "Main"
        Write-Log "4. Run 'cursor' to launch Cursor AI Editor" "Info" "Main"
        Write-Log "5. Run 'discord' to launch Discord" "Info" "Main"
        Write-Log "6. Run 'chrome' to launch Google Chrome" "Info" "Main"
        Write-Log "7. Run 'notion' to launch Notion" "Info" "Main"
        Write-Log "8. Run 'obsidian' to launch Obsidian" "Info" "Main"
        Write-Log "9. Run 'powertoys' to launch PowerToys" "Info" "Main"
        Write-Log "10. Press 'Alt+Space' to launch Flowlauncher" "Info" "Main"
        Write-Log "11. Run 'protonvpn' to launch ProtonVPN" "Info" "Main"
        Write-Log "12. Look for QuickShare in your system tray or Start menu" "Info" "Main"
        Write-Log "13. Install Microsoft Office manually using the guide above" "Info" "Main"
        Write-Log "14. Run 'scoop help' to see available commands" "Info" "Main"
        Write-Log "15. Visit https://scoop.sh/ for more information" "Info" "Main"
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

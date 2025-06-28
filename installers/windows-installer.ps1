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

#region VSCode Installation
function Install-VSCode {
    Write-Log "Starting VSCode installation..." "Info" "VSCode"
    
    try {
        # Check if VSCode is already installed
        if (Test-Command "code") {
            Write-Log "VSCode is already installed. Skipping installation." "Info" "VSCode"
            return $true
        }
        
        # Check if Scoop is available
        if (-not (Test-Command "scoop")) {
            Write-Log "Scoop is not available. Cannot install VSCode." "Error" "VSCode"
            return $false
        }
        
        # Add extras bucket if not already added
        Write-Log "Adding extras bucket to Scoop..." "Debug" "VSCode"
        scoop bucket add extras
        
        # Install VSCode using Scoop extras bucket
        Write-Log "Installing VSCode using Scoop extras bucket..." "Info" "VSCode"
        scoop install extras/vscode
        
        if (Test-Command "code") {
            Write-Log "VSCode installed successfully!" "Info" "VSCode"
            return $true
        } else {
            Write-Log "VSCode installation failed - command not found after installation" "Error" "VSCode"
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
        # Check if Cursor is already installed
        if (Test-Command "cursor") {
            Write-Log "Cursor is already installed. Skipping installation." "Info" "Cursor"
            return $true
        }
        
        # Check if Scoop is available
        if (-not (Test-Command "scoop")) {
            Write-Log "Scoop is not available. Cannot install Cursor." "Error" "Cursor"
            return $false
        }
        
        # Add extras bucket if not already added
        Write-Log "Adding extras bucket to Scoop..." "Debug" "Cursor"
        scoop bucket add extras
        
        # Install Cursor using Scoop extras bucket
        Write-Log "Installing Cursor AI editor using Scoop extras bucket..." "Info" "Cursor"
        scoop install extras/cursor
        
        if (Test-Command "cursor") {
            Write-Log "Cursor AI editor installed successfully!" "Info" "Cursor"
            return $true
        } else {
            Write-Log "Cursor installation failed - command not found after installation" "Error" "Cursor"
            return $false
        }
    } catch {
        Write-Log "Failed to install Cursor: $($_.Exception.Message)" "Error" "Cursor"
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
    $totalSteps = 4
    
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
        Write-Log "5. Run 'scoop help' to see available commands" "Info" "Main"
        Write-Log "6. Visit https://scoop.sh/ for more information" "Info" "Main"
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

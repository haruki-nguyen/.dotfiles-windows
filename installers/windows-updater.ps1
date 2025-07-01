#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Windows dotfiles updater and system cleanup script
    
.DESCRIPTION
    This script updates installed packages and cleans up system clutter,
    behaving like Nix package manager with clean package management.
    
.PARAMETER LogLevel
    Logging level: Debug, Info, Warning, Error. Default: Info
    
.PARAMETER UpdateOnly
    Only update packages, skip cleanup operations
    
.PARAMETER CleanupOnly
    Only perform cleanup operations, skip package updates
    
.PARAMETER ForceCleanup
    Force aggressive cleanup operations (use with caution)
    
.EXAMPLE
    .\windows-updater.ps1 -LogLevel Debug
    .\windows-updater.ps1 -UpdateOnly
    .\windows-updater.ps1 -CleanupOnly -ForceCleanup
#>

param(
    [ValidateSet("Debug", "Info", "Warning", "Error")]
    [string]$LogLevel = "Info",
    [switch]$UpdateOnly,
    [switch]$CleanupOnly,
    [switch]$ForceCleanup
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

#region Package Management Functions
function Update-ScoopPackages {
    Write-Log "Updating Scoop packages..." "Info" "ScoopUpdate"
    
    try {
        if (-not (Test-Command "scoop")) {
            Write-Log "Scoop is not installed. Skipping Scoop updates." "Warning" "ScoopUpdate"
            return $false
        }
        
        # Update Scoop itself
        Write-Log "Updating Scoop..." "Info" "ScoopUpdate"
        scoop update
        
        # Update all installed packages
        Write-Log "Updating all Scoop packages..." "Info" "ScoopUpdate"
        scoop update *
        
        # Clean up old versions
        Write-Log "Cleaning up old Scoop package versions..." "Info" "ScoopUpdate"
        scoop cleanup *
        
        Write-Log "Scoop packages updated successfully!" "Info" "ScoopUpdate"
        return $true
    } catch {
        Write-Log "Failed to update Scoop packages: $($_.Exception.Message)" "Error" "ScoopUpdate"
        return $false
    }
}

function Update-WingetPackages {
    Write-Log "Updating winget packages..." "Info" "WingetUpdate"
    
    try {
        if (-not (Test-Command "winget")) {
            Write-Log "winget is not installed. Skipping winget updates." "Warning" "WingetUpdate"
            return $false
        }
        
        # Update all packages
        Write-Log "Updating all winget packages..." "Info" "WingetUpdate"
        winget upgrade --all --accept-source-agreements --accept-package-agreements
        
        Write-Log "winget packages updated successfully!" "Info" "WingetUpdate"
        return $true
    } catch {
        Write-Log "Failed to update winget packages: $($_.Exception.Message)" "Error" "WingetUpdate"
        return $false
    }
}
#endregion

#region System Cleanup Functions
function Clear-TemporaryFiles {
    Write-Log "Clearing temporary files..." "Info" "Cleanup"
    
    try {
        $tempPaths = @(
            $env:TEMP,
            $env:TMP,
            [System.IO.Path]::GetTempPath(),
            "$env:LOCALAPPDATA\Temp",
            "$env:WINDIR\Temp"
        )
        
        $totalCleaned = 0
        
        foreach ($tempPath in $tempPaths) {
            if (Test-Path $tempPath) {
                Write-Log "Cleaning temporary files in: $tempPath" "Debug" "Cleanup"
                
                try {
                    $files = Get-ChildItem -Path $tempPath -Recurse -Force -ErrorAction SilentlyContinue | Where-Object {
                        $_.LastWriteTime -lt (Get-Date).AddDays(-7) -and -not $_.PSIsContainer
                    }
                    
                    foreach ($file in $files) {
                        try {
                            Remove-Item $file.FullName -Force -ErrorAction SilentlyContinue
                            $totalCleaned++
                        } catch {
                            # Continue with other files
                        }
                    }
                } catch {
                    Write-Log "Error accessing $tempPath : $($_.Exception.Message)" "Debug" "Cleanup"
                }
            }
        }
        
        Write-Log "Cleaned $totalCleaned temporary files" "Info" "Cleanup"
        return $true
    } catch {
        Write-Log "Failed to clear temporary files: $($_.Exception.Message)" "Error" "Cleanup"
        return $false
    }
}

function Clear-WindowsUpdateCache {
    Write-Log "Clearing Windows Update cache..." "Info" "Cleanup"
    
    try {
        # Stop Windows Update service
        Write-Log "Stopping Windows Update service..." "Debug" "Cleanup"
        Stop-Service -Name "wuauserv" -Force -ErrorAction SilentlyContinue
        
        # Clear Windows Update cache
        $updateCachePath = "$env:SystemRoot\SoftwareDistribution\Download"
        if (Test-Path $updateCachePath) {
            Write-Log "Removing Windows Update cache..." "Debug" "Cleanup"
            Remove-Item -Path $updateCachePath -Recurse -Force -ErrorAction SilentlyContinue
        }
        
        # Restart Windows Update service
        Write-Log "Restarting Windows Update service..." "Debug" "Cleanup"
        Start-Service -Name "wuauserv" -ErrorAction SilentlyContinue
        
        Write-Log "Windows Update cache cleared successfully!" "Info" "Cleanup"
        return $true
    } catch {
        Write-Log "Failed to clear Windows Update cache: $($_.Exception.Message)" "Error" "Cleanup"
        return $false
    }
}

function Clear-DNS {
    Write-Log "Clearing DNS cache..." "Info" "Cleanup"
    
    try {
        ipconfig /flushdns
        Write-Log "DNS cache cleared successfully!" "Info" "Cleanup"
        return $true
    } catch {
        Write-Log "Failed to clear DNS cache: $($_.Exception.Message)" "Error" "Cleanup"
        return $false
    }
}

function Clear-RecycleBin {
    Write-Log "Clearing Recycle Bin (manual method)..." "Info" "Cleanup"
    try {
        $drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Free -gt 0 }
        $cleared = $false
        $deletedCount = 0
        foreach ($drive in $drives) {
            $recyclePath = Join-Path $drive.Root '$Recycle.Bin'
            if (Test-Path $recyclePath) {
                # Remove all subfolders (each user's SID) and files
                $items = Get-ChildItem -Path $recyclePath -Force -ErrorAction SilentlyContinue
                foreach ($item in $items) {
                    try {
                        Remove-Item $item.FullName -Recurse -Force -ErrorAction SilentlyContinue
                        $deletedCount++
                        $cleared = $true
                    } catch {
                        # Ignore errors (e.g., locked files)
                    }
                }
            }
        }
        if ($cleared) {
            Write-Log "Recycle Bin cleared manually on all drives. Deleted $deletedCount items/folders." "Info" "Cleanup"
            return $true
        } else {
            Write-Log "No Recycle Bin folders found to clear." "Warning" "Cleanup"
            return $false
        }
    } catch {
        Write-Log "Failed to clear Recycle Bin: $($_.Exception.Message)" "Error" "Cleanup"
        return $false
    }
}

function Optimize-DiskSpace {
    Write-Log "Running disk space optimization..." "Info" "Cleanup"
    
    try {
        # Run DISM cleanup
        Write-Log "Running DISM cleanup..." "Debug" "Cleanup"
        dism.exe /online /cleanup-image /startcomponentcleanup /resetbase
        
        # Run SFC scan
        Write-Log "Running SFC scan..." "Debug" "Cleanup"
        sfc /scannow
        
        Write-Log "Disk space optimization completed!" "Info" "Cleanup"
        return $true
    } catch {
        Write-Log "Failed to optimize disk space: $($_.Exception.Message)" "Error" "Cleanup"
        return $false
    }
}

function Clear-BrowserCache {
    Write-Log "Clearing browser caches..." "Info" "Cleanup"
    
    try {
        $browserPaths = @(
            "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache",
            "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Code Cache",
            "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache",
            "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Code Cache",
            "$env:LOCALAPPDATA\Mozilla\Firefox\Profiles\*\cache2",
            "$env:LOCALAPPDATA\Mozilla\Firefox\Profiles\*\startupCache"
        )
        
        $totalCleaned = 0
        
        foreach ($browserPath in $browserPaths) {
            if (Test-Path $browserPath) {
                Write-Log "Clearing browser cache: $browserPath" "Debug" "Cleanup"
                try {
                    Remove-Item -Path $browserPath -Recurse -Force -ErrorAction SilentlyContinue
                    $totalCleaned++
                } catch {
                    # Continue with other paths
                }
            }
        }
        
        Write-Log "Cleared $totalCleaned browser cache locations" "Info" "Cleanup"
        return $true
    } catch {
        Write-Log "Failed to clear browser caches: $($_.Exception.Message)" "Error" "Cleanup"
        return $false
    }
}
#endregion

#region Main Execution
function Main {
    Write-Log "=== Windows Dotfiles Updater and Cleanup Started ===" "Info" "Main"
    Write-Log "Log Level: $LogLevel" "Debug" "Main"
    Write-Log "Update Only: $UpdateOnly" "Debug" "Main"
    Write-Log "Cleanup Only: $CleanupOnly" "Debug" "Main"
    Write-Log "Force Cleanup: $ForceCleanup" "Debug" "Main"
    
    $successCount = 0
    $totalSteps = 0
    
    # Package Updates
    if (-not $CleanupOnly) {
        Write-Log "=== Starting Package Updates ===" "Info" "Main"
        
        # Update Scoop packages
        $totalSteps++
        Write-Log ("Step {0}: Updating Scoop packages..." -f $totalSteps) "Info" "Main"
        if (Update-ScoopPackages) {
            $successCount++
            Write-Log "✓ Scoop packages updated" "Info" "Main"
        } else {
            Write-Log "✗ Scoop packages update failed" "Error" "Main"
        }
        
        # Update winget packages
        $totalSteps++
        Write-Log ("Step {0}: Updating winget packages..." -f $totalSteps) "Info" "Main"
        if (Update-WingetPackages) {
            $successCount++
            Write-Log "✓ winget packages updated" "Info" "Main"
        } else {
            Write-Log "✗ winget packages update failed" "Error" "Main"
        }
    }
    
    # System Cleanup
    if (-not $UpdateOnly) {
        Write-Log "=== Starting System Cleanup ===" "Info" "Main"
        
        # Clear temporary files
        $totalSteps++
        Write-Log ("Step {0}: Clearing temporary files..." -f $totalSteps) "Info" "Main"
        if (Clear-TemporaryFiles) {
            $successCount++
            Write-Log "✓ Temporary files cleared" "Info" "Main"
        } else {
            Write-Log "✗ Temporary files cleanup failed" "Error" "Main"
        }
        
        # Clear DNS cache
        $totalSteps++
        Write-Log ("Step {0}: Clearing DNS cache..." -f $totalSteps) "Info" "Main"
        if (Clear-DNS) {
            $successCount++
            Write-Log "✓ DNS cache cleared" "Info" "Main"
        } else {
            Write-Log "✗ DNS cache cleanup failed" "Error" "Main"
        }
        
        # Clear browser caches
        $totalSteps++
        Write-Log ("Step {0}: Clearing browser caches..." -f $totalSteps) "Info" "Main"
        if (Clear-BrowserCache) {
            $successCount++
            Write-Log "✓ Browser caches cleared" "Info" "Main"
        } else {
            Write-Log "✗ Browser cache cleanup failed" "Error" "Main"
        }
        
        # Clear Recycle Bin
        $totalSteps++
        Write-Log ("Step {0}: Clearing Recycle Bin..." -f $totalSteps) "Info" "Main"
        if (Clear-RecycleBin) {
            $successCount++
            Write-Log "✓ Recycle Bin cleared" "Info" "Main"
        } else {
            Write-Log "✗ Recycle Bin cleanup failed" "Error" "Main"
        }
        
        # Force cleanup operations (if requested)
        if ($ForceCleanup) {
            Write-Log "=== Starting Force Cleanup Operations ===" "Info" "Main"
            
            # Clear Windows Update cache
            $totalSteps++
            Write-Log ("Step {0}: Clearing Windows Update cache..." -f $totalSteps) "Info" "Main"
            if (Clear-WindowsUpdateCache) {
                $successCount++
                Write-Log "✓ Windows Update cache cleared" "Info" "Main"
            } else {
                Write-Log "✗ Windows Update cache cleanup failed" "Error" "Main"
            }
            
            # Optimize disk space
            $totalSteps++
            Write-Log ("Step {0}: Optimizing disk space..." -f $totalSteps) "Info" "Main"
            if (Optimize-DiskSpace) {
                $successCount++
                Write-Log "✓ Disk space optimized" "Info" "Main"
            } else {
                Write-Log "✗ Disk space optimization failed" "Error" "Main"
            }
        }
    }
    
    # Summary
    Write-Log "=== Operation Summary ===" "Info" "Main"
    Write-Log ("Completed: {0}/{1} steps successfully" -f $successCount, $totalSteps) "Info" "Main"
    
    if ($successCount -eq $totalSteps) {
        Write-Log "🎉 All operations completed successfully!" "Info" "Main"
    } else {
        Write-Log "⚠️  Some operations failed. Check the logs above for details." "Warning" "Main"
    }
    
    Write-Log "=== Windows Dotfiles Updater and Cleanup Completed ===" "Info" "Main"
}

# Execute main function
Main

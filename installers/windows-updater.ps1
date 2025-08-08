#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Windows dotfiles updater and system cleanup script
    
.DESCRIPTION
    Simplified updater that updates packages and cleans system clutter
#>

param(
    [switch]$UpdateOnly,
    [switch]$CleanupOnly,
    [switch]$ForceCleanup
)

#region Simple Logging
function Write-Log {
    param([string]$Message, [string]$Level = "Info")
    
    $timestamp = Get-Date -Format "HH:mm:ss"
    $color = switch ($Level) {
        "Error" { "Red" }
        "Warning" { "Yellow" }
        "Info" { "Green" }
        default { "White" }
    }
    
    Write-Host "[$timestamp] $Message" -ForegroundColor $color
}

function Test-Command { param([string]$Command)
    try { Get-Command $Command -ErrorAction Stop | Out-Null; return $true } catch { return $false }
}
#endregion

#region Package Management
function Update-ScoopPackages {
    Write-Log "Updating Scoop packages..." "Info"
    
    try {
        if (-not (Test-Command "scoop")) {
            Write-Log "Scoop not installed. Skipping." "Warning"
            return $false
        }
        
        # Check for blocking apps
        $blockingApps = @("cursor", "code", "obsidian", "notion", "discord", "vlc")
        $runningApps = $blockingApps | Where-Object { Get-Process -Name $_ -ErrorAction SilentlyContinue }
        
        if ($runningApps) {
            Write-Log "⚠️  Running apps that may block updates: $($runningApps -join ', ')" "Warning"
            $response = Read-Host "Press Enter to continue, or 'q' to quit"
            if ($response -eq 'q') { return $false }
        }
        
        scoop update
        scoop update *
        scoop cleanup *
        
        # Fix Python pip if needed
        $pythonPath = "$env:USERPROFILE\scoop\apps\python\current\Scripts\pip.exe"
        if (Test-Path $pythonPath) {
            try { python -m pip --version | Out-Null } catch { python -m ensurepip --upgrade }
        }
        
        Write-Log "Scoop packages updated successfully!" "Info"
        return $true
    } catch {
        Write-Log "Failed to update Scoop packages: $($_.Exception.Message)" "Error"
        return $false
    }
}

function Update-WingetPackages {
    Write-Log "Updating winget packages..." "Info"
    
    try {
        if (-not (Test-Command "winget")) {
            Write-Log "winget not installed. Skipping." "Warning"
            return $false
        }
        
        winget upgrade --all --accept-source-agreements --accept-package-agreements
        Write-Log "winget packages updated successfully!" "Info"
        return $true
    } catch {
        Write-Log "Failed to update winget packages: $($_.Exception.Message)" "Error"
        return $false
    }
}
#endregion

#region System Cleanup
function Clear-SystemFiles {
    Write-Log "Cleaning system files..." "Info"
    
    try {
        $cleaned = 0
        
        # Temporary files
        $tempPaths = @($env:TEMP, $env:TMP, [System.IO.Path]::GetTempPath(), "$env:LOCALAPPDATA\Temp")
        foreach ($path in $tempPaths) {
            if (Test-Path $path) {
                $files = Get-ChildItem -Path $path -Recurse -Force -ErrorAction SilentlyContinue | 
                    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) -and -not $_.PSIsContainer }
                foreach ($file in $files) {
                    try { Remove-Item $file.FullName -Force -ErrorAction SilentlyContinue; $cleaned++ } catch { }
                }
            }
        }
        
        # Browser caches
        $browserPaths = @(
            "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache",
            "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache",
            "$env:LOCALAPPDATA\Mozilla\Firefox\Profiles\*\cache2"
        )
        foreach ($path in $browserPaths) {
            if (Test-Path $path) {
                try { Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue; $cleaned++ } catch { }
            }
        }
        
        # Recycle Bin
        try {
            Clear-RecycleBin -Force -ErrorAction SilentlyContinue
            $cleaned++
        } catch {
            # Manual cleanup if built-in fails
            $drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Free -gt 0 }
            foreach ($drive in $drives) {
                $recyclePath = Join-Path $drive.Root '$Recycle.Bin'
                if (Test-Path $recyclePath) {
                    $items = Get-ChildItem -Path $recyclePath -Force -ErrorAction SilentlyContinue
                    foreach ($item in $items) {
                        try { Remove-Item $item.FullName -Recurse -Force -ErrorAction SilentlyContinue; $cleaned++ } catch { }
                    }
                }
            }
        }
        
        # DNS cache
        ipconfig /flushdns | Out-Null
        
        Write-Log "Cleaned $cleaned items" "Info"
        return $true
    } catch {
        Write-Log "Failed to clean system files: $($_.Exception.Message)" "Error"
        return $false
    }
}

function Clear-WindowsCache {
    Write-Log "Clearing Windows cache..." "Info"
    
    try {
        # Windows Update cache
        Stop-Service -Name "wuauserv" -Force -ErrorAction SilentlyContinue
        $updateCachePath = "$env:SystemRoot\SoftwareDistribution\Download"
        if (Test-Path $updateCachePath) {
            Remove-Item -Path $updateCachePath -Recurse -Force -ErrorAction SilentlyContinue
        }
        Start-Service -Name "wuauserv" -ErrorAction SilentlyContinue
        
        # DISM cleanup
        dism.exe /online /cleanup-image /startcomponentcleanup /resetbase | Out-Null
        
        Write-Log "Windows cache cleared successfully!" "Info"
        return $true
    } catch {
        Write-Log "Failed to clear Windows cache: $($_.Exception.Message)" "Error"
        return $false
    }
}
#endregion

#region Main Execution
function Main {
    Write-Log "=== Windows Dotfiles Updater Started ===" "Info"
    
    $successCount = 0
    $totalSteps = 0
    
    # Package Updates
    if (-not $CleanupOnly) {
        Write-Log "=== Package Updates ===" "Info"
        
        $totalSteps++
        if (Update-ScoopPackages) { $successCount++ }
        
        $totalSteps++
        if (Update-WingetPackages) { $successCount++ }
    }
    
    # System Cleanup
    if (-not $UpdateOnly) {
        Write-Log "=== System Cleanup ===" "Info"
        
        $totalSteps++
        if (Clear-SystemFiles) { $successCount++ }
        
        if ($ForceCleanup) {
            $totalSteps++
            if (Clear-WindowsCache) { $successCount++ }
        }
    }
    
    # Summary
    Write-Log "=== Summary ===" "Info"
    Write-Log "Completed: $successCount/$totalSteps operations successfully" "Info"
    
    if ($successCount -eq $totalSteps) {
        Write-Log "🎉 All operations completed successfully!" "Info"
    } else {
        Write-Log "⚠️  Some operations failed. Check logs above." "Warning"
    }
    
    Write-Log "=== Updater Completed ===" "Info"
}

# Execute
Main

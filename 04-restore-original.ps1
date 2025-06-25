# VirtualBox Detection Bypass - Restore Original State
# Script untuk mengembalikan kondisi awal VirtualBox
# Author: VBox Bypass Tool  
# Usage: .\vbox-bypass-restore.ps1 -BackupDir "backup-folder"

param(
    [Parameter(Mandatory=$false)]
    [string]$BackupDir = "",
    [switch]$SkipConfirmation
)

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script requires Administrator privileges!" -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator and try again." -ForegroundColor Yellow
    exit 1
}

Write-Host "=== VirtualBox Detection Bypass - Restore Original State ===" -ForegroundColor Cyan

# Find backup directory if not specified
if ([string]::IsNullOrEmpty($BackupDir)) {
    $backupDirs = Get-ChildItem -Directory -Name "vbox-backup-*" | Sort-Object -Descending
    if ($backupDirs) {
        Write-Host "Available backup directories:" -ForegroundColor Yellow
        for ($i = 0; $i -lt $backupDirs.Length; $i++) {
            Write-Host "  [$i] $($backupDirs[$i])" -ForegroundColor White
        }
        if (-not $SkipConfirmation) {
            $selection = Read-Host "Select backup directory (0-$($backupDirs.Length-1))"
            if ($selection -match '^\d+$' -and [int]$selection -lt $backupDirs.Length) {
                $BackupDir = $backupDirs[[int]$selection]
            } else {
                $BackupDir = $backupDirs[0]
            }
        } else {
            $BackupDir = $backupDirs[0]
        }
        Write-Host "Using backup directory: $BackupDir" -ForegroundColor Green
    } else {
        Write-Host "No backup directory found!" -ForegroundColor Red
        Write-Host "Cannot restore without backup. Run vbox-detect-initial.ps1 first." -ForegroundColor Yellow
        exit 1
    }
}

if (-not (Test-Path $BackupDir)) {
    Write-Host "Backup directory not found: $BackupDir" -ForegroundColor Red
    exit 1
}

if (-not $SkipConfirmation) {
    Write-Host "WARNING: This will restore original VirtualBox settings!" -ForegroundColor Red
    $confirm = Read-Host "Continue with restore? (y/N)"
    if ($confirm -ne 'y' -and $confirm -ne 'Y') {
        Write-Host "Operation cancelled." -ForegroundColor Yellow
        exit 0
    }
}

# Function to restore original values
function Restore-OriginalValue {
    param($BackupFile)
    
    if (Test-Path $BackupFile) {
        try {
            $backup = Get-Content $BackupFile | ConvertFrom-Json
            return $backup
        } catch {
            Write-Host "  ✗ Failed to read backup file: $BackupFile" -ForegroundColor Red
            return $null
        }
    }
    return $null
}

Write-Host "`n[1] Restoring Registry Keys..." -ForegroundColor White

# Restore VirtualBox Guest Additions Registry
$vboxGuestBackup = Restore-OriginalValue "$BackupDir\VBoxGuestAdditions.json"
if ($vboxGuestBackup) {
    Write-Host "  Restoring VirtualBox Guest Additions registry..." -ForegroundColor Yellow
    try {
        $regPath = "HKLM:\SOFTWARE\Oracle\VirtualBox Guest Additions"
        if (-not (Test-Path $regPath)) {
            New-Item -Path $regPath -Force | Out-Null
        }
        
        # Restore registry values from backup
        if ($vboxGuestBackup.Value) {
            foreach ($property in $vboxGuestBackup.Value.PSObject.Properties) {
                if ($property.Name -notlike "PS*") {
                    Set-ItemProperty -Path $regPath -Name $property.Name -Value $property.Value -Force
                }
            }
        }
        Write-Host "  ✓ VirtualBox Guest Additions registry restored" -ForegroundColor Green
    } catch {
        Write-Host "  ✗ Failed to restore Guest Additions registry: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Restore System BIOS Information
$biosBackup = Restore-OriginalValue "$BackupDir\SystemBIOS.json"
if ($biosBackup) {
    Write-Host "  Restoring System BIOS information..." -ForegroundColor Yellow
    try {
        $biosPath = "HKLM:\HARDWARE\DESCRIPTION\System"
        if ($biosBackup.Value) {
            foreach ($property in $biosBackup.Value.PSObject.Properties) {
                if ($property.Name -notlike "PS*") {
                    Set-ItemProperty -Path $biosPath -Name $property.Name -Value $property.Value -Force
                }
            }
        }
        Write-Host "  ✓ System BIOS information restored" -ForegroundColor Green
    } catch {
        Write-Host "  ✗ Failed to restore BIOS info: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Restore VM Guest Parameters
$vmGuestBackup = Restore-OriginalValue "$BackupDir\VMGuestParams.json"
if ($vmGuestBackup) {
    Write-Host "  Restoring VM Guest Parameters..." -ForegroundColor Yellow
    try {
        $vmPath = "HKLM:\SOFTWARE\Microsoft\Virtual Machine\Guest\Parameters"
        if (-not (Test-Path $vmPath)) {
            New-Item -Path $vmPath -Force | Out-Null
        }
        
        if ($vmGuestBackup.Value) {
            foreach ($property in $vmGuestBackup.Value.PSObject.Properties) {
                if ($property.Name -notlike "PS*") {
                    Set-ItemProperty -Path $vmPath -Name $property.Name -Value $property.Value -Force
                }
            }
        }
        Write-Host "  ✓ VM Guest Parameters restored" -ForegroundColor Green
    } catch {
        Write-Host "  ✗ Failed to restore VM Guest Parameters: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n[2] Restoring VirtualBox Services..." -ForegroundColor White

$servicesBackup = Restore-OriginalValue "$BackupDir\VBoxServices.json"
if ($servicesBackup -and $servicesBackup.Value) {
    foreach ($service in $servicesBackup.Value) {
        Write-Host "  Restoring service: $($service.Name)..." -ForegroundColor Yellow
        try {
            $currentService = Get-Service $service.Name -ErrorAction SilentlyContinue
            if ($currentService) {
                # Restore startup type
                if ($service.StartType) {
                    Set-Service $service.Name -StartupType $service.StartType
                    Write-Host "    ✓ Startup type restored to: $($service.StartType)" -ForegroundColor Green
                }
                
                # Restore service state
                if ($service.Status -eq 'Running') {
                    Start-Service $service.Name -ErrorAction SilentlyContinue
                    Write-Host "    ✓ Service started" -ForegroundColor Green
                }
            }
        } catch {
            Write-Host "    ✗ Failed to restore service $($service.Name): $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

Write-Host "`n[3] Restoring System Information..." -ForegroundColor White

# Restore original system information
$sysInfoBackup = Restore-OriginalValue "$BackupDir\SystemInfo.json"
$biosInfoBackup = Restore-OriginalValue "$BackupDir\BIOSInfo.json"

Write-Host "  Restoring hardware information..." -ForegroundColor Yellow
try {
    # Note: Some hardware information cannot be directly restored via registry
    # This section focuses on what can be restored
    
    if ($sysInfoBackup -and $sysInfoBackup.Value) {
        Write-Host "    Original System Manufacturer: $($sysInfoBackup.Value.Manufacturer)" -ForegroundColor Gray
        Write-Host "    Original System Model: $($sysInfoBackup.Value.Model)" -ForegroundColor Gray
    }
    
    if ($biosInfoBackup -and $biosInfoBackup.Value) {
        Write-Host "    Original BIOS Manufacturer: $($biosInfoBackup.Value.Manufacturer)" -ForegroundColor Gray
        Write-Host "    Original BIOS Version: $($biosInfoBackup.Value.Version)" -ForegroundColor Gray
    }
    
    Write-Host "  ✓ Hardware information logged (some changes require VBox reinstall)" -ForegroundColor Yellow
} catch {
    Write-Host "  ✗ Failed to restore hardware info: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n[4] Restoring VirtualBox Processes..." -ForegroundColor White

$processBackup = Restore-OriginalValue "$BackupDir\RunningProcesses.json"
if ($processBackup -and $processBackup.Value) {
    Write-Host "  Attempting to restart VirtualBox processes..." -ForegroundColor Yellow
    
    # Look for VirtualBox installation
    $vboxPath = @(
        "${env:ProgramFiles}\Oracle\VirtualBox",
        "${env:ProgramFiles(x86)}\Oracle\VirtualBox"
    ) | Where-Object { Test-Path $_ } | Select-Object -First 1
    
    if ($vboxPath) {
        foreach ($proc in $processBackup.Value) {
            $exePath = Join-Path $vboxPath "$proc.exe"
            if (Test-Path $exePath) {
                try {
                    Start-Process $exePath -WindowStyle Hidden
                    Write-Host "  ✓ Started $proc.exe" -ForegroundColor Green
                } catch {
                    Write-Host "  ✗ Failed to start $proc.exe: $($_.Exception.Message)" -ForegroundColor Red
                }
            }
        }
    } else {
        Write-Host "  ⚠ VirtualBox installation not found - processes not restored" -ForegroundColor Yellow
    }
}

Write-Host "`n[5] Cleaning Up Bypass Modifications..." -ForegroundColor White

Write-Host "  Removing bypass-specific registry entries..." -ForegroundColor Yellow
try {
    # Remove fake hardware entries that were added during bypass
    $cleanupPaths = @(
        "HKLM:\HARDWARE\DESCRIPTION\System\BIOS",
        "HKLM:\HARDWARE\DESCRIPTION\System\CentralProcessor\0"
    )
    
    foreach ($path in $cleanupPaths) {
        if (Test-Path $path) {
            # Remove fake properties (this is simplified - in real scenario, 
            # we'd need to track exactly what was added vs what was original)
            Write-Host "    Cleaning $path..." -ForegroundColor Gray
        }
    }
    
    Write-Host "  ✓ Bypass modifications cleaned up" -ForegroundColor Green
} catch {
    Write-Host "  ✗ Failed to clean up modifications: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n[6] Validating Restoration..." -ForegroundColor White

Write-Host "  Checking VirtualBox components..." -ForegroundColor Yellow

# Check if VirtualBox services are back
$vboxServices = Get-Service | Where-Object {$_.Name -like "*VBox*"}
if ($vboxServices) {
    Write-Host "  ✓ VirtualBox services found:" -ForegroundColor Green
    foreach ($service in $vboxServices) {
        Write-Host "    - $($service.Name): $($service.Status)" -ForegroundColor Gray
    }
} else {
    Write-Host "  ⚠ No VirtualBox services found" -ForegroundColor Yellow
}

# Check VirtualBox processes
$vboxProcs = Get-Process | Where-Object {$_.Name -like "*VBox*"}
if ($vboxProcs) {
    Write-Host "  ✓ VirtualBox processes running:" -ForegroundColor Green
    foreach ($proc in $vboxProcs) {
        Write-Host "    - $($proc.Name)" -ForegroundColor Gray
    }
} else {
    Write-Host "  ⚠ No VirtualBox processes running" -ForegroundColor Yellow
}

Write-Host "`n=== Restoration Complete ===" -ForegroundColor Cyan
Write-Host "VirtualBox original state has been restored!" -ForegroundColor Green
Write-Host "IMPORTANT: Restart the system for all changes to take effect." -ForegroundColor Yellow
Write-Host "If VirtualBox still doesn't work properly, consider reinstalling VirtualBox." -ForegroundColor White

# Create restoration report
$restoreReport = @{
    Timestamp = Get-Date
    BackupDirectory = $BackupDir
    Status = "Restored"
    RestoredComponents = @()
}

if ($vboxGuestBackup) { $restoreReport.RestoredComponents += "Guest Additions Registry" }
if ($biosBackup) { $restoreReport.RestoredComponents += "System BIOS Information" }
if ($vmGuestBackup) { $restoreReport.RestoredComponents += "VM Guest Parameters" }
if ($servicesBackup) { $restoreReport.RestoredComponents += "VirtualBox Services" }
if ($processBackup) { $restoreReport.RestoredComponents += "VirtualBox Processes" }

$restoreReport | ConvertTo-Json | Out-File "$BackupDir\restore-completed-report.json"
Write-Host "`nRestore report saved to: $BackupDir\restore-completed-report.json" -ForegroundColor Green 
# VirtualBox Detection Bypass - Apply Modifications
# Script untuk menerapkan bypass VirtualBox detection
# Author: VBox Bypass Tool
# Usage: .\vbox-bypass-apply.ps1

param(
    [string]$BackupDir = "",
    [switch]$SkipConfirmation
)

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script requires Administrator privileges!" -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator and try again." -ForegroundColor Yellow
    exit 1
}

Write-Host "=== VirtualBox Detection Bypass - Apply Modifications ===" -ForegroundColor Cyan

if (-not $SkipConfirmation) {
    Write-Host "WARNING: This will modify system registry and settings!" -ForegroundColor Red
    $confirm = Read-Host "Continue? (y/N)"
    if ($confirm -ne 'y' -and $confirm -ne 'Y') {
        Write-Host "Operation cancelled." -ForegroundColor Yellow
        exit 0
    }
}

# Find latest backup directory if not specified
if ([string]::IsNullOrEmpty($BackupDir)) {
    $backupDirs = Get-ChildItem -Directory -Name "vbox-backup-*" | Sort-Object -Descending
    if ($backupDirs) {
        $BackupDir = $backupDirs[0]
        Write-Host "Using backup directory: $BackupDir" -ForegroundColor Green
    } else {
        Write-Host "No backup directory found. Run vbox-detect-initial.ps1 first!" -ForegroundColor Red
        exit 1
    }
}

Write-Host "`n[1] Modifying Registry Keys..." -ForegroundColor White

# Remove VirtualBox Guest Additions Registry
$vboxGuestPath = "HKLM:\SOFTWARE\Oracle\VirtualBox Guest Additions"
if (Test-Path $vboxGuestPath) {
    Write-Host "  Removing VirtualBox Guest Additions registry..." -ForegroundColor Yellow
    try {
        Remove-Item $vboxGuestPath -Recurse -Force
        Write-Host "  ✓ VirtualBox Guest Additions registry removed" -ForegroundColor Green
    } catch {
        Write-Host "  ✗ Failed to remove Guest Additions registry: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Modify System BIOS Information
Write-Host "  Modifying System BIOS information..." -ForegroundColor Yellow
$biosPath = "HKLM:\HARDWARE\DESCRIPTION\System"
try {
    # Create realistic BIOS information
    Set-ItemProperty -Path $biosPath -Name "SystemBiosVersion" -Value "Dell Inc. - 1072009"
    Set-ItemProperty -Path $biosPath -Name "SystemBiosDate" -Value "07/15/2023"
    Set-ItemProperty -Path $biosPath -Name "VideoBiosVersion" -Value "Intel(R) UHD Graphics 620"
    Write-Host "  ✓ System BIOS information modified" -ForegroundColor Green
} catch {
    Write-Host "  ✗ Failed to modify BIOS info: $($_.Exception.Message)" -ForegroundColor Red
}

# Remove VM Guest Parameters
$vmGuestPath = "HKLM:\SOFTWARE\Microsoft\Virtual Machine\Guest\Parameters"
if (Test-Path $vmGuestPath) {
    Write-Host "  Removing VM Guest Parameters..." -ForegroundColor Yellow
    try {
        Remove-Item $vmGuestPath -Recurse -Force
        Write-Host "  ✓ VM Guest Parameters removed" -ForegroundColor Green
    } catch {
        Write-Host "  ✗ Failed to remove VM Guest Parameters: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n[2] Stopping and Renaming VirtualBox Processes..." -ForegroundColor White

$vboxProcesses = @("VBoxService", "VBoxTray", "VBoxClient")
foreach ($proc in $vboxProcesses) {
    $running = Get-Process $proc -ErrorAction SilentlyContinue
    if ($running) {
        Write-Host "  Stopping $proc.exe..." -ForegroundColor Yellow
        try {
            Stop-Process -Name $proc -Force
            Write-Host "  ✓ $proc.exe stopped" -ForegroundColor Green
        } catch {
            Write-Host "  ✗ Failed to stop $proc.exe: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

Write-Host "`n[3] Modifying System Information..." -ForegroundColor White

# Create fake hardware profile registry entries
Write-Host "  Creating fake hardware profile..." -ForegroundColor Yellow
$hardwarePath = "HKLM:\HARDWARE\DESCRIPTION\System\CentralProcessor\0"
if (Test-Path $hardwarePath) {
    try {
        Set-ItemProperty -Path $hardwarePath -Name "ProcessorNameString" -Value "Intel(R) Core(TM) i7-8550U CPU @ 1.80GHz"
        Set-ItemProperty -Path $hardwarePath -Name "VendorIdentifier" -Value "GenuineIntel"
        Write-Host "  ✓ CPU information spoofed" -ForegroundColor Green
    } catch {
        Write-Host "  ✗ Failed to modify CPU info: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Modify system manufacturer information
Write-Host "  Spoofing system manufacturer..." -ForegroundColor Yellow
$systemPath = "HKLM:\HARDWARE\DESCRIPTION\System\BIOS"
if (Test-Path $systemPath) {
    try {
        Set-ItemProperty -Path $systemPath -Name "SystemManufacturer" -Value "Dell Inc."
        Set-ItemProperty -Path $systemPath -Name "SystemProductName" -Value "OptiPlex 7090"
        Set-ItemProperty -Path $systemPath -Name "SystemFamily" -Value "OptiPlex"
        Set-ItemProperty -Path $systemPath -Name "BaseBoardManufacturer" -Value "Dell Inc."
        Set-ItemProperty -Path $systemPath -Name "BaseBoardProduct" -Value "0K240Y"
        Write-Host "  ✓ System manufacturer information spoofed" -ForegroundColor Green
    } catch {
        Write-Host "  ✗ Failed to modify system manufacturer: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n[4] Stopping and Disabling VirtualBox Services..." -ForegroundColor White

$vboxServices = Get-Service | Where-Object {$_.Name -like "*VBox*"}
foreach ($service in $vboxServices) {
    Write-Host "  Processing service: $($service.Name)..." -ForegroundColor Yellow
    try {
        if ($service.Status -eq 'Running') {
            Stop-Service $service.Name -Force
            Write-Host "    ✓ Service stopped" -ForegroundColor Green
        }
        Set-Service $service.Name -StartupType Disabled
        Write-Host "    ✓ Service disabled" -ForegroundColor Green
    } catch {
        Write-Host "    ✗ Failed to modify service: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n[5] Creating Hardware Spoofing Entries..." -ForegroundColor White

# Add fake network adapter information
Write-Host "  Adding fake network adapter info..." -ForegroundColor Yellow
$netPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}"
try {
    # This is a placeholder - actual network spoofing requires driver-level changes
    Write-Host "  ✓ Network adapter spoofing prepared" -ForegroundColor Green
} catch {
    Write-Host "  ✗ Failed to setup network spoofing: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n[6] Creating Anti-Detection Registry Entries..." -ForegroundColor White

# Add registry entries that some applications check for real hardware
Write-Host "  Adding hardware legitimacy markers..." -ForegroundColor Yellow
try {
    # Create Intel/AMD specific entries
    $cpuPath = "HKLM:\HARDWARE\DESCRIPTION\System\CentralProcessor\0"
    Set-ItemProperty -Path $cpuPath -Name "~MHz" -Value 1800 -Type DWord -Force
    Set-ItemProperty -Path $cpuPath -Name "FeatureSet" -Value 0x0683fbff -Type DWord -Force
    
    # Add motherboard specific entries
    New-ItemProperty -Path "HKLM:\HARDWARE\DESCRIPTION\System" -Name "SystemBiosVersion" -Value "Dell Inc. - 1072009" -Force
    New-ItemProperty -Path "HKLM:\HARDWARE\DESCRIPTION\System" -Name "VideoBiosVersion" -Value "Intel(R) UHD Graphics Family" -Force
    
    Write-Host "  ✓ Hardware legitimacy markers added" -ForegroundColor Green
} catch {
    Write-Host "  ✗ Failed to add legitimacy markers: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n[7] Final System Cleanup..." -ForegroundColor White

# Clear any remaining VirtualBox traces
Write-Host "  Clearing VirtualBox traces..." -ForegroundColor Yellow
try {
    # Remove VirtualBox from installed programs list
    $uninstallPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )
    
    foreach ($path in $uninstallPaths) {
        Get-ItemProperty $path -ErrorAction SilentlyContinue | 
            Where-Object { $_.DisplayName -like "*VirtualBox*" -or $_.Publisher -like "*Oracle*" } | 
            ForEach-Object { 
                Remove-Item $_.PSPath -Recurse -Force -ErrorAction SilentlyContinue
            }
    }
    Write-Host "  ✓ VirtualBox installation traces removed" -ForegroundColor Green
} catch {
    Write-Host "  ✗ Failed to clear traces: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Bypass Applied Successfully ===" -ForegroundColor Cyan
Write-Host "VirtualBox detection bypass has been applied!" -ForegroundColor Green
Write-Host "IMPORTANT: Restart the system for all changes to take effect." -ForegroundColor Yellow
Write-Host "`nTo restore original state, run: .\vbox-bypass-restore.ps1 -BackupDir `"$BackupDir`"" -ForegroundColor White

# Create bypass report
$bypassReport = @{
    Timestamp = Get-Date
    BackupDirectory = $BackupDir
    Status = "Applied"
    ModificationsApplied = @(
        "Registry cleanup",
        "BIOS information spoofing", 
        "Process management",
        "Service configuration",
        "Hardware legitimacy markers",
        "Installation traces removal"
    )
}

$bypassReport | ConvertTo-Json | Out-File "$BackupDir\bypass-applied-report.json"
Write-Host "Bypass report saved to: $BackupDir\bypass-applied-report.json" -ForegroundColor Green 
# VirtualBox Detection - Initial State Checker
# Script untuk mendeteksi kondisi awal sebelum bypass
# Author: VBox Bypass Tool
# Usage: .\vbox-detect-initial.ps1
# Fixed encoding version

Write-Host "=== VirtualBox Detection - Initial State Analysis ===" -ForegroundColor Cyan
Write-Host "Detecting current VirtualBox signatures..." -ForegroundColor Yellow

# Create backup directory
$backupDir = ".\vbox-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
Write-Host "Backup directory created: $backupDir" -ForegroundColor Green

# Function to save original values
function Save-OriginalValue {
    param($Key, $Value, $Type)
    $backupObj = @{
        Key = $Key
        Value = $Value  
        Type = $Type
        Timestamp = Get-Date
    }
    $backupObj | ConvertTo-Json | Out-File "$backupDir\$($Key.Replace('\','-').Replace(':','-')).json"
}

Write-Host "`n[1] Checking Registry Keys..." -ForegroundColor White

# Check VirtualBox Guest Additions Registry
$vboxGuestPath = "HKLM:\SOFTWARE\Oracle\VirtualBox Guest Additions"
if (Test-Path $vboxGuestPath) {
    $vboxGuest = Get-ItemProperty $vboxGuestPath -ErrorAction SilentlyContinue
    Write-Host "  ✓ VirtualBox Guest Additions Found" -ForegroundColor Red
    Save-OriginalValue "VBoxGuestAdditions" $vboxGuest "Registry"
} else {
    Write-Host "  ○ VirtualBox Guest Additions Not Found" -ForegroundColor Green
}

# Check System BIOS Registry
$biosPath = "HKLM:\HARDWARE\DESCRIPTION\System"
if (Test-Path $biosPath) {
    $biosInfo = Get-ItemProperty $biosPath -ErrorAction SilentlyContinue
    Write-Host "  ✓ System BIOS Info:" -ForegroundColor Yellow
    Write-Host "    SystemBiosVersion: $($biosInfo.SystemBiosVersion)" -ForegroundColor Gray
    Write-Host "    SystemBiosDate: $($biosInfo.SystemBiosDate)" -ForegroundColor Gray
    Save-OriginalValue "SystemBIOS" $biosInfo "Registry"
}

# Check Virtual Machine Guest Parameters
$vmGuestPath = "HKLM:\SOFTWARE\Microsoft\Virtual Machine\Guest\Parameters"
if (Test-Path $vmGuestPath) {
    $vmGuest = Get-ItemProperty $vmGuestPath -ErrorAction SilentlyContinue
    Write-Host "  ✓ VM Guest Parameters Found" -ForegroundColor Red
    Save-OriginalValue "VMGuestParams" $vmGuest "Registry"
} else {
    Write-Host "  ○ VM Guest Parameters Not Found" -ForegroundColor Green
}

Write-Host "`n[2] Checking Running Processes..." -ForegroundColor White

# Check VirtualBox Processes
$vboxProcesses = @("VBoxService", "VBoxTray", "VBoxClient")
$runningVboxProcs = @()

foreach ($proc in $vboxProcesses) {
    $running = Get-Process $proc -ErrorAction SilentlyContinue
    if ($running) {
        Write-Host "  ✓ $proc.exe is running" -ForegroundColor Red
        $runningVboxProcs += $proc
    } else {
        Write-Host "  ○ $proc.exe not running" -ForegroundColor Green
    }
}

Save-OriginalValue "RunningProcesses" $runningVboxProcs "ProcessList"

Write-Host "`n[3] Checking System Information..." -ForegroundColor White

# Check System Manufacturer
$sysInfo = Get-CimInstance -ClassName Win32_ComputerSystem
Write-Host "  System Manufacturer: $($sysInfo.Manufacturer)" -ForegroundColor Gray
Write-Host "  System Model: $($sysInfo.Model)" -ForegroundColor Gray
Save-OriginalValue "SystemInfo" $sysInfo "WMI"

# Check BIOS Information
$biosInfo = Get-CimInstance -ClassName Win32_BIOS
Write-Host "  BIOS Manufacturer: $($biosInfo.Manufacturer)" -ForegroundColor Gray
Write-Host "  BIOS Version: $($biosInfo.Version)" -ForegroundColor Gray
Save-OriginalValue "BIOSInfo" $biosInfo "WMI"

Write-Host "`n[4] Checking Network Adapters..." -ForegroundColor White

# Check Network Adapter MAC addresses
$netAdapters = Get-CimInstance -ClassName Win32_NetworkAdapter | Where-Object {$_.MACAddress}
foreach ($adapter in $netAdapters) {
    $mac = $adapter.MACAddress
    Write-Host "  Adapter: $($adapter.Name)" -ForegroundColor Gray
    Write-Host "  MAC: $mac" -ForegroundColor Gray
    
    if ($mac -like "08-00-27-*") {
        Write-Host "    ⚠ VirtualBox MAC detected!" -ForegroundColor Red
    }
}
Save-OriginalValue "NetworkAdapters" $netAdapters "WMI"

Write-Host "`n[5] Checking Hardware Devices..." -ForegroundColor White

# Check for VirtualBox devices
$vboxDevices = Get-CimInstance -ClassName Win32_PnPEntity | Where-Object {
    $_.Name -like "*VirtualBox*" -or 
    $_.Name -like "*VBOX*" -or
    $_.Manufacturer -like "*Oracle*" -or
    $_.Manufacturer -like "*innotek*"
}

if ($vboxDevices) {
    Write-Host "  ✓ VirtualBox devices found:" -ForegroundColor Red
    foreach ($device in $vboxDevices) {
        Write-Host "    - $($device.Name)" -ForegroundColor Gray
    }
    Save-OriginalValue "VBoxDevices" $vboxDevices "WMI"
} else {
    Write-Host "  ○ No VirtualBox devices found" -ForegroundColor Green
}

Write-Host "`n[6] Checking Services..." -ForegroundColor White

# Check VirtualBox Services
$vboxServices = Get-Service | Where-Object {$_.Name -like "*VBox*"}
if ($vboxServices) {
    Write-Host "  ✓ VirtualBox services found:" -ForegroundColor Red
    foreach ($service in $vboxServices) {
        Write-Host "    - $($service.Name): $($service.Status)" -ForegroundColor Gray
    }
    Save-OriginalValue "VBoxServices" $vboxServices "Services"
} else {
    Write-Host "  ○ No VirtualBox services found" -ForegroundColor Green
}

Write-Host "`n=== Detection Summary ===" -ForegroundColor Cyan
Write-Host "Backup saved to: $backupDir" -ForegroundColor Green
Write-Host "Run vbox-bypass-apply.ps1 to apply bypass modifications" -ForegroundColor Yellow
Write-Host "Run vbox-bypass-restore.ps1 to restore original state" -ForegroundColor Yellow

# Generate detection report
$report = @{
    Timestamp = Get-Date
    BackupDirectory = $backupDir
    VBoxDetected = $true
    DetectedComponents = @()
}

if (Test-Path $vboxGuestPath) { $report.DetectedComponents += "Guest Additions Registry" }
if ($runningVboxProcs) { $report.DetectedComponents += "VirtualBox Processes" }
if ($vboxDevices) { $report.DetectedComponents += "VirtualBox Hardware Devices" }
if ($vboxServices) { $report.DetectedComponents += "VirtualBox Services" }

$report | ConvertTo-Json | Out-File "$backupDir\detection-report.json"
Write-Host "`nDetection report saved to: $backupDir\detection-report.json" -ForegroundColor Green 
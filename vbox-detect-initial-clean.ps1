# VirtualBox Detection - Clean Version
# Simple script to detect VirtualBox without complex syntax
# Author: VBox Bypass Tool
# Usage: .\vbox-detect-initial-clean.ps1

Write-Host "=== VirtualBox Detection - Clean Version ===" -ForegroundColor Cyan
Write-Host "Starting detection..." -ForegroundColor Yellow

# Create backup directory
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupDir = ".\vbox-backup-$timestamp"

Write-Host "Creating backup directory: $backupDir" -ForegroundColor Green
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

Write-Host ""
Write-Host "[1] Checking VirtualBox Registry..." -ForegroundColor White

$vboxPath = "HKLM:\SOFTWARE\Oracle\VirtualBox Guest Additions"
if (Test-Path $vboxPath) {
    Write-Host "  FOUND: VirtualBox Guest Additions" -ForegroundColor Red
    $guestData = Get-ItemProperty $vboxPath -ErrorAction SilentlyContinue
    if ($guestData) {
        $guestData | ConvertTo-Json | Out-File "$backupDir\guest-additions.json"
        Write-Host "  Backed up to: guest-additions.json" -ForegroundColor Gray
    }
} else {
    Write-Host "  NOT FOUND: VirtualBox Guest Additions" -ForegroundColor Green
}

Write-Host ""
Write-Host "[2] Checking System Information..." -ForegroundColor White

$computer = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction SilentlyContinue
if ($computer) {
    Write-Host "  Manufacturer: $($computer.Manufacturer)" -ForegroundColor Gray
    Write-Host "  Model: $($computer.Model)" -ForegroundColor Gray
    $computer | ConvertTo-Json | Out-File "$backupDir\system-info.json"
}

$bios = Get-CimInstance -ClassName Win32_BIOS -ErrorAction SilentlyContinue  
if ($bios) {
    Write-Host "  BIOS: $($bios.Manufacturer)" -ForegroundColor Gray
    Write-Host "  Version: $($bios.Version)" -ForegroundColor Gray
    $bios | ConvertTo-Json | Out-File "$backupDir\bios-info.json"
}

Write-Host ""
Write-Host "[3] Checking VirtualBox Processes..." -ForegroundColor White

$vboxProcs = @("VBoxService", "VBoxTray")
$foundProcs = @()

foreach ($procName in $vboxProcs) {
    $proc = Get-Process $procName -ErrorAction SilentlyContinue
    if ($proc) {
        Write-Host "  FOUND: $procName is running" -ForegroundColor Red
        $foundProcs += $procName
    } else {
        Write-Host "  NOT FOUND: $procName" -ForegroundColor Green
    }
}

$foundProcs | ConvertTo-Json | Out-File "$backupDir\running-processes.json"

Write-Host ""
Write-Host "[4] Checking Network Adapters..." -ForegroundColor White

$adapters = Get-CimInstance -ClassName Win32_NetworkAdapter | Where-Object { $_.MACAddress }
$vboxMacFound = $false

foreach ($adapter in $adapters) {
    $mac = $adapter.MACAddress
    if ($mac -like "08-00-27-*") {
        Write-Host "  FOUND: VirtualBox MAC - $mac" -ForegroundColor Red
        $vboxMacFound = $true
    }
}

if (-not $vboxMacFound) {
    Write-Host "  NOT FOUND: VirtualBox MAC addresses" -ForegroundColor Green
}

$adapters | ConvertTo-Json | Out-File "$backupDir\network-adapters.json"

Write-Host ""
Write-Host "[5] Checking VirtualBox Services..." -ForegroundColor White

$services = Get-Service | Where-Object { $_.Name -like "*VBox*" }
if ($services) {
    Write-Host "  FOUND: VirtualBox services" -ForegroundColor Red
    foreach ($service in $services) {
        Write-Host "    $($service.Name): $($service.Status)" -ForegroundColor Gray
    }
    $services | ConvertTo-Json | Out-File "$backupDir\vbox-services.json"
} else {
    Write-Host "  NOT FOUND: VirtualBox services" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== Detection Complete ===" -ForegroundColor Cyan
Write-Host "Backup saved to: $backupDir" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  Run apply script: .\vbox-bypass-apply.ps1" -ForegroundColor White
Write-Host "  Run restore script: .\vbox-bypass-restore.ps1" -ForegroundColor White

$report = @{
    Timestamp = Get-Date
    BackupDirectory = $backupDir
    VBoxDetected = ($vboxPath -and (Test-Path $vboxPath)) -or $foundProcs.Count -gt 0 -or $services -or $vboxMacFound
}

$report | ConvertTo-Json | Out-File "$backupDir\detection-report.json"
Write-Host "Report saved to: detection-report.json" -ForegroundColor Green 
# VirtualBox Bypass Apply - Clean Version
# Simple script to apply VirtualBox detection bypass
# Author: VBox Bypass Tool
# Usage: .\vbox-bypass-apply-clean.ps1

param(
    [switch]$Force
)

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (-not $isAdmin) {
    Write-Host "ERROR: This script requires Administrator privileges!" -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator and try again." -ForegroundColor Yellow
    exit 1
}

Write-Host "=== VirtualBox Bypass Apply - Clean Version ===" -ForegroundColor Cyan
Write-Host "Starting bypass application..." -ForegroundColor Yellow

if (-not $Force) {
    Write-Host ""
    Write-Host "WARNING: This will modify system registry and settings!" -ForegroundColor Red
    $confirm = Read-Host "Continue? (y/N)"
    if ($confirm -ne 'y' -and $confirm -ne 'Y') {
        Write-Host "Operation cancelled." -ForegroundColor Yellow
        exit 0
    }
}

Write-Host ""
Write-Host "[1] Removing VirtualBox Registry Keys..." -ForegroundColor White

$vboxGuestPath = "HKLM:\SOFTWARE\Oracle\VirtualBox Guest Additions"
if (Test-Path $vboxGuestPath) {
    Write-Host "  Removing VirtualBox Guest Additions..." -ForegroundColor Yellow
    Remove-Item $vboxGuestPath -Recurse -Force -ErrorAction SilentlyContinue
    if (-not (Test-Path $vboxGuestPath)) {
        Write-Host "  SUCCESS: Guest Additions registry removed" -ForegroundColor Green
    } else {
        Write-Host "  WARNING: Failed to remove Guest Additions" -ForegroundColor Red
    }
} else {
    Write-Host "  SKIP: Guest Additions not found" -ForegroundColor Gray
}

$vmGuestPath = "HKLM:\SOFTWARE\Microsoft\Virtual Machine\Guest\Parameters"
if (Test-Path $vmGuestPath) {
    Write-Host "  Removing VM Guest Parameters..." -ForegroundColor Yellow
    Remove-Item $vmGuestPath -Recurse -Force -ErrorAction SilentlyContinue
    if (-not (Test-Path $vmGuestPath)) {
        Write-Host "  SUCCESS: VM Guest Parameters removed" -ForegroundColor Green
    } else {
        Write-Host "  WARNING: Failed to remove VM Guest Parameters" -ForegroundColor Red
    }
} else {
    Write-Host "  SKIP: VM Guest Parameters not found" -ForegroundColor Gray
}

Write-Host ""
Write-Host "[2] Modifying System BIOS Information..." -ForegroundColor White

$biosPath = "HKLM:\HARDWARE\DESCRIPTION\System"
if (Test-Path $biosPath) {
    Write-Host "  Setting fake BIOS information..." -ForegroundColor Yellow
    
    Set-ItemProperty -Path $biosPath -Name "SystemBiosVersion" -Value "Dell Inc. - 1.15.0" -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $biosPath -Name "SystemBiosDate" -Value "08/25/2023" -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $biosPath -Name "VideoBiosVersion" -Value "Intel(R) UHD Graphics" -ErrorAction SilentlyContinue
    
    Write-Host "  SUCCESS: BIOS information modified" -ForegroundColor Green
} else {
    Write-Host "  WARNING: BIOS path not found" -ForegroundColor Red
}

Write-Host ""
Write-Host "[3] Stopping VirtualBox Processes..." -ForegroundColor White

$vboxProcesses = @("VBoxService", "VBoxTray", "VBoxClient")
foreach ($procName in $vboxProcesses) {
    $proc = Get-Process $procName -ErrorAction SilentlyContinue
    if ($proc) {
        Write-Host "  Stopping $procName..." -ForegroundColor Yellow
        Stop-Process -Name $procName -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1
        
        $stillRunning = Get-Process $procName -ErrorAction SilentlyContinue
        if (-not $stillRunning) {
            Write-Host "  SUCCESS: $procName stopped" -ForegroundColor Green
        } else {
            Write-Host "  WARNING: $procName still running" -ForegroundColor Red
        }
    } else {
        Write-Host "  SKIP: $procName not running" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "[4] Modifying System Manufacturer..." -ForegroundColor White

$systemBiosPath = "HKLM:\HARDWARE\DESCRIPTION\System\BIOS"
if (Test-Path $systemBiosPath) {
    Write-Host "  Setting Dell manufacturer info..." -ForegroundColor Yellow
    
    Set-ItemProperty -Path $systemBiosPath -Name "SystemManufacturer" -Value "Dell Inc." -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $systemBiosPath -Name "SystemProductName" -Value "OptiPlex 7090" -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $systemBiosPath -Name "SystemFamily" -Value "OptiPlex" -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $systemBiosPath -Name "BaseBoardManufacturer" -Value "Dell Inc." -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $systemBiosPath -Name "BaseBoardProduct" -Value "0K240Y" -ErrorAction SilentlyContinue
    
    Write-Host "  SUCCESS: System manufacturer spoofed" -ForegroundColor Green
} else {
    Write-Host "  WARNING: System BIOS path not accessible" -ForegroundColor Red
}

Write-Host ""
Write-Host "[5] Configuring VirtualBox Services..." -ForegroundColor White

$services = Get-Service | Where-Object { $_.Name -like "*VBox*" }
if ($services) {
    foreach ($service in $services) {
        Write-Host "  Processing $($service.Name)..." -ForegroundColor Yellow
        
        if ($service.Status -eq 'Running') {
            Stop-Service $service.Name -Force -ErrorAction SilentlyContinue
            Write-Host "    Stopped service" -ForegroundColor Gray
        }
        
        Set-Service $service.Name -StartupType Disabled -ErrorAction SilentlyContinue
        Write-Host "    Disabled startup" -ForegroundColor Gray
    }
    Write-Host "  SUCCESS: VirtualBox services configured" -ForegroundColor Green
} else {
    Write-Host "  SKIP: No VirtualBox services found" -ForegroundColor Gray
}

Write-Host ""
Write-Host "[6] Adding Hardware Legitimacy..." -ForegroundColor White

$cpuPath = "HKLM:\HARDWARE\DESCRIPTION\System\CentralProcessor\0"
if (Test-Path $cpuPath) {
    Write-Host "  Setting CPU information..." -ForegroundColor Yellow
    
    Set-ItemProperty -Path $cpuPath -Name "ProcessorNameString" -Value "Intel(R) Core(TM) i7-8550U CPU @ 1.80GHz" -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $cpuPath -Name "VendorIdentifier" -Value "GenuineIntel" -ErrorAction SilentlyContinue
    
    Write-Host "  SUCCESS: CPU information spoofed" -ForegroundColor Green
} else {
    Write-Host "  WARNING: CPU path not accessible" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Bypass Applied Successfully ===" -ForegroundColor Cyan
Write-Host "VirtualBox detection bypass has been applied!" -ForegroundColor Green
Write-Host ""
Write-Host "IMPORTANT NOTES:" -ForegroundColor Yellow
Write-Host "  1. Restart the system for full effect" -ForegroundColor White
Write-Host "  2. Some changes require VM restart" -ForegroundColor White
Write-Host "  3. Use restore script to undo changes" -ForegroundColor White
Write-Host ""
Write-Host "Next: Restart system and test your application" -ForegroundColor Cyan 
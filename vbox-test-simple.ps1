# VirtualBox Simple Test Script
# Test script untuk memverifikasi PowerShell execution
# Author: VBox Bypass Tool
# Usage: .\vbox-test-simple.ps1

Write-Host "=== VirtualBox Simple Test ===" -ForegroundColor Cyan
Write-Host "Testing PowerShell execution..." -ForegroundColor Yellow

# Test basic functionality
$testDir = ".\test-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
Write-Host "Test backup directory: $testDir" -ForegroundColor Green

# Test VirtualBox detection (basic)
try {
    $vboxGuestPath = "HKLM:\SOFTWARE\Oracle\VirtualBox Guest Additions"
    if (Test-Path $vboxGuestPath) {
        Write-Host "✓ VirtualBox Guest Additions detected!" -ForegroundColor Red
        $guestInfo = Get-ItemProperty $vboxGuestPath -ErrorAction SilentlyContinue
        Write-Host "  Version: $($guestInfo.Version)" -ForegroundColor Gray
    } else {
        Write-Host "○ VirtualBox Guest Additions not found" -ForegroundColor Green
    }
} catch {
    Write-Host "⚠ Error checking Guest Additions: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Test system info
try {
    $sysInfo = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction SilentlyContinue
    Write-Host "System Info:" -ForegroundColor White
    Write-Host "  Manufacturer: $($sysInfo.Manufacturer)" -ForegroundColor Gray
    Write-Host "  Model: $($sysInfo.Model)" -ForegroundColor Gray
} catch {
    Write-Host "⚠ Error getting system info: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Test network adapters
try {
    $adapters = Get-CimInstance -ClassName Win32_NetworkAdapter | Where-Object {$_.MACAddress} | Select-Object -First 2
    Write-Host "Network Adapters:" -ForegroundColor White
    foreach ($adapter in $adapters) {
        Write-Host "  $($adapter.Name): $($adapter.MACAddress)" -ForegroundColor Gray
        if ($adapter.MACAddress -like "08-00-27-*") {
            Write-Host "    ⚠ VirtualBox MAC detected!" -ForegroundColor Red
        }
    }
} catch {
    Write-Host "⚠ Error checking network adapters: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host "`n=== Test Completed Successfully! ===" -ForegroundColor Green
Write-Host "PowerShell execution is working properly." -ForegroundColor Cyan
Write-Host "You can now run the main scripts:" -ForegroundColor White
Write-Host "  .\vbox-detect-initial.ps1" -ForegroundColor Yellow
Write-Host "  .\vbox-bypass-apply.ps1" -ForegroundColor Yellow
Write-Host "  .\vbox-bypass-restore.ps1" -ForegroundColor Yellow 
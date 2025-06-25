# Minimal Test Script
Write-Host "PowerShell Test Started" -ForegroundColor Green

# Basic variables
$testVar = "Hello World"
Write-Host "Test Variable: $testVar" -ForegroundColor Yellow

# Basic function test
function Test-Function {
    return "Function works"
}

$result = Test-Function
Write-Host "Function Result: $result" -ForegroundColor Cyan

# Check if in VM
$computer = Get-CimInstance -ClassName Win32_ComputerSystem
Write-Host "Computer: $($computer.Manufacturer) $($computer.Model)" -ForegroundColor White

# Simple registry test
$testPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion"
if (Test-Path $testPath) {
    Write-Host "Registry access: OK" -ForegroundColor Green
} else {
    Write-Host "Registry access: FAILED" -ForegroundColor Red
}

Write-Host "Test Completed Successfully!" -ForegroundColor Green 
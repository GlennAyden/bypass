# VirtualBox Host Configuration Script - Windows Version
# Script untuk konfigurasi VirtualBox di HOST Windows (tanpa WSL)
# Author: VBox Bypass Tool
# Usage: .\05-host-configuration.ps1 [detect|apply|restore] [-VMName "YourVM"] [-SafeMode] [-Force] [-BackupDir "BackupDir"]

param(
    [Parameter(Position=0)]
    [ValidateSet("detect", "apply", "restore")]
    [string]$Action = "detect",
    
    [string]$VMName = "Windows10",
    [string]$BackupDir = "",
    [switch]$Force,
    [switch]$SafeMode
)

# Global variables
$script:ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$script:BackupDir = ""
$script:VMName = $VMName

# Helper functions for colored output
function Write-Status {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Check if VirtualBox is installed
function Test-VirtualBoxInstalled {
    try {
        $vboxVersion = & VBoxManage --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Status "VirtualBox version: $vboxVersion"
            return $true
        }
    } catch {
        Write-Error "VirtualBox is not installed or VBoxManage not in PATH!"
        Write-Status "Please install VirtualBox or add it to PATH"
        Write-Status "Default path: C:\Program Files\Oracle\VirtualBox\"
        return $false
    }
    return $false
}

# Check if VM exists
function Test-VMExists {
    try {
        $vms = & VBoxManage list vms 2>$null
        if ($vms -match "`"$script:VMName`"") {
            Write-Status "VM '$script:VMName' found"
            return $true
        } else {
            Write-Error "VM '$script:VMName' not found!"
            Write-Status "Available VMs:"
            & VBoxManage list vms
            return $false
        }
    } catch {
        Write-Error "Failed to list VMs"
        return $false
    }
}

# Generate random hex string
function Get-RandomHex {
    param([int]$Length)
    $hex = ""
    for ($i = 0; $i -lt $Length; $i++) {
        $hex += "{0:X}" -f (Get-Random -Maximum 16)
    }
    return $hex
}

# Generate random MAC address that looks legitimate
function Get-RandomMac {
    # Use legitimate manufacturer prefixes (Dell, HP, Lenovo, etc.)
    $manufacturerPrefixes = @(
        "DELLFC",  # Dell
        "B85510",  # HP
        "E41D2D",  # HP
        "5CB901",  # Lenovo
        "0017A4",  # Lenovo
        "001DD8",  # ASUS
        "BC5FF4",  # ASUS
        "1C872C",  # Acer
        "02004C"   # Generic
    )
    
    $prefix = $manufacturerPrefixes | Get-Random
    $suffix = Get-RandomHex -Length 6
    return $prefix + $suffix
}

# Detect current VM configuration
function Invoke-DetectVMConfig {
    Write-Status "=== VirtualBox Host Configuration Detection ==="
    
    if (-not (Test-VirtualBoxInstalled)) { exit 1 }
    if (-not (Test-VMExists)) { exit 1 }
    
    # Create backup directory
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $script:BackupDir = Join-Path $script:ScriptDir "vbox-backup-$timestamp"
    New-Item -ItemType Directory -Path $script:BackupDir -Force | Out-Null
    Write-Success "Backup directory created: $script:BackupDir"
    
    Write-Status "Detecting current VM configuration for: $script:VMName"
    
    try {
        # Get current VM info
        $vmInfo = & VBoxManage showvminfo $script:VMName --machinereadable
        $vmInfo | Out-File -FilePath "$script:BackupDir\vm_original_config.txt" -Encoding UTF8
        
        # Parse and display configuration
        Write-Status "[1] Hardware Configuration:"
        $vmInfo | Where-Object { $_ -match "(macaddress|biosbootmenu|firmware|chipset|paravirtprovider)" } | ForEach-Object {
            Write-Host "  $_" -ForegroundColor Gray
        }
        
        Write-Status "[2] System Information:"
        $vmInfo | Where-Object { $_ -match "(ostype|memory|vram|cpus)" } | ForEach-Object {
            Write-Host "  $_" -ForegroundColor Gray
        }
        
        Write-Status "[3] Storage Configuration:"
        $vmInfo | Where-Object { $_ -match "(storagecontroller|IDE|SATA)" } | ForEach-Object {
            Write-Host "  $_" -ForegroundColor Gray
        }
        
        Write-Status "[4] Network Configuration:"
        $vmInfo | Where-Object { $_ -match "(nic|macaddress|bridgeadapter)" } | ForEach-Object {
            Write-Host "  $_" -ForegroundColor Gray
        }
        
        # Save individual components for restoration
        $macAddress = ($vmInfo | Where-Object { $_ -match "macaddress1=" }) -replace 'macaddress1="([^"]*)".*', '$1'
        $biosBootMenu = ($vmInfo | Where-Object { $_ -match "biosbootmenu=" }) -replace 'biosbootmenu="([^"]*)".*', '$1'
        $firmware = ($vmInfo | Where-Object { $_ -match "firmware=" }) -replace 'firmware="([^"]*)".*', '$1'
        $paravirtProvider = ($vmInfo | Where-Object { $_ -match "paravirtprovider=" }) -replace 'paravirtprovider="([^"]*)".*', '$1'
        
        $macAddress | Out-File "$script:BackupDir\original_mac.txt" -Encoding UTF8
        $biosBootMenu | Out-File "$script:BackupDir\original_biosbootmenu.txt" -Encoding UTF8
        $firmware | Out-File "$script:BackupDir\original_firmware.txt" -Encoding UTF8
        $paravirtProvider | Out-File "$script:BackupDir\original_paravirtprovider.txt" -Encoding UTF8
        
        Write-Success "Configuration detected and backed up to: $script:BackupDir"
        
        # Check for VirtualBox signatures
        Write-Status "[5] VirtualBox Signature Detection:"
        
        if ($macAddress -like "08002*") {
            Write-Warning "VirtualBox MAC address detected: $macAddress"
        } else {
            Write-Success "MAC address looks legitimate: $macAddress"
        }
        
        if ($firmware -eq "BIOS") {
            Write-Warning "Using BIOS firmware (easily detectable)"
        } else {
            Write-Success "Using EFI firmware: $firmware"
        }
        
        if ($paravirtProvider -ne "none") {
            Write-Warning "Paravirtualization enabled: $paravirtProvider"
        } else {
            Write-Success "Paravirtualization disabled"
        }
        
    } catch {
        Write-Error "Failed to detect VM configuration: $($_.Exception.Message)"
        exit 1
    }
}

# Apply VirtualBox detection bypass
function Invoke-ApplyBypass {
    param([switch]$SafeMode)
    
    Write-Status "=== Applying VirtualBox Detection Bypass ==="
    
    if (-not (Test-VirtualBoxInstalled)) { exit 1 }
    if (-not (Test-VMExists)) { exit 1 }
    
    # Check if VM is running
    $runningVMs = & VBoxManage list runningvms 2>$null
    if ($runningVMs -match "`"$script:VMName`"") {
        Write-Error "VM '$script:VMName' is currently running!"
        Write-Status "Please shut down the VM before applying bypass."
        exit 1
    }
    
    if (-not $Force) {
        if ($SafeMode) {
            Write-Warning "This will apply SAFE MODE bypass modifications to '$script:VMName'"
            Write-Status "Safe mode only changes MAC address and basic settings."
        } else {
            Write-Warning "This will apply FULL bypass modifications to '$script:VMName'"
            Write-Status "This includes DMI spoofing which may cause boot issues on some systems."
        }
        $confirm = Read-Host "Continue with bypass application? (y/N)"
        if ($confirm -ne 'y' -and $confirm -ne 'Y') {
            Write-Status "Operation cancelled."
            exit 0
        }
    }
    
    if ($SafeMode) {
        Write-Status "=== SAFE MODE: Applying minimal bypass modifications ==="
    } else {
        Write-Status "=== FULL MODE: Applying comprehensive bypass modifications ==="
    }
    
    try {
        # 1. Change MAC address (always safe)
        Write-Status "[1] Changing MAC address..."
        $newMac = Get-RandomMac
        & VBoxManage modifyvm $script:VMName --macaddress1 $newMac
        Write-Success "MAC address changed to: $newMac"
        
        if ($SafeMode) {
            # SAFE MODE: Only apply minimal changes
            Write-Status "[2] Disabling paravirtualization (safe)..."
            & VBoxManage modifyvm $script:VMName --paravirtprovider none
            Write-Success "Paravirtualization disabled"
            
            Write-Status "[3] Optimizing hardware virtualization..."
            & VBoxManage modifyvm $script:VMName --hwvirtex on
            & VBoxManage modifyvm $script:VMName --nestedpaging on
            & VBoxManage modifyvm $script:VMName --largepages on
            & VBoxManage modifyvm $script:VMName --vtxvpid on
            & VBoxManage modifyvm $script:VMName --vtxux on
            Write-Success "Hardware virtualization optimized"
            
            Write-Success "=== SAFE MODE Bypass Applied Successfully ==="
            Write-Status "VM '$script:VMName' configured with safe bypass modifications."
            Write-Status "Safe mode avoids potentially problematic DMI/BIOS spoofing."
            
        } else {
            # FULL MODE: Apply all modifications
            # 2. Set BIOS/EFI information
            Write-Status "[2] Configuring BIOS/EFI settings..."
            & VBoxManage modifyvm $script:VMName --firmware efi
            & VBoxManage modifyvm $script:VMName --biosbootmenu disabled
            Write-Success "Firmware set to EFI, boot menu disabled"
            
            # 3. Disable paravirtualization
            Write-Status "[3] Disabling paravirtualization..."
            & VBoxManage modifyvm $script:VMName --paravirtprovider none
            Write-Success "Paravirtualization disabled"
            
            # 4. Set system information via EFI
            Write-Status "[4] Setting system information..."
            & VBoxManage setextradata $script:VMName "VBoxInternal/Devices/efi/0/Config/DmiSystemVendor" "Dell Inc."
            & VBoxManage setextradata $script:VMName "VBoxInternal/Devices/efi/0/Config/DmiSystemProduct" "OptiPlex 7090"
            & VBoxManage setextradata $script:VMName "VBoxInternal/Devices/efi/0/Config/DmiSystemVersion" "1.0"
            $serialNumber = Get-RandomHex -Length 16
            & VBoxManage setextradata $script:VMName "VBoxInternal/Devices/efi/0/Config/DmiSystemSerial" $serialNumber
            & VBoxManage setextradata $script:VMName "VBoxInternal/Devices/efi/0/Config/DmiSystemFamily" "OptiPlex"
            Write-Success "System information configured as Dell OptiPlex"
            
            # 5. Set motherboard information
            Write-Status "[5] Setting motherboard information..."
            & VBoxManage setextradata $script:VMName "VBoxInternal/Devices/efi/0/Config/DmiBoardVendor" "Dell Inc."
            & VBoxManage setextradata $script:VMName "VBoxInternal/Devices/efi/0/Config/DmiBoardProduct" "0K240Y"
            & VBoxManage setextradata $script:VMName "VBoxInternal/Devices/efi/0/Config/DmiBoardVersion" "A00"
            $boardSerial = Get-RandomHex -Length 12
            & VBoxManage setextradata $script:VMName "VBoxInternal/Devices/efi/0/Config/DmiBoardSerial" $boardSerial
            Write-Success "Motherboard information configured"
            
            # 6. Set CPU information (FIXED: EFI-safe strings)
            Write-Status "[6] Setting CPU information..."
            & VBoxManage setextradata $script:VMName "VBoxInternal/Devices/efi/0/Config/DmiProcessorManufacturer" "Intel Corporation"
            & VBoxManage setextradata $script:VMName "VBoxInternal/Devices/efi/0/Config/DmiProcessorVersion" "Intel Core i7-8550U"
            Write-Success "CPU information configured"
            
            # 7. Set BIOS information
            Write-Status "[7] Setting BIOS information..."
            & VBoxManage setextradata $script:VMName "VBoxInternal/Devices/efi/0/Config/DmiBIOSVendor" "Dell Inc."
            & VBoxManage setextradata $script:VMName "VBoxInternal/Devices/efi/0/Config/DmiBIOSVersion" "1.21.0"
            & VBoxManage setextradata $script:VMName "VBoxInternal/Devices/efi/0/Config/DmiBIOSReleaseDate" "07/15/2023"
            Write-Success "BIOS information configured"
            
            # 8. Configure hardware virtualization
            Write-Status "[8] Configuring hardware virtualization..."
            & VBoxManage modifyvm $script:VMName --hwvirtex on
            & VBoxManage modifyvm $script:VMName --nestedpaging on
            & VBoxManage modifyvm $script:VMName --largepages on
            & VBoxManage modifyvm $script:VMName --vtxvpid on
            & VBoxManage modifyvm $script:VMName --vtxux on
            Write-Success "Hardware virtualization optimized"
            
            Write-Success "=== FULL MODE Bypass Applied Successfully ==="
            Write-Status "VM '$script:VMName' has been configured to evade detection."
        }
        
        Write-Warning "IMPORTANT: Start the VM and test your application."
        
        # Create bypass report
        $modificationsApplied = @("MAC address changed to: $newMac")
        
        if ($SafeMode) {
            $modificationsApplied += @(
                "Paravirtualization disabled",
                "Hardware virtualization optimized",
                "SAFE MODE: DMI spoofing skipped"
            )
        } else {
            $modificationsApplied += @(
                "Firmware set to EFI",
                "Paravirtualization disabled",
                "System information spoofed (Dell OptiPlex 7090)",
                "Motherboard information configured",
                "CPU information spoofed (Intel Core i7-8550U)",
                "BIOS information configured",
                "Hardware virtualization optimized"
            )
        }
        
        $report = @{
            Timestamp = Get-Date
            VMName = $script:VMName
            BackupDirectory = $script:BackupDir
            SafeMode = $SafeMode
            ModificationsApplied = $modificationsApplied
        }
        
        $report | ConvertTo-Json | Out-File "$script:BackupDir\bypass_applied_report.json" -Encoding UTF8
        Write-Success "Bypass report saved to: $script:BackupDir\bypass_applied_report.json"
        
    } catch {
        Write-Error "Failed to apply bypass: $($_.Exception.Message)"
        Write-Status "You may need to restore original configuration and try Safe Mode."
        exit 1
    }
}

# Restore original configuration
function Invoke-RestoreConfig {
    param([string]$RestoreDir)
    
    Write-Status "=== Restoring Original VirtualBox Configuration ==="
    
    if (-not (Test-VirtualBoxInstalled)) { exit 1 }
    if (-not (Test-VMExists)) { exit 1 }
    
    # Find backup directory if not specified
    if ([string]::IsNullOrEmpty($RestoreDir)) {
        # FIXED: Proper directory detection without character array bug
        $backupDirs = @(Get-ChildItem -Directory -Path $script:ScriptDir | Where-Object { $_.Name -like "vbox-backup-*" } | Sort-Object Name -Descending)
        
        if ($backupDirs.Count -gt 0) {
            Write-Status "Available backup directories:"
            for ($i = 0; $i -lt $backupDirs.Count; $i++) {
                Write-Host "  [$i] $($backupDirs[$i].Name)" -ForegroundColor White
            }
            if (-not $Force) {
                $selection = Read-Host "Select backup directory (0-$($backupDirs.Count-1))"
                if ($selection -match '^\d+$' -and [int]$selection -lt $backupDirs.Count) {
                    $RestoreDir = $backupDirs[[int]$selection].FullName
                } else {
                    $RestoreDir = $backupDirs[0].FullName
                }
            } else {
                $RestoreDir = $backupDirs[0].FullName
            }
            Write-Success "Using backup directory: $RestoreDir"
        } else {
            Write-Error "No backup directory found!"
            Write-Status "Cannot restore without backup. Run detect first."
            exit 1
        }
    } else {
        # FIXED: Handle relative paths properly
        if (-not [System.IO.Path]::IsPathRooted($RestoreDir)) {
            $RestoreDir = Join-Path $script:ScriptDir $RestoreDir
        }
        Write-Status "Using specified backup directory: $RestoreDir"
    }
    
    if (-not (Test-Path $RestoreDir)) {
        Write-Error "Backup directory not found: $RestoreDir"
        Write-Status "Available backup directories:"
        $availableBackups = Get-ChildItem -Directory -Path $script:ScriptDir | Where-Object { $_.Name -like "vbox-backup-*" }
        foreach ($backup in $availableBackups) {
            Write-Host "  - $($backup.Name)" -ForegroundColor Gray
        }
        exit 1
    }
    
    # Check if VM is running
    $runningVMs = & VBoxManage list runningvms 2>$null
    if ($runningVMs -match "`"$script:VMName`"") {
        Write-Error "VM '$script:VMName' is currently running!"
        Write-Status "Please shut down the VM before restoring configuration."
        exit 1
    }
    
    if (-not $Force) {
        Write-Warning "This will restore original VirtualBox settings for '$script:VMName'"
        $confirm = Read-Host "Continue with restore? (y/N)"
        if ($confirm -ne 'y' -and $confirm -ne 'Y') {
            Write-Status "Operation cancelled."
            exit 0
        }
    }
    
    Write-Status "Restoring configuration from: $RestoreDir"
    
    try {
        # Restore MAC address
        $macFile = Join-Path $RestoreDir "original_mac.txt"
        if (Test-Path $macFile) {
            $originalMac = Get-Content $macFile -Raw -ErrorAction SilentlyContinue
            if (-not [string]::IsNullOrWhiteSpace($originalMac)) {
                $originalMac = $originalMac.Trim()
                Write-Status "Restoring MAC address: $originalMac"
                & VBoxManage modifyvm $script:VMName --macaddress1 $originalMac
                Write-Success "MAC address restored"
            } else {
                Write-Warning "MAC address backup file is empty, skipping restore"
            }
        } else {
            Write-Warning "MAC address backup file not found, skipping restore"
        }
        
        # Restore BIOS boot menu
        $biosBootFile = Join-Path $RestoreDir "original_biosbootmenu.txt"
        if (Test-Path $biosBootFile) {
            $originalBiosBootMenu = Get-Content $biosBootFile -Raw -ErrorAction SilentlyContinue
            if (-not [string]::IsNullOrWhiteSpace($originalBiosBootMenu)) {
                $originalBiosBootMenu = $originalBiosBootMenu.Trim()
                Write-Status "Restoring BIOS boot menu: $originalBiosBootMenu"
                & VBoxManage modifyvm $script:VMName --biosbootmenu $originalBiosBootMenu
                Write-Success "BIOS boot menu restored"
            } else {
                Write-Warning "BIOS boot menu backup file is empty, setting to default"
                & VBoxManage modifyvm $script:VMName --biosbootmenu messageandmenu
                Write-Success "BIOS boot menu set to default"
            }
        } else {
            Write-Warning "BIOS boot menu backup file not found, setting to default"
            & VBoxManage modifyvm $script:VMName --biosbootmenu messageandmenu
            Write-Success "BIOS boot menu set to default"
        }
        
        # Restore firmware
        $firmwareFile = Join-Path $RestoreDir "original_firmware.txt"
        if (Test-Path $firmwareFile) {
            $originalFirmware = Get-Content $firmwareFile -Raw -ErrorAction SilentlyContinue
            if (-not [string]::IsNullOrWhiteSpace($originalFirmware)) {
                $originalFirmware = $originalFirmware.Trim()
                Write-Status "Restoring firmware: $originalFirmware"
                & VBoxManage modifyvm $script:VMName --firmware $originalFirmware
                Write-Success "Firmware restored"
            } else {
                Write-Warning "Firmware backup file is empty, setting to BIOS"
                & VBoxManage modifyvm $script:VMName --firmware bios
                Write-Success "Firmware set to BIOS (default)"
            }
        } else {
            Write-Warning "Firmware backup file not found, setting to BIOS"
            & VBoxManage modifyvm $script:VMName --firmware bios
            Write-Success "Firmware set to BIOS (default)"
        }
        
        # Restore paravirtualization
        $paravirtFile = Join-Path $RestoreDir "original_paravirtprovider.txt"
        if (Test-Path $paravirtFile) {
            $originalParavirt = Get-Content $paravirtFile -Raw -ErrorAction SilentlyContinue
            if (-not [string]::IsNullOrWhiteSpace($originalParavirt)) {
                $originalParavirt = $originalParavirt.Trim()
                Write-Status "Restoring paravirtualization: $originalParavirt"
                & VBoxManage modifyvm $script:VMName --paravirtprovider $originalParavirt
                Write-Success "Paravirtualization restored"
            } else {
                Write-Warning "Paravirtualization backup file is empty, setting to default"
                & VBoxManage modifyvm $script:VMName --paravirtprovider default
                Write-Success "Paravirtualization set to default"
            }
        } else {
            Write-Warning "Paravirtualization backup file not found, setting to default"
            & VBoxManage modifyvm $script:VMName --paravirtprovider default
            Write-Success "Paravirtualization set to default"
        }
        
        # Remove all extra data that was added (ENHANCED: More comprehensive cleanup)
        Write-Status "Removing spoofed system information..."
        $extraDataKeys = @(
            "VBoxInternal/Devices/efi/0/Config/DmiSystemVendor",
            "VBoxInternal/Devices/efi/0/Config/DmiSystemProduct",
            "VBoxInternal/Devices/efi/0/Config/DmiSystemVersion",
            "VBoxInternal/Devices/efi/0/Config/DmiSystemSerial",
            "VBoxInternal/Devices/efi/0/Config/DmiSystemFamily",
            "VBoxInternal/Devices/efi/0/Config/DmiBoardVendor",
            "VBoxInternal/Devices/efi/0/Config/DmiBoardProduct",
            "VBoxInternal/Devices/efi/0/Config/DmiBoardVersion",
            "VBoxInternal/Devices/efi/0/Config/DmiBoardSerial",
            "VBoxInternal/Devices/efi/0/Config/DmiProcessorManufacturer",
            "VBoxInternal/Devices/efi/0/Config/DmiProcessorVersion",
            "VBoxInternal/Devices/efi/0/Config/DmiBIOSVendor",
            "VBoxInternal/Devices/efi/0/Config/DmiBIOSVersion",
            "VBoxInternal/Devices/efi/0/Config/DmiBIOSReleaseDate"
        )
        
        foreach ($key in $extraDataKeys) {
            & VBoxManage setextradata $script:VMName $key 2>$null
        }
        Write-Success "Spoofed system information removed"
        
        Write-Success "=== Configuration Restored Successfully ==="
        Write-Status "VM '$script:VMName' has been restored to original configuration."
        Write-Status "You can now start the VM safely."
        
        # Create restore report
        $restoreReport = @{
            Timestamp = Get-Date
            VMName = $script:VMName
            RestoreDirectory = $RestoreDir
            RestoredComponents = @(
                "MAC address",
                "BIOS boot menu setting", 
                "Firmware type",
                "Paravirtualization provider",
                "System information (removed spoofed data)",
                "Motherboard information (removed spoofed data)",
                "CPU information (removed spoofed data)",
                "BIOS information (removed spoofed data)"
            )
        }
        
        $restoreReport | ConvertTo-Json | Out-File "$RestoreDir\restore_completed_report.json" -Encoding UTF8
        Write-Success "Restore report saved to: $RestoreDir\restore_completed_report.json"
        
    } catch {
        Write-Error "Failed to restore configuration: $($_.Exception.Message)"
        Write-Status "You may need to manually restore settings or recreate the VM."
        exit 1
    }
}

# Main script logic
switch ($Action) {
    "detect" {
        Invoke-DetectVMConfig
    }
    "apply" {
        Invoke-ApplyBypass -SafeMode $SafeMode
    }
    "restore" {
        Invoke-RestoreConfig -RestoreDir $BackupDir
    }
    default {
        Write-Host "Usage: .\05-host-configuration.ps1 [detect|apply|restore] [-VMName `"YourVM`"] [-SafeMode] [-Force] [-BackupDir "BackupDir"]" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Commands:" -ForegroundColor White
        Write-Host "  detect  - Detect current VM configuration and create backup" -ForegroundColor Gray
        Write-Host "  apply   - Apply VirtualBox detection bypass modifications" -ForegroundColor Gray  
        Write-Host "  restore - Restore original configuration from backup" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Parameters:" -ForegroundColor White
        Write-Host "  -VMName     - Name of the VM to configure (default: 'Windows10')" -ForegroundColor Gray
        Write-Host "  -SafeMode   - Apply only safe modifications (no DMI spoofing)" -ForegroundColor Gray
        Write-Host "  -Force      - Skip confirmation prompts" -ForegroundColor Gray
        Write-Host "  -BackupDir  - Specific backup directory for restore" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Examples:" -ForegroundColor White
        Write-Host "  .\05-host-configuration.ps1 detect -VMName `"TOEFL 1`"" -ForegroundColor Gray
        Write-Host "  .\05-host-configuration.ps1 apply -VMName `"TOEFL 1`" -SafeMode" -ForegroundColor Gray
        Write-Host "  .\05-host-configuration.ps1 apply -VMName `"TOEFL 1`" -Force" -ForegroundColor Gray
        Write-Host "  .\05-host-configuration.ps1 restore -VMName `"TOEFL 1`" -Force" -ForegroundColor Gray
        Write-Host "  .\05-host-configuration.ps1 restore -BackupDir `"vbox-backup-20231201-143022`"" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Safe Mode vs Full Mode:" -ForegroundColor White
        Write-Host "  Safe Mode   - Only MAC address & basic changes (95% safe)" -ForegroundColor Green
        Write-Host "  Full Mode   - Complete DMI spoofing (higher detection but EFI risks)" -ForegroundColor Yellow
        exit 1
    }
} 
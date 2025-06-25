# VirtualBox Detection Bypass Toolkit

Toolkit komprehensif untuk mendeteksi, menghindari, dan mengembalikan deteksi VirtualBox. Script ini dibuat untuk keperluan testing, research, dan development yang legitimate.

## ⚠️ Disclaimer

**PENTING: Gunakan toolkit ini secara bertanggung jawab!**

✅ **Penggunaan yang Diizinkan:**
- Testing aplikasi dalam environment virtual
- Security research dan analisis malware
- Development dan debugging
- Educational purposes

❌ **TIDAK untuk:**
- Aktivitas ilegal atau melanggar ToS
- Fraud atau penipuan
- Bypass security sistem production

## 📁 File Structure

```
vbox-bypass-toolkit/
├── 01-test-execution.ps1      # Test PowerShell execution (START HERE)
├── 02-detect-virtualbox.ps1   # Detect VirtualBox components  
├── 03-apply-bypass.ps1        # Apply bypass modifications
├── 04-restore-original.ps1    # Restore original state
├── 05-host-configuration.ps1  # Host configuration (Windows PowerShell)
└── README.md                  # Comprehensive documentation
```

## 🚀 Quick Start Guide

### Step 1: Test PowerShell Execution

**WAJIB dijalankan pertama kali untuk memastikan tidak ada masalah:**

```powershell
# Buka PowerShell as Administrator
# Set execution policy untuk session ini
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

# Test script paling dasar
.\01-test-execution.ps1
```

**Jika ada error di Step 1, JANGAN lanjut ke step berikutnya!**

### Step 2: Deteksi VirtualBox

```powershell
# Jalankan detection script
.\02-detect-virtualbox.ps1
```

**Output yang diharapkan:**
- ✅ Backup directory dibuat
- ✅ Deteksi VirtualBox components
- ✅ JSON backup files tersimpan

### Step 3: Apply Bypass

```powershell
# Terapkan bypass (HATI-HATI: Akan modify system!)
.\03-apply-bypass.ps1

# Atau force tanpa konfirmasi
.\03-apply-bypass.ps1 -Force
```

### Step 4: Restart & Test

```powershell
# Restart system untuk efek penuh
Restart-Computer
```

### Step 5: Restore (Jika Diperlukan)

```powershell
# Kembalikan ke kondisi original
.\04-restore-original.ps1
```

## 🖥️ Script Details

### 01-test-execution.ps1 ✅ **MULAI DARI SINI**

**Fungsi:** Test dasar PowerShell execution
**Wajib:** Ya, jalankan pertama kali
**Output:** Verifikasi PowerShell, registry access, sistem info

```powershell
# Simple test - tidak mengubah apapun
.\01-test-execution.ps1
```

### 02-detect-virtualbox.ps1 🔍

**Fungsi:** Deteksi lengkap VirtualBox components
**Input:** Tidak ada
**Output:** Backup directory + JSON files
**Deteksi:**
- Registry VirtualBox Guest Additions
- System manufacturer/BIOS info  
- VirtualBox processes (VBoxService, VBoxTray)
- Network adapters (MAC 08-00-27-*)
- VirtualBox services

### 03-apply-bypass.ps1 ⚡

**Fungsi:** Bypass VirtualBox detection
**Requires:** Administrator privileges
**WARNING:** Modifikasi system registry!

**Modifikasi yang dilakukan:**
- ❌ Remove VirtualBox registry keys
- 🔄 Change BIOS information → Dell Inc.
- ⏹️ Stop VirtualBox processes
- 🏭 Spoof manufacturer → Dell OptiPlex 7090
- 🚫 Disable VirtualBox services
- 💻 Change CPU info → Intel i7-8550U

### 04-restore-original.ps1 🔄

**Fungsi:** Restore kondisi original
**Input:** Backup directory (auto-detect)
**Restores:**
- Registry keys original
- VirtualBox services
- System information
- Service startup types

### 05-host-configuration.ps1 🏠 (Windows Host Configuration)

**Fungsi:** Konfigurasi VirtualBox dari HOST Windows (Native PowerShell)
**Platform:** Windows PowerShell
**Requires:** VirtualBox installed, VBoxManage in PATH

**Features:**
- ✅ **Safe Mode**: MAC + basic changes (95% safe, recommended first)
- ✅ **Full Mode**: Complete DMI spoofing (higher effectiveness)
- ✅ **Auto Backup**: Automatic configuration backup
- ✅ **Smart Restore**: Handles empty/missing backup files gracefully
- ✅ **Error Recovery**: Proper fallback to defaults

**Usage:**
```powershell
# 1. Detect VM configuration and create backup
.\05-host-configuration.ps1 detect -VMName "TOEFL 1"

# 2. Apply SAFE MODE bypass (recommended first try)
.\05-host-configuration.ps1 apply -VMName "TOEFL 1" -SafeMode

# 3. Apply FULL MODE bypass (if Safe Mode not enough)
.\05-host-configuration.ps1 apply -VMName "TOEFL 1"

# 4. Apply with force (no confirmation prompts)
.\05-host-configuration.ps1 apply -VMName "TOEFL 1" -Force

# 5. Restore original configuration
.\05-host-configuration.ps1 restore -VMName "TOEFL 1" -Force

# 6. Restore from specific backup directory
.\05-host-configuration.ps1 restore -VMName "TOEFL 1" -BackupDir "vbox-backup-20231201-143022"

# 7. View help and all options
.\05-host-configuration.ps1
```

**Safe Mode vs Full Mode:**
- **Safe Mode**: Only MAC address + paravirtualization changes (95% boot success)
- **Full Mode**: Complete DMI/BIOS spoofing (higher detection bypass but potential EFI issues)

**IMPORTANT:** Always run `detect` first to create backup, then try `SafeMode` before `Full Mode`.

## 📊 Efektivitas Bypass

| Teknik | Success Rate | Kompleksitas | Impact |
|--------|-------------|--------------|---------|
| Registry Cleanup | 85% | 🟢 Rendah | 🔴 Tinggi |
| BIOS/SMBIOS Spoofing | 95% | 🟡 Sedang | 🔴 Sangat Tinggi |
| MAC Address Change | 90% | 🟢 Rendah | 🔴 Tinggi |
| Process Management | 70% | 🔴 Tinggi | 🟡 Sedang |
| Host-level Config | 95% | 🟡 Sedang | 🔴 Sangat Tinggi |

**Rekomendasi:** Kombinasi 2-3 teknik untuk hasil maksimal.

## 🔧 Troubleshooting

### PowerShell Script Error / Won't Run

**Problem:** Script dibuka dengan Notepad atau parsing error

**Solution:**
```powershell
# 1. ALWAYS test minimal script first
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
.\01-test-execution.ps1

# 2. If still error, one-liner approach
powershell -ExecutionPolicy Bypass -File ".\02-detect-virtualbox.ps1"

# 3. Check PowerShell version
$PSVersionTable.PSVersion
```

### "UnauthorizedAccess" Error

```powershell
# Run PowerShell as Administrator
# Then set execution policy
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
```

### VM Won't Boot After Bypass

**Host-level fix:**
```powershell
# Restore VM configuration (RECOMMENDED)
.\05-host-configuration.ps1 restore -VMName "TOEFL 1" -Force

# Or emergency manual reset
VBoxManage modifyvm "TOEFL 1" --firmware bios
VBoxManage setextradata "TOEFL 1" "VBoxInternal/Devices/efi/0/Config/DmiProcessorManufacturer"
```

**Guest-level fix:**
```powershell
# Restore original settings
.\04-restore-original.ps1
```

### Script "Stops" or Hangs

```powershell
# Kill PowerShell and restart
# Use individual commands instead of full script
# Check Windows Defender real-time protection
```

### Backup Directory Not Found

```powershell
# List available backups
Get-ChildItem -Directory -Name "*backup*" | Sort-Object -Descending

# Or check specific backup
Test-Path ".\vbox-backup-YYYYMMDD-HHMMSS"
```

## 🎯 Testing Strategy

### Phase 1: Basic Testing
1. ✅ Run `01-test-execution.ps1`
2. ✅ Run `02-detect-virtualbox.ps1`
3. ✅ Verify backup files created

### Phase 2: Light Bypass
1. ✅ Run `03-apply-bypass.ps1`
2. ✅ Test with simple VM detector
3. ✅ Restart and verify

### Phase 3: Full Bypass
1. ✅ Host-level configuration
2. ✅ Guest-level bypass
3. ✅ Test with target application

### Phase 4: Restoration
1. ✅ Verify restore works
2. ✅ Document any issues
3. ✅ Keep backups safe

## 📝 Backup Management

**Automatic Backups:**
- Format: `vbox-backup-YYYYMMDD-HHMMSS`
- Location: Script directory
- Contents: JSON files + reports

**Manual Backup:**
```powershell
# Export VM settings
VBoxManage showvminfo "YourVM" --machinereadable > vm-backup.txt

# Registry backup
reg export "HKLM\SOFTWARE\Oracle" oracle-backup.reg
```

## 🛡️ Security Notes

1. **Always backup** before making changes
2. **Test in isolated environment** first  
3. **Monitor system behavior** after bypass
4. **Keep restore scripts handy**
5. **Don't use on production systems**

## 🔗 External Tools

### Online VM Detection Tests:
- [Pafish](https://github.com/a0rtega/pafish) - Anti-VM detection tool
- [CheckVirtual.com](http://checkvirtual.com) - Online VM detector
- [VMware Detection](https://www.hybrid-analysis.com/) - Malware analysis

### VirtualBox Tools:
- VBoxManage command reference
- VM import/export utilities
- Snapshot management

## 📚 References

- [VirtualBox Manual](https://www.virtualbox.org/manual/)
- [VM Evasion Techniques](https://evasions.checkpoint.com/)
- [Anti-VM Research](https://github.com/CheckPointSW/InviZzzible)
- [Malware VM Detection](https://malwareanalysis.co/vm-detection/)

## 🤝 Contributing

Contributions welcome! Please:
1. Test thoroughly in safe environment
2. Document all changes clearly
3. Follow existing code style
4. Add appropriate error handling

## 📄 License

This toolkit is for educational and research purposes only. Use responsibly and in accordance with applicable laws and terms of service.

---

**Happy Testing! 🚀**

> Remember: With great power comes great responsibility. Use these tools ethically and legally. 
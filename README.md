# VirtualBox Detection Bypass Scripts

Kumpulan script untuk mendeteksi, menerapkan, dan mengembalikan bypass deteksi VirtualBox. Script ini dibuat untuk keperluan testing dan research, bukan untuk aktivitas ilegal.

## ⚠️ Disclaimer

Script ini dibuat untuk:
- **Testing aplikasi** dalam environment virtual
- **Security research** dan analisis malware
- **Development purposes** tanpa interference detection
- **Educational purposes** untuk memahami VM detection

**TIDAK** untuk aktivitas ilegal atau melanggar ToS aplikasi tertentu.

## 📁 File Structure

```
vbox-bypass/
├── vbox-detect-initial.ps1    # Deteksi kondisi awal (Guest OS)
├── vbox-bypass-apply.ps1      # Terapkan bypass (Guest OS)
├── vbox-bypass-restore.ps1    # Kembalikan kondisi awal (Guest OS)
├── vbox-host-config.sh        # Konfigurasi host VirtualBox
└── README.md                  # Dokumentasi ini
```

## 🖥️ Script untuk Guest OS (Windows)

### 1. vbox-detect-initial.ps1

**Fungsi:** Mendeteksi kondisi awal VirtualBox di dalam VM (Guest OS)

**Yang Dideteksi:**
- Registry keys VirtualBox
- Running processes (VBoxService, VBoxTray)
- System information (Manufacturer, BIOS)
- Network adapters (MAC address)
- Hardware devices VirtualBox
- Services VirtualBox

**Usage:**
```powershell
# Jalankan sebagai Administrator
.\vbox-detect-initial.ps1
```

**Output:**
- Backup directory dengan timestamp
- File JSON untuk setiap komponen
- Detection report lengkap

### 2. vbox-bypass-apply.ps1

**Fungsi:** Menerapkan bypass detection VirtualBox

**Modifikasi yang Dilakukan:**
- Hapus registry VirtualBox Guest Additions
- Ubah System BIOS information
- Stop dan rename VirtualBox processes
- Spoof system manufacturer (Dell Inc.)
- Disable VirtualBox services
- Buat hardware legitimacy markers
- Bersihkan installation traces

**Usage:**
```powershell
# Jalankan sebagai Administrator
.\vbox-bypass-apply.ps1

# Skip confirmation
.\vbox-bypass-apply.ps1 -SkipConfirmation

# Specify backup directory
.\vbox-bypass-apply.ps1 -BackupDir "vbox-backup-20231201-143022"
```

**⚠️ Penting:** Restart system setelah apply untuk efek maksimal.

### 3. vbox-bypass-restore.ps1

**Fungsi:** Mengembalikan kondisi awal VirtualBox

**Yang Dikembalikan:**
- Registry keys original
- VirtualBox services
- System information
- VirtualBox processes
- Hardware information

**Usage:**
```powershell
# Jalankan sebagai Administrator
.\vbox-bypass-restore.ps1

# Pilih backup directory tertentu
.\vbox-bypass-restore.ps1 -BackupDir "vbox-backup-20231201-143022"

# Skip confirmation
.\vbox-bypass-restore.ps1 -SkipConfirmation
```

## 🖥️ Script untuk Host OS (Linux/WSL)

### vbox-host-config.sh

**Fungsi:** Konfigurasi VirtualBox di HOST untuk menghindari detection

**Modifikasi yang Dilakukan:**
- Change MAC address (Dell prefix)
- Set EFI firmware
- Disable paravirtualization
- Spoof system information (Dell OptiPlex 7090)
- Configure motherboard info
- Set CPU information (Intel i7-8550U)
- Configure BIOS information

**Usage:**
```bash
# Buat file executable
chmod +x vbox-host-config.sh

# Edit VM name di script (default: Windows10)
nano vbox-host-config.sh

# Detect current configuration
./vbox-host-config.sh detect

# Apply bypass
./vbox-host-config.sh apply

# Restore original
./vbox-host-config.sh restore ./vbox-backup-20231201-143022
```

## 🚀 Quick Start Guide

### Untuk Guest OS (dalam VM):

1. **Copy scripts** ke dalam VM Windows
2. **Buka PowerShell as Administrator**
3. **Set execution policy** (jika diperlukan):
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```
4. **Detect kondisi awal:**
   ```powershell
   .\vbox-detect-initial.ps1
   ```
5. **Apply bypass:**
   ```powershell
   .\vbox-bypass-apply.ps1
   ```
6. **Restart VM**
7. **Test aplikasi** yang sebelumnya terdeteksi VM

### Untuk Host OS:

1. **Shutdown VM** terlebih dahulu
2. **Edit script** untuk sesuaikan nama VM
3. **Detect configuration:**
   ```bash
   ./vbox-host-config.sh detect
   ```
4. **Apply modifications:**
   ```bash
   ./vbox-host-config.sh apply
   ```
5. **Start VM** dan test

## 📊 Tingkat Efektivitas

| Metode | Success Rate | Kompleksitas | Impact |
|--------|-------------|--------------|---------|
| MAC Address Change | 90% | Rendah | Tinggi |
| BIOS/SMBIOS Spoofing | 95% | Sedang | Sangat Tinggi |
| Registry Cleanup | 85% | Rendah | Tinggi |
| Process Management | 70% | Tinggi | Sedang |
| Hardware Spoofing | 80% | Tinggi | Tinggi |

## 🔧 Troubleshooting

### VM Tidak Boot Setelah Apply

1. **Restore configuration:**
   ```bash
   ./vbox-host-config.sh restore <backup_directory>
   ```

2. **Reset ke BIOS jika EFI bermasalah:**
   ```bash
   VBoxManage modifyvm "YourVM" --firmware bios
   ```

### PowerShell Execution Policy Error

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### VirtualBox Services Tidak Start

```powershell
# Manual start services
Start-Service VBoxService -ErrorAction SilentlyContinue
```

### Backup Directory Tidak Ditemukan

```powershell
# List available backups
Get-ChildItem -Directory -Name "vbox-backup-*"
```

## 🛡️ Security Notes

1. **Backup selalu dibuat** sebelum modifikasi
2. **Administrator privileges** diperlukan
3. **VM harus shutdown** untuk host modifications
4. **Test di environment isolated** dulu
5. **Restore jika ada masalah**

## 🎯 Testing Recommendations

### Online VM Detection Tools:
- `checkvirtual.com`
- `hybrid-analysis.com`
- Custom detector tools

### Applications untuk Test:
- Banking applications
- DRM-protected software
- Anti-VM malware samples (research purpose)
- Online games dengan anti-cheat

## 📝 Logs dan Reports

Semua script menghasilkan:
- **Backup files** (JSON format)
- **Detection reports** 
- **Modification reports**
- **Restore reports**

Lokasi default: `./vbox-backup-YYYYMMDD-HHMMSS/`

## 🔄 Restoration Process

Jika ingin kembali ke kondisi normal VirtualBox:

1. **Guest OS:**
   ```powershell
   .\vbox-bypass-restore.ps1
   ```

2. **Host OS:**
   ```bash
   ./vbox-host-config.sh restore <backup_dir>
   ```

3. **Restart VM**

## ⚙️ Advanced Configuration

### Custom Hardware Spoofing

Edit file `vbox-host-config.sh` untuk custom manufacturer:

```bash
# Ganti Dell dengan manufacturer lain
VBoxManage setextradata "$VM_NAME" "VBoxInternal/Devices/efi/0/Config/DmiSystemVendor" "HP"
VBoxManage setextradata "$VM_NAME" "VBoxInternal/Devices/efi/0/Config/DmiSystemProduct" "EliteBook 850"
```

### Custom MAC Address

```bash
# Generate MAC dengan prefix tertentu
local new_mac="HP$(openssl rand -hex 4 | tr '[:lower:]' '[:upper:]')"
```

## 📚 References

- [VirtualBox Documentation](https://www.virtualbox.org/manual/)
- [VM Detection Techniques](https://evasions.checkpoint.com/)
- [Anti-VM Research](https://github.com/CheckPointSW/InviZzzible)

## 🤝 Contributing

Jika menemukan bug atau ingin improvement:
1. Test scripts di environment yang aman
2. Document issue dengan detail
3. Provide solution jika memungkinkan

---

**Happy Testing! 🚀** 
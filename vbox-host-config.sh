#!/bin/bash
# VirtualBox Host Configuration Script
# Script untuk konfigurasi VirtualBox di HOST OS (Linux/Windows dengan WSL)
# Author: VBox Bypass Tool
# Usage: ./vbox-host-config.sh [detect|apply|restore]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$SCRIPT_DIR/vbox-backup-$(date +%Y%m%d-%H%M%S)"
VM_NAME="Windows10"  # Change this to your VM name

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if VirtualBox is installed
check_vbox_installed() {
    if ! command -v VBoxManage &> /dev/null; then
        print_error "VirtualBox is not installed or not in PATH!"
        exit 1
    fi
    
    local vbox_version=$(VBoxManage --version 2>/dev/null)
    print_status "VirtualBox version: $vbox_version"
}

# Check if VM exists
check_vm_exists() {
    if ! VBoxManage list vms | grep -q "\"$VM_NAME\""; then
        print_error "VM '$VM_NAME' not found!"
        print_status "Available VMs:"
        VBoxManage list vms
        exit 1
    fi
}

# Function to detect current VM configuration
detect_vm_config() {
    print_status "=== VirtualBox Host Configuration Detection ==="
    
    check_vbox_installed
    check_vm_exists
    
    # Create backup directory
    mkdir -p "$BACKUP_DIR"
    print_success "Backup directory created: $BACKUP_DIR"
    
    print_status "Detecting current VM configuration for: $VM_NAME"
    
    # Get current VM info
    local vm_info=$(VBoxManage showvminfo "$VM_NAME" --machinereadable)
    echo "$vm_info" > "$BACKUP_DIR/vm_original_config.txt"
    
    print_status "[1] Hardware Configuration:"
    echo "$vm_info" | grep -E "(macaddress|biosbootmenu|firmware|chipset|paravirtprovider)" | while read line; do
        echo "  $line"
    done
    
    print_status "[2] System Information:"
    echo "$vm_info" | grep -E "(ostype|memory|vram|cpus)" | while read line; do
        echo "  $line"
    done
    
    print_status "[3] Storage Configuration:"
    echo "$vm_info" | grep -E "(storagecontroller|IDE|SATA)" | while read line; do
        echo "  $line"
    done
    
    print_status "[4] Network Configuration:"
    echo "$vm_info" | grep -E "(nic|macaddress|bridgeadapter)" | while read line; do
        echo "  $line"
    done
    
    # Save individual components for restoration
    echo "$vm_info" | grep "macaddress1=" | cut -d'=' -f2 | tr -d '"' > "$BACKUP_DIR/original_mac.txt"
    echo "$vm_info" | grep "biosbootmenu=" | cut -d'=' -f2 | tr -d '"' > "$BACKUP_DIR/original_biosbootmenu.txt"
    echo "$vm_info" | grep "firmware=" | cut -d'=' -f2 | tr -d '"' > "$BACKUP_DIR/original_firmware.txt"
    echo "$vm_info" | grep "paravirtprovider=" | cut -d'=' -f2 | tr -d '"' > "$BACKUP_DIR/original_paravirtprovider.txt"
    
    print_success "Configuration detected and backed up to: $BACKUP_DIR"
    
    # Check for VirtualBox signatures
    print_status "[5] VirtualBox Signature Detection:"
    
    local current_mac=$(echo "$vm_info" | grep "macaddress1=" | cut -d'=' -f2 | tr -d '"')
    if [[ $current_mac == 08002* ]]; then
        print_warning "VirtualBox MAC address detected: $current_mac"
    else
        print_success "MAC address looks legitimate: $current_mac"
    fi
    
    local firmware=$(echo "$vm_info" | grep "firmware=" | cut -d'=' -f2 | tr -d '"')
    if [[ $firmware == "BIOS" ]]; then
        print_warning "Using BIOS firmware (easily detectable)"
    else
        print_success "Using EFI firmware: $firmware"
    fi
    
    local paravirt=$(echo "$vm_info" | grep "paravirtprovider=" | cut -d'=' -f2 | tr -d '"')
    if [[ $paravirt != "none" ]]; then
        print_warning "Paravirtualization enabled: $paravirt"
    else
        print_success "Paravirtualization disabled"
    fi
}

# Function to apply bypass modifications
apply_bypass() {
    print_status "=== Applying VirtualBox Detection Bypass ==="
    
    check_vbox_installed
    check_vm_exists
    
    # Check if VM is running
    if VBoxManage list runningvms | grep -q "\"$VM_NAME\""; then
        print_error "VM '$VM_NAME' is currently running!"
        print_status "Please shut down the VM before applying bypass modifications."
        exit 1
    fi
    
    print_status "Applying bypass modifications to VM: $VM_NAME"
    
    # 1. Change MAC address to look like a real manufacturer
    print_status "[1] Changing MAC address..."
    local new_mac="DELLFC$(openssl rand -hex 3 | tr '[:lower:]' '[:upper:]')"
    VBoxManage modifyvm "$VM_NAME" --macaddress1 "$new_mac"
    print_success "MAC address changed to: $new_mac"
    
    # 2. Set BIOS/EFI information
    print_status "[2] Configuring BIOS/EFI settings..."
    VBoxManage modifyvm "$VM_NAME" --firmware efi
    VBoxManage modifyvm "$VM_NAME" --biosbootmenu disabled
    print_success "Firmware set to EFI, boot menu disabled"
    
    # 3. Disable paravirtualization
    print_status "[3] Disabling paravirtualization..."
    VBoxManage modifyvm "$VM_NAME" --paravirtprovider none
    print_success "Paravirtualization disabled"
    
    # 4. Set system information via EFI
    print_status "[4] Setting system information..."
    VBoxManage setextradata "$VM_NAME" "VBoxInternal/Devices/efi/0/Config/DmiSystemVendor" "Dell Inc."
    VBoxManage setextradata "$VM_NAME" "VBoxInternal/Devices/efi/0/Config/DmiSystemProduct" "OptiPlex 7090"
    VBoxManage setextradata "$VM_NAME" "VBoxInternal/Devices/efi/0/Config/DmiSystemVersion" "1.0"
    VBoxManage setextradata "$VM_NAME" "VBoxInternal/Devices/efi/0/Config/DmiSystemSerial" "$(openssl rand -hex 8 | tr '[:lower:]' '[:upper:]')"
    VBoxManage setextradata "$VM_NAME" "VBoxInternal/Devices/efi/0/Config/DmiSystemFamily" "OptiPlex"
    print_success "System information configured as Dell OptiPlex"
    
    # 5. Set motherboard information
    print_status "[5] Setting motherboard information..."
    VBoxManage setextradata "$VM_NAME" "VBoxInternal/Devices/efi/0/Config/DmiBoardVendor" "Dell Inc."
    VBoxManage setextradata "$VM_NAME" "VBoxInternal/Devices/efi/0/Config/DmiBoardProduct" "0K240Y"
    VBoxManage setextradata "$VM_NAME" "VBoxInternal/Devices/efi/0/Config/DmiBoardVersion" "A00"
    VBoxManage setextradata "$VM_NAME" "VBoxInternal/Devices/efi/0/Config/DmiBoardSerial" "$(openssl rand -hex 6 | tr '[:lower:]' '[:upper:]')"
    print_success "Motherboard information configured"
    
    # 6. Set CPU information
    print_status "[6] Setting CPU information..."
    VBoxManage setextradata "$VM_NAME" "VBoxInternal/Devices/efi/0/Config/DmiProcessorManufacturer" "Intel(R) Corporation"
    VBoxManage setextradata "$VM_NAME" "VBoxInternal/Devices/efi/0/Config/DmiProcessorVersion" "Intel(R) Core(TM) i7-8550U CPU @ 1.80GHz"
    print_success "CPU information configured"
    
    # 7. Set BIOS information
    print_status "[7] Setting BIOS information..."
    VBoxManage setextradata "$VM_NAME" "VBoxInternal/Devices/efi/0/Config/DmiBIOSVendor" "Dell Inc."
    VBoxManage setextradata "$VM_NAME" "VBoxInternal/Devices/efi/0/Config/DmiBIOSVersion" "1.21.0"
    VBoxManage setextradata "$VM_NAME" "VBoxInternal/Devices/efi/0/Config/DmiBIOSReleaseDate" "07/15/2023"
    print_success "BIOS information configured"
    
    # 8. Configure hardware virtualization
    print_status "[8] Configuring hardware virtualization..."
    VBoxManage modifyvm "$VM_NAME" --hwvirtex on
    VBoxManage modifyvm "$VM_NAME" --nestedpaging on
    VBoxManage modifyvm "$VM_NAME" --largepages on
    VBoxManage modifyvm "$VM_NAME" --vtxvpid on
    VBoxManage modifyvm "$VM_NAME" --vtxux on
    print_success "Hardware virtualization optimized"
    
    # 9. Set storage controller names
    print_status "[9] Configuring storage controllers..."
    # Note: This requires careful handling of existing storage
    print_warning "Storage controller configuration skipped (requires manual handling)"
    
    print_success "=== Bypass Applied Successfully ==="
    print_status "VM '$VM_NAME' has been configured to evade detection."
    print_warning "IMPORTANT: Start the VM and install/configure guest additions carefully."
    
    # Create bypass report
    cat > "$BACKUP_DIR/bypass_applied_report.txt" << EOF
VirtualBox Detection Bypass Applied
===================================
Timestamp: $(date)
VM Name: $VM_NAME
Backup Directory: $BACKUP_DIR

Modifications Applied:
- MAC address changed to: $new_mac
- Firmware set to EFI
- Paravirtualization disabled
- System information spoofed (Dell OptiPlex 7090)
- Motherboard information configured
- CPU information spoofed (Intel i7-8550U)
- BIOS information configured
- Hardware virtualization optimized

To restore original configuration:
./vbox-host-config.sh restore $BACKUP_DIR
EOF
    
    print_success "Bypass report saved to: $BACKUP_DIR/bypass_applied_report.txt"
}

# Function to restore original configuration
restore_config() {
    local restore_dir="$1"
    
    if [[ -z "$restore_dir" ]]; then
        print_error "Please specify backup directory to restore from"
        print_status "Usage: $0 restore <backup_directory>"
        exit 1
    fi
    
    if [[ ! -d "$restore_dir" ]]; then
        print_error "Backup directory not found: $restore_dir"
        exit 1
    fi
    
    print_status "=== Restoring Original VirtualBox Configuration ==="
    
    check_vbox_installed
    check_vm_exists
    
    # Check if VM is running
    if VBoxManage list runningvms | grep -q "\"$VM_NAME\""; then
        print_error "VM '$VM_NAME' is currently running!"
        print_status "Please shut down the VM before restoring configuration."
        exit 1
    fi
    
    print_status "Restoring configuration from: $restore_dir"
    
    # Restore MAC address
    if [[ -f "$restore_dir/original_mac.txt" ]]; then
        local original_mac=$(cat "$restore_dir/original_mac.txt")
        print_status "Restoring MAC address: $original_mac"
        VBoxManage modifyvm "$VM_NAME" --macaddress1 "$original_mac"
        print_success "MAC address restored"
    fi
    
    # Restore BIOS boot menu
    if [[ -f "$restore_dir/original_biosbootmenu.txt" ]]; then
        local original_biosbootmenu=$(cat "$restore_dir/original_biosbootmenu.txt")
        print_status "Restoring BIOS boot menu: $original_biosbootmenu"
        VBoxManage modifyvm "$VM_NAME" --biosbootmenu "$original_biosbootmenu"
        print_success "BIOS boot menu restored"
    fi
    
    # Restore firmware
    if [[ -f "$restore_dir/original_firmware.txt" ]]; then
        local original_firmware=$(cat "$restore_dir/original_firmware.txt")
        print_status "Restoring firmware: $original_firmware"
        VBoxManage modifyvm "$VM_NAME" --firmware "$original_firmware"
        print_success "Firmware restored"
    fi
    
    # Restore paravirtualization
    if [[ -f "$restore_dir/original_paravirtprovider.txt" ]]; then
        local original_paravirt=$(cat "$restore_dir/original_paravirtprovider.txt")
        print_status "Restoring paravirtualization: $original_paravirt"
        VBoxManage modifyvm "$VM_NAME" --paravirtprovider "$original_paravirt"
        print_success "Paravirtualization restored"
    fi
    
    # Remove all extra data that was added
    print_status "Removing spoofed system information..."
    VBoxManage setextradata "$VM_NAME" "VBoxInternal/Devices/efi/0/Config/DmiSystemVendor"
    VBoxManage setextradata "$VM_NAME" "VBoxInternal/Devices/efi/0/Config/DmiSystemProduct"
    VBoxManage setextradata "$VM_NAME" "VBoxInternal/Devices/efi/0/Config/DmiSystemVersion"
    VBoxManage setextradata "$VM_NAME" "VBoxInternal/Devices/efi/0/Config/DmiSystemSerial"
    VBoxManage setextradata "$VM_NAME" "VBoxInternal/Devices/efi/0/Config/DmiSystemFamily"
    VBoxManage setextradata "$VM_NAME" "VBoxInternal/Devices/efi/0/Config/DmiBoardVendor"
    VBoxManage setextradata "$VM_NAME" "VBoxInternal/Devices/efi/0/Config/DmiBoardProduct"
    VBoxManage setextradata "$VM_NAME" "VBoxInternal/Devices/efi/0/Config/DmiBoardVersion"
    VBoxManage setextradata "$VM_NAME" "VBoxInternal/Devices/efi/0/Config/DmiBoardSerial"
    VBoxManage setextradata "$VM_NAME" "VBoxInternal/Devices/efi/0/Config/DmiProcessorManufacturer"
    VBoxManage setextradata "$VM_NAME" "VBoxInternal/Devices/efi/0/Config/DmiProcessorVersion"
    VBoxManage setextradata "$VM_NAME" "VBoxInternal/Devices/efi/0/Config/DmiBIOSVendor"
    VBoxManage setextradata "$VM_NAME" "VBoxInternal/Devices/efi/0/Config/DmiBIOSVersion"
    VBoxManage setextradata "$VM_NAME" "VBoxInternal/Devices/efi/0/Config/DmiBIOSReleaseDate"
    print_success "Spoofed system information removed"
    
    print_success "=== Configuration Restored Successfully ==="
    print_status "VM '$VM_NAME' has been restored to original configuration."
    
    # Create restore report
    cat > "$restore_dir/restore_completed_report.txt" << EOF
VirtualBox Configuration Restored
=================================
Timestamp: $(date)
VM Name: $VM_NAME
Restore Directory: $restore_dir

Components Restored:
- MAC address
- BIOS boot menu setting
- Firmware type
- Paravirtualization provider
- System information (removed spoofed data)
- Motherboard information (removed spoofed data)
- CPU information (removed spoofed data)
- BIOS information (removed spoofed data)

Original configuration has been restored.
EOF
    
    print_success "Restore report saved to: $restore_dir/restore_completed_report.txt"
}

# Main script logic
case "${1:-detect}" in
    "detect")
        detect_vm_config
        ;;
    "apply")
        apply_bypass
        ;;
    "restore")
        restore_config "$2"
        ;;
    *)
        echo "Usage: $0 [detect|apply|restore] [backup_directory]"
        echo ""
        echo "Commands:"
        echo "  detect  - Detect current VM configuration and create backup"
        echo "  apply   - Apply VirtualBox detection bypass modifications"
        echo "  restore - Restore original configuration from backup"
        echo ""
        echo "Examples:"
        echo "  $0 detect"
        echo "  $0 apply"
        echo "  $0 restore ./vbox-backup-20231201-143022"
        exit 1
        ;;
esac 
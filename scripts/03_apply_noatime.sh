#!/bin/bash

# Apply noatime optimization to mounted filesystems
# This script remounts filesystems with noatime option to improve I/O performance

set -e

echo "=== Applying noatime Optimization ==="
echo "Starting at: $(date)"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script requires root privileges for mount operations"
   echo "Please run with: sudo $0"
   exit 1
fi

# Backup current mount options
echo "Backing up current mount configuration..."
cp /etc/fstab /etc/fstab.backup.$(date +%Y%m%d_%H%M%S)

# Function to remount with noatime
apply_noatime() {
    local mount_point=$1
    local device=$(findmnt -n -o SOURCE "$mount_point" 2>/dev/null)
    
    if [[ -z "$device" ]]; then
        echo "Warning: No device found for $mount_point"
        return 1
    fi
    
    echo "Applying noatime to $mount_point (device: $device)"
    
    # Get current mount options
    local current_opts=$(findmnt -n -o OPTIONS "$mount_point")
    
    # Check if noatime is already set
    if echo "$current_opts" | grep -q "noatime"; then
        echo "  noatime already applied to $mount_point"
        return 0
    fi
    
    # Remount with noatime
    mount -o remount,noatime "$mount_point"
    
    if [[ $? -eq 0 ]]; then
        echo "  Successfully applied noatime to $mount_point"
        
        # Update fstab for persistence
        if grep -q "$mount_point" /etc/fstab; then
            sed -i.bak "s|\\($mount_point.*defaults\\)|\\1,noatime|" /etc/fstab
            echo "  Updated /etc/fstab for $mount_point"
        fi
    else
        echo "  Failed to apply noatime to $mount_point"
        return 1
    fi
}

# Apply noatime to test mount points
MOUNT_POINTS=(
    "/mnt/nvme_test"
    "/mnt/graid0_test"
    "/mnt/graid1_test"
)

for mount_point in "${MOUNT_POINTS[@]}"; do
    if mountpoint -q "$mount_point" 2>/dev/null; then
        apply_noatime "$mount_point"
    else
        echo "Skipping $mount_point - not mounted"
    fi
done

# Also optimize system mount points if requested
read -p "Apply noatime to system mounts (/tmp, /var)? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    apply_noatime "/tmp" || true
    apply_noatime "/var" || true
fi

# Display current mount options
echo ""
echo "Current mount options:"
mount | grep -E "(nvme|graid|noatime)" || true

# Additional I/O optimizations
echo ""
echo "Applying additional I/O optimizations..."

# Set I/O scheduler for NVMe devices (none is best for NVMe)
for device in /sys/block/nvme*/queue/scheduler; do
    if [[ -w "$device" ]]; then
        echo "none" > "$device"
        echo "Set scheduler to 'none' for $(dirname $(dirname $device))"
    fi
done

# Increase read-ahead for sequential workloads
for device in /sys/block/*/queue/read_ahead_kb; do
    if [[ -w "$device" ]]; then
        echo "2048" > "$device"
        echo "Set read-ahead to 2048KB for $(dirname $(dirname $device))"
    fi
done

echo ""
echo "=== Optimization Complete ==="
echo "Changes applied:"
echo "1. noatime option added to specified mount points"
echo "2. I/O scheduler set to 'none' for NVMe devices"
echo "3. Read-ahead increased to 2048KB"
echo ""
echo "Run 04_optimized_fio_test.sh to measure performance improvements"
# Troubleshooting Guide

This guide helps resolve common issues encountered during AOSP storage performance testing.

## Common Issues and Solutions

### 1. NVMe Device Not Detected

**Symptoms:**
- `nvme list` shows no devices
- `/dev/nvme*` devices missing

**Solutions:**
```bash
# Check if NVMe module is loaded
lsmod | grep nvme

# Load NVMe module if missing
modprobe nvme
modprobe nvme_core

# Check PCIe devices
lspci | grep -i nvme

# Rescan PCIe bus
echo 1 > /sys/bus/pci/rescan
```

### 2. Mount Failed: Wrong fs type

**Symptoms:**
- Error: "mount: wrong fs type, bad option, bad superblock"

**Solutions:**
```bash
# Check filesystem type
file -s /dev/nvme0n1
blkid /dev/nvme0n1

# Install filesystem utilities
apt-get install xfsprogs  # For XFS
apt-get install e2fsprogs # For ext4

# Check for filesystem corruption
xfs_repair -n /dev/nvme0n1  # Dry run
```

### 3. FIO Tests Running Slowly

**Symptoms:**
- FIO shows lower than expected performance
- High latency reported

**Solutions:**
```bash
# Check if direct I/O is working
strace -e open,openat fio [options] 2>&1 | grep O_DIRECT

# Verify mount options
mount | grep nvme

# Check for CPU throttling
cpupower frequency-info

# Disable CPU power saving
cpupower frequency-set -g performance
```

### 4. noatime Not Taking Effect

**Symptoms:**
- Access times still being updated
- Performance not improved

**Solutions:**
```bash
# Verify current mount options
findmnt -t xfs,ext4 -o TARGET,SOURCE,OPTIONS

# Force remount
umount /mnt/nvme_test
mount -o noatime,nodiratime /dev/nvme0n1 /mnt/nvme_test

# Check if option is in /etc/fstab
grep nvme /etc/fstab
```

### 5. GRAID Not Performing as Expected

**Symptoms:**
- GRAID performance lower than individual drives
- Uneven load distribution

**Solutions:**
```bash
# Check GRAID status
graidctl status -v

# Verify all drives are active
graidctl show graid0

# Check individual drive performance
for i in /dev/nvme[1-8]n1; do
    echo "Testing $i"
    dd if=$i of=/dev/null bs=1M count=1000 iflag=direct
done

# Rebuild GRAID array if needed
graidctl delete graid0
graidctl create -n graid0 -l 0 -d /dev/nvme[1-8]n1
```

### 6. Out of Memory During AOSP Build

**Symptoms:**
- Build fails with "virtual memory exhausted"
- System becomes unresponsive

**Solutions:**
```bash
# Check memory usage
free -h

# Reduce parallel jobs
make -j32  # Instead of -j64

# Increase swap (temporary)
dd if=/dev/zero of=/swapfile bs=1G count=32
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile

# Monitor memory during build
vmstat 1 > memory_log.txt &
```

### 7. Storage Device Overheating

**Symptoms:**
- Performance drops during sustained tests
- NVMe temperature warnings

**Solutions:**
```bash
# Check NVMe temperature
nvme smart-log /dev/nvme0n1 | grep temperature

# Monitor temperatures
watch -n 1 'nvme smart-log /dev/nvme0n1 | grep temperature'

# Reduce workload if overheating
# Add delays between tests
# Improve cooling
```

### 8. Inconsistent Test Results

**Symptoms:**
- Large variations between test runs
- Results not reproducible

**Solutions:**
```bash
# Clear caches before each test
sync && echo 3 > /proc/sys/vm/drop_caches

# Ensure no background processes
iotop
top

# Disable automatic maintenance
systemctl stop apt-daily.timer
systemctl stop apt-daily-upgrade.timer

# Use consistent test parameters
# Always use --time_based in fio
```

## Performance Debugging Commands

```bash
# Check for I/O errors
dmesg | grep -i error

# Monitor block device stats
watch -n 1 'cat /sys/block/nvme0n1/stat'

# Trace I/O operations
blktrace -d /dev/nvme0n1 -o trace

# Analyze I/O patterns
iostat -x 1 | tee iostat_log.txt

# Check interrupt distribution
cat /proc/interrupts | grep nvme
```

## Getting Help

If issues persist:

1. Collect system information:
   ```bash
   uname -a > system_info.txt
   lspci -vv >> system_info.txt
   dmesg >> system_info.txt
   mount >> system_info.txt
   ```

2. Run diagnostic script:
   ```bash
   bash -x ./scripts/01_setup_environment.sh 2>&1 | tee setup_debug.log
   ```

3. Open an issue on GitHub with:
   - System information
   - Error messages
   - Steps to reproduce
   - Diagnostic logs
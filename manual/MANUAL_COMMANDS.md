# Manual Commands Reference

This document contains manual commands for AOSP storage performance testing and optimization.

## Storage Device Identification

```bash
# List all NVMe devices
nvme list

# Show detailed NVMe information
nvme id-ctrl /dev/nvme0n1

# List block devices with details
lsblk -o NAME,SIZE,TYPE,FSTYPE,MODEL,SERIAL,MOUNTPOINT

# Check RAID configuration
cat /proc/mdstat
```

## Filesystem Creation

```bash
# Create XFS filesystem on NVMe
mkfs.xfs -f -L aosp_nvme /dev/nvme0n1

# Create XFS with specific options
mkfs.xfs -f -d agcount=32 -l size=512m -L aosp_graid /dev/graid0

# Create ext4 (not recommended for performance)
mkfs.ext4 -L aosp_test /dev/nvme0n1
```

## Mount Operations

```bash
# Mount with noatime
mount -o noatime,nodiratime /dev/nvme0n1 /mnt/nvme_test

# Mount XFS with additional options
mount -o noatime,nodiratime,logbufs=8,logbsize=256k /dev/graid0 /mnt/graid0_test

# Remount with new options
mount -o remount,noatime /mnt/nvme_test
```

## Performance Testing

```bash
# Quick FIO test - Sequential Read
fio --name=seq_read --filename=/mnt/nvme_test/test.fio --size=10G --runtime=60 \
    --ioengine=libaio --direct=1 --bs=1M --iodepth=32 --rw=read

# Quick FIO test - Random 4K Write
fio --name=rand_write_4k --filename=/mnt/graid0_test/test.fio --size=10G --runtime=60 \
    --ioengine=libaio --direct=1 --bs=4k --iodepth=32 --numjobs=8 --rw=randwrite --group_reporting

# AOSP-like workload simulation
fio --name=aosp_sim --filename=/mnt/graid1_test/test.fio --size=50G --runtime=300 \
    --ioengine=libaio --direct=0 --bs=4k-1M --iodepth=64 --numjobs=32 \
    --rwmixread=70 --rw=randrw --group_reporting
```

## I/O Optimization

```bash
# Set I/O scheduler for NVMe
echo none > /sys/block/nvme0n1/queue/scheduler

# Increase read-ahead
echo 2048 > /sys/block/nvme0n1/queue/read_ahead_kb

# Set nr_requests
echo 256 > /sys/block/nvme0n1/queue/nr_requests

# Check current settings
cat /sys/block/nvme*/queue/scheduler
cat /sys/block/nvme*/queue/read_ahead_kb
```

## GRAID Specific Commands

```bash
# Create GRAID array (example)
graidctl create -n graid0 -l 0 -d /dev/nvme[1-3]n1

# Check GRAID status
graidctl status

# Monitor GRAID performance
graidctl monitor -i 1
```

## AOSP Build Commands

```bash
# Set up build environment
source build/envsetup.sh
lunch aosp_arm64-eng

# Build with optimized paths
export OUT_DIR=/mnt/nvme_test/aosp_out
export CCACHE_DIR=/mnt/nvme_test/ccache
ccache -M 100G

# Time the build
time make -j64

# Monitor I/O during build
iotop -b -d 1 > build_io_log.txt &
```

## Monitoring Commands

```bash
# Real-time I/O statistics
iostat -x 1

# NVMe specific monitoring
nvme smart-log /dev/nvme0n1

# Check mount options
findmnt -t xfs,ext4

# Monitor specific process I/O
pidstat -d 1

# System-wide I/O summary
sar -b 1 10
```

## Cleanup Commands

```bash
# Clear page cache
sync && echo 3 > /proc/sys/vm/drop_caches

# TRIM/discard for SSDs
fstrim -v /mnt/nvme_test

# Remove test files
rm -f /mnt/*/test.fio
```
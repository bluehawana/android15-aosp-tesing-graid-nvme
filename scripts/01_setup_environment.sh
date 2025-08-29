#!/bin/bash

# AOSP Build Environment Setup Script
# This script prepares the system for AOSP build performance testing

set -e

echo "=== AOSP Build Environment Setup ==="
echo "Starting at: $(date)"

# Check if running as root for mount operations
if [[ $EUID -ne 0 ]]; then
   echo "This script requires root privileges for mount operations"
   echo "Please run with: sudo $0"
   exit 1
fi

# Install required packages
echo "Installing required packages..."
apt-get update || yum update
apt-get install -y fio hdparm smartmontools iotop sysstat || \
yum install -y fio hdparm smartmontools iotop sysstat

# Create test directories
echo "Creating test directories..."
mkdir -p /mnt/nvme_test
mkdir -p /mnt/graid0_test  
mkdir -p /mnt/graid1_test
mkdir -p ~/aosp_build_test/results

# Check for NVMe devices
echo "Detecting NVMe devices..."
nvme list

# Display storage configuration
echo "Current storage configuration:"
lsblk -d -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT,MODEL

# Set up performance monitoring
echo "Setting up performance monitoring..."
systemctl start sysstat || service sysstat start

echo "=== Setup Complete ==="
echo "Next steps:"
echo "1. Mount your test drives to /mnt/nvme_test, /mnt/graid0_test, /mnt/graid1_test"
echo "2. Run 02_baseline_fio_test.sh to measure baseline performance"
echo "3. Apply optimizations with 03_apply_noatime.sh"
echo "4. Run 04_optimized_fio_test.sh to measure optimized performance"
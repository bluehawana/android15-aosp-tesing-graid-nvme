#!/bin/bash

# AOSP 15 Setup Script for Azure VM with NVMe RAID 0
# Run this script on your Azure VM as azureuser

set -e

echo "=== AOSP 15 Build Environment Setup ==="
echo "This script will configure NVMe RAID 0 and set up AOSP 15 build environment"
echo ""

# Step 1: Configure NVMe RAID 0
echo "Step 1: Configuring NVMe RAID 0..."
sudo mdadm --create /dev/md0 --level=0 --raid-devices=2 /dev/nvme0n1 /dev/nvme1n1 --assume-clean

# Create filesystem
echo "Creating ext4 filesystem..."
sudo mkfs.ext4 -F /dev/md0

# Mount the RAID array
echo "Mounting RAID array..."
sudo mkdir -p /aosp
sudo mount /dev/md0 /aosp
sudo chown -R azureuser:azureuser /aosp

# Make mount persistent
echo "Configuring persistent mount..."
echo '/dev/md0 /aosp ext4 defaults,noatime 0 0' | sudo tee -a /etc/fstab

# Save RAID configuration
sudo mdadm --detail --scan | sudo tee -a /etc/mdadm/mdadm.conf
sudo update-initramfs -u

# Step 2: Install AOSP dependencies
echo ""
echo "Step 2: Installing AOSP 15 build dependencies..."
sudo apt-get update
sudo apt-get install -y \
    git-core gnupg flex bison build-essential zip curl \
    zlib1g-dev libc6-dev-i386 libncurses5 lib32ncurses5-dev \
    x11proto-core-dev libx11-dev lib32z1-dev libgl1-mesa-dev \
    libxml2-utils xsltproc unzip fontconfig \
    python3 python3-pip python-is-python3 \
    openjdk-17-jdk \
    bc bison build-essential ccache curl flex g++-multilib \
    gcc-multilib git git-lfs gnupg gperf imagemagick \
    lib32readline-dev lib32z1-dev libelf-dev liblz4-tool \
    libsdl1.2-dev libssl-dev libxml2 libxml2-utils \
    lzop pngcrush rsync schedtool squashfs-tools xsltproc \
    zip zlib1g-dev

# Step 3: Install repo tool
echo ""
echo "Step 3: Installing repo tool..."
mkdir -p ~/bin
curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
chmod a+x ~/bin/repo

# Add to PATH
echo 'export PATH=~/bin:$PATH' >> ~/.bashrc
export PATH=~/bin:$PATH

# Step 4: Configure git
echo ""
echo "Step 4: Configuring git..."
git config --global user.name "AOSP Builder"
git config --global user.email "aosp@example.com"

# Step 5: Initialize AOSP 15 source
echo ""
echo "Step 5: Initializing AOSP 15 source tree..."
cd /aosp
repo init -u https://android.googlesource.com/platform/manifest -b android-15.0.0_r1

# Step 6: Sync AOSP source (this will take a while)
echo ""
echo "Step 6: Syncing AOSP source (this will take 1-2 hours)..."
repo sync -c -j$(nproc) --force-sync --no-clone-bundle --no-tags

# Step 7: Set up build environment
echo ""
echo "Step 7: Setting up build environment..."
cd /aosp
source build/envsetup.sh

# Step 8: Configure ccache for faster rebuilds
echo ""
echo "Step 8: Configuring ccache..."
export USE_CCACHE=1
export CCACHE_DIR=/aosp/.ccache
ccache -M 50G

echo ""
echo "=== Setup Complete ==="
echo ""
echo "To build AOSP 15, run:"
echo "  cd /aosp"
echo "  source build/envsetup.sh"
echo "  lunch aosp_arm64-eng"
echo "  make -j\$(nproc)"
echo ""
echo "Build output will be in: /aosp/out/"
#!/bin/bash

# Quick AOSP 15 Build Script
# Run this after the initial setup is complete

set -e

echo "=== Starting AOSP 15 Build ==="
echo ""

# Navigate to AOSP directory
cd /aosp

# Set up environment
echo "Setting up build environment..."
source build/envsetup.sh

# Select build target
echo ""
echo "Available lunch targets:"
echo "1. aosp_arm64-eng (ARM64 emulator, engineering build)"
echo "2. aosp_x86_64-eng (x86_64 emulator, engineering build)"
echo "3. aosp_arm64-userdebug (ARM64 emulator, userdebug build)"
echo ""
read -p "Enter lunch target (default: aosp_arm64-eng): " LUNCH_TARGET
LUNCH_TARGET=${LUNCH_TARGET:-aosp_arm64-eng}

echo "Building target: $LUNCH_TARGET"
lunch $LUNCH_TARGET

# Start build with performance monitoring
echo ""
echo "Starting build with $(nproc) threads..."
echo "Build started at: $(date)"
START_TIME=$(date +%s)

# Run build
make -j$(nproc) 2>&1 | tee /aosp/build-logs/build-output-$(date +%Y%m%d-%H%M%S).log

# Calculate build time
END_TIME=$(date +%s)
BUILD_TIME=$((END_TIME - START_TIME))
BUILD_HOURS=$((BUILD_TIME / 3600))
BUILD_MINUTES=$(((BUILD_TIME % 3600) / 60))
BUILD_SECONDS=$((BUILD_TIME % 60))

echo ""
echo "=== Build Complete ==="
echo "Build finished at: $(date)"
echo "Total build time: ${BUILD_HOURS}h ${BUILD_MINUTES}m ${BUILD_SECONDS}s"
echo ""
echo "Build output location: /aosp/out/target/product/"
echo ""

# Show build artifacts
echo "Build artifacts:"
ls -lh /aosp/out/target/product/*/system.img 2>/dev/null || echo "No system.img found"
ls -lh /aosp/out/target/product/*/vendor.img 2>/dev/null || echo "No vendor.img found"
ls -lh /aosp/out/target/product/*/userdata.img 2>/dev/null || echo "No userdata.img found"
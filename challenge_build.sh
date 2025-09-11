#!/bin/bash
# AOSP 15 World Record Challenge Script
# Current Record: 7:47 by bluehawana team with GRAID technology
# Challenge our record and share your results!

set -e

echo "=================================================="
echo "   AOSP 15 BUILD WORLD RECORD CHALLENGE"
echo "   Current Record: 7 minutes 47 seconds"
echo "   Target: aosp_x86_64-eng"
echo "=================================================="
echo ""

# Check available resources
echo "Your System Resources:"
echo "CPU Cores: $(nproc)"
echo "RAM: $(free -h | awk '/^Mem:/ {print $2}')"
echo "Available Disk: $(df -h . | awk 'NR==2 {print $4}')"
echo ""

# Verify minimum requirements
if [ $(nproc) -lt 32 ]; then
    echo "⚠️  Warning: Less than 32 cores detected. Build will be slower."
fi

if [ $(free -g | awk '/^Mem:/ {print $2}') -lt 64 ]; then
    echo "⚠️  Warning: Less than 64GB RAM detected. May cause issues."
fi

echo "Press Enter to start the challenge or Ctrl+C to abort..."
read

# Create build directory
BUILD_DIR="$HOME/aosp15-challenge-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

echo "📁 Build directory: $BUILD_DIR"
echo ""

# Initialize repo
echo "🔄 Initializing AOSP 15 repository..."
repo init -u https://android.googlesource.com/platform/manifest -b android-15.0.0_r1 --depth=1

# Sync source with maximum parallelism
echo "📥 Syncing AOSP source (this will take 30-60 minutes)..."
SYNC_START=$(date +%s)
repo sync -c -j$(nproc) --force-sync --no-clone-bundle --no-tags --optimized-fetch --prune
SYNC_END=$(date +%s)
SYNC_TIME=$((SYNC_END - SYNC_START))
echo "✅ Sync completed in $((SYNC_TIME/60)) minutes"
echo ""

# Setup build environment
echo "🔧 Setting up build environment..."
source build/envsetup.sh

# Select target
echo "🎯 Selecting build target: aosp_x86_64-eng"
lunch aosp_x86_64-eng

# Clear any previous builds
echo "🧹 Ensuring clean build environment..."
m clean

echo ""
echo "=================================================="
echo "   STARTING TIMED BUILD CHALLENGE"
echo "   Record to beat: 7:47"
echo "=================================================="
echo ""

# Start the timed build
BUILD_START=$(date +%s)
BUILD_START_TIME=$(date '+%Y-%m-%d %H:%M:%S')
echo "⏱️  Build started at: $BUILD_START_TIME"
echo ""

# Run the build with progress tracking
m -j$(nproc) 2>&1 | tee build.log | while IFS= read -r line; do
    if [[ "$line" == *"build completed successfully"* ]]; then
        echo ""
        echo "=================================================="
        echo "$line"
        echo "=================================================="
    else
        echo "$line"
    fi
done

# Calculate build time
BUILD_END=$(date +%s)
BUILD_END_TIME=$(date '+%Y-%m-%d %H:%M:%S')
BUILD_TIME=$((BUILD_END - BUILD_START))
BUILD_MINUTES=$((BUILD_TIME/60))
BUILD_SECONDS=$((BUILD_TIME%60))

echo ""
echo "=================================================="
echo "   BUILD CHALLENGE RESULTS"
echo "=================================================="
echo "Start Time: $BUILD_START_TIME"
echo "End Time: $BUILD_END_TIME"
echo "Build Duration: ${BUILD_MINUTES} minutes ${BUILD_SECONDS} seconds"
echo ""

# Compare with record
RECORD_SECONDS=$((7*60 + 47))  # 7:47 in seconds
if [ $BUILD_TIME -lt $RECORD_SECONDS ]; then
    echo "🏆 NEW WORLD RECORD! You beat 7:47!"
    echo "🎉 Congratulations! Please share your results!"
else
    DIFF=$((BUILD_TIME - RECORD_SECONDS))
    echo "📊 Your build was $((DIFF/60))m $((DIFF%60))s slower than the record"
    echo "💪 Keep optimizing to beat 7:47!"
fi

echo ""
echo "=================================================="
echo "Share your results: https://github.com/bluehawana/android15-aosp-tesing-graid-nvme"
echo "Include: Hardware specs, OS version, and build.log"
echo "=================================================="

# Save results summary
cat > challenge_results.txt << EOF
AOSP 15 Build Challenge Results
================================
Date: $(date)
Build Time: ${BUILD_MINUTES}:${BUILD_SECONDS}
CPU Cores: $(nproc)
RAM: $(free -h | awk '/^Mem:/ {print $2}')
OS: $(lsb_release -ds 2>/dev/null || echo "Unknown")
Kernel: $(uname -r)
Filesystem: $(df -T . | awk 'NR==2 {print $2}')

World Record: 7:47 (467 seconds)
Your Time: ${BUILD_MINUTES}:${BUILD_SECONDS} (${BUILD_TIME} seconds)
Difference: $((BUILD_TIME - RECORD_SECONDS)) seconds
EOF

echo ""
echo "📄 Results saved to: $BUILD_DIR/challenge_results.txt"
echo "📜 Build log saved to: $BUILD_DIR/build.log"
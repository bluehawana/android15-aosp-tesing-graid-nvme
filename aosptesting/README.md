# AOSP Testing Configuration

This directory contains AOSP-specific testing configurations and scripts.

## Contents

- Build configuration files
- AOSP-specific test scripts
- Performance measurement tools
- Build optimization settings

## Usage

Place your AOSP build configuration files here when setting up test environments.

### Example Build Configuration

```bash
# Source build environment
source build/envsetup.sh

# Select target
lunch aosp_arm64-eng

# Set optimized paths
export OUT_DIR=/mnt/nvme_test/aosp_out
export CCACHE_DIR=/mnt/nvme_test/ccache

# Enable ccache
export USE_CCACHE=1
ccache -M 100G

# Build
make -j$(nproc)
```

### Performance Monitoring

Monitor build performance using:
- `time` command for overall build time
- `iostat` for I/O statistics
- `htop` for CPU utilization
- Custom scripts in parent `scripts/` directory
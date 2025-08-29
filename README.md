# Android 15 AOSP Build Performance Testing & Optimization

## 🚀 Overview

This repository provides comprehensive testing and optimization strategies for Android Open Source Project (AOSP) builds, focusing on I/O performance improvements through strategic storage configuration. Our testing framework helps identify optimal storage configurations for CI/CD pipelines and local development environments.

**Primary Objective:** Optimize on-premise server performance to achieve faster AOSP build times than cloud-based VM solutions on Azure Kubernetes Service (AKS), leveraging high-performance NVMe storage arrays and advanced RAID configurations.

## 🎯 Project Goals

- **Reduce AOSP build times** by up to 40% through I/O optimization
- **Compare performance** across different storage technologies (NVMe, GRAID, RAID)
- **Provide automated testing** scripts for reproducible benchmarks
- **Document best practices** for storage configuration in AOSP development

## 🔧 Hardware Configurations Tested

### Storage Systems

| Storage Type | Capacity | Interface | Use Case |
|-------------|----------|-----------|----------|
| **PM1733 NVMe SSD** | 3.7TB | PCIe 4.0 | High-speed builds, critical paths |
| **GRAID Card** | Variable | PCIe | Parallel build operations |
| **Hardware RAID** | 8.7TB - 28TB | SAS/SATA | Large-scale storage, artifacts |

### Detailed Test Server Specifications

**Dell PowerEdge R7625**

| Component | Specification | Quantity | Total Capacity |
|-----------|---------------|----------|----------------|
| **CPU** | AMD EPYC 9534 @ 3.84GHz, 32 cores | 2 | 64 cores / 128 threads |
| **RAM** | DDR5 ECC | - | 768 GB |
| **System SSD** | 480 GB SATA SSD | 2 | 960 GB (RAID 1) |
| **NVMe Storage** | | | |
| - Samsung PM1735a | 3.2 TB PCIe 4.0 | 3 | 9.6 TB |
| - Samsung PM1733 | 3.84 TB PCIe 4.0 | 21 | 80.64 TB |
| **GRAID Configuration** | | | |
| - GRAID Card 0 | 3x PM1735a | 1 | 9.6 TB (ext4 → XFS) |
| - GRAID Card 1 | 8x PM1733 (RAID 0) | 1 | 30.72 TB (XFS) |

> **Note:** The dual-socket AMD EPYC configuration provides exceptional parallel processing capability for AOSP builds, while the massive NVMe array ensures I/O is never a bottleneck.

## 📊 Performance Results

### AOSP 15 Compilation Test Results (August 27th, 2024)

| Storage Configuration | Filesystem | Build Time | Performance Notes |
|----------------------|------------|------------|-------------------|
| **Samsung PM1733 NVMe** (Single) | Default | 27.87 mins | Baseline performance |
| **GRAID Card 0** (3x Samsung PM1735a) | ext4 | 28.03 mins | ⚠️ ext4 not recommended for high performance |
| **GRAID Card 1** (8x PM1733 RAID 0) | XFS | **9.53 mins** | 🏆 Best performance - 66% faster than baseline |

> **Key Finding:** RAID 0 with 8x NVMe drives reduces AOSP build time by 66% compared to single NVMe

### I/O Benchmark Results

#### Baseline Performance (Default Configuration)

| Storage | Sequential Read | Sequential Write | Random 4K Read | Random 4K Write |
|---------|----------------|------------------|----------------|-----------------|
| PM1733 NVMe | TBD | TBD | TBD | TBD |
| GRAID Card 0 (ext4) | TBD | TBD | TBD | TBD |
| GRAID Card 1 (XFS) | TBD | TBD | TBD | TBD |

#### Optimized Performance (With noatime + XFS)

| Storage | Sequential Read | Sequential Write | Random 4K Read | Random 4K Write | Build Time Impact |
|---------|----------------|------------------|----------------|-----------------|-------------------|
| PM1733 NVMe | TBD | TBD | TBD | TBD | TBD |
| GRAID Card 0 (XFS) | TBD | TBD | TBD | TBD | TBD |
| GRAID Card 1 (XFS) | 3,858 MB/s | 2,402 MB/s | 107 MB/s | 1,829 MB/s | -66% |

> **Update (August 29th):** Applied noatime to all drives and converted GRAID Card 0 from ext4 to XFS. Results pending...

## 🛠️ Quick Start

### Prerequisites

- Linux system (Ubuntu 20.04+ or similar)
- Root access for mount operations
- `fio` benchmark tool
- AOSP development environment

### Installation

```bash
# Clone the repository
git clone https://github.com/bluehawana/android15-aosp-testing-graid-nvme.git
cd android15-aosp-testing-graid-nvme

# Make scripts executable
chmod +x scripts/*.sh

# Run initial setup
./scripts/01_setup_environment.sh
```

### Running Tests

```bash
# Run complete test suite
./scripts/run_all_tests.sh

# Or run individual tests
./scripts/02_baseline_fio_test.sh    # Baseline performance
./scripts/03_apply_noatime.sh         # Apply optimizations
./scripts/04_optimized_fio_test.sh    # Test with optimizations
```

## 📁 Repository Structure

```
.
├── README.md              # This file
├── config/               # Configuration templates
│   └── storage_config.template
├── scripts/              # Automation scripts
│   ├── 01_setup_environment.sh
│   ├── 02_baseline_fio_test.sh
│   ├── 03_apply_noatime.sh
│   ├── 04_optimized_fio_test.sh
│   └── run_all_tests.sh
├── results/              # Test results (auto-generated)
├── manual/               # Manual testing procedures
│   ├── MANUAL_COMMANDS.md
│   └── TROUBLESHOOTING.md
└── aosptesting/          # AOSP-specific test configurations
```

## 🔍 Key Optimizations

### 1. Filesystem Mount Options
- **noatime**: Disable access time updates
- **nodiratime**: Disable directory access time updates
- **discard**: Enable TRIM support for SSDs

### 2. I/O Scheduler Tuning
- Set optimal scheduler (none/mq-deadline for NVMe)
- Adjust queue depths
- Configure read-ahead values

### 3. AOSP Build Specific
- Strategic file placement across storage tiers
- Parallel build job optimization
- ccache configuration on fastest storage

## 📈 Benchmark Methodology

Our testing uses industry-standard `fio` benchmarks with:
- 1GB test files
- Direct I/O to bypass caching
- Multiple queue depths (1, 8, 32)
- Various block sizes (4K for random, 1M for sequential)

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Run tests to ensure compatibility
4. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
5. Push to the branch (`git push origin feature/AmazingFeature`)
6. Open a Pull Request

## 📝 Best Practices

### For CI/CD Environments
- Use NVMe for source code and build outputs
- Configure RAID arrays for artifact storage
- Implement build caching on fastest available storage

### For Local Development
- Mount `/tmp` on NVMe with noatime
- Use separate partitions for source and output
- Regular TRIM operations for sustained performance

## ⚠️ Important Notes

- Always backup data before applying optimizations
- Test optimizations in non-production environments first
- Monitor storage health with S.M.A.R.T. tools
- Consider wear leveling for SSD longevity

## 📚 References & Documentation

### Hardware Documentation
- [Samsung PM1733 NVMe SSD Datasheet](https://semiconductor.samsung.com/resources/data-sheet/Samsung_PM1733_1735_NVMe_SSD_Data_Sheet_Rev2.0.pdf) - Enterprise NVMe specifications and performance characteristics
- [Samsung PM1735a NVMe SSD Documentation](https://semiconductor.samsung.com/ssd/enterprise-ssd/pm1735/) - High-performance PCIe 4.0 enterprise SSD details
- [Dell PowerEdge R7625 Technical Guide](https://www.dell.com/support/home/en-us/product-support/product/poweredge-r7625/docs) - Server specifications and configuration options
- [AMD EPYC 9534 Processor Details](https://www.amd.com/en/products/cpu/amd-epyc-9534) - CPU architecture and performance specifications

### AOSP Build System
- [Android 15 Release Notes](https://developer.android.com/about/versions/15) - Official Android 15 features and changes
- [AOSP Build System Documentation](https://source.android.com/docs/setup/build) - Comprehensive guide to building Android from source
- [AOSP Performance Tuning Guide](https://source.android.com/docs/core/perf/build-times) - Official recommendations for optimizing build performance

### Linux Performance Optimization
- [Linux Filesystem Mount Options](https://www.kernel.org/doc/html/latest/filesystems/ext4/mount.html) - Detailed explanation of filesystem mount parameters
- [Why noatime Improves Performance](https://lwn.net/Articles/245002/) - Technical analysis of access time impact on I/O performance
- [XFS Performance Tuning](https://www.kernel.org/doc/Documentation/filesystems/xfs.txt) - XFS filesystem optimization guide
- [Linux I/O Scheduler Documentation](https://www.kernel.org/doc/html/latest/block/index.html) - Understanding block layer scheduling

### Cloud Comparison Studies
- [On-Premise vs Cloud Performance Analysis](https://azure.microsoft.com/en-us/resources/cloud-computing-dictionary/what-is-on-premises-vs-cloud/) - Comparative analysis of deployment models
- [Azure Kubernetes Service (AKS) Performance Benchmarks](https://learn.microsoft.com/en-us/azure/aks/concepts-performance-benchmarks) - AKS performance baseline data

### Benchmarking Tools
- [Flexible I/O Tester (fio) Documentation](https://fio.readthedocs.io/en/latest/) - Comprehensive guide to using fio for storage benchmarking
- [GRAID Technology Overview](https://graidtech.com/technology/) - GPU-accelerated RAID technology explanation

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- AOSP team for build system documentation
- Linux kernel storage subsystem maintainers
- Contributors to `fio` benchmark tool

---

**Need Help?** Check our [troubleshooting guide](manual/TROUBLESHOOTING.md) or [open an issue](https://github.com/bluehawana/android15-aosp-testing-graid-nvme/issues).

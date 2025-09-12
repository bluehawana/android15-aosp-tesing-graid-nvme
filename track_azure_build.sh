#!/bin/bash

# Azure HB120rs_v3 AOSP 15 Build Time Tracker
# Run this on the Azure VM during the AOSP build

echo "================================================"
echo "Azure HB120rs_v3 AOSP 15 Build Performance Test"
echo "================================================"
echo "VM Type: Standard HB120rs_v3"
echo "vCPUs: 120 (AMD EPYC 7V73X)"
echo "Memory: 456 GiB HBM2"
echo "OS: Ubuntu 24.04 LTS"
echo "Date: $(date)"
echo "================================================"

# Record start time
START_TIME=$(date +%s)
echo "Build started at: $(date)"

# Run AOSP build (adjust command as needed)
echo "Running: m -j120"
time m -j120

# Record end time
END_TIME=$(date +%s)
ELAPSED_TIME=$((END_TIME - START_TIME))

# Calculate minutes and seconds
MINUTES=$((ELAPSED_TIME / 60))
SECONDS=$((ELAPSED_TIME % 60))

echo "================================================"
echo "Build completed at: $(date)"
echo "Total build time: ${MINUTES} minutes ${SECONDS} seconds"
echo "================================================"

# Save results to file
RESULT_FILE="azure_hb120rs_v3_result_$(date +%Y%m%d_%H%M%S).txt"
cat > $RESULT_FILE << EOF
Azure HB120rs_v3 AOSP 15 Build Results
=======================================
Date: $(date)
VM Type: Standard HB120rs_v3
vCPUs: 120 (AMD EPYC 7V73X)
Memory: 456 GiB HBM2
OS: Ubuntu 24.04 LTS
Build Time: ${MINUTES} minutes ${SECONDS} seconds
EOF

echo "Results saved to: $RESULT_FILE"
#!/bin/bash

# Optimized FIO Performance Test Script
# Measures storage performance after applying optimizations

set -e

RESULTS_DIR="./results/optimized_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$RESULTS_DIR"

echo "=== Optimized FIO Performance Test ==="
echo "Results will be saved to: $RESULTS_DIR"

# Verify optimizations are applied
echo "Checking applied optimizations..."
mount | grep -E "(nvme|graid)" | grep -q "noatime" && echo "✓ noatime detected" || echo "✗ noatime not found"

# Test configurations (same as baseline for comparison)
DEVICES=(
    "/mnt/nvme_test:PM1733_NVMe"
    "/mnt/graid0_test:GRAID_Card0"
    "/mnt/graid1_test:GRAID_Card1"
)

# FIO test parameters
RUNTIME=60
SIZE=1G
NUMJOBS=8

run_fio_test() {
    local path=$1
    local name=$2
    local test_type=$3
    local blocksize=$4
    local iodepth=$5
    local readwrite=$6
    
    echo "Running $test_type test on $name..."
    
    fio --name="$test_type" \
        --filename="$path/test.fio" \
        --size=$SIZE \
        --runtime=$RUNTIME \
        --time_based \
        --ioengine=libaio \
        --direct=1 \
        --bs=$blocksize \
        --iodepth=$iodepth \
        --numjobs=$NUMJOBS \
        --rw=$readwrite \
        --group_reporting \
        --output="$RESULTS_DIR/${name}_${test_type}.json" \
        --output-format=json
}

# Run tests for each device
for device_info in "${DEVICES[@]}"; do
    IFS=':' read -r path name <<< "$device_info"
    
    if [[ ! -d "$path" ]]; then
        echo "Warning: $path not found, skipping $name"
        continue
    fi
    
    echo "Testing $name at $path"
    
    # Sequential read test
    run_fio_test "$path" "$name" "seq_read" "1M" "32" "read"
    
    # Sequential write test  
    run_fio_test "$path" "$name" "seq_write" "1M" "32" "write"
    
    # Random 4K read test
    run_fio_test "$path" "$name" "rand_read_4k" "4k" "32" "randread"
    
    # Random 4K write test
    run_fio_test "$path" "$name" "rand_write_4k" "4k" "32" "randwrite"
    
    # Mixed workload test
    run_fio_test "$path" "$name" "mixed_rw" "4k" "32" "randrw"
    
    echo "Completed tests for $name"
    echo "---"
done

# Generate summary report with optimization status
cat > "$RESULTS_DIR/summary.txt" << EOF
Optimized Performance Test Summary
Date: $(date)
Test Duration: ${RUNTIME}s per test
File Size: $SIZE
Number of Jobs: $NUMJOBS

Applied Optimizations:
$(mount | grep -E "(nvme|graid)" | grep noatime || echo "- No noatime detected!")
$(cat /sys/block/nvme*/queue/scheduler 2>/dev/null | head -1 && echo "- I/O Scheduler: none" || echo "- Default I/O scheduler")

Test Devices:
$(for device in "${DEVICES[@]}"; do echo "- $device"; done)

Individual test results are in JSON format in this directory.
Compare with baseline results to measure improvement.
EOF

# Simple performance comparison if baseline exists
if [[ -d "./results/baseline_"* ]]; then
    echo ""
    echo "Baseline results found. Creating comparison..."
    # This would require a more complex script to parse JSON and compare
    echo "Use compare_results.py to generate detailed comparison report"
fi

echo "=== Optimized testing complete ==="
echo "Results saved to: $RESULTS_DIR"
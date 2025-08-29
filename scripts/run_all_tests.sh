#!/bin/bash

# Master test execution script
# Runs complete AOSP storage performance test suite

set -e

echo "==================================="
echo "AOSP Storage Performance Test Suite"
echo "==================================="
echo "Started at: $(date)"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script requires root privileges"
   echo "Please run with: sudo $0"
   exit 1
fi

# Create results directory
RESULTS_ROOT="./results/full_test_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$RESULTS_ROOT"

# Log file for the entire run
LOG_FILE="$RESULTS_ROOT/test_run.log"
exec 1> >(tee -a "$LOG_FILE")
exec 2>&1

echo "Logging to: $LOG_FILE"
echo ""

# Function to run script with timing
run_test() {
    local script=$1
    local description=$2
    
    echo "-----------------------------------"
    echo "Running: $description"
    echo "Script: $script"
    echo "Start: $(date)"
    
    start_time=$(date +%s)
    
    if bash "$script"; then
        end_time=$(date +%s)
        duration=$((end_time - start_time))
        echo "Completed in: ${duration} seconds"
        echo "Status: SUCCESS"
    else
        echo "Status: FAILED"
        return 1
    fi
    
    echo "-----------------------------------"
    echo ""
}

# Run all tests in sequence
echo "=== Phase 1: Environment Setup ==="
run_test "./scripts/01_setup_environment.sh" "Environment Setup"

echo "=== Phase 2: Baseline Performance ==="
run_test "./scripts/02_baseline_fio_test.sh" "Baseline FIO Tests"

# Wait for user confirmation before applying optimizations
echo "Ready to apply optimizations."
read -p "Continue? [Y/n] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]] && [[ ! -z $REPLY ]]; then
    echo "Test suite aborted by user"
    exit 1
fi

echo "=== Phase 3: Apply Optimizations ==="
run_test "./scripts/03_apply_noatime.sh" "noatime Optimization"

echo "=== Phase 4: Optimized Performance ==="
run_test "./scripts/04_optimized_fio_test.sh" "Optimized FIO Tests"

# Generate final report
echo "=== Generating Final Report ==="
cat > "$RESULTS_ROOT/final_report.txt" << EOF
AOSP Storage Performance Test Suite - Final Report
================================================

Test Date: $(date)
System: $(uname -a)
CPU: $(lscpu | grep "Model name" | cut -d: -f2 | xargs)
Memory: $(free -h | grep Mem | awk '{print $2}')

Storage Devices Tested:
$(lsblk -d -o NAME,SIZE,TYPE,MODEL | grep -E "(nvme|raid)")

Mount Points:
$(mount | grep -E "(nvme|graid)" | awk '{print $1 " on " $3 " (" $5 ")"}')

Test Results:
- Baseline results: ./results/baseline_*
- Optimized results: ./results/optimized_*

Key Optimizations Applied:
1. noatime mount option
2. I/O scheduler optimization (none for NVMe)
3. Increased read-ahead buffer

Next Steps:
1. Analyze JSON results with parsing tools
2. Compare baseline vs optimized performance
3. Run AOSP build tests with optimized configuration

EOF

# Move all test results to the main results directory
echo "Collecting all test results..."
find ./results -name "baseline_*" -o -name "optimized_*" -maxdepth 1 -type d | \
while read dir; do
    if [[ "$dir" != "$RESULTS_ROOT" ]]; then
        mv "$dir" "$RESULTS_ROOT/"
    fi
done

echo ""
echo "==================================="
echo "Test Suite Complete!"
echo "==================================="
echo "All results saved to: $RESULTS_ROOT"
echo "Review the final report at: $RESULTS_ROOT/final_report.txt"
echo ""
echo "To run AOSP build performance test:"
echo "1. Configure AOSP build environment"
echo "2. Use optimized mount points for source and output"
echo "3. Time the build process: time make -j$(nproc)"
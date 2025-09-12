#!/bin/bash

# AOSP Build Monitoring Script
# Run this in a separate terminal while building AOSP

echo "=== AOSP Build Performance Monitor ==="
echo "Press Ctrl+C to stop monitoring"
echo ""

# Create log directory
mkdir -p /aosp/build-logs
LOGFILE="/aosp/build-logs/build-$(date +%Y%m%d-%H%M%S).log"

echo "Logging to: $LOGFILE"
echo ""

# Header for CSV log
echo "timestamp,cpu_usage,mem_usage,disk_read_mb,disk_write_mb,raid_read_mb,raid_write_mb" > $LOGFILE

while true; do
    # Get timestamp
    TIMESTAMP=$(date +%Y-%m-%d\ %H:%M:%S)
    
    # Get CPU usage
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
    
    # Get memory usage
    MEM_USAGE=$(free -m | awk 'NR==2{printf "%.1f", $3*100/$2}')
    
    # Get disk I/O stats for system disk
    DISK_STATS=$(iostat -d sda -m 1 2 | tail -n 2 | head -n 1)
    DISK_READ=$(echo $DISK_STATS | awk '{print $3}')
    DISK_WRITE=$(echo $DISK_STATS | awk '{print $4}')
    
    # Get RAID I/O stats
    RAID_STATS=$(iostat -d md0 -m 1 2 | tail -n 2 | head -n 1)
    RAID_READ=$(echo $RAID_STATS | awk '{print $3}')
    RAID_WRITE=$(echo $RAID_STATS | awk '{print $4}')
    
    # Display current stats
    clear
    echo "=== AOSP Build Performance Monitor ==="
    echo "Time: $TIMESTAMP"
    echo "----------------------------------------"
    printf "CPU Usage:        %5.1f%%\n" $CPU_USAGE
    printf "Memory Usage:     %5.1f%%\n" $MEM_USAGE
    printf "System Disk R/W:  %5.1f / %5.1f MB/s\n" $DISK_READ $DISK_WRITE
    printf "RAID 0 R/W:       %5.1f / %5.1f MB/s\n" $RAID_READ $RAID_WRITE
    echo "----------------------------------------"
    
    # Log to file
    echo "$TIMESTAMP,$CPU_USAGE,$MEM_USAGE,$DISK_READ,$DISK_WRITE,$RAID_READ,$RAID_WRITE" >> $LOGFILE
    
    # Wait 5 seconds before next sample
    sleep 5
done
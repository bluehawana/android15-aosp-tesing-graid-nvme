#!/bin/bash

# Prometheus and Grafana Monitoring Setup Script
# Sets up monitoring infrastructure for AOSP build performance tracking

set -e

echo "=== Setting up Prometheus & Grafana Monitoring ==="
echo "Dashboard ID: 11173 (Disk I/O Performance)"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script requires root privileges"
   echo "Please run with: sudo $0"
   exit 1
fi

# Variables
NODE_EXPORTER_VERSION="1.6.1"
PROMETHEUS_VERSION="2.47.0"

# Install dependencies
echo "Installing dependencies..."
apt-get update
apt-get install -y wget tar curl software-properties-common

# Install Node Exporter
echo ""
echo "Installing Prometheus Node Exporter..."
cd /tmp
wget https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
tar xvf node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
cp node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter /usr/local/bin/
rm -rf node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64*

# Create systemd service for node_exporter
cat > /etc/systemd/system/node_exporter.service << EOF
[Unit]
Description=Prometheus Node Exporter
After=network.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/node_exporter \\
    --collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($|/) \\
    --collector.diskstats \\
    --collector.diskstats.ignored-devices=^(ram|loop|fd|(h|s|v|xv)d[a-z]|nvme\\d+n\\d+p)\\d+$ \\
    --collector.filesystem.fs-types-exclude=^(tmpfs|fuse.lxcfs|squashfs|vfat)$ \\
    --collector.netstat \\
    --collector.processes

[Install]
WantedBy=multi-user.target
EOF

# Create prometheus user
useradd --no-create-home --shell /bin/false prometheus || true

# Install Prometheus (optional)
read -p "Install Prometheus server? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Installing Prometheus..."
    cd /tmp
    wget https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz
    tar xvf prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz
    cp prometheus-${PROMETHEUS_VERSION}.linux-amd64/prometheus /usr/local/bin/
    cp prometheus-${PROMETHEUS_VERSION}.linux-amd64/promtool /usr/local/bin/
    mkdir -p /etc/prometheus /var/lib/prometheus
    cp -r prometheus-${PROMETHEUS_VERSION}.linux-amd64/consoles /etc/prometheus
    cp -r prometheus-${PROMETHEUS_VERSION}.linux-amd64/console_libraries /etc/prometheus
    
    # Create Prometheus config
    cat > /etc/prometheus/prometheus.yml << EOF
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'node'
    static_configs:
    - targets: ['localhost:9100']
      labels:
        instance: 'aosp-build-server'
EOF
    
    chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus
    
    # Create Prometheus systemd service
    cat > /etc/systemd/system/prometheus.service << EOF
[Unit]
Description=Prometheus
After=network.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \\
    --config.file=/etc/prometheus/prometheus.yml \\
    --storage.tsdb.path=/var/lib/prometheus/ \\
    --web.console.templates=/etc/prometheus/consoles \\
    --web.console.libraries=/etc/prometheus/console_libraries

[Install]
WantedBy=multi-user.target
EOF
fi

# Install Grafana
read -p "Install Grafana? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Installing Grafana..."
    curl -fsSL https://packages.grafana.com/gpg.key | gpg --dearmor -o /etc/apt/keyrings/grafana.gpg
    echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://packages.grafana.com/oss/deb stable main" | tee -a /etc/apt/sources.list.d/grafana.list
    apt-get update
    apt-get install -y grafana
fi

# Start services
echo ""
echo "Starting services..."
systemctl daemon-reload
systemctl enable node_exporter
systemctl start node_exporter

if systemctl list-unit-files | grep -q prometheus.service; then
    systemctl enable prometheus
    systemctl start prometheus
fi

if systemctl list-unit-files | grep -q grafana-server.service; then
    systemctl enable grafana-server
    systemctl start grafana-server
fi

# Display status
echo ""
echo "=== Monitoring Setup Complete ==="
echo ""
echo "Service Status:"
systemctl status node_exporter --no-pager | head -5
echo ""
[[ -f /usr/local/bin/prometheus ]] && systemctl status prometheus --no-pager | head -5 && echo ""
[[ -f /usr/bin/grafana-server ]] && systemctl status grafana-server --no-pager | head -5 && echo ""

echo "Access Points:"
echo "- Node Exporter: http://localhost:9100/metrics"
[[ -f /usr/local/bin/prometheus ]] && echo "- Prometheus: http://localhost:9090"
[[ -f /usr/bin/grafana-server ]] && echo "- Grafana: http://localhost:3000 (admin/admin)"

echo ""
echo "Next Steps:"
echo "1. Access Grafana at http://localhost:3000"
echo "2. Add Prometheus data source (http://localhost:9090)"
echo "3. Import dashboard ID: 11173"
echo "4. Start AOSP build and monitor I/O performance"

# Create monitoring script for AOSP builds
cat > /usr/local/bin/monitor_aosp_build << 'EOF'
#!/bin/bash
# Monitor AOSP build with I/O statistics

echo "Starting AOSP build monitoring..."
echo "Grafana Dashboard: http://localhost:3000"
echo "Dashboard ID: 11173"
echo ""
echo "Starting I/O monitoring in background..."

# Start iostat monitoring
iostat -x 1 > aosp_build_iostat_$(date +%Y%m%d_%H%M%S).log &
IOSTAT_PID=$!

# Start iotop monitoring (if available)
if command -v iotop &> /dev/null; then
    iotop -b -d 1 > aosp_build_iotop_$(date +%Y%m%d_%H%M%S).log &
    IOTOP_PID=$!
fi

echo "Monitoring PIDs: iostat=$IOSTAT_PID"
[[ ! -z $IOTOP_PID ]] && echo "iotop=$IOTOP_PID"

echo ""
echo "Run your AOSP build command now."
echo "Press Ctrl+C when build is complete to stop monitoring."

# Wait for user to stop
trap "kill $IOSTAT_PID $IOTOP_PID 2>/dev/null; echo 'Monitoring stopped.'; exit" INT
wait
EOF

chmod +x /usr/local/bin/monitor_aosp_build

echo ""
echo "AOSP build monitoring script created: /usr/local/bin/monitor_aosp_build"
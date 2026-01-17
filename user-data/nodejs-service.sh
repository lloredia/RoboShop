#!/bin/bash

##############################################
# Node.js Service Installation for RoboShop
# Services: Catalogue, User, Cart
# OS: Amazon Linux 2 / RHEL 8
##############################################

set -e

LOG_FILE="/var/log/roboshop-${SERVICE_NAME}-install.log"
exec > >(tee -a $LOG_FILE)
exec 2>&1

echo "========================================="
echo "${SERVICE_NAME} Installation Started: $(date)"
echo "========================================="

print_status() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

check_status() {
    if [ $? -eq 0 ]; then
        print_status "✓ SUCCESS: $1"
    else
        print_status "✗ FAILED: $1"
        exit 1
    fi
}

# Service configuration (passed via environment variables)
SERVICE_NAME=${SERVICE_NAME:-catalogue}
SERVICE_PORT=${SERVICE_PORT:-8080}
SERVICE_URL=${SERVICE_URL:-"https://roboshop-artifacts.s3.amazonaws.com/${SERVICE_NAME}.zip"}

# Install Node.js 18.x
print_status "Installing Node.js..."
curl -sL https://rpm.nodesource.com/setup_18.x | bash -
yum install -y nodejs
check_status "Node.js installation"

# Verify Node.js installation
print_status "Node.js version: $(node -v)"
print_status "npm version: $(npm -v)"

# Create application user
print_status "Creating roboshop user..."
useradd -m -d /app -s /bin/bash roboshop || true
check_status "User creation"

# Download application code
print_status "Downloading ${SERVICE_NAME} code..."
mkdir -p /app
cd /app
curl -L -o /tmp/${SERVICE_NAME}.zip $SERVICE_URL
check_status "${SERVICE_NAME} code download"

# Extract application code
print_status "Extracting ${SERVICE_NAME} code..."
unzip -o /tmp/${SERVICE_NAME}.zip
rm -f /tmp/${SERVICE_NAME}.zip

# Move files to /app
if [ -d "${SERVICE_NAME}-main" ]; then
    mv ${SERVICE_NAME}-main/* .
    rm -rf ${SERVICE_NAME}-main
elif [ -d "${SERVICE_NAME}" ]; then
    mv ${SERVICE_NAME}/* .
    rm -rf ${SERVICE_NAME}
fi
check_status "${SERVICE_NAME} code extraction"

# Set ownership
chown -R roboshop:roboshop /app
check_status "Set ownership"

# Install dependencies
print_status "Installing npm dependencies..."
su - roboshop -c "cd /app && npm install --production"
check_status "npm install"

# Create systemd service file
print_status "Creating systemd service..."
cat > /etc/systemd/system/${SERVICE_NAME}.service <<EOF
[Unit]
Description=RoboShop ${SERVICE_NAME} Service
After=network.target

[Service]
Type=simple
User=roboshop
WorkingDirectory=/app
Environment="NODE_ENV=production"
ExecStart=/usr/bin/node /app/server.js
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=${SERVICE_NAME}

[Install]
WantedBy=multi-user.target
EOF
check_status "Systemd service file"

# Reload systemd
print_status "Reloading systemd..."
systemctl daemon-reload
check_status "Systemd reload"

# Enable and start service
print_status "Starting ${SERVICE_NAME} service..."
systemctl enable ${SERVICE_NAME}
systemctl start ${SERVICE_NAME}
check_status "${SERVICE_NAME} service start"

# Wait for service to be ready
sleep 10

# Check service status
print_status "Checking ${SERVICE_NAME} status..."
systemctl status ${SERVICE_NAME} --no-pager
check_status "${SERVICE_NAME} service status"

# Test service endpoint
print_status "Testing ${SERVICE_NAME} endpoint..."
curl -s http://localhost:${SERVICE_PORT}/health > /dev/null || \
curl -s http://localhost:${SERVICE_PORT}/ > /dev/null
check_status "${SERVICE_NAME} endpoint test"

# Configure firewall
if systemctl is-active --quiet firewalld; then
    print_status "Configuring firewall..."
    firewall-cmd --permanent --add-port=${SERVICE_PORT}/tcp
    firewall-cmd --reload
    check_status "Firewall configuration"
fi

# Print service info
print_status "${SERVICE_NAME} installation completed!"
echo "========================================="
echo "Service: ${SERVICE_NAME}"
echo "Node.js Version: $(node -v)"
echo "Service Status: $(systemctl is-active ${SERVICE_NAME})"
echo "Service Port: ${SERVICE_PORT}"
echo "App Directory: /app"
echo "User: roboshop"
echo "Log: journalctl -u ${SERVICE_NAME} -f"
echo ""
echo "Health Check: curl http://localhost:${SERVICE_PORT}/health"
echo "========================================="

print_status "Installation log saved to: $LOG_FILE"

echo "========================================="
echo "${SERVICE_NAME} Installation Completed: $(date)"
echo "========================================="

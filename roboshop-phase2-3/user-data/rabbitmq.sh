#!/bin/bash

##############################################
# RabbitMQ Installation Script for RoboShop
# OS: Amazon Linux 2 / RHEL 8
##############################################

set -e

LOG_FILE="/var/log/roboshop-rabbitmq-install.log"
exec > >(tee -a $LOG_FILE)
exec 2>&1

echo "========================================="
echo "RabbitMQ Installation Started: $(date)"
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

# Install Erlang (RabbitMQ dependency)
print_status "Installing Erlang..."
curl -s https://packagecloud.io/install/repositories/rabbitmq/erlang/script.rpm.sh | bash
yum install -y erlang
check_status "Erlang installation"

# Add RabbitMQ repository
print_status "Adding RabbitMQ repository..."
curl -s https://packagecloud.io/install/repositories/rabbitmq/rabbitmq-server/script.rpm.sh | bash
check_status "RabbitMQ repository added"

# Install RabbitMQ
print_status "Installing RabbitMQ..."
yum install -y rabbitmq-server
check_status "RabbitMQ installation"

# Enable and start RabbitMQ service
print_status "Starting RabbitMQ service..."
systemctl enable rabbitmq-server
systemctl start rabbitmq-server
check_status "RabbitMQ service start"

# Wait for RabbitMQ to be ready
print_status "Waiting for RabbitMQ to be ready..."
sleep 10

# Enable RabbitMQ management plugin
print_status "Enabling RabbitMQ management plugin..."
rabbitmq-plugins enable rabbitmq_management
check_status "Management plugin enabled"

# Create RoboShop user
RABBITMQ_USER=${RABBITMQ_USER:-roboshop}
RABBITMQ_PASSWORD=${RABBITMQ_PASSWORD:-roboshop123}

print_status "Creating RabbitMQ user..."
rabbitmqctl add_user $RABBITMQ_USER $RABBITMQ_PASSWORD || true
rabbitmqctl set_user_tags $RABBITMQ_USER administrator
rabbitmqctl set_permissions -p / $RABBITMQ_USER ".*" ".*" ".*"
check_status "RabbitMQ user creation"

# Configure RabbitMQ for remote access
print_status "Configuring RabbitMQ for remote access..."
cat > /etc/rabbitmq/rabbitmq.conf <<EOF
listeners.tcp.default = 5672
management.tcp.port = 15672
management.tcp.ip = 0.0.0.0
loopback_users = none
EOF
check_status "RabbitMQ remote access configuration"

# Restart RabbitMQ to apply changes
print_status "Restarting RabbitMQ..."
systemctl restart rabbitmq-server
sleep 10
check_status "RabbitMQ restart"

# Configure firewall
if systemctl is-active --quiet firewalld; then
    print_status "Configuring firewall..."
    firewall-cmd --permanent --add-port=5672/tcp
    firewall-cmd --permanent --add-port=15672/tcp
    firewall-cmd --reload
    check_status "Firewall configuration"
fi

# Create vhost for RoboShop
print_status "Creating RoboShop vhost..."
rabbitmqctl add_vhost roboshop || true
rabbitmqctl set_permissions -p roboshop $RABBITMQ_USER ".*" ".*" ".*"
check_status "Vhost creation"

# Install monitoring script
print_status "Installing monitoring script..."
cat > /usr/local/bin/rabbitmq-monitor.sh <<'MONITOR_SCRIPT'
#!/bin/bash
echo "========================================="
echo "RabbitMQ Status: $(date)"
echo "========================================="
echo "Service Status: $(systemctl is-active rabbitmq-server)"
rabbitmqctl status | grep -A 5 "Status of node"
echo ""
rabbitmqctl list_queues
echo ""
rabbitmqctl list_users
echo "========================================="
MONITOR_SCRIPT

chmod +x /usr/local/bin/rabbitmq-monitor.sh
check_status "Monitoring script creation"

# Setup backup script
print_status "Installing backup script..."
mkdir -p /backup/rabbitmq

cat > /usr/local/bin/rabbitmq-backup.sh <<BACKUP_SCRIPT
#!/bin/bash
BACKUP_DIR="/backup/rabbitmq"
DATE=\$(date +%Y%m%d_%H%M%S)

# Export definitions
curl -u $RABBITMQ_USER:$RABBITMQ_PASSWORD \
     http://localhost:15672/api/definitions \
     -o \$BACKUP_DIR/definitions_\$DATE.json

# Compress old backups
find \$BACKUP_DIR -name "definitions_*.json" -mtime +1 -exec gzip {} \;

# Remove old backups
find \$BACKUP_DIR -name "definitions_*.json.gz" -mtime +7 -delete
BACKUP_SCRIPT

chmod +x /usr/local/bin/rabbitmq-backup.sh
check_status "Backup script installation"

# Setup daily backup
print_status "Setting up daily backup..."
(crontab -l 2>/dev/null; echo "0 2 * * * /usr/local/bin/rabbitmq-backup.sh") | crontab -
check_status "Cron job setup"

# Configure resource limits
print_status "Configuring resource limits..."
cat >> /etc/rabbitmq/rabbitmq.conf <<EOF

# Resource limits
vm_memory_high_watermark.relative = 0.6
disk_free_limit.absolute = 2GB
EOF
check_status "Resource limits configuration"

# Restart to apply all changes
systemctl restart rabbitmq-server
sleep 10

# Print RabbitMQ info
print_status "RabbitMQ installation completed!"
echo "========================================="
echo "RabbitMQ Version: $(rabbitmqctl version)"
echo "RabbitMQ Status: $(systemctl is-active rabbitmq-server)"
echo "AMQP Port: 5672"
echo "Management Port: 15672"
echo "Username: $RABBITMQ_USER"
echo "Password: $RABBITMQ_PASSWORD"
echo "VHost: roboshop"
echo ""
echo "Management UI: http://$(hostname -I | awk '{print $1}'):15672"
echo "Monitor: /usr/local/bin/rabbitmq-monitor.sh"
echo "========================================="

print_status "Installation log saved to: $LOG_FILE"

echo "========================================="
echo "RabbitMQ Installation Completed: $(date)"
echo "========================================="

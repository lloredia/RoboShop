#!/bin/bash

##############################################
# Redis Installation Script for RoboShop
# OS: Amazon Linux 2 / RHEL 8
##############################################

set -e

LOG_FILE="/var/log/roboshop-redis-install.log"
exec > >(tee -a $LOG_FILE)
exec 2>&1

echo "========================================="
echo "Redis Installation Started: $(date)"
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

# Install Redis
print_status "Installing Redis..."
yum install -y redis
check_status "Redis installation"

# Configure Redis to listen on all interfaces
print_status "Configuring Redis..."
sed -i 's/127.0.0.1/0.0.0.0/g' /etc/redis.conf
sed -i 's/protected-mode yes/protected-mode no/g' /etc/redis.conf
check_status "Redis configuration"

# Optimize Redis for production
print_status "Optimizing Redis settings..."
cat >> /etc/redis.conf <<EOF

# RoboShop optimizations
maxmemory 512mb
maxmemory-policy allkeys-lru
tcp-backlog 511
timeout 0
tcp-keepalive 300
EOF
check_status "Redis optimization"

# Enable and start Redis service
print_status "Starting Redis service..."
systemctl enable redis
systemctl start redis
check_status "Redis service start"

# Wait for Redis to be ready
print_status "Waiting for Redis to be ready..."
sleep 5

# Test Redis connectivity
print_status "Testing Redis connectivity..."
redis-cli ping
check_status "Redis connectivity test"

# Configure firewall
if systemctl is-active --quiet firewalld; then
    print_status "Configuring firewall..."
    firewall-cmd --permanent --add-port=6379/tcp
    firewall-cmd --reload
    check_status "Firewall configuration"
fi

# Setup Redis persistence (RDB + AOF)
print_status "Configuring Redis persistence..."
redis-cli CONFIG SET save "900 1 300 10 60 10000"
redis-cli CONFIG SET appendonly yes
redis-cli CONFIG REWRITE
check_status "Persistence configuration"

# Create backup directory
print_status "Creating backup directory..."
mkdir -p /backup/redis
chown redis:redis /backup/redis
check_status "Backup directory creation"

# Install backup script
print_status "Installing backup script..."
cat > /usr/local/bin/redis-backup.sh <<'BACKUP_SCRIPT'
#!/bin/bash
BACKUP_DIR="/backup/redis"
DATE=$(date +%Y%m%d_%H%M%S)
REDIS_DIR="/var/lib/redis"

# Save current state
redis-cli BGSAVE

# Wait for save to complete
while [ $(redis-cli LASTSAVE) -eq $(redis-cli LASTSAVE) ]; do
    sleep 1
done

# Copy dump file
cp $REDIS_DIR/dump.rdb $BACKUP_DIR/dump_$DATE.rdb

# Compress old backups
find $BACKUP_DIR -name "dump_*.rdb" -mtime +1 -exec gzip {} \;

# Remove old compressed backups
find $BACKUP_DIR -name "dump_*.rdb.gz" -mtime +7 -delete
BACKUP_SCRIPT

chmod +x /usr/local/bin/redis-backup.sh
check_status "Backup script installation"

# Setup hourly backup
print_status "Setting up hourly backup..."
(crontab -l 2>/dev/null; echo "0 * * * * /usr/local/bin/redis-backup.sh") | crontab -
check_status "Cron job setup"

# Install monitoring tools
print_status "Installing Redis monitoring tools..."
yum install -y nc telnet
check_status "Monitoring tools installation"

# Create monitoring script
print_status "Creating monitoring script..."
cat > /usr/local/bin/redis-monitor.sh <<'MONITOR_SCRIPT'
#!/bin/bash
echo "========================================="
echo "Redis Status: $(date)"
echo "========================================="
echo "Service Status: $(systemctl is-active redis)"
echo "Memory Usage: $(redis-cli INFO memory | grep used_memory_human)"
echo "Connected Clients: $(redis-cli INFO clients | grep connected_clients)"
echo "Keys: $(redis-cli DBSIZE)"
echo "Uptime: $(redis-cli INFO server | grep uptime_in_days)"
echo "========================================="
MONITOR_SCRIPT

chmod +x /usr/local/bin/redis-monitor.sh
check_status "Monitoring script creation"

# Print Redis info
print_status "Redis installation completed!"
echo "========================================="
echo "Redis Version: $(redis-cli --version)"
echo "Redis Status: $(systemctl is-active redis)"
echo "Redis Port: 6379"
echo "Redis Config: /etc/redis.conf"
echo "Redis Data Dir: /var/lib/redis"
echo "Redis Log: /var/log/redis/redis.log"
echo ""
echo "Test Redis: redis-cli ping"
echo "Monitor Redis: /usr/local/bin/redis-monitor.sh"
echo "========================================="

print_status "Installation log saved to: $LOG_FILE"

echo "========================================="
echo "Redis Installation Completed: $(date)"
echo "========================================="

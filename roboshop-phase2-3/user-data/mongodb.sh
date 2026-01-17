#!/bin/bash

##############################################
# MongoDB Installation Script for RoboShop
# OS: Amazon Linux 2 / RHEL 8
##############################################

set -e  # Exit on error

LOG_FILE="/var/log/roboshop-mongodb-install.log"
exec > >(tee -a $LOG_FILE)
exec 2>&1

echo "========================================="
echo "MongoDB Installation Started: $(date)"
echo "========================================="

# Function to print status
print_status() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Function to check command success
check_status() {
    if [ $? -eq 0 ]; then
        print_status "✓ SUCCESS: $1"
    else
        print_status "✗ FAILED: $1"
        exit 1
    fi
}

# Update system
print_status "Updating system packages..."
yum update -y
check_status "System update"

# Add MongoDB repository
print_status "Adding MongoDB repository..."
cat > /etc/yum.repos.d/mongodb.repo <<EOF
[mongodb-org-6.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/\$releasever/mongodb-org/6.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-6.0.asc
EOF
check_status "MongoDB repository added"

# Install MongoDB
print_status "Installing MongoDB..."
yum install -y mongodb-org
check_status "MongoDB installation"

# Configure MongoDB to listen on all interfaces
print_status "Configuring MongoDB..."
sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
check_status "MongoDB configuration"

# Enable and start MongoDB service
print_status "Starting MongoDB service..."
systemctl enable mongod
systemctl start mongod
check_status "MongoDB service start"

# Wait for MongoDB to be ready
print_status "Waiting for MongoDB to be ready..."
sleep 10

# Check MongoDB status
print_status "Checking MongoDB status..."
systemctl status mongod --no-pager
mongo --eval "db.version()" > /dev/null 2>&1
check_status "MongoDB connectivity test"

# Load schema data (if URLs are provided via environment variables)
if [ -n "$CATALOGUE_SCHEMA_URL" ]; then
    print_status "Loading catalogue schema..."
    curl -s $CATALOGUE_SCHEMA_URL -o /tmp/catalogue.js
    mongo < /tmp/catalogue.js
    check_status "Catalogue schema load"
fi

if [ -n "$USER_SCHEMA_URL" ]; then
    print_status "Loading user schema..."
    curl -s $USER_SCHEMA_URL -o /tmp/user.js
    mongo < /tmp/user.js
    check_status "User schema load"
fi

# Configure firewall (if firewalld is running)
if systemctl is-active --quiet firewalld; then
    print_status "Configuring firewall..."
    firewall-cmd --permanent --add-port=27017/tcp
    firewall-cmd --reload
    check_status "Firewall configuration"
fi

# Create backup directory
print_status "Creating backup directory..."
mkdir -p /backup/mongodb
chown mongod:mongod /backup/mongodb
check_status "Backup directory creation"

# Install backup script
print_status "Installing backup script..."
cat > /usr/local/bin/mongodb-backup.sh <<'BACKUP_SCRIPT'
#!/bin/bash
BACKUP_DIR="/backup/mongodb"
DATE=$(date +%Y%m%d_%H%M%S)
mongodump --out $BACKUP_DIR/backup_$DATE
find $BACKUP_DIR -type d -mtime +7 -exec rm -rf {} +
BACKUP_SCRIPT

chmod +x /usr/local/bin/mongodb-backup.sh
check_status "Backup script installation"

# Add daily backup cron job
print_status "Setting up daily backup..."
(crontab -l 2>/dev/null; echo "0 2 * * * /usr/local/bin/mongodb-backup.sh") | crontab -
check_status "Cron job setup"

# Install CloudWatch agent (optional)
if [ "$ENABLE_CLOUDWATCH" = "true" ]; then
    print_status "Installing CloudWatch agent..."
    wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
    rpm -U ./amazon-cloudwatch-agent.rpm
    check_status "CloudWatch agent installation"
fi

# Print MongoDB info
print_status "MongoDB installation completed!"
echo "========================================="
echo "MongoDB Version: $(mongod --version | head -1)"
echo "MongoDB Status: $(systemctl is-active mongod)"
echo "MongoDB Port: 27017"
echo "MongoDB Data Dir: /var/lib/mongo"
echo "MongoDB Log: /var/log/mongodb/mongod.log"
echo "========================================="

print_status "Installation log saved to: $LOG_FILE"

echo "========================================="
echo "MongoDB Installation Completed: $(date)"
echo "========================================="
